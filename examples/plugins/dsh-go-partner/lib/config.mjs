/**
 * partner 的配置 —— **宿主注入的 config 是唯一配置源**
 *
 * 上一轮的注释说「本包坚持零第三方依赖，所以只认一个 JSON 文件」，那是把结论当成了理由。
 * 真实情况（R4 第三轮查证，见 R4-M3-CONFIG.md）：
 *   · cordis 会把 profile patch 里这一行的 config 校验后作为 apply(ctx, config) 的第二个参数给插件；
 *   · DSH 的原生设置表单（设置 › 引擎参数 › 插件 / 插件详情 › 设置）通过
 *     ConfigEditor.edit() 写的就是**同一个 profile patch**（$DSH_HOME/profiles/<name>/cordis.patch.yml）；
 *   · 所以「表单」和「插件读到的值」本来就是同一条链，只要插件**真的去读注入的 config**。
 *
 * 因此现在只有一套配置：
 *   1. 在 DSH 里跑（apply 拿到了 config）→ **只认宿主注入的 config**；
 *   2. 没有宿主（单元测试、CLI 探针、网页预览）→ 退回 ~/.dsh/partner/config.json。
 * 两套不会同时生效，面板上会写明当前生效的是哪一套（cfg.__source）。
 *
 * 旧的 config.json 如果还在，**不再参与运行**，只在面板上提示一句「它已经不生效了，请把值填进原生表单」——
 * 静默忽略会让用户以为自己设过的东西生效了，那种错误比没有设置更糟。
 *
 * 三个模块**互相独立**：任何一个 enabled=false，它就既不进面板、也不进系统提示、
 * 也不注册工具的执行，其余两个照常。
 */
import fs from 'node:fs'
import path from 'node:path'
import os from 'node:os'

/** 延迟读：模块级 const 会在 import 那一刻定死，测试里换 DSH_HOME 就不生效了。 */
export const dshHome = () => process.env.DSH_HOME || path.join(os.homedir(), '.dsh')

/** partner 自己的数据目录（只写这里，绝不去改 fish-memory / feiyu-mood 的文件）。 */
export const partnerDir = () => path.join(dshHome(), 'partner')

export const configPath = () => process.env.DSH_PARTNER_CONFIG || path.join(partnerDir(), 'config.json')

/** 宿主注入的 config（cordis 给 apply 的那一份）。null = 当前没有宿主。 */
let liveSource = null

/**
 * 注册宿主配置源。apply() 在启动时调用；返回 disposer，卸载时清掉。
 * @param {(() => any)|null} fn 返回 cordis 校验后的 config（含 Volatile 引用）
 */
export function setLiveConfigSource(fn) {
  if (typeof fn !== 'function') {
    liveSource = null
    return () => {}
  }
  liveSource = fn
  return () => { if (liveSource === fn) liveSource = null }
}

export const hasLiveConfig = () => liveSource !== null;

export const DEFAULTS = Object.freeze({
  persona: {
    enabled: true,
    // 空 = 自动找（见 persona.mjs 的 candidates）。写了就只读这一个。
    personaFile: '',
    // 额外的表达风格约定（用户自己写的，不是模型猜的）
    style: '',
    // 主动话题偏好：她主动开口时更喜欢聊什么
    topics: [],
    // 身份卡：M2 的 identity 卡就是这一张；这里只覆盖不新建
    identityFile: '',
    sectionOrder: 100,
  },
  memory: {
    enabled: true,
    /** 短期记忆的时间窗（小时）：这段时间内记下的算「刚刚记住的」 */
    shortTermHours: 24,
    /** 检索默认返回条数 */
    recallLimit: 6,
    /** 检索最低分（0–1），低于它不返回 */
    recallFloor: 0.12,
    /** 一页记忆面板最多画多少行 */
    panelLimit: 40,
  },
  mood: {
    enabled: true,
    /** 把此刻心情作为上下文交给 Agent */
    inject: true,
    contextOrder: 880,
    /** 时间线最多画几条 */
    timelineLimit: 8,
  },
  tools: {
    /** 注册 partner_recall / partner_remember / partner_correct / partner_mood */
    enabled: true,
  },
  /** 常驻系统提示：告诉她「你自己有记忆和情绪」 */
  hint: { enabled: true, sectionOrder: 89990 },
})

function clone(v) {
  if (Array.isArray(v)) return v.map(clone)
  if (v && typeof v === 'object') {
    const out = {}
    for (const k of Object.keys(v)) out[k] = clone(v[k])
    return out
  }
  return v
}

function merge(base, patch) {
  // ⚠️ 必须**新拷贝**：DEFAULTS 是 Object.freeze 的，直接返回它再写 __file 会抛
  //   「Cannot add property __file, object is not extensible」—— 这个 bug 只在「没有配置文件」时出现，
  //   也就是**刚装上的第一台机器**，最容易被漏测。
  if (!patch || typeof patch !== 'object' || Array.isArray(patch)) return clone(base)
  const out = { ...base }
  for (const [k, v] of Object.entries(patch)) {
    if (v === undefined) continue
    const cur = out[k]
    if (cur && typeof cur === 'object' && !Array.isArray(cur) && v && typeof v === 'object' && !Array.isArray(v)) {
      out[k] = merge(cur, v)
    } else if (Array.isArray(cur)) {
      out[k] = Array.isArray(v) ? v.slice() : cur
    } else if (typeof cur === 'boolean') {
      out[k] = Boolean(v)
    } else if (typeof cur === 'number') {
      const n = Number(v)
      out[k] = Number.isFinite(n) ? n : cur
    } else if (typeof cur === 'string') {
      out[k] = typeof v === 'string' ? v : String(v)
    } else {
      out[k] = v
    }
  }
  return out
}

/**
 * 把 cordis 给的 config 摊平成纯值：volatile 字段是引用对象（{ get() }），
 * 每次读都要现取，才能做到「表单改了立刻生效，不用重启」。
 */
export function unwrapLive(value) {
  if (value === null || value === undefined) return value
  if (typeof value === 'object' && typeof value.get === 'function' && typeof value[Symbol.for('cosmokit.volatile.write')] === 'function') {
    return unwrapLive(value.get())
  }
  if (Array.isArray(value)) return value.map(unwrapLive)
  if (typeof value === 'object') {
    const out = {}
    for (const k of Object.keys(value)) out[k] = unwrapLive(value[k])
    return out
  }
  return value
}

function readFileRaw(file) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''))
  } catch {
    return null
  }
}

/**
 * 读配置。永远返回一个完整对象，永不抛错 ——
 * 配置坏了不能让插件整个起不来，那样用户连「出问题了」都看不到。
 *
 * 优先级：宿主注入的 config（唯一真相）> 没有宿主时才读 JSON 文件。
 * @returns {object} 带 __source（'host' / 'file'）、__file、__legacy、__ok、__reason 的完整配置
 */
export function loadConfig(file = configPath()) {
  let live = null
  if (liveSource) {
    try { live = unwrapLive(liveSource()) } catch { live = null }
  }
  if (live && typeof live === 'object' && !Array.isArray(live)) {
    const cfg = merge(DEFAULTS, live)
    cfg.__source = 'host'
    cfg.__file = file
    cfg.__ok = true
    cfg.__reason = ''
    // 旧文件还在、而且确实有内容 —— 如实告诉用户它已经不生效了，不静默忽略
    const legacy = readFileRaw(file)
    cfg.__legacy = legacy && Object.keys(legacy).length ? file : ''
    return cfg
  }
  const raw = readFileRaw(file)
  const cfg = merge(DEFAULTS, raw)
  cfg.__source = 'file'
  cfg.__file = file
  cfg.__ok = raw !== null
  cfg.__legacy = ''
  cfg.__reason = raw !== null ? '' : (fs.existsSync(file) ? 'unreadable' : 'missing')
  return cfg
}

/** 三个模块是否至少开着一个 —— 全关就什么也不注册，宿主那边干净退出。 */
export function anyModuleOn(cfg) {
  return Boolean(cfg.persona?.enabled || cfg.memory?.enabled || cfg.mood?.enabled)
}
