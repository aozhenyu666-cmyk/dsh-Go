package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * P0-A · 拦截页把人交给一手做题。一手判题，DSH Go 只核对"这张凭证是不是这一次拦截的"。
 *
 * Production path only: every guard comes from [InterceptKernel.open] on a real temp directory,
 * and every "survives a restart" case re-opens that directory.
 */
class InterceptYishouHandoffTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private val bili = "tv.danmaku.bili"
    private val douyin = "com.ss.android.ugc.aweme"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = 20_000L)

    private fun tmpDir(): File = kotlin.io.path.createTempDirectory("intercept-yishou").toFile()

    private fun open(dir: File) = InterceptKernel.open(dir, { wall }, { "evt-" + (++seq) })

    private fun fresh(): Pair<File, InterceptKernel.Opened> {
        val dir = tmpDir()
        val k = open(dir)
        k.guard.setConfig(
            InterceptConfig(
                enabled = true,
                targets = listOf(InterceptTarget(bili, "Bilibili"), InterceptTarget(douyin, "Douyin")),
                trainingMs = 0,
                cooldownMs = 0,
            ),
            wall,
        )
        return dir to k
    }

    /** Triggered and proved on screen: the only state a hand-off may start from. */
    private fun shownBlock(g: InterceptGuard, pkg: String = bili): InterceptDecision.Block {
        val d = g.onForeground(pkg, env(), wall)
        assertTrue("a configured target blocks: $d", d is InterceptDecision.Block)
        val b = d as InterceptDecision.Block
        assertTrue(g.onPageShown(b.eventId, wall))
        return b
    }

    // ---- the happy path -------------------------------------------------------------------

    @Test
    fun a_verified_answer_with_the_right_secret_lets_the_app_through_once() {
        val (dir, k) = fresh()
        val b = shownBlock(k.guard)
        val nonce = k.guard.beginHandoff(b.eventId, wall)
        assertNotNull("a shown page can hand off", nonce)
        assertTrue(k.guard.handoffActive(b.eventId))

        wall += 60_000L
        assertTrue(k.guard.onExternalPass(b.eventId, nonce!!, 15, "card:42", wall))
        assertNull(k.guard.storageError)
        assertNull("the interception is over", k.guard.openEventId())

        val receipt = k.ledger.state.receipts.last()
        assertEquals(InterceptOutcome.RELEASED, receipt.outcome)
        assertEquals(InterceptGuard.RELEASE_YISHOU, receipt.releasedBy)
        assertEquals("the evidence is kept", "yishou:card:42", receipt.reason)
        assertEquals(wall + 15 * 60_000L, receipt.releasedUntilWall)

        val during = k.guard.onForeground(bili, env(), wall + 1_000L)
        assertTrue("the app is let through for the pass", during is InterceptDecision.Allow)

        assertFalse("the same pass cannot be spent twice", k.guard.onExternalPass(b.eventId, nonce, 15, null, wall + 2_000L))

        val again = open(dir)
        assertEquals("the release survives a restart", 1, again.ledger.state.receipts.count {
            it.releasedBy == InterceptGuard.RELEASE_YISHOU
        })
        assertTrue(again.guard.onForeground(bili, env(), wall + 3_000L) is InterceptDecision.Allow)
    }

    // ---- what the secret protects -----------------------------------------------------------

    @Test
    fun a_claim_with_the_wrong_secret_or_event_grants_nothing() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        val nonce = k.guard.beginHandoff(b.eventId, wall)!!

        assertFalse("wrong secret", k.guard.onExternalPass(b.eventId, "0".repeat(32), 15, null, wall))
        assertFalse("wrong event", k.guard.onExternalPass("evt-999", nonce, 15, null, wall))
        assertFalse("zero minutes", k.guard.onExternalPass(b.eventId, nonce, 0, null, wall))
        assertFalse("too many minutes", k.guard.onExternalPass(b.eventId, nonce, InterceptGuard.MAX_EXTERNAL_PASS_MIN + 1, null, wall))
        assertEquals("still open, nothing released", b.eventId, k.guard.openEventId())
        assertTrue(k.ledger.state.receipts.none { it.outcome == InterceptOutcome.RELEASED })
    }

    @Test
    fun the_page_cannot_name_the_yishou_door_itself() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        k.guard.beginHandoff(b.eventId, wall)
        assertFalse(k.guard.onReleased(b.eventId, InterceptGuard.RELEASE_YISHOU, wall))
        assertEquals(b.eventId, k.guard.openEventId())
    }

    @Test
    fun a_claim_without_a_handoff_grants_nothing() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        assertFalse(k.guard.onExternalPass(b.eventId, InterceptGuard.newNonce(), 15, null, wall))
    }

    @Test
    fun a_page_that_was_never_shown_cannot_hand_off() {
        val (_, k) = fresh()
        val d = k.guard.onForeground(bili, env(), wall) as InterceptDecision.Block
        assertNull("P0-5: nobody was asked anything", k.guard.beginHandoff(d.eventId, wall))
    }

    @Test
    fun handing_off_twice_keeps_the_same_secret_and_start_time() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        val first = k.guard.beginHandoff(b.eventId, wall)
        val deadline = k.guard.handoffDeadline()
        wall += 30_000L
        assertEquals(first, k.guard.beginHandoff(b.eventId, wall))
        assertEquals("tapping again does not buy more time", deadline, k.guard.handoffDeadline())
    }

    // ---- leaving the training is not finishing it ---------------------------------------------

    @Test
    fun going_back_to_the_target_instead_of_answering_blocks_it_again() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        k.guard.beginHandoff(b.eventId, wall)

        wall += 10_000L
        val d = k.guard.onForeground(bili, env(), wall)
        assertTrue("not let through: $d", d is InterceptDecision.Block)
        val old = k.ledger.state.receipts.single { it.eventId == b.eventId }
        assertEquals(InterceptOutcome.EXITED, old.outcome)
        assertEquals(InterceptGuard.REASON_LEFT_TRAINING, old.reason)
    }

    @Test
    fun opening_another_target_during_the_handoff_is_intercepted_too() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        k.guard.beginHandoff(b.eventId, wall)

        wall += 10_000L
        val d = k.guard.onForeground(douyin, env(), wall)
        assertTrue("REASON_ANOTHER_OPEN must not become a free pass: $d", d is InterceptDecision.Block)
    }

    @Test
    fun yishou_and_dsh_go_in_front_do_not_end_the_handoff() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        k.guard.beginHandoff(b.eventId, wall)
        assertEquals(InterceptDecision.Ignore, k.guard.onForeground(YishouProtocol.YISHOU_PACKAGE, env(), wall + 1_000L))
        assertEquals(InterceptDecision.Ignore, k.guard.onForeground("io.github.ccch1mneyyy.dsh_app", env(), wall + 2_000L))
        assertTrue(k.guard.handoffActive(b.eventId))
    }

    @Test
    fun coming_back_to_the_page_cancels_the_handoff_and_the_old_secret() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        val nonce = k.guard.beginHandoff(b.eventId, wall)!!
        assertTrue(k.guard.cancelHandoff(b.eventId, wall + 5_000L))
        assertFalse(k.guard.handoffActive(b.eventId))
        assertFalse("a cancelled secret is dead", k.guard.onExternalPass(b.eventId, nonce, 15, null, wall + 6_000L))
        assertEquals(b.eventId, k.guard.openEventId())
    }

    // ---- running out of time ------------------------------------------------------------------

    @Test
    fun a_handoff_that_runs_out_is_blocked_never_released() {
        val (_, k) = fresh()
        val b = shownBlock(k.guard)
        val nonce = k.guard.beginHandoff(b.eventId, wall)!!

        assertFalse("not yet", k.guard.expireHandoff(b.eventId, wall + InterceptGuard.HANDOFF_TTL_MS - 1))
        wall += InterceptGuard.HANDOFF_TTL_MS
        assertFalse("a late answer does not count", k.guard.onExternalPass(b.eventId, nonce, 15, null, wall))
        assertTrue(k.guard.expireHandoff(b.eventId, wall))
        val r = k.ledger.state.receipts.single { it.eventId == b.eventId }
        assertEquals(InterceptOutcome.BLOCKED, r.outcome)
        assertEquals(InterceptGuard.REASON_TRAINING_TIMEOUT, r.reason)
        assertTrue("and the app is intercepted again", k.guard.onForeground(bili, env(), wall + 1_000L) is InterceptDecision.Block)
    }

    // ---- process death ------------------------------------------------------------------------

    @Test
    fun a_process_death_during_the_handoff_records_a_block_and_kills_the_secret() {
        val (dir, k) = fresh()
        val b = shownBlock(k.guard)
        val nonce = k.guard.beginHandoff(b.eventId, wall)!!

        val again = open(dir)
        assertNull("recovery settles the open interception", again.guard.openEventId())
        assertEquals(InterceptOutcome.BLOCKED, again.ledger.state.receipts.single { it.eventId == b.eventId }.outcome)
        assertFalse(again.guard.handoffActive(b.eventId))
        assertFalse("a pass that arrives after the restart is refused", again.guard.onExternalPass(b.eventId, nonce, 15, null, wall + 1_000L))
    }

    @Test
    fun the_handoff_secret_is_persisted_with_the_interception() {
        val (dir, k) = fresh()
        val b = shownBlock(k.guard)
        k.guard.beginHandoff(b.eventId, wall)
        val snap = File(dir, InterceptRepository.FILE_NAME).readText()
        assertTrue("one atomic snapshot carries the hand-off", snap.contains("handoffNonce"))
    }

    // ---- protocol shape -----------------------------------------------------------------------

    @Test
    fun parse_pass_accepts_only_the_v1_shape() {
        val good = mapOf<String, Any?>(
            YishouProtocol.EXTRA_VERSION to 1, YishouProtocol.EXTRA_EVENT_ID to "evt-1",
            YishouProtocol.EXTRA_NONCE to "a".repeat(32), YishouProtocol.EXTRA_PASS_MINUTES to 15,
            YishouProtocol.EXTRA_REF to "card:1",
        )
        assertEquals(YishouProtocol.PassClaim("evt-1", "a".repeat(32), 15, "card:1"), YishouProtocol.parsePass { good[it] })
        assertNull("other version", YishouProtocol.parsePass { (good + (YishouProtocol.EXTRA_VERSION to 2))[it] })
        assertNull("short nonce", YishouProtocol.parsePass { (good + (YishouProtocol.EXTRA_NONCE to "abc"))[it] })
        assertNull("no minutes", YishouProtocol.parsePass { (good - YishouProtocol.EXTRA_PASS_MINUTES)[it] })
        assertNull("no event", YishouProtocol.parsePass { (good - YishouProtocol.EXTRA_EVENT_ID)[it] })
    }

    @Test
    fun nonces_are_long_hex_and_different() {
        val a = InterceptGuard.newNonce()
        val b = InterceptGuard.newNonce()
        assertEquals(32, a.length)
        assertTrue(a.all { it in "0123456789abcdef" })
        assertTrue(a != b)
    }
}
