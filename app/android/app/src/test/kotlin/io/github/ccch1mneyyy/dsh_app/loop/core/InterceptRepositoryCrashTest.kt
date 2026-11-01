package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 4B · P0-4: 崩溃一致性的**故障注入**测试。
 *
 * 这些测试不验证"正常情况能存下来"，那是别的测试的事。这里每一次都让**某一步失败**，
 * 然后问同一个问题：磁盘上留下的是什么，内存里相信的是什么，两者是否仍然一致。
 *
 * 关键点：任何"真正的重启"都必须新建 Repository / Ledger / Guard 对象，只共享**字节**。
 * 复用内存对象假装重启，就测不出任何东西 —— 这正是上一轮 InterceptRecoveryTest 的问题。
 */
class InterceptRepositoryCrashTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private val bili = "tv.danmaku.bili"

    /** 一块可注入故障的磁盘：一个字节缓冲 + 一个"下一次写要不要炸"的开关。 */
    private class FaultyDisk : SnapshotStore {
        var bytes: String? = null
        /** null = 正常；否则抛这个异常。 */
        var failNextWrite: Throwable? = null
        /** 写成功但不真正落盘（模拟"返回成功却没持久化"）。 */
        var silentlyDropWrites = false
        /** 写到一半的字节（模拟写到一半进程死亡）：留下截断内容。 */
        var truncateNextWriteTo: Int? = null

        var writes = 0
        var reads = 0

        override fun read(): SnapshotStore.Read {
            reads++
            val t = bytes ?: return SnapshotStore.Read.Empty
            return try {
                SnapshotStore.Read.Loaded(
                    io.github.ccch1mneyyy.dsh_app.phone.Json.parse(t) as Map<*, *>,
                )
            } catch (e: Throwable) {
                SnapshotStore.Read.Unreadable(e.toString())
            }
        }

        override fun write(map: Map<String, Any?>) {
            writes++
            failNextWrite?.let { boom -> failNextWrite = null; throw boom }
            val text = io.github.ccch1mneyyy.dsh_app.phone.Json.write(map)
            if (silentlyDropWrites) return
            val cut = truncateNextWriteTo
            if (cut != null) {
                truncateNextWriteTo = null
                bytes = text.substring(0, minOf(cut, text.length))
                return
            }
            bytes = text
        }
    }

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = 20_000L)

    /** 一个"进程"：自己的仓库、自己的账本、自己的守卫，只共享磁盘字节。 */
    private inner class Proc(val disk: FaultyDisk) {
        val repo = InterceptRepository(disk)
        val ledger = InterceptLedgerBook(disk, sharedWithRepository = true)
        val guard = InterceptGuard(disk, ledger, { wall }, repository = repo)

        fun boot(): Proc {
            // Order matters: the repository reads the snapshot first, then exposes it, then the
            // guard and the ledger read *that* — one file, one read, one truth.
            repo.load()
            ledger.repositoryView = { repo.committed.toMap() }
            ledger.recover()
            guard.recover(wall)
            return this
        }

        fun arm() = also { guard.setConfig(InterceptConfig(enabled = true, trainingMs = 0), wall) }

        fun blocked(): InterceptDecision.Block {
            val d = guard.onForeground(bili, env(), wall)
            assertTrue("blocks", d is InterceptDecision.Block)
            return d as InterceptDecision.Block
        }
    }

    private fun reboot(disk: FaultyDisk) = Proc(disk).boot()

    // ---- 1. 临时文件创建失败 ----------------------------------------------------------

    @Test
    fun a_write_that_cannot_even_open_a_temp_file_leaves_the_old_snapshot_intact() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        val b = p1.blocked()
        assertTrue(p1.guard.onPageShown(b.eventId, wall))
        val before = disk.bytes
        assertNotNull("first commit landed", before)

        disk.failNextWrite = java.io.IOException("no space for temp file")
        p1.guard.onReleased(b.eventId, InterceptGuard.RELEASE_WHITELIST, wall)
        // The door may have been accepted in memory, but the commit could not be written.
        assertNotNull("the failed write is reported", p1.guard.storageError)
        assertEquals("the previous snapshot is untouched", before, disk.bytes)

        // A fresh process sees exactly the pre-release state: no whitelist, no release receipt.
        val p2 = reboot(disk)
        assertFalse("no whitelist was persisted", bili in p2.guard.config.whitelist)
        assertEquals("no release receipt was persisted", 0L, p2.ledger.state.userReleasedCount)
        assertTrue("and no phantom RELEASED", p2.ledger.state.receipts.none { it.outcome == InterceptOutcome.RELEASED });
    }

    // ---- 2. 写到一半进程死亡（截断内容） ----------------------------------------------

    @Test
    fun a_truncated_write_is_not_readable_as_a_valid_snapshot() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        p1.blocked()
        val good = disk.bytes

        disk.truncateNextWriteTo = 40
        // Whatever the guard tried, the commit must notice the read-back is wrong.
        p1.guard.setConfig(InterceptConfig(enabled = false), wall)
        assertNotEquals("the good snapshot was replaced by a truncated one", good, disk.bytes)

        // The next process gets a recovery issue, not a silently empty state.
        val p2 = Proc(disk).boot()
        assertNotNull("an unreadable snapshot is reported", p2.repo.recoveryIssue ?: p2.guard.recoveryIssue)
    }

    // ---- 3. fsync 前死亡 与 4. fsync 后替换前死亡 --------------------------------------

    @Test
    fun a_crash_before_the_rename_leaves_the_previous_snapshot_readable() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        val b = p1.blocked()
        assertTrue(p1.guard.onPageShown(b.eventId, wall))
        val good = disk.bytes

        // fsync fails, or the process dies at that point: the store throws and the snapshot stays.
        disk.failNextWrite = java.io.IOException("fsync interrupted")
        p1.guard.onExited(b.eventId, wall)
        assertEquals("the previously committed snapshot is still what is on disk", good, disk.bytes)

        val p2 = reboot(disk)
        assertEquals("and it still parses", 1, p2.ledger.state.receipts.size)
        assertEquals(InterceptOutcome.BLOCKED, p2.ledger.state.receipts.single().outcome)
    }

    // ---- 5. 替换完成、内存更新前死亡 ---------------------------------------------------

    @Test
    fun a_restart_after_a_durable_commit_recovers_the_committed_state_not_the_old_one() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        val b = p1.blocked()
        assertTrue(p1.guard.onPageShown(b.eventId, wall))
        assertTrue(p1.guard.onReleased(b.eventId, InterceptGuard.RELEASE_WHITELIST, wall))

        // Nothing else happens in p1: pretend it was killed right after the rename.
        val p2 = reboot(disk)
        assertTrue("the committed whitelist survived", bili in p2.guard.config.whitelist)
        assertEquals("and its receipt", 1L, p2.ledger.state.userReleasedCount)
    }

    // ---- 6. 写"成功"但没落盘（静默丢失） ----------------------------------------------

    @Test
    fun a_store_that_silently_drops_the_write_is_caught_by_the_read_back() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        p1.blocked()

        disk.silentlyDropWrites = true
        val ok = p1.repo.commit(
            config = p1.guard.config.toMap(),
            guardState = p1.guard.state.toMap(),
            ledgerState = p1.ledger.state.toMap(),
            appliedEventIds = p1.ledger.appliedIds(),
        )
        assertFalse("the commit must not claim success", ok)
        assertNotNull("and must say why", p1.repo.lastCommitError)
    }

    // ---- 7. 同一 eventId 重复提交（幂等） ----------------------------------------------

    @Test
    fun the_same_eventId_applied_twice_adds_one_receipt() {
        val disk = FaultyDisk()
        val p = Proc(disk).boot().arm()
        val b = p.blocked()
        assertTrue(p.guard.onPageShown(b.eventId, wall))
        p.guard.onPageShown(b.eventId, wall)
        // A receipt is written when the event ENDS, not when it is shown, so at this point the
        // ledger legitimately has none. What must hold is that the second proof does not add a
        // second block count.
        assertEquals("a second proof does not count a second block", 1L, p.ledger.state.blockedCount)
        assertEquals(0, p.ledger.state.receipts.size)
        p.guard.onExited(b.eventId, wall)
        assertEquals("ending once produces exactly one receipt", 1, p.ledger.state.receipts.size)
    }

    // ---- 8. 每日计数更新中断 -----------------------------------------------------------

    @Test
    fun an_interrupted_daily_count_write_does_not_double_count_on_restart() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        val b = p1.blocked()
        assertTrue(p1.guard.onPageShown(b.eventId, wall))
        val counted = p1.guard.state.countToday
        assertEquals("the first shown block is counted", 1, counted)

        disk.failNextWrite = java.io.IOException("interrupted")
        p1.guard.onExited(b.eventId, wall) // try to move on; the write fails

        val p2 = reboot(disk)
        assertEquals(
            "the durable count is the committed one, not a half-applied one",
            counted, p2.guard.state.countToday,
        )
    }

    // ---- 9. 快照自洽校验：不让矛盾状态被写下 -------------------------------------------

    @Test
    fun a_snapshot_whose_trigger_count_is_below_its_receipts_is_refused() {
        val disk = FaultyDisk()
        val p = Proc(disk).boot().arm()
        // triggerCount is the number of *attempts*; it can never be smaller than the number of
        // finished receipts, because every receipt implies a trigger. That is the invariant worth
        // guarding — unlike "counts <= receipts", which a legitimate mid-event state violates.
        val ok = p.repo.commit(
            config = p.guard.config.toMap(),
            guardState = p.guard.state.toMap(),
            ledgerState = linkedMapOf(
                "triggerCount" to 0L,
                "blockedCount" to 0L,
                "userReleasedCount" to 0L,
                "userExitedCount" to 0L,
                "pausedCount" to 0L,
                "receipts" to listOf(emptyMap<String, Any?>()),
                "lastRecordedAt" to 0L,
            ),
            appliedEventIds = emptyList(),
        )
        assertFalse("an incoherent snapshot must not be committed", ok)
        assertNotNull(p.repo.lastCommitError)
    }

    // ---- 10. 版本比本进程新：拒绝而不是覆盖 -------------------------------------------

    @Test
    fun a_newer_schema_is_refused_rather_than_overwritten() {
        val disk = FaultyDisk()
        disk.bytes = io.github.ccch1mneyyy.dsh_app.phone.Json.write(
            linkedMapOf(
                "schemaVersion" to 999L,
                "config" to emptyMap<String, Any?>(),
                "guardState" to emptyMap<String, Any?>(),
                "ledgerState" to emptyMap<String, Any?>(),
                "appliedEventIds" to emptyList<String>(),
                "lastCommittedTransactionId" to 0L,
            ),
        )
        val repo = InterceptRepository(disk)
        assertNull("a future schema is not loaded", repo.load())
        assertNotNull("and the reason is reported", repo.recoveryIssue)
        assertEquals("nothing was overwritten", 0, disk.writes)
    }

    // ---- 11/12. 白名单与 RELEASED 回执写失败 ------------------------------------------

    @Test
    fun a_failed_whitelist_write_leaves_neither_a_whitelist_entry_nor_a_receipt() {
        val disk = FaultyDisk()
        val p1 = Proc(disk).boot().arm()
        val b = p1.blocked()
        assertTrue(p1.guard.onPageShown(b.eventId, wall))

        disk.failNextWrite = java.io.IOException("whitelist write failed")
        p1.guard.onReleased(b.eventId, InterceptGuard.RELEASE_WHITELIST, wall)

        val p2 = reboot(disk)
        assertFalse("no half-written whitelist", bili in p2.guard.config.whitelist)
        assertTrue(
            "no phantom RELEASED receipt",
            p2.ledger.state.receipts.none { it.outcome == InterceptOutcome.RELEASED },
        )
    }
}
