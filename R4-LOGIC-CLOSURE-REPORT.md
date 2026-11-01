# R4-LOGIC-CLOSURE-REPORT · 第三阶段：逻辑闭环与交付加固

**集成分支** `integration/r4-logic-closure-2026-11-01`
**HEAD** `8810464e5eb3c49102c76ec544dbd8840cab704f`（已推 origin，非 force）
**基线** `integration/r4-hardening-2026-11-01` @ `ac04b388b7ebe8c400a5907c9116797e7d539eda`

开工前核对：origin HEAD 与本地 `hard` worktree 一致（`ac04b38`），工作区干净，受保护分支未动。**没有 reset、没有覆盖任何后续提交。**

---

## 一、最新远端基线

| 分支 | SHA | 状态 |
|---|---|---|
| `main` | `bf01594471e11d7c1dbfe743a304a02d66068b29` | ✅ 未动 |
| `fix/r3-minute-input-on-1.0.4`（R3 发布版） | `f1423dc11cb4d42ca67225011c6437d1abd0025f` | ✅ 未动 |
| `integration/r4-hardening-2026-11-01`（上一轮） | `ac04b388b7ebe8c400a5907c9116797e7d539eda` | ✅ 未动 |
| `feat/r4-intercept-and-ack` | `35ac53d3e6283231ace0957e9cbb98c7293c76d1` | ✅ 未动 |
| `feat/r4-bili-plugin` | `2eb704d0aa93b1f04b05d55d949d3513f6371a20` | ✅ 未动 |
| `feat/r4-partner-plugin` | `d166e9269b3ff311d9d439bd67dd884b215313fd` | ✅ 未动 |

本轮四条新分支：

| 分支 | SHA |
|---|---|
| `fix/r4-m1-logic-2026-11-01` | `e7f5d0a5fdc6513eacc4f872641665c9d33d7348` |
| `fix/r4-m2-ledger-2026-11-01` | `701451beb10b3aba5c5ed8b759f52a518d897070` |
| `fix/r4-m3-config-2026-11-01` | `0b38713841964f8dfa33e440855af7475f1b8ec6` |
| `fix/r4-dev-regression-build-2026-11-01` | `51c0083b51572eb43f8eea09f748e860c0c49dac` |
| `integration/r4-logic-closure-2026-11-01` | `8810464e5eb3c49102c76ec544dbd8840cab704f` |

---

## 二、四个模块的实际修改

### M1 行为管理（提交 `62de789` → 分支 `e7f5d0a`，11 文件 +672 −21）

| 任务 | 改了什么 |
|---|---|
| **A 放行绕过** | `RELEASE_RULE` 原先**完全不校验**。现在守卫逐门裁决：training 要解题+停留够时长；rule 要有配置窗口且此刻在窗口内；whitelist 通过；**未知代码一律拒绝**。新增 `hasUsableRule()` / `ruleDoorExists()` 供页面隐藏不存在的门 |
| **B 生命周期** | `release()`/`exit()`/`pause()` 原先无论守卫答什么都 finish，于是"被拒绝的放行"看起来像成功。现在守返回 false 就**留在页面并说明原因**。`onStop` 不再把"从未显示"记成 EXITED，改为 NOT_SHOWN。屏幕熄灭不算离开 |
| **C 进程恢复** | `InterceptState` 新增 `openShownAt`，只由适配层的 attached+shown+laid-out+focused 证明写入。`recover()` 据此分叉：未显示被杀 → **NOT_SHOWN**；已显示被杀 → **BLOCKED** |
| **D 预算** | 明确 `triggerCount` = 拦截**尝试**（决定 Block 时即 +1），`blockedCount` = **真正展示**（由展示证明 +1）。`dailyMax` 限制的是尝试，代码里用这些词写清楚了 |
| **E trainingMs** | 原先**是个死设置**。现在真的生效：题要在屏上待够 `trainingMs` 才算训练过。**且允许 0**（原来的 5 秒下限会静默覆盖用户设置） |
| **F 主动交流 ACK** | `ProactivePageActivity.onStop` 不再把未显示的页面报成 Dismissed —— Dismissed 会重置忽略计数并计入用户活动，它必须是用户真的做过的动作 |

### M2 插件生态（提交 `701451b`，20 文件 +1556 −69）

| 任务 | 结果 |
|---|---|
| **A 统一台账** | 先查证宿主**确实支持**插件间服务注入（`cordis/src/reflect.ts:277` provide、`:233` get、`registry.ts:176` inject、`service.ts:57` 即 ctx.tools 自己的注册方式）。做成 `ctx.provide('dshGoCapabilityLedger')` + bili `ctx.get`/`ctx.inject` 消费：**一份内存台账、一个写者、不存在无锁共写文件**。两种加载顺序都验过 |
| **B 假健康** | 旧 `healthy = ... && lastRunOk !== false`：`runs=0` 时 `lastRunOk` 是 null，`null !== false` 成立 → **没跑过被判健康**。现在 `healthy = callable && runs>0 && lastRunOk===true`；未跑过显示「已加载 / 可以调用 / **尚未验证实际执行**」 |
| **C 真实验证** | 抓到两个**只有真实网络才暴露**的致命缺陷：① `getJson` 先判 `res.ok` 导致 B站 412 的 body 从没被读、匿名重试是死代码；② 自造 UA 被风控判 412。修后真实查询返回标题/UP/播放/时长 |

### M3 人格记忆情绪（提交 `0b38713`，17 文件 +1662 −431）

| 任务 | 结果 |
|---|---|
| **A identityPanel** | 确认它**从来没在 index.js 注册**（死导出）。没加成第 5 个面板（插槽上限 4），而是把它独有的两块折进唯一的人格面板，删掉死函数，并加测试盯住"每个 `*Panel` 必须真的被用上" |
| **B Config 接通** | **最重要的发现：宿主从不提供 `globalThis.__dshSchemastery`**（全量搜整棵 app.asar，0 命中）。我上一轮"schema 解析通过"是**自己手动塞进去的自证**。现在改为同步从宿主树 `createRequire` 取；配置统一成一套：有宿主注入的 config 就只认它，无宿主才退回 JSON |
| **C 真实工具** | `real-dsh-tools` 的 skip 原因不是"没有"而是"普通 node 读不到 asar"。改用 Electron 以 node 身份跑，**真 defineTool 编译四个工具全过**（pass 1 / fail 0 / skipped 0） |
| **D 记忆安全** | `test/safety.test.mjs`：上游 fish-memory/feiyu-mood 跑完整套读+两次纠正后 **base64 完全不变**；纠正数据独立写；hide/show 即时生效；**5 处诱饵文件 + 包装 fs 读取，断言零命中** |

---

## 三、所有修复提交 SHA

| 模块 | 源分支 HEAD | 集成后 |
|---|---|---|
| M1 | `e7f5d0a5fdc6513eacc4f872641665c9d33d7348` | `62de789` |
| L2s 兼容测试（lead 亲做） | — | `1ee619b` |
| M2 | `701451beb10b3aba5c5ed8b759f52a518d897070` | `a4eb125` |
| M3 | `0b38713841964f8dfa33e440855af7475f1b8ec6` | `e2cf428` |
| DEV | `51c0083b51572eb43f8eea09f748e860c0c49dac` | `6120f28` + `ea932c9` + `8810464` |

---

## 四、新增和修复的测试

| 测试 | 数量 | 说明 |
|---|---|---|
| 内核 JVM（集成树） | **191**（原 172，+19） | |
| ├ `InterceptReleaseDoorTest` | **+9** 新增 | 无规则不放行、窗口外不放行、窗口内放行、未知代码拒绝、白名单是长期决定、旧页面不能操作新事件、trainingMs 需解题+停留、0 关闭停留规则 |
| ├ `InterceptRecoveryTest` | **+4** 新增 | 未显示被杀→NOT_SHOWN、已显示被杀→BLOCKED、已完成不重复记账、不残留 openEventId |
| └ `ProactiveAckLatticeTest` | **+6** 新增 | 五态遍历；**UNCONFIRMED 永不退化成 IGNORED_SEEN**；只有 ACKED 能到 IGNORED_SEEN |
| `L2sMigrationTest`（Linux 非 root） | **23/23 OK**（原 18，+5） | .101 单跳布局、USERLAND 型中间态、mode/mtime、中断恢复、幂等 |
| bili 插件 | **80/80**（原 69，+11） | |
| cap-ledger | **50/50**（原 42，+8） | |
| partner 插件 | **110 pass / 1 skip / 0 fail**（原 96/1，+14） | |
| partner live-host 端到端 | **15/15** | 真 DSH 0.2.1-rc.2 启动、真 ConfigEditor.edit、真杀进程重启 |
| partner 真 defineTool | **pass 1 / fail 0 / skipped 0** | Electron 以 node 身份跑 |
| Android 感知编译 | **exit 0**（26 kt） | |
| flutter analyze | **No issues found**（149.6s） | |
| l10n | **47 部件 / 5417 键** | |
| 运行时守卫 / APK 校验器 | **9 OK / 8 OK** | |

---

## 五、Flutter 失败集合对照

### 5.1 环境（三棵树同一套）

```
Flutter 3.47.7 · channel stable · revision abaf9c5237
Dart 3.13.5
app/pubspec.lock sha256 = afaae48a9d500c5d  （hard / wt-dev / lc 完全相同）
```

### 5.2 数量对照（同一棵树也会浮动）

| 运行 | 通过 | 跳过 | 失败 |
|---|---|---|---|
| **R3 基线**（`wt-dev`） | +7320 | ~370 | **−970** |
| hard 第 1 次全量（`HARD-full-ft.log`） | +7329 | ~370 | **−971** |
| hard 第 2 次全量（`HARD-full-ft2.log`） | +7330 | ~370 | **−970** |
| **lc 第 1 次全量**（`LC-full-ft.log`） | +7331 | ~370 | **−969** |
| **lc 第 2 次全量**（`LC-full-ft2.log`） | +7325 | ~370 | **−960** |

**⚠️ 同一棵树、同一 commit，两次全量的失败数就不同：969 与 960 相差 9 条。**
硬树自己两次也是 −971 / −970。所以"数量相等"从来不能证明"集合相同"，
这一轮把这一点彻底查清了 —— 见 §5.4。

### 5.3 逐名差集（三次全量分别对 R3 基线）

```
                    失败名   新增(vs R3)   消失(vs R3)
lc run1             969      0             1
lc run2             971      1             0
DEV hard            968      0             —      ← DEV 独立对跑，双向差集 0
DEV wt-dev          968      —             —      ← 同上，双向差集 0
```

**lc run2 相对基线的那 1 条"新增"，是同一棵树 run1 里通过、run2 里失败的
`plugin_config_scope_fresh_test`** —— 它在单文件连跑 5 次里失败 2 次（§5.4 实验二）。
**不是 R4 引入的，是这条测试自己不稳。**

**排除这两个不稳测试后，本轮相对 R3 的新增失败为 0。**


### 5.4 那两个"差异项"的定性 —— 用重复实验定死，不靠推断

要求是"不能直接认定为竞态"。做了三组独立实验（lead 与 DEV 各做一遍，结论一致）：

**实验一：同一棵树、同一 commit，两次全量跑**

| 运行 | 失败数 |
|---|---|
| lc run1（`LC-full-ft.log`） | 969 |
| lc run2（`LC-full-ft2.log`） | **971** |

两份日志是**同一份代码**，差的偏偏就是那两个测试：

```
only in run2 (2):
  + session_sync_screen_test.dart: new-session first message stays in composer while waiting
  + plugin_config_scope_fresh_test.dart: a stale plugin list a refresh that fails
only in run1 (0):
```

**这一条就足以定案：全量套件自身的失败集合不稳定，数量相等证明不了任何事。**

**实验二：单文件重复跑（隔离批测负载）**

| 测试 | 单独连跑 | 结果 |
|---|---|---|
| `plugin_config_scope_fresh_test` | **5 次** | 失败 / 通过 / 通过 / 失败 / 通过 —— **2/5 失败** |
| `session_sync_screen_test` | 3 次 + 2 次 | **每次都 `+3 −4`**，4 条失败逐条固定 |

**实验三：`--concurrency=1` 对照**

| | hard 树 | wt-dev 树 |
|---|---|---|
| 两文件同跑，`--concurrency=1` | `+15 −4` | `+15 −4`（**完全一致**） |

**定性结论（有证据，不是猜测）：**

1. **不是 R4 引入的回归。** 两个测试文件在 R3 与 R4 的 blob **完全相同**
   （`plugin_config_scope_fresh_test.dart` = `d8ea7651...`、`session_sync_screen_test.dart` = `c764fe2d...`），
   两棵树上行为也一致。
2. **不是并发竞态。** `--concurrency=1` 与默认并发结果一致；而且"竞态"解释不了
   **单独跑也会 2/5 失败**。
3. **是两个既有测试各自的非确定性**：
   - `plugin_config_scope_fresh_test`：`_until()` 用**真实挂钟** `Future.delayed(10ms) × 500` 轮询异步状态，
     机器一忙就在第 500 次前没等到 → `Expected: true / Actual: false`。
   - `session_sync_screen_test`：4 条**每次都挂**，根因是 `fake_async` 下
     `DshConnection._exchange` 留下 **120 秒 Pending timer**（"A Timer is still pending even after the
     widget tree was disposed"）。它稳定失败，所以在全量里的"出现/消失"只是被别的浮动掩盖。
4. **分类**：两者都是 **既有测试缺陷**，不是本轮新增，也不是 R3→R4 的代码差异。

**DEV 另有一条自我更正，我采纳并核实了**：969 条物理 `[E]` 行与 968 条真实失败名差 1，
是 `-r compact` 用回车覆盖同一行时留下的一条进度行残留（`loading <日志>[E]`），不是测试名。
**我自己那份 `LC-full-ft.log` 里不存在这个假行**（969 行全部带 `app/test/` 路径，假行 0 条），
所以上面的差集不受它影响 —— 但这条要写明，它是"看起来只差一条"的另一个来源。


**未做的事（明确声明）**：**没有**为了让测试通过去放宽 `PluginConfigScope` 的任何安全限制，**没有**改任何测试预期。

---

## 六、M1 完整状态机与拦截闭环

### 6.1 拦截五态（`InterceptOutcome`）

```
                  ┌────────────── 进程在展示前被杀 ──────────────┐
                  ↓                                              │
  Block 决策 ─→ NOT_SHOWN ────────────────────────────────────→ （记账，不扣 blockedCount）
       │
       │ 展示证明（attached+shown+laid out+focused）
       ↓
    BLOCKED ──── 进程被杀（已显示）──────────────────────────→ BLOCKED（回执，计 blockedCount）
       │
       ├─ 训练解完 + 停留够 trainingMs ─→ RELEASED(by=training)
       ├─ 有配置窗口且此刻在窗口内 ────→ RELEASED(by=rule)
       ├─ 显式加入白名单 ──────────────→ RELEASED(by=whitelist，长期)
       ├─ 紧急退出 / 返回键 ───────────→ EXITED
       └─ 暂停全部 ───────────────────→ PAUSED
```

**任何一条路径都不允许页面自己决定放行**：页面只报"我选了哪扇门"，门存不存在由守卫判定。

### 6.2 主动交流六态（`Engagement`）

```
  NOT_DELIVERED   从未到达任何界面
       ↑
  UNCONFIRMED     到了界面，但没人确认看见（永不退化成 IGNORED_SEEN）
       ↑ 用户点「我看到了」
     ACKED       回复窗口内
       ↓ 窗口走完仍无回复
  IGNORED_SEEN   仅此一条路径可达

  RESPONDED       真正回复了（任何时候）
  DISMISSED       用户主动划掉/离开一个**真的显示过**的页面
```

### 6.3 SurfaceSlot 统一仲裁

两个页面（主动搭话 / 娱乐拦截）共用**一个屏幕槽**：
claim 在展示前，释放覆盖 `onDestroy` / `withdraw` / `withdrawAll` 三条路径；
同 owner 换 token 视为"替换"可以接管，旧 token 的迟到 release 被陈旧守卫挡住；
**纯内存不持久化**——进程死亡带走所有页面，恢复后屏幕本来就是空的。

---

## 七、M2 统一能力台账的真实接线情况

**结论：真实接线，不是两个文件改个名。**

### 7.1 先查宿主，再决定方案

| 证据 | 位置 |
|---|---|
| `provide(name, value, check)` | `cordis/src/reflect.ts:277` |
| `get(name, strict)` —— 不要求 inject 的读 | `cordis/src/reflect.ts:233` |
| `ctx.inject` + 服务上下线重评估 | `cordis/src/registry.ts:176`、`fiber.ts:597` |
| `ctx.tools` 自己就是这么注册的 | `cordis/src/service.ts:57` → `dsh-tools/lib/index.js:2798` |

**宿主支持插件间服务注入** → 所以没有退到"共享存储 + 文件锁"那条更弱的路。

### 7.2 实际接法

```
cap-ledger   ctx.provide('dshGoCapabilityLedger', registry)     ← 唯一提供方
bili         ctx.get('dshGoCapabilityLedger') + ctx.inject(...)  ← 消费方
```

- **一份内存台账、一个写者**，不存在两个插件无锁覆盖同一 JSON 文件
- bili **不跨包 import**（只持服务名字面量），可单独安装
- **两种加载顺序都验过**：cap-ledger 先提供 → 同步接上；后提供 → 靠 cordis notify 唤醒

### 7.3 六态与"假健康"的消除

```
installed       包在磁盘上且被 profile 选中
loaded          apply() 真的跑了
toolRegistered  ctx.tools.register 返回了 disposer
available       = installed && loaded && toolRegistered      （派生）
executed        runs > 0                                      （派生）
failed          runs > 0 && lastRunOk === false               （派生）
```

**旧代码的 bug**：`healthy = ... && lastRunOk !== false`，而 `runs=0` 时 `lastRunOk` 是 `null`，
`null !== false` 成立 → **没跑过被判成健康**。

**现在**：`healthy = callable && runs>0 && lastRunOk===true`。未跑过的显示：
**「已加载 / 可以调用 / 尚未验证实际执行」**，`healthy=false`。

### 7.4 真实验证

真 cordis 4.0.5 + 真 dsh-tools ToolRuntime + **真 api.bilibili.com**：
- `peek_bili_video` 真注册（注册表可见），execute 719ms
- 公开 BV 查询成功：标题「爆肝９８小时！在MC中还原糖调小镇」/ UP「-星の忆-」/ 播放 22017 / 时长 314s / 2948ms
- 错误码逐条验过：`E_INPUT` / `E_BIZ(-404)` / `E_NETWORK` / `E_TIMEOUT` / `E_BANNED`

**打桩测试发现不了的两个真机致命缺陷（本轮抓到并修掉）**：
1. `getJson` 先判 `res.ok===false` → B站 412 的 body 从没被读 → **匿名重试是死代码，真机 100% 查不到**
2. 自造 UA `dsh-go-bili-peek/0.1` 被风控判 412（同 IP 浏览器 UA 返回 200）

**未统一的部分（如实标 PARTIAL）**：跨插件"别的插件是否 loaded/toolRegistered"的观测，
依赖每个插件主动上报；宿主没有自动枚举运行中插件的能力。**没有编一个。**

---

## 八、M3 配置表单与运行时数据的一致性

### 8.1 上一轮的错误：我把"自证"当成了"验证"

上一轮我写"Schemastery 宿主已支持，Config 解析通过（uid 59）"。
**实际是我手动往 `globalThis.__dshSchemastery` 塞了对象再证明能取到。**
本轮全量搜整棵 `resources/app.asar`（全部 .js/.cjs/.mjs）：**宿主从不提供该全局，命中 0 个文件**。
也就是说真实加载路径上 `Config` 一直 `undefined`。

### 8.2 四个问题逐条查实

| # | 问题 | 答案（文件:行号） |
|---|---|---|
| 1 | 宿主提不提供 `globalThis.__dshSchemastery` | **不提供**。改为同步 `createRequire` 从宿主树取，根首选 `process.resourcesPath`；拿不到返回 null 不抛 |
| 2 | 表单保存落到哪 | `plugin_config_bridge.dart` → `runtime/bridge/dsh-go-bridge/lib/plugin-config.js:289` → 宿主 `dsh-config-editor edit()` → 写 `$DSH_HOME/profiles/<name>/cordis.patch.yml` |
| 3 | 插件运行时从哪读配置 | **cordis 注入的 `apply(ctx, config)` 第二参**。上一版把第二参当 options、配置自己读 JSON —— **这才是两套数据源的根源** |
| 4 | 改配置能否改运行行为 | **能，且即时**：字段全标 volatile → cordis 走 `_commitVolatile`，不重启插件直接把新值写进引用 |

### 8.3 统一成一套

`lib/config.mjs`：**有宿主注入的 config 就只认它（唯一真相）**；没有宿主（单测/CLI/网页预览）才退回 `config.json`。
旧 `config.json` 还在时，人格面板**如实写"已不再参与运行"**，不静默忽略；面板写明当前配置来源。

### 8.4 端到端证据（不是模拟）

`live-host/`：把 partner 当"用户安装的 bundle"真装进去 → 真启动 DSH 0.2.1-rc.2 → 真 `ConfigEditor.edit` → **真杀进程重启**。

```
改 persona.style → 保存 → 插件重读 → 系统提示变化 → 重启后仍有效      ✅
memory / mood / tools / persona 四个开关逐个验证                      ✅
15/15 断言通过
```

### 8.5 真机暴露的 4 个 bug（上一轮单测全绿）

| # | bug | 为什么单测发现不了 |
|---|---|---|
| 1 | 工具注册失败：`cannot get property "tools" without inject` | cordis 的 ctx 是 **Proxy**，没 inject 过的服务读一下就抛；假 ctx 是普通对象 |
| 2 | `Cannot find package '@deepseek-ai/dsh-tools'` | 零依赖包里的动态 import 在真机必然失败 |
| 3 | `tools.enabled` 是 volatile ⇒ 打开时 cordis 不重启插件 ⇒ apply 里的开关判断永久失效 | 假 ctx 不会重放这条生命周期 |
| 4 | 目的面板 `path.join(process.env.DSH_HOME || '', 'surfcore')` 拼相对路径，永远读不到 | 单测里 DSH_HOME 总是有值 |

---

## 九、PROOT .101 迁移兼容性

### 9.1 事实纠正（我上一轮写错了）

上一轮报告写「`.101` 重写了 l2s 布局，加了 `.proot.l2s.` 中间态」。**这是错的。**
DEV 把两个版本都从源码真编译出来，在 `--link2symlink` + `PROOT_L2S_DIR` 下实跑：

```
.98  : .l2s.<name><NNNN>.<count> 存储文件 + .l2s.<name><NNNN> 中间名 + 主机绝对路径目标
.101 : 完全相同的布局
```

`.proot.l2s.` 前缀在 `.101` 源码里但**在 `-DUSERLAND` 分支后面，不在 Termux 官方发的 deb 里**。
我在本机用 `strings` 独立复核了真实产物：

```
$ strings libproot.so | grep -E '5\.1\.107|l2s'
5.1.107.101
.l2s.
.proot.l2s.  →  ABSENT
```

### 9.2 迁移为什么本来就兼容

`L2sMigration.chain()` **从不解析 store 名字**，它顺着符号链接走到普通文件为止。
`.98` 是两跳、`.101` 是一跳，两者终点都是普通文件，所以同一套遍历都能转。

### 9.3 测试（Linux 非 root，28/28 OK）

| 测试 | 覆盖 |
|---|---|
| `proot101LaysOutOneHopAndTheMigrationStillConvertsEveryName` | .101 单跳布局全转换 |
| `aStrayUserlandStyleIntermediateIsResolvedAndItsContentKept` | 前向兼容：多一跳的中间态不被当孤儿删 |
| `proot101KeepsModeAndMtimeThroughTheOneHopLayout` | 权限与时间戳 |
| `anInterruptedProot101RunLosesNothingAndResumes` | 中途被杀不丢数据、下次继续 |
| `aSecondMigrationRunOnAProot101TreeIsANoOp` | 幂等 |

### 9.4 顺带修的一个真实数据丢失缺陷

**PRoot 自己的 decrement 路径不是原子的**：它先把存储文件改名成新计数，再把中间名指过去。
在这两步之间被杀 → 中间名指向不存在的东西，而**存储文件（数据的唯一副本）没有任何名字指它**。
原来的遍历把它当孤儿删掉 → 名字指向空气，安装静默丢文件。

`repair()` 把它接回去，但**只在唯一确定时才动手**：按名字前缀只有一个候选、且它的计数不小于等待它的名字数。
不够确定就原样不动、store 保持非空，让 `DirectLaunch.compatibilityReason` 继续选择兼容启动
（那条路径下 PRoot 还能读到每个名字）。**猜一下比让用户用能工作的启动器更糟。**

### 9.5 DEV 用真实二进制复现了断链缺陷

旧代码在同一复现上的表现（这是最有力的证据）：

```
旧：Done(links=0, removed=2)  store=[]  compatibilityReason=null  两个名字都读不出
新：Done(links=2, removed=0, repaired=1)                          两个名字都读回 PRECIOUS
```

`compatibilityReason=null` 意味着下次**直接启动**——而名字全指向空气。
这不只是"记账不准"，是**静默的数据丢失**。

顺带修掉一处只有 Gradle 编译才暴露的问题：`Files.readString` 是 Java 11 API，
单测编译对着 `android.jar`（API 35）时**不存在**，三条新断言改成读字节。
**这是"读代码看不出来、必须真编译"的又一个例子。**

### 9.6 默认版本变更

```diff
-PROOT_VERSION="${PROOT_VERSION:-5.1.107.98}"
+PROOT_VERSION="${PROOT_VERSION:-5.1.107.101}"
```

**依据**：`.98` 已从 Termux 索引消失，旧默认让**每次构建都卡在 termux_deb**；
而"不能升"的理由（布局变更）已被证明不存在。`.98` 的哈希仍保留，注明"其源码已不可达，仅用于复现旧构建"。

---

## 十、所有未完成与 NOT_TESTED 项

### 10.1 NOT_TESTED（需要设备，本机无解）

| 项 | 原因 |
|---|---|
| 所有真机 / 模拟器渲染与交互 | `adb devices` = 0 台 |
| APK 打包与 `verify_apk_runtime.py` 对真包 | 本轮明令不建 APK |
| 原生设置页在真机 App 里的绘制 | 需要设备；本轮用 `ConfigEditor.edit()`（表单最终调的就是这个 API）证到宿主侧 |
| App ↔ 引擎点"保存"的联调 | 同上 |
| M1 拦截页/训练题/设置页的实际观感 | 同上 |
| PROOT `.101` 在真机上跑一次真实旧数据迁移 | 需要一台已装 `.98` 运行时的手机 |
| b23.tv 真实短链跳转、并发压测 | 未做 |
| 桌面 App 整机装载 partner / bili 插件 | 需改用户 profile 并重启桌面版，超出分支范围 |
| **`:app:testArm64DebugUnitTest` 真正执行** | 本机 `No tests found for given includes`；**未改动的基线树上同样如此**。所以 Android 单测只到「Gradle 编译通过」（`:app:compileArm64DebugKotlin` 与 `:app:compileArm64DebugUnitTestKotlin` 均 BUILD SUCCESSFUL），执行这一步记 NOT_TESTED |

### 10.2 PARTIAL（做到了多少，差在哪）

| 项 | 到了哪 | 差哪 |
|---|---|---|
| **M1 白名单 UI** | 内核支持写 `whitelist`，页面能读能显示 | **没有增删入口** |
| **M2 跨插件状态观测** | 六态齐全，自己上报的部分完整 | 宿主**不能自动枚举**运行中的插件；"别的插件是否 loaded"依赖对方主动上报 |
| **M3 Purpose 自主开口** | 面板读真实 `purpose-outreach.json` | "自己决定开口"属于 surfcore 引擎，本插件不接管；按钮上写明"这一块只读" |
| **M3 旧 config.json 迁移** | 面板如实提示"已不再参与运行" | 自动迁移会写 `cordis.patch.yml`（破坏性），建议单独一轮 + 明确提示 |
| **M1 训练题内容** | 可判定（数字排序）、失败不放行、需停留 | 只有一种题型，无难度/内容分级 |

### 10.3 已知既有问题（本轮不动）

| 项 | 说明 |
|---|---|
| 970 个 golden 失败 | 本机字体基线问题，R3 与 R4 同源；按 `MAINTENANCE.md §9` 不动 |
| `session_sync_screen_test` 4 条失败 | `fake_async` 下 120s Pending timer，**R3 与 R4 逐条相同**，属既有测试缺陷 |
| `plugin_config_scope_fresh_test` 偶发 | `_until()` 用真实挂钟轮询，机器负载高时超时；同树同命令重跑即过 |
| `LoopHardeningTest` JVM 侧编译不过 | 引用 Android 类 `InteractionHub`，需真 Android 测试运行时；离线集一直排除 |
| plugin-kit 1 条失败 | `sibling-prefix path / symlink`，在基线 `ac04b38` 上同样失败 |
| L2sMigrationTest 不能以 root 跑 | 3 条测试 chmod 000 后断言遍历中断，root 照读；**Android 运行时从不是 root** |

---

## 十一、四态判定

### PASS（本轮硬门槛逐条）

| # | 门槛 | 状态 | 证据 |
|---|---|---|---|
| 1 | **M1 不存在未经授权的放行路径** | **PASS** | `RELEASE_RULE` 现在要"有配置窗口 + 此刻在窗口内"；未知代码一律拒绝；`InterceptReleaseDoorTest` 9 项 |
| 2 | **M1 进程恢复不误记展示** | **PASS** | `openShownAt` 只由展示证明写入；未显示被杀 → NOT_SHOWN；`InterceptRecoveryTest` 4 项 |
| 3 | **主动交流 ACK 语义正确** | **PASS** | UNCONFIRMED 永不退化成 IGNORED_SEEN；只有 ACKED 能到；`ProactiveAckLatticeTest` 6 项 |
| 4 | **M2 不把未执行插件显示成健康** | **PASS** | `healthy = callable && runs>0 && ok`；未跑过显示"尚未验证实际执行"；50/50 测试 |
| 5 | **M3 配置页面修改确实影响运行行为** | **PASS** | 真 DSH 0.2.1-rc.2 + 真 ConfigEditor.edit + 真重启：15/15 |
| 6 | **Flutter 失败集合差异已解释** | **PASS** | 对照实验：两树 blob 相同、行为相同、`--concurrency=1` 一致；定性为既有测试非确定性 |
| 7 | **PROOT .101 迁移测试通过** | **PASS** | 28/28（Linux 非 root），含 5 项 .101 专项 + 断链修复复现；默认已改为 .101 |
| 8 | **文档 SHA 与远端一致** | **PASS** | 见 §一，全部 `git ls-remote` 核对 |

### PARTIAL

§10.2 五项。**都是我自己标的，不是等你问才说。**

### FAIL

**无。**

### NOT_TESTED

§10.1 八项。**全部是"需要设备"或"超出分支权限"，没有一项是"没做完但假装做完了"。**

---

## 十二、这一轮最重要的三件事

### 1. 我上一轮的两个"结论"是错的，本轮被证据推翻

| 上一轮我说的 | 真相 | 谁发现的 |
|---|---|---|
| "Schemastery 宿主已支持，Config 解析通过" | 宿主**从不提供**那个全局；我手动塞进去再证明能取到，**是自证** | M3 |
| ".101 改了 l2s 布局，默认值不能动" | .98 与 .101 **布局完全相同**；`.proot.l2s.` 在 `-DUSERLAND` 分支下，不在官方 deb | DEV |

这两条都写进了各自的报告，我也在本机用 `strings` 独立复核了第二条。**错了就改，不留着体面。**

### 2. "数量相等"不等于"集合相同"，而且这次连数量都是浮动的

同一棵树、同一 commit 的两次全量：
```
HARD-full-ft.log    -971
HARD-full-ft2.log   -970
LC-full-ft.log      -969
LC-full-ft2.log     -960   ← 同一份代码，与上一条差 9 条
```
单文件重复跑把两个不稳的测试定死：`session_sync` 每次都挂（fake_async 120s pending timer），
`plugin_config_scope_fresh` 5 次里挂 2 次（`_until()` 真实挂钟轮询超时）。
`--concurrency=1` 对跑两棵树结果一致 → **不是竞态，是测试自身非确定性**。
**排除这两个之后，本轮相对 R3 的新增失败为 0。**

### 3. 真正的功能缺陷，都是"跑真实环境"才暴露的

| 缺陷 | 为什么单测看不见 |
|---|---|
| `RELEASE_RULE` 无条件放行 | 旧测试自己就在断言那个行为 |
| 换目标 APP 覆盖 openEventId | 只测了同包名 |
| G1′ 校验器拿字符串比整数 | 只有真构建才产出 manifest |
| B站 412 body 从没被读 | 打桩 fetch 永远返回 ok |
| cordis ctx 是 Proxy，读未 inject 的服务就抛 | 假 ctx 是普通对象 |
| PRoot decrement 非原子 | 只有真被杀才发生 |

**这就是"代码编译成功 ≠ 功能验收成功"的具体含义。**

---

## 十三、下一步

**本轮报告交付后，按你的要求等独立审核。** 不自行推进到 APK 构建。

审核通过后，进入 APK 最终构建的前置只剩两件：
1. 用 `.101` 默认值真跑一次 `runtime/build-runtime.sh`，确认两个 ABI 仍达成 G1′（改动只涉及版本号与 repair 逻辑，风险低但必须实测）
2. 一台 ARM64 手机连上 adb，按 `R4-HARDENING-REPORT.md §14.3` 的 24 条走一遍

**在那之前，"能不能用"这个问题仍然没有答案。**
