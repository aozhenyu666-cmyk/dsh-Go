package io.github.ccch1mneyyy.dsh_app.loop.intercept

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.github.ccch1mneyyy.dsh_app.loop.LoopRuntime
import io.github.ccch1mneyyy.dsh_app.loop.core.AtomicJsonFile
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptConfig
import io.github.ccch1mneyyy.dsh_app.loop.core.EnforcementOutcome
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptDeadline
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptKernel
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptMigration
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptDecision
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptDrill
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptEnv
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptGuard
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptLedger
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptLedgerBook
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptReceipt
import io.github.ccch1mneyyy.dsh_app.loop.core.Switches
import io.github.ccch1mneyyy.dsh_app.loop.core.VisibleSurface
import io.github.ccch1mneyyy.dsh_app.phone.PhoneControl
import java.io.File
import java.util.Calendar
import java.util.TimeZone
import java.util.UUID

/**
 * Android adapter for 娱乐 APP 拦截 (loop/core/Intercept.kt). Owns one [InterceptGuard] and one
 * 行为拦截账 [InterceptLedgerBook] per process, decides from the verified foreground package that
 * [LoopRuntime] reads back from the window list, and shows exactly one blocking page.
 *
 * It has **no scheduler, no alarm and no timer of its own**: an interception is decided when the
 * person opens a target app, which is precisely when the accessibility service already reports a
 * window change. The proactive runtime is deliberately not involved — the two features have
 * separate books and neither can pause the other.
 *
 * Main thread only (accessibility events and pages both live there).
 */
object InterceptRuntime {
    private const val TAG = "DshIntercept"
    private val main = Handler(Looper.getMainLooper())
    private lateinit var app: Context
    private var guard: InterceptGuard? = null
    private var ledger: InterceptLedgerBook? = null

    /** The page must not stay up forever; the kernel keeps the receipt either way. */
    private const val PAGE_TTL_MS = InterceptDeadline.DEFAULT_PAGE_TTL_MS

    /** 回 HOME 之后给系统一点时间把前台切过去，再读一次。 */
    private const val HOME_RETRY_MS = 600L

    /**
     * The clock every deadline uses: **monotonic**, so a manual time change or a DST move cannot
     * skip the proof window or stall the TTL. Wall time is only for receipts.
     */
    private fun mono(): Long = android.os.SystemClock.elapsedRealtime()

    /**
     * 拦截结束后让前台被重新判定（P0-2）。
     *
     * 做成一个可替换的函数而不是直接调 LoopRuntime：一是这个从属关系只应该是单向的（无障碍宿主 →
     * 拦截特性），二是纯逻辑测试与编译检查都不必把整个 Android 宿主拖进来。
     */
    var recheckForeground: (String) -> Unit = { reason ->
        runCatching { LoopRuntime.recheckForeground(reason) }
    }
    /** When the current interception asked for its page, monotonic. 0 when none is open. */
    private var requestedAtMono = 0L
    /** When the page was proved on screen, monotonic. 0 until the proof lands. */
    private var shownAtMono = 0L
    /** The one timer that decides when this interception ends, whoever is (not) watching. */
    private val deadlineTick = Runnable { settleIfDue() }
    private val attempts = InterceptDeadline.Attempts()
    private val backoff = InterceptDeadline.Backoff()

    fun ensure(context: Context): InterceptGuard {
        guard?.let { return it }
        app = context.applicationContext
        val dir = File(File(app.filesDir, "loop"), "intercept")
        // W1: 生产初始化走 InterceptKernel —— 一份原子快照，外加旧数据迁移。
        // 之前这里 new 两个 AtomicJsonFile，所以 InterceptRepository 与 InterceptMigration 虽然
        // 写好了、测过了，却从来没有在生产里执行过一次。
        val opened = InterceptKernel.open(
            dir,
            clock = System::currentTimeMillis,
            ids = { UUID.randomUUID().toString() },
        )
        migrationResult = opened.migration
        snapshotActive = opened.repo != null
        opened.recoveryIssue?.let {
            Log.w(TAG, "legacy intercept state needs attention: " + it)
        }
        ledger = opened.ledger
        guard = opened.guard
        Log.i(
            TAG,
            "ready: targets=" + opened.guard.config.targets.size +
                " enabled=" + opened.guard.config.enabled +
                " snapshot=" + snapshotActive +
                " migration=" + opened.migration.javaClass.simpleName,
        )
        return opened.guard
    }

    /** The three ways a page can grant passage, re-exported so the page imports one class only. */
    val RELEASE_TRAINING = InterceptGuard.RELEASE_TRAINING
    val RELEASE_RULE = InterceptGuard.RELEASE_RULE
    val RELEASE_WHITELIST = InterceptGuard.RELEASE_WHITELIST

    fun guardOrNull(): InterceptGuard? = guard

    /** W1: the ledger’s own write error, which the guard’s `storageError` does not cover. */
    fun ledgerBookStorageError(): String? = ledger?.storageError

    /** W1: migration outcome, surfaced in the status map. */
    @Volatile var migrationResult: InterceptMigration.Result? = null
        private set

    /** W1: true when the atomic snapshot is the storage in use (false after a legacy fallback). */
    @Volatile var snapshotActive: Boolean = false
        private set
    fun ledger(): InterceptLedger = ledger?.state ?: InterceptLedger()
    fun config(): InterceptConfig = guard?.config ?: InterceptConfig()
    fun releaseMs(): Long = config().releaseMs

    fun setConfig(context: Context, next: InterceptConfig) {
        ensure(context).setConfig(next, System.currentTimeMillis())
        LoopRuntime.configChanged()
    }

    /** Whether the feature is on at all; part of [Switches] so the two features share one arbitration. */
    fun enabled(): Boolean = guard?.config?.enabled == true

    /**
     * One verified foreground reading, called from [LoopRuntime] right after the window list was
     * read back. Null / blank means "unreadable": nothing is decided and nothing is recorded.
     */
    fun onForeground(packageName: String?) {
        val g = guard ?: return
        if (packageName.isNullOrBlank()) return
        if (!enabled()) return
        // One visible DSH surface at a time. Checked *before* asking the guard, because a Block
        // decision immediately spends the cooldown and the daily count ([InterceptGuard.onForeground]
        // stamps lastTriggerAt and increments countToday). Refusing afterwards would charge the
        // person for an interception that never reached the screen, and the next attempt would be
        // swallowed by the cooldown. So: while someone else holds the screen, decide nothing at all.
        if (!VisibleSurface.isFree() && !VisibleSurface.isHeldBy(VisibleSurface.OWNER_INTERCEPT)) {
            Log.i(TAG, "surface busy (" + VisibleSurface.holder() + "); no decision for " + packageName)
            return
        }
        // A page that could not be shown for this package: do not ask again for a moment. This is
        // a HOLD-OFF, not a release - the app stays exactly as it was, and the guard is not asked,
        // so nothing is charged. Turning this into a release is what D2 forbids.
        if (backoff.isHoldingOff(packageName, mono())) {
            // 第四阶段 4B · D2: this used to `return` and that was an invisible pass-through. The app
            // is still in front and still usable; "we are holding off on showing the page" is a
            // statement about us, not a permission for them. So do what we can: leave the app.
            Log.i(TAG, "holding off " + packageName + "; enforcing the exit instead")
            enforceLeave(packageName, "holdoff")
            return
        }
        val now = System.currentTimeMillis()
        when (val d = g.onForeground(packageName, env(now), now)) {
            is InterceptDecision.Block -> show(d, now)
            is InterceptDecision.Allow -> Log.d(TAG, "allow " + packageName + ": " + d.reason)
            InterceptDecision.Ignore -> Unit
        }
    }

    private fun show(block: InterceptDecision.Block, now: Long) {
        // D2: a package that cannot get a page up must not be retried forever. Three a minute,
        // then a reported fault - the target app is left alone rather than covered in a page that
        // keeps failing to appear.
        if (!attempts.record(block.target.packageName, mono())) {
            Log.w(TAG, "giving up on " + block.target.packageName + ": too many failed attempts this minute")
            guard?.onUnavailable(block.eventId, "attempt_budget", now)
            backoff.note(block.target.packageName, mono())
            return
        }
        // Race guard: onForeground already refused to decide while another feature held the screen,
        // so reaching here with the slot taken means the proactive page claimed it in between. The
        // decision has been made by then, so the honest record is NOT_SHOWN rather than pretending
        // the block happened.
        if (!VisibleSurface.claim(VisibleSurface.OWNER_INTERCEPT, block.eventId)) {
            guard?.onUnavailable(block.eventId, "surface_busy", System.currentTimeMillis())
            Log.i(TAG, "surface busy (" + VisibleSurface.holder() + "); " + block.target.packageName + " passes this time")
            return
        }
        requestedAtMono = mono()
        shownAtMono = 0L
        val ok = InterceptPageActivity.start(
            app, block.eventId, block.target.packageName, block.target.label,
            config().trainingMs, now + PAGE_TTL_MS,
        )
        if (!ok) {
            VisibleSurface.release(VisibleSurface.OWNER_INTERCEPT, block.eventId)
            // The system refused the page: the interception did not happen, so nothing is owed.
            guard?.onUnavailable(block.eventId, "start_failed", System.currentTimeMillis())
            backoff.note(block.target.packageName, mono())
            Log.w(TAG, "could not show the block page for " + block.target.packageName)
            requestedAtMono = 0L
            // D2: the launch was refused, so the app is still in front and usable. Going quiet here
            // is exactly the invisible pass-through this fixes.
            enforceLeave(block.target.packageName, "start_failed")
            return
        }
        // `start()` returning true only means the system accepted the intent. Whether an Activity
        // ever appears is a different question, and it is the one that used to hang the feature.
        // Arm the timer here so it is answered either way, with the page present or not.
        armDeadline()
    }

    /**
     * One timer decides when this interception ends, so no ending depends on the page reporting it.
     * Re-armed after every proof or state change; see [settleIfDue].
     */
    private fun armDeadline() {
        main.removeCallbacks(deadlineTick)
        val open = if (requestedAtMono == 0L) null else InterceptDeadline.Open(requestedAtMono, shownAtMono)
        val next = InterceptDeadline.nextDeadline(open) ?: return
        val delay = (next - mono()).coerceAtLeast(0L)
        main.postDelayed(deadlineTick, delay)
    }

    /**
     * The ending the page cannot report: no proof in time, or proved and left up too long.
     *
     * D1 (expired) ends the event as BLOCKED(page_ttl). It grants nothing, so the target app is
     * intercepted again on the very next foreground reading. D2 (not shown) refunds the charge and
     * starts the retry backoff. Both take the page down and re-check what is in front, because the
     * person is somewhere and the guard has just learned something about it.
     */
    fun settleIfDue() {
        val g = guard ?: return
        val open = if (requestedAtMono == 0L) null else InterceptDeadline.Open(requestedAtMono, shownAtMono)
        when (InterceptDeadline.due(open, mono())) {
            InterceptDeadline.Due.Nothing -> Unit
            InterceptDeadline.Due.NotShown -> {
                val id = g.openEventId() ?: run { clearDeadlineState(); return }
                val pkg = g.openPackage()
                Log.w(TAG, "no visibility proof for " + pkg + "; settling as NOT_SHOWN")
                g.onUnavailable(id, "no_visibility_proof", System.currentTimeMillis())
                if (pkg != null) backoff.note(pkg, mono())
                InterceptPageActivity.withdraw(id)
                clearDeadlineState()
                VisibleSurface.release(VisibleSurface.OWNER_INTERCEPT, id)
                // D2: nothing was shown, so the app is still in front. Try to leave it; the chain
                // reports honestly if it cannot.
                pkg?.let { enforceLeave(it, "no_visibility_proof") } ?: recheckForeground("intercept_not_shown")
            }
            InterceptDeadline.Due.Expired -> {
                val id = g.openEventId() ?: run { clearDeadlineState(); return }
                val pkg = g.openPackage()
                Log.i(TAG, "page_ttl reached for " + pkg + "; settling as BLOCKED")
                g.expireOpen(id, System.currentTimeMillis())
                InterceptPageActivity.withdraw(id)
                clearDeadlineState()
                VisibleSurface.release(VisibleSurface.OWNER_INTERCEPT, id)
                // D1: back to the home screen, then judge whatever is in front again.
                runCatching { InterceptPageActivity.goHome(app) }
                recheckForeground("intercept_page_ttl")
            }
        }
    }

    /**
     * 第四阶段 4B · D2: 页面没能显示时，把"这条链"走完 —— 而不是直接 return。
     *
     *   回 HOME → 重新读前台 → 目标 APP 还在就再试一次 → 还在就如实报 ENFORCEMENT_UNAVAILABLE
     *
     * 关键约束：
     *   * 全程**不**写 releases、**不**记 BLOCKED、**不**产生任何授权回执；
     *   * 读不到前台算"未确认离开"，不算成功；
     *   * 最后的失败必须让用户看得见，而不是安静地放过去。
     */
    private fun enforceLeave(packageName: String, code: String) {
        if (!goHome()) {
            reportEnforcementUnavailable(packageName, code, 0)
            return
        }
        main.postDelayed({
            // One re-read, then one retry. Two attempts is enough to tell "the ROM ignored us" from
            // "the app was slow to leave"; more than that just fights the system.
            val after = currentForeground()
            if (!EnforcementOutcome.stillInFront(after, packageName)) {
                Log.i(TAG, "left " + packageName + " after " + code)
                // The app really did leave; ask the guard to judge whatever is in front now.
                recheckForeground("intercept_enforced_exit")
                return@postDelayed
            }
            if (!goHome()) {
                reportEnforcementUnavailable(packageName, code, 1)
                return@postDelayed
            }
            main.postDelayed({
                val second = currentForeground()
                if (EnforcementOutcome.stillInFront(second, packageName)) {
                    reportEnforcementUnavailable(
                        packageName, code, 2,
                        EnforcementOutcome.failureKind(second, packageName),
                    )
                } else {
                    recheckForeground("intercept_enforced_exit")
                }
            }, HOME_RETRY_MS)
        }, HOME_RETRY_MS)
    }

    /** 回 HOME 的动作。做成接缝，测试与编译检查不必依赖真实的 Activity 栈。 */
    var goHome: () -> Boolean = {
        runCatching { InterceptPageActivity.goHome(app); true }.getOrDefault(false)
    }

    /** 读当前前台包名。读不到返回 null —— 由 EnforcementOutcome 决定这算不算离开。 */
    var currentForeground: () -> String? = { LoopRuntime.readForegroundNow() }

    /**
     * 如实报告"这次没拦住"。**不记 BLOCKED、不写放行**：技术失败不等于拦截成功。
     */
    private fun reportEnforcementUnavailable(
        packageName: String,
        code: String,
        attempts: Int,
        kind: String = EnforcementOutcome.REASON_UNREADABLE,
    ) {
        val why = EnforcementOutcome.unavailableReason(code, attempts, kind)
        Log.w(TAG, "ENFORCEMENT_UNAVAILABLE " + packageName + ": " + why)
        enforcementUnavailable = why
        // Surface it: the person must know the block did not happen. This is a notification, not a
        // receipt - nothing in the ledger claims a successful interception.
        runCatching { notifyEnforcementUnavailable(why) }
    }

    /** Worst recent enforcement failure, surfaced in the settings screen. Null when all is well. */
    @Volatile var enforcementUnavailable: String? = null
        private set

    /** 用户可见的提醒。接缝，便于测试与不同 UI 形态。 */
    var notifyEnforcementUnavailable: (String) -> Unit = { why ->
        EnforcementAlert.notify(app, why)
    }

    private fun clearDeadlineState() {
        requestedAtMono = 0L
        shownAtMono = 0L
        main.removeCallbacks(deadlineTick)
    }

    /** The page proved it is really on screen (attached + shown + laid out + focused). */
    fun onPageShown(eventId: String): Boolean {
        val ok = guard?.onPageShown(eventId, System.currentTimeMillis()) == true
        if (ok) {
            // The proof moves the deadline from "show me something" to "how long may it stay".
            shownAtMono = mono()
            armDeadline()
        }
        return ok
    }

    /**
     * The 训练题 this interception must show, or null when nothing is open.
     *
     * Minted by the guard from the eventId, so the page can only render it: it cannot invent,
     * reroll or shorten it. Rendering it is the page's job; judging it is the guard's.
     */
    fun drill(eventId: String): InterceptDrill? =
        guard?.drill()?.takeIf { guard?.openEventId() == eventId }

    /**
     * One press of the 训练题. False when this page names an interception that is not the open one,
     * so a stale page cannot drill its way into a pass for somebody else's interception.
     */
    fun tapDrill(eventId: String, value: Int): Boolean =
        guard?.tapDrill(eventId, value) == true

    /**
     * The page is gone, whichever way it ended (released, exited, paused, timed out, destroyed).
     * Freeing the shared slot here - not in the guard - keeps "who owns the screen" a property of
     * the adapter rather than of the intercept book.
     */
    /**
     * The page could not be shown (the system refused the start, or it was stopped before the
     * visibility proof). Recorded as NOT_SHOWN: the interception did not happen, so nothing is owed
     * to the block ledger and no cooldown is charged against a block that never existed.
     */
    fun onUnavailable(eventId: String, code: String): Boolean =
        guard?.onUnavailable(eventId, code, System.currentTimeMillis()) == true

    fun onPageGone(eventId: String?) {
        VisibleSurface.release(VisibleSurface.OWNER_INTERCEPT, eventId)
        // Whatever took the page away, this interception is over: no deadline may fire for it later.
        clearDeadlineState()
        // The page is gone but nothing may have decided what the person is looking at now. Ask the
        // host to read the foreground again: this is the case P0-2 is about - the page disappearing
        // used to leave the target app usable until some later window event happened to arrive.
        recheckForeground("intercept_page_gone")
    }

    /** 训练通过 / 授权规则 / 白名单. True when the guard accepted it. */
    fun onReleased(eventId: String, how: String): Boolean {
        val ok = guard?.onReleased(eventId, how, System.currentTimeMillis()) == true
        if (ok) {
            clearDeadlineState()
            // A release ends the interception too; the app is about to be put back in front, and the
            // guard must judge it under the new state (a whitelist entry, a release window) rather
            // than under the one it was left in.
            recheckForeground("intercept_released")
        }
        return ok
    }

    /**
     * 紧急退出。
     *
     * D5 的关键一条：退出**不获得放行许可**。守卫不给 releases，所以退出后立刻重开目标 APP 会被重新拦。
     * 另外这里必须重新判定前台（P0-2）—— 用户是按"退出"离开的，前台已经不是拦截页了，不重判就等于
     * 把"退出"当成了一条绕过路径。
     */
    fun onExited(eventId: String): Boolean {
        val ok = guard?.onExited(eventId, System.currentTimeMillis()) == true
        if (ok) {
            clearDeadlineState()
            recheckForeground("intercept_exited")
        }
        return ok
    }

    fun onPaused(eventId: String?): Boolean {
        val ok = guard?.onPaused(eventId, InterceptGuard.DEFAULT_PAUSE_MS, System.currentTimeMillis()) == true
        if (ok && eventId != null) {
            clearDeadlineState()
            recheckForeground("intercept_paused")
        }
        return ok
    }

    /** Put a released app back in front, so 放行 actually means "you may go". */
    fun openTarget(context: Context, packageName: String) {
        runCatching {
            val launch = context.packageManager.getLaunchIntentForPackage(packageName) ?: return
            context.startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }.onFailure { Log.w(TAG, "open " + packageName, it) }
    }

    fun receipts(limit: Int = 50): List<InterceptReceipt> = guard?.receipts(limit) ?: emptyList()

    /** Facts read just before deciding, the same shape the proactive Gate has. */
    private fun env(now: Long): InterceptEnv {
        val core = PhoneControl.peek()
        val power = app.getSystemService(android.os.PowerManager::class.java)
        val keyguard = app.getSystemService(android.app.KeyguardManager::class.java)
        return InterceptEnv(
            screenOn = power?.isInteractive != false,
            unlocked = keyguard?.isKeyguardLocked != true,
            dshBusy = core != null && (core.tasks.isActive || core.tasks.callsInFlight > 0 || core.prompts.busy()),
            minuteOfDay = minuteOfDay(now),
            dayKey = dayOf(now),
        )
    }

    private fun minuteOfDay(wall: Long): Int = Calendar.getInstance(TimeZone.getDefault()).run {
        timeInMillis = wall; get(Calendar.HOUR_OF_DAY) * 60 + get(Calendar.MINUTE)
    }

    private fun dayOf(wall: Long): Long = Calendar.getInstance(TimeZone.getDefault()).run {
        timeInMillis = wall; get(Calendar.YEAR) * 1000L + get(Calendar.DAY_OF_YEAR)
    }
}
