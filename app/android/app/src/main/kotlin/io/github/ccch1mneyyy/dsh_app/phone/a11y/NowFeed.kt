package io.github.ccch1mneyyy.dsh_app.phone.a11y

/**
 * "Now" for the relationship engine: which app is in front, how long, screen, charging.
 *
 * Fed by the accessibility service (window events + screen/charging broadcasts), not by a
 * continuous screen read. This is the minimum context `relationship_check` needs; it does not
 * contain screen text. If the service is not connected the snapshot is empty, and callers must
 * treat that as unknown rather than "not using the phone".
 *
 * Pure Kotlin (no Android imports) so the time arithmetic is unit-tested on the JVM.
 */
object NowFeed {
    data class Snapshot(
        val app: String?,
        val appMinutes: Int,
        val screenOn: Boolean,
        val charging: Boolean,
        val since: Long,
        val lastEventAgeMs: Long,
    )

    private var app: String? = null
    private var since = 0L
    private var lastEventAt = 0L
    private var screenOn = true
    private var charging = false

    @Synchronized
    fun onApp(packageName: String?, now: Long) {
        if (packageName.isNullOrBlank()) return
        if (isNoise(packageName)) return
        if (packageName != app) {
            app = packageName
            since = now
        }
        lastEventAt = now
    }

    /** System UI, the IME and permission dialogs are layers over the app, not a new app. */
    private fun isNoise(packageName: String): Boolean {
        if (packageName == "android" || packageName == "com.android.systemui") return true
        val lower = packageName.lowercase()
        return lower.contains("inputmethod") ||
            lower.endsWith(".ime") ||
            lower.contains("permissioncontroller")
    }

    @Synchronized
    fun onScreen(on: Boolean, now: Long) {
        screenOn = on
        if (!on) {
            app = null
            since = 0L
        }
        lastEventAt = now
    }

    @Synchronized
    fun onCharging(on: Boolean, now: Long) {
        charging = on
        lastEventAt = now
    }

    @Synchronized
    fun snapshot(now: Long): Snapshot {
        val minutes = if (app == null || since <= 0L) {
            0
        } else {
            ((now - since).coerceAtLeast(0L) / 60_000L).toInt()
        }
        return Snapshot(
            app = app,
            appMinutes = minutes,
            screenOn = screenOn,
            charging = charging,
            since = since,
            lastEventAgeMs = if (lastEventAt <= 0L) -1L else (now - lastEventAt).coerceAtLeast(0L),
        )
    }

    @Synchronized
    fun reset() {
        app = null
        since = 0L
        lastEventAt = 0L
        screenOn = true
        charging = false
    }
}
