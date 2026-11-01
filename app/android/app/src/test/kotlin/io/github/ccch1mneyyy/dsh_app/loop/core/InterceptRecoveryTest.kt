package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 逻辑闭合轮 / 第四阶段 A: what survives a process death, proven by actually rebuilding everything.
 *
 * The previous version of this file did not test recovery. It shared one in-memory ledger across
 * the "restart" (so the ledger never had to be read back from disk), and its ledger helper dropped
 * the store it was handed, so nothing it wrote could ever be read by a second instance. Both bugs
 * made the test green for reasons unrelated to the code under test. They are also why the P0-3
 * defect (NOT_SHOWN still charging cooldown) went unnoticed: the fixtures set cooldownMs = 0.
 *
 * Rules this file now follows, so it cannot drift back:
 *
 *  1. A "restart" constructs a NEW store object over the SAME bytes, a NEW ledger, and a NEW guard.
 *     Nothing is reused. If the code forgets to persist something, this fails.
 *  2. The store is backed by a real string buffer shared by both incarnations, which is as close
 *     to a file as MemorySnapshotStore gets; a test that wants a file uses [FileSnapshotStore]
 *     below.
 *  3. Cooldowns and daily caps are left at their real defaults unless a test is specifically about
 *     them, so a NOT_SHOWN that wrongly charges a cooldown is visible.
 */
class InterceptRecoveryTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private var day = 20_000L
    private val bili = "tv.danmaku.bili"
    private val douyin = "com.ss.android.ugc.aweme"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = day)

    /**
     * One durable buffer standing in for the two files on disk. Sharing the *buffer* is what a
     * restart has in common with the previous run; sharing objects is what it must not do.
     */
    private class Disk {
        var guardBytes: String? = null
        var ledgerBytes: String? = null

        fun guardStore() = ReplayStore({ guardBytes }, { guardBytes = it })
        fun ledgerStore() = ReplayStore({ ledgerBytes }, { ledgerBytes = it })
    }

    /** A SnapshotStore over a shared byte buffer: read returns what the last write left. */
    private class ReplayStore(
        private val readBytes: () -> String?,
        private val writeBytes: (String) -> Unit,
    ) : SnapshotStore {
        override fun read(): SnapshotStore.Read {
            val text = readBytes() ?: return SnapshotStore.Read.Empty
            return try {
                SnapshotStore.Read.Loaded(
                    io.github.ccch1mneyyy.dsh_app.phone.Json.parse(text) as Map<*, *>,
                )
            } catch (e: Throwable) {
                SnapshotStore.Read.Unreadable(e.toString())
            }
        }

        override fun write(map: Map<String, Any?>) {
            writeBytes(io.github.ccch1mneyyy.dsh_app.phone.Json.write(map))
        }
    }

    /** A whole incarnation: its own guard and its own ledger, reading whatever the disk holds. */
    private inner class Incarnation(disk: Disk) {
        val book = InterceptLedgerBook(disk.ledgerStore()).also { it.recover() }
        val guard = InterceptGuard(disk.guardStore(), book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }

        fun armed(cfg: InterceptConfig = InterceptConfig(enabled = true, trainingMs = 0)) = also {
            guard.setConfig(cfg, wall)
        }

        fun blocked(pkg: String = "tv.danmaku.bili"): InterceptDecision.Block {
            val d = guard.onForeground(pkg, env(), wall)
            assertTrue("a configured target blocks", d is InterceptDecision.Block)
            return d as InterceptDecision.Block
        }
    }

    /** Simulates the process dying and the app starting again: brand-new everything. */
    private fun restart(disk: Disk) = Incarnation(disk)

    // ---- 1. killed before the page was ever proved on screen ------------------------------

    @Test
    fun aTriggerThatNeverReachedTheScreenRecoversAsNotShown() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.blocked()
        assertEquals("a trigger is not yet a block", 0L, first.book.state.blockedCount)

        val revived = restart(disk)

        val receipt = revived.book.state.receipts.singleOrNull()
        assertNotNull("the trigger was persisted and is accounted for", receipt)
        assertEquals("nothing was ever on screen", InterceptOutcome.NOT_SHOWN, receipt!!.outcome)
        assertEquals("and it is not counted as a block", 0L, revived.book.state.blockedCount)
        assertNull("no interception is left open", revived.guard.openEventId())
        assertEquals(block.eventId, receipt.eventId)
    }

    // ---- 2. killed after the page was proved on screen -----------------------------------

    @Test
    fun aShownBlockRecoversAsBlocked() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.blocked()
        assertTrue(first.guard.onPageShown(block.eventId, wall))
        assertEquals("that proof is what counts as a block", 1L, first.book.state.blockedCount)

        val revived = restart(disk)

        val receipt = revived.book.state.receipts.singleOrNull()
        assertNotNull(receipt)
        assertEquals("it really did stop the person", InterceptOutcome.BLOCKED, receipt!!.outcome)
        assertEquals("not counted twice", 1L, revived.book.state.blockedCount)
        assertNull("but nothing is left open", revived.guard.openEventId())
    }

    // ---- 3. a finished event must never be re-recorded ------------------------------------

    @Test
    fun aFinishedInterceptionIsNotRecordedAgainByRecovery() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.blocked()
        first.guard.onPageShown(block.eventId, wall)
        assertTrue(first.guard.onExited(block.eventId, wall))
        assertEquals(1, first.book.state.receipts.size)

        val revived = restart(disk)
        assertEquals("one event, one receipt", 1, revived.book.state.receipts.size)
        assertEquals(InterceptOutcome.EXITED, revived.book.state.receipts.first().outcome)
        assertNull(revived.guard.openEventId())
        assertEquals("an exit grants no passage", 0L, revived.book.state.userReleasedCount)
    }

    // ---- 4. the open event must not survive as a ghost -----------------------------------

    @Test
    fun aVanishedPageDoesNotLeaveAnOpenEventBehind() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        first.blocked()

        val revived = restart(disk)
        assertNull("no permanent openEventId", revived.guard.openEventId())
        assertNull("and no stale drill", revived.guard.drill())

        wall += 11 * 60_000L // past the default cooldown, this test is not about it
        val next = revived.guard.onForeground(bili, env(), wall)
        assertTrue("a new interception is possible after recovery", next is InterceptDecision.Block)
    }

    // ---- 5. the ledger is written to the SAME place the next run reads -------------------

    @Test
    fun theLedgerTheNextRunReadsIsTheOneThisRunWrote() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.blocked()
        first.guard.onPageShown(block.eventId, wall)
        assertTrue(first.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall))

        // The whitelist lives in the guard's own store, the receipt in the ledger's. Both must be
        // readable by a process that has nothing but the bytes.
        val revived = restart(disk)
        assertTrue("the whitelist survived", bili in revived.guard.config.whitelist)
        assertEquals("the release survived", 1L, revived.book.state.userReleasedCount)
        assertEquals(InterceptOutcome.RELEASED, revived.book.state.receipts.single().outcome)
    }

    // ---- 6. a NOT_SHOWN must not charge a cooldown (P0-3, why the old fixture hid it) ----

    @Test
    fun aRecoveredNotShownDoesNotChargeACooldown() {
        val disk = Disk()
        // Real defaults: cooldownMs = 2 min, dailyMax = 0. The old fixture set cooldownMs = 0,
        // which is exactly what made P0-3 invisible.
        val first = Incarnation(disk)
        first.guard.setConfig(InterceptConfig(enabled = true, trainingMs = 0), wall)
        first.blocked()

        val revived = restart(disk)
        // One minute later, well inside the default two-minute cooldown: a NOT_SHOWN owes nothing,
        // so the app must be judged on its merits again, not waved through by a cooldown.
        wall += 60_000L
        val again = revived.guard.onForeground(bili, env(), wall)
        assertTrue(
            "a page that was never shown must not put the app in a cooldown",
            again is InterceptDecision.Block,
        )
    }

    // ---- 7. the two stores are independent ----------------------------------------------

    @Test
    fun corruptingOneStoreDoesNotCorruptTheOther() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.blocked()
        first.guard.onPageShown(block.eventId, wall)
        assertTrue(first.guard.onExited(block.eventId, wall))

        disk.ledgerBytes = "{ this is not json"
        val revived = restart(disk)
        // The ledger reports its own damage…
        assertNotNull("the ledger says it is unreadable", revived.book.recoveryIssue)
        // …and the guard state is unaffected: it is a different file.
        assertNull(revived.guard.recoveryIssue)
        assertEquals("the config still loaded", true, revived.guard.config.enabled)
    }
}
