package io.github.ccch1mneyyy.dsh_app.loop

// EventScheduler v0: the local rules that decide whether a confirmed entry may trigger.
// Random proactive triggers, time windows and alarms come later (see docs/loop/ARCHITECTURE.md);
// they will feed the same [TriggerRules.decide] so every trigger passes the same gates.

data class LoopConfig(
    val enabled: Boolean = false,
    val targetPackage: String? = null,
    /** Minimum gap between two triggers, across restarts (wall clock). */
    val cooldownMs: Long = DEFAULT_COOLDOWN_MS,
    /** How long the interaction page waits for an answer. */
    val timeoutMs: Long = DEFAULT_TIMEOUT_MS,
) {
    fun normalized(): LoopConfig = copy(
        targetPackage = targetPackage?.trim()?.takeIf { it.isNotEmpty() && it.length <= 255 },
        cooldownMs = cooldownMs.coerceIn(0, 24 * 3_600_000L),
        timeoutMs = timeoutMs.coerceIn(5_000, 10 * 60_000L),
    )

    fun toMap(): Map<String, Any?> = linkedMapOf(
        "enabled" to enabled, "targetPackage" to targetPackage, "cooldownMs" to cooldownMs, "timeoutMs" to timeoutMs,
    )

    companion object {
        const val DEFAULT_COOLDOWN_MS = 60_000L
        const val DEFAULT_TIMEOUT_MS = 60_000L

        fun fromMap(m: Map<*, *>?): LoopConfig = if (m == null) LoopConfig() else LoopConfig(
            enabled = m["enabled"] == true,
            targetPackage = m["targetPackage"] as? String,
            cooldownMs = (m["cooldownMs"] as? Number)?.toLong() ?: DEFAULT_COOLDOWN_MS,
            timeoutMs = (m["timeoutMs"] as? Number)?.toLong() ?: DEFAULT_TIMEOUT_MS,
        ).normalized()
    }
}

/** Facts the Android side supplies at decision time. */
data class Environment(
    val screenInteractive: Boolean = true,
    val keyguardLocked: Boolean = false,
    /** A DSH phone task is running or a DSH question is on screen: never compete with it. */
    val dshBusy: Boolean = false,
)

object TriggerRules {
    sealed interface Decision {
        data object Trigger : Decision
        data class Suppress(val reason: String) : Decision
    }

    /** The order is the rule: the first failing gate names the reason. */
    fun decide(
        now: Long,
        config: LoopConfig,
        env: Environment,
        lastTriggerAt: Long,
        hasOpenEvent: Boolean,
    ): Decision = when {
        !config.enabled -> Decision.Suppress("disabled")
        !env.screenInteractive -> Decision.Suppress("screen_off")
        env.keyguardLocked -> Decision.Suppress("locked")
        env.dshBusy -> Decision.Suppress("dsh_busy")
        hasOpenEvent -> Decision.Suppress("interaction_open")
        lastTriggerAt > now -> Decision.Suppress("clock_back")
        lastTriggerAt != 0L && now - lastTriggerAt < config.cooldownMs -> Decision.Suppress("cooldown")
        else -> Decision.Trigger
    }
}
