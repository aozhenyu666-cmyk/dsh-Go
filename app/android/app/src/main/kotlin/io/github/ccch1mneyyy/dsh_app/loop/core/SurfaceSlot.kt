package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * The one visible DSH surface at a time.
 *
 * Two features can want the screen at the same moment: 主动搭话 shows a page from the coordinator,
 * 娱乐拦截 shows a page because the person just opened a target app. They are two activities with
 * two task affinities, so without a shared slot both can be on screen at once - the person gets two
 * DSH pages stacked, and one of them records an outcome the other never saw.
 *
 * This is deliberately tiny and pure: it decides *who* holds the screen, nothing else. No timer, no
 * queue, no policy - every caller keeps its own book. [owner] names the feature ("proactive",
 * "intercept"); [token] names the surface instance (a coordinator token, an intercept eventId), so
 * a stale release can never free a surface it does not own.
 */
class SurfaceSlot {

    private var owner: String? = null
    private var token: String? = null
    private var since: Long = 0L

    /** Who holds the screen now; null when nothing is showing. */
    val holder: String? get() = owner

    /** The surface instance that holds it, for the stale-release guard. */
    val holderToken: String? get() = token

    fun isFree(): Boolean = owner == null

    fun isHeldBy(who: String): Boolean = owner == who

    /**
     * Take the slot for [who]/[token]. True when it is free, or already held by the same instance
     * (a repeated Present for the same token is not a conflict).
     */
    fun claim(who: String, token: String, now: Long): Boolean = when {
        owner == null -> {
            this.owner = who
            this.token = token
            since = now
            true
        }
        owner == who && this.token == token -> true
        else -> false
    }

    /**
     * Give the slot back. Only the holder can release, and only for the instance that took it:
     * a page's late onDestroy must not free the surface its replacement already claimed.
     */
    fun release(who: String, token: String?): Boolean {
        if (owner != who) return false
        if (token != null && this.token != token) return false
        owner = null
        this.token = null
        since = 0L
        return true
    }

    /** Since when the current holder has had it; 0 when free. */
    fun heldSince(): Long = since

    fun clear() {
        owner = null
        token = null
        since = 0L
    }
}

/**
 * The process-wide slot. Android adapters go through this object; the rules themselves stay in
 * [SurfaceSlot] so they can be tested without Android.
 */
object VisibleSurface {
    const val OWNER_PROACTIVE = "proactive"
    const val OWNER_INTERCEPT = "intercept"

    private val slot = SurfaceSlot()

    fun claim(owner: String, token: String, now: Long = System.currentTimeMillis()): Boolean =
        slot.claim(owner, token, now)

    fun release(owner: String, token: String?): Boolean = slot.release(owner, token)

    fun holder(): String? = slot.holder

    fun holderToken(): String? = slot.holderToken

    fun isHeldBy(owner: String): Boolean = slot.isHeldBy(owner)

    fun isFree(): Boolean = slot.isFree()
}
