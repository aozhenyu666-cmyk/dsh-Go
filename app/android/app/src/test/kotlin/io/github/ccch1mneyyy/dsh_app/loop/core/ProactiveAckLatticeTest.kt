package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * 逻辑闭合轮: the five states of 主动搭话, walked end to end so a change to any single edge is caught.
 *
 *   NOT_DELIVERED   never reached a surface
 *   UNCONFIRMED     reached a surface, nobody confirmed seeing it
 *   ACKED           「我看到了」 pressed, reply window still open
 *   IGNORED_SEEN    ACKED, then the whole reply window passed unanswered
 *   RESPONDED       the person actually replied
 *
 * The two edges round 4 left unproven, and which this file pins:
 *  * UNCONFIRMED must never decay into IGNORED_SEEN — the person never said they saw it, so there
 *    is nothing to ignore, and punishing it would make the streak depend on a page nobody looked at;
 *  * only an ACKED event can ever reach IGNORED_SEEN, because only the ack starts the reply window.
 *
 * AckStateMachineTest already covers the individual reports; this walks the whole lattice in one
 * place so the *relations* between the states are asserted, not just each state on its own.
 */
class ProactiveAckLatticeTest {
    private var now = 1_793_340_000_000L
    private var seq = 0
    private val window = 20 * 60_000L

    private fun coordinator(cfg: CoordinatorConfig = CoordinatorConfig(replyWindowMs = window)) =
        Coordinator(MemorySnapshotStore(), cfg, { now }, { "id-" + (++seq) })

    private fun request(id: String = "e" + (++seq)) = EventRequest(
        eventId = id, source = "SCHEDULER", kind = "random_chat", dedupeKey = id,
        createdAt = now, fallbackText = "hi",
    )

    /** Submit and prove the page on screen; returns (eventId, token). */
    private fun Coordinator.showPage(): Pair<String, String> {
        val (submit, step) = submit(request())
        val id = (submit as Submit.Queued).eventId
        val token = step.commands.filterIsInstance<Command.Present>().single().token
        onSurface(token, SurfaceReport.Posted)
        onSurface(token, SurfaceReport.Shown)
        return id to token
    }

    // ---- 1. never delivered ----------------------------------------------------------------

    @Test
    fun anEventThatNeverReachesASurfaceIsNotDelivered() {
        // No accessibility, no notifications, screen off: the gate cannot offer any surface.
        val c = coordinator().also { it.recover(Gate(featureEnabled = true, a11yConnected = false, notificationsAllowed = false)) }
        val (submit, _) = c.submit(request())
        val id = (submit as Submit.Queued).eventId
        val e = c.find(id)
        assertNotNull(e)
        assertEquals(
            "nothing was ever on screen, so nothing was delivered",
            Engagement.NOT_DELIVERED,
            e!!.engagement,
        )
    }

    // ---- 2. shown, never confirmed -----------------------------------------------------------

    @Test
    fun aPageShownButNeverConfirmedStaysUnconfirmedForever() {
        val c = coordinator().also { it.recover(Gate()) }
        val (id, _) = c.showPage()

        // Well past both the interaction timeout and the reply window.
        now += 60 * 60_000L
        c.tick()

        val e = c.find(id)
        assertNotNull(e)
        val closed = e!!
        assertEquals(
            "nobody said they saw it, so there is nothing to ignore",
            Engagement.UNCONFIRMED,
            closed.engagement,
        )
        assertNull("no ack was ever recorded", closed.acknowledgedAt)
    }

    // ---- 3. acked, window open --------------------------------------------------------------

    @Test
    fun anAckedPageIsAckedWhileTheReplyWindowIsOpen() {
        val c = coordinator().also { it.recover(Gate()) }
        val (id, token) = c.showPage()
        c.onSurface(token, SurfaceReport.Acked)

        val e = c.find(id)
        assertNotNull(e)
        assertNotNull("the click is recorded as a fact", e!!.acknowledgedAt)
        assertNull("but it is not an answer", e.respondedAt)
        assertEquals(Engagement.ACKED, e.engagement)
    }

    // ---- 4. acked, window passed -> IGNORED_SEEN --------------------------------------------

    @Test
    fun ackedThenSilentForTheWholeWindowBecomesIgnoredSeen() {
        val c = coordinator().also { it.recover(Gate()) }
        val (id, token) = c.showPage()
        c.onSurface(token, SurfaceReport.Acked)

        // Past the reply window: the kernel closes an acked-but-unanswered event itself.
        now += window + 1_000L
        c.tick()

        val e = c.find(id)
        assertNotNull(e)
        assertEquals(
            "acked, then the whole window without an answer",
            Engagement.IGNORED_SEEN,
            e!!.engagement,
        )
    }

    // ---- 5. replying is RESPONDED -----------------------------------------------------------

    @Test
    fun replyingAfterAnAckIsResponded() {
        val c = coordinator().also { it.recover(Gate()) }
        val (id, token) = c.showPage()
        c.onSurface(token, SurfaceReport.Acked)
        c.onSurface(token, SurfaceReport.Answered("ok"))
        val e = c.find(id)
        assertNotNull(e)
        assertEquals(Engagement.RESPONDED, e!!.engagement)
        assertEquals(Outcome.RESPONDED, e.outcome)
    }

    // ---- 6. the relation between the two silent states --------------------------------------

    @Test
    fun onlyAnAckedEventCanReachIgnoredSeen() {
        // Same elapsed time as test 4, but no Ack: must stay UNCONFIRMED.
        val unacked = coordinator().also { it.recover(Gate()) }
        val (aId, _) = unacked.showPage()
        now += window + 1_000L
        unacked.tick()
        val a = unacked.find(aId)
        assertNotNull(a)
        assertEquals(Engagement.UNCONFIRMED, a!!.engagement)

        // And with the Ack it does become IGNORED_SEEN — same clock movement, one click apart.
        val acked = coordinator().also { it.recover(Gate()) }
        val (bId, bToken) = acked.showPage()
        acked.onSurface(bToken, SurfaceReport.Acked)
        acked.tick()
        now += window + 1_000L
        acked.tick()
        val b = acked.find(bId)
        assertNotNull(b)
        assertEquals(Engagement.IGNORED_SEEN, b!!.engagement)
    }
}
