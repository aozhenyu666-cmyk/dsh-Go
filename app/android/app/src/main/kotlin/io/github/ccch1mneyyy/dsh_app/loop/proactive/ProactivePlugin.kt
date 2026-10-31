package io.github.ccch1mneyyy.dsh_app.loop.proactive

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.github.ccch1mneyyy.dsh_app.loop.core.CoreCodecPublic
import io.github.ccch1mneyyy.dsh_app.loop.core.ProactiveScheduler
import io.github.ccch1mneyyy.dsh_app.loop.core.SchedulerConfig

/**
 * `dsh/proactive` (methods) + `dsh/proactive/agent` (events): the App side of the agent port.
 *
 * Kotlin → Dart (event stream), one map per HTTP call Dart must make on the current host:
 *   {op: "request", requestId, path: "/dsh-go-proactive/v1/request", body}
 *   {op: "poll",    requestId, path: "/dsh-go-proactive/v1/result?requestId=…&waitMs=20000"}
 *   {op: "cancel",  requestId, path: "/dsh-go-proactive/v1/cancel", body}
 * Dart → Kotlin: `agentHttp {requestId, status, body}` with the raw answer (status 0 = no answer).
 * Dart never interprets the plugin's states: AgentWire does.
 *
 * Methods: `status`, `setConfig` (SchedulerConfig fields), `receipts {limit}`, `agentHttp`,
 * `userActivity` (the person sent a chat message), `tick`.
 */
class ProactivePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, AgentPort {
    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "dsh/proactive").also { it.setMethodCallHandler(this) }
        events = EventChannel(binding.binaryMessenger, "dsh/proactive/agent").also { it.setStreamHandler(this) }
        // D2: the notification surface must exist before the kernel can pick it, or the gate would
        // report "notifications not allowed" on a phone that has them.
        main.post {
            ProactiveRuntime.ensure(context)
            if (ProactiveRuntime.notificationPort == null) {
                ProactiveRuntime.notificationPort = NotificationPortImpl(context)
                ProactiveRuntime.refreshGate("notification_port")
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (ProactiveRuntime.agentPort === this) ProactiveRuntime.agentPort = null
        methods?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        methods = null
        events = null
    }

    // Dart listens → the port exists; requests made while nobody listens fail as no_transport.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        ProactiveRuntime.agentPort = this
        // Dart is now listening: replay whatever the coordinator asked for while it was starting.
        ProactiveRuntime.onAgentPortReady()
    }

    override fun onCancel(arguments: Any?) {
        sink = null
        if (ProactiveRuntime.agentPort === this) ProactiveRuntime.agentPort = null
    }

    override fun request(requestId: String, body: Map<String, Any?>) =
        emit(mapOf("op" to "request", "requestId" to requestId, "path" to "${io.github.ccch1mneyyy.dsh_app.loop.core.AgentWire.PREFIX}/request", "body" to body))

    override fun poll(requestId: String) =
        emit(mapOf("op" to "poll", "requestId" to requestId, "path" to io.github.ccch1mneyyy.dsh_app.loop.core.AgentWire.resultPath(requestId)))

    override fun cancel(requestId: String) =
        emit(mapOf("op" to "cancel", "requestId" to requestId, "path" to "${io.github.ccch1mneyyy.dsh_app.loop.core.AgentWire.PREFIX}/cancel",
            "body" to io.github.ccch1mneyyy.dsh_app.loop.core.AgentWire.cancelBody(requestId)))

    /** A one-off plugin route: the caller supplies the path (sessions read / config write). */
    override fun requestVia(requestId: String, path: String, body: Map<String, Any?>) =
        emit(mapOf("op" to "request", "requestId" to requestId, "path" to path, "body" to body))

    override fun pollVia(requestId: String, path: String) =
        emit(mapOf("op" to "poll", "requestId" to requestId, "path" to path))

    private fun emit(m: Map<String, Any?>) { main.post { sink?.success(m) } }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        ProactiveRuntime.ensure(context)
        when (call.method) {
            "status" -> result.success(status())
            "setConfig" -> {
                val m = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
                val merged = ProactiveScheduler.configMap(ProactiveRuntime.schedulerConfig()) + m.entries.associate { it.key.toString() to it.value }
                ProactiveRuntime.setSchedulerConfig(context, ProactiveScheduler.configFrom(merged))
                result.success(ProactiveScheduler.configMap(ProactiveRuntime.schedulerConfig()))
            }
            "receipts" -> result.success(ProactiveRuntime.ensure(context).receipts(call.argument<Int>("limit") ?: 50).map(CoreCodecPublic::event))
            "agentHttp" -> {
                val id = call.argument<String>("requestId")
                if (id == null) { result.success(false); return }
                ProactiveRuntime.onAgentHttp(id, call.argument<Int>("status") ?: 0, call.argument<Any?>("body"))
                result.success(true)
            }
            "userActivity" -> { ProactiveRuntime.onUserActivity(); result.success(true) }
            "tick" -> { ProactiveRuntime.tick("app"); result.success(true) }
            // The plugin's own /status and /config, carried over the authenticated connection by
            // Dart. The answer is returned raw: this page only displays sessions, it never decides
            // that one may be used (the plugin refuses missing, archived and busy agents itself).
            "agentSessions" -> ProactiveRuntime.fetchPluginRoute(result, "GET", "/status", null)
            "agentSessionSet" -> ProactiveRuntime.fetchPluginRoute(
                result, "POST", "/config", linkedMapOf("sessionId" to call.argument<String>("sessionId")),
            )
            else -> result.notImplemented()
        }
    }

    private fun status(): Map<String, Any?> {
        val c = ProactiveRuntime.ensure(context)
        return linkedMapOf(
            "config" to ProactiveScheduler.configMap(ProactiveRuntime.schedulerConfig()),
            "gate" to ProactiveRuntime.gate().let { g -> linkedMapOf("hold" to g.holdReason(), "surface" to g.surface()?.name) },
            "wakeMode" to io.github.ccch1mneyyy.dsh_app.loop.core.WakeMode.of(ProactiveRuntime.caps()).name,
            "alarmError" to WakeAlarm.lastError,
            "transport" to (ProactiveRuntime.agentPort != null),
            "active" to c.active()?.let(CoreCodecPublic::event),
            "queued" to c.queued().size,
            "storageError" to c.storageError,
            "recoveryIssue" to c.recoveryIssue,
        )
    }
}
