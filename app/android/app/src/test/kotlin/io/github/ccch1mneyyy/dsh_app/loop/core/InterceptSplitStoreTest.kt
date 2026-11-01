package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 P0-4: guard 和 ledger 是两份文件，一次事件要写两份。
 *
 * 现在每一次状态推进至少写两个文件：`guard.json`（config + open 事件 + 冷却）+ `ledger.json`
 * （回执 + 计数）。两次写入各自是原子的（临时文件 + 备份 + rename），但**合起来不是**：
 * 进程在两次写之间死掉，磁盘上就留下一个自相矛盾的状态。三种可观察的后果：
 *
 *   1. 白名单写在 guard、回执写在 ledger：只写成功一半 → 白名单丢了，或者回执说"已放行"但白名单没有；
 *   2. `blockedCount` 已加而事件变成 NOT_SHOWN → 账本说有 N 次拦截，回执里只有 N-1 条；
 *   3. `triggerCount` 已加但没有对应回执 → 触发数永远比回执多。
 *
 * 这些测试不模拟"写到一半"的时序（那需要一个可注入的崩溃点），而是直接构造**两份文件本来就不一致**
 * 的磁盘状态 —— 这正是崩溃后真实会出现的样子 —— 然后断言守卫能**发现**它。
 *
 * 发现是不够的：P0-4 的修法是单一原子快照。这些测试先钉住"现在发现不了"，修完后钉住"能发现并自愈"。
 */
class InterceptSplitStoreTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private var day = 20_000L
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = day)

    /** One byte buffer per file, so a test can corrupt exactly one of them. */
    private class Disk {
        var guardBytes: String? = null
        var ledgerBytes: String? = null
        fun guardStore() = Buffer(guardBytes) { guardBytes = it }
        fun ledgerStore() = Buffer(ledgerBytes) { ledgerBytes = it }
    }

    private class Buffer(private val current: String?, private val keep: (String) -> Unit) : SnapshotStore {
        override fun read(): SnapshotStore.Read {
            val t = current ?: return SnapshotStore.Read.Empty
            return try {
                SnapshotStore.Read.Loaded(
                    io.github.ccch1mneyyy.dsh_app.phone.Json.parse(t) as Map<*, *>,
                )
            } catch (e: Throwable) {
                SnapshotStore.Read.Unreadable(e.toString())
            }
        }

        override fun write(map: Map<String, Any?>) {
            keep(io.github.ccch1mneyyy.dsh_app.phone.Json.write(map))
        }
    }

    private inner class Incarnation(disk: Disk) {
        val book = InterceptLedgerBook(disk.ledgerStore()).also { it.recover() }
        val guard = InterceptGuard(disk.guardStore(), book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }
        fun armed() = also { guard.setConfig(InterceptConfig(enabled = true, trainingMs = 0), wall) }
    }

    // ---- 1. a ledger that counts blocks the guard has no record of ------------------------

    @Test
    fun a_ledger_that_counts_a_block_the_guard_lost_is_reported_not_trusted() {
        val disk = Disk()
        // The two files disagree: the ledger says one block happened, the guard has no state at all.
        // The real on-disk shape of ledger.json: { ledger: {...}, applied: [...] }.
        disk.ledgerBytes = io.github.ccch1mneyyy.dsh_app.phone.Json.write(
            linkedMapOf(
                "ledger" to linkedMapOf(
                    "triggerCount" to 1L,
                    "blockedCount" to 1L,
                    "userReleasedCount" to 0L,
                    "userExitedCount" to 0L,
                    "pausedCount" to 0L,
                    "receipts" to emptyList<Any?>(),
                    "lastRecordedAt" to 0L,
                ),
                "applied" to emptyList<Any?>(),
            ),
        )
        disk.guardBytes = null // guard.json never got written

        val revived = Incarnation(disk)

        assertEquals("the ledger kept what it was told", 1L, revived.book.state.blockedCount)
        assertEquals("but it has no receipt to back the count", 0, revived.book.state.receipts.size)
        // The invariant that must hold on any consistent pair: every counted block has a receipt.
        assertNotNull(
            "a block count with no receipt is a split write, and must be surfaced",
            revived.book.splitWrite,
        )
    }

    // ---- 2. a whitelist the ledger never heard about ---------------------------------------

    @Test
    fun a_whitelist_the_ledger_never_heard_about_is_surfaced() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.guard.onForeground(bili, env(), wall) as InterceptDecision.Block
        first.guard.onPageShown(block.eventId, wall)
        assertTrue(first.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall))

        // Simulate the crash landing between the two writes: the ledger write was lost.
        disk.ledgerBytes = null

        val revived = Incarnation(disk)
        assertTrue("the whitelist survived in the guard", bili in revived.guard.config.whitelist)
        assertEquals("but the receipt is gone", 0L, revived.book.state.userReleasedCount)
        assertNotNull(
            "a whitelist entry with no release receipt is a split write",
            revived.guard.splitWrite ?: revived.book.splitWrite,
        )
    }

    // ---- 3. a consistent pair must NOT be flagged ------------------------------------------

    @Test
    fun a_consistent_pair_is_not_flagged() {
        val disk = Disk()
        val first = Incarnation(disk).armed()
        val block = first.guard.onForeground(bili, env(), wall) as InterceptDecision.Block
        first.guard.onPageShown(block.eventId, wall)
        first.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall)

        val revived = Incarnation(disk)
        assertNull("nothing to report when both files agree", revived.book.splitWrite)
        assertNull("and the guard agrees", revived.guard.splitWrite)
        assertEquals(1L, revived.book.state.userReleasedCount)
        assertTrue(bili in revived.guard.config.whitelist)
    }
}
