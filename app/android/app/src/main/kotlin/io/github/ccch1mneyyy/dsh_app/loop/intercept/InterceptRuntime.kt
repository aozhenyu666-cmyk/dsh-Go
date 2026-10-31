package io.github.ccch1mneyyy.dsh_app.loop.intercept

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.github.ccch1mneyyy.dsh_app.loop.LoopRuntime
import io.github.ccch1mneyyy.dsh_app.loop.core.AtomicJsonFile
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptConfig
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptDecision
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptEnv
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptGuard
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptLedger
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptLedgerBook
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptReceipt
import io.github.ccch1mneyyy.dsh_app.loop.core.Switches
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
    private const val PAGE_TTL_MS = 10 * 60_000L

    fun ensure(context: Context): InterceptGuard {
        guard?.let { return it }
        app = context.applicationContext
        val dir = File(File(app.filesDir, "loop"), "intercept")
        val book = InterceptLedgerBook(AtomicJsonFile(File(dir, "ledger.json")))
        book.recover()
        val g = InterceptGuard(
            AtomicJsonFile(File(dir, "guard.json")), book,
            clock = System::currentTimeMillis, ids = { UUID.randomUUID().toString() },
        )
        g.recover(System.currentTimeMillis())
        ledger = book
        guard = g
        Log.i(TAG, "ready: targets=" + g.config.targets.size + " enabled=" + g.config.enabled)
        return g
    }

    /** The three ways a page can grant passage, re-exported so the page imports one class only. */
    val RELEASE_TRAINING = InterceptGuard.RELEASE_TRAINING
    val RELEASE_RULE = InterceptGuard.RELEASE_RULE
    val RELEASE_WHITELIST = InterceptGuard.RELEASE_WHITELIST

    fun guardOrNull(): InterceptGuard? = guard
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
        val now = System.currentTimeMillis()
        when (val d = g.onForeground(packageName, env(now), now)) {
            is InterceptDecision.Block -> show(d, now)
            is InterceptDecision.Allow -> Log.d(TAG, "allow " + packageName + ": " + d.reason)
            InterceptDecision.Ignore -> Unit
        }
    }

    private fun show(block: InterceptDecision.Block, now: Long) {
        val ok = InterceptPageActivity.start(
            app, block.eventId, block.target.packageName, block.target.label,
            config().trainingMs, now + PAGE_TTL_MS,
        )
        if (!ok) {
            // The system refused the page: the interception did not happen, so nothing is owed.
            guard?.onUnavailable(block.eventId, "start_failed", System.currentTimeMillis())
            Log.w(TAG, "could not show the block page for " + block.target.packageName)
        }
    }

    /** The page proved it is really on screen (attached + shown + laid out + focused). */
    fun onPageShown(eventId: String): Boolean = guard?.onPageShown(eventId, System.currentTimeMillis()) == true

    /** 训练通过 / 授权规则 / 白名单. True when the guard accepted it. */
    fun onReleased(eventId: String, how: String): Boolean =
        guard?.onReleased(eventId, how, System.currentTimeMillis()) == true

    fun onExited(eventId: String): Boolean = guard?.onExited(eventId, System.currentTimeMillis()) == true

    fun onPaused(eventId: String?): Boolean =
        guard?.onPaused(eventId, InterceptGuard.DEFAULT_PAUSE_MS, System.currentTimeMillis()) == true

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
