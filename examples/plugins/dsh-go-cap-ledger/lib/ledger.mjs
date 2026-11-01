/**
 * cap-ledger 的纯内核：**四个状态必须分得开**，只显示插件名等于没有台账。
 *
 *   installed      已安装：这个包在磁盘上、被 profile 选中（能看到 package.json 与入口文件）
 *   loaded         已加载：apply() 真的跑起来了（本进程里那个模块被实例化）
 *   toolRegistered 工具已注册：ctx.tools.register 返回了 disposer
 *   lastRunOk      最近一次执行：true / false / null（null = 还没跑过，**不是失败**）
 *
 * 三条不许违反的规则（都是踩过的坑）：
 *   1. **不猜**。拿不到就是 null / 'unknown'，不默认成 true。假绿比不显示更坏。
 *   2. **失败要带原因**。只有 lastRunOk=false 没有 code/message，等于没有可行动信息。
 *   3. **纯函数 + 薄 IO**。这里不碰文件系统、不碰网络、不读时间以外的外部状态，
 *      所以每条判据都能 node --test 直接验。
 *
 * 零第三方依赖。
 */

export const LEDGER_VERSION = 2

/** 六态的名字，给外面做遍历/校验用（顺序 = 面板上的显示顺序）。 */
/**
 * 六态（每一态是一个独立事实，任何一态都不能被别的态顶替）：
 *   installed      已安装：包在磁盘上、被 profile 选中
 *   loaded         已加载：apply() 真的跑起来了
 *   toolRegistered 工具已注册：ctx.tools.register 返回了 disposer
 *   available      可用：同时满足 installed + loaded + toolRegistered
 *   executed       真的执行过（runs > 0）—— 「跑过没有」和「跑得对不对」是两件事
 *   failed         执行过且失败：lastRunOk === false
 *
 * 另有一个**只有跑过且成功**才成立的 derived 标志 verified：
 * 「已加载 / 可以调用」不等于「验证过能跑」。没跑过的插件必须显示
 * 「尚未验证实际执行」，不许算成健康 —— 假绿比不显示更坏。
 */
export const STATES = ['installed', 'loaded', 'toolRegistered', 'available', 'executed', 'failed']

/** 一个插件的空台账。字段全在，缺的显式写 null。 */
export function emptyEntry(plugin = '') {
  return {
    plugin: String(plugin),
    installed: null,
    loaded: null,
    toolRegistered: null,
    available: null,
    executed: null,
    failed: null,
    verified: null,
    lastRunOk: null,
    lastRunAt: null,
    lastRunCode: null,
    lastRunMessage: null,
    runs: 0,
    fails: 0,
    updatedAt: null,
  }
}

/** 一整份台账。 */
export function emptyLedger() {
  return { v: LEDGER_VERSION, plugins: {}, updatedAt: null }
}

const isObject = (v) => typeof v === 'object' && v !== null && !Array.isArray(v)
const tri = (v) => (v === true || v === false ? v : null)
const nonNegInt = (v) => (Number.isInteger(v) && v >= 0 ? v : 0)
const text = (v) => (typeof v === 'string' && v !== '' ? v : null)

/**
 * 规整一条插件台账。**不信任任何输入**：类型不对退回默认，不抛。
 * @param {unknown} raw
 * @param {string} [plugin] 兜底的插件名
 */
export function normalizeEntry(raw, plugin = '') {
  const out = emptyEntry(plugin)
  if (!isObject(raw)) return out
  out.plugin = text(raw.plugin) ?? String(plugin)
  out.installed = tri(raw.installed)
  out.loaded = tri(raw.loaded)
  out.toolRegistered = tri(raw.toolRegistered)
  out.lastRunOk = tri(raw.lastRunOk)
  out.lastRunAt = Number.isFinite(raw.lastRunAt) ? raw.lastRunAt : null
  out.lastRunCode = text(raw.lastRunCode)
  out.lastRunMessage = text(raw.lastRunMessage)
  out.runs = nonNegInt(raw.runs)
  out.fails = Math.min(nonNegInt(raw.fails), nonNegInt(raw.runs))
  out.updatedAt = Number.isFinite(raw.updatedAt) ? raw.updatedAt : null
  // 后三态**由前面的字段算出来**，不信任入参，也不许手写
  out.executed = out.runs > 0 ? true : null
  out.failed = out.runs > 0 ? out.lastRunOk === false : null
  out.available = out.installed === true && out.loaded === true && out.toolRegistered === true
    ? true
    : (out.installed === false || out.loaded === false || out.toolRegistered === false ? false : null)
  // verified：只有「真跑过且上次成功」才成立。没跑过 = null（尚未验证），不是 true。
  out.verified = out.runs > 0 && out.lastRunOk === true ? true : null
  // 「还没跑过」和「失败」是两件事：runs=0 时 lastRunOk 只能是 null
  if (out.runs === 0) {
    out.lastRunOk = null
    out.lastRunAt = null
    out.lastRunCode = null
    out.lastRunMessage = null
  }
  // 失败的记录必须带原因（老数据/手工写坏时补一句，而不是留一个空）
  if (out.lastRunOk === false && out.lastRunCode === null) out.lastRunCode = 'E_UNKNOWN'
  return out
}

/**
 * 规整一整份台账（磁盘上的旧文件 / 测试里造的假数据都走这里）。
 * @param {unknown} raw
 */
export function normalizeLedger(raw) {
  const out = emptyLedger()
  if (!isObject(raw)) return out
  if (raw.v !== LEDGER_VERSION) return out
  if (isObject(raw.plugins)) {
    for (const [name, entry] of Object.entries(raw.plugins)) {
      if (name === '') continue
      out.plugins[name] = normalizeEntry(entry, name)
    }
  }
  out.updatedAt = Number.isFinite(raw.updatedAt) ? raw.updatedAt : null
  return out
}

/** 取一条（没有就建一条空的，不自动写回）。 */
export function entryOf(ledger, plugin) {
  const l = normalizeLedger(ledger)
  return l.plugins[plugin] ?? emptyEntry(plugin)
}

/** 就地写入一条（调用方持有单例，所以这里改的是同一份）。 */
export function putEntry(ledger, entry) {
  const e = normalizeEntry(entry, entry?.plugin)
  ledger.plugins[e.plugin] = e
  ledger.updatedAt = e.updatedAt ?? ledger.updatedAt
  return ledger
}

/**
 * 记「已安装」—— 判定依据是**看得见这个包**（package.json 与入口文件都在）。
 * @param {object} entry
 * @param {{ ok: boolean, at?: number }} evidence
 */
export function markInstalled(entry, evidence) {
  entry.installed = evidence?.ok === true
  entry.updatedAt = Number.isFinite(evidence?.at) ? evidence.at : entry.updatedAt
  return entry
}

/**
 * 记「已加载」—— 判定依据是 apply() 真的执行到了这里。
 * @param {object} entry
 * @param {{ at?: number }} [evidence]
 */
export function markLoaded(entry, evidence = {}) {
  entry.loaded = true
  entry.updatedAt = Number.isFinite(evidence.at) ? evidence.at : entry.updatedAt
  return entry
}

/**
 * 记「工具已注册」—— 判定依据是 register() **返回了 disposer**，
 * 不是「我调用过 register」。调了但抛错 = false。
 * @param {object} entry
 * @param {{ ok: boolean, error?: string, at?: number }} evidence
 */
export function markToolRegistered(entry, evidence) {
  entry.toolRegistered = evidence?.ok === true
  if (entry.toolRegistered === false && typeof evidence?.error === 'string' && evidence.error !== '') {
    // 注册失败本身就是一次「最近一次不成功」，原因要落下来
    entry.lastRunOk = false
    entry.lastRunCode = 'E_REGISTER'
    entry.lastRunMessage = '工具注册失败：' + evidence.error
    entry.fails += 1
    entry.runs += 1
  }
  entry.updatedAt = Number.isFinite(evidence?.at) ? evidence.at : entry.updatedAt
  return entry
}

/**
 * 记「最近一次执行」。
 * @param {object} entry
 * @param {{ ok: boolean, code?: string, message?: string, at?: number }} run
 */
export function markRun(entry, run) {
  const at = Number.isFinite(run?.at) ? run.at : Date.now()
  entry.runs += 1
  entry.lastRunOk = run?.ok === true
  entry.lastRunAt = at
  if (entry.lastRunOk) {
    // 成功后不该还挂着上一次的错误码
    entry.lastRunCode = null
    entry.lastRunMessage = null
  } else {
    entry.lastRunCode = text(run?.code) ?? 'E_UNKNOWN'
    entry.lastRunMessage = text(run?.message) ?? '（没有给出原因）'
    entry.fails += 1
  }
  entry.updatedAt = at
  return entry
}

/**
 * 六态各自怎么读 —— 面板与状态条共用这一份，避免两处口径不一致。
 *
 * **最要紧的一条**：healthy 只给「真跑通过」的插件。
 * 装好了、加载了、工具也注册了，但一次都没执行过 —— 那叫
 * 「已加载 / 可以调用 / 尚未验证实际执行」，**不叫健康**。
 * 上一轮就是在这里把「没跑过」算成了健康，那是假绿。
 *
 * @param {object} entry
 * @returns {{ installed: string, loaded: string, toolRegistered: string, available: string,
 *   executed: string, failed: string, verified: string, lastRunOk: string,
 *   callable: boolean, healthy: boolean, usable: boolean, health: string, headline: string }}
 */
export function describeEntry(entry) {
  const e = normalizeEntry(entry, entry?.plugin)
  const yesNo = (v) => (v === true ? '是' : v === false ? '否' : '未知')
  const lastRunOk = e.runs === 0
    ? '还没跑过'
    : e.lastRunOk === true
      ? '成功'
      : '失败（' + String(e.lastRunCode) + '）'
  const available = e.available === true
    ? '能用'
    : e.available === false
      ? '不能用'
      : '未知'
  const executed = e.runs === 0 ? '还没跑过' : `跑过 ${e.runs} 次`
  const failed = e.runs === 0 ? '还没跑过' : e.failed === true ? `失败 ${e.fails} 次` : '没有失败'
  // verified 只有三种值，一个都不许含糊：没跑过 ≠ 成功
  const verified = e.runs === 0
    ? '尚未验证实际执行'
    : e.lastRunOk === true
      ? '已验证（真的跑通过）'
      : '验证过，但上次失败'

  /** 前三态齐 = 现在能调用它。这是「能不能叫」，不是「试过没有」。 */
  const callable = e.installed === true && e.loaded === true && e.toolRegistered === true
  /** 健康 = 能调用 **且** 真的跑成功过。少一样都不算。 */
  const healthy = callable && e.runs > 0 && e.lastRunOk === true

  const health = healthy
    ? 'healthy'
    : callable
      ? (e.runs === 0 ? 'callable_unverified' : 'callable_last_failed')
      : (e.installed === false || e.loaded === false || e.toolRegistered === false ? 'broken' : 'unknown')

  const headline = healthy
    ? '已加载 / 可以调用 / 已验证实际执行'
    : callable
      ? (e.runs === 0 ? '已加载 / 可以调用 / 尚未验证实际执行' : '已加载 / 可以调用 / 上次执行失败')
      : '未就绪'

  return {
    installed: yesNo(e.installed),
    loaded: yesNo(e.loaded),
    toolRegistered: yesNo(e.toolRegistered),
    available,
    executed,
    failed,
    verified,
    lastRunOk,
    callable,
    health,
    headline,
    healthy,
    // usable 保持旧语义 = 现在能不能用（前三态齐），**不等于**健康。
    usable: callable,
  }
}

/**
 * 汇总：几成插件真的**验证过能用**（给状态条一句话）。
 *
 * healthy 只数「跑成功过」的；另外单独数 callable（装上且能调用）与
 * unverified（能调用但一次都没跑）—— 三个数分开报，不许把后两者并进 healthy。
 */
export function summarize(ledger) {
  const l = normalizeLedger(ledger)
  const names = Object.keys(l.plugins)
  const total = names.length
  let healthy = 0
  let failing = 0
  let callable = 0
  let unverified = 0
  for (const name of names) {
    const d = describeEntry(l.plugins[name])
    if (d.healthy) healthy += 1
    if (d.callable) callable += 1
    if (d.health === 'callable_unverified') unverified += 1
    if (l.plugins[name].lastRunOk === false) failing += 1
  }
  return { total, healthy, failing, callable, unverified }
}

/**
 * 判断一份磁盘上的插件目录「算不算已安装」。
 * **只看文件在不在**，不猜它能不能跑（那是 loaded 的事）。
 * @param {(p: string) => boolean} exists 注入的 existsSync，方便单测
 * @param {string} dir 插件目录
 * @param {string} main package.json 里声明的入口（相对路径）
 */
export function looksInstalled(exists, dir, main) {
  if (typeof dir !== 'string' || dir === '') return false
  if (typeof exists !== 'function') return false
  const join = (a, b) => a.replace(/[\\/]+$/, '') + '/' + b.replace(/^\.\//, '')
  if (!exists(join(dir, 'package.json'))) return false
  if (typeof main !== 'string' || main === '') return true
  return exists(join(dir, main))
}

/** 序列化 / 反序列化（落盘由调用方做；这里不碰文件系统）。 */
export function serialize(ledger) {
  return JSON.stringify(normalizeLedger(ledger))
}

export function deserialize(text) {
  if (typeof text !== 'string' || text === '') return emptyLedger()
  try {
    return normalizeLedger(JSON.parse(text))
  } catch {
    return emptyLedger()
  }
}
