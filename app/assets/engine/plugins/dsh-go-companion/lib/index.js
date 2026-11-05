// dsh-go-companion · 宿主半边
//
// 手机端主动事件的唯一决策与回合服务：
//   POST /request   一次主动交流（原生闹钟已经判定“到点”）
//   GET  /result    长轮询 accepted / claimed / generated / failed
//   POST /cancel
//   POST /plan      本地决策：开没开、静不静、额度、掷骰、话题（零模型）
//   POST /outcome   送达/展示/回应回执（写账本）
//   GET  /status
//   POST /config
//
// 复用：fish-memory.sqlite（只读话题/事实/经历）、relation 存在性、原生展示层。
// 不新建记忆库；不读屏幕内容；所有 SQL 参数绑定。

import { mkdirSync, readFileSync, renameSync, writeFileSync, existsSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'
import { randomUUID } from 'node:crypto'
import { Desk, SOURCE_KIND } from './core.js'
import { BACKGROUND_LIMIT, backgroundFacts, chooseTopic, loadCandidates, openMemoryDb } from './topics.js'
import { buildPrompt } from './prompt.js'
import { appendLedger, readLedger, summarize } from './ledger.js'
import { plan as decide } from './plan.js'
import { classifyReply } from './classify.js'

export const name = 'dsh-go-companion'
const PREFIX = '/dsh-go-companion/v1'
const MAX_BODY = 16 * 1024

const DEFAULTS = Object.freeze({
  enabled: true,
  sessionId: undefined,
  quietStart: 1,
  quietEnd: 8,
  dailyMax: 6,
  minGapMs: 30 * 60_000,
  diceThreshold: 60,
  cooldownMs: 24 * 60 * 60_000,
  allowColdSession: true,
  owner: '主人',
  self: '大肥鱼',
})

function home() {
  return process.env.DSH_HOME || join(homedir(), '.dsh')
}

function configPath() {
  return join(home(), 'companion', 'config.json')
}

function readConfig() {
  let merged = { ...DEFAULTS }
  try {
    const raw = JSON.parse(readFileSync(configPath(), 'utf8'))
    if (raw && typeof raw === 'object') merged = { ...merged, ...raw }
  } catch {
    // defaults
  }
  // 旧 dsh-go-proactive 设置过目标会话：迁过来，避免升级后“开了但不说话”。
  if (!merged.sessionId) {
    try {
      const legacy = JSON.parse(readFileSync(join(home(), 'storages', 'dsh-go-proactive', 'config.json'), 'utf8'))
      if (legacy && typeof legacy.sessionId === 'string' && legacy.sessionId) merged.sessionId = legacy.sessionId
    } catch {
      // no legacy config
    }
  }
  return merged
}

function writeConfig(cfg) {
  const p = configPath()
  mkdirSync(join(p, '..'), { recursive: true, mode: 0o700 })
  const tmp = p + '.' + String(process.pid) + '.tmp'
  writeFileSync(tmp, JSON.stringify(cfg, null, 2) + '\n', { encoding: 'utf8', mode: 0o600 })
  renameSync(tmp, p)
}

function memoryPath() {
  return join(home(), 'fish-memory', 'fish-memory.sqlite')
}

function startOfDay(now) {
  const d = new Date(now)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}

function send(res, status, body) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  })
  res.end(JSON.stringify(body))
}

async function readJson(req) {
  if (!String(req.headers['content-type'] ?? '').startsWith('application/json')) return { error: 415 }
  let size = 0
  const chunks = []
  for await (const c of req) {
    size += c.length
    if (size > MAX_BODY) return { error: 413 }
    chunks.push(c)
  }
  try {
    return { value: JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}') }
  } catch {
    return { error: 400 }
  }
}

function sessionIds(id) {
  const s = String(id || '')
  return s.startsWith('session-') ? [s, s.slice(8)] : [s, 'session-' + s]
}

function isArchived(ctx, id) {
  try {
    const archived = ctx.get?.('workspaceRegistry')?.archivedSessionIds
    if (!Array.isArray(archived)) return false
    return sessionIds(id).some((x) => archived.includes(x))
  } catch {
    return false
  }
}

function liveAgent(ctx, id) {
  const agents = ctx.get?.('agents')
  if (!agents) return undefined
  for (const x of sessionIds(id)) {
    try {
      const a = agents.get(x)
      if (a !== undefined) return a
    } catch {
      // not live
    }
  }
  return undefined
}

/** 冷会话：只唤醒调用方指定/配置过的会话；失败不新建。 */
async function resolveAgent(ctx, id, config) {
  const live = liveAgent(ctx, id)
  if (live !== undefined) return { agent: live, cold: false }
  if (config.allowColdSession !== true) return undefined
  const sc = ctx.get?.('sessionController')
  if (!sc || typeof sc.resolveAgent !== 'function') return undefined
  for (const x of sessionIds(id)) {
    try {
      const r = await sc.resolveAgent(x)
      if (r && r.agent) return { agent: r.agent, cold: true }
    } catch {
      // try the other id form
    }
  }
  return undefined
}

function userMessage(text) {
  return { id: randomUUID(), role: 'user', content: [{ type: 'text', text }], source: { kind: SOURCE_KIND } }
}

function messageText(data) {
  const content = data?.content
  if (!Array.isArray(content)) return ''
  return content
    .filter((b) => b && b.type === 'text' && typeof b.text === 'string')
    .map((b) => b.text)
    .join('')
    .trim()
}

export function apply(ctx) {
  let config = readConfig()
  console.error('[companion] loaded; session=' + String(config.sessionId || 'none') + ' memory=' + memoryPath())

  /** sessionId -> {requestId, topicId, at}: a generated message the person has not answered yet. */
  const pendingReply = new Map()
  const REPLY_WINDOW_MS = 2 * 3_600_000

  function setPending(sessionId, value) {
    if (!sessionId) return
    for (const id of sessionIds(sessionId)) pendingReply.set(id, value)
  }

  function takePending(sessionId) {
    if (!sessionId) return undefined
    for (const id of sessionIds(sessionId)) {
      const v = pendingReply.get(id)
      if (v) {
        for (const x of sessionIds(sessionId)) pendingReply.delete(x)
        return v
      }
    }
    return undefined
  }

  function record(entry) {
    appendLedger(home(), { v: 1, ...entry })
  }

  async function compose(_req, sessionId) {
    const db = openMemoryDb(memoryPath())
    try {
      const now = Date.now()
      const candidates = loadCandidates(db, { sessionId, now })
      const recent = summarize(readLedger(home(), 400), startOfDay(now))
      const topic = chooseTopic(candidates, {
        now,
        lastTopicId: recent.lastTopicId,
        lastAt: recent.lastAt,
        cooldownMs: config.cooldownMs,
      })
      if (!topic) return { error: 'no-topic' }
      const prompt = buildPrompt({
        topic,
        facts: backgroundFacts(candidates, BACKGROUND_LIMIT),
        episodes: (candidates.episodes || []).map((e) => e.text),
        owner: config.owner,
        self: config.self,
      })
      return { text: prompt, prompt, topic }
    } finally {
      try {
        db?.close?.()
      } catch {
        // ignore
      }
    }
  }

  const desk = new Desk({
    resolveAgent: (id) => resolveAgent(ctx, id, config),
    compose,
    makeMessage: userMessage,
    isArchived: (id) => isArchived(ctx, id),
    defaultSession: () => config.sessionId,
    onChange: (r) => {
      record({
        requestId: r.requestId,
        eventId: r.eventId,
        sessionId: r.sessionId,
        topicId: r.topicId,
        topicKind: r.topicKind,
        state: r.state,
        at: Date.now(),
        text: r.text ?? undefined,
        failure: r.failure ?? undefined,
        cold: r.cold === true,
      })
      // 生成成功后等一次人的回应；2 小时内没有就记 none（有限跟进/冷却的依据）。
      if (r.state === 'generated') {
        setPending(r.sessionId, { requestId: r.requestId, topicId: r.topicId, at: Date.now() })
      }
    },
  })

  ctx.on('session/event', (session, event) => {
    try {
      desk.onSessionEvent(session?.id, event)
    } catch {
      // never disturb the session
    }
    try {
      if (event?.type === 'user/message') {
        const pending = takePending(session?.id)
        if (pending) {
          const text = messageText(event.data)
          const replyClass = classifyReply(text)
          record({
            requestId: pending.requestId,
            sessionId: session?.id,
            topicId: pending.topicId,
            state: 'replied',
            at: Date.now(),
            replyClass,
          })
          if (replyClass === 'substantive') {
            record({
              requestId: pending.requestId,
              sessionId: session?.id,
              topicId: pending.topicId,
              state: 'substantive',
              at: Date.now(),
              replyClass,
            })
          }
        }
      }
    } catch {
      // classification must never break a turn
    }
  })
  ctx.on(
    'tools/pre-execute',
    (exec, next) => {
      let denied
      try {
        denied = desk.guardTool(exec?.agent?.id ?? exec?.agent?.session?.id)
      } catch {
        denied = undefined
      }
      return denied ?? next()
    },
    { global: true, prepend: true },
  )
  ctx.on('agent/disposed', (agent) => {
    try {
      if (agent?.id) desk.onAgentGone(agent.id)
    } catch {
      // ignore
    }
  })
  const sweeper = setInterval(() => {
    desk.sweep()
    const now = Date.now()
    for (const [sid, pending] of [...pendingReply]) {
      if (now - pending.at < REPLY_WINDOW_MS) continue
      record({ requestId: pending.requestId, sessionId: sid, topicId: pending.topicId, state: 'none', at: now })
      for (const x of sessionIds(sid)) pendingReply.delete(x)
    }
  }, 5_000)
  sweeper.unref?.()
  ctx.effect?.(() => () => clearInterval(sweeper))

  const rejection = (req) => {
    const connection = ctx.get?.('connection')
    return connection === undefined ? 503 : connection.requestRejection(req)
  }

  const handler = async (req, res) => {
    const denied = rejection(req)
    if (denied !== undefined) {
      res.writeHead(denied, { 'cache-control': 'no-store' })
      res.end()
      return
    }
    const url = new URL(req.url, 'http://local')
    const path = url.pathname.slice(PREFIX.length)
    try {
      if (req.method === 'POST' && (path === '/request' || path === '/cancel' || path === '/config' || path === '/plan' || path === '/outcome')) {
        const body = await readJson(req)
        if (body.error) {
          return send(res, body.error, {
            v: 1,
            error: {
              code: body.error === 415 ? 'unsupported-media-type' : body.error === 413 ? 'too-large' : 'bad-request',
              message: 'body',
            },
          })
        }
        if (path === '/request') {
          const r = await desk.request(body.value)
          return send(res, r.status, r.body)
        }
        if (path === '/cancel') {
          const r = desk.cancel(String(body.value?.requestId ?? ''))
          return send(res, r.status, r.body)
        }
        if (path === '/plan') return send(res, 200, planRoute(body.value))
        if (path === '/outcome') return send(res, 200, outcomeRoute(body.value))
        config = mergeConfig(config, body.value)
        writeConfig(config)
        return send(res, 200, { v: 1, sessionId: config.sessionId ?? null, config: publicConfig() })
      }
      if (req.method === 'GET' && path === '/result') {
        const waitMs = Math.min(Math.max(Number(url.searchParams.get('waitMs') ?? 0) || 0, 0), 25_000)
        const r = await desk.wait(String(url.searchParams.get('requestId') ?? ''), waitMs)
        return send(res, r.status, r.body)
      }
      if (req.method === 'GET' && path === '/status') {
        return send(res, 200, statusBody())
      }
      return send(res, 404, { v: 1, error: { code: 'not-found', message: path } })
    } catch (e) {
      return send(res, 500, { v: 1, error: { code: 'plugin-error', message: String(e?.message ?? e) } })
    }
  }

  function publicConfig() {
    return {
      enabled: config.enabled,
      sessionId: config.sessionId ?? null,
      quietStart: config.quietStart,
      quietEnd: config.quietEnd,
      dailyMax: config.dailyMax,
      minGapMs: config.minGapMs,
      diceThreshold: config.diceThreshold,
      allowColdSession: config.allowColdSession,
      owner: config.owner,
      self: config.self,
    }
  }

  function planRoute(body) {
    const now = Date.now()
    const sessionId = typeof body?.sessionId === 'string' && body.sessionId ? body.sessionId : config.sessionId
    if (!sessionId) return { v: 1, speak: false, reason: 'no-session', topic: null }
    const db = openMemoryDb(memoryPath())
    let candidates = { topics: [], facts: [], episodes: [] }
    try {
      candidates = loadCandidates(db, { sessionId, now })
    } finally {
      try {
        db?.close?.()
      } catch {
        // ignore
      }
    }
    const recent = summarize(readLedger(home(), 400), startOfDay(now))
    const topic = chooseTopic(candidates, {
      now,
      lastTopicId: recent.lastTopicId,
      lastAt: recent.lastAt,
      cooldownMs: config.cooldownMs,
    })
    const out = decide({
      config,
      now,
      topic,
      sentToday: recent.counts.generated,
      lastAt: recent.lastAt,
      roll: body?.roll,
    })
    return { v: 1, ...out, sessionId }
  }

  function outcomeRoute(body) {
    const requestId = typeof body?.requestId === 'string' ? body.requestId : ''
    const stage = String(body?.stage || '')
    const allowed = new Set(['delivered', 'displayed', 'replied', 'substantive', 'dismissed'])
    if (!requestId || !allowed.has(stage)) {
      return { v: 1, error: { code: 'bad-outcome', message: 'requestId/stage' } }
    }
    record({
      requestId,
      state: stage,
      at: Number(body?.at) || Date.now(),
      replyClass: typeof body?.replyClass === 'string' ? body.replyClass.slice(0, 32) : undefined,
    })
    return { v: 1, ok: true }
  }

  function statusBody() {
    const agents = ctx.get?.('agents')
    const live = (agents?.roots?.() ?? agents?.list?.() ?? []).map((a) => ({ id: a.id, status: a.status }))
    const now = Date.now()
    const entries = readLedger(home(), 400)
    const today = summarize(entries, startOfDay(now))
    return {
      v: 1,
      version: '0.1.0',
      config: publicConfig(),
      sessionId: config.sessionId ?? null,
      agents: live,
      counters: desk.counters,
      today: today.counts,
      lastTopicId: today.lastTopicId || null,
      memory: { path: memoryPath(), exists: existsSync(memoryPath()) },
      recent: readLedger(home(), 20),
    }
  }

  ctx.inject(['webServer'], (webCtx) => {
    webCtx.effect(
      () => webCtx.webServer.register({ kind: 'prefix', path: PREFIX, handler }),
      'dsh-go-companion: routes',
    )
    console.error('[companion] routes ' + PREFIX)
  })
}

function mergeConfig(current, body) {
  const next = { ...current }
  if (body && typeof body === 'object') {
    if (body.sessionId === null) next.sessionId = undefined
    else if (typeof body.sessionId === 'string' && body.sessionId.length <= 256) next.sessionId = body.sessionId
    if (typeof body.enabled === 'boolean') next.enabled = body.enabled
    for (const key of ['quietStart', 'quietEnd']) {
      if (Number.isFinite(Number(body[key]))) next[key] = Math.max(0, Math.min(23, Math.round(Number(body[key]))))
    }
    if (Number.isFinite(Number(body.dailyMax))) next.dailyMax = Math.max(0, Math.min(48, Math.round(Number(body.dailyMax))))
    if (Number.isFinite(Number(body.minGapMs))) next.minGapMs = Math.max(60_000, Math.min(24 * 3_600_000, Number(body.minGapMs)))
    if (Number.isFinite(Number(body.diceThreshold))) next.diceThreshold = Math.max(0, Math.min(100, Number(body.diceThreshold)))
    if (typeof body.allowColdSession === 'boolean') next.allowColdSession = body.allowColdSession
    if (typeof body.owner === 'string' && body.owner.trim()) next.owner = body.owner.trim().slice(0, 40)
    if (typeof body.self === 'string' && body.self.trim()) next.self = body.self.trim().slice(0, 40)
  }
  return next
}
