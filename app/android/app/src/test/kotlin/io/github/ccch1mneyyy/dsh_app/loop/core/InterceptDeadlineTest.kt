package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 P0-1: 三条到期规则，以及它们【不是】什么。
 *
 * 规则本身的正确性在这里证明；把它们接进运行时的部分在 Android 侧，无法在 JVM 上跑。
 * 所以这个文件只管「给一个时钟读数，该做什么」—— 那是纯函数，也正是过去出错的地方：
 * 到期判定原本写在页面里（bind() 检查一次 deadline），页面不在就永远不判。
 */
class InterceptDeadlineTest {

    private val requested = 1_000_000L

    // ---- 1. 证明窗口：启动了但没起来 ----

    @Test
    fun a_page_that_never_proves_itself_is_not_shown_after_the_window() {
        val open = InterceptDeadline.Open(requestedAt = requested)
        assertEquals(
            "before the window there is still time",
            InterceptDeadline.Due.Nothing,
            InterceptDeadline.due(open, now = requested + 4_999L),
        )
        assertEquals(
            "at the window it is settled",
            InterceptDeadline.Due.NotShown,
            InterceptDeadline.due(open, now = requested + 5_000L),
        )
    }

    @Test
    fun the_proof_window_does_not_depend_on_the_page_ttl() {
        val open = InterceptDeadline.Open(requestedAt = requested)
        assertEquals(InterceptDeadline.Due.NotShown, InterceptDeadline.due(open, now = requested + 5_000L))
        assertTrue(
            "the TTL is much longer than the proof window",
            InterceptDeadline.DEFAULT_PAGE_TTL_MS > InterceptDeadline.DEFAULT_PROOF_WINDOW_MS * 10,
        )
    }

    // ---- 2. 展示上限：证明之后什么都不做 ----

    @Test
    fun a_shown_page_expires_at_the_ttl_and_not_before() {
        val open = InterceptDeadline.Open(requestedAt = requested, shownAt = requested + 500L)
        assertEquals(
            "a shown page is fine until the TTL",
            InterceptDeadline.Due.Nothing,
            InterceptDeadline.due(open, now = requested + 500L + InterceptDeadline.DEFAULT_PAGE_TTL_MS - 1),
        )
        assertEquals(
            "and expires at it",
            InterceptDeadline.Due.Expired,
            InterceptDeadline.due(open, now = requested + 500L + InterceptDeadline.DEFAULT_PAGE_TTL_MS),
        )
    }

    @Test
    fun the_ttl_runs_from_the_proof_not_from_the_request() {
        val slow = InterceptDeadline.Open(requestedAt = requested, shownAt = requested + 4_000L)
        assertEquals(
            InterceptDeadline.Due.Nothing,
            InterceptDeadline.due(slow, now = requested + 4_000L + InterceptDeadline.DEFAULT_PAGE_TTL_MS - 1),
        )
    }

    // ---- 3. 未开启时不做任何事 ----

    @Test
    fun nothing_is_due_when_nothing_is_open() {
        assertEquals(InterceptDeadline.Due.Nothing, InterceptDeadline.due(null, now = requested))
        assertNull(InterceptDeadline.nextDeadline(null))
    }

    // ---- 4. 一个定时器而不是轮询 ----

    @Test
    fun the_next_deadline_is_the_earliest_moment_the_answer_could_change() {
        val unshown = InterceptDeadline.Open(requestedAt = requested)
        assertEquals(requested + 5_000L, InterceptDeadline.nextDeadline(unshown))

        val shown = InterceptDeadline.Open(requestedAt = requested, shownAt = requested + 1_000L)
        assertEquals(
            requested + 1_000L + InterceptDeadline.DEFAULT_PAGE_TTL_MS,
            InterceptDeadline.nextDeadline(shown),
        )
    }

    // ---- 5. 退避不是放行（D2 最后一句） ----

    @Test
    fun the_retry_backoff_only_holds_off_and_never_grants_passage() {
        val backoff = InterceptDeadline.Backoff(backoffMs = 15_000L)
        backoff.note("tv.danmaku.bili", now = requested)

        assertTrue(backoff.isHoldingOff("tv.danmaku.bili", requested))
        assertTrue(backoff.isHoldingOff("tv.danmaku.bili", requested + 14_999L))
        assertFalse(backoff.isHoldingOff("tv.danmaku.bili", requested + 15_000L))
        assertFalse(backoff.isHoldingOff("com.ss.android.ugc.aweme", requested))
    }

    // ---- 6. 每分钟尝试上限（D2） ----

    @Test
    fun a_package_gets_three_tries_a_minute_then_is_reported() {
        val a = InterceptDeadline.Attempts(maxPerMinute = 3, windowMs = 60_000L)
        assertTrue(a.record("bili", requested))
        assertTrue(a.record("bili", requested + 1_000L))
        assertTrue(a.record("bili", requested + 2_000L))
        assertFalse("the fourth inside the window is refused", a.record("bili", requested + 3_000L))
        assertEquals(3, a.count("bili", requested + 3_000L))

        // The window slides. At t=61s the attempts at 0s and 1s have aged out (61-0 and 61-1 are
        // both >= 60) while the one at 2s has not (61-2 = 59 < 60), so one slot is free again.
        assertTrue(a.record("bili", requested + 61_000L))
        assertEquals("two inside the window now", 2, a.count("bili", requested + 61_000L))
        // A third fits; a fourth does not, because three inside the window is the budget.
        assertTrue(a.record("bili", requested + 61_500L))
        assertFalse(a.record("bili", requested + 61_900L))
        assertEquals(3, a.count("bili", requested + 61_900L))
    }

    @Test
    fun the_attempt_budget_is_per_package() {
        val a = InterceptDeadline.Attempts(maxPerMinute = 1, windowMs = 60_000L)
        assertTrue(a.record("bili", requested))
        assertFalse(a.record("bili", requested + 1L))
        assertTrue("a different app has its own budget", a.record("douyin", requested + 2L))
    }

    // ---- 7. 时钟形状：单调，不是墙钟 ----

    @Test
    fun the_policy_takes_a_monotonic_reading_so_a_clock_change_cannot_skip_it() {
        val open = InterceptDeadline.Open(requestedAt = requested)
        assertEquals(
            InterceptDeadline.Due.Nothing,
            InterceptDeadline.due(open, now = requested - 10_000L),
        )
    }
}
