package io.github.ccch1mneyyy.dsh_app.loop.proactive

import android.app.ActivityManager
import android.app.AlarmManager
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
import io.github.ccch1mneyyy.dsh_app.loop.core.EventRequest
import io.github.ccch1mneyyy.dsh_app.loop.core.Gate
import io.github.ccch1mneyyy.dsh_app.loop.core.ProactiveScheduler
import io.github.ccch1mneyyy.dsh_app.loop.core.SchedulerConfig
import io.github.ccch1mneyyy.dsh_app.loop.core.Step
import io.github.ccch1mneyyy.dsh_app.loop.core.Submit
import io.github.ccch1mneyyy.dsh_app.loop.core.Surface
import io.github.ccch1mneyyy.dsh_app.loop.core.SurfaceReport
import io.github.ccch1mneyyy.dsh_app.loop.core.WakeMode
import io.github.ccch1mneyyy.dsh_app.phone.PhoneControl
import io.github.ccch1mneyyy.dsh_app.phone.PhoneTasks
import io.github.ccch1mneyyy.dsh_app.phone.a11y.PhoneA11yService
import io.github.ccch1mneyyy.dsh_app.phone.a11y.ProtectedPages
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

    fun ensure(context: Context): Coordinator {
        coordinator?.let { return it }
        app = context.applicationContext
        val dir = File(File(app.filesDir, "loop"), "proactive")
        val c = Coordinator(AtomicJsonFile(File(dir, "coordinator.json")), clock = System::currentTimeMillis, ids = { UUID.randomUUID().toString() })
        val s = ProactiveScheduler(AtomicJsonFile(File(dir, "scheduler.json")), ::minuteOfDay, ::dayOf)
        coordinator = c
        scheduler = s
        s.recover(clocks())
        dispatch(c.recover(gate()))
        watchTasks()
        arm()
        return c
    }

    fun schedulerConfig(): SchedulerConfig = scheduler?.config ?: SchedulerConfig()

    fun setSchedulerConfig(context: Context, cfg: SchedulerConfig) {
        ensure(context)
        scheduler!!.setConfig(cfg, clocks())
        refreshGate("config")
    }

    /** Alarm, boot, app open: one evaluation, no loop. */
    fun tick(reason: String) {
        val c = coordinator ?: return
        val s = scheduler ?: return
        watchTasks()
        dispatch(c.setGate(gate()))
        when (val d = s.evaluate(clocks())) {
            is ProactiveScheduler.Decision.Fire -> submit(d.request, fromScheduler = true)
            is ProactiveScheduler.Decision.Wait -> Unit
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
        dispatch(c.setGate(gate()))
        Log.d(TAG, "gate $reason")
    }

    fun onSurface(token: String, report: SurfaceReport) {
        val c = coordinator ?: return
        dispatch(c.onSurface(token, report))
        if (report is SurfaceReport.Answered || report == SurfaceReport.Dismissed) scheduler?.onUserActivity(clocks())
    }

    /** Dart reports one HTTP answer from the plugin; status 0 = no answer. */
    fun onAgentHttp(requestId: String, status: Int, body: Any?) {
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

    /** The person used DSH (sent a message): keep proactive attempts out of the way for a while. */
    fun onUserActivity() { scheduler?.onUserActivity(clocks()) }

    private fun dispatch(step: Step) {
        for (cmd in step.commands) runCatching { run(cmd) }.onFailure { Log.w(TAG, "command $cmd", it) }
        for (closed in step.closed) {
            scheduler?.onOutcome(closed.eventId, closed.engagement, clocks())
            Log.i(TAG, "closed ${closed.eventId} ${closed.outcome} ${closed.reason} engagement=${closed.engagement}")
        }
        main.removeCallbacks(deadlineTick)
        coordinator?.nextDeadline()?.let { main.postDelayed(deadlineTick, (it - System.currentTimeMillis()).coerceIn(50, 10 * 60_000L)) }
        if (step.closed.isNotEmpty()) arm()
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
                if (port == null) holdAgent(cmd, AgentWire.requestBody(cmd, System.currentTimeMillis()))
                else port.request(cmd.requestId, AgentWire.requestBody(cmd, System.currentTimeMillis()))
            }
            // The plugin answers a replayed requestId with its record and never sends twice.
            is Command.ResumeAgent -> {
                val port = agentPort
                if (port == null) holdAgent(Command.ResumeAgent(cmd.eventId, cmd.requestId, cmd.deadline), null)
                else port.poll(cmd.requestId)
            }
            is Command.CancelAgent -> agentPort?.cancel(cmd.requestId)
            is Command.Present -> when (cmd.surface) {
                Surface.ACTIVITY -> ProactivePageActivity.start(app, cmd.token, cmd.content.text, cmd.deadline)
                    .let { ok -> if (ok) dispatch(c.onSurface(cmd.token, SurfaceReport.Posted)) else dispatch(c.onSurface(cmd.token, SurfaceReport.Failed("start_failed"))) }
                Surface.NOTIFICATION -> {
                    val ok = notificationPort?.post(cmd.token, cmd.content.text, cmd.deadline) == true
                    dispatch(c.onSurface(cmd.token, if (ok) SurfaceReport.Posted else SurfaceReport.Failed("no_notification")))
                }
            }
            is Command.Withdraw -> when (cmd.surface) {
                Surface.ACTIVITY -> ProactivePageActivity.withdraw(cmd.token)
                Surface.NOTIFICATION -> notificationPort?.cancel(cmd.token)
            }
            Command.ClearLeftovers -> { ProactivePageActivity.withdrawAll(); notificationPort?.cancelAll() }
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
            featureEnabled = scheduler?.config?.enabled == true,
            dshTaskActive = core != null && (core.tasks.isActive || core.tasks.callsInFlight > 0),
            dshPromptOpen = core?.prompts?.busy() == true,
            protectedForeground = fg != null && (fg in ProtectedPages.packages),
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

    private fun minuteOfDay(wall: Long): Int = Calendar.getInstance(TimeZone.getDefault()).run {
        timeInMillis = wall; get(Calendar.HOUR_OF_DAY) * 60 + get(Calendar.MINUTE)
    }

    private fun dayOf(wall: Long): Long = Calendar.getInstance(TimeZone.getDefault()).run {
        timeInMillis = wall; get(Calendar.YEAR) * 1000L + get(Calendar.DAY_OF_YEAR)
    }
}
