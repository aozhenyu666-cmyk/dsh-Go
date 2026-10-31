# dsh-go-partner

> R4「人格 / 长期记忆 / 情绪」在 **DSH Go（Android）** 上的**原生界面层**。
> **只读，不写任何数据** —— 数据仍由 `dsh-fish-memory`（记）和 `dsh-feiyu-mood`（判）管，
> 本包只负责把它们画成 DSH Go 的原生插槽。

## 为什么需要这个包（三方仓库都没有这件事）

`dsh-fish-memory` 和 `dsh-feiyu-mood` 的界面都在 `client.js` —— **web 半端（React）**。
DSH Go 的原生界面**不执行插件的任何 JS**，只认两样东西：

1. `package.json` 里的 `dshGo` 清单（声明胶囊/状态条/面板放哪）
2. 插件宿主用 `ctx.dshGo` 推的 **JSON 视图**

所以不写这一层，在 App 里只能切「网页模式」才看得见 —— 而用户要的恰恰是「右下角会变脸的小东西」「输入框上方那一行」。这就是本包存在的唯一理由。

## 它长什么样

| 位置 | 内容 |
| --- | --- |
| **状态条**（输入框上方） | `开心 72` + 心形图标，点开接心情面板。30 秒轮询一次，没变化不推 |
| **面板 · 心情** | 心情值 + 五档标签 / 七维情绪柱图 / 最近 6 次涨跌（带理由）/ 基线·半衰期·注入方式·门槛 |
| **面板 · 记忆** | 容量条（读到才画）/ 按「初次相遇 → 永远不会忘的 → 最初的日子 → 和主人的记忆 → 正在模糊的事」分组 / 每条带清晰度·重要度·时间 |
| **面板 · 目的** | 今天几次/上限、下次什么时候、5 维驱动条、目标假设（把握 % + 风险）、没说完的事。P2 之前显示「还没做」 |
| **工具卡** | `remember` 的结果画成卡片（成功绿、失败黄并写原因） |

## 装（手机本机引擎）

```bash
# ① 把目录推上去
adb push dsh-go-partner /sdcard/Download/
#    （App › 设置里打开「访问手机文件」，本机环境里就是 /sdcard/Download/）

# ② App › 本机引擎 › 终端
mkdir -p /root/.dsh/dsh-go/plugins
cp -r /sdcard/Download/dsh-go-partner /root/.dsh/dsh-go/plugins/
dsh plugin --profile web add /root/.dsh/dsh-go/plugins/dsh-go-partner
```

装完**不用重启**（指路链接生效，几秒内 App 就拿到新清单）；改了 `lib/*.js` 才要重启引擎。
卸载：`dsh plugin --profile web remove dsh-go-partner`。

> ⚠️ 装的是**指向这个目录的链接** —— 目录删了插件就起不来。

## 不装也能先验（不碰手机）

```bash
node lib/views.mjs          # 5 个视图的预算校验（面板 32KiB/120 节点/8 层…）
node test/apply.test.mjs    # 23 项：清单合法性 / 无桥接不打挂 / 无数据不空白 / 真数据能读 / 错乱要明说
```

两套都是纯 Node、零依赖、可离线。**改任何视图之前先跑这两个**，因为它们检查的正是「写错不报错、只是整块降级成『插件界面有误』」的那些点。

## 三条设计取舍（都是踩过的坑）

### 1. 只读，不抢写

`dsh-fish-memory` 和 `dsh-feiyu-mood` 各自持有自己的状态文件。本包**只读**：
不注册工具、不调模型、不改 `state.json`。一个写者原则 —— 否则两边同时改一份 JSON，谁赢看运气。

### 2. `view` / `strip` 必须同步返回

```js
// ✗ 错：async 保护会把返回值变成 Promise
const guard = (fn) => async (...a) => { try { return await fn(...a) } catch { return null } }
ctx.dshGo.panel('x', { view: guard(myView) })     // → App 报「插件界面有误」

// ✓ 对：同步/异步分开
const syncGuard = (fn) => (...a) => { try { return fn(...a) } catch { return undefined } }
```
`view(scope, caps)` 要**同步**返回视图；`strip(id, dataFn)` 的 `dataFn` 要**同步**返回取消函数。
用 async 包一层 → 视图拿到 Promise（整块降级）、取消函数永远调不到（定时器泄漏）。
`test/apply.test.mjs` 里有一条专门断言 `!(v instanceof Promise)`。

### 3. 插槽 id 全插件唯一

状态条和面板**不能**都叫 `mood`。撞了不会崩，但 App 插件详情页会显示「原生界面 · 1 项有误」。
所以这里是状态条 `mood.strip`、面板 `mood`。

## 数据从哪读（只读路径）

| 插件 | 路径 | 结构 |
| --- | --- | --- |
| 心情 | `$DSH_HOME/feiyu-mood/state.json` | `{ moods: { <slotId>: { mood, dims, timeline:[{at,delta,reason}] } } }` |
| 心情配置 | `$DSH_HOME/feiyu-mood/config.json` | `slots[]` 里 `sessions[]` 决定哪个会话归哪份心情 |
| 记忆 | `$DSH_HOME/fish-memory/<sessionId>.json` | 形状各版本有差异：`memories` / `records` / `items` 都兜住 |
| 目的 | `$DSH_HOME/surfcore/characters/<id>/purpose-outreach.json` 等 | P2 之前不存在 → 面板显示「还没做」 |

> `DSH_HOME` 是**延迟读取**的（`dshHome()` 函数），不是模块级常量 —— 否则 import 那一刻就定死，
> 换主机/换 profile/测试都不生效。这条在测试里直接踩到过。

### 绑定对不上时：显示 + 警告，不猜

`config.slots[].id` 和 `state.json` 的键对不上（0.7.0 修过的那个 bug，老数据仍可能是错的）：

- 只有一份记录 → **照样显示，但面板最上面挂一条黄色警告**，写明两个 id 各是什么、去哪个设置页重选；
- 一份都对不上 → 只显示警告，不显示数字。

静默显示是错的（用户以为绑对了）；只报错不显示也是错的（数据其实读得到）。

## 已知取舍

| 取舍 | 原因 |
| --- | --- |
| **没有导出 `Config`（schemastery）** | 本包没有自己的设置项 —— 心情/记忆的参数在各自插件里改，这里再放一套只会两边打架。所以 App 的「插件设置表单」里不会有本包 |
| 状态条 30 秒轮询，不是推送 | 心情只在 `turn-stopping` 后变；30 秒足够，且省电。桥接本身限 4Hz，这里没变化就不 emit |
| 记忆条数不设「总数」指标 | 面板已经很挤，`title` 里带就够了 |
| 目的面板 P2 前是空壳 | 宁可明确说「还没做」，也不放假数据 |

## 与主方案的关系

本包 = 主方案（`DSH-Go-R4-人格记忆情绪-架构与复用方案.md`）里的 **P1：原生面板**。
它不解决「合并成一个插件」（那是 P3），也不做目的层的 driver（P2）。它只做一件事：
**让已经有记忆、有心情的伙伴，在 Android 原生的界面上看得见。**
