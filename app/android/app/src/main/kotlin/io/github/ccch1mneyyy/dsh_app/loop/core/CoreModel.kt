package io.github.ccch1mneyyy.dsh_app.loop.core

// The proactive interaction kernel's data model. Plain Kotlin: no Android types, so the whole
// kernel (arbitration, scheduling, agent protocol) runs in JVM tests.
//
// One event moves through one pipeline:
//
//   QUEUED → AWAITING_AGENT → READY → PRESENTING → SHOWN → CLOSED
//                (optional)              │  (notification: DELIVERED, never "seen")
//                                        └→ withdrawn when DSH needs the screen → READY again
//
// Facts (timestamps) are recorded separately from the state, because "the agent accepted",
// "the model produced text", "a surface was posted", "the person saw it" and "the person
// answered" are different things and none of them implies the next.

enum class Priority(val rank: Int) { LOW(0), NORMAL(1), HIGH(2) }

enum class Stage { QUEUED, AWAITING_AGENT, READY, PRESENTING, DELIVERED, SHOWN, CLOSED }

/** Where the content shown to the person came from. */
enum class ContentSource { LOCAL, AGENT, FALLBACK }

enum class Surface { ACTIVITY, NOTIFICATION }

/** How an event ended. Set once. */
enum class Outcome {
    /** The person tapped an answer on a surface. */
    RESPONDED,
    /** The person closed the surface on purpose (back, swipe away, leave the page). */
    DISMISSED,
    /** No answer before the interaction deadline. See [ProactiveEvent.engagement]. */
    TIMEOUT,
    /** Turned off, cancelled by the caller, or the configuration changed. */
    CANCELLED,
    /** Gave way to DSH more often than allowed. */
    YIELDED,
    /** Its time-to-live ran out before it could be shown. */
    EXPIRED,
    /** Folded into an equivalent event (see [ProactiveEvent.mergedInto]). */
    MERGED,
    /** The queue was full and this was the least valuable event. */
    DROPPED,
    /** No surface could be shown (start refused, no permission, never acknowledged). */
    UNAVAILABLE,
    /** The agent failed and the event had no local fallback. */
    FAILED,
    /** The process died while the event was on screen; closed on recovery. */
    ABANDONED,
}

/**
 * What the person's side of an event amounted to — the only thing the scheduler learns from.
 * A posted notification that timed out is [UNCONFIRMED]: posting is not reading.
 */
enum class Engagement { RESPONDED, DISMISSED, IGNORED_SEEN, UNCONFIRMED, NOT_DELIVERED }

/** What a producer (window observer, scheduler, …) asks for. */
data class EventRequest(
    val eventId: String,
    /** "A11Y_WINDOW", "SCHEDULER", … */
    val source: String,
    /** Free-form kind for the agent ("app_enter", "random_chat"). */
    val kind: String,
    /** Equal keys are the same intent: a second one merges instead of queueing. */
    val dedupeKey: String,
    val priority: Priority = Priority.NORMAL,
    val createdAt: Long,
    val ttlMs: Long = 10 * 60_000L,
    /** Ask the DSH agent for the text; otherwise [fallbackText] is shown as is. */
    val needsAgent: Boolean = false,
    /** Shown when the agent is not asked, fails or times out. Null: no fallback (the event fails). */
    val fallbackText: String? = null,
    /** Small facts for the agent (package name, local time). Never screen contents. */
    val payload: Map<String, String> = emptyMap(),
)

data class Content(val text: String, val source: ContentSource, val agentTurnId: String? = null)

/**
 * One event and everything known about it. Immutable; the coordinator replaces it on every
 * change and persists the result before returning.
 */
data class ProactiveEvent(
    val request: EventRequest,
    val stage: Stage = Stage.QUEUED,
    val outcome: Outcome? = null,
    val reason: String? = null,
    val expiresAt: Long = request.createdAt + request.ttlMs,
    val priority: Priority = request.priority,
    val mergedCount: Int = 0,
    val mergedInto: String? = null,
    val yields: Int = 0,
    // Agent exchange
    val agentRequestId: String? = null,
    val agentAttempts: Int = 0,
    val agentDeadline: Long = 0,
    val agentRequestedAt: Long? = null,
    val agentAcceptedAt: Long? = null,
    /** The agent loop took the message: a turn is running on it. */
    val agentClaimedAt: Long? = null,
    val generatedAt: Long? = null,
    val agentError: String? = null,
    val lateResults: Int = 0,
    val content: Content? = null,
    // Presentation
    val surface: Surface? = null,
    val token: String? = null,
    val presentDeadline: Long = 0,
    val presentedAt: Long? = null,
    val deliveredAt: Long? = null,
    val shownAt: Long? = null,
    val interactionDeadline: Long = 0,
    val respondedAt: Long? = null,
    val answer: String? = null,
    val closedAt: Long? = null,
    /** The page could not be shown once: the next attempt uses a notification. */
    val avoidActivity: Boolean = false,
) {
    val eventId: String get() = request.eventId
    val open: Boolean get() = stage != Stage.CLOSED

    val engagement: Engagement get() = when {
        outcome == Outcome.RESPONDED -> Engagement.RESPONDED
        outcome == Outcome.DISMISSED -> Engagement.DISMISSED
        shownAt != null -> Engagement.IGNORED_SEEN
        deliveredAt != null -> Engagement.UNCONFIRMED
        else -> Engagement.NOT_DELIVERED
    }
}

/**
 * The facts the coordinator arbitrates on, read by the Android adapter from DSH's own state.
 * The kernel only reads them: it never takes or fakes a PhoneTasks owner or a PromptArbiter slot.
 */
data class Gate(
    val featureEnabled: Boolean = true,
    /** PhoneTasks: a task is active, or a tool call is in flight. */
    val dshTaskActive: Boolean = false,
    /** PromptArbiter has a question open (approval, review, native confirm, handoff). */
    val dshPromptOpen: Boolean = false,
    /** A system permission / install / security page is in front (ProtectedPages). */
    val protectedForeground: Boolean = false,
    val screenOn: Boolean = true,
    val unlocked: Boolean = true,
    /** DSH's accessibility service is bound: the only way to start a page from the background. */
    val a11yConnected: Boolean = true,
    val notificationsAllowed: Boolean = true,
) {
    /** DSH needs the screen or the person is answering DSH: proactive surfaces must give way. */
    val dshNeedsScreen: Boolean get() = dshTaskActive || dshPromptOpen || protectedForeground

    /** Nothing new may appear now. */
    fun holdReason(): String? = when {
        !featureEnabled -> "disabled"
        dshTaskActive -> "dsh_task"
        dshPromptOpen -> "dsh_prompt"
        protectedForeground -> "protected_page"
        !screenOn -> "screen_off"
        !unlocked -> "locked"
        else -> null
    }

    /** Where a page could appear now; null when none can. */
    fun surface(): Surface? = when {
        holdReason() != null -> null
        a11yConnected -> Surface.ACTIVITY
        notificationsAllowed -> Surface.NOTIFICATION
        else -> null
    }
}

/** What the adapter must do. Every command names its event; surface commands carry the token. */
sealed interface Command {
    data class RequestAgent(val eventId: String, val requestId: String, val deadline: Long, val request: EventRequest) : Command
    /** After a restart: the request may still be running in the engine; ask for its result again. */
    data class ResumeAgent(val eventId: String, val requestId: String, val deadline: Long) : Command
    data class CancelAgent(val eventId: String, val requestId: String, val reason: String) : Command
    data class Present(val eventId: String, val token: String, val surface: Surface, val content: Content, val deadline: Long) : Command
    data class Withdraw(val eventId: String, val token: String, val surface: Surface, val reason: String) : Command
    /** After a restart: remove any page or notification a dead process left behind. */
    data object ClearLeftovers : Command
}

/** The result of one call into the coordinator: commands to run, events that just closed. */
data class Step(val commands: List<Command> = emptyList(), val closed: List<ProactiveEvent> = emptyList()) {
    operator fun plus(o: Step) = Step(commands + o.commands, closed + o.closed)
}

sealed interface Submit {
    data class Queued(val eventId: String) : Submit
    data class Merged(val into: String) : Submit
    data class Rejected(val reason: String) : Submit
}

/** What the agent side said about one request. */
sealed interface AgentReply {
    /** The message is in the agent's inbox. Not yet a turn. */
    data object Accepted : AgentReply
    /** The loop claimed it: a turn is running. Still no text. */
    data class Claimed(val turn: Long?) : AgentReply
    data class Generated(val text: String, val turnId: String?) : AgentReply
    data class Failed(val code: String) : AgentReply
}

/** What a surface reports, always with the token it was given. */
sealed interface SurfaceReport {
    /** The surface was handed to the system (activity started / notification posted). */
    data object Posted : SurfaceReport
    /** The surface is confirmed on screen (activity resumed). Notifications never send this. */
    data object Shown : SurfaceReport
    data class Answered(val choice: String) : SurfaceReport
    data object Dismissed : SurfaceReport
    /** The system refused it (start blocked, notifications off). */
    data class Failed(val code: String) : SurfaceReport
}
