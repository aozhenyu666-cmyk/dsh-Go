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
}
