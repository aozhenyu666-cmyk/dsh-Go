package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 P0-5: 没显示出来的页面，不能放行。
 *
 * 每一条通路都只校验自己那件事 —— 训练题解没解、有没有授权窗口、白名单要不要加 ——
 * 但**没有一条校验"这一页到底显示出来过没有"**。于是一个从未上屏的拦截（ROM 静默丢弃 start、
 * 可见性证明失败、页面根本没创建），只要页面活着就能走完任何一扇门，把目标 APP 放出去。
 *
 * 判据很简单：`openShownAt == 0` 表示适配层从未证明页面在屏上。
 * 那不是"用户看到了但没选"，是"用户根本没看见"，所以：
 *
 *   * 任何一扇放行门都必须拒绝（`onReleased` 的所有 how）
 *   * 紧急退出与暂停也不能记成用户的动作（那是 NOT_SHOWN，不是 EXITED/PAUSED）
 *
 * 同一批测试也钉住反方向：**显示过**以后，同样的调用必须成功 —— 否则"修好"就变成了"全都不放行"。
 */
class InterceptVisibilityGateTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private var day = 20_000L
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = day)

    private inner class Rig {
        val book = InterceptLedgerBook(MemorySnapshotStore()).also { it.recover() }
        val guard = InterceptGuard(MemorySnapshotStore(), book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }

        fun armed() = also {
            guard.setConfig(InterceptConfig(enabled = true, trainingMs = 0), wall)
        }

        fun blocked(): InterceptDecision.Block {
            val d = guard.onForeground(bili, env(), wall)
            assertTrue("a configured target blocks", d is InterceptDecision.Block)
            return d as InterceptDecision.Block
        }

        fun solveDrill(block: InterceptDecision.Block) {
            val order = if (block.drill.ascending) block.drill.candidates.sorted()
            else block.drill.candidates.sortedDescending()
            for (v in order) assertTrue(guard.tapDrill(block.eventId, v))
        }
    }

    // ---- 1. no door opens for a page that was never on screen ----------------------------

    @Test
    fun a_training_pass_is_refused_when_the_page_was_never_shown() {
        val r = Rig().armed()
        val block = r.blocked()
        r.solveDrill(block) // the drill is solved, which is all the old check asked for
        assertFalse(
            "a solved drill on a page nobody saw must not open the app",
            r.guard.onReleased(block.eventId, InterceptGuard.RELEASE_TRAINING, wall),
        )
        assertNotNull("the interception is still open", r.guard.openEventId())
        assertNull("and no receipt was written for a pass", r.book.state.receipts.firstOrNull())
    }

    @Test
    fun a_whitelist_pass_is_refused_when_the_page_was_never_shown() {
        val r = Rig().armed()
        val block = r.blocked()
        assertFalse(
            "a standing permission must not be granted by a page nobody saw",
            r.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall),
        )
        assertFalse("and the whitelist is untouched", bili in r.guard.config.whitelist)
        assertEquals(0L, r.book.state.userReleasedCount)
    }

    @Test
    fun a_rule_pass_is_refused_when_the_page_was_never_shown() {
        val r = Rig().armed()
        val minuteNow = InterceptGuard.minuteOfDayOf(wall)
        r.guard.setConfig(r.guard.config.copy(authorizedWindows = listOf(minuteNow until minuteNow + 60)), wall)
        val block = r.blocked()
        assertFalse(
            "even a valid window must not let an unseen page release",
            r.guard.onReleased(block.eventId, InterceptGuard.RELEASE_RULE, wall),
        )
        assertNotNull(r.guard.openEventId())
    }

    // ---- 2. an unseen page's exit is not the person's act --------------------------------

    @Test
    fun an_unseen_page_exiting_is_recorded_as_not_shown_not_as_an_exit() {
        val r = Rig().armed()
        val block = r.blocked()
        // The page reports "the person left" without ever having proved it was on screen.
        r.guard.onExited(block.eventId, wall)
        val receipt = r.book.state.receipts.singleOrNull()
        assertNotNull("the event is settled, not left hanging", receipt)
        assertEquals(
            "nobody saw it, so nobody left it",
            InterceptOutcome.NOT_SHOWN,
            receipt!!.outcome,
        )
        assertEquals("and it is not counted as the person walking away", 0L, r.book.state.userExitedCount)
    }

    @Test
    fun an_unseen_page_pausing_is_recorded_as_not_shown_not_as_a_pause() {
        val r = Rig().armed()
        val block = r.blocked()
        r.guard.onPaused(block.eventId, InterceptGuard.DEFAULT_PAUSE_MS, wall)
        val receipt = r.book.state.receipts.singleOrNull()
        assertNotNull(receipt)
        assertEquals(
            "a pause by a page nobody saw must not pause anything on the person's behalf",
            InterceptOutcome.NOT_SHOWN,
            receipt!!.outcome,
        )
        assertEquals(0L, r.book.state.pausedCount)
    }

    // ---- 3. the other direction: shown pages still work ----------------------------------

    @Test
    fun every_door_still_opens_once_the_page_was_really_shown() {
        // training
        Rig().armed().let { r ->
            val block = r.blocked()
            assertTrue(r.guard.onPageShown(block.eventId, wall))
            r.solveDrill(block)
            assertTrue(r.guard.onReleased(block.eventId, InterceptGuard.RELEASE_TRAINING, wall))
            assertEquals(InterceptOutcome.RELEASED, r.book.state.receipts.single().outcome)
        }
        // whitelist
        Rig().armed().let { r ->
            val block = r.blocked()
            assertTrue(r.guard.onPageShown(block.eventId, wall))
            assertTrue(r.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall))
            assertTrue(bili in r.guard.config.whitelist)
        }
        // exit
        Rig().armed().let { r ->
            val block = r.blocked()
            assertTrue(r.guard.onPageShown(block.eventId, wall))
            assertTrue(r.guard.onExited(block.eventId, wall))
            assertEquals(InterceptOutcome.EXITED, r.book.state.receipts.single().outcome)
            assertEquals(1L, r.book.state.userExitedCount)
        }
        // pause
        Rig().armed().let { r ->
            val block = r.blocked()
            assertTrue(r.guard.onPageShown(block.eventId, wall))
            assertTrue(r.guard.onPaused(block.eventId, InterceptGuard.DEFAULT_PAUSE_MS, wall))
            assertEquals(InterceptOutcome.PAUSED, r.book.state.receipts.single().outcome)
            assertEquals(1L, r.book.state.pausedCount)
        }
    }
}
