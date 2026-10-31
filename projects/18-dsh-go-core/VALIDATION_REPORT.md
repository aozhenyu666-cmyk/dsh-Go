# VALIDATION_REPORT

标注规则：**PASS** = 在本文写明的环境里跑过且通过；**NOT_TESTED** = 没有该环境的证据。
模拟器/本机 JVM 一律**不等于**真机验证。

## 1. 测试环境

Windows 11（26H2）+ Flutter 3.47.7 + JDK 21 + Android SDK 36 + Gradle 9.3.1。
无 Android 模拟器、无真机（按要求不连接任何设备）。

## 2. 自动化结果

| # | 检查 | 命令 | 结果 |
|---|---|---|---|
| 1 | 内核 + 闭环 JVM 测试 | `gradlew :app:testArm64DebugUnitTest --tests "io.github.ccch1mneyyy.dsh_app.loop.*"` | **PASS 96/96** |
| 2 | 触发测试页 Flutter 测试 | `flutter test test/phone/loop_test_page_test.dart` | **PASS 14/14** |
| 3 | 主动搭话页 Flutter 测试 | `flutter test test/phone/proactive_page_test.dart` | **PASS 7/7** |
| 4 | D1 转发层 Flutter 测试 | `flutter test test/proactive_channel_test.dart` | **PASS 12/12** |
| 5 | Dart 静态检查 | `flutter analyze` | **PASS，No issues found** |
| 6 | 宿主插件纯逻辑 | `node --test test/core.test.mjs` | **PASS 10/10** |
| 7 | APK 构建 | `gradlew :app:assembleArm64Debug` | **PASS** |

### JVM 96 项构成

| 套件 | 数量 | 覆盖 |
|---|---|---|
| `LoopEngineTest` | 17 | 第一轮闭环（Claude 原型，未改动） |
| `LoopHardeningTest` | 15 | P0-01/P1-01/P1-02 + T3 回执契约 + T7 桥接降级 |
| `TriggerRulesTest` | 7 | T5 跨零点免打扰、每日上限、时钟回拨（历史任务，保留） |
| `AgentWireTest` | 4 | 协议编解码（Claude） |
| `CoordinatorTest` | 25 | T4 仲裁状态机（Claude） |
| `ProactiveSchedulerTest` | 17 | T6 调度（Claude） |
| `KernelChainTest` | 3 | 全链路（Claude） |
| `KernelRiskTest` | 8 | **本轮新增**：三个跨 Agent 风险 |

## 3. 三个关键缺陷的验收证据

### P0-01 交互页过早标记 SHOWN

- 修法：`stateOf()` 只读；`InteractionActivity` 在 decor view 已挂载、`isShown`、
  宽高 > 0 之后才 `shown()`；未可见就离开记 `UNAVAILABLE(not_shown)`。
- 证据：`LoopHardeningTest.askingForTheStateDoesNotMarkThePageShown` /
  `onlyAVisiblePageMovesTheEventToShown` / `shownAfterTheEventWasClosedIsRefused`。

### P1-01 无障碍异常缺少诊断

- 修法：新增 `LoopDiagnostics`（计数、连续失败、最近 20 条、每类最近成功时间），
  `LoopRuntime` 的每条异常路径都记账而不再只 `Log.w`；`dsh/loop` 的 `status` 暴露该 map；
  异常仍被 `runCatching` 挡住，**不会**传给 `PhoneA11yService`。
- 证据：`LoopHardeningTest.diagnosticsCountStreakAndKeepTheLatestFaults` /
  `diagnosticsDistinguishNeverRanFromNoFailures`；设置页 `proactive`/`loop` 均显示。

### P1-02 状态文件替换可靠性

- 修法：`FileLoopStore` 改为 临时文件 → fsync → 备份旧文件 → 原子 move → 目录 fsync；
  读不到主文件时回退 `.bak` 并把坏文件隔离成 `.bad`（旧 `.bad` 带时间戳保留）。
  `AtomicJsonFile`（Claude 内核的存储）有**相同缺陷**，一并按同一方案修复。
- 证据：`LoopHardeningTest.aDamagedStateFileFallsBackToTheBackupAndSaysSo` /
  `aWriteNeverLeavesTheFileMissing` / `anEmptyFileIsUnreadableNotEmpty`；
  `KernelRiskTest.theKernelStoreFallsBackToItsBackupAndSaysSo` /
  `theKernelStoreNeverLeavesTheFileMissing` / `anEmptyKernelFileIsUnreadableNotEmpty`。

## 4. 第一轮任务验收项的真机部分（全部 NOT_TESTED）

| 验证项 | 自动化 | 真机 |
|---|---|---|
| 20 次应用切换 | `twentySwitchesTriggerTwentyTimesWithOneReceiptEach` PASS | NOT_TESTED |
| 前后台切换 / 冷却 | `backgroundAndBackWithinTheCooldown…` PASS | NOT_TESTED |
| 用户主动退出（返回/系统返回/超时/离开） | `leavingThePageBackKeyAndTimeout…` PASS | NOT_TESTED |
| 服务重连 | `serviceReconnectWhileStillInTheApp…` PASS | NOT_TESTED |
| 进程重启 | `processRestartClosesOpenEvents…` PASS | NOT_TESTED |
| 异常回执（页面没弹出） | `KernelRiskTest.postedIsNotShown…` + T3 序列 | NOT_TESTED |
| 不打扰 DSH 任务 | `dshBusyLockedAndScreenOffSuppress` PASS | NOT_TESTED |
| 通知兜底 | 回执契约已测；**实际发通知** | NOT_TESTED |
| 调度恢复 | `ProactiveSchedulerTest` 17 项 PASS | NOT_TESTED |
| 模型失败降级 | `LoopHardeningTest` T7 组 PASS | NOT_TESTED（真实模型） |

## 5. 截图基线（golden）的环境归因

`flutter test test/phone` 在补齐 `app/test/phone/goldens/` 后，仍有 **34 个 golden 对比失败**
（差异 3.7%–14.6%）。**已证明与本改动无关**：

- 在**未含我任何改动**的基线提交 `bc72be3` 上开 worktree，跑同一批测试，
  **同样 34 个失败，且像素差异百分比逐项相同**（4.38% / 3.73% / 13.19% / 14.62% …）；
- 原因：本机没有 `Noto Sans CJK`（`test/support/test_fonts.dart` 默认从
  `/usr/share/fonts/noto-cjk` 读取），我用 Windows 自带微软雅黑 TTC 以同名文件替代，
  字形宽度与基线不同。**没有修改任何 golden，也没有放宽任何断言。**

## 6. 未执行（NOT_TESTED）与原因

| 项 | 原因 |
|---|---|
| 真机全部行为 | 按要求不连接、不操作真实手机 |
| `runtime/build-runtime.sh` 完整构建 | 需 Linux 主机与 Ubuntu base/deb 输入 |
| `runtime/test-host.sh` 的 proactive 端到端 | 需 bwrap + x86_64 Linux |
| 真实 DeepSeek 模型接入 | 无 Key，且不得把 Key 写进仓库；插件侧已在 Claude 沙箱用假模型验证 26/26 |
| 远程主机（SSH/中转） | 无环境 |

## 7. 结论

本机可验证的层次（Kotlin 逻辑、Dart 逻辑、编译、打包、APK 构建）**全部 PASS**；
设备相关层次**全部 NOT_TESTED**，未做任何"模拟器等于真机"的推断。
