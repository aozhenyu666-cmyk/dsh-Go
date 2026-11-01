# WIRING-RESULT

```
$ git ls-remote origin refs/heads/fix/r4-wiring-2026-11-02
（推送后填入）
```

起点 `7d2ef4d`。未 force push、未碰其他分支、未建 APK、未装机。

| 任务 | 改动文件 | 验收输出（原文） | 状态 |
|---|---|---|---|
| W0 | 无 | `OK (248 tests)` / `PASS` | **DONE** |
| W1 | `core/InterceptKernel.kt`(新) `core/InterceptMigration.kt` `intercept/InterceptRuntime.kt` `intercept/InterceptPlugin.kt` `core/InterceptKernelTest.kt`(新) | `OK (253 tests)` / `PASS`；`grep AtomicJsonFile(File(dir,"guard.json"))` → 无输出；`grep InterceptKernel.open` → 恰好 1 处(InterceptRuntime.kt:85) | **DONE** |
| W2 | `loop/LoopRuntime.kt` `core/EnforcementOutcome.kt` `intercept/EnforcementAlert.kt`(新) `intercept/InterceptRuntime.kt` `intercept/InterceptPlugin.kt` `res/values{,-zh}/intercept_strings.xml` `lib/intercept/intercept_channel.dart` `lib/ui/phone/intercept_page.dart` `lib/l10n/parts/intercept_{en,zh}.arb` `core/EnforcementOutcomeTest.kt` `core/InterceptSeamsWiredTest.kt`(新) | `OK (258 tests)` / `PASS`；`grep "= { null }\|-> Unit = { }"` → 无输出；`flutter analyze` → `No issues found! (ran in 3.4s)` | **DONE** |
| W3 | `tooling/run-kernel-tests.sh` | 破坏 alert 调用：`FAIL: nothing calls EnforcementAlert.notify...` + `WIRING FAIL`（同一次运行中 `OK (258 tests) PASS`，证明检查器独立生效）；改回后 `wiring OK` | **DONE** |
| W4 | `tooling/device-smoke.md`(新，33 行) | 文件存在，8 场景各有期望与失败判据 | **DONE** |

## 期间发现并修掉的缺陷

1. **W1**：`InterceptMigration` 一致性检查把四个计数**相加**再与回执数比。一次"展示后放行"的事件同时进
   `blockedCount` 和 `userReleasedCount`，计数和 2 > 回执 1 → **拒绝一切正常数据**。改为"任一单计数 ≤ 回执数"。
   （同一错误我在 4B 的 `InterceptRepository.validate()` 犯过并修好，然后又在这里原样复制。）
2. **W2**：离线 Android 编译脚本仍指向旧 worktree `p4`，第一次 `exit=0` 编译的是**上一轮代码**
   （`InterceptKernel.class`/`EnforcementAlert.class` 都不存在）。修好路径后 32 源文件才暴露下面两条。
3. **W2**：`EnforcementAlert` 用了 AndroidX `NotificationCompat`，而该编译集只有 `android.jar`+stdlib → 改平台 `Notification.Builder`。
4. **W2**：它硬引用 `MainActivity`（不在编译集）→ 改为注入 `launchIntent`；未注入时仍发通知，仅无点击目标。
5. **W3**：检查器第一版在 `set -e` 下因 `grep -v` 返回 1 而静默 `exit 1`；且误报 `dayKey = { null }`。
   **会误报的检查器比没有更糟**，现在只按名字查那两个 D2 接缝。

## 还没做的

- **没有在手机上跑过任何一条。** adb 一直 0 台，`device-smoke.md` 是清单不是结果。
- 主动交流闭环、白名单撤销、`hostdeps.mjs`、rc.4 非 Electron、`.101` 夹具、双 ABI、D1–D7 —— 均未动。
- `Notification.Builder(context, channelId)` 是 API 26+，`minSdk` 正好 26，成立；若降到 25 需换兼容写法。

## 记法

W0–W4 全部 **DONE**。但按约定：**手机上跑过之前，任何东西都不叫"通过"`。
DONE 的含义只是"接线接上了、检查通过了"。
