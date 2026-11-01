# R4-PHASE4B-FAILURE-MATRIX

> 每个故障注入点：**注入什么 → 期望什么 → 实际什么**。
> 全部在 `InterceptRepositoryCrashTest` 里，与生产代码走同一条提交路径。

分支 `fix/r4-transactional-state-2026-11-01`，基线 `40c69eb1c10dac058d24fa27755b067da25d92d8`。

命令：

```
KOTLIN_JARS=/root/kernel-jars tooling/run-kernel-tests.sh
```

原始输出（本轮终态）：

```
java:    /usr/bin/java
jars:    10
sources: 50
classes: 25
compiling...
compiled
running 25 classes...
OK (248 tests)
PASS
```

---

## 一、P0-4 故障注入矩阵

| # | 注入的故障 | 期望 | 实测 | 测试名 |
|---|---|---|---|---|
| 1 | 写临时文件时抛 IOException | 提交失败并报告；磁盘仍是上一份快照；新进程看不到白名单、看不到 RELEASED 回执 | 通过 | `a_write_that_cannot_even_open_a_temp_file_leaves_the_old_snapshot_intact` |
| 2 | 写到一半（内容截断到 40 字节） | 回读校验失败；下一进程报 recoveryIssue，而不是当成空状态 | 通过 | `a_truncated_write_is_not_readable_as_a_valid_snapshot` |
| 3 | fsync 前死亡（store 抛异常） | 磁盘保留完整旧快照；旧快照仍能解析、回执仍是 BLOCKED | 通过 | `a_crash_before_the_rename_leaves_the_previous_snapshot_readable` |
| 4 | 替换完成后、内存更新前死亡 | 新进程读到的是**已提交**的新状态（白名单 + 回执都在） | 通过 | `a_restart_after_a_durable_commit_recovers_the_committed_state_not_the_old_one` |
| 5 | store 返回成功但**没真正落盘** | 回读比对发现不一致 → 提交报失败，不得声称成功 | 通过 | `a_store_that_silently_drops_the_write_is_caught_by_the_read_back` |
| 6 | 同一 eventId 重复提交 | 只计一次拦住；结束一次只产生一条回执 | 通过 | `the_same_eventId_applied_twice_adds_one_receipt` |
| 7 | 每日计数更新中断 | 重启后计数等于**已提交**的那个值，不是半应用的值、也不翻倍 | 通过 | `an_interrupted_daily_count_write_does_not_double_count_on_restart` |
| 8 | 快照自相矛盾（triggerCount=0 但有回执） | 拒绝提交，报原因 | 通过 | `a_snapshot_whose_trigger_count_is_below_its_receipts_is_refused` |
| 9 | schemaVersion 比本进程新 | 拒绝加载、报 recoveryIssue、**不覆盖**（writes 仍为 0） | 通过 | `a_newer_schema_is_refused_rather_than_overwritten` |
| 10 | 白名单写入失败 | 既没有白名单条目，也没有 RELEASED 回执 | 通过 | `a_failed_whitelist_write_leaves_neither_a_whitelist_entry_nor_a_receipt` |

**"重启"的定义**：每次都是新的 `InterceptRepository` + 新的 `InterceptLedgerBook` + 新的
`InterceptGuard`，只共享字节。没有任何一处复用内存对象冒充恢复。

---

## 二、旧数据迁移矩阵

| # | 场景 | 期望 | 实测 | 测试名 |
|---|---|---|---|---|
| 1 | 无旧文件 | Fresh，不写任何东西 | 通过 | `with_no_legacy_files_the_result_is_fresh_not_a_migration` |
| 2 | 两份旧文件一致 | Migrated，快照可回读，白名单与计数保留 | 通过 | `consistent_legacy_files_migrate_and_read_back` |
| 3 | 已迁移后再启动 | AlreadyMigrated，写次数不增加 | 通过 | `a_second_run_does_not_migrate_again` |
| 4 | 白名单有条目但账本没有对应放行 | **RecoveryRequired**，不写快照，理由里点名 whitelist | 通过 | `a_whitelist_entry_the_ledger_never_released_stops_the_migration` |
| 5 | 结束计数多于回执 | RecoveryRequired，不写快照 | 通过 | `more_endings_than_receipts_stops_the_migration` |
| 6 | 守卫有 open 事件但账本没触发 | RecoveryRequired，不写快照 | 通过 | `an_open_interception_with_no_recorded_trigger_stops_the_migration` |
| 7 | 旧文件读不懂 | RecoveryRequired，不覆盖 | 通过 | `an_unreadable_legacy_file_stops_the_migration` |
| 8 | 中断后重跑 | 幂等：只产生一份快照，旧文件原样保留 | 通过 | `an_interrupted_migration_can_be_rerun_safely` |

**关键设计**：不一致时**不猜**。不补放行记录、不删旧文件、不伪造白名单 —— 旧数据原样留在盘上
供人工处理。

---

## 三、D5 授权语义矩阵

| 场景 | 期望 | 实测 |
|---|---|---|
| EXITED 后立即重开（cooldownMs 非零） | **Block**（退出不给放行） | 通过 |
| BLOCKED（TTL 到期）后重开 | **Block** | 通过 |
| NOT_SHOWN 后重开 | **Block** | 通过 |
| dailyMax=1，EXITED 后重开 | **Ignore**（限打扰，不放行） | 通过 |
| 答对训练题 → releaseMs 内 | **Allow(RELEASED)** | 通过 |
| releaseMs 到期 | **Block** | 通过 |
| PAUSED 到期 | **Block** | 通过 |
| WHITELIST | 一个月后仍 **Allow(WHITELIST)** | 通过 |
| 扫描若干时间点 | 任何 Allow 的理由都**不得**是 cooldown / daily_max | 通过 |

### 三条旧测试的预期被修改（不是放宽，是需求变更）

| 测试 | 原来断言 | 现在断言 | 为什么 |
|---|---|---|---|
| `InterceptChainTest.oneInterceptionAtATimeAndNoStormAfterAnExit` | `Allow(REASON_COOLDOWN)` after exit | `Block` | 原断言就是 D5 点名的绕过路径：按退出换 2 分钟免费 |
| `InterceptChainTest.theDailyCapStopsTheInterceptionsForThatDay` | `Allow(REASON_DAILY_MAX)` | `Ignore` | 每日上限是限打扰，不是许可 |
| `InterceptSurfaceBudgetTest.a_shown_block_does_spend_the_cooldown` | 展示过的拦截产生 `Allow(cooldown)` | 计数+1 且下一次**不是** Allow | 冷却不能变成许可 |

三处都留了注释写明"以前断言什么、D5 为什么改"，并在本表留下前后对照。**没有为了让测试变绿而放宽任何断言。**

---

## 四、D2 降级矩阵

| 场景 | 期望 | 实测 |
|---|---|---|
| 任意展示失败 code | 请求运行时回 HOME | 通过 |
| 未知 code | 仍然回 HOME（页面反正已经没了） | 通过 |
| 回 HOME 后前台仍是目标 APP | 判定"未离开" → 重试 → 仍不行则报 ENFORCEMENT_UNAVAILABLE | 通过 |
| 回 HOME 后前台是别的 APP | 判定"已离开" | 通过 |
| **读不到前台（null）** | 算作**未离开**（不是成功） | 通过 |
| 最终失败 | 理由里含 code、尝试次数、以及「did not take effect」 | 通过 |

---

## 五、未覆盖 / NOT_TESTED

| 项 | 状态 | 原因 |
|---|---|---|
| 真实文件系统上的断电 | **NOT_TESTED** | 需要真实掉电或内核级故障注入；本轮用 `FaultyDisk` 在 store 边界注入，语义等价但不是物理断电 |
| 真实 fsync 行为 | **PARTIAL** | `AtomicJsonFile` 已有 `fd.sync()` + 目录 fsync，但未在真机上验证掉电后的表现 |
| 迁移的真实旧数据 | **NOT_TESTED** | 夹具构造的旧格式来自代码，不是从真机取的真实文件；需要在升级路径上实测 |
| HOME 是否真的切走前台 | **NOT_TESTED** | 需要设备；本轮验证的是判定逻辑与接线 |
| 每分钟尝试上限触发后的用户体验 | **NOT_TESTED** | 需要真机观察通知与恢复 |
