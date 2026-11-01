# dsh-go-bili —— B站速览（bili-peek）

> R4「插件生态与能力扩展」的第一件：让 **Agent 主动调用一个 B 站信息查询工具**，
> 拿到**结构化 JSON**，结果在 dsh-go App 里画成**原生卡片**，并且那个结果能**交回给 Agent 继续分析**。
>
> 每次都把结果上报到**统一能力台账**（`dshGoCapabilityLedger` 服务，由 dsh-go-cap-ledger 提供）：
> 全进程一份台账、一个写者，失败时连原因一起记下来。

## 一句话能力

| 你会说的话 | 发生了什么 |
| --- | --- |
| 「BV1uv411q7Mv 这视频讲了啥？」 | 模型调 `peek_bili_video`，拿到标题/UP/简介/播放/点赞/时长/分P → App 里出卡片 → 模型基于它继续分析 |
| 「看看这个链接 https://www.bilibili.com/video/BV…」 | 同上（链接、b23.tv 短链、av 号都认） |
| 「上次那个视频播放多少？」 | 状态条与面板里有最近查过的记录，模型也能再查一次 |

**只读**：只打 `api.bilibili.com/x/web-interface/view` 这一个公开接口。
不登录、不带 cookie、不碰评论/私信/动态 —— 本轮明确不做任何涉及账号权限的功能。

## 宿主契约（以本仓库源码为准，不是猜的）

插件只用这三样宿主能力：

| 能力 | 真实签名（源码位置） | 本插件怎么用 |
| --- | --- | --- |
| `ctx.tools.register` | `@deepseek-ai/dsh-tools` 0.2.1-rc.2，`lib/index.js` 的 `register(definition)` / `defineTool(options)`。register 会断言「`output.render` 必须是函数、`presentationMeta` 要么是函数要么不存在」，并**返回 disposer** | 注册 `peek_bili_video`；返回值是函数才算 `toolRegistered=true` |
| `ctx.effect` | cordis 4.0.5，`fiber.effect(execute)`：execute 立即跑，返回的函数在 fiber 卸载时执行 | 卸载时落盘台账、注销工具、清空推送者 |
| `ctx.dshGo` | dsh-go 桥接，**必须**写在 `ctx.inject(['dshGo'], …)` 里 | `strip('peek.strip')` + `panel('peek')` |

`defineTool` 的 `output.schema` 用的是它的**作者 DSL**，不是裸 JSON Schema：对象节点必须显式写
`additionalProperties`，property 上的 `required` 只能写 `true`。写错会在注册那一刻被拒。

## 存在性检查先于一切（不崩，也不假装）

| 宿主缺什么 | 本插件的行为 |
| --- | --- |
| 没有 `ctx.tools` | 不注册工具，`toolRegistered=false`，**不抛错**；面板/状态条照常起，面板上明写「否」 |
| `ctx.tools.register` 抛错（schema 被拒/重名） | 接住、记进 `lastRunMessage`、`toolRegistered=false`，插件继续跑 |
| 没有 dsh-go 桥接 | `ctx.inject(['dshGo'])` 的回调永远不执行，插件安静地只做工具 |
| 没有 `ctx.effect` | 跳过清理注册 |
| 没有全局 `fetch` | 工具返回 `ok:false, code:'E_NO_FETCH'`，并告诉用户去哪儿修 |

## 错误码（一个都不许静默）

| 码 | 什么时候 | 卡片上会写什么 |
| --- | --- | --- |
| `E_INPUT` | BV 号 / 链接认不出来 | 认不出的原文 + BV 号长什么样 |
| `E_NO_FETCH` | 宿主没有 fetch，也没注入端口 | 「缺依赖」+ 升级/换主机的提示 |
| `E_TIMEOUT` | 超过 `timeoutMs`（默认 12 s） | 超时 + 「过一会儿再试」 |
| `E_ABORTED` | 调用方取消（与超时**分开**） | 「这次被取消了」 |
| `E_NETWORK` | 连接失败（含 DNS） | 原始报错 + 检查网络 |
| `E_HTTP` | 非 2xx | HTTP 状态码 |
| `E_NOT_JSON` | 返回不是 JSON（网关页/劫持页） | 拿到的那一小段原文 |
| `E_BANNED` | 被 B站风控挡了（HTTP 412 / `code:-412`） | 「出口 IP 被拦了，换网络再试」——**不是** BV 号错 |
| `E_BIZ` | B站业务码 ≠ 0（视频不存在等） | `code=-404 啥都木有` |
| `E_NO_DATA` | 有 `code:0` 但没数据 | 稍后重试 |
| `E_INTERNAL` | 插件自己的 bug | 「请把错误信息反馈」 |

### 真实网络才暴露的两个坑（打桩测试全绿也发现不了）

**① 自造 UA 会被风控判 412。** 同 IP 实测：

| User-Agent | 结果 |
| --- | --- |
| `Mozilla/5.0 (Linux; Android 14) dsh-go-bili-peek/0.1` | **412 request was banned** |
| `Mozilla/5.0 (Windows NT 10.0; Win64; x64) … Chrome/131` | **200 OK** |

所以 `BROWSER_UA` 用的是浏览器形状的 UA。

**② HTTP 412 的响应体里才有 `{"code":-412}`。** 老代码先判 `res.ok === false` 就抛 `E_HTTP`，
body 根本没被读，后续的匿名指纹重试一次都不会触发 —— 真机 100% 查不到。
现在**先读 body 再判状态码**。

绕风控用**懒补匿名指纹**：正常路径不多打一个请求；被 -412 挡了才去
`x/frontend/finger/spi` 取匿名 `buvid3/buvid4` 重试一次，成功就进程内缓存。
**这不是登录**：不带账号、不带 token、不读用户 cookies、不落盘。

**失败不是异常**：`execute` 不抛，而是返回 `{ ok:false, code, message, hint }`。
抛异常会让模型看不到原因；返回结构化失败，模型才能真正告诉用户「下一步怎么办」。

## 原生界面

| 位置 | 内容 | 预算 |
| --- | --- | --- |
| **工具卡**（`presentationMeta` 里的 `dsh-go/view"`） | 播放/点赞/时长三个数字 + UP/发布日期 + 简介 + 分P；失败时是「错误码 + 原因 + 下一步」的提醒条 | ≤ 8 KiB / 40 节点 / 6 层，只用白名单 8 个组件 |
| **状态条**（输入框上方） | 最近查的那个：`标题 557.7万`；没查过是「待命」；工具没注册是「未就绪」 | text ≤ 24 字 / ≤ 2 KiB，没变化不 emit |
| **面板 · B站速览** | 能力台账（四态）+ 查过/失败次数 + 最近 20 条记录 | ≤ 32 KiB / 120 节点 / 8 层 |

面板放在 `session.tab` / `chat.panel` / `features` 三处，由清单里的 `placement` 决定。

## 上报到统一能力台账

宿主 cordis 4.0.5 原生支持插件间服务注入，所以**不再各写一份 `ledger.json`**：

| 时刻 | 做什么 |
| --- | --- |
| `apply()` 跑到 | `ctx.get('dshGoCapabilityLedger')` 拿服务；拿到就 `register('dsh-go-bili', {installed, loaded, toolRegistered, error?})` |
| 服务晚于本插件提供 | `ctx.inject(['dshGoCapabilityLedger'], …)` 回补 —— 两种加载顺序都能接上 |
| 每次 `execute` 结束 | `record('dsh-go-bili', { ok, code?, message?, at })` —— 成功与失败都记，失败必带原因 |
| 宿主没有这个服务 | **不崩、不假装**：`handle.unified()` 返回 `null`，本地照常工作 |

服务契约由 `dsh-go-cap-ledger` 生产（`lib/registry.mjs`），本插件只持有服务名
`REGISTRY_SERVICE = 'dshGoCapabilityLedger'` + 一个读取函数 —— **不做跨包 import**，
这样本插件可以单独安装。名字两边不许漂移，由 `test/plugin.test.mjs` 守。

本地仍保留 `$DSH_HOME/cache/dsh-go-bili/ledger.json` 作为**离线回退存档**
（`DSH_HOME` 延迟读；落盘失败只在内存里记，观测本身不该变成故障源），
但它**不再是**「统一台账」——统一台账只有一份，在 cap-ledger 里。

## 测试

```sh
node --test test/*.test.mjs   # 80 项，纯 Node、零依赖、离线；不碰真网络、不碰真 home
node lib/views.mjs            # 视图预算自测（面板/卡片/状态条）

# 真跑（真 cordis + 真 dsh-tools + 真连 api.bilibili.com），与上面的打桩测试**不同**
node --import ./verify/hooks.mjs verify/live-host.mjs
```

覆盖：

| 组 | 内容 |
| --- | --- |
| 输入解析 | BV / av / 链接 / 短链 / `?p=2`；认不出来 → `E_INPUT` |
| 网络 | 成功、网络失败、超时、取消、HTTP 错、非 JSON、空响应、业务码错、缺 fetch —— **每条都有自己的码** |
| 结果形状 | 缺字段就不给那个键；分P 截到 20；失败也能出卡 |
| 插件加载 | 有/无 `ctx.tools`、register 抛错、无 `ctx.effect`、无桥接 |
| 工具调用 | 注入 fetch 端口、卡片/文字/值三件套、失败不抛、卡片超 8 KiB 返回 `{}` |
| 台账 | 四态彼此独立、失败原因落盘后可读回、坏文件不崩、`normalizeLedger` 不信输入 |
| 统一台账 | 有服务就登记+记账、失败带 code、没服务不崩、服务晚到能回补、服务名两边不漂移 |
| 风控 | `-412` → 取匿名指纹重试成功、带指纹仍被挡 → `E_BANNED`、正常路径不多打请求 |
| 视图 | 工具卡白名单、面板四态文字、状态条 ≤24 字、30 条记录不超预算 |
| 桥接 | 用 `sdk/plugin-kit` 的**真测试宿主**跑清单解析 / 视图 / 数据推送 / 动作效果 |

`output.schema` 的 DSL 合规性有两层验证：一层是本仓库自带的逐条规则检查（无 DSH 也能跑），
另一层在找得到真 `@deepseek-ai/dsh-tools` 时用它的 `defineTool` + `validateJsonSchemaValue` 实测。

## 装

```sh
# 手机本机引擎（App › 终端），或 SSH / 中转主机上
dsh plugin --profile web add /绝对路径/dsh-go-bili
```

需要 DSH ≥ 0.2.1-rc.2。改了 `lib/*.js` 要重启内核才会重新加载。

## 文件

| 文件 | 作用 |
| --- | --- |
| `lib/index.js` | 插件本体：宿主探测、工具注册、台账、原生界面注册 |
| `lib/bili.mjs` | 纯逻辑：输入解析、可注入 fetch 的查询、错误码 |
| `lib/views.mjs` | 纯函数：工具卡 / 面板 / 状态条 + 预算校验（与 partner 那份同一套判据） |
| `lib/ledger.mjs` | 本地离线回退存档（四态 + 计数 + 规整 + 序列化）；统一台账请到 cap-ledger |
| `verify/*.mjs` | 真实宿主 + 真实网络的验证脚本（不是测试替身） |
| `support/dsh-tools.js` | 测试辅助：让 `@deepseek-ai/dsh-tools` 在 DSH 之外可解析（找得到真包就用真的） |
| `test/*.test.mjs` | `node --test` |

## 参考与授权

- 插件骨架照 `examples/plugins/dsh-go-partner`（同仓 R4 M3）与 `examples/plugins/dsh-go-example-weather`
  （同仓官方示例，MIT © DSH-TUI）的写法；**没有**照抄 Windows 专用代码。
- B站接口字段形状参考了 `dsh-bili-subagent` / `dsh-bili-whale`（都是 MIT）的公开知识，
  但**没有复用它们的任何代码**：那两个依赖 Python/uv/登录态/二维码，本插件零依赖、只读公开接口、不登录。
- 数据来源：B站公开 Web 接口，卡片与状态条上标明来源。

## 许可

MIT。
