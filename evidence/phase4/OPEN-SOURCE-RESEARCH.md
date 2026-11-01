# 开源参考项目研究（源码级，非 README）

> 研究对象：Monk（主要技术参考）、Nudge（生命周期测试参考）。
> 只读源码与测试，**本文件不改任何代码**。采用决定逐条写在这里。

---

## A. Monk — https://github.com/mdportnov/monk

| 项 | 核实结果 |
|---|---|
| 许可证 | **Apache-2.0 / MIT 双许可**（仓库根目录有 `LICENSE-APACHE` 9723 B 与 `LICENSE-MIT` 1072 B，MIT 署名 "Copyright (c) 2026 Mikhail Portnov"）。GitHub API 的 `license.spdx_id` 只报 Apache-2.0，以仓库文件为准 |
| 默认分支 | `master`（**不是** main — 任务书里的链接需要加分支） |
| 实际取到 | `ForegroundGate.kt` 8069 B、`InterceptSession.kt` 5452 B、`InterceptActivity.kt` 6087 B、`RuntimeState.kt` 2749 B、`ForegroundGateTest.kt` 11761 B，**全部 200** |

### A.1 值得借鉴的七个设计（逐条对应我们的 P0）

**① 纯 Kotlin 前台状态机 —— `ForegroundGate`**

不是"事件来了就判"，而是一个带**记忆**的状态机，字段只有三个：
```kotlin
private var lastForeground: String?   // 真的是"上一个前台 App"
private var lastLaunchAt = 0L         // 防回声
private var pending: String?          // 锁屏/通话中暂挂，解锁后补判
```
	oonWindow(pkg, className)` 的过滤顺序值得抄：
1. 自己包的 UI 在前 → 只更新 `lastForeground`，**不判**
2. Launcher → 重置 `lastForeground`，取消定时器
3. **transient**（下拉 shade、keyguard、输入法、权限弹窗、拨号）→ **直接 return，不算进入也不算离开**
4. **不是 Activity 窗口**（dialog/popup/PiP/bubble 同事件类型）→ return
5. 同一 App 且没有拦截页在盖它 → 不重复判
6. 锁屏 / 通话中 → 记 `pending`，解锁后补判

**→ 直接对上我们的 P0-2（切回不重判）**：我们缺的正是"离开再回来要重判"这条。

**② 会话与 Activity 解耦 —— `InterceptSession` + `InterceptRegistry`**

```
InterceptRegistry  按 token 持有活的 session（HashMap<Long, InterceptSession>）
InterceptSession   持有 decided 标志、UI 状态、open()/dismiss()/abandon()
InterceptActivity  只做渲染 + 转发，onCreate 找不到 session 就立刻 finish
```
注释原文点明原因：
> "Holding sessions here (not in the Activity) means a **configuration change or a slow cold start
> never spawns a second countdown or a second 'intercepted'.**"

**→ 直接对上我们的 P0-1（永久悬挂）**：我们把状态放在 Activity 里，Activity 不来 = 永不结算。
Monk 把状态放在 registry 里，Activity 只是视图，视图死了不影响状态。

**③ token 守卫 —— `InterceptGate`**

```kotlin
fun closed(token: Long) { if (token != this.token) return; ... }   // ← 旧实例清不掉新实例的 state
fun owns(token: Long) = token == this.token
```

**→ 对上我们的 P2-4 / 上一轮的同 owner 换 token 问题**。Monk 用 token 比对，不靠"谁最后销毁"。

**④ Activity 未恢复的超时检测 —— `isCreated/isResumed` + 启动 miss 计数**

```kotlin
val preferOverlay: Boolean get() = prefs.getInt(KEY_LAUNCH_MISSES, 0) >= 2
fun noteLaunchMiss() / noteLaunchOk()
```
**连续两次启动失败后改用 overlay**。注释：
> "Some ROMs drop the pause-screen Activity launch from a service; every miss costs the guard
> delay with the app visible."

**→ 对上我们的 P0-1 第 a 条（startActivity 返回 true 但 Activity 从未创建）**。
我们完全没有这个计数，所以永远不知道"启动了但没起来"。

**⑤ Accessibility Overlay 备用显示 —— `InterceptOverlay.kt`**

`hideOverlay()` 在"另一个 App 或 Launcher 浮上来"时调用；`interceptInFront()` 判断 overlay 是否真在前。
**→ 这是我们没有的能力，但它是 P0-1 的根治手段之一。本轮先不引入 overlay（工作量大），
用 ④ 的 miss 计数 + ④' 的"启动失败即 NOT_SHOWN"覆盖同类风险。**

**⑥ 失败后回桌面 —— `nav.goHome()`**

`dismiss()` 里 `nav.goHome()`。**→ 对上 D1（TTL 到期回桌面）。**

**⑦ 三个重判触发点 —— 这是 P0-2 的完整答案**

```kotlin
fun onUserPresent()      = reevaluateForeground()   // 解锁
fun onClockChanged()     { cancelScheduled(); reevaluateForeground() }  // 改时间
fun reevaluateForeground() {
    val pkg = lastForeground ?: return
    if (!effects.isWatched(pkg)) return
    if (effects.isKeyguardLocked()) { pending = pkg; return }
    ...
}
```
外加 `evaluate()` 里 **放行到期时主动排定时器**：
```kotlin
val allowance = effects.allowanceUntil(pkg)?.let { it - clock() }?.takeIf { it > 0 }
val delay = listOfNotNull(allowance, boundary).minOrNull() ?: return
effects.schedule(delay + 250) { if (lastForeground == pkg) reevaluateForeground() }
```
注释（值得整段引用）：
> "the expiry timer runs on **uptime, which stops while the device sleeps**, so an allowance that
> ran out under a locked screen would otherwise outlive itself by however long the phone dozed."

**→ 这解释了我们 D2/P2-2 的时钟问题：用 `SystemClock.elapsedRealtime()`（uptime），不是 wall clock。**

### A.2 Monk 的测试方法（`ForegroundGateTest`，28 个用例）

用 `Fake : ForegroundGate.Effects` 把所有副作用（launcher 判定、锁屏、通话、调度、显示/隐藏）
做成可断言的记录器，**不用 Robolectric、不用 Android**，纯 JVM。

28 个用例逐个列在下面（这些就是我们该补的测试清单）：
```
interceptsOnEnteringWatchedActivity            ignoresDialogsBubblesAndTransientWindows
sameAppEventsDoNotRetriggerButLauncherResets  monkMainScreenResetsForegroundButInterceptScreenDoesNot
keyguardDefersUntilUnlock                     keyguardDeferralRecoversWithoutUserPresent
allowanceSchedulesReevaluationAtExpiry        ruleBoundaryIsScheduledEvenWithoutAllowance
clockChangeDropsTheTimerAndRejudgesTheForegroundApp
leavingForAnotherAppCancelsTheExpiryTimer     coldStartWindowsUnderALiveInterceptAreNotCountedAgain
resurfacingAboveLiveInterceptRecoversExceptForEcho
overlayHidesWhenAnotherActivityOrLauncherSurfaces
unlockRejudgesAnExpiredAllowanceEvenWithoutPendingApp
unlockWithLiveAllowanceReschedulesFromTheWallClock
unlockOnLauncherDoesNothing                   foregroundChangesAreHandedToTheHost
restoredForegroundIsJudgedOnReevaluate        restoreNeverOverridesALiveObservation
reevaluateUnderKeyguardWaitsForUnlock         unlockOverALivePauseScreenNeitherCountsAgainNorRestartsIt
anAppOpenedDuringACallIsJudgedOnItsNextWindowAfterIt
anAllowanceRunningOutUnderTheKeyguardWaitsForTheUnlock
```

### A.3 采用决定

| Monk 的什么 | 本轮的用法 | 许可处理 |
|---|---|---|
| `ForegroundGate` 的**状态机设计思想**（lastForeground / pending / lastLaunchAt / reevaluate 触发点） | **适配**：在我们 `LoopRuntime` 里加同构的前台判定层，不复制文件 | 思想不构成复制 |
| `InterceptRegistry` 的**会话与视图解耦** | **适配**：把拦截状态从 Activity 提到 `InterceptRuntime` | 同上 |
| `InterceptGate` 的 **token 守卫** | 我们已有 `VisibleSurface` token，补齐 `closed(token)` 语义 | 同上 |
| `noteLaunchMiss / preferOverlay` 的**失败计数** | **适配**：记 miss，连续 N 次转 NOT_SHOWN + 退避 | 同上 |
| 具体代码文件 | **不复制**。如后续确需逐段移植，将保留 Apache-2.0 头、写入 `THIRD_PARTY_NOTICES.md`、记录上游 commit 与修改说明 | — |

**本轮结论：只借鉴设计，不复制代码。因此暂不需要动 `THIRD_PARTY_NOTICES.md`；
若后续改为移植，必须先补许可声明再提交。**

---

## B. Nudge — https://github.com/astraedus/nudge

| 项 | 核实结果 |
|---|---|
| 许可证 | **GPL-3.0**（GitHub API） |
| 实际取到 | `OverlayLifecycle.kt` 23280 B、`BlockLaunchGuard.kt` 15975 B、`OverlayLifecycleGuardTest.kt` 33266 B、`BlockLaunchGuardReplayTest.kt` 44490 B，**全部 200**；GPL-3.0 全文已存证 35149 B |
| 上游 commit（备将来引用） | Monk `9d5a43c40390bfd5c3352af183dd067b94b5ba09` · Nudge `83e5baa096434f7d3c78235d45087c19c67e32f1` |

### B.1 许可证结论（重要）

**GPL-3.0 与本项目（Apache-2.0/MIT 混合）不兼容。**
任务书也明确写了"本轮不直接复制其代码或测试文件，只将其真实问题转化为我们自己的测试"。
**我严格遵守：Nudge 的代码行一行都不进我们的仓库。**

### B.2 它暴露的"真实问题"（转成我们自己的测试）

| Nudge 的文件 | 它解决的问题 | 我们要写的自有测试 |
|---|---|---|
| `OverlayLifecycle` / `...GuardTest` | overlay 与 Activity 谁在前、谁先放弃 | `InterceptVisibilityProofTest`：证明失败→NOT_SHOWN |
| `OverlayLifecycleFullscreenRelaunchTest` | 全屏重建后重新拉起 | `InterceptRecreateTest`：配置变化重建不重复计数 |
| `BlockLaunchGuard` / `...ReplayTest` | 同一次拦截被重复拉起（replay） | `InterceptLaunchReplayTest`：重复 start 只有一次计数 |
| `DuplicateBlockLaunchReplayTest` | 重复启动去重 | 同上 |
| `CooldownGateTest` | 冷却判定 | `InterceptCooldownTest`：D5 的五结局规则表 |
| `EmergencyPass`（截断） | 紧急放行 | `InterceptEmergencyExitTest`：EXITED 不给放行、不进冷却 |

**这些测试是我们自己写，只借鉴"该测什么"，不借鉴"怎么写的代码"。**

### B.3 洁净室证据（可复核）

```
grep -ril 于 p4 全仓（*.kt/*.kts/*.java/*.dart）：
  astraedus        0 files
  OverlayLifecycle 0 files
  BlockLaunchGuard 0 files
  CooldownGate     0 files
  EmergencyPass    0 files
  mdportnov        0 files
  ForegroundGate   0 files
  InterceptRegistry 0 files
  InterceptGate    0 files
  preferOverlay    0 files
```

唯一出现 "nudge" 的 7 个文件是**英文单词的普通用法**，例如
`app/lib/ui/common/overview_card.dart:295  static const nudge = 3.0;`（布局微调量），
与 Nudge 项目无关。**本项目一行 GPL 代码都没有。**

---

## C. 与架构审查报告的关系

审查报告的 P0-1/P0-2 与 Monk 的两个设计（会话解耦、前台重判）**指向同一个根因**，
这是两个独立来源得出同一结论 —— 提高了我对这两个缺陷真实性的把握。

但**报告没有提 Monk**，也没提"启动 miss 计数"和"uptime 时钟"这两个具体手段，这两条是我从源码读出来的补充。
