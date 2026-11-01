package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * 第四阶段 W1: 生产初始化工厂的测试。
 *
 * 这里和之前的测试有一处根本不同：**它不手工装配 guard/ledger/repository，而是调用
 * [InterceptKernel.open]** —— 也就是 `InterceptRuntime.ensure()` 在生产里调用的那个函数。
 *
 * 这正是自审发现的缺口：以前 24 项测试全绿，但测的都是"手工传了 repository 的对象"，
 * 生产那条路一次都没被覆盖过。
 *
 * 用真实临时目录，不用内存夹具 —— 因为这里要验证的正是"磁盘上留下了哪些文件"。
 */
class InterceptKernelTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = 20_000L)

    private fun tmpDir(): File = kotlin.io.path.createTempDirectory("intercept-kernel").toFile()

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

    private fun names(dir: File): List<String> =
        dir.listFiles()?.map { it.name }?.sorted() ?: emptyList()

    // ---- a. 全新安装：只产生快照，不再产生两个旧文件 -------------------------------

    @Test
    fun a_fresh_install_writes_only_the_snapshot() {
        val dir = tmpDir()
        val k = open(dir)
        assertTrue("fresh: " + k.migration, k.migration is InterceptMigration.Result.Fresh)
        assertNotNull("the snapshot store is in use", k.repo)

        configure(k.guard)
        val block = k.guard.onForeground(bili, env(), wall) as InterceptDecision.Block
        assertTrue(k.guard.onPageShown(block.eventId, wall))
        assertTrue(k.guard.onExited(block.eventId, wall))

        val files = names(dir)
        assertTrue("the snapshot exists: " + files, files.any { it.startsWith(InterceptRepository.FILE_NAME) })
        assertFalse("no guard.json: " + files, "guard.json" in files)
        assertFalse("no ledger.json: " + files, "ledger.json" in files)
    }

    // ---- b. 旧数据被迁移，旧文件字节不变 --------------------------------------------

    @Test
    fun b_legacy_files_are_migrated_and_left_untouched() {
        val dir = tmpDir()
        // Build legacy state the way the old build did: two separate AtomicJsonFile stores.
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
        assertTrue("legacy whitelist written", bili in oldGuard.config.whitelist)

        val guardBytes = File(dir, "guard.json").readBytes()
        val ledgerBytes = File(dir, "ledger.json").readBytes()

        val k = open(dir)
        assertTrue("migrated: " + k.migration, k.migration is InterceptMigration.Result.Migrated)
        assertTrue("the whitelist came across", bili in k.guard.config.whitelist)
        assertTrue(
            "guard.json is byte-identical",
            guardBytes.contentEquals(File(dir, "guard.json").readBytes()),
        )
        assertTrue(
            "ledger.json is byte-identical",
            ledgerBytes.contentEquals(File(dir, "ledger.json").readBytes()),
        )
    }

    // ---- c. 第二次打开不再迁移 ------------------------------------------------------

    @Test
    fun c_a_second_open_does_not_migrate_again() {
        val dir = tmpDir()
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

        val first = open(dir)
        assertTrue(first.migration is InterceptMigration.Result.Migrated)
        val triggersAfterFirst = first.ledger.state.triggerCount

        val second = open(dir)
        assertTrue("already migrated: " + second.migration, second.migration is InterceptMigration.Result.AlreadyMigrated)
        assertTrue("the whitelist is still there", bili in second.guard.config.whitelist)
        assertEquals("counts did not move", triggersAfterFirst, second.ledger.state.triggerCount)
    }

    // ---- d. 进程被杀：重开看到 NOT_SHOWN，不算拦住 --------------------------------

    @Test
    fun d_a_kill_before_the_proof_recovers_as_not_shown() {
        val dir = tmpDir()
        val first = open(dir)
        configure(first.guard)
        first.guard.onForeground(bili, env(), wall)   // triggered, never shown

        // Everything is dropped: new objects over the same directory.
        val second = open(dir)
        val receipts = second.ledger.state.receipts
        assertEquals("one event, one receipt", 1, receipts.size)
        assertEquals("nothing was ever on screen", InterceptOutcome.NOT_SHOWN, receipts.first().outcome)
        assertEquals("so it is not counted as a block", 0L, second.ledger.state.blockedCount)
    }

    // ---- e. 旧数据互相矛盾：退回旧模式，不猜、不删 --------------------------------

    @Test
    fun e_contradictory_legacy_state_falls_back_and_reports() {
        val dir = tmpDir()
        // Whitelist present in the guard, but the ledger records no release at all: a split write.
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
        // Now destroy the ledger side, leaving the whitelist orphaned in the guard file.
        File(dir, "ledger.json").writeText("{ not json")

        val guardBytesBefore = File(dir, "guard.json").readBytes()

        val k = open(dir)
        assertTrue("recovery required: " + k.migration, k.migration is InterceptMigration.Result.RecoveryRequired)
        assertNull("no snapshot is in use", k.repo)
        assertNotNull("and the reason is exposed", k.recoveryIssue)
        assertTrue(
            "guard.json was not touched",
            guardBytesBefore.contentEquals(File(dir, "guard.json").readBytes()),
        )
    }
}
