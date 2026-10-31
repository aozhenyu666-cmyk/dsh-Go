/**
 * dsh-go-partner —— R4 的原生界面层（只读，不写任何数据）
 *
 * 定位（这点必须守住，否则会和两个现有插件打架）：
 *   · dsh-fish-memory 负责「记」和「想」，dsh-feiyu-mood 负责「判」；
 *   · 本插件**只负责「看得见」**：把它们的 JSON 读出来，画成 DSH Go 的原生插槽。
 *   · 所以它**不注册 remember、不调模型、不改 state.json** —— 一个写者原则。
 *
 * 为什么需要它（三方仓库都没有这件事）：
 *   fish-memory / feiyu-mood 的界面都在 `client.js`（web 半端，React）。
 *   DSH Go 的原生界面**不执行插件的任何 JS**，只认 `package.json` 的 `dshGo` 清单
 *   + 宿主用 `ctx.dshGo` 推的 JSON 视图。所以不写这一层，App 里就只看得到网页模式。
 *
 * 三条硬约束（照 docs/plugins/slots.md）：
 *   1. `ctx.inject(['dshGo'], …)` —— 写 `['dshGo']`，**不要**写 `['dshGo?']`（回调永远不执行），
 *      也**不要**放进插件顶层 `inject`（没有桥接的主机上整个插件起不来）。
 *   2. 状态条 `emit` 的数据 ≤ 32KiB / 4Hz，每次给**完整**一份，`null` 等于缺失。
 *   3. 回调抛错/超时(3s)/返回不合格 → 记一次违规；连续 5 次本次运行降级成网页版。
 */

import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'

import { moodPanel, memoryPanel, purposePanel, stripData, validate } from './views.mjs'

// ── 配置（插件导出的 Config 会画成 App 原生设置表单）────────────────────────
// 只放「本包自己的」开关；记忆/心情的参数在各自插件里改，这里不重复一套。
export const Config = undefined // 见 §为什么不用 schemastery —— 见 README「已知取舍」

// ⚠️ 必须**延迟读**：写成模块级 const 就等于在 import 那一刻定死，
//    之后改 process.env.DSH_HOME 不生效（测试里直接踩到），换主机/换 profile 也接不住。
const dshHome = () => process.env.DSH_HOME || path.join(os.homedir(), '.dsh')

function readJson(p) {
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, ''))
  } catch {
    return null
  }
}

function statSig(p) {
  try {
    const s = fs.statSync(p)
    return `${s.mtimeMs}:${s.size}`
  } catch {
    return 'missing'
  }
}

// ── 数据源：只读 ────────────────────────────────────────────────────────────
function moodStatePath() { return path.join(dshHome(), 'feiyu-mood', 'state.json') }
function moodConfigPath() { return path.join(dshHome(), 'feiyu-mood', 'config.json') }

/**
 * 心情：state.json 的结构是 { moods: { <slotId>: { mood, dims, timeline } } }。
 * 取哪一份：① 有 sessionId 就从 config 的 slots 里找绑了这个会话的那份；② 否则取第一份。
 * ⚠️ 两个 id 对不上时**不要猜**，把「绑没绑对」这件事显示出来 —— 这是最常见的排障点。
 */
function readMood(sessionId) {
  const state = readJson(moodStatePath())
  const cfg = readJson(moodConfigPath()) || {}
  if (!state) return { ok: false, reason: 'no-state', cfg }
  const moods = state.moods || {}
  const keys = Object.keys(moods)
  if (!keys.length) return { ok: false, reason: 'no-moods', cfg, state }

  const slots = Array.isArray(cfg.slots) ? cfg.slots : []
  let slot = null
  if (sessionId) {
    slot = slots.find((s) => Array.isArray(s.sessions) && s.sessions.includes(sessionId)) || null
  }
  if (!slot) slot = slots[0] || { id: keys[0] }
  // slot.id 与 moods 的 key 可能对不上（0.7.0 修过这个 bug，老数据仍可能错乱）
  let mood = moods[slot.id]
  let matched = Boolean(mood)
  if (!mood && keys.length === 1) { mood = moods[keys[0]]; matched = false }
  if (!mood) return { ok: false, reason: 'slot-mismatch', cfg, slot, keys }
  return { ok: true, mood, cfg, slot, matched, selfName: cfg.selfName || slot.selfName, ownerName: cfg.ownerName }
}

/**
 * 记忆：fish-memory 一个会话一个 json 文件（%USERPROFILE%\.dsh\fish-memory\<sid>.json）。
 * 形状在不同版本间有差异（memories / records / items），这里都兜住。
 */
function readMemory(sessionId) {
  const dir = path.join(dshHome(), 'fish-memory')
  let files = []
  try {
    files = fs.readdirSync(dir).filter((n) => n.endsWith('.json') && !n.endsWith('.bak'))
  } catch {
    return { ok: false, reason: 'no-dir' }
  }
  if (!files.length) return { ok: false, reason: 'empty' }

  let file = null
  if (sessionId) file = files.find((n) => n === `${sessionId}.json`) || null
  if (!file) file = files.sort((a, b) => statSig(path.join(dir, b)).localeCompare(statSig(path.join(dir, a))))[0]

  const raw = readJson(path.join(dir, file))
  if (!raw) return { ok: false, reason: 'unreadable', file }
  const list = raw.memories || raw.records || raw.items || []
  const records = (Array.isArray(list) ? list : []).map((m, i) => ({
    id: m.id || `m${i}`,
    text: m.text || m.content || '',
    title: m.title || '',
    // fish-memory 是「鲜活度」，surfcore 是「清晰度」：两者都映射到同一套显示词
    clarity: m.clarity || (typeof m.vitality === 'number'
      ? (m.vitality >= 0.66 ? 'vivid' : m.vitality >= 0.4 ? 'clear' : m.vitality >= 0.18 ? 'fuzzy' : 'trace')
      : 'clear'),
    importance: typeof m.importance === 'number' ? Math.round(m.importance * (m.importance <= 1 ? 100 : 1)) : undefined,
    createdAt: m.createdAt || m.at || m.time || '',
    tags: Array.isArray(m.tags) ? m.tags : [],
    pinned: Boolean(m.pinned || m.superseded === false),
    isInitial: Boolean(m.isInitial),
    firstMet: Boolean(m.firstMet),
  }))
  return { ok: true, file, records, raw }
}

/**
 * 目的：P2 之前不存在这个文件；面板要能优雅地「说还没做」而不是空白。
 */
function readPurpose(sessionId) {
  const candidates = [
    path.join(dshHome(), 'partner', 'purpose-outreach.json'),
    path.join(dshHome(), 'surfcore', 'state', 'purpose-outreach.json'),
  ]
  try {
    const cur = readJson(path.join(dshHome(), 'surfcore', 'characters', 'current.json'))
    if (cur?.id) candidates.unshift(path.join(dshHome(), 'surfcore', 'characters', cur.id, 'purpose-outreach.json'))
  } catch {}
  for (const p of candidates) {
    const j = readJson(p)
    if (j) return { ok: true, state: j, file: p }
  }
  return { ok: false, reason: 'not-implemented' }
}

// ── 插件本体 ────────────────────────────────────────────────────────────────
export function apply(ctx) {
  // ⚠️ 必须写 ['dshGo']；写成 ['dshGo?'] 回调永远不执行，写在顶层 inject 会在无桥接主机上整体挂掉
  ctx.inject(['dshGo'], (ctx) => {
    // ⚠️⚠️ 这里有个**很容易踩的坑**，我第一版就踩了：
    //   `view(scope, caps)` 必须是**同步**返回视图；`strip(id, dataFn)` 的 dataFn 必须是
    //   **同步**返回取消函数。用 async 包一层「保护异常」会把返回值变成 Promise ——
    //   于是 view 拿到 Promise（App 报「插件界面有误」），strip 拿到 Promise
    //   （取消函数永远调不到，定时器泄漏）。所以异常保护必须**分同步/异步两版**。
    const syncGuard = (name, fn) => (...args) => {
      try {
        return fn(...args)
      } catch (error) {
        console.error(`[partner] ${name} 失败：${error && error.message}`)
        return undefined
      }
    }
    const asyncGuard = (name, fn) => async (...args) => {
      try {
        return await fn(...args)
      } catch (error) {
        console.error(`[partner] ${name} 失败：${error && error.message}`)
        return null
      }
    }

    // ── 状态条：输入框上方一行「开心 72」────────────────────────────────
    // ⚠️ 插槽 id = `mood.strip`，**不能**也叫 `mood` —— 同一插件内所有插槽的 id 不许重复
    //    （和 panels 里的 `mood` 撞了 → App 插件详情页报「原生界面 · N 项有误」）
    ctx.dshGo.strip('mood.strip', (scope, emit) => {
      let last = ''
      const push = () => {
        const r = readMood(scope && scope.sessionId)
        const data = r.ok
          ? stripData(r.mood, { moodBase: r.cfg.moodBase, selfName: r.selfName })
          : { text: '心情未开', icon: 'question', tone: 'muted' }
        const sig = JSON.stringify(data)
        if (sig === last) return       // 没变就不推（桥接本身限 4Hz，但省一点是一点）
        last = sig
        emit(data)
      }
      push()
      const timer = setInterval(syncGuard('strip.push', push), 30_000)
      // 返回取消函数：没人看时别留定时器（必须是**同步**返回）
      return () => clearInterval(timer)
    })

    // ── 面板 1：心情 ────────────────────────────────────────────────────
    ctx.dshGo.panel('mood', {
      view: syncGuard('mood.view', (scope) => {
        const r = readMood(scope && scope.sessionId)
        if (!r.ok) {
          const why = {
            'no-state': '还没判过任何一轮。确认：①「每轮判断心情」开着 ② 会话/工作区绑对了 ③ 判断模型能用。',
            'no-moods': '一次都没判过。同上三条。',
            'slot-mismatch': '设置里的 slot id 与 state.json 里的键对不上（0.7.0 修过这个 bug，老数据可能仍是错的）。到「鱼的心情」设置页重新选一次会话即可。',
          }[r.reason] || '心情数据读不出来。'
          return { v: 1, type: 'stack', title: '心情', children: [{ type: 'callout', tone: 'warn', text: why }] }
        }
        return moodPanel(r.mood, {
          label: r.slot?.label,
          selfName: r.selfName,
          ownerName: r.ownerName,
          moodBase: r.cfg.moodBase,
          decayHalfHours: r.cfg.decayHalfHours,
          injectMode: r.cfg.injectMode,
          injectConfidence: r.cfg.injectConfidence,
          // 绑定对不上但仍只有一份记录：**显示 + 明确警告**。
          // 静默显示是错的（用户会以为绑对了）；只报错不显示也是错的（数据其实读得到）。
          bindingWarning: r.matched === false
            ? `设置里的会话与 state.json 里的记录对不上（设置：${r.slot?.id ?? '?'}，记录：${String(r.keys?.[0] ?? '?').slice(0, 8)}…）。现在显示的是唯一那份记录，但新对话可能不会进这一份 —— 到「鱼的心情」设置页重选一次会话。`
            : '',
        })
      }),
      actions: {
        refresh: asyncGuard('mood.refresh', (scope) => {
          ctx.dshGo.refresh('mood', scope)
          return { toast: '已刷新' }
        }),
        timeline: asyncGuard('mood.timeline', () => ({ toast: '完整记录在「网页模式 › 设置 › 鱼的心情」' })),
      },
    })

    // ── 面板 2：记忆 ────────────────────────────────────────────────────
    ctx.dshGo.panel('memory', {
      view: syncGuard('memory.view', (scope) => {
        const r = readMemory(scope && scope.sessionId)
        if (!r.ok) {
          const why = {
            'no-dir': '还没装 dsh-fish-memory，或者装了没跑过。',
            empty: '还没有任何会话的记忆。聊几句、说过一件明确的事，它就会自己记。',
            unreadable: '记忆文件读不出来（可能正在写入）。稍后再刷新。',
          }[r.reason] || '记忆读不出来。'
          return { v: 1, type: 'stack', title: '记忆', children: [{ type: 'callout', tone: 'warn', text: why }] }
        }
        // 容量：fish-memory 的字段名不稳定，能拿就拿，拿不到就不画进度条
        const status = r.raw?.status && typeof r.raw.status === 'object' ? r.raw.status : {}
        const chars = status.chars ?? status.charCount ?? undefined
        const warn = status.warnChars ?? status.maxChars ?? undefined
        const percent = chars && warn ? Math.min(100, Math.round((chars / warn) * 1000) / 10) : 0
        return memoryPanel({ records: r.records, status: { chars, warnChars: warn, percent, counts: { total: r.records.length } } })
      }),
      actions: {
        refresh: asyncGuard('memory.refresh', (scope) => { ctx.dshGo.refresh('memory', scope); return { toast: '已刷新' } }),
        open: asyncGuard('memory.open', () => ({ toast: '原文在网页模式里看' })),
        full: asyncGuard('memory.full', () => ({ toast: '全量存档在 P2 才接；现在只有记忆卡' })),
        export: asyncGuard('memory.export', () => ({ toast: '导出在网页模式里做' })),
      },
    })

    // ── 面板 3：目的 ────────────────────────────────────────────────────
    ctx.dshGo.panel('purpose', {
      view: syncGuard('purpose.view', () => {
        const r = readPurpose()
        if (!r.ok) {
          return {
            v: 1,
            type: 'stack',
            title: '目的',
            children: [
              { type: 'callout', tone: 'info', text: '还没做（P2）。做好之后，它会在安静时段之外、每天有限的次数里，自己找个由头来找你说话。' },
              { type: 'text', text: '在那之前，这里显示的是它的「念头」，不是定时问候。', tone: 'muted' },
            ],
          }
        }
        return purposePanel(r.state)
      }),
      actions: {
        run: asyncGuard('purpose.run', () => ({ toast: 'P2 才接；现在只能预览' })),
        preview: asyncGuard('purpose.preview', () => ({ toast: 'P2 才接' })),
      },
    })
  })
}
