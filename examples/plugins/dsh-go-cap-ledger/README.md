# dsh-go-cap-ledger —— 插件能力台账

> R4「插件生态与能力扩展」的第二件：一份**轻量台账**，把每个插件的六个状态分清楚：
> **installed / loaded / toolRegistered / available / executed / failed**，
> 外加一个只有「真跑通过」才成立的 **verified**。
>
> 只显示插件名等于没有台账。这个包的唯一存在理由，就是让「装了但没生效」「工具没注册上」
> 「**装好了但一次都没跑过**」「上次调用为什么失败」这四件事**一眼能看出来**。
>
> **它同时是统一台账的生产方**：用 `ctx.provide('dshGoCapabilityLedger', …)` 把登记接口
> 挂到宿主上，别的插件 `ctx.get` 到它、登记自己、上报每次执行 —— 全进程**一份台账、一个写者**。
> 详见 §统一能力登记接口。

纯 JS、零第三方依赖、可 `node --test` 单测，也能在手机上跑。

## 它区分什么（这是全部）

| 状态 | 到底是什么意思 | 谁来定 | 判据 |
| --- | --- | --- | --- |
| `installed` | 已安装：包在磁盘上、被 profile 选中 | 插件包自己 / 外部登记 | 看得到 `package.json` 和声明的入口文件（`looksInstalled`） |
| `loaded` | 已加载：代码真的跑起来了 | `apply()` 执行到 | 光是「配置里开着」不算 |
| `toolRegistered` | 工具已注册 | `ctx.tools.register` | **返回了 disposer 才算**；调过但抛错 = false，且原因落进 `lastRun*` |
| `available` | **现在能调用**（派生） | 前三态同时成立 | 前三态任一为 false 就是 false；任一 null 就是 null |
| `executed` | 真的执行过（派生） | `runs > 0` | 「跑过没有」和「跑得对不对」是两件事 |
| `failed` | 执行过且失败（派生） | `lastRunOk === false` | `runs=0` 时是 null，不是 false |
| `verified` | **验证过实际执行**（派生） | `runs > 0 && lastRunOk === true` | 只跑过但失败 = null |

**最关键的一条**：`healthy` 只给「真跑通过」的插件。

```js
callable = installed && loaded && toolRegistered        // 现在能不能叫
healthy  = callable && runs > 0 && lastRunOk === true   // 真的验证过
```

装好了、加载了、工具也注册了，但一次都没执行过 —— 那是
**「已加载 / 可以调用 / 尚未验证实际执行」**，**不叫健康**。
上一轮这里把「没跑过」算成了 healthy，那是假绿，本轮已修。

`null` 和 `false` 是**两件不同的事**：

- `null`（还没跑过）：面板上写「还没跑过」，不算不健康；
- `false`（跑过但失败）：面板上写「失败（E_TIMEOUT）」，并且把原因单独列一页。

## 为什么不能只存一个布尔

真实排障顺序是反过来问的：**「它根本没装 / 装了没加载 / 加载了但工具没注册上 / 工具能调但每次都失败」**
—— 这四种情况的修法完全不同（重装 / 看引擎日志 / 看 schema 与重名 / 看网络与参数）。
一个 `ok: false` 把这四种压成一种，等于什么都没说。

## 谁能写台账

| 写者 | 怎么写 |
| --- | --- |
| 台账插件自己 | `apply()` 里给自己建一条：installed=true、loaded=true、toolRegistered 看 register 结果 |
| **别的插件（推荐）** | `ctx.get('dshGoCapabilityLedger')` 拿到服务，`register(name, {installed, loaded, toolRegistered})` + `record(name, {ok, code, message})`。或用 `ctx.inject(['dshGoCapabilityLedger'], cb)` 等它就绪 |
| 进程内操作者 | 本插件返回的 `api` 对象同样可用 |
| 落盘文件 | 直接改 `$DSH_HOME/cache/dsh-go-cap-ledger/ledger.json`（格式见下）；坏数据会被规整，不会崩 |

**为什么是服务注入而不是「两个插件共写一个 JSON」**：共写要处理抢写、锁、原子 rename、
崩溃残留锁，而服务注入天然只有一个内存对象、一个写者（本插件），这些问题根本不存在。

## 统一能力登记接口（本轮核心）

宿主 `cordis` 4.0.5 原生支持插件间服务注入（**源码为证，不是猜的**）：

| 能力 | 文件:行 |
| --- | --- |
| `provide(name, value, check)` | `cordis/src/reflect.ts:277` |
| `get(name, strict = true)`（不要求 inject 的读） | `cordis/src/reflect.ts:233` |
| `ctx.inject(deps, callback)` | `cordis/src/registry.ts:176` |
| 服务 provide/dispose 时唤醒依赖方 | `cordis/src/registry.ts:314` + `fiber.ts:597` |
| 直接读未提供的服务会 throw | `cordis/src/reflect.ts:144` |

服务名 **`dshGoCapabilityLedger`**（唯一契约字面量，见 `lib/registry.mjs` 的 `REGISTRY_SERVICE`）。

```js
// 消费方（例如 dsh-go-bili）
const ledger = ctx.get('dshGoCapabilityLedger')   // 拿不到就是 undefined，不抛
if (ledger) {
  ledger.register('dsh-go-bili', { installed: true, loaded: true, toolRegistered: true })
  ledger.record('dsh-go-bili', { ok: true, at: Date.now() })
}

// 服务晚于本插件提供？用 inject 等它
ctx.inject(['dshGoCapabilityLedger'], (c) => {
  c.dshGoCapabilityLedger.register('dsh-go-bili', { … })
})
```

接口形状（`v: 1`）：`register(plugin, evidence)` / `record(plugin, run)` / `get(plugin)` / `all()` / `summary()`。
烂入参一律抛 `TypeError` —— 不静默写脏数据。

提供失败（宿主没有 `ctx.provide`、或服务名已被占）**不崩**：插件其余部分照常起来，
失败原因记进自己的 `lastRun*`（`E_NO_REGISTRY`），面板能看见。

```jsonc
{
  "v": 2,
  "plugins": {
    "dsh-go-bili": {
      "plugin": "dsh-go-bili",
      "installed": true,          // 三态：true / false / null（未知）
      "loaded": true,
      "toolRegistered": true,
      "lastRunOk": false,         // null = 还没跑过
      "lastRunCode": "E_TIMEOUT", // 失败必经这里
      "lastRunMessage": "请求超时：超过 12000 ms",
      "runs": 5, "fails": 1,
      "updatedAt": 1767225600000
    }
  },
  "updatedAt": 1767225600000
}
```

## 三条不违反的规则（都是踩过的坑）

1. **不猜。** 拿不到就是 `null`，不默认成 `true`。假绿比不显示更坏 ——
   `describeEntry()` 在任一态为 `null` 时一律判 `healthy: false`。
2. **失败必须带原因。** 只有 `lastRunOk: false` 没有 code/message 的记录会被 `normalizeEntry` 补上
   `E_UNKNOWN`，而不是留一个光秃秃的 `false`。
3. **观测不该变成故障源。** 落盘失败（只读 home、手机没权限）只在内存里记，不改任何行为；
   坏文件当成第一次跑，不抛。

## 原生界面

| 位置 | 内容 | 预算 |
| --- | --- | --- |
| **状态条** | `全部已验 3/4` / `2 个尚未验证` / `1 个上次失败` / `台账 · 空` | text ≤ 24 字 / ≤ 2 KiB，没变化不 emit |
| **面板** | **登记 / 已验证 / 未验证 / 上次失败** 四个数 + 每个插件七项状态 + 一句话结论 + 「上次为什么失败」清单 | ≤ 32 KiB / 120 节点 / 8 层 |
| **工具卡** | `cap_ledger_status` 的结果（谁坏了、坏在哪一环） | ≤ 8 KiB，只用白名单 8 个组件 |

## 工具

`cap_ledger_status`：Agent 能直接问「哪个插件坏了」。

| 参数 | 说明 |
| --- | --- |
| `plugin`（可选） | 只看某一个插件；不填就全部 |

返回 `{ ok, summary: { total, healthy, failing }, plugins: [{ plugin, installed, loaded, toolRegistered, lastRunOk, lastRunCode, lastRunMessage, runs, fails, healthy }] }`。
**没跑过的插件不给 `lastRunOk` 字段**（缺失 = 不知道），不给 `false`。

`healthy` 只对「真跑通过」的插件为 true。`summary` 另有 `callable`（能调用）与
`unverified`（能调用但没跑过）两个数 —— 三个数分开报，不许把后两者并进 healthy。

## 宿主契约

| 能力 | 用在哪 | 缺了会怎样 |
| --- | --- | --- |
| `ctx.provide` | 对外提供统一台账服务 | `E_NO_REGISTRY`，插件其余照常；面板能看见原因 |
| `ctx.tools.register` | 注册 `cap_ledger_status` | `toolRegistered=false`（且不算一次执行失败），插件其余部分照常 |
| `ctx.effect` | 卸载时落盘 + 撤销服务 | 跳过清理注册 |
| `ctx.dshGo`（写在 `ctx.inject(['dshGo'])` 里） | 状态条 + 面板 | 桥接不在时回调不执行，插件安静地只提供工具 |

## 测试

```sh
node --test test/*.test.mjs   # 50 项：内核 21 + 插件层 29
node --import ./verify/hooks.mjs verify/live-host.mjs   # 真 cordis + 真 dsh-tools
node lib/views.mjs     # 视图预算自测
```

| 组 | 内容 |
| --- | --- |
| 内核（`ledger.mjs`） | 四态互相不覆盖、`null` ≠ `false`、注册失败带原因、`runs=0` 时 `lastRun*` 全空、`fails ≤ runs`、`summarize` 三个数独立、序列化往返、坏文本给空台账 |
| 插件层 | 自己那条台账、无 `ctx.tools` / register 抛错 / 无 `ctx.effect` / 无桥接 都不崩、工具调用与过滤、失败原因原样进结果、落盘后重启可读回、`DSH_HOME` 延迟读 |
| 视图 | 面板四态逐条写、空台账有人话、25 个插件不超预算、状态条三种情况三种话、App 解析器孪生零 error |
| 桥接 | 用 `sdk/plugin-kit` 的真测试宿主跑清单解析 / 视图 / 数据推送 / 动作效果 |

## 装

```sh
dsh plugin --profile web add /绝对路径/dsh-go-cap-ledger
```

## 文件

| 文件 | 作用 |
| --- | --- |
| `lib/ledger.mjs` | 纯内核：四态判定、规整、计数、汇总、序列化（零 IO，全部可单测） |
| `lib/views.mjs` | 纯函数：面板 / 状态条 + 预算校验（与 partner 同一套判据） |
| `lib/index.js` | 插件本体：探测宿主、注册工具、落盘、原生界面 |
| `test/` | `node --test` |

## 与 `dsh-go-bili` 的关系

`dsh-go-bili`（B站速览）里内置了一份更小的台账（`lib/ledger.mjs`），因为它需要在没有
cap-ledger 的机器上也能说清自己的状态；本包是**独立、完整、多插件**的那一份。
两者数据形状不共享：内置那份只管自己，本包管全部。

## 许可

MIT。
