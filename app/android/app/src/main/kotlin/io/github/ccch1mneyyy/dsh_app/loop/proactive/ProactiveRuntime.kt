package io.github.ccch1mneyyy.dsh_app.loop.proactive

import android.app.ActivityManager
import android.app.AlarmManager
import android.content.pm.ApplicationInfo
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import io.github.ccch1mneyyy.dsh_app.loop.LoopRuntime
import io.github.ccch1mneyyy.dsh_app.loop.core.AgentReply
import io.github.ccch1mneyyy.dsh_app.loop.core.AgentWire
import io.github.ccch1mneyyy.dsh_app.loop.core.AtomicJsonFile
import io.github.ccch1mneyyy.dsh_app.loop.core.BackgroundCaps
import io.github.ccch1mneyyy.dsh_app.loop.core.Clocks
import io.github.ccch1mneyyy.dsh_app.loop.core.Command
import io.github.ccch1mneyyy.dsh_app.loop.core.Coordinator
import io.github.ccch1mneyyy.dsh_app.loop.core.CoordinatorConfig
import io.github.ccch1mneyyy.dsh_app.loop.core.EventRequest
import io.github.ccch1mneyyy.dsh_app.loop.core.Gate
import io.github.ccch1mneyyy.dsh_app.loop.core.ProactiveLedgerBook
import io.github.ccch1mneyyy.dsh_app.loop.core.ProactiveScheduler
import io.github.ccch1mneyyy.dsh_app.loop.core.ReplyWindow
import io.github.ccch1mneyyy.dsh_app.loop.core.SchedulerConfig
import io.github.ccch1mneyyy.dsh_app.loop.core.Step
import io.github.ccch1mneyyy.dsh_app.loop.core.Submit
import io.github.ccch1mneyyy.dsh_app.loop.core.VisibleSurface
import io.github.ccch1mneyyy.dsh_app.loop.core.Surface
import io.github.ccch1mneyyy.dsh_app.loop.core.Switches
import io.github.ccch1mneyyy.dsh_app.loop.core.SurfaceReport
import io.github.ccch1mneyyy.dsh_app.loop.core.WakeMode
import io.github.ccch1mneyyy.dsh_app.phone.PhoneControl
import io.github.ccch1mneyyy.dsh_app.phone.PhoneTasks
import io.github.ccch1mneyyy.dsh_app.phone.a11y.NowFeed
import io.github.ccch1mneyyy.dsh_app.phone.a11y.PhoneA11yService
import io.github.ccch1mneyyy.dsh_app.loop.intercept.InterceptRuntime
import java.io.File
import java.util.Calendar
import java.util.TimeZone
import java.util.UUID

/** Carries agent commands to the engine. Implemented over Flutter (Dart holds the engine cookie). */
interface AgentPort {
    /** POST /request (also used to resume: the plugin replays an existing requestId without resending). */
    fun request(requestId: String, body: Map<String, Any?>)
    /** GET /result long poll for [requestId]; answer through [ProactiveRuntime.onAgentHttp]. */
    fun poll(requestId: String)
    fun cancel(requestId: String)

    /**
     * One arbitrary plugin route, for the settings page's session read/config write. Separate from
     * the three agent ops so the agent pipeline's semantics cannot be confused with a one-off
     * read; both still go through the same authenticated Dart connection.
     */
    fun requestVia(requestId: String, path: String, body: Map<String, Any?>) = request(requestId, body)
    fun pollVia(requestId: String, path: String) = poll(requestId)
}

/** A notification surface (DeepSeek T3). Must report through [ProactiveRuntime.onSurface] with the token. */
interface NotificationPort {
    fun post(token: String, text: String, deadline: Long): Boolean
    fun cancel(token: String)
    fun cancelAll()
}

/**
 * Android adapter for the proactive kernel (loop/core). Owns one [Coordinator] and one
 * [ProactiveScheduler] per process, builds the [Gate] from DSH's own state (read only), runs the
 * kernel's commands, and keeps exactly one timer: a main-thread callback at the coordinator's next
 * deadline, plus one alarm at the scheduler's next decision (none when the system forbids it).
 *
 * Main thread only.
 */
object ProactiveRuntime {
    private const val TAG = "DshProactive"
    private val main = Handler(Looper.getMainLooper())
    private lateinit var app: Context
    private var coordinator: Coordinator? = null
    private var scheduler: ProactiveScheduler? = null
    /** A. 主动交流账: its own file, its own counters; 行为拦截账 lives in InterceptRuntime. */
    private var ledger: ProactiveLedgerBook? = null
    @Volatile var agentPort: AgentPort? = null
    @Volatile var notificationPort: NotificationPort? = null
    private val deadlineTick = Runnable { tick("deadline") }
    private val taskListener: (PhoneTasks.Snapshot) -> Unit = { main.post { refreshGate("dsh_task") } }
    private var listening: PhoneTasks? = null
    private var lastOpportunistic = 0L

    /** Agent commands that arrived before Dart connected; see [holdAgent]. */
    private data class HeldAgent(val requestId: String, val body: Map<String, Any?>?, val deadline: Long)
    private val heldAgent = LinkedHashMap<String, HeldAgent>()

    /** How often the adapter retries a held agent command while Flutter is still starting. */
    private const val AGENT_RETRY_MS = 5_000L

    /** How long a one-off plugin route may take before the page is told it timed out. */
    private const val ROUTE_TIMEOUT_MS = 12_000L

    fun ensure(context: Context): Coordinator {
        coordinator?.let { return it }
        app = context.applicationContext
        // Load 触发测试's switch before anything reads it: if Flutter starts before the accessibility
        // service, an unloaded LoopEngine would read as "off" and applySwitches would cancel live
        // app-enter events with the wrong reason (review r3, startup race).
        runCatching { LoopRuntime.engine(app) }
        val dir = File(File(app.filesDir, "loop"), "proactive")
        // The reply window is kernel policy: 20 minutes, 60 seconds in a debug build so the
        // ACK → ignored → pause chain can be walked by hand on a phone. Read from the manifest
        // flag rather than BuildConfig, which this build does not generate.
        val debuggable = (app.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        val replyWindow = if (debuggable) ReplyWindow.DEBUG_MS else ReplyWindow.DEFAULT_MS
        val c = Coordinator(
            AtomicJsonFile(File(dir, "coordinator.json")),
            CoordinatorConfig(replyWindowMs = replyWindow),
            clock = System::currentTimeMillis, ids = { UUID.randomUUID().toString() },
        )
        val book = ProactiveLedgerBook(AtomicJsonFile(File(dir, "ledger.json")))
        book.recover()
        val s = ProactiveScheduler(AtomicJsonFile(File(dir, "scheduler.json")), ::minuteOfDay, ::dayOf, ledger = book)
        ledger = book
        coordinator = c
        scheduler = s
        s.recover(clocks())
        dispatch(c.recover(gate()))
        // Round-1 twins whose kernel event closed while no LoopEngine was alive (review r3, A).
        runCatching { LoopRuntime.reconcileWithKernel(c::find) }
        applySwitches()
        watchTasks()
        arm()
        return c
    }

    fun schedulerConfig(): SchedulerConfig = scheduler?.config ?: SchedulerConfig()

    fun setSchedulerConfig(context: Context, cfg: SchedulerConfig) {
        ensure(context)
        scheduler!!.setConfig(cfg, clocks())
        refreshGate("config")
        // 主动搭话 alone still needs foreground readings for the protected-page gate (review r3, C).
        runCatching { LoopRuntime.configChanged() }
    }

    fun proactiveEnabled(): Boolean = scheduler?.config?.enabled == true

    /** The coordinator if this process created it; never creates one. */
    fun kernelOrNull(): Coordinator? = coordinator

    /** Each feature switch cancels only its own events (review r3, B). */
    private fun applySwitches() {
        val c = coordinator ?: return
        val sw = Switches(LoopRuntime.triggerEnabled(), proactiveEnabled())
        for ((source, reason) in sw.disabledSources()) dispatch(c.cancelSource(source, reason))
        // A different test app: app-enter events about the old one are no longer wanted.
        val target = LoopRuntime.triggerTarget()
        if (sw.triggerTest) {
            (c.queued() + listOfNotNull(c.active()))
                .filter { it.request.source == Switches.SOURCE_APP_ENTER && it.request.payload["packageName"] != target }
                .forEach { dispatch(c.cancel(it.eventId, "target_changed")) }
        }
    }

    /** Alarm, boot, app open: one evaluation, no loop. [force] = the user's 「现在试一次」. */
    fun tick(reason: String, force: Boolean = false) {
        val c = coordinator ?: return
        val s = scheduler ?: return
        watchTasks()
        applySwitches()
        dispatch(c.setGate(gate()))
        when (val d = s.evaluate(clocks(), force)) {
            is ProactiveScheduler.Decision.Fire -> submit(d.request, fromScheduler = true)
            is ProactiveScheduler.Decision.Wait -> {
                arm()
                // 让 companion 的 nextEligibleAt 决定下一次检查；仍复用这一个 scheduler/alarm。
                if (d.reason != "pending") consultPlanSoon()
            }
        }
        arm()
        Log.d(TAG, "tick $reason")
    }

    /** Window events from LoopRuntime: cheap, throttled; the only clock in OPPORTUNISTIC mode. */
    fun onWindowActivity() {
        val now = SystemClock.elapsedRealtime()
        if (coordinator == null || now - lastOpportunistic < 60_000) return
        lastOpportunistic = now
        tick("window")
    }

    fun submit(request: EventRequest, fromScheduler: Boolean = false): Submit {
        val c = coordinator ?: return Submit.Rejected("not_ready")
        val (r, step) = c.submit(request)
        if (fromScheduler) when (r) {
            is Submit.Rejected -> scheduler?.onRejected(r.reason, clocks())
            else -> scheduler?.onSubmitted(request.eventId, clocks())
        }
        dispatch(step)
        return r
    }

    fun refreshGate(reason: String) {
        val c = coordinator ?: return
        watchTasks()
        applySwitches()
        dispatch(c.setGate(gate()))
        Log.d(TAG, "gate $reason")
    }

    fun onSurface(token: String, report: SurfaceReport) {
        val c = coordinator ?: return
        val before = c.active()?.takeIf { it.token == token }
        dispatch(c.onSurface(token, report))
        // 展示回执交给 companion 账本：posted = 送达，shown = 真正显示，dismissed = 用户划掉。
        val agentRequestId = before?.agentRequestId
        if (agentRequestId != null) {
            when (report) {
                SurfaceReport.Posted -> reportOutcome(agentRequestId, "delivered")
                SurfaceReport.Shown -> reportOutcome(agentRequestId, "displayed")
                SurfaceReport.Dismissed -> reportOutcome(agentRequestId, "dismissed")
                else -> Unit
            }
        }
        if (report == SurfaceReport.Shown && before != null) runCatching { LoopRuntime.onKernelShown(c.find(before.eventId)) }
        // 「我看到了」: the scheduler learns about the confirmation (and book A records it) at once,
        // but the attempt stays pending until the reply window decides answered vs ignored. It is
        // deliberately *not* user activity: acknowledging is not answering, so it must not defer
        // the next attempt the way an answer does.
        if (report == SurfaceReport.Acked && before != null) scheduler?.onAcked(before.eventId, clocks())
        if (report is SurfaceReport.Answered || report == SurfaceReport.Dismissed) {
            scheduler?.onUserActivity(clocks())
            // 人的回应会改变 garden 的 nextEligibleAt（2h / 12h / done），马上重新问一次。
            consultPlanSoon()
        }
    }

    /** Fire-and-forget: one delivery receipt for the companion ledger; a missing plugin is harmless. */
    private val reportedOutcomes = mutableSetOf<String>()
    private val ignoreResult = object : io.flutter.plugin.common.MethodChannel.Result {
        override fun success(result: Any?) {}
        override fun error(code: String, message: String?, details: Any?) {}
        override fun notImplemented() {}
    }

    private fun reportOutcome(requestId: String, stage: String) {
        if (requestId.isBlank() || !reportedOutcomes.add(requestId + ":" + stage)) return
        fetchPluginRoute(ignoreResult, "POST", "/outcome", linkedMapOf("requestId" to requestId, "stage" to stage))
    }

    private var lastPlanConsult = 0L
    private val planResult = object : io.flutter.plugin.common.MethodChannel.Result {
        override fun success(result: Any?) {
            main.post { applyPlan(result) }
        }
        override fun error(code: String, message: String?, details: Any?) {}
        override fun notImplemented() {}
    }

    /**
     * Ask the companion when the next topic is eligible and move the single scheduler alarm there.
     * This is the only bridge between garden.nextEligibleAt and AlarmManager; no second timer.
     */
    private fun consultPlanSoon() {
        if (agentPort == null) return
        val now = System.currentTimeMillis()
        if (now - lastPlanConsult < 60_000) return
        lastPlanConsult = now
        // The engine runs on TZ=GMT; quiet hours and the daily reset are the phone's wall clock,
        // so the phone's own zone goes with the request. The plugin falls back to Asia/Shanghai.
        fetchPluginRoute(
            planResult,
            "POST",
            "/plan",
            linkedMapOf("roll" to 100, "timeZone" to TimeZone.getDefault().id),
        )
    }

    private fun applyPlan(raw: Any?) {
        val map = raw as? Map<*, *> ?: return
        val at = (map["nextCheckAt"] as? Number)?.toLong() ?: return
        if (at <= 0) return
        scheduler?.setNextDueAt(at, clocks())
        arm()
    }

    /** Dart reports one HTTP answer from the plugin; status 0 = no answer. */
    fun onAgentHttp(requestId: String, status: Int, body: Any?) {
        // A one-off plugin route (sessions / config) rather than a kernel agent request: hand the
        // raw answer to whoever asked, and keep it away from the coordinator, which would otherwise
        // see an unknown request id.
        routeAnswers.remove(requestId)?.let { deliver ->
            main.post { deliver(status, body) }
            return
        }
        val c = coordinator ?: return
        when (val d = AgentWire.decode(status, body)) {
            is AgentWire.Decoded.Reply -> {
                dispatch(c.onAgent(requestId, d.reply))
                if (!d.terminal && c.active()?.agentRequestId == requestId) agentPort?.poll(requestId)
            }
            is AgentWire.Decoded.Retry -> main.postDelayed({
                if (c.active()?.agentRequestId == requestId) agentPort?.poll(requestId)
            }, d.afterMs)
        }
    }

    /** One pending one-off plugin route: `requestId -> answer handler`. */
    private val routeAnswers = LinkedHashMap<String, (Int, Any?) -> Unit>()

    /**
     * Fetches one plugin route over the same Dart transport the agent uses, and answers the
     * MethodChannel call with the plugin's own JSON (or an error map when there is no transport).
     *
     * Deliberately one-shot: this serves the settings page's session read/config write, not a
     * second agent pipeline. `GET` goes out through the transport's poll op (which is the GET one),
     * `POST` through its request op; both are ops the plugin contract already defines.
     */
    fun fetchPluginRoute(
        result: io.flutter.plugin.common.MethodChannel.Result,
        method: String,
        route: String,
        body: Map<String, Any?>?,
    ) {
        val port = agentPort
        if (port == null) {
            result.success(linkedMapOf("error" to linkedMapOf("code" to "no_transport")))
            return
        }
        val requestId = "route-${UUID.randomUUID().toString().take(8)}"
        val path = "${AgentWire.PREFIX}$route"
        routeAnswers[requestId] = { status, raw ->
            result.success(
                when {
                    // status 0 = the transport never got an answer. Kept distinct from an HTTP
                    // error so the page can say "not connected" rather than "plugin refused".
                    status == 0 -> linkedMapOf("error" to linkedMapOf("code" to "no_answer"))
                    raw is Map<*, *> -> raw
                    else -> linkedMapOf("error" to linkedMapOf("code" to "bad-answer", "status" to status))
                },
            )
        }
        main.postDelayed({
            if (routeAnswers.remove(requestId) != null) {
                result.success(linkedMapOf("error" to linkedMapOf("code" to "timeout")))
            }
        }, ROUTE_TIMEOUT_MS)
        if (method == "GET") port.pollVia(requestId, path) else port.requestVia(requestId, path, body ?: emptyMap())
    }

    /** The person used DSH (sent a message): keep proactive attempts out of the way for a while. */
    fun onUserActivity() { scheduler?.onUserActivity(clocks()) }

    private fun dispatch(step: Step) {
        for (cmd in step.commands) runCatching { run(cmd) }.onFailure { Log.w(TAG, "command $cmd", it) }
        for (closed in step.closed) {
            scheduler?.onOutcome(closed.eventId, closed.engagement, clocks())
            // The kernel owns the outcome; the round-1 twin mirrors it (review r3, A).
            runCatching { LoopRuntime.onKernelClosed(closed) }
            Log.i(TAG, "closed ${closed.eventId} ${closed.outcome} ${closed.reason} engagement=${closed.engagement}")
        }
        main.removeCallbacks(deadlineTick)
        coordinator?.nextDeadline()?.let { main.postDelayed(deadlineTick, (it - System.currentTimeMillis()).coerceIn(50, 10 * 60_000L)) }
        if (step.closed.isNotEmpty()) {
            arm()
            // A closed attempt makes the scheduler pick a random 45 min–3 h gap; the companion's
            // ladder (5 min lighter, 15 min channel) must win, so ask it right away.
            consultPlanSoon()
        }
    }

    private fun run(cmd: Command) {
        val c = coordinator!!
        when (cmd) {
            // The Dart port is only wired once Flutter is up. At process start the coordinator's
            // recovery emits ResumeAgent *before* that happens, so "no port yet" must not be turned
            // into a failure: an agent turn that is still inside its deadline is kept and replayed
            // when the port arrives. Only a port that is still missing after the deadline fails.
            is Command.RequestAgent -> {
                val port = agentPort
                val body = AgentWire.requestBody(cmd, System.currentTimeMillis(), phoneContext())
                if (port == null) holdAgent(cmd, body)
                else port.request(cmd.requestId, body)
            }
            // The plugin answers a replayed requestId with its record and never sends twice.
            is Command.ResumeAgent -> {
                val port = agentPort
                if (port == null) holdAgent(Command.ResumeAgent(cmd.eventId, cmd.requestId, cmd.deadline), null)
                else port.poll(cmd.requestId)
            }
            is Command.CancelAgent -> agentPort?.cancel(cmd.requestId)
            is Command.Present -> when (cmd.surface) {
                Surface.ACTIVITY -> {
                    // One visible DSH surface at a time (round-4 integration): the intercept page is
                    // its own activity in its own task, so without this slot the two stack. A
                    // refusal is reported as a surface failure, which the coordinator already knows
                    // how to handle (it falls back to the notification when one is allowed).
                    val claimed = VisibleSurface.claim(VisibleSurface.OWNER_PROACTIVE, cmd.token)
                    if (!claimed) {
                        Log.i(TAG, "activity surface busy (" + VisibleSurface.holder() + "); not stacking")
                        dispatch(c.onSurface(cmd.token, SurfaceReport.Failed("surface_busy")))
                    } else {
                        val ok = ProactivePageActivity.start(app, cmd.token, cmd.content.text, cmd.deadline)
                        if (!ok) VisibleSurface.release(VisibleSurface.OWNER_PROACTIVE, cmd.token)
                        dispatch(c.onSurface(cmd.token, if (ok) SurfaceReport.Posted else SurfaceReport.Failed("start_failed")))
                    }
                }
                Surface.NOTIFICATION -> {
                    val ok = notificationPort?.post(cmd.token, cmd.content.text, cmd.deadline) == true
                    dispatch(c.onSurface(cmd.token, if (ok) SurfaceReport.Posted else SurfaceReport.Failed("no_notification")))
                }
            }
            is Command.Withdraw -> when (cmd.surface) {
                Surface.ACTIVITY -> {
                    ProactivePageActivity.withdraw(cmd.token)
                    VisibleSurface.release(VisibleSurface.OWNER_PROACTIVE, cmd.token)
                }
                Surface.NOTIFICATION -> notificationPort?.cancel(cmd.token)
            }
            Command.ClearLeftovers -> {
                ProactivePageActivity.withdrawAll()
                VisibleSurface.release(VisibleSurface.OWNER_PROACTIVE, null)
                notificationPort?.cancelAll()
            }
        }
    }

    /** Dart started listening: replay agent commands held while Flutter was still coming up. */
    fun onAgentPortReady() {
        main.removeCallbacks(agentRetry)
        flushHeldAgent()
        // The gate depends on the port (notificationsAllowed), so the decision has to be revisited.
        refreshGate("agent_port")
    }

    /**
     * An agent command that arrived before the Dart port existed. [body] is non-null for a fresh
     * request: replaying a fresh request is safe because the plugin answers a repeated requestId
     * with its existing record and never sends the message twice.
     */
    private fun holdAgent(cmd: Command, body: Map<String, Any?>?) {
        val requestId = when (cmd) {
            is Command.RequestAgent -> cmd.requestId
            is Command.ResumeAgent -> cmd.requestId
            else -> return
        }
        val deadline = when (cmd) {
            is Command.RequestAgent -> cmd.deadline
            is Command.ResumeAgent -> cmd.deadline
            else -> 0L
        }
        heldAgent[requestId] = HeldAgent(requestId, body, deadline)
        Log.i(TAG, "agent port not ready, holding $requestId until Flutter connects")
        main.removeCallbacks(agentRetry)
        main.postDelayed(agentRetry, AGENT_RETRY_MS)
    }

    /** Replays what was held once the port exists; drops it only when its deadline has passed. */
    private fun flushHeldAgent() {
        val port = agentPort ?: return
        if (heldAgent.isEmpty()) return
        val now = System.currentTimeMillis()
        val pending = heldAgent.values.toList()
        heldAgent.clear()
        for (h in pending) {
            if (now >= h.deadline) {
                // The turn's window is gone: let the kernel fail it honestly.
                dispatch(coordinator!!.onAgent(h.requestId, AgentReply.Failed("no_transport")))
                continue
            }
            if (h.body != null) port.request(h.requestId, h.body!!) else port.poll(h.requestId)
        }
    }

    private val agentRetry = Runnable { flushHeldAgent() }

    /** DSH's own state, read only. Never takes a PhoneTasks owner or a PromptArbiter slot. */
    fun gate(): Gate {
        val core = PhoneControl.peek()
        val power = app.getSystemService(PowerManager::class.java)
        val keyguard = app.getSystemService(KeyguardManager::class.java)
        val nm = app.getSystemService(NotificationManager::class.java)
        val fg = LoopRuntime.lastForeground
        return Gate(
            // Either feature keeps arbitration on; each one's events are cancelled by applySwitches.
            featureEnabled = Switches(LoopRuntime.triggerEnabled(), proactiveEnabled()).arbitrate,
            dshTaskActive = core != null && (core.tasks.isActive || core.tasks.callsInFlight > 0),
            dshPromptOpen = core?.prompts?.busy() == true,
            protectedForeground = io.github.ccch1mneyyy.dsh_app.loop.ProtectedForeground.isProtected(fg),
            screenOn = power?.isInteractive != false,
            unlocked = keyguard?.isKeyguardLocked != true,
            a11yConnected = PhoneA11yService.isConnected(),
            notificationsAllowed = nm?.areNotificationsEnabled() == true && notificationPort != null,
        )
    }

    private fun watchTasks() {
        PhoneControl.peek()?.prompts?.onBusyChanged = { refreshGate("dsh_prompt") }
        val tasks = PhoneControl.peek()?.tasks ?: return
        if (listening === tasks) return
        listening?.removeListener(taskListener)
        tasks.addListener(taskListener)
        listening = tasks
    }

    fun caps(): BackgroundCaps {
        val am = app.getSystemService(ActivityManager::class.java)
        val alarms = app.getSystemService(AlarmManager::class.java)
        return BackgroundCaps(
            alarmsAvailable = alarms != null,
            exactAlarms = Build.VERSION.SDK_INT < 31 || alarms?.canScheduleExactAlarms() == true,
            backgroundRestricted = Build.VERSION.SDK_INT >= 28 && am?.isBackgroundRestricted == true,
        )
    }

    private fun arm() {
        val s = scheduler ?: return
        val mode = WakeMode.of(caps())
        WakeAlarm.set(app, s.nextWake(clocks(), mode), mode)
    }

    fun clocks() = Clocks(System.currentTimeMillis(), SystemClock.elapsedRealtime(),
        runCatching { Settings.Global.getInt(app.contentResolver, Settings.Global.BOOT_COUNT) }.getOrDefault(0))

    /**
     * 手边的情况 for the companion: front app, how long, today's totals, screen, charging, local
     * time. From [NowFeed] (accessibility events, no screen text). Null when the service never fed
     * it: unknown is not "not using the phone".
     */
    private fun phoneContext(): Map<String, Any?>? = runCatching {
        val now = SystemClock.elapsedRealtime()
        val s = NowFeed.snapshot(now)
        if (s.lastEventAgeMs < 0) return@runCatching null
        val wall = System.currentTimeMillis()
        val targets = runCatching { InterceptRuntime.config().targets }.getOrNull().orEmpty()
        val funApps = targets.associate { it.packageName to it.label }
        val pm = app.packageManager
        fun label(pkg: String): String? = funApps[pkg]
            ?: runCatching { pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString() }.getOrNull()
        val today = NowFeed.today(now, dayOf(wall)).map { (pkg, minutes) ->
            linkedMapOf<String, Any?>("app" to pkg, "label" to label(pkg), "minutes" to minutes, "fun" to (pkg in funApps))
        }
        val front = s.app
        linkedMapOf<String, Any?>(
            "app" to front,
            "label" to front?.let { label(it) },
            "minutes" to s.appMinutes,
            "fun" to (front != null && front in funApps),
            "screenOn" to s.screenOn,
            "charging" to s.charging,
            "local" to String.format(java.util.Locale.US, "%02d:%02d", minuteOfDay(wall) / 60, minuteOfDay(wall) % 60),
            "today" to today,
        )
    }.getOrNull()

    private fun minuteOfDay(wall: Long): Int = Calendar.getInstance(TimeZone.getDefault()).run {
        timeInMillis = wall; get(Calendar.HOUR_OF_DAY) * 60 + get(Calendar.MINUTE)
    }

    private fun dayOf(wall: Long): Long = Calendar.getInstance(TimeZone.getDefault()).run {
        timeInMillis = wall; get(Calendar.YEAR) * 1000L + get(Calendar.DAY_OF_YEAR)
    }
}
