package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * 生产路径回归 —— 每一行都**经由 [InterceptKernel.open] 打开一个真实临时目录**。
 *
 * 上一轮的盲区是"只测自己手写构造的对象"：24 项测试全绿，而三个机制在生产里从未执行过。
 * 所以本文件禁止使用 MemorySnapshotStore，也不手工 new InterceptGuard ——
 * 只走 InterceptRuntime.ensure() 在生产里调用的那个入口。
 */
class InterceptProductionPathTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = 20_000L)

    private fun tmpDir(): File = kotlin.io.path.createTempDirectory("intercept-production").toFile()

    private fun open(dir: File) = InterceptKernel.open(dir, { wall }, { "evt-" + (++seq) })

    private fun configure(g: InterceptGuard) {
        g.setConfig(
            InterceptConfig(
                enabled = true,
                targets = listOf(InterceptTarget(bili, "Bilibili")),
                trainingMs = 0,
                cooldownMs = 0,
            ),
            wall,
        )
    }

    private fun trigger(g: InterceptGuard): InterceptDecision.Block {
        val d = g.onForeground(bili, env(), wall)
        assertTrue("a configured target blocks: " + d, d is InterceptDecision.Block)
        return d as InterceptDecision.Block
    }

    private fun solve(g: InterceptGuard, b: InterceptDecision.Block) {
        val order = if (b.drill.ascending) b.drill.candidates.sorted() else b.drill.candidates.sortedDescending()
        for (v in order) g.tapDrill(b.eventId, v)
    }

    // ---- F1: the settings page pause must not poison the snapshot --------------------

    @Test
    fun a_settings_pause_commits_and_survives_a_restart() {
        val dir = tmpDir()
        val k = open(dir)
        configure(k.guard)

        assertTrue("the settings pause is accepted", k.guard.onPaused(null, InterceptGuard.DEFAULT_PAUSE_MS, wall));
        assertNull(
            "a settings pause writes no trigger, so it must not break the snapshot: " + k.guard.storageError,
            k.guard.storageError,
        )

        val again = open(dir)
        assertTrue("the pause is still in force after a restart", again.guard.config.pauseUntilWall > wall)
        assertNull(again.guard.storageError)
    }

    @Test
    fun three_pauses_then_a_block_then_a_whitelist_all_survive_a_restart() {
        val dir = tmpDir()
        val k = open(dir)
        configure(k.guard)

        assertTrue(k.guard.onPaused(null, 60_000L, wall));
        assertTrue(k.guard.onPaused(null, 60_000L, wall + 1_000L));
        assertTrue(k.guard.onPaused(null, 60_000L, wall + 2_000L));
        // Resume so the next foreground reading can actually intercept.
        k.guard.setConfig(k.guard.config.copy(pauseUntilWall = 0), wall + 3_000L)

        val block = trigger(k.guard)
        assertTrue(k.guard.onPageShown(block.eventId, wall + 4_000L))
        assertTrue(k.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall + 5_000L))
        assertNull("no commit was rejected along the way: " + k.guard.storageError, k.guard.storageError)

        val again = open(dir)
        assertTrue("the whitelist survived", bili in again.guard.config.whitelist)
        assertNull("and nothing was left in an error state", again.guard.storageError)
    }

    // ---- F2: a failed commit must not leave memory ahead of the disk --------------------
    //
    // Commit failure is injected at the store, but everything is still built by InterceptKernel.open
    // on a real temp directory: the point is to exercise the same seam production uses.

    /** Wraps the real snapshot file and can refuse the next write. */
    private class FailingStore(private val real: SnapshotStore) : SnapshotStore {
        var failNextWrite = false
        var writes = 0
        override fun read(): SnapshotStore.Read = real.read()
        override fun write(map: Map<String, Any?>) {
            writes++
            if (failNextWrite) {
                failNextWrite = false
                throw java.io.IOException("injected write failure")
            }
            real.write(map)
        }
    }

    private class Rig(val dir: File, val store: FailingStore, val opened: InterceptKernel.Opened)

    private fun openWithFaults(dir: File): Rig {
        var created: FailingStore? = null
        val o = InterceptKernel.open(dir, { wall }, { "evt-" + (++seq) }) { f ->
            FailingStore(AtomicJsonFile(f)).also { created = it }
        }
        return Rig(dir, created!!, o)
    }

    @Test
    fun a_failed_release_rolls_back_and_returns_false() {
        val rig = openWithFaults(tmpDir())
        configure(rig.opened.guard)
        val b = trigger(rig.opened.guard)
        assertTrue(rig.opened.guard.onPageShown(b.eventId, wall))

        val configBefore = rig.opened.guard.config
        val stateBefore = rig.opened.guard.state
        val ledgerBefore = rig.opened.ledger.state
        val appliedBefore = rig.opened.ledger.appliedIds()

        rig.store.failNextWrite = true
        val ok = rig.opened.guard.onReleased(b.eventId, InterceptGuard.RELEASE_WHITELIST, wall + 1_000L)

        assertTrue("a commit that did not land must report failure", !ok)
        assertEquals("config rolled back", configBefore, rig.opened.guard.config)
        assertEquals("guard state rolled back", stateBefore, rig.opened.guard.state)
        assertEquals("ledger state rolled back", ledgerBefore, rig.opened.ledger.state)
        assertEquals("applied ids rolled back", appliedBefore, rig.opened.ledger.appliedIds())
    }

    @Test
    fun a_failed_exit_rolls_back_and_returns_false() {
        val rig = openWithFaults(tmpDir())
        configure(rig.opened.guard)
        val b = trigger(rig.opened.guard)
        assertTrue(rig.opened.guard.onPageShown(b.eventId, wall))
        val stateBefore = rig.opened.guard.state
        val ledgerBefore = rig.opened.ledger.state

        rig.store.failNextWrite = true
        assertTrue("an exit that did not land must report failure", !rig.opened.guard.onExited(b.eventId, wall + 1_000L))
        assertEquals(stateBefore, rig.opened.guard.state)
        assertEquals(ledgerBefore, rig.opened.ledger.state)
    }

    @Test
    fun a_failed_settings_pause_rolls_back_and_returns_false() {
        val rig = openWithFaults(tmpDir())
        configure(rig.opened.guard)
        val configBefore = rig.opened.guard.config
        val ledgerBefore = rig.opened.ledger.state

        rig.store.failNextWrite = true
        assertTrue("a pause that did not land must report failure", !rig.opened.guard.onPaused(null, 60_000L, wall))
        assertEquals("the pause window was not applied", configBefore, rig.opened.guard.config)
        assertEquals(ledgerBefore, rig.opened.ledger.state)
    }

    @Test
    fun a_failed_set_config_rolls_back_and_reports_the_old_one() {
        val rig = openWithFaults(tmpDir())
        configure(rig.opened.guard)
        val before = rig.opened.guard.config

        rig.store.failNextWrite = true
        val returned = rig.opened.guard.setConfig(before.copy(enabled = false), wall + 1_000L)

        assertEquals("setConfig must hand back the config that is still in force", before, returned)
        assertEquals(before, rig.opened.guard.config)
    }

    @Test
    fun a_failed_drill_tap_rolls_back_and_returns_false() {
        val rig = openWithFaults(tmpDir())
        configure(rig.opened.guard)
        val b = trigger(rig.opened.guard)
        assertTrue(rig.opened.guard.onPageShown(b.eventId, wall))
        val stateBefore = rig.opened.guard.state

        rig.store.failNextWrite = true
        assertTrue(
            "a drill tap that did not land must report failure",
            !rig.opened.guard.tapDrill(b.eventId, b.drill.candidates.first()),
        )
        assertEquals(stateBefore, rig.opened.guard.state)
    }

    @Test
    fun a_failed_unavailable_rolls_back_and_returns_false() {
        val rig = openWithFaults(tmpDir())
        configure(rig.opened.guard)
        val b = trigger(rig.opened.guard)
        val stateBefore = rig.opened.guard.state
        val ledgerBefore = rig.opened.ledger.state

        rig.store.failNextWrite = true
        assertTrue(
            "a NOT_SHOWN that did not land must report failure",
            !rig.opened.guard.onUnavailable(b.eventId, "no_visibility_proof", wall + 1_000L),
        )
        assertEquals(stateBefore, rig.opened.guard.state)
        assertEquals(ledgerBefore, rig.opened.ledger.state)
    }

    // ---- F4: a fallback to the old two-file mode must be visible, not silent -----------

    @Test
    fun falling_back_to_legacy_files_carries_a_reason_the_ui_can_show() {
        val dir = tmpDir()
        // Build a legacy pair that contradicts itself: a whitelist with no release behind it.
        val oldLedger = InterceptLedgerBook(AtomicJsonFile(File(dir, "ledger.json")))
        oldLedger.recover()
        val oldGuard = InterceptGuard(
            AtomicJsonFile(File(dir, "guard.json")), oldLedger,
            { wall }, ids = { "old-" + (++seq) },
        )
        oldGuard.recover(wall)
        configure(oldGuard)
        val block = oldGuard.onForeground(bili, env(), wall) as InterceptDecision.Block
        oldGuard.onPageShown(block.eventId, wall)
        assertTrue(oldGuard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall))
        // Keep the ledger readable but rewrite it so it records a trigger and no release at all:
        // the whitelist entry in guard.json is then orphaned, which is the contradiction the
        // whitelist check exists to catch (and the message the UI has to show).
        File(dir, "ledger.json").writeText(
            io.github.ccch1mneyyy.dsh_app.phone.Json.write(
                linkedMapOf(
                    "version" to 1,
                    "ledger" to linkedMapOf(
                        "triggerCount" to 1L,
                        "blockedCount" to 1L,
                        "userReleasedCount" to 0L,
                        "userExitedCount" to 0L,
                        "pausedCount" to 0L,
                        "receipts" to listOf(
                            linkedMapOf(
                                "eventId" to block.eventId,
                                "packageName" to bili,
                                "triggeredAt" to 1L,
                                "endedAt" to 2L,
                                "outcome" to "BLOCKED",
                                "reason" to "x",
                                "releasedBy" to null,
                                "releasedUntilWall" to 0L,
                            ),
                        ),
                        "lastRecordedAt" to 0L,
                    ),
                    "applied" to listOf("trigger:" + block.eventId, "blocked:" + block.eventId, "end:" + block.eventId),
                ),
            ),
        )

        val k = open(dir)
        assertTrue("fell back: " + k.migration, k.migration is InterceptMigration.Result.RecoveryRequired)
        assertNull("no snapshot in use", k.repo)
        assertNotNull("the person must be told why: the UI shows this string", k.recoveryIssue)
        assertTrue(
            "the reason names the whitelist, so the message is actionable: " + k.recoveryIssue,
            k.recoveryIssue!!.contains("whitelist"),
        )
    }

    // ---- F7: the production path regression pack ---------------------------------------
    //
    // Every case below opens a real temp directory through InterceptKernel.open, asserts the commit
    // succeeded, then re-opens and asserts the state survived. A case that only checks memory would
    // pass even if nothing was written - which is what this file exists to prevent.

    private fun openFresh(): Pair<File, InterceptKernel.Opened> {
        val dir = tmpDir()
        val k = open(dir)
        configure(k.guard)
        return dir to k
    }

    @Test
    fun p1_training_release_grants_a_window_and_one_receipt() {
        val (dir, k) = openFresh()
        val b = trigger(k.guard)
        assertTrue(k.guard.onPageShown(b.eventId, wall))
        solve(k.guard, b)
        assertTrue(k.guard.onReleased(b.eventId, InterceptGuard.RELEASE_TRAINING, wall + 1_000L))
        assertNull(k.guard.storageError)

        val again = open(dir)
        assertEquals("one RELEASED receipt", 1, again.ledger.state.receipts.count {
            it.outcome == InterceptOutcome.RELEASED
        })
        assertEquals(1L, again.ledger.state.userReleasedCount)
        assertNull(again.guard.storageError)
    }

    @Test
    fun p2_whitelist_survives_a_restart() {
        val (dir, k) = openFresh()
        val b = trigger(k.guard)
        assertTrue(k.guard.onPageShown(b.eventId, wall))
        assertTrue(k.guard.onReleased(b.eventId, InterceptGuard.RELEASE_WHITELIST, wall + 1_000L))
        assertNull(k.guard.storageError)

        assertTrue("the whitelist survived", bili in open(dir).guard.config.whitelist)
    }

    @Test
    fun p3_page_pause_survives_a_restart() {
        val (dir, k) = openFresh()
        val b = trigger(k.guard)
        assertTrue(k.guard.onPageShown(b.eventId, wall))
        assertTrue(k.guard.onPaused(b.eventId, 10 * 60_000L, wall + 1_000L))
        assertNull(k.guard.storageError)

        assertTrue("the pause window survived", open(dir).guard.config.pauseUntilWall > wall)
    }

    @Test
    fun p4_resuming_clears_the_pause_window() {
        val (dir, k) = openFresh()
        assertTrue(k.guard.onPaused(null, 10 * 60_000L, wall))
        k.guard.setConfig(k.guard.config.copy(pauseUntilWall = 0), wall + 1_000L)
        assertNull(k.guard.storageError)

        assertEquals("resume cleared it", 0L, open(dir).guard.config.pauseUntilWall)
    }

    @Test
    fun p5_a_page_that_never_appeared_refunds_the_charge() {
        val (dir, k) = openFresh()
        val b = trigger(k.guard)
        assertTrue(k.guard.onUnavailable(b.eventId, "no_visibility_proof", wall + 1_000L))
        assertNull(k.guard.storageError)

        val again = open(dir)
        assertEquals("nothing was blocked", 0L, again.ledger.state.blockedCount)
        assertEquals("and no cooldown is running", 0L, again.guard.state.lastTriggerAt)
    }

    @Test
    fun p6_a_process_death_before_the_proof_records_not_shown() {
        val dir = tmpDir()
        val first = open(dir)
        configure(first.guard)
        trigger(first.guard)   // never shown, then everything is dropped

        val again = open(dir)
        assertEquals(1, again.ledger.state.receipts.size)
        assertEquals(InterceptOutcome.NOT_SHOWN, again.ledger.state.receipts.first().outcome)
        assertEquals(0L, again.ledger.state.blockedCount)
    }

    @Test
    fun p7_a_process_death_after_the_proof_records_blocked() {
        val dir = tmpDir()
        val first = open(dir)
        configure(first.guard)
        val b = trigger(first.guard)
        assertTrue(first.guard.onPageShown(b.eventId, wall))

        val again = open(dir)
        assertEquals(1, again.ledger.state.receipts.size)
        assertEquals(InterceptOutcome.BLOCKED, again.ledger.state.receipts.first().outcome)
        assertEquals(1L, again.ledger.state.blockedCount)
    }

    @Test
    fun p8_removing_a_target_applies_the_new_config() {
        val (dir, k) = openFresh()
        val next = k.guard.setConfig(k.guard.config.copy(targets = emptyList()), wall + 1_000L)
        assertNull(k.guard.storageError)
        assertTrue("the target is gone from the applied config", next.targets.isEmpty())

        assertTrue("and it stayed gone", open(dir).guard.config.targets.isEmpty())
    }

    @Test
    fun p9_one_hundred_and_twenty_rounds_keep_every_commit_and_cap_the_receipts() {
        val (dir, k) = openFresh()
        repeat(120) {
            val t = wall + it * 1_000L
            val d = k.guard.onForeground(bili, env(), t)
            assertTrue("round $it blocks", d is InterceptDecision.Block)
            val b = d as InterceptDecision.Block
            assertTrue(k.guard.onPageShown(b.eventId, t))
            assertTrue(k.guard.onExited(b.eventId, t + 1L))
            assertNull("round $it committed: " + k.guard.storageError, k.guard.storageError)
        }
        val again = open(dir)
        assertEquals("receipts are capped at 100", 100, again.ledger.state.receipts.size)
        assertEquals("but every trigger is counted", 120L, again.ledger.state.triggerCount)
        assertNull(again.guard.storageError)
    }
}
