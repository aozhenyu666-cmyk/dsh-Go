package io.github.ccch1mneyyy.dsh_app.loop

import java.util.UUID

/**
 * The first closed loop, platform-free:
 *
 *   verified foreground → [ForegroundTracker] (new visit?) → [TriggerRules] → open event
 *   → InteractionHub shows the page → [answer] closes the event → receipt persisted.
 *
 * Every state change is written before the method returns, so a process death at any point
 * leaves a file [recover] can close honestly (ABANDONED) instead of forgetting the event.
 * Thread-safe: the Android side calls in from the main thread and the plugin thread.
 */
class LoopEngine(
    private val store: LoopStore,
    filter: PackageFilter,
    private val clock: () -> Long = System::currentTimeMillis,
    private val ids: () -> String = { UUID.randomUUID().toString() },
) {
    sealed interface Outcome {
        /** Show the interaction page for this event now. */
        data class Show(val event: LoopEvent, val timeoutMs: Long) : Outcome
        /** A candidate was turned down by a rule; the event is already closed and stored. */
        data class Suppressed(val event: LoopEvent) : Outcome
        /** Not a candidate at all (same visit, neutral window, …). Nothing stored. */
        data class Ignored(val why: String) : Outcome
    }

    private val lock = Any()
    private val tracker = ForegroundTracker(filter)
    private var config = LoopConfig()
    private var lastTriggerAt = 0L
    private val events = ArrayDeque<LoopEvent>()

    /** Last storage failure, for the settings page. Null once a write succeeds again. */
    @Volatile var storageError: String? = null
        private set

    /**
     * Process start / service (re)connect. Loads the file; any event still open belonged to a
     * process or page that is gone, so it closes as ABANDONED. The visit is kept: a reconnect
     * while the person is still in the test app does not count as a new entry.
     */
    fun recover(): List<LoopEvent> = synchronized(lock) {
        val closed = mutableListOf<LoopEvent>()
        when (val r = store.read()) {
            LoopStore.Read.Empty -> Unit
            is LoopStore.Read.Unreadable -> {
                events.clear()
                closed += record(newEvent(EventSource.RECOVERY, EventState.CLOSED, EventResult.ERROR, error = "state_unreadable: ${r.error}"))
            }
            is LoopStore.Read.Loaded -> {
                config = r.snapshot.config
                tracker.restore(r.snapshot.tracker)
                lastTriggerAt = r.snapshot.lastTriggerAt
                events.clear()
                events.addAll(r.snapshot.events.takeLast(LoopStore.MAX_EVENTS))
                val now = clock()
                for (i in events.indices) {
                    val e = events[i]
                    if (!e.open) continue
                    val c = e.copy(state = EventState.CLOSED, result = EventResult.ABANDONED, reason = "process_restart", updatedAt = now)
                    events[i] = c
                    closed += c
                }
            }
        }
        persist()
        closed
    }

    fun config(): LoopConfig = synchronized(lock) { config }

    fun setConfig(next: LoopConfig): LoopConfig = synchronized(lock) {
        val n = next.normalized()
        // A different test app is a different loop: drop the visit and close what is open.
        if (n.targetPackage != config.targetPackage || !n.enabled) closeOpenLocked(EventResult.DISMISSED, "config_changed")
        config = n
        persist()
        config
    }

    /** One verified foreground reading. [env] is read by the caller just before. */
    fun onForeground(verified: String?, env: Environment, source: EventSource = EventSource.A11Y_WINDOW): Outcome = synchronized(lock) {
        val target = config.targetPackage.takeIf { config.enabled }
        val before = tracker.state
        val step = tracker.onForeground(verified, target) { ids() }
        if (tracker.state != before) persist()
        val visitId = when (step) {
            is ForegroundTracker.Step.Entered -> step.visitId
            ForegroundTracker.Step.Stayed -> return Outcome.Ignored("same_visit")
            ForegroundTracker.Step.Exited -> return Outcome.Ignored("exited")
            is ForegroundTracker.Step.Ignored -> return Outcome.Ignored(step.why)
        }
        val now = clock()
        if (lastTriggerAt > now) lastTriggerAt = now // the clock went back: restart the cooldown from here
        val base = newEvent(source, EventState.CONFIRMED, packageName = verified, visitId = visitId)
        when (val d = TriggerRules.decide(now, config, env, lastTriggerAt, events.any { it.open })) {
            is TriggerRules.Decision.Suppress -> Outcome.Suppressed(
                record(base.copy(state = EventState.CLOSED, result = EventResult.SUPPRESSED, reason = d.reason)),
            )
            TriggerRules.Decision.Trigger -> {
                lastTriggerAt = now
                Outcome.Show(record(base.copy(state = EventState.TRIGGERED, surface = "activity")), config.timeoutMs)
            }
        }
    }

    /** The page is on screen. False when the event is already closed (stale page: finish it). */
    fun shown(eventId: String): Boolean = synchronized(lock) {
        val e = find(eventId) ?: return false
        if (e.state == EventState.SHOWN) return true
        if (e.state != EventState.TRIGGERED) return false
        replace(e.copy(state = EventState.SHOWN, updatedAt = clock()))
        true
    }

    /** Where [eventId] stands now; null when unknown (evicted or never existed). */
    fun stateOf(eventId: String): EventState? = synchronized(lock) { find(eventId)?.state }

    /**
     * Closes the event with the person's answer (or TIMEOUT / DISMISSED / UNAVAILABLE / ERROR).
     * Idempotent: the first answer wins, later ones (double tap, back + button) return null.
     */
    fun answer(eventId: String, result: EventResult, reason: String? = null, error: String? = null): LoopEvent? = synchronized(lock) {
        val e = find(eventId)?.takeIf { it.open } ?: return null
        replace(e.copy(state = EventState.CLOSED, result = result, reason = reason ?: e.reason, error = error, updatedAt = clock()))
    }

    /** Newest first. */
    fun events(limit: Int = 50): List<LoopEvent> = synchronized(lock) { events.reversed().take(limit.coerceIn(0, LoopStore.MAX_EVENTS)) }

    fun clearEvents() = synchronized(lock) {
        events.removeAll { !it.open }
        persist()
    }

    fun trackerState(): ForegroundTracker.State = synchronized(lock) { tracker.state }

    private fun closeOpenLocked(result: EventResult, reason: String) {
        val now = clock()
        for (i in events.indices) if (events[i].open) {
            events[i] = events[i].copy(state = EventState.CLOSED, result = result, reason = reason, updatedAt = now)
        }
    }

    private fun newEvent(
        source: EventSource, state: EventState, result: EventResult? = null, error: String? = null,
        packageName: String? = null, visitId: String? = null,
    ): LoopEvent {
        val now = clock()
        return LoopEvent(ids(), source, now, state, result, error, packageName = packageName, visitId = visitId, updatedAt = now)
    }

    private fun find(id: String): LoopEvent? = events.lastOrNull { it.eventId == id }

    private fun record(e: LoopEvent): LoopEvent {
        events.addLast(e)
        while (events.size > LoopStore.MAX_EVENTS) {
            // Never evict an open event: its page still needs to close it.
            val idx = events.indexOfFirst { !it.open }.takeIf { it >= 0 } ?: break
            events.removeAt(idx)
        }
        persist()
        return e
    }

    private fun replace(e: LoopEvent): LoopEvent {
        val i = events.indexOfLast { it.eventId == e.eventId }
        if (i >= 0) events[i] = e
        persist()
        return e
    }

    private fun persist() {
        storageError = try {
            store.write(LoopSnapshot(config, tracker.state, lastTriggerAt, events.toList()))
            null
        } catch (t: Throwable) {
            "${t.javaClass.simpleName}: ${t.message}".take(300)
        }
    }
}
