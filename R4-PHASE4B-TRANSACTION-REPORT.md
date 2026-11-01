# R4-PHASE4B-TRANSACTION-REPORT

**第四阶段 4B · 原子持久化与授权逻辑一致性修复**

- 基线：`fix/r4-phase4-2026-11-01` @ `40c69eb1c10dac058d24fa27755b067da25d92d8`（开工前核对远端一致）
- 工作分支：`fix/r4-transactional-state-2026-11-01`
- 未动：`main` / R3 / 原始集成分支 / 之前所有分支与 worktree（18 个全在）

---

## 一、结论

| 项 | 状态 | 一句话 |
|---|---|---|
| **P0-4 单一原子快照** | **PASS** | `InterceptRepository` 单文件一次提交；回读验证通过才算成功 |
| **P0-4 旧数据迁移** | **PASS** | 四条一致性检查；不一致则 RECOVERY_REQUIRED，不猜不删 |
| **D2 展示失败不隐形放行** | **PASS**（代码级） | 失败 → NOT_SHOWN → 回 HOME → 重读前台 → 失败则如实报 |
| **D5 授权语义统一** | **PASS** | 冷却与日上限不再产生 `Allow`；EXITED 不给放行 |

**FAIL：0。** 真机相关全部 NOT_TESTED（adb 0 台）。

---

## 二、方案选择（ADR 0001）

| | 方案 | 改动 | 结论 |
|---|---|---|---|
| **A** | 单一原子 JSON 快照 | 小：复用 `AtomicJsonFile` | **采用** |
| B | SQLite 单事务 | 大：C 依赖 + 迁移 + 体积 | 拒绝：为 4 个计数引数据库不成比例 |
| C | Event log + snapshot | 中：日志格式 + 重放 + 压缩 | 拒绝：状态很小，收益抵不上复杂度 |

A 能满足崩溃一致性的依据：`AtomicJsonFile` 已实现 **临时文件 → flush → fsync → 原子替换 → 目录 fsync**，
所以只要把两次写合成一次，一致性就是现成的。**没有引入新数据库。**

---

## 三、提交协议（这是本轮的核心）

```
1. 由内存算出完整新快照
2. 校验内部一致性
3. store.write(...)  ← 临时文件 → flush → fsync → 原子替换 → 目录 fsync
4. 回读，并与刚写下的内容比对
5. 只有第 4 步通过，才更新内存并返回成功
```

第 4 步不可省：**返回成功却没落盘**正是这个协议要抓的失败模式，除此之外没有别的办法发现。
第 5 步不可提前：先改内存，就等于让"写失败"看起来像"提交成功"。

写失败时：内存不前进、不返回成功、不产生 RELEASED 回执、磁盘仍是上一份可读快照。

---

## 四、我在这轮改错并改正的两处

### 4.1 校验器写得太严，导致**所有**提交都失败

第一版要求 `各结局计数之和 ≤ 回执数`。读起来天经地义，实际上把每一次正常提交都拒了：

`blockedCount` 数的是**页面真的上屏了**，而回执要到事件**结束**才写。所以
「已展示、尚未结束」这个中间态合法地满足 `blockedCount=1, receipts=0`。

**教训**：校验太严不是"更安全"，是"状态永远停在第一次写"。比不校验更糟。
现在只保留三条真正不可能成立的关系（触发数 ≥ 回执数、无重复事件键、open 事件必须有包名）。

### 4.2 回读比对用 Map 相等，被 Int/Long 坑了

JSON 解析把数字读成 `Long`，写下去是 `Int`，于是 `Map.equals` 因为装箱不同而失败 ——
与持久化毫无关系。改为**比对序列化后的文本**。

---

## 五、D2：隐形放行

### 修改前

```kotlin
if (backoff.isHoldingOff(packageName, mono())) {
    Log.i(TAG, "holding off ...")
    return          // ← 目标 APP 仍在前台可交互
}
```

### 修改后

```
展示失败 → 记 NOT_SHOWN（退还额度与冷却）→ 回 HOME → 重读前台
   ├─ 已离开 → recheckForeground，正常继续
   ├─ 还在   → 再试一次
   └─ 还不行 → ENFORCEMENT_UNAVAILABLE：记日志、通知用户、**不记 BLOCKED、不写放行**
```

关键判定：`stillInFront(null, target) == true` —— **读不到前台算"未确认离开"**。
把"不知道"当成"已离开"，正是把失败记成成功的那条路。

### 如实说明物理限制

普通应用**无法**保证绝对阻断（Home 手势、最近任务、系统设置都能绕过）。
能保证的是三件事：**不放行、不误记、如实报告**。15 秒退避只控制"多久之后再试着弹"。

---

## 六、D5：授权语义

### 修改前（两处把降噪手段当成了访问许可）

```kotlin
if (config.dailyMax > 0 && countToday >= config.dailyMax)
    return InterceptDecision.Allow(packageName, REASON_DAILY_MAX)     // 「今天别打扰」→「今天随便用」
if (... now - lastTriggerAt in 0 until config.cooldownMs)
    return InterceptDecision.Allow(packageName, REASON_COOLDOWN)      // 「别马上再弹」→「这两分钟随便用」
```

### 修改后

```kotlin
if (config.dailyMax > 0 && countToday >= config.dailyMax)
    return InterceptDecision.Ignore     // 不提问题，也不许可
if (... now - lastTriggerAt in 0 until config.cooldownMs)
    return InterceptDecision.Ignore
```

### 一个真正的绕过路径被关掉

`endOpen()` 在 BLOCKED/EXITED 之后仍保留 `lastTriggerAt` → `decide()` 看到"在冷却内" →
返回 `Allow`。**所以按「紧急退出」等于换到 2 分钟免费使用。**
现在 NOT_SHOWN / BLOCKED / EXITED 都会清掉该时间戳：只有 RELEASED 与 PAUSED 能留下放行理由。

### 完整许可清单（集中在一处）

```
WHITELIST  永久，直到用户撤销
PAUSED     用户明确暂停，到 pauseUntil
RELEASED   答对训练题等真实授权，到 releaseUntil
授权时段    用户配置的时间窗口内自动放行
```
除此四条以外，**没有任何路径产生 Allow**。

---

## 七、测试

| 套件 | 结果 |
|---|---|
| 内核（`tooling/run-kernel-tests.sh`） | **25 类 / 248 项 / 全过** |
| L2s 迁移（Linux **非 root**） | **28 / 28 OK** |
| bili | 80 / 80 |
| cap-ledger | 50 / 50 |
| partner | 110 pass / 1 skip / 0 fail |
| python `test_verify_outputs` | Ran 9, OK |
| python `test_verify_apk_runtime` | Ran 8, OK |
| Android 感知编译 | **exit 0**（27 源文件） |

本轮新增 **31 项**内核测试：

| 类 | 数量 | 覆盖 |
|---|---|---|
| `InterceptRepositoryCrashTest` | 11 | P0-4 故障注入 |
| `InterceptMigrationTest` | 8 | 旧数据迁移 |
| `InterceptAuthorizationSemanticsTest` | 10 | D5 授权语义 |
| `EnforcementOutcomeTest` | 5 | D2 降级判定 |

**三条旧测试的预期被修改**（见 `R4-PHASE4B-FAILURE-MATRIX.md` §三），因为它们断言的正是 D5
废止的行为。每处都写明"原来断言什么、为什么改"，**没有放宽任何断言来制造 PASS**。

---

## 八、已知风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| 快照比单文件大约两倍 | 磁盘占用（KB 级） | 回执上限 100 条，实际很小 |
| 迁移不可逆 | 旧文件只读保留是唯一还原依据 | 从不删除旧文件 |
| 每次提交多一次回读 | 略微增加 I/O | 一次 fsync 替代原来的两次，净持平或更好 |
| `InterceptGuard` 多了个可选参数 | 纯逻辑测试按位置传 `ids` 会错位 | 参数放在 `ids` **之前**，测试用命名参数 `repository=` |
| 真机上 HOME 可能被 ROM 拦截 | 拦截退化为"如实报告失败" | 这正是 D2 要求的行为，不是静默放行 |

---

## 九、PARTIAL 与 NOT_TESTED

### PARTIAL

| 项 | 差什么 |
|---|---|
| 真实 fsync / 掉电语义 | `AtomicJsonFile` 有 `fd.sync()` + 目录 fsync，但未在真机验证掉电表现 |
| 生产路径接入 | `InterceptRuntime` 尚未构造 `InterceptRepository`（见下） |

### NOT_TESTED

| 项 | 原因 |
|---|---|
| 真机 / 模拟器任何交互 | adb 0 台 |
| 真实旧数据文件迁移 | 夹具格式来自代码，不是真机 `pull` 下来的文件 |
| HOME 真的把前台切走 | 需要设备 |
| 断电测试 | 需要物理或内核级故障注入 |
| APK / 装机 / Release | 本轮明令禁止 |
| 双 ABI 运行时构建 | 任务书要求先报资源并获批 |

### 一个必须说清的缺口

`InterceptRepository` 目前只在**内核层**完成并验证（含 11 项崩溃注入）。
`InterceptRuntime` 仍然用两个 `AtomicJsonFile` 构造 guard 与 ledger，**还没有切换到仓库**。
这是一步独立的接线改动，涉及 `InterceptPlugin` 的初始化路径，我没有在本轮顺手塞进去 ——
因为它会让"已完成的原子快照"和"未切换的接线"混在同一个提交里，反而不好审。

**所以：内核层的崩溃一致性是 PASS，端到端的生产接线是 PARTIAL。**

---

## 十、提交

```
c223ec2  loop: when the page cannot appear, leave the app instead of quietly passing it   (D2)
775fedf  loop: a cooldown is not a permission, and neither is a daily cap                 (D5)
4602ea7  state: migrate the two old files only when they agree, and never by guessing      (迁移)
b3e6fbc  state: one snapshot, one commit, or nothing at all                                (P0-4)
```

ADR：`docs/adr/0001-intercept-persistence-and-authorization.md`
（含 D3 保留 `RELEASE_RULE`、D6 绑定 `sessionId`、D7 宿主事件为主要证据 的决策记录）

---

## 十一、停下来等审核

本轮到此为止。没有构建 APK、没有装机、没有 Release、没有合并 main。

**下一轮如果要继续，第一件事应该是把 `InterceptRuntime` 切到 `InterceptRepository`** ——
那是把已完成的原子快照真正用起来的唯一剩余步骤。
