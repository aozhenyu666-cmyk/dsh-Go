package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 4B · D2: 展示失败后的降级判定。
 *
 * 重点是"读不到前台"这种情况：它必须被当成**未确认离开**，而不是离开。把不确定说成确定，
 * 正是这一轮要消灭的那类错误。
 */
class EnforcementOutcomeTest {

    @Test
    fun a_show_failure_asks_the_runtime_to_go_home() {
        assertEquals(EnforcementOutcome.Step.SendHome, EnforcementOutcome.afterShowFailure("start_failed"));
        assertEquals(EnforcementOutcome.Step.SendHome, EnforcementOutcome.afterShowFailure("no_visibility_proof"));
        assertEquals(EnforcementOutcome.Step.SendHome, EnforcementOutcome.afterShowFailure("surface_busy"));
        assertEquals(EnforcementOutcome.Step.SendHome, EnforcementOutcome.afterShowFailure("attempt_budget"));
        assertEquals(
            "an unknown code still means the page is gone, so still try to leave",
            EnforcementOutcome.Step.SendHome,
            EnforcementOutcome.afterShowFailure("something_new"),
        )
    }

    @Test
    fun the_target_is_still_in_front_when_it_is_still_in_front() {
        assertTrue(EnforcementOutcome.stillInFront("tv.danmaku.bili", "tv.danmaku.bili"));
    }

    @Test
    fun another_app_in_front_means_the_target_left() {
        assertFalse(EnforcementOutcome.stillInFront("com.android.launcher", "tv.danmaku.bili"));
    }

    @Test
    fun an_unreadable_foreground_counts_as_not_having_left() {
        // The whole point: "we could not tell" must never be reported as "it is gone".
        assertTrue(
            "unknown foreground must not be treated as success",
            EnforcementOutcome.stillInFront(null, "tv.danmaku.bili"),
        )
    }

    @Test
    fun an_unreadable_foreground_is_reported_as_unreadable() {
        assertEquals(EnforcementOutcome.REASON_UNREADABLE, EnforcementOutcome.failureKind(null, "tv.danmaku.bili"))
    }

    @Test
    fun a_target_still_in_front_is_reported_as_such() {
        assertEquals(
            EnforcementOutcome.REASON_STILL_IN_FRONT,
            EnforcementOutcome.failureKind("tv.danmaku.bili", "tv.danmaku.bili"),
        )
    }

    @Test
    fun the_unavailable_reason_names_the_code_and_the_attempt_count() {
        val r = EnforcementOutcome.unavailableReason("start_failed", 2);
        assertTrue(r.contains("start_failed"));
        assertTrue(r.contains("2"));
        assertTrue("it says the interception did not take effect", r.contains("did not take effect"));
    }
}
