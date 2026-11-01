# R4-PHASE4B-MIGRATION-REPORT

> 旧 `guard.json` + `ledger.json` → 单一 `intercept.snapshot.json` 的迁移设计、校验、与失败处理。

代码：`loop/core/InterceptMigration.kt`
测试：`loop/core/InterceptMigrationTest.kt`（8 项，全过）

---

## 一、迁移在什么时候跑

```
启动
  ├─ 读 intercept.snapshot.json
  │    ├─ 有且可读      → AlreadyMigrated（不再迁移，旧文件原样留着）
  │    └─ 有但读不懂    → recoveryIssue，进入 RECOVERY_REQUIRED
  └─ 没有快照
       ├─ 两个旧文件都不存在 → Fresh（全新安装，建空快照）
       └─ 至少一个存在       → 走一致性校验
```

---

## 二、四条一致性检查

迁移**不是**复制数据。真正的工作是判断两份旧文件是否互相说得通。

| # | 检查 | 不通过说明什么 |
|---|---|---|
| 1 | 守卫有 `openEventId` ⇒ 账本 `triggerCount ≥ 1` | 有未结算的拦截，却没有任何触发记录 |
| 2 | `blocked+released+exited+paused ≤ 回执数` | 记账多于历史 |
| 3 | `回执数 ≤ triggerCount` | 有结束却没有触发 |
| 4 | **白名单条目数 ≤ `userReleasedCount`** | 有一条永久授权，但账本不记得它被授予过 |

第 4 条是最要紧的：白名单是**永久权限**。如果它在账本里找不到来源，只有两种可能 —— 要么
白名单是凭空写进去的，要么放行记录丢了。两种情况都不该由程序替用户决定"那就当它存在吧"。
**代码在这里绝不补一条放行记录**：那是在伪造历史。

---

## 三、不一致时的行为

```
RecoveryRequired(reason, detail)
  ├─ 不写快照          ← 旧数据一个字节都不动
  ├─ 不删旧文件        ← 用户仍能读到自己的数据
  ├─ 不伪造白名单      ← 不补、不删、不改
  ├─ 不产生新放行授权  ← 没有 Allow 被写出
  └─ 理由进 recoveryIssue，供界面显示与人工处理
```

**为什么不自动修复**：两份文件不一致时，"哪一份是对的"这个问题**没有答案**。程序能看到的只有
两个互相矛盾的事实，猜一个就等于用代码替用户决定他的白名单是否存在、他的拦截是否发生过。
停下来交给人，比猜对了更有价值 —— 而且我们无法知道自己猜对了。

---

## 四、中断安全

迁移的唯一副作用是**写一次快照**。因此：

| 中断位置 | 结果 |
|---|---|
| 写快照之前 | 什么都没变，下次重跑 |
| 写快照过程中 | `AtomicJsonFile` 保证要么旧文件在、要么新文件在（临时文件 + 原子替换） |
| 写快照之后、标记之前 | 下次启动看到快照 → `AlreadyMigrated`，不会重复迁移 |

测试 `an_interrupted_migration_can_be_rerun_safely` 验证：重跑只产生一份快照，旧文件原样保留。

---

## 五、旧文件如何处理

**保留，不删除，不重命名。**

理由：迁移是一次不可逆的格式转换。旧文件是唯一的原始证据。如果迁移逻辑本身有 bug，
删掉旧文件就等于销毁了唯一的还原依据。占用的空间以 KB 计，不值得为此冒险。

---

## 六、实测

```
InterceptMigrationTest
  with_no_legacy_files_the_result_is_fresh_not_a_migration            OK
  consistent_legacy_files_migrate_and_read_back                      OK
  a_second_run_does_not_migrate_again                                OK
  a_whitelist_entry_the_ledger_never_released_stops_the_migration    OK
  more_endings_than_receipts_stops_the_migration                     OK
  an_open_interception_with_no_recorded_trigger_stops_the_migration  OK
  an_unreadable_legacy_file_stops_the_migration                      OK
  an_interrupted_migration_can_be_rerun_safely                       OK
```

---

## 七、未验证的部分（如实）

| 项 | 状态 | 说明 |
|---|---|---|
| 真实旧数据 | **NOT_TESTED** | 测试里的旧格式是从代码推出的形状，不是从真机 `pull` 下来的真实文件。升级时必须实测 |
| 大三份真实 JSON 的迁移 | **NOT_TESTED** | 夹具是小的；真实账本有最多 100 条回执 |
| 迁移期间省电模式/进程被杀 | **PARTIAL** | 逻辑上幂等，但没有在真机上制造过 |
| 用户如何在界面里看到 RECOVERY_REQUIRED | **NOT_TESTED** | 字段已暴露，界面接线未做（本轮不改 UI） |
