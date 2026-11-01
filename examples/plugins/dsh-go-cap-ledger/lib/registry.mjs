/**
 * 统一能力登记接口（插件间服务注入版）。
 *
 * ── 为什么是「服务注入」而不是「两个插件共写一个 JSON」────────────────────
 * 宿主（cordis 4.0.5）**原生支持插件间服务注入**，证据是源码而不是猜：
 *
 *   · cordis/src/reflect.ts:277  provide(name, value, check)
 *       → 「Register a service implementation owned by the current fiber …
 *          is unregistered … when the returned disposer runs or the fiber unloads」
 *   · cordis/src/reflect.ts:233  get(name, strict = true)
 *       → 「Read a service from the store without the inject requirement」
 *   · cordis/src/registry.ts:176  ctx.inject(deps, callback)
 *       → 声明依赖，服务就绪时才跑回调；注册表 registry.ts:314 notify() 会在
 *         服务 provide / dispose 时重新评估依赖它的 fiber（fiber.ts:597 _checkImpl）
 *   · cordis/src/service.ts:57   Service 基类构造里 self.ctx.reflect.provide(...)
 *       → 这也是 ctx.tools（dsh-tools/lib/index.js:2798 super(ctx, "tools")）的注册方式
 *
 * 所以正确的做法是：**cap-ledger 提供（provide）一个服务，bili 注入（inject）它**。
 * 一份内存对象、一个写者（cap-ledger），天然不存在两个进程各写一半的问题。
 *
 * 「共享存储 + 原子写」只作为服务不可用时的降级路径保留，
 * 并且降级时**只有 cap-ledger 落盘**（单写者），bili 从不写共享文件。
 *
 * 零第三方依赖。
 */

/** 服务名：别的插件用 ctx.inject(['dshGoCapabilityLedger'], …) 拿它。 */
export const REGISTRY_SERVICE = 'dshGoCapabilityLedger'

/** 接口版本：bili 只认 >= 1 的 v1 形状。 */
export const REGISTRY_API_VERSION = 1

/**
 * 造一个登记接口对象（**纯数据 + 纯函数**，IO 由调用方注入，可单测）。
 *
 * @param {{
 *   get: (plugin: string) => object,           // describeEntry(entryOf(ledger, plugin))
 *   register: (plugin: string, evidence?: object) => object,
 *   record: (plugin: string, run: object) => object,
 *   all: () => object,                          // normalizeLedger(ledger)
 *   summary: () => object,                      // summarize(ledger)
 * }} ports
 */
export function createRegistry(ports) {
  const need = (name) => {
    const fn = ports?.[name]
    if (typeof fn !== 'function') throw new TypeError('createRegistry: 缺端口 ' + name)
    return fn
  }
  const get = need('get')
  const register = need('register')
  const record = need('record')
  const all = need('all')
  const summary = need('summary')

  return {
    v: REGISTRY_API_VERSION,
    /**
     * 登记一个插件「已安装 / 已加载 /（可选）工具已注册」。
     * **只写这些事实**，不动 lastRun*。
     */
    register(plugin, evidence = {}) {
      if (typeof plugin !== 'string' || plugin === '') throw new TypeError('capabilityLedger.register: plugin 必须是非空字符串')
      return register(plugin, evidence)
    },
    /** 记一次真实执行结果（成功或失败 + 失败原因）。 */
    record(plugin, run) {
      if (typeof plugin !== 'string' || plugin === '') throw new TypeError('capabilityLedger.record: plugin 必须是非空字符串')
      if (run === null || typeof run !== 'object') throw new TypeError('capabilityLedger.record: run 必须是对象')
      return record(plugin, run)
    },
    /** 读一个插件的六态描述。 */
    get(plugin) {
      if (typeof plugin !== 'string' || plugin === '') throw new TypeError('capabilityLedger.get: plugin 必须是非空字符串')
      return get(plugin)
    },
    /** 整份台账（只读快照）。 */
    all,
    /** 汇总（total / healthy / failing / callable / unverified）。 */
    summary,
  }
}

/**
 * 从宿主上下文里取登记接口 —— **服务优先，服务不在就返回 undefined**。
 *
 * 为什么不用 ctx.xxx 直接读：cordis 的 proxy 在没有 inject 的情况下读一个
 * 未提供的服务会 **throw**（reflect.ts:144 "cannot get property … without inject"），
 * 所以这里必须走 ctx.get()（reflect.ts:233，设计上就是「不要求 inject 的读」）
 * 并且包住 try —— 让「宿主没有这个服务」表现为 undefined 而不是异常。
 *
 * @param {object} ctx cordis 上下文
 * @param {string} [name]
 * @returns {object|undefined}
 */
export function readRegistry(ctx, name = REGISTRY_SERVICE) {
  if (ctx === null || typeof ctx !== 'object') return undefined
  try {
    if (typeof ctx.get === 'function') {
      const got = ctx.get(name)
      if (got !== undefined && got !== null) return got
    }
  } catch {}
  try {
    const direct = ctx[name]
    if (direct !== undefined && direct !== null) return direct
  } catch {}
  return undefined
}

/**
 * 把登记接口挂到宿主上（cap-ledger 用）。
 *
 * 三步，任何一步失败都**不抛**：拿不到宿主能力时插件本体照常起来，
 * 只是「统一台账」这一项降级，并且台账里会写清原因（不假装提供成功）。
 *
 * @param {object} ctx
 * @param {{ api: object, name?: string }} options
 * @returns {{ provided: boolean, reason: string|null, dispose: (() => void)|null }}
 */
export function provideRegistry(ctx, options = {}) {
  const name = options.name ?? REGISTRY_SERVICE
  const api = options.api
  if (api === undefined || api === null) return { provided: false, reason: 'api 为空', dispose: null }
  if (ctx === null || typeof ctx !== 'object') return { provided: false, reason: '没有宿主上下文', dispose: null }
  if (typeof ctx.provide !== 'function') return { provided: false, reason: '宿主没有 ctx.provide（cordis < 4 或不是 cordis）', dispose: null }
  try {
    const disposer = ctx.provide(name, api)
    return { provided: true, reason: null, dispose: typeof disposer === 'function' ? disposer : null }
  } catch (error) {
    // 重名 / 已被别人占用：不猜、不覆盖，如实记下来
    return { provided: false, reason: error instanceof Error ? error.message : String(error), dispose: null }
  }
}
