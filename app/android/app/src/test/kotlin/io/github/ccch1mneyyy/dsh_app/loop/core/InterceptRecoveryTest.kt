package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 逻辑闭合轮: what a killed process is allowed to claim it did.
 *
 * Before this round `recover()` wrote **BLOCKED** for any open interception, whether or not the page
 * had ever been proved on screen. So "the person opened Bilibili and the app died before the block
 * page came up" was recorded as a block — a receipt for something that never happened. The state now
 * carries `openShownAt` (the adapter's attached+shown+laid-out+focused proof), and recovery reads it:
 *
 *   triggered, never shown, process killed  -> NOT_SHOWN   (nothing was owed, nothing counted)
 *   shown, process killed                   -> BLOCKED     (it really did stop the person)
 *
 * Both paths are exercised here, on the same store, so the difference cannot drift.
 */
class InterceptRecoveryTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private var day = 20_000L
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = day)

    private fun ledgerBook(store: MemorySnapshotStore) =
        InterceptLedgerBook(MemorySnapshotStore()).also { it.recover() }

    private fun guard(store: MemorySnapshotStore, book: InterceptLedgerBook) =
        InterceptGuard(store, book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }

    private fun InterceptGuard.armed() = also {
        it.setConfig(InterceptConfig(enabled = true, trainingMs = 0, cooldownMs = 0, dailyMax = 0), wall)
    }

    private fun blocked(g: InterceptGuard): InterceptDecision.Block {
        val d = g.onForeground(bili, env(), wall)
        assertTrue(d is InterceptDecision.Block)
        return d as InterceptDecision.Block
    }

    // ---- 1. killed before the page was ever proved on screen -----------------------------

    @Test
    fun aTriggerThatNeverReachedTheScreenRecoversAsNotShown() {
        val store = MemorySnapshotStore()
        val book = ledgerBook(store)
        val first = guard(store, book).armed()
        val block = blocked(first) // triggered; onPageShown is never called
        assertEquals("a trigger is not yet a block", 0L, book.state.blockedCount)

        // The process dies here. A fresh guard reads the same store.
        val revived = guard(store, book).also { it.recover(wall + 1_000L) }

        val receipt = book.state.receipts.singleOrNull()
        assertNotNull("the trigger is accounted for, not forgotten", receipt)
        assertEquals(
            "nothing was ever on screen, so nothing was shown",
            InterceptOutcome.NOT_SHOWN,
            receipt!!.outcome,
        )
        assertEquals("and it is not counted as a block", 0L, book.state.blockedCount)
        assertNull("no interception is left open", revived.openEventId())
        assertEquals(block.eventId, receipt.eventId)
    }

    // ---- 2. killed after the page was proved on screen -----------------------------------

    @Test
    fun aShownBlockRecoversAsBlocked() {
        val store = MemorySnapshotStore()
        val book = ledgerBook(store)
        val first = guard(store, book).armed()
        val block = blocked(first)
        assertTrue("the page proved it was on screen", first.onPageShown(block.eventId, wall))
        assertEquals("that proof is what counts as a block", 1L, book.state.blockedCount)

        val revived = guard(store, book).also { it.recover(wall + 1_000L) }

        val receipt = book.state.receipts.singleOrNull()
        assertNotNull(receipt)
        assertEquals("it really did stop the person", InterceptOutcome.BLOCKED, receipt!!.outcome)
        assertEquals("the block is not counted twice", 1L, book.state.blockedCount)
        assertNull("but nothing is left open", revived.openEventId())
    }

    // ---- 3. a finished event must never be re-recorded ------------------------------------

    @Test
    fun aFinishedInterceptionIsNotRecordedAgainByRecovery() {
        val store = MemorySnapshotStore()
        val book = ledgerBook(store)
        val first = guard(store, book).armed()
        val block = blocked(first)
        first.onPageShown(block.eventId, wall)
        assertTrue(first.onExited(block.eventId, wall))
        val afterExit = book.state.receipts.size
        assertEquals(1, afterExit)

        // Nothing is open any more, so recovery has nothing to settle.
        val revived = guard(store, book).also { it.recover(wall + 5_000L) }
        assertEquals("one event, one receipt", afterExit, book.state.receipts.size)
        assertEquals(InterceptOutcome.EXITED, book.state.receipts.first().outcome)
        assertNull(revived.openEventId())
    }

    // ---- 4. the open event must not survive as a ghost -----------------------------------

    @Test
    fun aVanishedPageDoesNotLeaveAnOpenEventBehind() {
        val store = MemorySnapshotStore()
        val book = ledgerBook(store)
        val first = guard(store, book).armed()
        blocked(first)
        // Recovery itself is the only thing that runs after a kill; it must clear the slot.
        val revived = guard(store, book).also { it.recover(wall + 1_000L) }
        assertNull("no permanent openEventId", revived.openEventId())
        assertNull("and no stale drill", revived.drill())

        // The app is usable again: a fresh foreground reading is decided normally.
        val next = revived.onForeground(bili, env(), wall + 2_000L)
        assertTrue("a new interception is possible after recovery", next is InterceptDecision.Block)
    }
}
