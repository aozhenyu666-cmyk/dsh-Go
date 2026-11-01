# R4-PHASE4-CHANGELOG · 每个缺陷一条

> 格式按任务书第四节的九项要求：缺陷编号 / 修改前行为 / 修改后行为 / 相关文件 / 测试名称 / 执行命令 / 原始输出 / Git SHA / 状态。
> 分支 `fix/r4-phase4-2026-11-01`，起点 `868dc330d8495b7d41c887cd268329aad5e3ffb5`。

统一执行命令（除特别说明）：
```
KOTLIN_JARS=/root/kernel-jars tooling/run-kernel-tests.sh
```
（Linux / WSL Ubuntu / JDK 21.0.12；**不能以 root 跑 L2s 那些 POSIX 权限测试，见 CHANGELOG 末尾**。）

---

## 阶段 A：测试体系

### A-1 内核测试不可在仓库内复现（P1-10）

| 项 | 内容 |
|---|---|
| 修改前 | 190/191 项靠仓库外脚本 `D:\code\R4\lc-verify.ps1` 跑；仓库里没有任何入口 |
| 修改后 | `tooling/run-kernel-tests.sh`：找 JDK → 找 jar（`KOTLIN_JARS` → Gradle 缓存 → `~/.m2`）→ 编译 `loop/core` + 不依赖 Android 的 loop 文件 → **自动发现**所有 `*Test` 类 |
| 文件 | `tooling/run-kernel-tests.sh`、`.gitignore` |
| 测试名称 | 脚本自身（无单测；以下 213/217 项即其输出） |
| 原始输出 | `sources: 38 / classes: 17 / OK (190 tests) / PASS` |
| Git | `f2c5f97` |
| 状态 | **PASS** |

### A-2 「191」这个数字是错的

| 项 | 内容 |
|---|---|
| 修改前 | 我一直报 191，其中硬编码了 `io.github.ccch1mneyyy.dsh_app.loop.ProtectedForegroundTest` |
| 事实 | **该类在仓库中不存在**（`Get-ChildItem -Recurse -Filter '*ProtectedForeground*'` 为空） |
| 修改后 | 真实数字 **190**，且由脚本自动发现，不再手写 |
| 状态 | **PASS**（数字更正） |

### A-3 Gradle「No tests found」根因（P1-10 后半）

| 项 | 内容 |
|---|---|
| 修改前 | 归因为"测试没被识别"，把执行记 NOT_TESTED |
| 事实 | `app/android/.gitignore` 第 1/4/5 行忽略 `gradle-wrapper.jar`、`/gradlew`、`/gradlew.bat`；仓库**从未有过 gradlew**；WSL 无系统 gradle；Gradle 任务还需要 Android SDK + `runtime/out` |
| 修改后 | 结论：**不是测试识别问题，是跑测试的工具不在仓库里**。本轮不修（属更大改动），改为让内核测试不依赖它 |
| 状态 | **PARTIAL**（根因已查明，修复未做） |

### A-4 `InterceptRecoveryTest` 测不到恢复（P1-9）

| 项 | 内容 |
|---|---|
| 修改前 | `ledgerBook(store)` 丢掉参数、新建空存储；"重启"复用同一内存账本；夹具 `cooldownMs=0` 掩盖 P0-3 |
| 修改后 | 一次重启 = **新 store（同一份字节）+ 新账本 + 新守卫**；`ReplayStore` 支撑共享字节；冷却用真实默认值。4 项 → **7 项** |
| 文件 | `T/loop/core/InterceptRecoveryTest.kt` |
| 测试名称 | `theLedgerTheNextRunReadsIsTheOneThisRunWrote`、`aRecoveredNotShownDoesNotChargeACooldown`、`corruptingOneStoreDoesNotCorruptTheOther` 等 7 项 |
| 原始输出 | 首次修改后：`Tests run: 193, Failures: 1`（证明新测试能抓到 P0-3）；修后 `OK` |
| Git | `ad823c6` 内 |
| 状态 | **PASS** |

---

## 阶段 B：五个 P0

### P0-3 NOT_SHOWN 仍扣冷却与每日额度

| 项 | 内容 |
|---|---|
| 修改前 | `onForeground` 决定 Block 时立即盖 `lastTriggerAt`、`countToday+1`；`onUnavailable` 与 `recover()` 都只 `endOpen(NOT_SHOWN)`，**不回滚**。结果：从未上屏的拦截让目标 APP 在冷却期被放行，并吃掉一格额度 |
| 修改后 | 两条路径都退还。`onUnavailable` 还原 Block 决定时捕获的旧值（`endOpen` 会清掉捕获，避免陈旧还原）；`recover()` 跨进程只做能证明的事：把这次触发的扣减拿掉，下限 0 |
| 文件 | `K/loop/core/Intercept.kt`（`onUnavailable`、`recover`、`onForeground`、`endOpen`） |
| 测试名称 | `aRecoveredNotShownDoesNotChargeACooldown`、`a_not_shown_interception_does_not_spend_the_cooldown`、`a_not_shown_interception_does_not_spend_the_daily_count`、`a_shown_block_does_spend_the_cooldown`、`aKilledAppComesBackToTheSameDrillNotAnEasierOne` |
| 原始输出 | 修前 `Tests run: 193, Failures: 1`（`a page that was never shown must not put the app in a cooldown`）；修后 `OK (194 tests)` |
| Git | `ad823c6` |
| 状态 | **PASS** |

**附带发现**：上一轮写的 `InterceptSurfaceBudgetTest` 两条测试**断言的就是这个 bug**（靠"被拒绝的那次刚武装了冷却"来证明"不该被扣第二次"）。已改为直接断言结局 + 新增反方向。

### P0-5 未展示页面可以走任何一扇门

| 项 | 内容 |
|---|---|
| 修改前 | `onReleased` 四个门（training/rule/whitelist/未知）**无一检查 `openShownAt`**；`onExited`/`onPaused` 也不查。且训练停留条件是 `shownAt != 0L && ...`，`shownAt==0` 时**整条件短路**——未展示反而最快通过 |
| 修改后 | ① `onReleased` 开头统一要求 `openShownAt != 0`；② `onExited` 无证明时结算为 **NOT_SHOWN**（不是 EXITED）；③ `onPaused` 同（设置页 `eventId=null` 不受影响）；④ 停留条件改为 `now - openShownAt < trainingMs`，不再有短路 |
| 文件 | `K/loop/core/Intercept.kt` |
| 测试名称 | `InterceptVisibilityGateTest` 6 项：三条放行门 + 两条动作门，各测"无证明被拒"与"有证明仍可用" |
| 原始输出 | 先写测试：`Tests run: 203, Failures: 5`；修后 `OK (203 tests)` |
| Git | `558a3b4` |
| 状态 | **PASS** |

### P0-4 guard.json / ledger.json 跨文件写入窗口

| 项 | 内容 |
|---|---|
| 修改前 | 两份文件各自原子（temp+backup+rename），**合起来不原子**。崩在两次 rename 之间 → 计数与回执不一致、白名单被静默丢失，而**没有任何代码去看** |
| 修改后 | 上半：`InterceptLedgerBook.checkConsistency()` + 两侧 `splitWrite: String?`。恢复时比对"计数 vs 回执"与"守卫侧白名单 vs 账本放行数"，不一致就**报告**，不猜哪边对 |
| 文件 | `K/loop/core/Ledgers.kt`、`K/loop/core/Intercept.kt` |
| 测试名称 | `InterceptSplitStoreTest` 3 项（两条不一致 + 一条"一致时不误报"） |
| 原始输出 | 先写测试：`Unresolved reference: splitWrite`；修后 `OK (197 tests)` |
| Git | `4bfa378` |
| 状态 | **PARTIAL** — 检测已做；**写入本身仍是两次 rename**，合并成单一原子快照尚未做 |

### P0-1 拦截事件永久悬挂 → 所有目标 APP 放行

| 项 | 内容 |
|---|---|
| 修改前 | 所有结局都由**页面**报告；页面不在（启动被静默丢弃 / Activity 被回收 / Intent 迟到 / 可见性重试用尽 / 熄屏后从锁屏进目标 APP）就永不结算。悬挂期间 `onForeground` 对每个目标 APP 返回 `Allow(already_open)` |
| 修改后 | 新增 `InterceptDeadline`（纯逻辑）：证明窗口 5s 未证明 → **NOT_SHOWN**；已证明超过 10min → **Expired**（记 BLOCKED/page_ttl，**不给放行**，回桌面并重判）。运行时用 `SystemClock.elapsedRealtime()` 挂**一个**定时器（不是轮询），页面不在也能结算。另接 D2：每包每分钟 3 次尝试上限 + NOT_SHOWN 后 15s 退避（**退避不是放行**，独立于 `releases`） |
| 文件 | `K/loop/core/InterceptDeadline.kt`（新）、`K/loop/core/Intercept.kt`（`expireOpen`）、`K/loop/intercept/InterceptRuntime.kt`、`K/loop/intercept/InterceptPageActivity.kt`（`goHome`） |
| 测试名称 | `InterceptDeadlineTest` 10 项（证明窗口≠TTL、TTL 从证明起算、退避不放行、每分钟 3 次、单调时钟） |
| 原始输出 | `Tests run: 213, OK`；Android 感知编译 `exit=0`（27 源文件） |
| Git | `63e3b40`（策略）+ `432811a`（接线） |
| 状态 | **PASS**（策略与接线均验证；真机生命周期未验，见 NOT_TESTED） |

### P0-2 事件结束后不重新判定前台

| 项 | 内容 |
|---|---|
| 修改前 | 结算后不再看前台。用户用"最近任务"切回目标 APP：窗口事件先到 → 守卫仍 open → `Allow(already_open)` → 随后页面 onStop 结算 → 此后再无窗口事件 → 目标 APP 一直可用 |
| 修改后 | **每条结束路径**都要求宿主重读前台：released / exited（D5：退出不给放行）/ paused / page gone / not_shown / page_ttl。经 `InterceptRuntime.recheckForeground` 这个单向接缝，不直接依赖 `LoopRuntime` |
| 文件 | `K/loop/intercept/InterceptRuntime.kt`、`K/loop/LoopRuntime.kt` |
| 测试名称 | `InterceptRejudgeTest` 4 项（exit/ttl/not_shown 三条都必须重新拦 + 一条放行后确实通过） |
| 原始输出 | `Tests run: 217, OK` |
| Git | `9e410c1` |
| 状态 | **PASS** |

---

## 状态总表

| 编号 | 缺陷 | 状态 |
|---|---|---|
| A-1 | 内核测试可复现 | **PASS** |
| A-2 | 191 → 190 更正 | **PASS** |
| A-3 | Gradle 无 gradlew | **PARTIAL**（根因明，未修） |
| A-4 | RecoveryTest 重写 | **PASS** |
| **P0-3** | NOT_SHOWN 扣冷却 | **PASS** |
| **P0-5** | 未展示可放行 | **PASS** |
| **P0-4** | 跨文件写入 | **PARTIAL**（检测已做，原子写未做） |
| **P0-1** | 永久悬挂 | **PASS**（代码级；真机未验） |
| **P0-2** | 不重判前台 | **PASS**（代码级；真机未验） |

**FAIL：0 项。**

---

## 一条测量纪律

本轮我三次修正自己的数字：191→190、969/970→三次采样、以及滑动窗口算术两次算错。
**每一次都是因为拿实测取代了推算。** 现在包里每个数字后面都挂着能重跑的命令。
