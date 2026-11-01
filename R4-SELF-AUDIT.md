# R4 自审报告（lead 对自己四轮工作的独立审核）

> 审核对象：`fix/r4-transactional-state-2026-11-01` @ `5f773c0e572b9c496be778c6a707e312229ec1a8`
> 审核方法：**重新实测**，不采信任何先前报告里的数字；对每条"已完成"的结论回代码验证。
> 审核时间 2026-11-01

---

## 结论先说

**我审出了 3 个真实缺陷，其中 1 个严重（D2 在生产中完全不生效），2 个中等（原子快照与迁移未接线）。**

| # | 问题 | 严重度 | 之前我怎么说 |
|---|---|---|---|
| **B-1** | **D2 的三个接缝在生产里从未赋值**，`enforceLeave()` 全程空转 | **严重** | 我报"PASS（代码级）" |
| **B-2** | **`InterceptRepository` 未接入生产**，线上仍用两个 `AtomicJsonFile` | 中 | 我报"PARTIAL"，说清了 |
| **B-3** | **`InterceptMigration` 是死代码**，从未被调用 | 中 | 我没有提 |

另外 **B-2 / B-3 叠加产生一个连锁风险**：快照永不被写入，迁移永不被触发，
所以线上既没有原子性，也没有迁移路径 —— 而我的报告读起来像两件事都做了。

---

## 一、重新实测的基线（先确认没记错）

### 1.1 远端实际状态

```
main                          bf01594471   ← 起点，未动 ✓
fix/r3-minute-input-on-1.0.4  f1423dc11c   ← R3，未动 ✓
integration/r4-hardening      ac04b388b7   ← 第二轮，未动 ✓
integration/r4-logic-closure  868dc330d8   ← 第三轮，未动 ✓
fix/r4-phase4-2026-11-01      40c69eb1c1   ← 第四轮，未动 ✓
fix/r4-transactional-state    5f773c0e57   ← 本轮（26 个分支之一）
```

**保护项复核：全部通过。** 26 个远端分支、18 个 worktree、两个工作树 `git status` 全干净。

### 1.2 测试重新跑（不是引用旧输出）

```
sources: 50
classes: 25
compiling...
compiled
running 25 classes...
OK (248 tests)
PASS
```

**248 项确实通过，可复现。** 这一条我敢担保。

---

## 二、B-1（严重）：D2 在生产里完全不生效

### 2.1 证据

D2 我做了三个可替换接缝，都有默认值：

```kotlin
// InterceptRuntime.kt:277
var goHome: () -> Boolean = {
    runCatching { InterceptPageActivity.goHome(app); true }.getOrDefault(false)
}

// InterceptRuntime.kt:282   ← 注意这个默认值
var currentForeground: () -> String? = { null }

// InterceptRuntime.kt:300   ← 空实现
var notifyEnforcementUnavailable: (String) -> Unit = { }
```

搜遍整个生产代码，**没有任何一处给它们赋值**：

```
$ grep -rn "currentForegrounds*=|goHomes*=|notifyEnforcementUnavailables*=" <生产代码>
(空)
```

### 2.2 为什么这是严重问题

`currentForeground` 默认返回 `null`，而我自己写的判定是：

```kotlin
// EnforcementOutcome.kt:50
fun stillInFront(foregroundAfterHome: String?, target: String): Boolean {
    if (foregroundAfterHome == null) return true   // 读不到 = 未确认离开
    return foregroundAfterHome == target
}
```

**`null` → `true` → "还在前台"**。于是在生产里：

```
展示失败 → enforceLeave()
  → goHome()（这个有真实实现，会回桌面）
  → 600ms 后 currentForeground() 返回 null
  → stillInFront(null, pkg) == true  "还在前台"
  → 再 goHome()
  → 再 600ms，currentForeground() 还是 null
  → stillInFront(null, pkg) == true
  → reportEnforcementUnavailable(...)
  → enforcementUnavailable = why
  → notifyEnforcementUnavailable(why)  ← 空实现，什么都不发生
```

**净效果**：每次展示失败都会多按两次 HOME（可能把人从别的界面踢回桌面），
然后 **静默地**记一次失败 —— 因为通知也是空实现，用户永远不知道。

而 `enforcementUnavailable` 字段虽然存在，却**没有任何地方读它**（Dart 侧搜不到，
status map 里也没有它）。

### 2.3 讽刺之处

D2 任务书原话：**"必须提醒用户当前拦截没有成功"**。
我写了一整套判定逻辑、5 项测试、一条重试链 —— 然后**忘了把提醒接出去**。

这正是我自己在 §10.3 里批评过的模式："测试通过 != 功能正确"。
`EnforcementOutcomeTest` 测的是**纯函数**，它当然全绿；因为纯函数没问题，接线才有问题。

### 2.4 修法（下一轮，不擅自在本轮扩大范围）

1. 在 `InterceptRuntime` 初始化时把 `currentForeground` 接到真实的前台读取（`LoopRuntime` 已有）；
2. `notifyEnforcementUnavailable` 接到真通知或设置页横幅；
3. `enforcementUnavailable` 加进 status map，Dart 侧显示；
4. **并且加一个"接缝必须被接线"的测试**：默认实现不能是 `{ null }`，或在初始化后断言已替换。

第 4 条是关键 —— 否则同类问题还会再犯。

---

## 三、B-2（中）：原子快照未接入生产

### 3.1 证据

```kotlin
// InterceptRuntime.kt:77-83  —— 生产初始化路径
val book = InterceptLedgerBook(AtomicJsonFile(File(dir, "ledger.json")))
book.recover()
val g = InterceptGuard(
    AtomicJsonFile(File(dir, "guard.json")), book,
    clock = System::currentTimeMillis, ids = { UUID.randomUUID().toString() },
)
```

**没有传 `repository=` 参数。** 而 `InterceptGuard` 的 `repository` 默认是 `null`，
于是 `persist()` 走回旧分支：两个文件、两次写。

```
$ grep -rn "InterceptRepository" <loop/intercept, loop/, loop/proactive>
(空)
```

`InterceptRepository` 只在 `loop/core/` 和测试里出现。

### 3.2 后果

**线上仍然是 P0-4 修复前的行为。**

11 项崩溃注入测试全部通过，但它们构造的是 `Proc(disk)`，自己 `new InterceptRepository` 并传 `repository=`。
**测的是仓库本身，不是生产走的路。**

### 3.3 我之前的表述

`R4-PHASE4B-TRANSACTION-REPORT.md` §九写了：

> 「`InterceptRepository` 目前只在**内核层**完成并验证……`InterceptRuntime` 仍然用两个
> `AtomicJsonFile` 构造 guard 与 ledger，**还没有切换到仓库**。」

**这一段是诚实的。** 但同一份报告的标题栏写的是「**P0-4 单一原子快照 PASS**」，
两句话放在一起会让人以为问题解决了。**这是表述问题，也算我的责任。**

准确的说法应该是：**P0-4 的"机制"PASS，"部署"未完成（PARTIAL）。**

---

## 四、B-3（中）：迁移是死代码

### 4.1 证据

```
$ grep -rn "InterceptMigration" <全部生产 .kt>
InterceptMigration.kt:20  object InterceptMigration {     ← 只有定义自己
```

**`InterceptMigration.run()` 从未被任何生产代码调用。** 8 项迁移测试全过，
但它们直接调 `InterceptMigration.run(...)`，不经过 `InterceptRuntime.ensure()`。

### 4.2 连锁后果（这是最值得警惕的地方）

B-2 与 B-3 叠加：

```
线上不建 repository  →  快照文件永不产生
                     →  InterceptMigration 判定"没有快照"
                     →  即使调用了，也会走 Fresh 分支
                     →  旧数据永远不会被迁移
```

但**实际上更糟**：迁移连调用都没有。所以：

| | 我报告里说的 | 线上实际 |
|---|---|---|
| 原子快照 | 单文件一次提交 | **两个文件两次写** |
| 旧数据迁移 | 四条检查、不一致即停 | **不存在这一步** |

**一个真实的旧用户升级到本版本，会继续用旧的 `guard.json` + `ledger.json`，
继续有两文件不一致的风险，而且不会得到任何迁移或提示。**

### 4.3 我为什么没发现

Phase 4B 的任务范围写的是"解决 P0-4 跨文件持久化不一致"。我实现了机制、写了 11 项测试、
写了 8 项迁移测试，然后**把"完成"定义成了"机制和测试存在"**，
而不是"生产路径上生效"。

这是范围理解的问题，也是我这一轮最该反省的地方。

---

## 五、审计中还发现的三处小问题

### 5.1 `REASON_COOLDOWN` / `REASON_DAILY_MAX` 变成死常量

```
Intercept.kt:260  const val REASON_DAILY_MAX = "daily_max"
Intercept.kt:261  const val REASON_COOLDOWN = "cooldown"
```

D5 之后这两个常量**不再被任何 `Allow` 使用**（只剩注释里提到）。保留它们是对的
（旧持久化回执里的 `reason` 字段可能含有值），但应该标注为 legacy-only。

**影响：无。** 只是代码清晰度。

### 5.2 `splitWrite` 是死诊断

```
InterceptGuard.splitWrite    ← 在 recover() 里赋值
InterceptLedgerBook.splitWrite
InterceptPlugin status map   ← 没有导出它
```

用户永远看不到这个不一致提示。**Phase 4B 用 `InterceptRepository` 的 `validate()` 取代了它，
所以功能上不需要了**，但它现在是残留字段。应当删除或标注明确用途。

### 5.3 设置页文案与新语义一致（这条是好消息）

我特意查了 UI 文案是否还在骗人：

```
"interceptCooldown": "Cooldown (minutes)"
"interceptEnabledHint": "…开启后每次打开下面这些 APP 都会被拦一次；冷却期内不会连着拦。"
"loopCooldownHint": "Minimum time between two pages; tap to change"
"loopDailyCapHint": "At most this many test pages a day; resets after midnight"
```

**全部只说"两次页面之间的最短间隔"和"每天最多几次"，没有说"冷却期内放行"。**

这一点设计是对的，而且 D5 的修法与文案本来就一致 —— 反而是旧代码违背了文案。

### 5.4 一个我原本怀疑、查证后没有的问题

`onForeground` 里有一处 `Allow(REASON_ALREADY_OPEN)`：

```kotlin
// Intercept.kt:523
if (s.openEventId != null) {
    val same = s.openPackage == packageName
    return InterceptDecision.Allow(packageName,
        if (same) REASON_ALREADY_OPEN else REASON_ANOTHER_OPEN)
}
```

我一开始怀疑这是"又一个隐形放行"。但读完全文后确认**不是**：

- 它只在**已经有拦截事件在屏上**时触发（`openEventId != null`）；
- 这是必要的：否则每个窗口事件都会重复弹题；
- P0-1 的截止定时器保证事件**一定会结束**，所以这个 Allow 不会永久有效；
- P0-5 保证未展示的页面不能通过这道门。

**但它的安全性依赖 P0-1 的定时器真的在跑。** 而定时器在 `InterceptRuntime` 里，
不受 JVM 测试覆盖。**所以这条在生产中的安全性，我无法用现有证据证明。**

→ 记为 **NOT_TESTED**，不是 PASS。

---

## 六、按严重度重排后的状态表

| 项 | 我之前的判定 | 审计后判定 | 依据 |
|---|---|---|---|
| 内核 248 项测试 | PASS | **PASS** | 重新跑，可复现 |
| P0-1 策略（InterceptDeadline） | PASS | **PASS** | 纯函数 + 10 项测试 |
| P0-1 运行时接线 | PASS（代码级） | **NOT_TESTED** | 依赖真机生命周期 |
| P0-2 重判前台 | PASS | **PARTIAL** | 逻辑在，但依赖 `recheckForeground` 的真实效果未验 |
| P0-3 退还扣费 | PASS | **PASS** | 纯逻辑 + 测试 |
| P0-4 机制 | PASS | **PASS** | 11 项故障注入 |
| **P0-4 部署** | PARTIAL | **PARTIAL（未接线，线上无效）** | B-2 |
| **迁移** | PASS | **PARTIAL（死代码）** | B-3 |
| P0-5 展示证明 | PASS | **PASS** | 纯逻辑 + 6 项测试 |
| D5 授权语义 | PASS | **PASS** | 10 项测试 + UI 文案一致 |
| **D2 执行失败降级** | PASS（代码级） | **FAIL（生产无效）** | B-1 |

**从 4 个 PASS 变成：3 个 FAIL/PARTIAL 需要修，1 个降级为 NOT_TESTED。**

这就是自审的意义 —— 如果我不审，这些都会被当成已完成交出去。

---

## 七、这几个问题有什么共同点

把 B-1 / B-2 / B-3 放在一起看，它们是**同一类错误**：

```
机制写好了  +  测试通过  +  ≠  功能生效
                            ↑
                    缺的那一步是"接线"
```

| 缺陷 | 机制 | 测试 | 接线 |
|---|---|---|---|
| B-1 D2 | `EnforcementOutcome` + `enforceLeave` 完整 | 5 项全绿 | **三个接缝没人赋值** |
| B-2 P0-4 | `InterceptRepository` 完整 | 11 项全绿 | **`repository=` 没传** |
| B-3 迁移 | `InterceptMigration` 完整 | 8 项全绿 | **`run()` 没人调** |

**24 项测试全部通过，而这三件事在生产里一件都没生效。**

### 为什么测试抓不到

因为测试构造的是**被测对象**，不是**生产路径**：

```kotlin
// 测试里（InterceptRepositoryCrashTest）
val repo = InterceptRepository(disk)
val guard = InterceptGuard(disk, ledger, { wall }, repository = repo)   // ← 手工传了

// 生产里（InterceptRuntime:79）
val g = InterceptGuard(
    AtomicJsonFile(File(dir, "guard.json")), book,
    clock = System::currentTimeMillis, ids = { UUID.randomUUID().toString() },
)                                                                       // ← 没传
```

**测试和生产走了两条不同的构造路径，而没有任何测试覆盖生产那条。**

### 这印证了我自己写过的那句话

我在档案 §10.3 写过：**"测试通过的原因，可能正是 bug 存在的原因"**。

现在它应验在我自己身上，而且是我最没想到的地方 —— 不是逻辑错，是**连线漏了**。

---

## 八、我建议怎么修（不擅自动手）

### 8.1 优先级

| 顺序 | 修什么 | 理由 |
|---|---|---|
| **1** | **B-1 D2 接线** | 唯一的 FAIL，且当前行为有害（多按 HOME + 静默失败） |
| **2** | **B-2 P0-4 接线** | 让 11 项故障注入测试真正有意义 |
| **3** | **B-3 迁移调用** | 依赖 B-2（没有快照就没有迁移） |
| 4 | 清理死常量 / 死字段 | 清晰度 |

### 8.2 关键：加"接线测试"，不只是修这一处

如果只修代码不加防护，下一轮还会犯。建议：

```kotlin
// 强制接缝必须被替换，否则启动就失败
private fun requireWired(name: String, replaced: Boolean) {
    check(replaced) { "$name was never wired; D2 cannot work" }
}

// 或者更简单：把默认实现改成显式抛异常
var currentForeground: () -> String? = {
    error("currentForeground was not wired")
}
```

**默认值 `{ null }` 是最危险的一种 —— 它不报错，只是回到"看起来还在前台"这个错误答案。**

### 8.3 我建议的验证方式

修完后必须有一条测试：**从生产入口构造**，而不是从测试里手工构造。

比如加一个 `InterceptRuntimeWiringTest`，检查 `ensure()` 之后：

- `guard` 是通过 repository 构造的（可暴露一个只读标志）
- `currentForeground` 不再是默认实现
- 快照文件在首次 `setConfig` 后存在

这类测试需要 Android 运行时，所以还是 **NOT_TESTED on JVM** —— 但至少可以在编译期用一个
"必须显式提供"的构造签名逼出来（去掉默认值，让编译器报错）。

---

## 九、这次自审改变了什么

### 9.1 数字上

```
修复前我报的：  PASS 8 项 · PARTIAL 2 项 · FAIL 0 项
自审后真实的：  PASS 4 项 · PARTIAL 3 项 · FAIL 1 项 · NOT_TESTED 1 项（降级）
```

### 9.2 更重要的是判断上

我之前反复说：

> 「所有 PASS 都是代码级的，没有一条来自真机。」

这句话**本身不够准确**。准确的说法是：

> 「**有些 PASS 连代码级都不成立 —— 因为代码没被调用。**」

"代码级 PASS" 这个词给了我一个虚假的安全感：只要有代码、有测试，就算 PASS。
但它漏掉了最关键的一问：**这段代码在真实路径上会被执行吗？**

### 9.3 一条我会记住的检查

```
写完一个机制之后，问三个问题：
  1. 谁调用它？        → 如果答案不是"生产代码"，它是死代码
  2. 默认值是什么？    → 如果默认值是"看起来成功"，它会静默地错
  3. 有没有测试走过生产那条路？ → 如果没有，测试证明的是别的对象
```

---

## 十、这份自审的局限

### 我审到了什么

接线缺失（3 处）、死代码（2 处）、状态判定过宽（1 处）；
确认了测试可复现、保护项完好、UI 文案与新语义一致。

### 我没有审到什么

| 项 | 为什么审不了 |
|---|---|
| 真机行为 | adb 0 台 |
| 无障碍服务的实际效果 | 需要设备 |
| Activity 生命周期那五条悬挂路径 | 需要真机 ROM |
| 前台读取在 Android 上是否真的可用 | 需要设备 |
| 插件在 rc.4 非 Electron 宿主 | 本轮未跑 |
| PRoot .101 真机迁移 | 需要已装 .98 的手机 |

**所以这份自审能证明的仍然是：代码之间接得上 / 接不上。不能证明它在手机上能用。**

---

## 十一、给审核方的一句话

这四轮我做的最有价值的事，可能不是修了那些 P0，而是**每一次都在报告里写清了我不知道什么**。

但这次自审说明：**"我写清了不知道什么"还不够。**

因为我把"机制完成"当成了"问题解决"，而这个偏差没被我自己写下的诚实说明挡住 ——
它们在报告的不同段落里，读者不会自动把它们相加。

**下一轮第一件事不是修 B-1，是把状态表的判定标准改掉：**

```
PASS 的定义从  "有代码 + 有测试"
            改成  "有代码 + 有测试 + 生产路径会执行它 + 我看过执行证据"
```

否则下一次还会交出一份"24 项测试全绿、三件事都没生效"的报告。

