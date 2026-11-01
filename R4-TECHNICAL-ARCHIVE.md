# DSH Go · R4 全阶段技术档案

> 从 1.0.4 到 Phase 4B 的完整记录：做了什么、为什么这么做、核心代码长什么样、证据在哪。

生成时间 2026-11-01 · 作者：lead（DEV / M1 / M2 / M3 协同）

---

## 目录

```
0  总体架构：三层结构
1  起点：main = 1.0.4
2  第一轮 R3：建立对照基线
3  第二轮 R4 加固：三条研发线
4  第三轮 逻辑闭环：证明规则真的生效
   4.1 InterceptGuard 状态机
   4.2 主动交流 ACK 六态
   4.3 M2 统一能力台账
   4.4 M3 配置一致性
   4.5 PROOT .101
5  第四轮 Phase 4：五个 P0
   5.1 P0-5 展示证明是所有门的前提
   5.2 P0-1 事件一定会结束
   5.3 P0-2 结束后重判前台
   5.4 P0-3 NOT_SHOWN 不欠账
6  第五轮 Phase 4B：原子持久化与授权语义
   6.1 P0-4 单一原子快照
   6.2 旧数据迁移
   6.3 D2 执行失败降级
   6.4 D5 授权语义
7  测试体系
8  数字汇总与证据索引
9  未完成 / 未验证
10 我犯过的错（完整清单）
```

---

## 0. 总体架构

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter 界面 (app/lib/)                                    │
│    phone/  拦截设置页、白名单、授权时段                        │
│    chat/   会话与消息                                        │
└───────────────────────┬─────────────────────────────────────┘
                        │ MethodChannel / Dart 侧镜像
┌───────────────────────▼─────────────────────────────────────┐
│  Android 适配层 (loop/intercept, loop/proactive)            │
│    InterceptRuntime    可见性证明、SurfaceSlot、截止定时器     │
│    InterceptPageActivity  只渲染，不裁决                      │
│    ProactivePageActivity / NotificationPort                  │
└───────────────────────┬─────────────────────────────────────┘
                        │ 纯 Kotlin 调用（无 Android 类型）
┌───────────────────────▼─────────────────────────────────────┐
│  纯逻辑内核 (loop/core) —— 全部可在 JVM 上测               │
│    InterceptGuard      拦截状态机 + 四扇放行门                │
│    InterceptRules      决策函数（纯函数）                     │
│    InterceptRepository 单一原子快照的所有者                   │
│    InterceptLedgerBook 回执与计数                            │
│    Coordinator / ProactiveScheduler  主动交流                 │
│    VisibleSurface      同一时刻只有一个 DSH 界面              │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  PRoot 运行时 + DSH 引擎插件 (examples/plugins/)             │
│    dsh-go-bili / dsh-go-cap-ledger / dsh-go-partner          │
└─────────────────────────────────────────────────────────────┘
```

**为什么要分成三层**：内核纯净才能被快速、可重复地测试。所有"这个决定该不该做"的逻辑都在
`loop/core`，因此 248 项测试不需要模拟器、不需要设备、不需要引擎。

**代价**：适配层的行为（Activity 生命周期、可见性）测不到，只能靠编译检查 + 真机。这是我
在 Phase 4 反复强调"代码级 PASS、真机 NOT_TESTED"的原因。

---

## 1. 起点：`main` = DSH Go 1.0.4

```
bf015944  DSH Go 1.0.4     ← 起点
c7a17b1   DSH Go 1.0.3
d38a39a   DSH Go 1.0.2
b963229   DSH Go 1.0.1
a5fa673   DSH Go 1.0.0 — source code (AGPL-3.0)
```

一个已发布的 Android 应用：Flutter 界面 + Kotlin 内核 + PRoot 跑 DSH 引擎。

**起点的问题不是缺功能，是没有验证体系。** 拦截、账本、插件、容器各自能跑，但：

- 没有能复现的测试入口（内核 190 项靠仓库外脚本）
- 没有失败集合基线（Flutter 全量失败数没人统计过）
- 关键路径（Activity 生命周期、崩溃一致性）从没有针对性测试

后面四轮的每一轮，本质上都是在补这三条。

---

## 2. 第一轮 R3：建立对照基线

**分支** `fix/r3-minute-input-on-1.0.4` @ `f1423dc1` · **10 个提交**

这一轮的产出是 **R3 发布版**，价值在于建立了一个**固定的对照点**。之后每次改动都要回答
"相对 R3 是变好还是变坏"，否则"改进"这个词没有意义。

R3 后来成了所有回归比较的基线：`wt-dev` 树就停在 R3 上，用来跑同一套 Flutter 全量。

---

## 3. 第二轮 R4 加固

**分支** `integration/r4-hardening-2026-11-01` @ `ac04b388` · **30 个提交**

三条研发线并行，我负责协调与集成：

| 线 | 范围 | 产出 |
|---|---|---|
| **M1** | 行为管理与拦截 | `InterceptGuard` 初版、四扇门、训练题 |
| **M2** | 插件生态 | cap-ledger 统一台账、bili 插件 |
| **M3** | 人格 / 记忆 / 情绪 | partner 插件、配置表单 |

产出文档：`R4-ACCEPTANCE.md`、`R4-HARDENING-REPORT.md`（31 KB）、`R4-INDEX.md`。

### 这一轮留下了什么债

交付了功能，但**大量结论是"看起来对"而不是"证明对了"**。具体：

| 当时写的 | 实际情况 |
|---|---|
| "Schemastery 宿主已支持，Config 解析通过" | 宿主从不提供那个全局，是自证 |
| "`.101` 改了 l2s 布局，默认不能动" | 两版本布局逐字相同 |
| "970 = 970，无新增失败" | 数量相等不代表集合相同 |
| "191 项内核测试" | 有个类根本不存在，真实 190 |

这些债就是第三轮的主要工作量。

---

## 4. 第三轮 逻辑闭环

**分支** `integration/r4-logic-closure-2026-11-01` @ `868dc330` · **41 个提交**

任务书原话：**"我们现在不是在追求更多代码。我们是在证明现有代码真的按照我们设计的规则运行。"**

### 4.1 InterceptGuard 状态机

#### 五态结局

```kotlin
enum class InterceptOutcome {
    NOT_SHOWN,   // 页面从未被证明在屏上：什么都没发生，不欠账
    BLOCKED,     // 页面真的展示了：真的拦住了
    RELEASED,    // 用户通过某扇门获得限时放行
    EXITED,      // 紧急退出：记一次拦截，但不给放行
    PAUSED,      // 用户主动暂停
}
```

#### 四扇放行门

```kotlin
// Intercept.kt:599  onReleased
fun onReleased(eventId: String, how: String, now: Long): Boolean = synchronized(lock) {
    if (state.openEventId != eventId) return@synchronized false

    // 第一道闸：页面必须被证明在屏上（P0-5）
    if (state.openShownAt == 0L) return@synchronized false

    when (how) {
        RELEASE_TRAINING -> {
            if (state.drill?.solved != true) return@synchronized false
            // 必须停留够时长，速点四个按钮不算停下来
            if (config.trainingMs > 0L && now - state.openShownAt < config.trainingMs) {
                return@synchronized false
            }
        }
        RELEASE_RULE -> if (!hasUsableRule(now)) return@synchronized false
        RELEASE_WHITELIST -> Unit
        else -> return@synchronized false   // 未知代码一律拒绝
    }
    // …写 releases / 加白名单 / endOpen(RELEASED)
}
```

**为什么门要在守卫侧判**：页面是"不受信任的构建也能伪造"的那一面。
页面只报告"我按了哪扇门"，"这扇门存不存在"由守卫决定。

#### 训练题的确定性铸造

```kotlin
// Intercept.kt:204
fun of(eventId: String): InterceptDrill {
    var state = seedOf(eventId)
    fun next(bound: Int): Int {
        // SplitMix64：小、确定、足够挑四个数字
        state += -0x61c8864680b583ebL
        var z = state
        z = (z xor (z ushr 30)) * -0x40a7b892e31b1a47L
        z = (z xor (z ushr 27)) * -0x6b2fb644ecceee15L
        z = z xor (z ushr 31)
        return ((z ushr 1) % bound).toInt()
    }
    // …挑四个不重复的数字，决定升序还是降序
}
```

**从 eventId 派生**，所以页面只能"按"，不能"造"或"重摇"。同一事件永远同一道题。

```kotlin
// Intercept.kt:754
fun tapDrill(eventId: String, value: Int): Boolean = synchronized(lock) {
    if (state.openEventId != eventId) return@synchronized false
    val current = state.drill ?: return@synchronized false
    val next = current.tap(value)
    state = state.copy(drill = next)
    persist()
    true
}
```

#### 这次修掉的洞

| 缺陷 | 修复前 | 修复后 |
|---|---|---|
| `RELEASE_RULE` 无条件放行 | 没配任何窗口，点一下就给 10 分钟 | 必须有窗口 **且** 此刻在窗口内 |
| 换目标 APP 覆盖 `openEventId` | 旧事件永不结算 | 先判"同时只开一个" |
| 拒绝的放行看起来像成功 | 页面消失，人以为进去了 | 留在页面并说明原因 |
| 未显示被杀记成 Dismissed | Dismissed 会重置忽略计数 | 记 NOT_SHOWN |

### 4.2 主动交流 ACK 六态

```kotlin
// CoreModel.kt:68
enum class Engagement { RESPONDED, DISMISSED, ACKED, IGNORED_SEEN, UNCONFIRMED, NOT_DELIVERED }
```

注释原文（值得整段引用）：

> The difference between ACKED, IGNORED_SEEN and UNCONFIRMED is the whole point: a page that
> merely appeared on screen proves nothing about attention, so only an explicit acknowledgement
> starts the clock. Ignoring is therefore *never* inferred from visibility alone — it takes an
> ACK plus ReplyWindow of silence.

```
UNCONFIRMED  ──用户点「我看到了」──►  ACKED
     │                                  │
     │ 页面展示了但没点                 │ 回复窗口内回复
     ▼                                  ▼
  永远不降级                        RESPONDED
  （不推断成"已忽略"）                 
                                     │ 窗口内沉默
                                     ▼
                                IGNORED_SEEN
```

**关键不变式**：`UNCONFIRMED` 永远不会退化成 `IGNORED_SEEN`。只有 `ACKED` 能到。

### 4.3 M2 统一能力台账

#### 先查宿主，再决定方案

| 证据 | 位置 |
|---|---|
| `provide(name, value, check)` | `cordis/src/reflect.ts:277` |
| `get(name, strict)` — 不要求 inject 的读 | `cordis/src/reflect.ts:233` |
| `ctx.inject` + 服务上下线重评估 | `cordis/src/registry.ts:176` |
| `ctx.tools` 自己就这么注册 | `cordis/src/service.ts:57` |

**宿主支持插件间服务注入** → 所以没有退到"共享存储 + 文件锁"那条更弱的路。

```
cap-ledger   ctx.provide('dshGoCapabilityLedger', registry)     ← 唯一提供方
bili         ctx.get('dshGoCapabilityLedger') + ctx.inject(...)  ← 消费方
```

一份内存台账、一个写者，不存在两个插件无锁覆盖同一 JSON。

#### 六态与"假健康"的消除

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

现在：`healthy = callable && runs>0 && lastRunOk===true`。未跑过显示「已加载 / 可以调用 / 尚未验证实际执行」。

#### 真网络抓到的两个致命 bug

打桩测试永远发现不了，因为它们只在真网络出现：

1. `getJson` 先判 `res.ok===false` → 而 B站风控是 HTTP 412 + body `{"code":-412}`
   → **body 从没被读，匿名重试是死代码，真机 100% 查不到**
2. 自造 UA `dsh-go-bili-peek/0.1` 被风控判 412（同 IP 浏览器 UA 返回 200）

真实验证：`peek_bili_video` 真注册、execute 719ms、公开 BV 查询成功返回标题/UP/播放数。

### 4.4 M3 配置一致性

#### 我上一轮的自证被推翻

| 我说过 | 真相 |
|---|---|
| "Schemastery 宿主已支持，Config 解析通过（uid 59）" | **宿主从不提供 `globalThis.__dshSchemastery`**。我手动塞进去再证明能取到 |

全量搜整棵 `resources/app.asar`（全部 .js/.cjs/.mjs）：**命中 0 个文件**。

#### 四个问题逐条查实

| # | 问题 | 答案 |
|---|---|---|
| 1 | 宿主提不提供那个全局 | **不提供**。改为同步 `createRequire` 从宿主树取 |
| 2 | 表单保存落到哪 | `plugin-config.js:289` → 宿主 `dsh-config-editor edit()` → `cordis.patch.yml` |
| 3 | 插件运行时从哪读配置 | **cordis 注入的 `apply(ctx, config)` 第二参** |
| 4 | 改配置能否改运行行为 | **能，且即时**：字段全标 volatile → `_commitVolatile`，不重启插件 |

第 3 条是关键：上一版把第二参当 options、配置自己读 JSON —— **这才是两套数据源的根源**。

#### 端到端证据（不是模拟）

`live-host/`：把 partner 当"用户安装的 bundle"真装进去 → 真启动 DSH 0.2.1-rc.2 →
真 `ConfigEditor.edit` → **真杀进程重启** → 15/15 断言通过。

#### 真机暴露的 4 个 bug（上一轮单测全绿）

| # | bug | 为什么单测发现不了 |
|---|---|---|
| 1 | `cannot get property "tools" without inject` | cordis 的 ctx 是 **Proxy**，没 inject 过的服务读一下就抛；假 ctx 是普通对象 |
| 2 | `Cannot find package '@deepseek-ai/dsh-tools'` | 零依赖包里的动态 import 在真机必然失败 |
| 3 | `tools.enabled` 是 volatile ⇒ 打开时 cordis 不重启插件 ⇒ apply 里的开关判断永久失效 | 假 ctx 不会重放这条生命周期 |
| 4 | 目的面板拼相对路径，永远读不到 | 单测里 `DSH_HOME` 总是有值 |

### 4.5 PROOT .101

#### 事实纠正

| 我说过 | 真相 |
|---|---|
| "`.101` 重写了 l2s 布局，加了 `.proot.l2s.` 中间态" | **错**。两版本布局逐字相同 |

DEV 从源码各自编译出二进制，在 `--link2symlink` + `PROOT_L2S_DIR` 下实跑：

```
.98  : .l2s.<name><NNNN>.<count> 存储文件 + .l2s.<name><NNNN> 中间名 + 主机绝对路径目标
.101 : 完全相同的布局
```

`.proot.l2s.` 前缀在 `.101` 源码里但**在 `-DUSERLAND` 分支后面，不在 Termux 官方 deb 里**。
我用 `strings` 独立复核真实产物：`5.1.107.101` + `.l2s.`，**没有** `.proot.l2s.`。

#### 迁移为什么本来就兼容

`L2sMigration.chain()` **从不解析 store 名字**，它顺着符号链接走到普通文件为止。
`.98` 是两跳、`.101` 是一跳，终点都是普通文件，所以同一套遍历都能转。

#### 顺带修的一个真实数据丢失缺陷

PRoot 撤销名字时：先改名存储文件、再改中间名。两步之间被杀 →
中间名指向不存在的名字，而**存储文件（数据的唯一副本）没有任何名字指它**。

旧代码把它当孤儿**删掉** → 名字指向空气 → 下次直接启动 → 安装静默丢文件。

```
旧：Done(links=0, removed=2)  store=[]  compatibilityReason=null  两个名字都读不出
新：Done(links=2, removed=0, repaired=1)                          两个名字都读回原内容
```

`repair()` 只在唯一确定时才动手：按名字前缀只有一个候选、且计数不小于等待它的名字数。
不够确定就原样不动、store 保持非空，让 `DirectLaunch.compatibilityReason` 继续选择兼容启动。

**猜一下比让用户用能工作的启动器更糟。**

---

## 5. 第四轮 Phase 4：五个 P0

**分支** `fix/r4-phase4-2026-11-01` @ `40c69eb1` · **49 个提交累积**

技术依据是 Claude 的架构审查报告，但我**逐条回代码核对**，没有照抄。

### 5.0 我核对出的、报告没点透的一条

报告的 P0-5 说"未展示页面可以走任何一扇门"。我回代码发现更严重：

```kotlin
// 修复前
if (config.trainingMs > 0L && shownAt != 0L && now - shownAt < config.trainingMs) {
    return false
}
```

`shownAt == 0` 时整条件**短路为 false** → 不 return → **不要求停留时长**。

也就是说：**页面根本没显示，反而是通过训练最快的路径。**这不只是忽略证明，是**把证明用反了**。

### 5.1 P0-5：展示证明是所有门的前提

```kotlin
// Intercept.kt:617 —— 加在 when(how) 之前
if (state.openShownAt == 0L) return@synchronized false
```

一行，但它把四扇门 + 两个动作（exit / pause）全部锁在"页面真的在屏上"之后。

`openShownAt` 由适配层的证明写入 —— 必须是 **attached + shown + laid out + focused**：

```kotlin
// InterceptPageActivity.kt:106
private fun proveVisible() {
    val decor = runCatching { window?.decorView }.getOrNull()
    val visible = decor != null && decor.isAttachedToWindow && decor.isShown &&
        decor.width > 0 && decor.height > 0 && decor.hasWindowFocus()
    if (visible) {
        shown = true
        InterceptRuntime.onPageShown(id)   // ← 只有这里能写 openShownAt
        render()
        return
    }
    if (++attempts <= MAX_PROOF_ATTEMPTS) main.postDelayed(proof, PROOF_STEP_MS)
}
```

**五个条件缺一不可**。只判 `isShown` 不够（可能被遮挡），只判 `hasWindowFocus` 不够（可能还没布局）。

### 5.2 P0-1：事件一定会结束

#### 问题

所有结局都由**页面**报告。页面不在的五条路径：

| # | 触发 | 结果 |
|---|---|---|
| a | `startActivity` 没抛异常，但 ROM 静默丢弃 | Activity 从未创建，不会有 onStop |
| b | 页面已展示 → 电源键 → onStop 看到熄屏 return → 锁屏上点通知进目标 APP | 不会再 stop 一次 |
| c | 系统回收 / 未列入 configChanges 的重建 | 重建时 finish 不报告 |
| d | Intent 晚到，deadline 已过 | 直接 finish，不报告 |
| e | 可见性证明 20 次都失败 | 重试用完就停，不报告 |

悬挂期间，守卫对每个目标 APP 返回 `Allow(already_open)` → **全部放行，直到进程重启**。

#### 修复：把到期判定从页面搬到运行时

```kotlin
// InterceptDeadline.kt:65 —— 纯函数，无时钟，无 Android
fun due(open: Open?, now: Long,
        proofWindowMs: Long = DEFAULT_PROOF_WINDOW_MS,
        pageTtlMs: Long = DEFAULT_PAGE_TTL_MS): Due {
    if (open == null) return Due.Nothing
    // 还没展示：由证明窗口决定，不是 TTL
    if (open.shownAt == 0L) {
        return if (now - open.requestedAt >= proofWindowMs) Due.NotShown else Due.Nothing
    }
    return if (now - open.shownAt >= pageTtlMs) Due.Expired else Due.Nothing
}
```

**两条规则分离**：

| 常量 | 值 | 管什么 |
|---|---|---|
| `DEFAULT_PROOF_WINDOW_MS` | 5 秒 | 启动了但没起来 → NOT_SHOWN |
| `DEFAULT_PAGE_TTL_MS` | 10 分钟 | 展示了但人不理 → BLOCKED(page_ttl) |

有测试专门断言这两者必须相差 10 倍以上 —— 因为把"静默丢弃"也等 10 分钟，功能就等于停用。

#### 运行时怎么驱动

```kotlin
// InterceptRuntime.kt:210
fun settleIfDue() {
    val open = if (requestedAtMono == 0L) null
               else InterceptDeadline.Open(requestedAtMono, shownAtMono)
    when (InterceptDeadline.due(open, mono())) {
        InterceptDeadline.Due.Nothing -> Unit

        InterceptDeadline.Due.NotShown -> {
            g.onUnavailable(id, "no_visibility_proof", System.currentTimeMillis())
            backoff.note(pkg, mono())                 // 15 秒退避（不是放行）
            InterceptPageActivity.withdraw(id)
            VisibleSurface.release(OWNER_INTERCEPT, id)
            enforceLeave(pkg, "no_visibility_proof")  // D2：试着把 APP 关掉
        }

        InterceptDeadline.Due.Expired -> {
            g.expireOpen(id, System.currentTimeMillis())  // 记 BLOCKED，不给放行
            InterceptPageActivity.withdraw(id)
            VisibleSurface.release(OWNER_INTERCEPT, id)
            InterceptPageActivity.goHome(app)
            recheckForeground("intercept_page_ttl")
        }
    }
}
```

#### 单调时钟，不是墙钟

```kotlin
private fun mono(): Long = android.os.SystemClock.elapsedRealtime()
```

**为什么**：手动改系统时间或时区跳变，不能"跳过"证明窗口，也不能让 TTL 白等。
（Monk 的注释说得好：定时器跑在 uptime 上，所以锁屏期间不会白等到期。）

#### 退避**不是**放行

```kotlin
// 两套数据结构，语义完全不同
releases[pkg]        = now + releaseMs    // 放行：APP 可用
retryAfter[pkg]      = now + 15_000       // 暂不尝试：不拦也不放行
```

如果把退避写进 `releases`，就等于"证明失败 → 放行 15 秒"，**违反 D2 最后一句**。

### 5.3 P0-2：结束后重判前台

#### 绕过路径

```
拦截页展示中，用户用「最近任务」切回目标 APP
  ├─ 窗口事件先到 → 守卫仍是 open → Allow(already_open)
  └─ 随后页面 onStop → 结算
     → 此后再没有窗口事件 → 目标 APP 一直可用
```

#### 修复

六条结束路径全部要求宿主重读前台：

```kotlin
// InterceptRuntime.kt
fun onReleased(...) { if (ok) { clearDeadlineState(); recheckForeground("intercept_released") } }
fun onExited(...)   { if (ok) { clearDeadlineState(); recheckForeground("intercept_exited")   } }
fun onPaused(...)   { if (ok) { clearDeadlineState(); recheckForeground("intercept_paused")   } }
fun onPageGone(...) { clearDeadlineState(); recheckForeground("intercept_page_gone") }
// settleIfDue 里的两条（not_shown / page_ttl）同上
```

#### 一个设计选择

```kotlin
var recheckForeground: (String) -> Unit = { reason ->
    runCatching { LoopRuntime.recheckForeground(reason) }
}
```

做成接缝而不是直接调 `LoopRuntime`：依赖只应该单向（无障碍宿主 → 拦截特性），
而且拦截模块的源码可以脱离整个宿主单独编译检查。

### 5.4 P0-3：NOT_SHOWN 不欠账

#### 问题

```kotlin
// onForeground 决定 Block 的那一刻就扣账
state = s.copy(
    lastTriggerAt = now,           // ← 冷却开始
    countToday = s.countToday + 1, // ← 每日额度 -1
)

// 但 onUnavailable 只 endOpen，不回滚
fun onUnavailable(eventId: String, code: String, now: Long): Boolean {
    endOpen(now, InterceptOutcome.NOT_SHOWN, code)
    persist()
}
```

结果：**一次从未上屏的拦截，让目标 APP 在冷却期内被放行，并吃掉一格当日额度。**

#### 修复：Block 时记下扣了什么，NOT_SHOWN 时退还

```kotlin
// Block 决定时捕获
chargedLastTriggerAt = s.lastTriggerAt
chargedLastTriggerPackage = s.lastTriggerPackage
chargedCountToday = s.countToday

// onUnavailable 里退还（还原到上一次拦截留下的值，不是清零）
state = state.copy(
    lastTriggerAt = chargedLastTriggerAt,
    lastTriggerPackage = chargedLastTriggerPackage,
    countToday = chargedCountToday,
)
```

**还原而不是清零**：之前真实的拦截仍然有效。

跨进程（`recover()`）无从知道旧值，只做它能证明的事：把这次触发的扣减拿掉，下限 0。

---

## 6. 第五轮 Phase 4B：原子持久化与授权语义

**分支** `fix/r4-transactional-state-2026-11-01` @ `311fb9d5` · **54 个提交累积**

### 6.1 P0-4：单一原子快照

#### 问题形状

```
一次拦截 = guard.json + ledger.json
两份各自原子（temp → flush → fsync → rename → dir fsync）
合起来不原子 → 崩在两次 rename 之间 → 自相矛盾的状态
```

三种可观察后果：

1. 白名单写在 guard、回执写在 ledger：只成功一半 → 白名单丢了
2. `blockedCount` 已加而事件变成 NOT_SHOWN → 账本说有 N 次拦截，回执只有 N-1 条
3. `triggerCount` 已加但没有回执 → 触发数永远比回执多

#### 方案选择（ADR 0001）

| | 方案 | 改动 | 结论 |
|---|---|---|---|
| **A** | 单一原子 JSON 快照 | 小：复用 `AtomicJsonFile` | **采用** |
| B | SQLite 单事务 | 大：C 依赖 + 迁移 + 体积 | 拒绝：为 4 个计数引数据库不成比例 |
| C | Event log + snapshot | 中：日志格式 + 重放 + 压缩 | 拒绝：状态很小，收益抵不上复杂度 |

A 能满足一致性的依据：`AtomicJsonFile` 已经实现了完整的崩溃语义，见下。

#### 已有的原子写（复用，不重写）

```kotlin
// SnapshotStore.kt:70
override fun write(map: Map<String, Any?>) {
    file.parentFile?.mkdirs()
    val bytes = Json.write(map).toByteArray(Charsets.UTF_8)
    FileOutputStream(temp).use { out ->
        out.write(bytes)
        out.flush()
        out.fd.sync()              // ← fsync
    }
    if (temp.length() != bytes.size.toLong()) error("short write")   // ← 校验长度
    keepPrevious()                 // ← 旧文件先备份
    replace()                      // ← ATOMIC_MOVE
    syncDirectory()                // ← 目录 fsync
}
```

#### 提交协议（本轮的核⼼）

```kotlin
// InterceptRepository.kt:115
fun commit(config, guardState, ledgerState, appliedEventIds): Boolean {
    val next = Snapshot(..., lastCommittedTransactionId = transactions + 1)

    val problem = validate(next)
    if (problem != null) { lastCommitError = problem; return false }

    return try {
        store.write(next.toMap())              // 1. 一次原子写

        val readBack = store.read()            // 2. 回读
        val landed = ... Snapshot.fromMap(...)

        val expectedText = Json.write(next.toMap())      // 3. 比对（比文本，不比 Map）
        val actualText   = Json.write(landed.toMap())
        if (expectedText != actualText) {
            lastCommitError = "commit read-back differs from what was written"
            return false
        }

        committed = next                       // 4. 只有到这里才动内存
        transactions = next.lastCommittedTransactionId
        true
    } catch (t: Throwable) {
        lastCommitError = ...
        false
    }
}
```

**第 2、3 步不可省**：一个"返回成功却没落盘"的 store 是这个协议存在的唯一理由，
除此之外没有任何办法发现它。故障注入测试专门验证这一条。

**第 4 步不可提前**：先改内存，就等于让"写失败"看起来像"提交成功"。

#### 快照结构

```json
{
  "schemaVersion": 1,
  "config":      { ... },     // InterceptConfig.toMap()
  "guardState":  { ... },     // InterceptState.toMap()
  "ledgerState": { ... },     // InterceptLedger.toMap()
  "appliedEventIds": [ ... ], // 幂等去重键
  "lastCommittedTransactionId": 42
}
```

#### 关键约束

**不是"两个类共用一个 AtomicJsonFile 然后各写各的"。**
那只是把两个文件换成一个文件、仍然两次写。必须是**统一的事务所有者**在一次调用里提交完整状态。

```kotlin
// Intercept.kt  persist()
private fun persist() {
    val repo = repository
    if (repo != null) {
        val ok = repo.commit(
            config = config.toMap(),
            guardState = state.toMap(),
            ledgerState = ledger.state.toMap(),   // ← 账本状态在同一次提交里
            appliedEventIds = ledger.appliedIds(),
        )
        storageError = if (ok) null else (repo.lastCommitError ?: "commit failed")
        return
    }
    // 没有仓库时退化为旧的单文件写（纯逻辑测试用）
}
```

被仓库持有账本时，账本自己的 `persist()` 只改内存：

```kotlin
private fun persist() {
    if (sharedWithRepository) return   // ← 写属于仓库的事务，不属于这本书
    ...
}
```

#### 11 项故障注入

| # | 注入 | 期望 |
|---|---|---|
| 1 | 临时文件创建失败 | 提交失败；磁盘仍是上一份；新进程看不到白名单 |
| 2 | 写到一半（截断 40 字节） | 回读失败；下一进程报 recoveryIssue |
| 3 | fsync 前死亡 | 旧快照完整、仍可解析 |
| 4 | 替换后、内存更新前死亡 | 新进程读到**已提交**状态 |
| 5 | 写"成功"但静默丢弃 | 回读发现 → 报失败 |
| 6 | 同一 eventId 重复提交 | 只计一次 |
| 7 | 每日计数更新中断 | 重启后是已提交的值，不翻倍 |
| 8 | 快照自相矛盾 | 拒绝提交 |
| 9 | schemaVersion 更新 | 拒绝加载、不覆盖 |
| 10 | 白名单写入失败 | 既无条目也无回执 |

**"重启"的定义**：每次都是新的 Repository + 新的 Ledger + 新的 Guard，只共享字节。
复用内存对象假装恢复，就测不出任何东西。

#### 我在这轮改错的两处

**错误 1：校验器写得太严，所有提交都失败。**

```kotlin
// 第一版（错的）
if (ended > receipts.size) return "counts exceed receipts"
```

读起来天经地义，实际把每一次正常提交都拒了：**`blockedCount` 数的是"真上屏了"，
而回执要到事件结束才写**。所以 `blockedCount=1, receipts=0` 是合法的中间态。

> **校验太严不是更安全，是"所有提交都失败、状态永远停在第一次写"。比不校验更糟。**

现在只保留三条真正不可能成立的关系：

```kotlin
if (trigger < receipts.size)          return "triggerCount smaller than receipts"
if (appliedIds has duplicates)        return "appliedEventIds has duplicates"
if (openId != null && openPackage == null) return "open event without a package"
```

**错误 2：回读比对用 Map 相等。** JSON 把数字读成 `Long`，写下去是 `Int`，
`Map.equals` 因装箱不同而失败——与持久化毫无关系。改成比对序列化文本。

### 6.2 旧数据迁移

#### 流程

```
启动
  ├─ 快照存在且可读    → AlreadyMigrated（不重跑，旧文件原样留着）
  ├─ 快照存在但读不懂  → recoveryIssue → RECOVERY_REQUIRED
  └─ 没有快照
       ├─ 两个旧文件都不存在 → Fresh
       └─ 至少一个存在       → 四条一致性检查
```

#### 四条一致性检查

| # | 检查 | 不通过说明什么 |
|---|---|---|
| 1 | 有 `openEventId` ⇒ `triggerCount ≥ 1` | 有未结算拦截却无触发记录 |
| 2 | 各结局计数之和 ≤ 回执数 | 记账多于历史 |
| 3 | 回执数 ≤ `triggerCount` | 有结束没有触发 |
| 4 | **白名单条目数 ≤ `userReleasedCount`** | 有永久授权但账本不记得授予过 |

第 4 条最要紧：

```kotlin
// InterceptMigration.kt
val whitelist = config?.let { M.list(it, "whitelist") } ?: emptyList<Any?>()
val released = ledgerState?.let { M.long(it, "userReleasedCount") } ?: 0L
if (whitelist.size.toLong() > released) {
    return Result.RecoveryRequired(
        "the whitelist has entries the ledger never recorded a release for",
        "whitelist=" + whitelist.size + " userReleasedCount=" + released,
    )
}
```

**白名单是永久权限。** 如果它在账本里找不到来源，只有两种可能：凭空写进去的，
或者放行记录丢了。**代码绝不补一条放行记录**——那是伪造历史。

#### 不一致时的行为

```
RecoveryRequired
  ├─ 不写快照          ← 旧数据一个字节都不动
  ├─ 不删旧文件        ← 用户仍能读到自己的数据
  ├─ 不伪造白名单      ← 不补、不删、不改
  ├─ 不产生新放行授权
  └─ 理由进 recoveryIssue，供人工处理
```

**为什么不自动修复**：两份文件不一致时，"哪一份是对的"**没有答案**。
程序看到的只有两个矛盾的事实，猜一个就等于替用户决定他的白名单是否存在。

#### 中断安全

| 中断位置 | 结果 |
|---|---|
| 写快照之前 | 什么都没变，下次重跑 |
| 写快照过程中 | `AtomicJsonFile` 保证要么旧要么新 |
| 写快照之后 | 下次看到快照 → AlreadyMigrated |

### 6.3 D2：执行失败不得隐形放行

#### 问题

```kotlin
if (backoff.isHoldingOff(packageName, mono())) {
    Log.i(TAG, "holding off ...")
    return          // ← 目标 APP 仍在前台可交互
}
```

**"我们暂时不再试着弹页面"是一个关于我们的陈述，不是给他们的许可。**
但代码行为等价于放行。

#### 修复后的链条

```
展示失败
  → 记 NOT_SHOWN（退还额度与冷却，P0-3）
  → 回 HOME
  → 重新读前台
  → 还在？再试一次
  → 还不行？ENFORCEMENT_UNAVAILABLE
```

```kotlin
// InterceptRuntime.kt:253
private fun enforceLeave(packageName: String, code: String) {
    if (!goHome()) { reportEnforcementUnavailable(packageName, code, 0); return }
    main.postDelayed({
        val after = currentForeground()
        if (!EnforcementOutcome.stillInFront(after, packageName)) {
            recheckForeground("intercept_enforced_exit")   // 真走了
            return@postDelayed
        }
        if (!goHome()) { reportEnforcementUnavailable(packageName, code, 1); return@postDelayed }
        main.postDelayed({
            val second = currentForeground()
            if (EnforcementOutcome.stillInFront(second, packageName)) {
                reportEnforcementUnavailable(packageName, code, 2)   // 如实报失败
            } else {
                recheckForeground("intercept_enforced_exit")
            }
        }, HOME_RETRY_MS)
    }, HOME_RETRY_MS)
}
```

#### 最关键的一行判定

```kotlin
// EnforcementOutcome.kt
fun stillInFront(foregroundAfterHome: String?, target: String): Boolean {
    if (foregroundAfterHome == null) return true   // ← 读不到 = 未确认离开
    return foregroundAfterHome == target
}
```

**把"不知道"当成"已离开"，正是把失败记成成功的那条路。**

#### 如实说明物理限制

普通应用**无法**保证绝对阻断（Home 手势、最近任务、系统设置都能绕过）。
能保证的是三件事：**不放行、不误记、如实报告**。

### 6.4 D5：授权语义

#### 修改前：两处把降噪手段当成访问许可

```kotlin
if (config.dailyMax > 0 && countToday >= config.dailyMax)
    return InterceptDecision.Allow(packageName, REASON_DAILY_MAX)   // 「今天别打扰」→「今天随便用」

if (lastTriggerPackage == packageName && lastTriggerAt != 0L &&
    now - lastTriggerAt in 0 until config.cooldownMs)
    return InterceptDecision.Allow(packageName, REASON_COOLDOWN)    // 「别马上再弹」→「这两分钟随便用」
```

#### 修改后

```kotlin
// Intercept.kt:324
if (config.dailyMax > 0 && countToday >= config.dailyMax) {
    return InterceptDecision.Ignore    // 不提问题，也不许可
}
if (lastTriggerPackage == packageName && lastTriggerAt != 0L &&
    now - lastTriggerAt in 0 until config.cooldownMs) {
    return InterceptDecision.Ignore
}
```

`Ignore` 的语义：**不弹题，也不标记为已许可**。所以下一次读前台时仍然可以拦。

#### 一个真实的绕过路径被关掉

`endOpen()` 在 BLOCKED / EXITED 之后**仍保留 `lastTriggerAt`**：

```
用户按「紧急退出」→ 事件以 EXITED 结束，但 lastTriggerAt 还在
  → decide() 看到「在冷却内」→ 返回 Allow
  → 退出等于换到 2 分钟免费使用
```

修复：

```kotlin
// endOpen 里
lastTriggerAt = if (outcome == NOT_SHOWN || outcome == BLOCKED || outcome == EXITED) {
    0L          // 这三种结局不留下任何放行理由
} else {
    s.lastTriggerAt    // 只有 RELEASED / PAUSED 可以
},
```

#### 完整许可清单（只剩四条）

```
WHITELIST   永久，直到用户撤销
PAUSED      用户明确暂停，到 pauseUntil
RELEASED    答对训练题等真实授权，到 releaseUntil
授权时段     用户配置的时间窗口内自动放行
```

**除此四条以外，没有任何路径产生 `Allow`。**

---

## 7. 测试体系

### 7.1 为什么需要专门做这件事

第三轮之前，内核 190 项测试靠**仓库外**的 `D:\code\R4\lc-verify.ps1` 跑。
这个脚本依赖 Windows 绝对路径和本机 Gradle 缓存，**别人无法复现**。

而 `:app:testArm64DebugUnitTest` 也替代不了它 —— 我查到了根因：

```
app/android/.gitignore 第 1、4、5 行：
  gradle-wrapper.jar
  /gradlew
  /gradlew.bat
```

**仓库里从来没有 `gradlew`**（`git ls-files | grep gradlew` 为空），WSL 也没有系统 gradle。
所以 "No tests found for given includes" 的真因是：**根本没有 gradlew 可跑**。
不是"测试没被识别"，是"跑测试的工具不在仓库里"。

### 7.2 `tooling/run-kernel-tests.sh`

自包含：找 JDK → 找 jar（`KOTLIN_JARS` → Gradle 缓存 → `~/.m2`）→ 编译 → 运行。

**关键设计：自动发现测试类，不手写名单。**

```bash
# 发现，而不是硬编码
while IFS= read -r f; do
  pkg="$(grep -m1 '^package ' "$f" | sed 's/^package //')"
  cls="$(basename "$f" .kt)"
  CLASSES+=("$pkg.$cls")
done < <(find "$TEST/loop" -name '*Test.kt' ! -name 'LoopHardeningTest.kt' | sort)
```

**为什么要这样**：旧的硬编码名单里有 `io.github.ccch1mneyyy.dsh_app.loop.ProtectedForegroundTest`，
**这个类在仓库里根本不存在**。JUnit 对无法解析的类名只报 `initializationError`，不计入 `Tests run`，
所以我一直报的"191"比真实多一个。**真实是 190。**

> 只要名单是手写的，它就会说谎。

### 7.3 为什么排除两个类

| 类 | 为什么 |
|---|---|
| `LoopHardeningTest` | 引用 Android 类 `InteractionHub`，JVM 侧编译不过 |
| `L2sMigrationTest` | 需要 POSIX 文件 API，**且必须非 root** |

L2s 那条值得单独说：它有三条测试 `chmod 000` 后断言遍历中断，而 **root 照读**。
所以 root 下跑必然假失败。我试过 Windows（`setPosixFilePermissions` 直接抛）、
WSL root（4 条假失败）、最后 **WSL 非 root 才 28/28**。

**Android 运行时从不是 root，所以非 root 那次才是诚实的那次。**

### 7.4 测试清单

| 类 | 项数 | 覆盖 |
|---|---|---|
| `AckStateMachineTest` | — | ACK 单步语义 |
| `AgentWireTest` | — | agent 线协议 |
| `CoordinatorTest` | — | 统一仲裁 |
| `InterceptChainTest` | — | 拦截链路 |
| `InterceptDrillTest` | 9 | 训练题 |
| `InterceptRecoveryTest` | 7 | 进程恢复（重写） |
| `InterceptReleaseDoorTest` | 9 | 四扇放行门 |
| `InterceptSurfaceBudgetTest` | 6 | 预算 |
| `InterceptVisibilityGateTest` | 6 | **P0-5** |
| `InterceptSplitStoreTest` | 3 | **P0-4 检测** |
| `InterceptDeadlineTest` | 10 | **P0-1** |
| `InterceptRejudgeTest` | 4 | **P0-2** |
| `InterceptRepositoryCrashTest` | 11 | **P0-4 故障注入** |
| `InterceptMigrationTest` | 8 | **旧数据迁移** |
| `InterceptAuthorizationSemanticsTest` | 10 | **D5** |
| `EnforcementOutcomeTest` | 5 | **D2** |
| 其余（Kernel*/LedgerBook/Proactive*/SurfaceSlot 等） | — | 内核基础 |
| **合计** | **248** | 25 个类 |

### 7.5 Flutter 基线：数量相等从来不是证据

```
HARD-full-ft.log    -971      ← hard@ac04b38
HARD-full-ft2.log   -970      ← 同一 commit！
LC-full-ft.log      -969
LC-full-ft2.log     -960      ← 同一份代码，与上一条差 9 条
```

**同一棵树、同一 commit，两次全量跑的失败集合就不同。**

单文件重复跑把两个不稳的测试定死：

| 测试 | 连跑 | 结果 |
|---|---|---|
| `plugin_config_scope_fresh` | 5 次 | **失败 2 / 通过 3** |
| `session_sync` | 3 次 + 2 次 | **每次 `+3 −4`**，逐条固定 |

- 前者：`_until()` 用**真实挂钟** `Future.delayed(10ms) × 500` 轮询，机器一忙就超时
- 后者：`fake_async` 下 `DshConnection._exchange` 留下 **120 秒 Pending timer**

两者在 R3 与 R4 的 **blob 完全相同**，所以不是 R4 引入的回归。
`--concurrency=1` 对跑两棵树结果一致 → **不是竞态，是测试自身非确定性**。

---

## 8. 数字汇总与证据索引

### 8.1 分支全景

```
main                          bf015944   DSH Go 1.0.4（起点，全程未动）
fix/r3-minute-input-on-1.0.4  f1423dc1   R3 发布版（对照基线，未动）
integration/r4-hardening      ac04b388   R4 加固（30 提交）
integration/r4-logic-closure  868dc330   逻辑闭环（41 提交）
fix/r4-phase4-2026-11-01      40c69eb1   Phase 4（49 提交）
fix/r4-transactional-state    311fb9d5   Phase 4B（54 提交）← 最新
```

### 8.2 测试数字

| 项 | 起点 | 现在 |
|---|---|---|
| 内核测试 | 外部脚本，实际 190 | **仓库内入口，25 类 / 248 项** |
| bili 插件 | 69 | **80** |
| cap-ledger | 42 | **50** |
| partner | 96 (+1 skip) | **110 (+1 skip)** |
| L2s 迁移 | 18 | **28** |
| python 守卫 | — | 9 + 8 |

### 8.3 文档索引

| 文档 | 内容 |
|---|---|
| `R4-ACCEPTANCE.md` | R4 验收标准 |
| `R4-HARDENING-REPORT.md` | 第二轮加固报告 31 KB |
| `R4-INDEX.md` | 索引 |
| `R4-LOGIC-CLOSURE-REPORT.md` | 第三轮 29 KB |
| `R4-PHASE4-ACCEPTANCE-REPORT.md` | 第四轮验收 |
| `R4-PHASE4-CONFIG-CONFIRMATION.md` | 策略确认（D1–D7） |
| `R4-PHASE4-CHANGELOG.md` | 逐缺陷记录 |
| `R4-PHASE4-TEST-MATRIX.md` | 测试矩阵 |
| `R4-PHASE4-DEVICE-CHECKLIST.md` | 真机验收清单 |
| `R4-PHASE4B-TRANSACTION-REPORT.md` | 第五轮主报告 |
| `R4-PHASE4B-FAILURE-MATRIX.md` | 故障注入矩阵 |
| `R4-PHASE4B-MIGRATION-REPORT.md` | 迁移设计 |
| `docs/adr/0001-*.md` | ADR：持久化 + 授权语义 + D2 |
| `evidence/phase4/OPEN-SOURCE-RESEARCH.md` | Monk/Nudge 研究 |

---

## 9. 未完成 / 未验证

### 9.1 唯一的阻塞

**一台 ARM64 手机 + adb。** 到目前为止 `adb devices` 一直是 **0 台**。

这意味着：**所有 PASS 都是代码级的，没有一条来自真机。**

### 9.2 PARTIAL

| 项 | 差什么 |
|---|---|
| **P0-4 生产接线** | `InterceptRepository` 在内核层完成并验证，但 **`InterceptRuntime` 仍用两个 `AtomicJsonFile` 构造 guard 与 ledger**，还没切到仓库 |
| Gradle 单测 | 仓库无 `gradlew`；根因已查明，修复未做 |
| 真实 fsync / 掉电语义 | 代码有 `fd.sync()` + 目录 fsync，未在真机验证 |
| M1 白名单 UI | 内核支持写、页面能读能显示，**没有增删入口** |
| M2 跨插件状态观测 | 六态齐全，但宿主**不能自动枚举**运行中的插件 |
| M3 Purpose 自主开口 | 面板读真实数据，但"自己决定开口"属于 surfcore 引擎 |
| Flutter 本轮口径 | Phase 4/4B 未改 Dart，未重新采样 |

### 9.3 NOT_TESTED

| 项 | 原因 |
|---|---|
| 真机 / 模拟器任何交互 | adb 0 台 |
| P0-1 的五条悬挂路径 | 需要真机 ROM 行为才能复现 |
| P0-2「最近任务切回」 | 同上 |
| P0-5 的证明失败场景 | 需要真机悬浮窗 / 分屏 |
| HOME 真的把前台切走 | 需要设备 |
| 真实旧数据迁移 | 夹具格式来自代码，不是真机 pull 的文件 |
| 断电 / 真实 fsync 行为 | 需要物理或内核级故障注入 |
| APK 打包与真包校验 | 全程禁止构建 APK |
| 双 ABI 运行时构建 | 任务书要求先报资源并获批 |
| 旧 .98 升级到 .101 | 需要一台已装 .98 的手机 |
| 阶段 C/D/E/F/G | 未开始（依赖 4 个待拍板的策略问题） |

### 9.4 待回答的 4 个问题

1. **D3**：删按钮后 `RELEASE_RULE` 枚举**保留**（仅测试可达）还是**一起删**？
2. **D5**：`EXITED` 那行（不扣冷却 / 不给放行 / 立即再拦）是否确认？
3. **D6**：「指定会话」= 事件记录的会话还是当前会话？
4. **D7**：「直接回复」观测：宿主事件（A）还是下次进入比对（B）？

D5 那条我在 Phase 4B 已经按"是"实现了（并有测试），如果现在要改，需要回退。

---

## 10. 我犯过的错（完整清单）

这一节是这份文档里我最想写清楚的部分。

### 10.1 结论错误

| # | 我说过 | 真相 | 谁推翻 |
|---|---|---|---|
| 1 | "191 项内核测试" | 190。名单里有个不存在的类 | 我自己（迁入仓库时） |
| 2 | "Schemastery 宿主已支持，Config 解析通过" | 宿主从不提供该全局，我手动塞进去再证明能取到 | M3 |
| 3 | "`.101` 改了 l2s 布局，默认不能动" | 两版本布局逐字相同 | DEV，我用 strings 复核 |
| 4 | "970 = 970，无新增失败" | 同 commit 两次跑就不同；必须比集合 | DEV + 我自己三次采样 |
| 5 | "这是竞态" | 不是。concurrency=1 一致，且单独跑也会失败 | 我自己做的对照实验 |

### 10.2 代码错误

| # | 错误 | 后果 | 怎么发现的 |
|---|---|---|---|
| 1 | 快照校验器要求 counts <= receipts | **所有提交都失败**，状态永远停在第一次写 | 故障注入测试全部失败 |
| 2 | 回读比对用 Map.equals | Int 读回变 Long，比较永远不等 | 同上 |
| 3 | 滑动窗口测试手算两遍都错 | 测试预期是错的，不是代码 | 跑失败后改为模拟求值 |
| 4 | 补丁打到 ProactiveLedgerBook 而非 InterceptLedgerBook | 编译失败 | 编译 |
| 5 | 构造函数参数插在 ids 之后 | 测试按位置传 lambda 全错位 | 编译 |

### 10.3 测试错误

| # | 错误 | 为什么危险 |
|---|---|---|
| 1 | InterceptRecoveryTest 的 ledgerBook(store) **丢掉了 store** | 它写的东西读不回来，"重启"从未真正读盘 |
| 2 | 同上，重启后**复用同一内存账本** | 结构上不可能测出跨进程问题 |
| 3 | 夹具设 cooldownMs = 0 | **正好掩盖 P0-3** |
| 4 | InterceptSurfaceBudgetTest 两条断言**依赖 bug 存在** | 字面期望对（"不该多扣"），但机制是 P0-3 本身 |

第 4 条值得展开：那两条测试的注释写着 "a busy surface must not be charged for a second
attempt" —— **期望完全正确**，但它实现这个期望的方式是依赖"被拒绝的那次刚武装了冷却"。
所以当我把 P0-3 真正修好，它们反而失败了。

我没有删掉它们，而是改成直接断言结局，并加了**反方向**测试（真展示过的拦截确实要占冷却）。

### 10.4 一条教训

```
测试通过 != 功能正确
测试通过的原因，可能正是 bug 存在的原因
```

这四轮里我三次修正自己的数字、两次推翻自己写进报告的结论。
**每一次都是因为拿实测取代了推算。**

现在包里每个数字后面都挂着能重跑的命令，每个结论后面都有原始输出。
如果哪里对不上，那一定是我的问题。

---

## 附录：一句话回答"现在能不能用"

**不知道。**

能说的是：

- 五个 P0 里四个在内核层修好并有测试保护
- 崩溃一致性做完并做了 11 项故障注入
- 授权语义统一，去掉了一条真实的绕过路径
- 测试从"仓库外、不可复现"变成"仓库内、自动发现"

不能说的是：它在手机上表现如何。**它从来没在手机上跑过。**

## 附录 A · 精确地址索引

> 全部行号在 `3529fd4328fc82acfb706c811f53a93393686ba2` 上用 `Select-String -SimpleMatch`
> 逐条实测得出，不是估的。仓库根 = `D:\code\R4\p4b`（等价于 GitHub 上的仓库根）。
>
> 路径前缀：**K/** = `app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/`
> **T/** = `app/android/app/src/test/kotlin/io/github/ccch1mneyyy/dsh_app/`

### A.1 拦截内核

| 内容 | 精确地址 |
|---|---|
| `InterceptDecision` sealed 接口 | `K/loop/core/Intercept.kt:236` |
| `InterceptRules` 决策函数所在 object | `K/loop/core/Intercept.kt:255` |
| `decide()` 全部放行判定 | `K/loop/core/Intercept.kt:288` |
| ├ disabled → Allow | `K/loop/core/Intercept.kt:298` |
| ├ whitelist → Allow | `K/loop/core/Intercept.kt:299` |
| ├ pause → Allow | `K/loop/core/Intercept.kt:300` |
| ├ released → Allow | `K/loop/core/Intercept.kt:301` |
| ├ authorized window → Allow | `K/loop/core/Intercept.kt:302` |
| └ **dailyMax → Ignore（D5）** | `K/loop/core/Intercept.kt:324` |
| └ **cooldown → Ignore（D5）** | `K/loop/core/Intercept.kt:327` |
| `InterceptGuard` 类声明 | `K/loop/core/Intercept.kt:387` |
| `recover()` 进程恢复 | `K/loop/core/Intercept.kt:426` |
| ├ recover 里 NOT_SHOWN 的退还 | `K/loop/core/Intercept.kt:479` |
| `onForeground()` 主决策入口 | `K/loop/core/Intercept.kt:515` |
| ├ **P0-3 捕获扣费** | `K/loop/core/Intercept.kt:545` |
| `onReleased()` 四扇门 | `K/loop/core/Intercept.kt:599` |
| ├ **P0-5 展示证明闸门** | `K/loop/core/Intercept.kt:617` |
| ├ trainingMs 停留检查 | `K/loop/core/Intercept.kt:624` |
| ├ RELEASE_RULE 窗口校验 | `K/loop/core/Intercept.kt:628` |
| `onExited()` | `K/loop/core/Intercept.kt:651` |
| `onPaused()` | `K/loop/core/Intercept.kt:671` |
| `expireOpen()` P0-1 TTL 结局 | `K/loop/core/Intercept.kt:716` |
| `onUnavailable()` | `K/loop/core/Intercept.kt:723` |
| ├ **P0-3 退还扣费** | `K/loop/core/Intercept.kt:728` |
| `tapDrill()` | `K/loop/core/Intercept.kt:754` |
| `endOpen()` 统一终止出口 | `K/loop/core/Intercept.kt:770` |
| ├ **D5 清冷却（exit/blocked/notshown）** | `K/loop/core/Intercept.kt:795` |
| `persist()` 路由到仓库 | `K/loop/core/Intercept.kt:832` |
| `InterceptDrill.of()` SplitMix64 铸题 | `K/loop/core/Intercept.kt:204` |

### A.2 持久化

| 内容 | 精确地址 |
|---|---|
| `AtomicJsonFile` 原子写 | `K/loop/core/SnapshotStore.kt:41` |
| ├ `write()` 完整协议 | `K/loop/core/SnapshotStore.kt:70` |
| ├ `keepPrevious()` 备份 | `K/loop/core/SnapshotStore.kt:85` |
| ├ `replace()` 原子替换 | `K/loop/core/SnapshotStore.kt:92` |
| └ `syncDirectory()` 目录 fsync | `K/loop/core/SnapshotStore.kt:114` |
| `InterceptRepository` 事务所有者 | `K/loop/core/InterceptRepository.kt:22` |
| ├ `Snapshot` 数据结构 | `K/loop/core/InterceptRepository.kt:27` |
| ├ `load()` | `K/loop/core/InterceptRepository.kt:85` |
| ├ **`commit()` 提交协议** | `K/loop/core/InterceptRepository.kt:115` |
| ├ `validate()` 自洽校验 | `K/loop/core/InterceptRepository.kt:185` |
| └ `SCHEMA` 版本常量 | `K/loop/core/InterceptRepository.kt:204` |
| `InterceptLedgerBook` | `K/loop/core/Ledgers.kt:223` |
| ├ `checkConsistency()` | `K/loop/core/Ledgers.kt:265` |
| └ `appliedIds()` | `K/loop/core/Ledgers.kt:361` |
| `InterceptLedger` 数据结构 | `K/loop/core/Ledgers.kt:189` |
| `InterceptMigration` | `K/loop/core/InterceptMigration.kt:20` |
| ├ `Result` sealed | `K/loop/core/InterceptMigration.kt:23` |
| ├ `RecoveryRequired` | `K/loop/core/InterceptMigration.kt:34` |
| ├ `run()` 迁移入口 | `K/loop/core/InterceptMigration.kt:42` |
| └ **白名单 vs 放行数检查** | `K/loop/core/InterceptMigration.kt:118` |

### A.3 截止与降级策略

| 内容 | 精确地址 |
|---|---|
| `InterceptDeadline` | `K/loop/core/InterceptDeadline.kt:26` |
| ├ 证明窗口 5 秒 | `K/loop/core/InterceptDeadline.kt:29` |
| ├ 页面 TTL 10 分钟 | `K/loop/core/InterceptDeadline.kt:32` |
| ├ **`due()` 纯判定函数** | `K/loop/core/InterceptDeadline.kt:65` |
| ├ `nextDeadline()` 单定时器 | `K/loop/core/InterceptDeadline.kt:83` |
| ├ `Attempts` 每分钟 3 次 | `K/loop/core/InterceptDeadline.kt:96` |
| └ `Backoff` 15 秒退避（**不是放行**） | `K/loop/core/InterceptDeadline.kt:126` |
| `EnforcementOutcome` | `K/loop/core/EnforcementOutcome.kt:18` |
| ├ `afterShowFailure()` | `K/loop/core/EnforcementOutcome.kt:32` |
| └ **`stillInFront()` null = 未离开** | `K/loop/core/EnforcementOutcome.kt:50` |

### A.4 适配层（Android）

| 内容 | 精确地址 |
|---|---|
| `InterceptRuntime` | `K/loop/intercept/InterceptRuntime.kt:39` |
| ├ **`mono()` 单调时钟** | `K/loop/intercept/InterceptRuntime.kt:56` |
| ├ `recheckForeground` 接缝 | `K/loop/intercept/InterceptRuntime.kt:64` |
| ├ `onForeground()` + 退避检查 | `K/loop/intercept/InterceptRuntime.kt:115` |
| ├ `show()` 启动页面 | `K/loop/intercept/InterceptRuntime.kt:147` |
| ├ `armDeadline()` 单定时器 | `K/loop/intercept/InterceptRuntime.kt:194` |
| ├ **`settleIfDue()`** | `K/loop/intercept/InterceptRuntime.kt:210` |
| ├ **`enforceLeave()` D2 降级链** | `K/loop/intercept/InterceptRuntime.kt:253` |
| ├ `goHome` 接缝 | `K/loop/intercept/InterceptRuntime.kt:284` |
| ├ `currentForeground` 接缝 | `K/loop/intercept/InterceptRuntime.kt:289` |
| ├ `enforcementUnavailable` 字段 | `K/loop/intercept/InterceptRuntime.kt:304` |
| ├ `notifyEnforcementUnavailable` | `K/loop/intercept/InterceptRuntime.kt:308` |
| ├ `onPageShown()` 记录证明 | `K/loop/intercept/InterceptRuntime.kt:317` |
| └ `onPageGone()` 清状态 + 重判 | `K/loop/intercept/InterceptRuntime.kt:356` |
| `InterceptPageActivity` | `K/loop/intercept/InterceptPageActivity.kt` |
| ├ `onCreate()` | `K/loop/intercept/InterceptPageActivity.kt:58` |
| ├ `bind()` | `K/loop/intercept/InterceptPageActivity.kt:75` |
| ├ **`proveVisible()` 五条件证明** | `K/loop/intercept/InterceptPageActivity.kt:106` |
| ├ `onStop()` | `K/loop/intercept/InterceptPageActivity.kt:131` |
| ├ `onDestroy()` | `K/loop/intercept/InterceptPageActivity.kt:153` |
| ├ `release()` 尊重守卫裁决 | `K/loop/intercept/InterceptPageActivity.kt:172` |
| ├ `withdraw()` | `K/loop/intercept/InterceptPageActivity.kt:387` |
| └ `goHome()` | `K/loop/intercept/InterceptPageActivity.kt:390` |
| `LoopRuntime` | `K/loop/LoopRuntime.kt:44` |
| ├ `verifyNow()` | `K/loop/LoopRuntime.kt:219` |
| └ **`recheckForeground()`** | `K/loop/LoopRuntime.kt:281` |
| `VisibleSurface` 槽位 | `K/loop/core/SurfaceSlot.kt` |
| ├ `claim()` | `K/loop/core/SurfaceSlot.kt:56` |
| ├ `release()` | `K/loop/core/SurfaceSlot.kt:77` |
| └ `OWNER_INTERCEPT` | `K/loop/core/SurfaceSlot.kt:102` |
| `Engagement` 六态 | `K/loop/core/CoreModel.kt:68` |

### A.5 测试

| 测试 | 精确地址 |
|---|---|
| `InterceptRepositoryCrashTest` 崩溃注入（11 项） | `T/loop/core/InterceptRepositoryCrashTest.kt:20` |
| ├ 临时文件失败 | `T/loop/core/InterceptRepositoryCrashTest.kt:98` |
| ├ 静默丢弃写入 | `T/loop/core/InterceptRepositoryCrashTest.kt:177` |
| └ 白名单写失败 | `T/loop/core/InterceptRepositoryCrashTest.kt:283` |
| `InterceptMigrationTest`（8 项） | `T/loop/core/InterceptMigrationTest.kt:16` |
| └ 白名单无放行来源 | `T/loop/core/InterceptMigrationTest.kt:153` |
| `InterceptAuthorizationSemanticsTest`（10 项） | `T/loop/core/InterceptAuthorizationSemanticsTest.kt:18` |
| ├ EXITED 后必须再拦 | `T/loop/core/InterceptAuthorizationSemanticsTest.kt:55` |
| └ 无 Allow 引用冷却/日上限 | `T/loop/core/InterceptAuthorizationSemanticsTest.kt:155` |
| `InterceptDeadlineTest`（10 项） | `T/loop/core/InterceptDeadlineTest.kt:16` |
| └ 未证明 → NOT_SHOWN | `T/loop/core/InterceptDeadlineTest.kt:23` |
| `InterceptVisibilityGateTest`（6 项） | `T/loop/core/InterceptVisibilityGateTest.kt:25` |
| └ 无证明拒绝训练门 | `T/loop/core/InterceptVisibilityGateTest.kt:58` |
| `EnforcementOutcomeTest`（5 项） | `T/loop/core/EnforcementOutcomeTest.kt:14` |
| └ null 前台算未离开 | `T/loop/core/EnforcementOutcomeTest.kt:40` |

### A.6 工具与文档

| 内容 | 精确地址 |
|---|---|
| 内核测试运行器 | `tooling/run-kernel-tests.sh`（153 行） |
| ├ 自动发现测试类 | `tooling/run-kernel-tests.sh` 的 `find "$TEST/loop" -name '*Test.kt'` |
| └ 排除 LoopHardeningTest | 同上 `! -name 'LoopHardeningTest.kt'` |
| ADR（持久化 + 授权 + D2） | `docs/adr/0001-intercept-persistence-and-authorization.md` |
| 本档案 | `R4-TECHNICAL-ARCHIVE.md` |

### A.7 复制即可用的查看命令

```bash
# 定位仓库
cd /d/code/R4/p4b            # WSL
# 或   cd D:\code\R4\p4b     # PowerShell

# 看某个精确位置（例如 P0-5 的闸门）
sed -n '610,632p' app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/loop/core/Intercept.kt

# 看 commit() 的提交协议
sed -n '115,160p' app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/loop/core/InterceptRepository.kt

# 看 D2 的降级链
sed -n '247,275p' app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/loop/intercept/InterceptRuntime.kt

# 找任意符号
grep -rn "openShownAt" app/android/app/src/main/kotlin/ | head
```

### A.8 一个诚实说明

**这份索引是我核对出来的，不是估的** —— 但正因为如此，我要说明：

上一版档案文档里有 9 处行号是**凭记忆写的、错的**（例如 `onReleased` 我写成 594，实为 599；
`decide()` 的 dailyMax 分支写成 322，实为 324）。已全部更正，并在提交里留了记录。

**行号会随代码变动失效。** 如果发现对不上，请以符号名（函数名 / 常量名）为准搜索，
不要以行号为准。行号只是"这个版本上的快捷方式"。
