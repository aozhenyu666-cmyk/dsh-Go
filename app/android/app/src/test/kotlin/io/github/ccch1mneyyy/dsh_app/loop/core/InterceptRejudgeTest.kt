package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 P0-2: 拦截一结束，前台必须重新判定。
 *
 * 不重判是一条真实的绕过路径：拦截页展示时用「最近任务」切回目标 APP，窗口事件先到、
 * 守卫仍是 open 状态、返回 Allow(already_open)，随后页面 onStop 结算；此后再没有窗口事件，
 * 于是目标 APP 一直可用，直到用户自己离开再回来。
 *
 * 这里能测的是**守卫侧**的事实：一次结束之后，同一个包名的下一次 onForeground 必须重新给出
 * 判决（而不是被上一事件的状态吞掉）。"重新调用验证一次"这部分在 Android 侧，
 * 由 InterceptRuntime 的 recheckForeground 负责，编译期已验证接线。
 */
class InterceptRejudgeTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private var day = 20_000L
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = day)

    private inner class Rig {
        val book = InterceptLedgerBook(MemorySnapshotStore()).also { it.recover() }
        val guard = InterceptGuard(MemorySnapshotStore(), book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }
        fun armed() = also {
            // cooldown 0 so this file measures re-judging, not the cooldown (which has its own tests).
            guard.setConfig(InterceptConfig(enabled = true, trainingMs = 0, cooldownMs = 0), wall)
        }
        fun blocked(): InterceptDecision.Block {
            val d = guard.onForeground(bili, env(), wall)
            assertTrue("blocks", d is InterceptDecision.Block)
            return d as InterceptDecision.Block
        }
    }

    // ---- 1. 结束后重新判定：退出这条路 ----------------------------------------------

    @Test
    fun after_an_exit_the_app_is_judged_again_not_waved_through() {
        val r = Rig().armed()
        val block = r.blocked()
        assertTrue(r.guard.onPageShown(block.eventId, wall))
        assertTrue(r.guard.onExited(block.eventId, wall))
        // D5: an exit grants no passage. The very next reading must block again.
        val again = r.guard.onForeground(bili, env(), wall + 1_000L)
        assertTrue("exiting must not be a way through", again is InterceptDecision.Block)
    }

    // ---- 2. 结束后重新判定：超时这条路 ----------------------------------------------

    @Test
    fun after_a_page_ttl_the_app_is_judged_again() {
        val r = Rig().armed()
        val block = r.blocked()
        assertTrue(r.guard.onPageShown(block.eventId, wall))
        assertTrue("the runtime ends it at the TTL", r.guard.expireOpen(block.eventId, wall + 10 * 60_000L))
        assertEquals("and records BLOCKED, not a pass", InterceptOutcome.BLOCKED, r.book.state.receipts.single().outcome)
        val again = r.guard.onForeground(bili, env(), wall + 10 * 60_000L + 1_000L)
        assertTrue("a TTL ending grants nothing", again is InterceptDecision.Block)
    }

    // ---- 3. 结束后重新判定：未展示这条路 --------------------------------------------

    @Test
    fun after_a_not_shown_the_app_is_judged_again() {
        val r = Rig().armed()
        val block = r.blocked()
        assertTrue(r.guard.onUnavailable(block.eventId, "no_visibility_proof", wall))
        val again = r.guard.onForeground(bili, env(), wall + 1_000L)
        assertTrue("a failed launch must not become a free pass either", again is InterceptDecision.Block)
    }

    // ---- 4. 反方向：放行之后确实不拦 ------------------------------------------------

    @Test
    fun after_a_release_the_app_really_is_let_through_for_the_window() {
        val r = Rig().armed()
        val block = r.blocked()
        assertTrue(r.guard.onPageShown(block.eventId, wall))
        assertTrue(r.guard.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall))
        val again = r.guard.onForeground(bili, env(), wall + 1_000L)
        assertTrue("a standing permission does pass it through", again is InterceptDecision.Allow)
        assertEquals(InterceptRules.REASON_WHITELIST, (again as InterceptDecision.Allow).reason)
    }
}
