# WIRING-RESULT

分支 / HEAD
```
refs/heads/fix/r4-snapshot-fix-2026-11-02
（HEAD 见 git ls-remote 原文，推送后追加）
```

起点 `caeba65`。未 force push、未碰其他分支、未建 APK、未上手机。

| 任务 | 改动文件 | 红 | 绿 | 状态 |
|---|---|---|---|---|
| **F0** | 无 | — | `OK (258 tests)` / `wiring OK` | **DONE** |
| **F1** | `core/Ledgers.kt` `core/Intercept.kt` `core/InterceptRepository.kt` `core/InterceptMigration.kt` `test/InterceptProductionPathTest.kt`(新) | `Tests run: 260, Failures: 2`<br>`FAIL -- see .kernel-tests/test.log`<br>`triggerCount (0) is smaller than receipts (1)` | `OK (260 tests)` / `PASS` / `wiring OK` | **DONE** |
| **F2** | `core/Intercept.kt` `core/Ledgers.kt` `core/InterceptKernel.kt` `test/InterceptProductionPathTest.kt` | `Tests run: 266, Failures: 6`<br>`FAIL -- see .kernel-tests/test.log`<br>`a drill tap that did not land must report failure` | `OK (266 tests)` / `PASS` / `wiring OK` | **DONE** |
| **F3** | `core/InterceptMigration.kt` `test/InterceptMigrationTest.kt` | `Tests run: 268, Failures: 1`<br>`FAIL -- see .kernel-tests/test.log`<br>`RecoveryRequired(max=150 receipts=100)` | `OK (268 tests)` / `PASS` / `wiring OK` | **DONE** |
| **F4** | `intercept/InterceptRuntime.kt` `intercept/InterceptPlugin.kt` `lib/intercept/intercept_channel.dart` `lib/ui/phone/intercept_page.dart` `lib/l10n/parts/intercept_{en,zh}.arb` `test/InterceptProductionPathTest.kt` | 测试首次失败（fixture 触发更早检查）；**修正 fixture 后即通过 → 真实缺口在 UI 未显示** | `OK (269 tests)` / `wiring OK`<br>`No issues found! (ran in 10.3s)` | **DONE** |
| **F5** | `intercept/InterceptRuntime.kt` `tooling/run-kernel-tests.sh` | 注释替换真实调用：`OK (269 tests)` `PASS` 但 `FAIL: nothing calls EnforcementAlert.notify` + `WIRING FAIL` | 恢复后 `OK (269 tests)` / `wiring OK` | **DONE** |
| **F6** | `lib/l10n/gen/`（重新生成） | 原 diff 3056 行 | 26 行，只涉 2 个新 key；`--check` exit=0 | **DONE** |
| **F7** | `test/InterceptProductionPathTest.kt` | —（回归包，非缺陷修复） | `OK (278 tests)` / `PASS` / `wiring OK` | **DONE** |

## 五处真实缺陷（都已修）

1. **F1**：设置页暂停写一条 `pause-<now>` 回执但不加 `triggerCount` → `validate()` 永久拒绝提交。
   之后暂停、白名单、回执全都写不进去，直到约 100 次拦截把该回执挤出上限；期间进程一死全丢。
2. **F2**：提交失败只记 `storageError`，各方法仍 `return true`。内存前进而磁盘没动，下次启动改动消失且无回执。
3. **F3**：回执上限 100 而计数一直累加 → 老用户 `blockedCount=150` 配 100 条回执被误判为数据损坏，**拒绝迁移用得最久的人**。
4. **F4**：退回旧格式时 `recoveryIssue` 只进日志，status map 与 Dart 都读不到 → 用户不知道自己仍在旧格式。
5. **F5**：`launchIntent` 从未赋值（通知点了没反应）；且 W3 检查跑在含注释的原文上，**注释能冒充真实调用**。

## 两条过程记录

- **F2 的可测性**：`InterceptKernel.open` 增加了可选 `snapshotStore` 工厂，故障注入才能经由生产入口，
  而不是手工 new Guard —— 后者正是上一轮 24 项全绿却什么都没生效的原因。
- **F6 的噪声**：上一轮提交的 `l10n/gen` 含约 3000 行格式化重排（长字符串重新折行），把真正的两个新 key 淹没。
  本轮回退到 `7d2ef4d` 后只用 `tool/l10n_merge.py` 重新生成，未跑 `dart format`。

## 还没做的

- **没有在手机上跑过任何一条。** `tooling/device-smoke.md` 是清单，不是结果。
- 主动回复闭环、白名单撤销入口、`hostdeps.mjs`、rc.4、PRoot、D1–D7、APK、真机 —— 按约定未动。
- 白名单检查（“数据对不上就不迁移”）本轮**未改**，等负责人决定。

## 记法

F0–F7 全部 **DONE**。手机上跑过之前，任何东西都不叫“通过”。
