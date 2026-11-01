# R4-M3 · 人格记忆情绪配置闭环（第三轮）

分支 `fix/r4-m3-config-2026-11-01`，基线 `ac04b388b7ebe8c400a5907c9116797e7d539eda`。
本轮**只修真实逻辑缺陷、补接线、消除错误状态**，不重写、不重构、不加第三方依赖。

---

## 0. 一句话结论

上一轮把「schema 能被 schemastery 解析」当成了「Config 完成」。**那不是完成 —— 真实加载路径上
`Config` 一直是 `undefined`**，因为这个插件取 schemastery 的方式是读一个**宿主从来不提供的全局**
`globalThis.__dshSchemastery`。本轮把这条链真正接通了，并用**真引擎**端到端证明：
改 `persona.style` → 保存 → 插件重读 → 系统提示变化 → 重启后仍有效，四个开关也都验了。

---

## 1. 四个必须先查清的问题（都给了文件与行号）

### Q1：DSH 宿主到底提不提供 `globalThis.__dshSchemastery`？

**不提供。上一轮的 `Config` 在真机上是 `undefined`。**

证据（全量搜索整棵宿主树，不是抽样）：

```
> 对 resources/app.asar/dsh（含 node_modules 全部 .js/.cjs/.mjs）递归搜索
  __dshSchemastery / dshSchemastery        → 命中 0 个文件
> git grep -n "__dshSchemastery"
  examples/plugins/dsh-go-partner/lib/index.js:56   ← 只有我们自己写的那处读取
  R4-HARDENING-REPORT.md:278                        ← 上一轮自己手动塞进去的验证命令
```

也就是说，上一轮报告里那句
`node -e "... globalThis.__dshSchemastery = z; import('./lib/index.js')"` → `Config defined: true`
**是自证**：先自己塞进去，再证明能取到。真实加载路径上没人塞，所以是 `undefined`。

宿主真正用的是它自己 `node_modules` 里那份：

| 包 | 路径 | 版本 |
|---|---|---|
| schemastery | `resources/app.asar/dsh/node_modules/@deepseek-ai/schemastery` | 3.18.5 |
| schemastery（profile 那份，可被普通 node require） | `~/.dsh/profiles/desktop/node_modules/@deepseek-ai/schemastery` | 3.18.5 |

**修法**：`lib/hostdeps.mjs` —— 同步 `createRequire` 从宿主那棵树取，**不靠任何全局**。
根目录按可靠性排序，第一条就是 `process.resourcesPath`（正在跑的宿主自己那棵树）：

```
lib/hostdeps.mjs:30-60   schemasteryRoots()  → resources/app.asar/dsh/node_modules/@deepseek-ai 优先
lib/hostdeps.mjs:62-80   entryOf()           → 按 package.json exports 找入口
lib/hostdeps.mjs:85-105  loadSchemasterySync()/loadDefineToolSync() → 拿不到返回 null，绝不抛
```

为什么必须同步：cordis 读插件形状是**同步**读 module namespace 的 `Config` 导出
（`cordis/lib/index.js:52255` `Config: plugin.Config`），异步 import 来不及。

### Q2：原生表单保存的数据实际落在哪个文件？

**落在 profile 的 `cordis.patch.yml`**，而且和插件的配置是同一份。

链路（`app` → bridge → 宿主）：

| 环节 | 文件:行 | 做什么 |
|---|---|---|
| App 表单 | `app/lib/state/plugin_config/plugin_config_bridge.dart` | `POST /dsh-go/v1/plugin-config/<entryId>` |
| 桥接路由 | `runtime/bridge/dsh-go-bridge/lib/plugin-config.js:289` `update()` | 校验 revision/ops，调 `editor.edit()` |
| 宿主写盘 | `resources/app.asar/dsh/node_modules/@deepseek-ai/dsh-config-editor/lib/index.js` `edit()` | 写 `profileContext.patchPath` |
| 落盘位置 | 同上 `get documentPath()` | `$DSH_HOME/profiles/<name>/cordis.patch.yml` |

所以「表单」和「插件读到的配置」**从来就是同一条链**，只要插件真的去读注入的 config。

### Q3：插件运行时从哪里读配置？

**cordis 把校验后的 config 作为 `apply(ctx, config)` 的第二个参数传进来**
（`cordis/lib/index.js:34937` 附近 `runtime.callback(this.ctx, this.config)`），
走 `resolveConfig(runtime, config)` → `runtime.Config['~standard'].validate(config)`
（`cordis/lib/index.js:30882`）。

**上一版的错**：`apply(ctx, options)` 第二个参数被当成 options，配置一律自己读 JSON。
于是「表单改了」和「插件读到的」是两套数据源。

**修法**：`lib/config.mjs`

```
config.mjs:40-58    setLiveConfigSource() / hasLiveConfig()
config.mjs:118-135  unwrapLive()：volatile 字段是 { get() } 引用，每次现取
config.mjs:150-175  loadConfig()：有 host config 就**只认它**；没有才读 JSON
```

`index.js:193` `apply(ctx, hostConfig, options)`，并保留 `apply(ctx, { defineTool })` 的旧调用兼容。

### Q4：表单修改能否真正改变运行行为？

**能，而且是即时的。** 每个字段都标了 `.extra('volatile', true)`，cordis 因此走
`equalExceptVolatile` → `_commitVolatile()`（`cordis-plugin-loader/lib/index.js:13358`），
**不重启插件**，直接把新值写进已有的 volatile 引用。

于是「每次现取」的闭包设计成立：系统提示的 `text()` 每轮现调 `loadConfig()`，读到的是新值。

---

## 2. 端到端验证（真引擎，不是模拟）

工具是仓库里的 `examples/plugins/dsh-go-partner/live-host/`：

- `setup.mjs`：搭临时 profile，把 partner 当**用户安装的 bundle** 挂进去（真安装的形状，
  `owner=installed` / `kind=plugin`），不是 overlay 行 —— 白名单只放行 bundle 里的行。
- `observer.mjs`：只用公开服务，把 `entry.fiber.config`、`systemPrompt.assemble()` 暴露成只读路由。
- `run.mjs`：跑 15 条断言，任意一条失败退出码非 0。

真跑结果（引擎 = 本机 DeepSeek Harness 0.2.1-rc.2，`ELECTRON_RUN_AS_NODE=1`）：

```
PASS  宿主提供真 Config（表单可读）
PASS  人格进了系统提示
PASS  心情进了每轮上下文
PASS  四个工具都注册上了
PASS  改 persona.style 被接受
PASS  persona.style 立刻出现在系统提示里
PASS  关记忆 → 提示段不再提记忆
PASS  关情绪 → 心情上下文为空
PASS  关工具 → 提示段为空
PASS  关人格 → 人格段为空
PASS  恢复后人格段回来
PASS  重启后 style 仍是改过的值
PASS  重启后系统提示仍带它
PASS  重启后四个工具仍在
PASS  重启后原生表单读到同一个值

15/15 通过
```

其中「重启」是**真的杀进程再 spawn**，不是同一个进程里换个变量。

### 真机暴露的 4 个 bug（上一轮全都没发现）

| # | 现象 | 根因 | 修法 |
|---|---|---|---|
| 1 | 日志 `[partner] 工具注册失败：cannot get property "tools" without inject` | cordis 的 ctx 是 **Proxy**，没在 `inject` 里声明过的服务**读一下就抛**，不是返回 undefined。上一版裸读 `ctx.tools` | `index.js:240` 起改用 `ctx.inject(['tools'], …)`；读服务处全部包 `try` |
| 2 | `Cannot find package '@deepseek-ai/dsh-tools'` | 插件零依赖，动态 import 在真机上必然失败 | `hostdeps.mjs` 同步从宿主树 require `defineTool` |
| 3 | 工具开关打开后，工具再也不出现 | `tools.enabled` 是 volatile ⇒ cordis **不重启**，apply 里那个「开没开」的判断停在上次启动的值 | 注册**永远做**，开关在**每次执行时**现查（`tools.mjs` 的 `offReason`） |
| 4 | 目的面板恒空 | `path.join(process.env.DSH_HOME || '', 'surfcore')` 在没设环境变量时拼成相对路径 | 改用 `dshHome()` |

---

## 3. 任务 A：identityPanel 接线

`identityPanel()` **确实没在 index.js 里注册** —— 上一轮只加进 `views.mjs`，是个死的导出。
`grep -n identityPanel lib/index.js` → 0 命中（基线 `ac04b38` 上即可复现）。

处理方式不是「把它接上变成第 5 个面板」（插槽上限 4 个，而且是两套几乎一样的人格面板，
长久了必然漂成两种说法），而是：

- 把 identityPanel **独有的两块**（四个模块的开关状态、配置来源说明）折进唯一的 `personaPanel`；
- 删掉 `identityPanel` 这个死函数；
- 顺手删掉另外两个同样「导出着但没人用」的旧面板 `moodPanel` / `memoryPanel`
  （它们读的是更早的 `records/status` 形状，早就被 `moodStatePanel` / `memorySectionsPanel` 取代）；
- 加一条测试把这类病钉死：`host-sdk.test.mjs`「views 里每个 `*Panel` 都必须被 index.js 真的用上」。

### Purpose 自主目的系统：**如实保留 PARTIAL**

surfcore 有真的 `purpose-outreach.json`（本机实测在
`~/.dsh/surfcore/characters/char-mvuaxf54/purpose-outreach.json`，含 drives / goals / pending），
所以**面板读的是真数据**。但「按驱力自己决定开口」这一层属于 surfcore 自己的引擎，
本插件**没有接管**，也不假装接管：

- 两个按钮如实写「这一块只读；真正开口由 surfcore 的引擎负责」；
- 没数据时 callout 说明**具体原因**（没有 surfcore / 角色还没生成过念头 / current.json 里没 id），
  不再用一句「还没做（P2）」糊过去；
- 页面文案明确写「只读 surfcore，不接管」。

---

## 4. 任务 C：真实工具验证（从 NOT_TESTED 变成真跑通）

`real-dsh-tools.test.mjs` 那个 skip 的原因是 `findRealDshTools()` 用普通 node 路径找，
而真 `dsh-tools` 在 `app.asar` 里 —— **普通 node 读不到 asar**，不是没有。

本轮改成先走 `hostdeps.mjs`（和运行时同一套解析），于是：

```
$ node --test test/real-dsh-tools.test.mjs
﹣ 真 defineTool：… (skipped: 普通 node 读不到宿主 app.asar 里的 @deepseek-ai/dsh-tools。用 Electron 以 node 身份跑…)

$ set ELECTRON_RUN_AS_NODE=1 && "DeepSeek Harness.exe" --test test\real-dsh-tools.test.mjs
✔ 真 defineTool：四个工具都能通过 DSH 的 schema 编译 (36.2108ms)
ℹ tests 1  ℹ pass 1  ℹ fail 0  ℹ skipped 0
```

**这是真的 `defineTool`**（`@deepseek-ai/dsh-tools` 的 `lib/index.js`，宿主自己那份），
不是 `(o) => o` 的假替身。普通 node 下仍然 skip，并**写清了为什么、以及怎么跑**。

---

## 5. 任务 D：记忆安全（逐条给证据）

新增 `test/safety.test.mjs`，5 条全过，每条都落在代码路径上：

| 要求 | 证据 |
|---|---|
| 上游 fish-memory 只读 | 「上游只读」：跑完四个面板视图 + 三份数据读取 + 两次纠正写入后，`session-s1.json` **base64 比对完全一致** |
| 上游 feiyu-mood 只读 | 同上快照里包含 `feiyu-mood/{config,state}.json`，一并比对 |
| partner 纠正数据独立写入 | `correct()` 之后 `~/.dsh/partner/memory-corrections.json` 存在，上游字节不变 |
| 改/藏后能正确刷新 | 「纠正层独立」：hide → 下一次 `loadLongTermFull` 里没有它、`recall` 返回 0；show → **立刻**回来（无缓存假象）；rewrite → 检索用新文本，上游原文还在 |
| 人格与记忆不得覆盖系统安全约束 | 「人格与记忆是上下文，不是新的安全授权」：断言 hint 段必须含「**不能推翻系统提示里更上位的约束**」+ 沙箱 / 审批 / 隐私边界三个词（这段是本轮新加的，见 `index.js` 的 `partner:hint`） |
| 不读屏幕/窗口/剪贴板 | 「不读屏幕…」：在 5 个「读了就能拿到」的位置放诱饵文件，**包住 `fs.readFileSync/openSync/statSync/readdirSync` 记录所有真实打开路径**，断言没有任何命中；同时断言监视器本身抓到了调用（否则这条断言没意义） |

---

## 6. 交付物

| 文件 | 变更 |
|---|---|
| `lib/config.mjs` | 唯一配置源（host config 优先），`unwrapLive` 现取 volatile，`__legacy` 如实提示旧文件失效 |
| `lib/hostdeps.mjs` | **新增**：同步从宿主树取 schemastery / defineTool，永不抛 |
| `lib/index.js` | `apply(ctx, hostConfig, options)`；`Config` 用真 schema；系统提示挂到 `systemPrompt` 服务；工具走 `ctx.inject(['tools'])`；purpose 面板修 `dshHome()` 与如实文案；hint 加「不得覆盖更上位约束」 |
| `lib/tools.mjs` | 开关改成**每次执行现查**，关掉时明确拒绝 |
| `lib/views.mjs` | 删死函数 `identityPanel` / `moodPanel` / `memoryPanel`；`personaPanel` 加上模块开关 + 配置来源 + 旧文件提示 |
| `lib/hostdeps.mjs` + `test/dsh-tools.js` | `real-dsh-tools` 改成从宿主树解析 |
| `test/config-live.test.mjs` | **新增** 4 条：真 schema、唯一配置源、volatile 现取、面板文案 |
| `test/module-switch.test.mjs` | **新增** 3 条：Proxy 语义、工具开关运行期语义、三开关独立 |
| `test/safety.test.mjs` | **新增** 5 条：任务 D 全部要求 |
| `test/host-sdk.test.mjs` | 新增 2 条：无死面板导出、人格面板带开关 |
| `live-host/` | **新增**：真引擎端到端（setup / observer / run / README） |

### 测试实数（原文）

```
$ node --test          # 普通 node，examples/plugins/dsh-go-partner
ℹ tests 111
ℹ pass 110
ℹ fail 0
ℹ skipped 1        ← real-dsh-tools：普通 node 读不到 asar，见任务 C

$ node lib/views.mjs --selftest
  全部视图在预算内，可以交给 App 渲染

$ node live-host/run.mjs --home <临时 profile> --port 39581
15/15 通过

$ ELECTRON_RUN_AS_NODE=1 "DeepSeek Harness.exe" --test test\real-dsh-tools.test.mjs
✔ 真 defineTool：四个工具都能通过 DSH 的 schema 编译
ℹ tests 1  ℹ pass 1  ℹ fail 0  ℹ skipped 0
```

### 真跑通 vs NOT_TESTED

| 项 | 状态 |
|---|---|
| Config 真的到了宿主（表单可读） | **真跑通**（真引擎，HTTP 200 + 22 个 schema 节点） |
| persona.style 改动影响系统提示 | **真跑通**（真引擎） |
| 重启后仍有效 | **真跑通**（真杀进程） |
| memory / mood / tools / persona 四开关 | **真跑通**（真引擎逐个断言） |
| 四个工具通过真 `defineTool` 编译 | **真跑通**（宿主那份 dsh-tools） |
| 真 `defineTool` 在普通 node 下的自动发现 | **不可得**（普通 node 读不到 asar；已写清绕法） |
| **原生设置页在真机 App 里的实际渲染** | **NOT_TESTED** — 需要真机/模拟器 + adb，本轮 `adb devices` 为 0 台设备。App 侧表单绘制属另一条链（`app/lib/ui/plugins/config/`），本轮只证到「宿主侧 schema 与写盘链路」 |
| **App ↔ 引擎联调（点保存按钮）** | **NOT_TESTED** — 同上，无可用设备；本轮用 `ConfigEditor.edit()`（表单最终调的就是这个 API）代替点击 |

---

## 7. 剩余阻塞与下一步

1. **真机 UI 验证仍然缺**：`adb devices` 空。要证「在 App 里点保存真的生效」，需要一台设备或一个
   可跑 Flutter 的目标；方案是把它塞进 `app/test/plugin_config/` 的假服务器用例（已有
   `plugin_config_bridge_test.dart` 覆盖控制器层），再加一条真机 smoke。
2. **purpose 自主开口**仍属 surfcore，本插件只读。如果以后要接管，得先决定「谁是唯一定时器作者」，
   否则会和 surfcore 打架 —— 这是设计决定，不是本轮该顺手做的。
3. **旧 `config.json` 要不要自动迁移**：本轮只做「如实提示已失效」。自动把文件值搬进 profile patch
   会写 `cordis.patch.yml`，属于破坏性操作，应该单独一轮 + 明确提示。
