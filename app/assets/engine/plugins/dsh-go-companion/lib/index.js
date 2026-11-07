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
import { DEFAULT_LIMITS, Desk, SOURCE_KIND } from './core.js'
import { BACKGROUND_LIMIT, backgroundFacts, loadCandidates, openMemoryDb } from './topics.js'
import { buildPrompt } from './prompt.js'
import { appendLedger, readLedger, summarize } from './ledger.js'
import { plan as decide } from './plan.js'
import { DEFAULT_TZ, minuteOfDay as zoneMinuteOfDay, startOfDay as zoneStartOfDay, zoneOr } from './tz.js'
import { classifyReply } from './classify.js'
import { gardenClass, judgeReply } from './judge.js'
import { isStock } from './stock.js'
import { capCount, nextShot, rallyStats } from './rally.js'
import { pickServeType } from './serve.js'
import { LIGHTER_TYPES, mutedUntil, serveWeights, silenceState } from './silence.js'
import { COACH_LIMITS, cleanPersona, effectiveMode, mergePersona, modeLimits, modeOr, modeServeOrder, modeSwitch, personaLines } from './persona.js'
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
import { lastReplyClass, readCommitments, readCorePersona, readMood } from './context.js'
import { cleanPhone, funToday, worthObserving } from './phone.js'
import { companionChatText, roleNames, strategistChatText } from './roles.js'
import { tide as tideOf, tideGap, tideHourly, vagueStreak } from './tide.js'
import { FACES, stepTemper, temperLine } from './temper.js'
import { drillLines, drillOf, pickDrill, scoldLines } from './drills.js'
import { brainLines, chooseFace, cleanBrain, drillScorer, observe, onReply, onServe, onSilent, revise } from './brain.js'
import { decideForce, forceLines } from './force.js'

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
  // 温和模式的最短间隔（设置页可调）。原来是 30 分钟再乘 1.5，现在直接写 45。
  minGapMs: 45 * 60_000,
  diceThreshold: 60,
  cooldownMs: 24 * 60 * 60_000,
  allowColdSession: true,
  owner: '主人',
  self: '大肥鱼',
  timeZone: DEFAULT_TZ,
  // 人格卡（口吻、口头禅、兴趣、关系、能说多狠、不碰的话题）和两种模式。
  persona: {},
  mode: 'partner',
  // 教练模式自己的频率（乒乓式高频）：最小间隔 8 分钟、每小时 6、每天 40。
  ...COACH_LIMITS,
  // 控机权限：水位到了就锁娱乐 App / 退回桌面（手机执行）。关掉就最多到浮层。
  control: true,
  // 人格卡进每一轮聊天（不只主动发球）：没有它，平时聊天里的大肥鱼就是一个普通助手。
  personaInChat: true,
  // 姐妹双人格：陪伴（妹妹，sessionId）+ 谋士（姐姐，strategistSessionId）。关掉就回到单人格大肥鱼。
  dual: true,
  strategistSessionId: undefined,
  companionName: '小肥鱼',
  strategistName: '大肥鱼',
  companionCard: '',
  strategistCard: '',
  // 做题模式：默认关，主线是聊天。说"开始做题 / 做题模式"打开，"别出题了"关掉。
  drills: false,
  // 判球可以单独配一个更快的模型；没配就沿用会话自己的 provider/model。
  judgeProvider: undefined,
  judgeModel: undefined,
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

/**
 * 最近 10 次实测耗时的中位数。发球 / 判球 / 聊天分开算：模型慢的时候，设置页要能一眼看出
 * 慢在哪一段，而不是只看到一句"没回"。
 */
function readTimings() {
  let rows = []
  try {
    rows = readLedger(home(), 400)
  } catch {
    rows = []
  }
  const median = (values) => {
    const a = values.filter((v) => Number.isFinite(v) && v >= 0).slice(0, 10).sort((x, y) => x - y)
    return a.length ? a[Math.floor(a.length / 2)] : null
  }
  // 账本本身就是时间线：generated.at - accepted.at 就是模型这一段。不依赖进程内 map，
  // 重启引擎后仍然能读出上一轮的真实耗时。
  const began = new Map()
  for (const e of rows) {
    if (!e || !e.requestId || !Number.isFinite(Number(e.at))) continue
    if (e.state === 'accepted' || e.state === 'said') began.set(String(e.requestId), Number(e.at))
  }
  const span = (state) => rows
    .filter((e) => e && e.state === state && e.requestId && began.has(String(e.requestId)))
    .map((e) => Number(e.at) - began.get(String(e.requestId)))
    .reverse() // oldest → newest; the median wants the latest ten
  const judge = rows
    .filter((e) => e && e.state === 'replied' && Number.isFinite(Number(e.judgeMs)))
    .map((e) => Number(e.judgeMs))
    .reverse()
  return {
    generate: median(span('generated')),
    judge: median(judge),
    chat: median(span('heard')),
  }
}

function memoryPath() {
  return join(home(), 'fish-memory', 'fish-memory.sqlite')
}

function gardenPath() {
  return join(home(), 'companion', 'topics.json')
}

function stateFile(name) {
  return join(home(), 'companion', name)
}

function readState(file, fallback) {
  try {
    return JSON.parse(readFileSync(file, 'utf8'))
  } catch {
    return fallback
  }
}

function writeJson(file, value) {
  try {
    mkdirSync(join(file, '..'), { recursive: true, mode: 0o700 })
    const tmp = file + '.' + String(process.pid) + '.tmp'
    writeFileSync(tmp, JSON.stringify(value) + '\n', { encoding: 'utf8', mode: 0o600 })
    renameSync(tmp, file)
  } catch (error) {
    console.error('[companion] 写 ' + file + ' 失败：' + String((error && error.message) || error))
  }
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

/** "开始做题""做题模式" → true；"别出题了""关掉做题" → false；别的 → null。 */
export function drillToggle(text) {
  const s = String(text == null ? '' : text).replace(/\s+/g, '')
  if (!s || s.length > 20) return null
  if (/(别|不要|不用|停止|关掉|关闭|停)(再)?(做题|出题)|(做题|出题)(模式)?(关掉|关了|先停)/.test(s)) return false
  if (/(开始|开启|打开|来|进入)(做题|出题)|做题模式|出(几|一)?道题/.test(s)) return true
  return null
}

function userMessage(text) {
  return { id: randomUUID(), role: 'user', content: [{ type: 'text', text }], source: { kind: SOURCE_KIND } }
}

/**
 * 判球用哪个模型：跟当前会话自己的选择走（它自己的人格和历史也都在那个会话里）。
 * 拿不到就返回 undefined —— 判球会退回本地规则，不会因为没模型就卡住。
 */
function judgeTargetOf(ctx, sessionId, config) {
  // 单独配的判球模型优先：判球只有 6 秒预算，不值得排在会话那个慢模型后面。
  const jp = config?.judgeProvider
  const jm = config?.judgeModel
  if (typeof jp === 'string' && jp && typeof jm === 'string' && jm) return { provider: jp, model: jm }
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

  // ---------------------------------------------------------------- 大脑
  // 大脑和脾气各存一个小文件；读坏了就从空的开始，绝不让一轮卡住。
  /** sessionId -> 他最后一次亲口说话的时间：正在聊就不用主动发球。 */
  const lastHumanAt = new Map()
  /** 他说完这么久之内算"正在聊"。 */
  const IN_CONVERSATION_MS = 3 * 60_000

  /** 他正在跟大肥鱼说话（刚说过，或者大肥鱼正在回他）。 */
  function inConversation(sessionId, now) {
    for (const id of sessionIds(sessionId)) {
      if (now - (lastHumanAt.get(id) || 0) < IN_CONVERSATION_MS) return true
    }
    return liveAgent(ctx, sessionId)?.status === 'running'
  }

  /** 讲通了理由之后松多久。 */
  const GRACE_MS = 20 * 60_000
  const loadBrain = () => cleanBrain(readState(stateFile('brain.json'), null))
  const saveBrain = (b) => writeJson(stateFile('brain.json'), b)
  /** requestId -> 发球时的现状（generated 时交给大脑开始计"有没有拉回来"）。 */
  const servedContext = new Map()
  /** requestId -> first seen moment, for the median latencies in /status (P6). */
  const startedAt = new Map()

  function hourOf(phone, now) {
    if (phone?.local) return Number(phone.local.slice(0, 2))
    return Math.floor(zoneMinuteOfDay(now, zoneOr(config.timeZone)) / 60)
  }

  /** 这一刻他陷得多深：手机现状 + 账本（连着没接、连着糊弄）。顺带让大脑看一眼上一球有没有把他拉回来。 */
  function sense(phone, entries, sessionId, now) {
    const brain = loadBrain()
    const pulled = observe(brain, { phone, now })
    if (pulled) {
      revise(brain, now)
      record({ state: 'pulled', at: now, pulled: pulled.pulled, face: pulled.face, band: pulled.band })
    }
    const silence = silenceState(entries, { sessionId, now })
    const vague = vagueStreak(entries)
    const water = tideOf({ phone, noTake: silence.noTake, vague, hour: hourOf(phone, now) })
    return { brain, silence, vague, water }
  }

  /** 上一道思维题怎么样了：没回 / 答糊弄了，这一球就要说他。 */
  function lastDrillOutcome(entries, now) {
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      const e = entries[i]
      if (e?.state !== 'generated') continue
      if (!e.drill) return null
      const reply = entries.find((x) => x?.requestId === e.requestId && x.state === 'replied')
      if (reply) return { drill: e.drill, requestId: e.requestId, verdict: reply.verdict, answer: reply.answer }
      if (now - Number(e.at) >= 5 * 60_000) return { drill: e.drill, requestId: e.requestId, silent: true }
      return null
    }
    return null
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

  /** 最近一小时发出去几条：阶梯能压过 minGap，靠这个兜住频率。回合里接着打的不算（见 capCount）。 */
  function sentLastHour(entries, now) {
    return capCount(entries, Number(now) - 3_600_000)
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

  /** 上一球是什么类型（观察球不连着打）。 */
  function lastServeType(entries) {
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      const e = entries[i]
      if (e?.state === 'generated') return String(e.serveType || '')
    }
    return ''
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

  async function compose(req, sessionId) {
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
      // 没有话题照样开口：用手边的情况、人设起话头。话题只是素材，不是开口的前提。
      if (topic) markUsed(garden, topic.id, now)
      persistGarden()

      const mood = readMood(home())
      // 没接球时不砸同一类：走阶梯就只挑更轻的球，平时按权重挑（被漠视的降、接住的升）。
      const silence = silenceState(entries, { sessionId, now })
      const lighter = silence.stage === 'lighter' || silence.stage === 'channel'
      // 模式决定从哪几种球里挑：伙伴偏闲聊/记忆，教练偏观察/挑衅。前三种里挑。
      const mode = effectiveMode(config, now)
      // 手边的情况由手机在 /request 里带来；没带就是不知道，观察球就不打（没东西可观察只能编）。
      const phone = cleanPhone(req?.phone)
      const order = modeServeOrder(mode).filter((t) => t !== 'observe' || phone)
      const picked = pickServeType(entries, Math.floor(Math.random() * 100), {
        only: lighter ? LIGHTER_TYPES : order.slice(0, 3),
        weights: serveWeights(entries),
      })
      // 正开着娱乐 App 一阵子了：这一球就打观察（"你在 B站 20 分钟了"），上一球已经是观察就不连着打。
      let serveType = !lighter && worthObserving(phone) && lastServeType(entries) !== 'observe' ? 'observe' : picked

      // 大脑：水位 → 脾气 → 脸色（Thompson 挑招）→ 力度 → 要不要出思维题。
      const { brain, water } = sense(phone, entries, sessionId, now)
      const temper = stepTemper(readState(stateFile('temper.json'), null), {
        mode, tide: water.level, noTake: silence.noTake, mood: mood ? mood.mood : undefined, now,
      })
      writeJson(stateFile('temper.json'), { edge: temper.edge, at: temper.at })
      const faceId = chooseFace(brain, { band: water.band, face: temper.face, surprise: temper.surprise })
      const face = { ...temper, ...(FACES.find((f) => f.face === faceId) || {}), face: faceId }
      const force = decideForce({
        phone, tide: water, mode, noTake: silence.noTake, control: config.control !== false, funToday: funToday(phone),
        grace: Number(brain.graceUntil) > now,
      })
      // 上一题没回 / 答糊弄了：这一球必须是说他 + 同一类题重问。
      const drillsOn = config.drills === true
      const owed = drillsOn ? lastDrillOutcome(entries, now) : null
      const scold = owed ? scoldLines(drillOf(owed.drill), owed) : []
      if (owed?.silent) onSilent(brain, { requestId: owed.requestId })
      // 在娱乐 App 里越陷越可能出题；要锁的那一球一定出题（答过线才放行）。
      // 阶梯在"换更轻的球"时不随机出题（欠着的题除外）；温和模式又不知道他在干嘛时，也不凭空出题。
      const drillChance = !drillsOn ? 0
        : force.level >= 3 || scold.length ? 1
        : lighter ? 0
        : phone?.fun ? 0.45 + water.level / 200
        : mode === 'coach' ? 0.3 : 0
      const drill = Math.random() < drillChance
        ? (scold.length ? drillOf(owed.drill) : pickDrill(entries, drillScorer(brain)))
        : null
      if (drill) serveType = 'drill'
      const firstToday = recent.counts.generated === 0
      saveBrain(brain)
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
        // 人格卡：关系库人物卡打底，配置里的覆盖（两张卡合一）。
        persona: mergePersona(readCorePersona(home()), config.persona),
        mode,
        phone,
        role: config.dual === false ? undefined : 'companion',
        names: roleNames(config),
        temper: face,
        drill,
        scold,
        beliefs: brainLines(brain),
        force: forceLines(force, phone, { drill: Boolean(drill) }),
        grace: Number(brain.graceUntil) > now,
        morning: firstToday,
        owner: config.owner,
        self: config.dual === false ? config.self : roleNames(config).companion,
      })
      servedContext.set(String(req?.requestId || ''), { phone, band: water.band, face: faceId, drill: drill?.id })
      const extra = {
        tide: water.level, band: water.band, face: faceId, surprise: temper.surprise || undefined,
        drill: drill?.id, force: force.level || undefined,
      }
      return { text: prompt, prompt, topic, serveType, rallyId: rally.rallyId, shot: rally.shot, silence, extra }
    } finally {
      try {
        db?.close?.()
      } catch {
        // ignore
      }
    }
  }

  /** 最近一次 /say 带来的手机时区（没带就用配置里的）。 */
  let sayZone = ''

  // ---------------------------------------------------------------- 直接聊（/say）
  // 浮层里打的字原样作为他的话进大肥鱼的会话（不带插件来源，就是他本人说的），大肥鱼照常回，
  // 工具也不拦——跟在 App 里聊一模一样。回复从 /result 取。判球、安静、换模式这些照常认这句话。
  const chat = new Desk({
    resolveAgent: (id) => resolveAgent(ctx, id, config),
    compose: async (req) => ({ text: req.payload.text, prompt: req.payload.text }),
    // 来源必须带：引擎的会话控制器默认每条消息都有 source，没有就抛异常、这一轮根本不开（真机测出来的）。
    // 他本人打的字，就照 App 里打字的格式标成 user；rpcId 加前缀，不会和 App 的提交撞上。
    // 带上手机时区：引擎只从 user 来源的 clientTimeZone 读当地时间；不带就按引擎的 GMT，
    // 大肥鱼会在中午说"四点了快去睡"（人格测试测出来的）。
    makeMessage: (text) => ({
      id: randomUUID(), role: 'user', content: [{ type: 'text', text }],
      source: { kind: 'user', rpcId: 'dsh-go-companion-say-' + randomUUID(), clientTimeZone: zoneOr(sayZone || config.timeZone) },
    }),
    isArchived: (id) => isArchived(ctx, id),
    defaultSession: () => config.sessionId,
    limits: { ...DEFAULT_LIMITS, maxPayloadValue: 2_000 },
    allowBusy: true,
    onChange: (r) => {
      const state = { accepted: 'said', generated: 'heard', failed: 'chat-failed' }[r.state]
      const now = Date.now()
      const key = String(r.requestId)
      const began = startedAt.get(key)
      if (r.state === 'accepted') startedAt.set(key, now)
      if (state) record({ requestId: r.requestId, sessionId: r.sessionId, state, at: now, ms: began ? now - began : undefined, failure: r.failure ?? undefined })
      if (r.state !== 'accepted') startedAt.delete(key)
    },
  })

  const desk = new Desk({
    resolveAgent: (id) => resolveAgent(ctx, id, config),
    compose,
    makeMessage: userMessage,
    isArchived: (id) => isArchived(ctx, id),
    defaultSession: () => config.sessionId,
    onChange: (r) => {
      const now = Date.now()
      const key = String(r.requestId)
      const began = startedAt.get(key)
      if (r.state === 'accepted') startedAt.set(key, now)
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
        ...(r.extra && (r.state === 'accepted' || r.state === 'generated') ? r.extra : {}),
        state: r.state,
        at: now,
        ms: began ? now - began : undefined,
        text: r.text ?? undefined,
        // 套话只在生成时判：谁都能说的模板不算开口。判出来就记进账本，
        // 下一球把它打回去，P5 的评测也靠这个数。
        stock: isStock(r.text) || undefined,
        failure: r.failure ?? undefined,
        cold: r.cold === true,
      })
      if (r.state !== 'accepted') startedAt.delete(key)
      // 生成成功后等一次人的回应；2 小时内没有就记 none（有限跟进/冷却的依据）。
      if (r.state === 'generated') {
        // 大脑从这一刻开始计：10 分钟内他有没有离开那个娱乐 App。
        const served = servedContext.get(String(r.requestId))
        servedContext.delete(String(r.requestId))
        if (served) {
          const b = loadBrain()
          onServe(b, { requestId: r.requestId, phone: served.phone, band: served.band, face: served.face, drill: served.drill, at: Date.now() })
          saveBrain(b)
        }
        // 发球原文、回合、拍数都留给判球用：回球回来时要能把它和这一球对上。
        setPending(r.sessionId, {
          requestId: r.requestId,
          topicId: r.topicId,
          rallyId: r.rallyId,
          shot: r.shot,
          serveType: r.serveType,
          drill: r.extra?.drill,
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
      chat.onSessionEvent(session?.id, event)
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
        lastHumanAt.set(String(session?.id || ''), Date.now())
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
        // "开始做题 / 做题模式"打开做题，"别出题了"关掉。
        const drillSwitch = drillToggle(text)
        if (drillSwitch !== null) {
          config = { ...config, drills: drillSwitch }
          try {
            writeConfig(config)
          } catch {
            // 写不进去也不影响这一轮
          }
          record({ state: 'drills', at: Date.now(), on: drillSwitch })
        }
        const pending = takePending(session?.id)
        if (pending) {
          // 这一球由大肥鱼自己判（6 秒超时或连不上就退回规则），不再按字数。
          const target = judgeTargetOf(ctx, session?.id, config)
          const judgeBegan = Date.now()
          const judged = await judgeReply({
            stream: streamOf(),
            provider: target?.provider,
            model: target?.model,
            sessionId: session?.id,
            serve: pending.serve,
            reply: text,
            recent: recentShots(),
            criteria: drillOf(pending.drill)?.pass,
            mode: effectiveMode(config, Date.now()),
          })
          const judgeMs = Date.now() - judgeBegan
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
            judgeMs,
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
          // 大脑记账：思维题过没过线、这张脸有没有把他拉回来；证据变了就改判断。
          {
            const b = loadBrain()
            onReply(b, { requestId: pending.requestId, verdict: judged.verdict })
            // 他讲了站得住的理由（真反驳）：先松一会儿，这段时间不锁。讲得通就该被听进去。
            if (judged.verdict === 'pushback') {
              b.graceUntil = now + GRACE_MS
              record({ state: 'grace', at: now, until: b.graceUntil, why: judged.why || undefined })
            }
            revise(b, now)
            saveBrain(b)
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
      if (agent?.id) {
        desk.onAgentGone(agent.id)
        chat.onAgentGone(agent.id)
      }
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

  // ---------------------------------------------------------------- 人格进每一轮聊天
  // 人格卡以前只在主动发球那一球里带给模型；他在 App 里或浮层里正常聊，模型拿不到，
  // 人格就只剩会话自带的设定（新装就是通用助手）。这里给目标会话挂一段固定的系统上下文，
  // 和记忆插件同一个机制（systemPrompt.context），每轮都带，不改历史、不破坏前缀缓存之外的东西。
  /** 单人格时代的说法（dual 关掉时用）。 */
  function singlePersonaText(mode) {
    const lines = ['你是' + String(config.self || '大肥鱼') + '，' + String(config.owner || '他') + '身边的伙伴，不是客服也不是工具。']
    for (const l of personaLines(mergePersona(readCorePersona(home()), config.persona), mode)) lines.push(l)
    lines.push(
      '聊天时：像朋友那样说话，短、直接、有自己的判断；他在解释为什么这样，先用自己的话复述你理解的理由，再表态——' +
        '站得住就认，站不住就具体说哪里站不住；别只重复立场，也别一被反驳就全盘让步。',
    )
    lines.push('答应他的事要真的做到：要定时提醒就用提醒工具真的设好，并说清楚到点是怎么提醒的；做不到的（比如替他数着打了几把）就别答应。不要假装记得没发生过的事；不知道就说不知道。')
    return lines.join('\n')
  }
  function chatPersonaText(role) {
    if (config.personaInChat === false) return ''
    const mode = effectiveMode(config, Date.now())
    if (config.dual === false) return singlePersonaText(mode)
    if (role === 'strategist') {
      // 关系库人物卡（价值观/底线/边界）是姐姐的底子。
      const core = personaLines(mergePersona(readCorePersona(home()), {}), mode).filter((l) => !/^现在是(伙伴|教练)模式/.test(l))
      return strategistChatText(config, core)
    }
    const extra = mode === 'coach' ? ['他现在开了严格模式：你可以更凶、更不依不饶，但还是你自己的样子。'] : []
    return companionChatText(config, extra)
  }
  /** role -> {sid, agent, off}：两个会话各挂各的人设。 */
  const personaMounts = new Map()
  function mountOne(role, sid) {
    const cur = personaMounts.get(role) || { sid: '', agent: null, off: null }
    const agent = sid ? liveAgent(ctx, sid) : null
    if (cur.agent === (agent || null) && cur.sid === sid) return
    try {
      cur.off?.()
    } catch {
      // ignore
    }
    const next = { sid, agent: agent || null, off: null }
    personaMounts.set(role, next)
    if (!agent?.ctx?.systemPrompt?.context) return
    try {
      const off = agent.ctx.systemPrompt.context({
        name: role === 'strategist' ? 'dafeiyu-strategist' : 'dafeiyu-persona',
        order: 850,
        interpolate: false,
        text: () => chatPersonaText(role),
      })
      if (typeof off === 'function') next.off = off
    } catch (error) {
      console.error('[companion] 人格挂不上（' + role + '）：' + String((error && error.message) || error))
    }
  }
  function mountPersona() {
    mountOne('companion', config.sessionId || '')
    const strat = config.dual === false ? '' : config.strategistSessionId || ''
    // 两个角色指向同一个会话时，只挂陪伴那一份，别让模型同时拿到两套人设。
    mountOne('strategist', strat && strat !== config.sessionId ? strat : '')
  }
  try {
    mountPersona()
  } catch {
    // agents may not be up yet; the timer retries
  }
  const personaTimer = setInterval(() => {
    try {
      mountPersona()
    } catch {
      // never break the engine
    }
  }, 2_000)
  personaTimer.unref?.()
  ctx.effect?.(() => () => clearInterval(personaTimer))

  const sweeper = setInterval(() => {
    desk.sweep()
    const now = Date.now()
    for (const [sid, pending] of [...pendingReply]) {
      if (now - pending.at < REPLY_WINDOW_MS) continue
      record({ requestId: pending.requestId, sessionId: sid, topicId: pending.topicId, state: 'none', at: now })
      if (pending.drill) {
        const b = loadBrain()
        onSilent(b, { requestId: pending.requestId })
        revise(b, now)
        saveBrain(b)
      }
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
      if (req.method === 'POST' && (path === '/request' || path === '/cancel' || path === '/config' || path === '/plan' || path === '/outcome' || path === '/say')) {
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
          // Start the clock here, not in the Desk callback: the accepted callback is not the only
          // entry point and this is the one moment that is certainly before the model runs.
          const rid = String(body.value?.requestId ?? '')
          if (rid) startedAt.set(rid, Date.now())
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
        if (path === '/say') {
          const said = String(body.value?.text ?? '').trim()
          if (typeof body.value?.timeZone === 'string' && body.value.timeZone) sayZone = body.value.timeZone
          if (!said) return send(res, 400, { v: 1, error: { code: 'empty', message: 'text' } })
          const id = typeof body.value?.requestId === 'string' && body.value.requestId ? body.value.requestId : 'say-' + randomUUID()
          startedAt.set(id, Date.now())
          // role=strategist：这句话给姐姐（谋士会话）；默认给妹妹（陪伴会话）。
          const toStrategist = body.value?.role === 'strategist' && config.dual !== false && config.strategistSessionId
          const r = await chat.request({
            v: 1, requestId: id, eventId: id, kind: 'say', payload: { text: said.slice(0, 2_000) }, deadlineMs: 120_000,
            ...(toStrategist ? { sessionId: config.strategistSessionId } : {}),
          })
          return send(res, r.status, r.body)
        }
        if (path === '/outcome') return send(res, 200, outcomeRoute(body.value))
        config = mergeConfig(config, body.value)
        writeConfig(config)
        // 换了会话 / 名字 / 人设：马上重挂，不等下一次定时检查。
        try {
          mountPersona()
        } catch {
          // ignore
        }
        return send(res, 200, { v: 1, sessionId: config.sessionId ?? null, config: publicConfig() })
      }
      if (req.method === 'GET' && path === '/result') {
        const waitMs = Math.min(Math.max(Number(url.searchParams.get('waitMs') ?? 0) || 0, 0), 25_000)
        const id = String(url.searchParams.get('requestId') ?? '')
        const r = await (chat.records.has(id) ? chat : desk).wait(id, waitMs)
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
      coachMinGapMs: config.coachMinGapMs,
      coachHourlyMax: config.coachHourlyMax,
      coachDailyMax: config.coachDailyMax,
      allowColdSession: config.allowColdSession,
      owner: config.owner,
      self: config.self,
      timeZone: config.timeZone,
      // 首页的一键安静：App 直接把要静音到的时间写进来。
      muteUntil: Number(config.muteUntil) || 0,
      // 人格卡与模式：首页可以编辑，引擎只管用。
      persona: cleanPersona(config.persona),
      // 实际进 prompt 的那张：关系库人物卡 + 上面的覆盖。
      personaEffective: mergePersona(readCorePersona(home()), config.persona),
      // 判球模型（没配就是 null，表示沿用会话）。
      judgeProvider: config.judgeProvider || null,
      judgeModel: config.judgeModel || null,
      // 最近 10 次的实测耗时：发球 / 判球 / 聊天。设置页显示中位数，一眼看出是不是模型慢。
      timings: readTimings(),
      control: config.control !== false,
      drills: config.drills === true,
      personaInChat: config.personaInChat !== false,
      dual: config.dual !== false,
      strategistSessionId: config.strategistSessionId ?? null,
      companionName: roleNames(config).companion,
      strategistName: roleNames(config).strategist,
      companionCard: config.companionCard || '',
      strategistCard: config.strategistCard || '',
      // 大脑现在对他的判断（会随证据改）和脾气的底色。
      beliefs: Object.values(loadBrain().beliefs || {}).map((b) => b.text),
      temper: readState(stateFile('temper.json'), null),
      mode: modeOr(config.mode),
      modeUntil: Number(config.modeUntil) || 0,
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
    // 手机每次问 /plan 都带上现状：水位决定节奏和力度，大脑顺带判上一球有没有把他拉回来。
    const phone = cleanPhone(body?.phone)
    const mind = sense(phone, ledger, sessionId, now)
    saveBrain(mind.brain)
    const water = mind.water
    const mode = effectiveMode(config, now)
    const limits = modeLimits(config, mode)
    const force = decideForce({
      phone, tide: water, mode, noTake: silence.noTake, control: config.control !== false, funToday: funToday(phone),
      grace: Number(mind.brain.graceUntil) > now,
    })
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
      // 教练模式更勤，伙伴更松；再按水位收紧：陷得越深越勤，间隔带随机，不让他摸出规律。
      // 在沉 / 陷住了就不掷骰子：该开口就开口。
      config: {
        ...config,
        ...limits,
        minGapMs: tideGap(limits.minGapMs, water.band),
        hourlyMax: tideHourly(limits.hourlyMax, water.band),
        diceThreshold: water.band === 'sink' || water.band === 'trap' ? 100
          : water.band === 'slide' ? Math.max(80, Number(config.diceThreshold) || 0) : config.diceThreshold,
      },
      now,
      tz,
      topic,
      sentToday: capCount(ledger, startOfDay(now, tz)),
      sentLastHour: sentLastHour(ledger, now),
      lastAt: recent.lastAt,
      roll: body?.roll,
      silence,
      mutedUntil: Number(config.muteUntil) || 0,
      nextTopicAt: nextTopicAt(garden, now),
      free: true,
    })
    // 他正在跟大肥鱼聊：不发主动球（发了也只会撞上"正忙"）。力度照常给手机——在游戏里边玩边聊也得锁。
    // 有一球正在路上（接下了、还没生成完）：再说开口就会连发两球（手机每次切 App 都会问一次）。
    desk.sweep()
    if (out.speak && desk.inFlight()) {
      Object.assign(out, { speak: false, reason: 'in-flight', nextCheckAt: now + 60_000 })
    }
    if (out.speak && inConversation(sessionId, now)) {
      Object.assign(out, { speak: false, reason: 'in-conversation', nextCheckAt: now + IN_CONVERSATION_MS })
    }
    // 一早第一球：今天还没开过口、屏幕亮着——不等骰子和间隔，先开球定今天的锚。
    if (!out.speak && (out.reason === 'dice' || out.reason === 'cooldown') && recent.counts.generated === 0 && phone?.screenOn && !inConversation(sessionId, now)) {
      Object.assign(out, { speak: true, reason: 'morning', nextCheckAt: now })
    }
    // 力度到了"锁 / 赶"：不管这一球说不说，手机都要执行（说到做到）。
    if (force.level >= 3) out.nextCheckAt = Math.min(Number(out.nextCheckAt) || now, now + 60_000)
    return {
      v: 1, ...out, silence, sessionId,
      tide: { level: water.level, band: water.band, why: water.why },
      // release：只有他讲通了（宽限期内）才放行大肥鱼加的锁。力度掉到 3 以下不等于放行——
      // 锁屏页一弹，前台就是 DSH 自己；赶回桌面后前台是桌面，这时力度本来就是 0。
      force: { level: force.level, name: force.name, why: force.why, app: phone?.app || undefined,
        release: Number(mind.brain.graceUntil) > now },
    }
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
      // 首页直接读这两项（不必再拆 config）：判球模型和最近 10 次的实测耗时。
      judgeProvider: config.judgeProvider || null,
      judgeModel: config.judgeModel || null,
      timings: readTimings(),
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
    if (Number.isFinite(Number(body.coachMinGapMs))) next.coachMinGapMs = Math.max(60_000, Math.min(6 * 3_600_000, Number(body.coachMinGapMs)))
    if (Number.isFinite(Number(body.coachHourlyMax))) next.coachHourlyMax = Math.max(0, Math.min(20, Math.round(Number(body.coachHourlyMax))))
    if (Number.isFinite(Number(body.coachDailyMax))) next.coachDailyMax = Math.max(0, Math.min(120, Math.round(Number(body.coachDailyMax))))
    if (Number.isFinite(Number(body.minGapMs))) next.minGapMs = Math.max(60_000, Math.min(24 * 3_600_000, Number(body.minGapMs)))
    if (Number.isFinite(Number(body.diceThreshold))) next.diceThreshold = Math.max(0, Math.min(100, Number(body.diceThreshold)))
    if (typeof body.allowColdSession === 'boolean') next.allowColdSession = body.allowColdSession
    if (typeof body.control === 'boolean') next.control = body.control
    if (typeof body.drills === 'boolean') next.drills = body.drills
    if (typeof body.personaInChat === 'boolean') next.personaInChat = body.personaInChat
    if (typeof body.dual === 'boolean') next.dual = body.dual
    if (body.strategistSessionId === null) next.strategistSessionId = undefined
    else if (typeof body.strategistSessionId === 'string' && body.strategistSessionId.length <= 256) next.strategistSessionId = body.strategistSessionId || undefined
    for (const k of ['companionName', 'strategistName']) if (typeof body[k] === 'string' && body[k].trim()) next[k] = body[k].trim().slice(0, 20)
    for (const k of ['companionCard', 'strategistCard']) if (typeof body[k] === 'string') next[k] = body[k].slice(0, 4000)
    if (typeof body.owner === 'string' && body.owner.trim()) next.owner = body.owner.trim().slice(0, 40)
    if (typeof body.self === 'string' && body.self.trim()) next.self = body.self.trim().slice(0, 40)
    if (typeof body.timeZone === 'string' && body.timeZone.trim()) next.timeZone = zoneOr(body.timeZone)
    // 判球模型：空字符串 = 清掉，回到沿用会话。
    if (typeof body.judgeProvider === 'string') next.judgeProvider = body.judgeProvider.trim().slice(0, 80) || undefined
    if (typeof body.judgeModel === 'string') next.judgeModel = body.judgeModel.trim().slice(0, 120) || undefined
  }
  return next
}
