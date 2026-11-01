# R4-PHASE4-TEST-MATRIX

> 每个测试类的实测结果。命令统一为
> `KOTLIN_JARS=/root/kernel-jars tooling/run-kernel-tests.sh`（Linux / JDK 21.0.12）或
> `node --test`（插件）。

## 一、内核（JVM，离线，不需要设备/模拟器/引擎）

| 测试类 | 覆盖 | 本轮变化 |
|---|---|---|
| `AckStateMachineTest` | ACK 单步语义 | — |
| `AgentWireTest` | agent 线协议 | — |
| `CoordinatorTest` | 统一仲裁 | — |
| `InterceptChainTest` | 拦截链路 | — |
| `InterceptDrillTest` | 训练题 | **改**：restart 用例改为断言"重启后重新被拦" |
| `InterceptRecoveryTest` | 进程恢复 | **重写**：4 → 7 项，真实重建 store/ledger/guard |
| `InterceptReleaseDoorTest` | 四扇放行门 | — |
| `InterceptSurfaceBudgetTest` | 预算 | **重写 2 项**：由"断言 bug 行为"改为断言 D2/D5 结局 + 反方向 |
| `KernelChainTest` / `KernelRiskTest` | 内核链与风险 | — |
| `LedgerBookTest` | 两本账 | — |
| `ProactiveAckLatticeTest` | 主动交流六态 | — |
| `ProactiveSchedulerTest` | 调度 | — |
| `SurfaceSlotTest` | 槽位 | — |
| `InterceptDrillTest` (含) | 训练 | — |
| `KernelMirrorTest` / `LoopEngineTest` / `TriggerRulesTest` | 引擎 | — |
| **`InterceptVisibilityGateTest`** | **P0-5：无证明不放行/不退出/不暂停** | **新增 6 项** |
| **`InterceptSplitStoreTest`** | **P0-4：两文件不一致可被检出** | **新增 3 项** |
| **`InterceptDeadlineTest`** | **P0-1：证明窗口 / TTL / 退避 / 每分钟次数 / 单调时钟** | **新增 10 项** |
| **`InterceptRejudgeTest`** | **P0-2：每类结束都重新判定** | **新增 4 项** |

**合计：21 个类，217 项，全过。**

```
$ KOTLIN_JARS=/root/kernel-jars tooling/run-kernel-tests.sh
java:    /usr/bin/java
jars:    10
sources: 43
classes: 21
compiling...
compiled
running 21 classes...
OK (217 tests)
PASS
```

### 被排除的类（如实说明）

| 类 | 为什么排除 |
|---|---|
| `LoopHardeningTest` | 引用 Android 类 `InteractionHub`（`android.content.Context` 等），JVM 侧编译不过，只能在真 Android 测试运行时里跑 |
| `L2sMigrationTest` | 需要 POSIX 文件 API：Windows 上 `setPosixFilePermissions` 直接抛 `UnsupportedOperationException`；**且必须非 root**（3 条测试 `chmod 000` 后断言遍历中断，root 照读 → 假失败）。单独在 WSL 非 root 下跑：**28/28 OK** |

## 二、插件（node --test）

| 插件 | 结果 |
|---|---|
| `dsh-go-bili` | 80 / 80 |
| `dsh-go-cap-ledger` | 50 / 50 |
| `dsh-go-partner` | 110 pass / 1 skip / 0 fail |
| `sdk/plugin-kit` | 76 / 78（`sibling-prefix path / symlink` 在基线 `ac04b38` 上同样失败，非本轮引入） |

## 三、python 守卫

| 测试 | 结果 |
|---|---|
| `runtime.tests.test_verify_outputs` | Ran 9, OK |
| `tooling.test_verify_apk_runtime` | Ran 8, OK |

## 四、Android

| 检查 | 结果 |
|---|---|
| Android 感知编译（27 源文件：`loop/core` + `loop/intercept` + 主动页 + 真 `android.jar` + `flutter.jar`） | **exit 0** |
| `:app:testArm64DebugUnitTest` 执行 | **NOT_TESTED** —— 无 `gradlew`（见 CHANGELOG A-3） |
| Flutter analyze | 本轮未改 Dart，**未重跑**（上一轮 `No issues found`） |

## 五、Flutter 失败集合（本轮未触碰）

本轮**没有修改任何 Dart 代码**，因此 Flutter 全量套件不在本轮变更面内。
上一轮已用三次采样对比 R3 基线（`lc run1 −969` / `lc run2 −960`，逐名差集 0 新增），
结论与证据保存在 `R4-LOGIC-CLOSURE-REPORT.md` §5。

**本轮不做的事**：不重新采样 Flutter，也不把旧数字搬进本轮报告充数。
如需本轮口径，须在阶段 G 按"基线 + 候选各 3 次、并集/交集比较"重跑。

## 六、逐条 PASS/PARTIAL/NOT_TESTED

| 项 | 状态 | 依据 |
|---|---|---|
| 内核 217 项 | **PASS** | 上面原文 |
| 插件 240 项 | **PASS** | 80+50+110 |
| Android 感知编译 | **PASS** | exit 0 |
| Android 单测**执行** | **NOT_TESTED** | 无 gradlew |
| 真机 / 模拟器 | **NOT_TESTED** | adb 0 台 |
| Flutter 全量 | **NOT_TESTED**（本轮） | 未改 Dart；上轮结论不搬用 |
| L2s 迁移 | **PASS**（另跑） | WSL 非 root 28/28 |
| 双 ABI 运行时 | **NOT_TESTED**（本轮） | 未跑 build-runtime.sh（需先报资源） |
