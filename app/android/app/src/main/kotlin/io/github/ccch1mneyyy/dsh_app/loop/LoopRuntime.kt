package io.github.ccch1mneyyy.dsh_app.loop

import android.accessibilityservice.AccessibilityService
import android.app.KeyguardManager
import android.content.Context
import android.graphics.Point
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityWindowInfo
import android.view.inputmethod.InputMethodManager
import io.github.ccch1mneyyy.dsh_app.phone.PhoneControl
import io.github.ccch1mneyyy.dsh_app.loop.proactive.ProactiveRuntime
import io.github.ccch1mneyyy.dsh_app.phone.a11y.Box
import io.github.ccch1mneyyy.dsh_app.phone.a11y.ProtectedPages
import io.github.ccch1mneyyy.dsh_app.phone.a11y.TreeCapture
import java.io.File
import java.lang.ref.WeakReference
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * EventObserver, Android half, and the process-wide owner of the loop.
 *
 * [PhoneA11yService] forwards window events here. They are only hints: after a short quiet gap
 * the real foreground is read back from the window list (package name only — never page
 * content), and only that reading reaches [LoopEngine]. Everything runs on the main thread,
 * where accessibility events arrive.
 *
 * Every failure on this path is counted by [diagnostics] instead of being swallowed by
 * `runCatching` + `Log.w`: a phone where the window list always throws, or where every verification
 * fails, used to look exactly like a phone with the loop switched off. [LoopPlugin] exposes the
 * counters and the last few faults to the settings page.
 */
object LoopRuntime {
    private const val TAG = "DshLoop"
    /** Quiet gap before reading the foreground: one app switch fires several window events. */
    private const val SETTLE_MS = 350L

    private val main = Handler(Looper.getMainLooper())
    @Volatile private var engine: LoopEngine? = null
    private var service: WeakReference<AccessibilityService>? = null
    private val verify = Runnable { verifyNow() }

    /** Failure counters and the last few faults, for the settings page. */
    val diagnostics = LoopDiagnostics()

    /** The local AgentBridge (v0). Null until the loop first runs, i.e. no agent turn is wired. */
    @Volatile private var localBridge: AgentBridge? = null

    fun bridge(): AgentBridge? = localBridge

    /** Counters for the settings page; reset with the process. */
    @Volatile var eventsSeen = 0L
        private set
    @Volatile var readings = 0L
        private set
    @Volatile var lastForeground: String? = null
        private set

    /** One engine per process. The first call recovers what the last process left open. */
    fun engine(context: Context): LoopEngine = engine ?: synchronized(this) {
        engine ?: run {
            val app = context.applicationContext
            val imm = app.getSystemService(InputMethodManager::class.java)
            val filter = PackageFilter(app.packageName) {
                imm?.enabledInputMethodList?.map { it.packageName }?.toSet().orEmpty()
            }
            val pm = app.packageManager
            LoopEngine(
                FileLoopStore(File(File(app.filesDir, "loop"), "state.json")),
                filter,
                minuteOfDay = { localMinuteOfDay() },
                dayKey = { localDayKey() },
            ).also {
                val abandoned = it.recover()
                if (abandoned.isNotEmpty()) Log.i(TAG, "recovered: closed ${abandoned.size} open event(s)")
                it.recoveredFrom?.let { b -> Log.w(TAG, "state file damaged, loaded backup $b") }
                localBridge = LocalTemplateBridge(
                    labels = { p -> p?.let { pkg -> runCatching { pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString() }.getOrNull() } },
                    template = { app -> app },
                )
                engine = it
            }
        }
    }

    fun attach(s: AccessibilityService) {
        runCatching { engine(s) }.onFailure { diagnostics.fault(LoopDiagnostics.KIND_ATTACH, it, "engine") }
        runCatching { ProactiveRuntime.ensure(s); ProactiveRuntime.refreshGate("a11y_connected") }
        service = WeakReference(s)
        runCatching { InteractionHub.ensureChannel(s) }
        // The person may already be in the test app; a still-open visit makes this a no-op.
        schedule()
    }

    fun detach(s: AccessibilityService) {
        if (service?.get() === s) service = null
        main.removeCallbacks(verify)
        // Pages can no longer start from the background: the kernel falls back to notifications.
        main.post { runCatching { ProactiveRuntime.refreshGate("a11y_gone") } }
    }

    fun onEvent(s: AccessibilityService, event: AccessibilityEvent?) {
        proactive(event)
        val type = event?.eventType ?: return
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && type != AccessibilityEvent.TYPE_WINDOWS_CHANGED) return
        val e = engine ?: return
        if (!e.config().enabled) return
        if (service?.get() !== s) service = WeakReference(s)
        eventsSeen++
        diagnostics.success(LoopDiagnostics.KIND_EVENT)
        schedule()
    }

    /** Hooks for the proactive kernel; every window event is also its opportunistic clock. */
    private fun proactive(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        runCatching { ProactiveRuntime.onWindowActivity() }
    }

    /** Settings changed: read the foreground again so the new target is judged from now on. */
    fun configChanged() = schedule()

    private fun schedule() {
        main.removeCallbacks(verify)
        main.postDelayed(verify, SETTLE_MS)
    }

    private fun verifyNow() {
        val s = service?.get() ?: return
        val e = engine ?: return
        if (!e.config().enabled) return
        val previousForeground = lastForeground
        val pkg = try {
            foreground(s).also {
                readings++
                lastForeground = it
                diagnostics.success(LoopDiagnostics.KIND_READ_FOREGROUND)
            }
        } catch (t: Throwable) {
            // A throwing window list used to vanish into Log.w; now it is a countable fault.
            Log.w(TAG, "read foreground", t)
            diagnostics.fault(LoopDiagnostics.KIND_READ_FOREGROUND, t)
            return
        }
        try {
            // The proactive gate cares whether a permission/security page took the foreground:
            // it must yield while one is up, and reopen once it is gone.
            if ((pkg in ProtectedPages.packages) != (previousForeground in ProtectedPages.packages)) {
                runCatching { ProactiveRuntime.refreshGate("protected_page") }
            }
            when (val out = e.onForeground(pkg, environment(s))) {
                is LoopEngine.Outcome.Show -> InteractionHub.show(s, e, out)
                is LoopEngine.Outcome.Suppressed -> Log.i(TAG, "suppressed ${out.event.packageName}: ${out.event.reason}")
                is LoopEngine.Outcome.Ignored -> Unit
            }
            diagnostics.success(LoopDiagnostics.KIND_VERIFY)
        } catch (t: Throwable) {
            Log.w(TAG, "verify", t)
            diagnostics.fault(LoopDiagnostics.KIND_VERIFY, t)
        }
    }

    /**
     * The app the person is looking at: the focused application window first (keyboards,
     * DSH's own overlay pill and the status bar are other window types and never win), then
     * DSH's general foreground reading as a fallback. Null when unreadable.
     */
    private fun foreground(s: AccessibilityService): String? {
        val windows = try { s.windows } catch (t: Throwable) {
            diagnostics.fault(LoopDiagnostics.KIND_READ_FOREGROUND, t, "windows")
            null
        }
        try {
            windows?.firstOrNull { it.type == AccessibilityWindowInfo.TYPE_APPLICATION && (it.isFocused || it.isActive) }
                ?.let { w ->
                    val root = w.root ?: return@let null
                    try { root.packageName?.toString() } finally { release(root) }
                }
                ?.let { return it }
        } finally {
            @Suppress("DEPRECATION")
            if (Build.VERSION.SDK_INT < 33) windows?.forEach { runCatching { it.recycle() } }
        }
        return TreeCapture.foregroundPackage(s, screenBox(s))
    }

    private fun environment(s: AccessibilityService): Environment {
        val power = s.getSystemService(PowerManager::class.java)
        val keyguard = s.getSystemService(KeyguardManager::class.java)
        val core = PhoneControl.peek()
        val busy = core != null && (core.tasks.isActive || core.tasks.callsInFlight > 0 || core.prompts.busy())
        return Environment(
            screenInteractive = power?.isInteractive != false,
            keyguardLocked = keyguard?.isKeyguardLocked == true,
            dshBusy = busy,
            minuteOfDay = localMinuteOfDay(),
            dayKey = localDayKey(),
        )
    }

    private fun localMinuteOfDay(): Int {
        val c = java.util.Calendar.getInstance()
        return c.get(java.util.Calendar.HOUR_OF_DAY) * 60 + c.get(java.util.Calendar.MINUTE)
    }

    private fun localDayKey(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    private fun screenBox(s: AccessibilityService): Box {
        val p = Point()
        @Suppress("DEPRECATION")
        s.getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY)?.getRealSize(p)
        return Box(0, 0, p.x.coerceAtLeast(1), p.y.coerceAtLeast(1))
    }

    @Suppress("DEPRECATION")
    private fun release(node: android.view.accessibility.AccessibilityNodeInfo) {
        if (Build.VERSION.SDK_INT < 33) runCatching { node.recycle() }
    }

    /** The label the person sees for a package; used by the page and the notification. */
    fun appLabel(context: Context, pkg: String?): String =
        pkg?.let { p -> runCatching { context.packageManager.getApplicationLabel(context.packageManager.getApplicationInfo(p, 0)).toString() }.getOrNull() } ?: pkg.orEmpty()
}
