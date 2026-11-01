# dsh-go-partner

R4 的**人格 / 记忆 / 情绪**层：把「她是谁、她记得什么、她现在什么心情」变成
App 里看得见、能纠正、也能真正交给模型的东西。

零第三方依赖（`import` 只有 `node:fs` / `node:path` / `node:os` / `node:module` + 本包自己的模块），
不需要 App、不需要桥接也能装上。原生设置表单要的 `schemastery` 是**从宿主那棵树同步取**的
（`lib/hostdeps.mjs`），不是本包的依赖；宿主没有就不导出 `Config`，插件照常跑。

---

## 它和上游的分工（一条写者原则）

| 谁 | 负责 | 本插件怎么对待 |
|---|---|---|
| [dsh-fish-memory](https://github.com/Yuuyuko-uu/dsh-fish-memory) | 会话记忆、检索、衰减、`remember` 工具 | **只读** `~/.dsh/fish-memory/session-*.json` |
| [dsh-feiyu-mood](https://github.com/Yuuyuko-uu/dsh-feiyu-mood) | 每轮判心情、时间线、注入 | **只读** `~/.dsh/feiyu-mood/{config,state}.json` |
| [surfcore](https://github.com/Miesiko/surfcore) | 角色目录、`persona.md`、跨会话记忆卡 | **只读** `~/.dsh/surfcore/characters/…` |
| **本插件** | 界面 + 人格装配 + 自己的记忆叠加层 + 工具 | 只写 `~/.dsh/partner/` 下的文件 |

**不替上游改一个字节。** 用户的「纠正」（隐藏 / 置顶 / 改写）写在自己的叠加层里，
上游文件原样不动 —— 有测试盯着这条（`纠正层：隐藏后检索不到，但上游文件字节未变`）。

**身份只有一份真相。** M2 的 identity 卡就是这张人格卡；`buildSelfIdentityBlock()` 的输出
作为 `persona.md` 的 **「## 自我身份」一节**接进去，不另起一份并排的提示词。
所以这里**没有** `dsh-go-identity` 插件。

**隐私边界（写死在代码里，不是文档里的君子协定）**
- 只读上面三处 JSON；`fish-memory` 目录只认 `/^session-[A-Za-z0-9._-]+\.json$/`。
- **不读屏幕、窗口标题、剪贴板，不截屏。** 有一个测试专门造一个 `screen-capture/` 目录，
  断言它永远不会被读进记忆。

---

## 三个模块，可以分别关

在 DSH 里改的是**原生设置表单**（设置 › 引擎参数 › 插件 › 伙伴），落盘到 profile 的
`cordis.patch.yml`（细节见下面「配置：只有一套」）。**没有宿主**（单测 / CLI）时才读
`~/.dsh/partner/config.json`（没有就用全默认；坏了也不会让插件起不来）

```json
{
  "persona": { "enabled": true, "personaFile": "", "style": "", "topics": [], "identityFile": "" },
  "memory":  { "enabled": true, "shortTermHours": 24, "recallLimit": 6, "recallFloor": 0.12, "panelLimit": 40 },
  "mood":    { "enabled": true, "inject": true },
  "tools":   { "enabled": true },
  "hint":    { "enabled": true }
}
```

任何一个 `enabled: false` 都会让它**整块停掉**：不读数据、不进系统提示、不注册工具，
面板改成一句「已在配置里关掉」而不是静默空白。每轮都重新读文件，改完不用重启。

---

## 四块原生界面（都接真实 provider）

| 面板 | 内容 | 数据来自 |
|---|---|---|
| **人格** `persona` | 她叫什么 / 你叫什么、人格卡来自哪个文件、分节标题、角色状态（认识多少天、记得多少条、此刻心情） | `persona.md` + `character.json` + 记忆统计 + 心情 |
| **记忆** `memory` | 短期（N 小时）/ 重要事实 / 长期三段；点开单条能**钉住、藏起来**；写明数据来自哪个文件 | `fish-memory` + surfcore 记忆卡 + partner 自己的库 |
| **心情** `mood` | 此刻值（含衰减后的）/ 记的值 / 七维柱状图 / 时间线 / 上游配置 | `feiyu-mood/{config,state}.json` |
| **目的** `purpose` | P2 还没做 → 明确说「还没做」，不装 | 有 `purpose-outreach.json` 才画 |

另有输入框上方的**人格胶囊**（`persona.strip`）：`大肥鱼 · 开心 72`，点开进人格面板。

---

## 四个工具（真注册，不是卡片装饰）

| 工具 | 干什么 | 写哪里 |
|---|---|---|
| `partner_recall` | 本地检索（字面 + 重要度 + 保鲜度 + 置顶），分数可解释 | 只读 |
| `partner_remember` | 记一条；同一 `fact` 键重复记 = 更新，不存两条 | `~/.dsh/partner/memory-own.json` |
| `partner_correct` | 隐藏 / 放回 / 钉住 / 取消 / 改写 / 备注 | `~/.dsh/partner/memory-corrections.json` |
| `partner_mood` | 读此刻心情 + 七维 + 最近几次变化 | 只读 |

参数谱只用了 DSH 支持的 JSON Schema 子集。`test/real-dsh-tools.test.mjs` 会在
能找到真的 `@deepseek-ai/dsh-tools` 时直接调它的 `defineTool()` 编译一遍 ——
拿不到就 **skip 并说明**，不假装通过。

---

## 交给 Agent 的两段提示

| 挂到哪 | 为什么 |
|---|---|
| 人格 → `systemPrompt.section()` | 它**不每轮变**，放在系统提示里能吃到前缀缓存 |
| 心情 → `systemPrompt.context()` | 它**每轮都可能变**；放 section 会把上千 token 的缓存整段打掉（fish-memory 实测过 20 倍成本差） |

还有第三段「工具提示」（`partner:hint`，order 89990）：**不告诉它你有这些工具，它基本不会主动调**。
这段会写清每个工具什么时候用、以及「只读本机、不联网、不读屏幕」的边界。

三段都 `interpolate: false` —— 人设或记忆里只要有一句带 `{{ }}`，模板插值会让整轮直接失败。

---

## 测试

```sh
cd examples/plugins/dsh-go-partner
node --test                     # 单元 + 模拟宿主（真 SDK 桥接代码）
node lib/views.mjs --selftest   # 所有视图的预算自检
DSH_TOOLS_DIR=<dsh-tools 目录> node --test   # 额外跑真 defineTool 编译
```

- `test/memory.test.mjs` —— 适配层、衰减、检索、事实提取、纠正层、隐私边界
- `test/persona.test.mjs` —— 身份块、候选链、风格/话题、角色状态
- `test/mood.test.mjs` —— 七维真名、衰减、挑份、上下文注入门槛
- `test/apply.test.mjs` —— 假宿主跑 `apply()`：清单、开箱空态、真实数据、点按真改到东西、工具注册、schema 子集、边界
- `test/host-sdk.test.mjs` —— 用 `sdk/plugin-kit/testing.js`（**桥接自己的代码**）验视图预算与效果白名单
- `test/real-dsh-tools.test.mjs` —— 用真的 `defineTool()` 编译参数谱

夹具（`test/fixtures.mjs`）的形状**逐字照抄本机实测文件**。这一点不是洁癖：
上一版把七维写成 `steady` / `tender`，而 `feiyu-mood` 从来只发 `calm` / `heartache`，
于是「心疼 7」在面板上一根柱子都没有 —— 夹具写错，测试全绿也没意义。

---

## 配置：只有一套（R4 第三轮改的）

```
原生设置表单（设置 › 引擎参数 › 插件 › 伙伴）
        │  ConfigEditor.edit()  ← 宿主自己的能力
        ▼
$DSH_HOME/profiles/<name>/cordis.patch.yml 里 partner 这一行的 config
        │  cordis 校验后作为 apply(ctx, config) 的第二个参数
        ▼
插件运行时读到的值（volatile 字段是引用，改完立刻生效，不用重启）
```

| 场景 | 用哪一份 |
|---|---|
| 在 DSH 里跑（apply 拿到了 config） | **只认宿主注入的 config**，它是唯一真相 |
| 没有宿主（单元测试 / CLI 探针 / 网页预览） | 退回 `~/.dsh/partner/config.json` |

旧的 `config.json` 如果还在，**不再参与运行**，人格面板会明说一句
「旧配置文件已不再参与运行」—— 静默忽略会让你以为自己设过的东西生效了。

字段（原生表单和文件用同一套名字）：

| 组 | 字段 | 含义 |
|---|---|---|
| `persona` | `enabled` / `personaFile` / `style` / `topics` / `identityFile` | 人格模块与表达风格 |
| `memory` | `enabled` / `shortTermHours` / `recallLimit` / `recallFloor` / `panelLimit` | 记忆模块 |
| `mood` | `enabled` / `inject` / `timelineLimit` | 情绪模块 |
| `tools` | `enabled` | 四个工具的执行开关 |
| `hint` | `enabled` | 告诉模型「你自己有记忆和情绪」的那段提示 |

每个字段都是 `.extra('volatile', true)`：宿主设置层只认 volatile，cordis 也靠它做热更新
（改完不重启插件，直接把新值写进引用）。

**开关是运行期语义**：关掉 `tools` 之后工具仍在列表里（注册一次就是这样），
调用会返回一句明确的拒绝，而不是按旧配置继续干活 —— 那比「打开了却什么都不发生」诚实。

**其他还没做的**
- 目的面板只**读** surfcore 的 `purpose-outreach.json`（念头、驱力、没说完的话）；
  「主动开口」由 surfcore 自己的引擎决定，本插件不接管，按钮上也如实写着没接。
- 记忆面板一次最多画 `panelLimit` 行，全量存档仍在网页版。
- 上游换了数据结构时 → 面板会显示 `shape: unknown` 和具体原因，不会瞎猜字段。

## 真宿主端到端

`live-host/` 里有一套起真引擎的脚本，证明「改 setting → 插件重新读 → 系统提示变化 →
重启后仍有效」。跑法见 [live-host/README.md](live-host/README.md)。
R4 第三轮就是靠它抓到 4 个只有真宿主才会暴露的缺陷。

---

## 许可与署名

MIT。人格卡的**分层思路**参考 [surfcore](https://github.com/Miesiko/surfcore)（MIT），
记忆的**保鲜度 / 事实键**概念参考 [dsh-fish-memory](https://github.com/Yuuyuko-uu/dsh-fish-memory)（MIT），
情绪的**七维与阈值**参考 [dsh-feiyu-mood](https://github.com/Yuuyuko-uu/dsh-feiyu-mood)（MIT），
人格文本体例参考 [大肥鱼](https://github.com/whyever77/dafeiyu-astrbot)（MIT）。
本仓库**没有**把它们的代码搬进来 —— 只借概念与字段口径，实现是自己写的。
