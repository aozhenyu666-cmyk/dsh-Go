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
import { BACKGROUND_LIMIT, backgroundFacts, loadCandidates, openMemoryDb } from './topics.js'
import { buildPrompt } from './prompt.js'
import { appendLedger, readLedger, summarize } from './ledger.js'
import { plan as decide } from './plan.js'
import { DEFAULT_TZ, startOfDay as zoneStartOfDay, zoneOr } from './tz.js'
import { classifyReply } from './classify.js'
import { gardenClass, judgeReply } from './judge.js'
import { isStock } from './stock.js'
import { nextShot, rallyStats } from './rally.js'
import { pickServeType } from './serve.js'
import { LIGHTER_TYPES, mutedUntil, serveWeights, silenceState, voiceSwitch } from './silence.js'
import { cleanPersona, effectiveMode, modeGap, modeOr, modeServeOrder, modeSwitch } from './persona.js'
import {
  MAX_ATTEMPTS,
  addTopic,
  applyNoReply,
  applyReply,
  closeTopic,
  discoverFromMessage,
  gardenStats,
  loadGarden,
  markGenerated,
  markUsed,
  nextTopic,
  nextTopicAt,
  publicTopic,
  saveGarden,
  seedFromCommitments,
  seedFromMemory,
} from './garden.js'
import { lastReplyClass, readCommitments, readMood } from './context.js'

export const name = 'dsh-go-companion'
// Without this, `ctx.tools` below throws "cannot get property tools without inject"
// and the whole entry fails to activate (routes, sweeper and companion_topic never load).
export const inject = ['tools']
const PREFIX = '/dsh-go-companion/v1'
const MAX_BODY = 16 * 1024

const DEFAULTS = Object.freeze({
  enabled: true,
  sessionId: undefined,
  quietStart: 1,
  quietEnd: 8,
  dailyMax: 6,
  // 每小时上限：阶梯换法子时 minGap 会被压过，靠它兜住"别连着砸"。
  hourlyMax: 3,
  minGapMs: 30 * 60_000,
  diceThreshold: 60,
  cooldownMs: 24 * 60 * 60_000,
  allowColdSession: true,
  owner: '主人',
  self: '大肥鱼',
  timeZone: DEFAULT_TZ,
  // 人格卡（口吻、口头禅、兴趣、关系、能说多狠、不碰的话题）和两种模式。
  persona: {},
  mode: 'partner',
  // 语音渠道：开了就是"用人设的口吻念出来"（手机侧系统 TTS）。默认关，他要了才开。
  voice: false,
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

function gardenPath() {
  return join(home(), 'companion', 'topics.json')
}

// 引擎跑在 TZ=GMT，凡是「今天」「零点」都必须按手机时区算，所以这里显式要 tz。
// /plan 允许每次请求带上 timeZone（APP 那边知道手机时区），其余入口用配置里的。
function startOfDay(now, tz) {
  return zoneStartOfDay(now, zoneOr(tz))
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

/**
 * 判球用哪个模型：跟当前会话自己的选择走（它自己的人格和历史也都在那个会话里）。
 * 拿不到就返回 undefined —— 判球会退回本地规则，不会因为没模型就卡住。
 */
function judgeTargetOf(ctx, sessionId) {
  try {
    const agent = liveAgent(ctx, sessionId)
    const cfg = agent?.config
    if (cfg && cfg.provider && cfg.model) return { provider: cfg.provider, model: cfg.model }
    const o = agent?.options
    if (o && o.provider && o.model) return { provider: o.provider, model: o.model }
  } catch {
    // fall through
  }
  return undefined
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
  let garden = loadGarden(gardenPath())
  // 判球要模型。llm 不在就一直是 undefined，判球自动退回本地规则——不能因为缺服务就不加载插件。
  let llmStream
  if (typeof ctx.inject === 'function') {
    try {
      ctx.inject(['llm'], (c) => {
        llmStream = c?.llm?.stream ? c.llm.stream.bind(c.llm) : undefined
      })
    } catch {
      // 没有 llm 服务也没关系
    }
  }
  const streamOf = () => llmStream
  console.error('[companion] loaded; session=' + String(config.sessionId || 'none') + ' memory=' + memoryPath())

  function persistGarden() {
    try {
      saveGarden(gardenPath(), garden)
    } catch (error) {
      console.error('[companion] 保存话题花园失败：' + String((error && error.message) || error))
    }
  }

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

  /**
   * 最近几拍，给判球当上下文（任务书：发球原文 + 回球 + 最近 3 拍）。
   * 只取最近一个回合里的：跨回合的内容对判断没帮助，还会带偏。
   */
  function recentShots() {
    const entries = readLedger(home(), 40)
    let rallyId = ''
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      if (entries[i]?.rallyId) {
        rallyId = String(entries[i].rallyId)
        break
      }
    }
    if (!rallyId) return []
    const out = []
    for (const e of entries) {
      if (e?.rallyId !== rallyId) continue
      if (e.state === 'generated' && e.text) out.push({ from: 'me', text: String(e.text) })
      else if (e.state === 'replied' && e.verdict) out.push({ from: 'user', text: String(e.answer || e.verdict) })
    }
    return out.slice(-3)
  }

  /** 最近一小时发出去几条：阶梯能压过 minGap，靠这个兜住频率。 */
  function sentLastHour(entries, now) {
    const since = Number(now) - 3_600_000
    let n = 0
    for (const e of entries) if (e?.state === 'generated' && Number(e.at) >= since) n += 1
    return n
  }

  /** 上一次被漠视的那一球：阶梯换法子时拿它当素材（"我叫了你两次，你在刷什么"）。 */
  function lastIgnored(entries) {
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      const e = entries[i]
      if (e?.state !== 'generated' || !e.requestId) continue
      let answered = false
      for (const x of entries) if (x?.requestId === e.requestId && x.state === 'replied') answered = true
      if (!answered) return { at: Number(e.at) || 0, serveType: String(e.serveType || ''), text: String(e.text || '') }
      return null
    }
    return null
  }

  // 上一球如果被判成套话（3.3），把原句取出来，下一球照着打回。
  function lastStockBall(entries) {
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      const e = entries[i]
      if (e?.state !== 'generated' || !e.text) continue
      return e.stock === true ? String(e.text) : null
    }
    return null
  }

  async function compose(_req, sessionId) {
    const db = openMemoryDb(memoryPath())
    try {
      const now = Date.now()
      const candidates = loadCandidates(db, { sessionId, now })
      const entries = readLedger(home(), 400)
      const recent = summarize(entries, startOfDay(now, config.timeZone))
      const commitments = readCommitments(home(), now, 3)

      // 记忆是话题的种子来源，花园自己管生命周期；每次合成前同步一次，只增不删。
      seedFromMemory(garden, candidates, now)
      seedFromCommitments(garden, commitments, now)

      const topic = nextTopic(garden, {
        now,
        lastTopicId: recent.lastTopicId,
        lastAt: recent.lastAt,
        cooldownMs: config.cooldownMs,
        maxAttempts: MAX_ATTEMPTS,
      })
      if (!topic) {
        persistGarden()
        return { error: 'no-topic' }
      }
      markUsed(garden, topic.id, now)
      persistGarden()

      const mood = readMood(home())
      // 没接球时不砸同一类：走阶梯就只挑更轻的球，平时按权重挑（被漠视的降、接住的升）。
      const silence = silenceState(entries, { sessionId, now })
      const lighter = silence.stage === 'lighter' || silence.stage === 'channel'
      // 模式决定从哪几种球里挑：伙伴偏闲聊/记忆，教练偏观察/挑衅。前三种里挑。
      const mode = effectiveMode(config, now)
      const serveType = pickServeType(entries, Math.floor(Math.random() * 100), {
        only: lighter ? LIGHTER_TYPES : modeServeOrder(mode).slice(0, 3),
        weights: serveWeights(entries),
      })
      // 回合与拍数都从账本重建：进程重启不会丢，也不多存一份状态。
      const rally = nextShot(entries, { sessionId, now })
      const prompt = buildPrompt({
        topic,
        facts: backgroundFacts(candidates, BACKGROUND_LIMIT),
        episodes: (candidates.episodes || []).map((e) => e.text),
        commitments,
        mood: mood ? mood.mood : undefined,
        replyClass: lastReplyClass(entries),
        serveType,
        stockHit: lastStockBall(entries),
        ignored: lighter ? lastIgnored(entries) : undefined,
        persona: config.persona,
        mode,
        owner: config.owner,
        self: config.self,
      })
      return { text: prompt, prompt, topic, serveType, rallyId: rally.rallyId, shot: rally.shot, silence }
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
        serveType: r.serveType ?? undefined,
        rallyId: r.rallyId ?? undefined,
        shot: r.shot ?? undefined,
        silence: r.silence ?? undefined,
        state: r.state,
        at: Date.now(),
        text: r.text ?? undefined,
        // 套话只在生成时判：谁都能说的模板不算开口。判出来就记进账本，
        // 下一球把它打回去，P5 的评测也靠这个数。
        stock: isStock(r.text) || undefined,
        failure: r.failure ?? undefined,
        cold: r.cold === true,
      })
      // 生成成功后等一次人的回应；2 小时内没有就记 none（有限跟进/冷却的依据）。
      if (r.state === 'generated') {
        // 发球原文、回合、拍数都留给判球用：回球回来时要能把它和这一球对上。
        setPending(r.sessionId, {
          requestId: r.requestId,
          topicId: r.topicId,
          rallyId: r.rallyId,
          shot: r.shot,
          serveType: r.serveType,
          serve: r.text || '',
          at: Date.now(),
        })
        if (r.topicId) {
          markGenerated(garden, r.topicId, r.text, Date.now())
          persistGarden()
        }
      }
    },
  })

  ctx.on('session/event', async (session, event) => {
    try {
      desk.onSessionEvent(session?.id, event)
    } catch {
      // never disturb the session
    }
    try {
      if (event?.type === 'user/message') {
        const text = messageText(event.data)
        // 插件注入的消息都走 user/message（自己、speak-up、思维驾驶员……），
        // 也都不是人打的字。当成回复会凭空记一条 replied，还会把话题判成 done；
        // 只有来源为空或明确标成 user 的才算人。
        const kind = event.data?.source?.kind
        if (kind && kind !== 'user') return
        // 他说"安静一小时""今天别找我"就照做：这是一句话就说清的事，不必占一次模型调用。
        const muteUntilAt = mutedUntil(text, Date.now(), { tz: config.timeZone })
        if (muteUntilAt) {
          config = { ...config, muteUntil: muteUntilAt }
          try {
            writeConfig(config)
          } catch {
            // 写不进去也不影响这一轮；下次他还说就再设一次
          }
          record({ state: 'muted', at: Date.now(), until: muteUntilAt, answer: String(text).slice(0, 100) })
        }
        // 他说"进入教练模式 2 小时"就切过去；给没给时长都认。
        const sw = modeSwitch(text)
        if (sw) {
          config = { ...config, mode: sw.mode, modeUntil: sw.hours ? Date.now() + sw.hours * 3_600_000 : 0 }
          try {
            writeConfig(config)
          } catch {
            // 写不进去也不影响这一轮
          }
          record({ state: 'mode', at: Date.now(), mode: sw.mode, until: config.modeUntil || undefined })
        }
        // 他说"开语音""别念了"就照做：15 分钟换渠道那一级这时会念出来。
        const voice = voiceSwitch(text)
        if (voice !== null && voice !== (config.voice === true)) {
          config = { ...config, voice }
          try {
            writeConfig(config)
          } catch {
            // 写不进去也不影响这一轮
          }
          record({ state: 'voice', at: Date.now(), voice, answer: String(text).slice(0, 100) })
        }
        const pending = takePending(session?.id)
        if (pending) {
          // 这一球由大肥鱼自己判（6 秒超时或连不上就退回规则），不再按字数。
          const target = judgeTargetOf(ctx, session?.id)
          const judged = await judgeReply({
            stream: streamOf(),
            provider: target?.provider,
            model: target?.model,
            sessionId: session?.id,
            serve: pending.serve,
            reply: text,
            recent: recentShots(),
            mode: effectiveMode(config, Date.now()),
          })
          const replyClass = gardenClass(judged.verdict)
          const now = Date.now()
          const shot = (Number(pending.shot) || 0) + 1
          record({
            requestId: pending.requestId,
            sessionId: session?.id,
            topicId: pending.topicId,
            rallyId: pending.rallyId || undefined,
            shot: pending.rallyId ? shot : undefined,
            state: 'replied',
            at: now,
            replyClass,
            verdict: judged.verdict,
            why: judged.why || undefined,
            next: judged.next,
            judged: judged.judged === true,
            // 判下一球时要看得到上一球回了什么；只留一小段，账本本来就在手机上、权限 0600。
            answer: String(text || '').slice(0, 200) || undefined,
          })
          if (replyClass === 'substantive') {
            record({
              requestId: pending.requestId,
              sessionId: session?.id,
              topicId: pending.topicId,
              rallyId: pending.rallyId || undefined,
              shot: pending.rallyId ? shot : undefined,
              state: 'substantive',
              at: now,
              replyClass,
              verdict: judged.verdict,
            })
          }
          // 话题花园跟着人的反应走：认真答就继续，敷衍就换轻的，拒绝就停。
          if (pending.topicId) {
            applyReply(garden, pending.topicId, replyClass, now)
            persistGarden()
          }
        } else if (text) {
          // 正常聊天里冒出的新话题：每天最多 3 条，宁缺毋滥。
          if (discoverFromMessage(garden, text, Date.now())) persistGarden()
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

  // 正常聊天时，模型可以把“以后还想聊的事”放进话题花园；主动回合里工具会被硬拦。
  const tools = ctx.get?.('tools') ?? ctx.tools
  if (tools && typeof tools.register === 'function') {
    try {
      const off = tools.register({
        name: 'companion_topic',
        description:
          'Record a topic worth returning to in the companion topic garden (not long-term facts). ' +
          'Use add when the person mentions something they want to do/watch/play/discuss later, ' +
          'or when you have an interesting share/idea worth bringing up later. ' +
          'list shows the garden; done/pause closes a topic. Keep one topic per entry.',
        parameters: {
          type: 'object',
          properties: {
            action: { type: 'string', enum: ['add', 'list', 'done', 'pause'] },
            title: { type: 'string', description: 'One line: what to talk about later.' },
            detail: { type: 'string', description: 'Optional context worth keeping.' },
            kind: { type: 'string', enum: ['continue', 'share', 'explore'], description: 'continue/unfinished, share, or an open question to think about.' },
            interest: { type: 'integer', description: '0..2, how much the person seems to care.' },
            id: { type: 'string', description: 'Topic id from list (for done/pause).' },
          },
          additionalProperties: false,
        },
        output: {
          schema: {
            type: 'object',
            additionalProperties: true,
            properties: { ok: { type: 'boolean' }, text: { type: 'string' } },
          },
          render: (_args, value) => [{ type: 'text', text: String((value && value.text) || '') }],
        },
        execute: (args = {}) => {
          const now = Date.now()
          const action = String(args.action || 'list')
          if (action === 'add') {
            const topic = addTopic(garden, {
              title: args.title,
              detail: args.detail,
              kind: args.kind,
              interest: args.interest,
              source: 'agent',
            }, now)
            if (!topic) return { ok: false, text: '标题不能为空。' }
            persistGarden()
            return { ok: true, text: '记进话题花园了：' + topic.title, topic: publicTopic(topic) }
          }
          if (action === 'list') {
            const rows = garden.topics.filter((t) => t.status !== 'done').slice(0, 10).map(publicTopic)
            return {
              ok: true,
              text: rows.length ? rows.map((t) => `${t.id} · ${t.kind} · ${t.status} · ${t.title}`).join('\n') : '花园里还没有话题。',
              topics: rows,
            }
          }
          let target = String(args.id || '')
          if (!target && args.title) {
            const needle = String(args.title).trim()
            const hit = garden.topics.find((t) => t.status !== 'done' && t.title.includes(needle))
            if (hit) target = hit.id
          }
          if (!target) return { ok: false, text: '没找到要关闭的话题（用 list 拿 id）。' }
          const closed = closeTopic(garden, target, action === 'done' ? 'done' : 'pause', now)
          if (!closed) return { ok: false, text: '没找到这个话题。' }
          persistGarden()
          return { ok: true, text: action === 'done' ? '话题结束了。' : '话题先搁着。', topic: publicTopic(closed) }
        },
      })
      if (typeof off === 'function') ctx.effect?.(() => off)
      console.error('[companion] registered tool companion_topic')
    } catch (error) {
      console.error('[companion] companion_topic 注册失败：' + String((error && error.message) || error))
    }
  }

  const sweeper = setInterval(() => {
    desk.sweep()
    const now = Date.now()
    for (const [sid, pending] of [...pendingReply]) {
      if (now - pending.at < REPLY_WINDOW_MS) continue
      record({ requestId: pending.requestId, sessionId: sid, topicId: pending.topicId, state: 'none', at: now })
      if (pending.topicId) {
        applyNoReply(garden, pending.topicId, now)
        persistGarden()
      }
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
          if (r.status >= 400) {
            console.error('[companion] request refused ' + r.status + ' ' + String(r.body?.error?.code || ''))
          }
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
      hourlyMax: config.hourlyMax,
      minGapMs: config.minGapMs,
      diceThreshold: config.diceThreshold,
      allowColdSession: config.allowColdSession,
      owner: config.owner,
      self: config.self,
      timeZone: config.timeZone,
      // 首页的一键安静：App 直接把要静音到的时间写进来。
      muteUntil: Number(config.muteUntil) || 0,
      // 人格卡与模式：首页可以编辑，引擎只管用。
      persona: cleanPersona(config.persona),
      mode: modeOr(config.mode),
      modeUntil: Number(config.modeUntil) || 0,
      // 语音渠道开关：手机读到 plan.channel === 'speech' 才会念。
      voice: config.voice === true,
    }
  }

  function planRoute(body) {
    const now = Date.now()
    const tz = zoneOr(body?.timeZone || config.timeZone)
    const sessionId = typeof body?.sessionId === 'string' && body.sessionId ? body.sessionId : config.sessionId
    if (!sessionId) return { v: 1, speak: false, reason: 'no-session', topic: null, nextCheckAt: now + 6 * 3_600_000 }
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
    const ledger = readLedger(home(), 400)
    const recent = summarize(ledger, startOfDay(now, tz))
    const silence = silenceState(ledger, { sessionId, now })
    seedFromMemory(garden, candidates, now)
    seedFromCommitments(garden, readCommitments(home(), now, 3), now)
    const topic = nextTopic(garden, {
      now,
      lastTopicId: recent.lastTopicId,
      lastAt: recent.lastAt,
      cooldownMs: config.cooldownMs,
      maxAttempts: MAX_ATTEMPTS,
    })
    persistGarden()
    const out = decide({
      // 教练模式更勤，伙伴更松：间隔按模式放大。
      config: { ...config, minGapMs: modeGap(config.minGapMs, effectiveMode(config, now)) },
      now,
      tz,
      topic,
      sentToday: recent.counts.generated,
      sentLastHour: sentLastHour(ledger, now),
      lastAt: recent.lastAt,
      roll: body?.roll,
      silence,
      mutedUntil: Number(config.muteUntil) || 0,
      nextTopicAt: nextTopicAt(garden, now),
      // 15 分钟换渠道：开了语音，plan 会返回 channel='speech'，手机就把这一球念出来。
      voice: config.voice === true,
    })
    return { v: 1, ...out, silence, sessionId }
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
    const today = summarize(entries, startOfDay(now, config.timeZone))
    return {
      v: 1,
      version: '0.2.0',
      config: publicConfig(),
      sessionId: config.sessionId ?? null,
      agents: live,
      counters: desk.counters,
      today: today.counts,
      // 好坏只看回合：有效回合 = 至少两拍且有一拍接住了（见 rally.js）。
      rallies: rallyStats(entries, startOfDay(now, config.timeZone)),
      // 「现在」这一层要能说清：上一球被漠视到哪一级、静音到什么时候。
      silence: silenceState(entries, { sessionId: config.sessionId, now }),
      lastTopicId: today.lastTopicId || null,
      memory: { path: memoryPath(), exists: existsSync(memoryPath()) },
      garden: gardenStats(garden, now),
      gardenTopics: garden.topics
        .filter((t) => t.status !== 'done')
        .slice(0, 8)
        .map(publicTopic),
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
    if (Number.isFinite(Number(body.hourlyMax))) next.hourlyMax = Math.max(0, Math.min(12, Math.round(Number(body.hourlyMax))))
    // 一键安静：给 0 或过去的时间就是解除。
    if (Number.isFinite(Number(body.muteUntil))) next.muteUntil = Math.max(0, Number(body.muteUntil))
    if (body.persona && typeof body.persona === 'object') next.persona = cleanPersona(body.persona)
    if (typeof body.mode === 'string') next.mode = modeOr(body.mode)
    if (Number.isFinite(Number(body.modeUntil))) next.modeUntil = Math.max(0, Number(body.modeUntil))
    if (Number.isFinite(Number(body.minGapMs))) next.minGapMs = Math.max(60_000, Math.min(24 * 3_600_000, Number(body.minGapMs)))
    if (Number.isFinite(Number(body.diceThreshold))) next.diceThreshold = Math.max(0, Math.min(100, Number(body.diceThreshold)))
    if (typeof body.allowColdSession === 'boolean') next.allowColdSession = body.allowColdSession
    if (typeof body.voice === 'boolean') next.voice = body.voice
    if (typeof body.owner === 'string' && body.owner.trim()) next.owner = body.owner.trim().slice(0, 40)
    if (typeof body.self === 'string' && body.self.trim()) next.self = body.self.trim().slice(0, 40)
    if (typeof body.timeZone === 'string' && body.timeZone.trim()) next.timeZone = zoneOr(body.timeZone)
  }
  return next
}
