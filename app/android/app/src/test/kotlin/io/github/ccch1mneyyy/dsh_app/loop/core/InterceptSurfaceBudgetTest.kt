package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Round-4 integration: the intercept must not spend its cooldown or daily budget when another DSH
 * surface already holds the screen.
 *
 * [InterceptGuard.onForeground] stamps `lastTriggerAt` and increments `countToday` the moment it
 * returns [InterceptDecision.Block]. So the "is the screen free" question has to be answered *before*
 * the guard is asked - otherwise a page that never appeared still costs the person an interception
 * and the retry is swallowed by the cooldown. These tests pin the guard's side of that contract:
 * once a Block is produced, the budget is already spent, which is why the adapter must not ask.
 */
class InterceptSurfaceBudgetTest {

    private class Harness {
        val store = MemorySnapshotStore()
        val book = InterceptLedgerBook(MemorySnapshotStore()).also { it.recover() }
        var wall = 1_000_000L
        var seq = 0
        val guard = InterceptGuard(store, book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }

        fun env(minute: Int = 600, day: Long = 20_000L) =
            InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = minute, dayKey = day)

        fun enable(target: String = "tv.danmaku.bili") {
            guard.setConfig(
                InterceptConfig(
                    enabled = true,
                    targets = listOf(InterceptTarget(target, "B站")),
                    cooldownMs = 2 * 60_000L,
                    dailyMax = 0,
                ),
                wall,
            )
        }
    }

    @Test
    fun a_not_shown_interception_does_not_spend_the_cooldown() {
        val h = Harness()
        h.enable()
        val first = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall)
        assertTrue(first is InterceptDecision.Block)
        // Nothing was ever shown, so nothing is owed: the trigger has to give back what it charged.
        h.guard.onUnavailable((first as InterceptDecision.Block).eventId, "surface_busy", h.wall)
        h.wall += 1_000
        val second = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall)
        assertTrue(
            "a page that was never shown must not put the app in a cooldown",
            second is InterceptDecision.Block,
        )
    }

    @Test
    fun a_not_shown_interception_does_not_spend_the_daily_count() {
        val h = Harness()
        h.guard.setConfig(
            InterceptConfig(
                enabled = true,
                targets = listOf(InterceptTarget("tv.danmaku.bili", "Bilibili")),
                cooldownMs = 0,
                dailyMax = 1,
            ),
            h.wall,
        )
        val first = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall)
        assertTrue(first is InterceptDecision.Block)
        h.guard.onUnavailable((first as InterceptDecision.Block).eventId, "surface_busy", h.wall)
        h.wall += 1_000
        val second = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall)
        assertTrue("a page that never appeared must not use up the day's budget", second is InterceptDecision.Block)
        assertEquals("and the counter was given back", 1, h.guard.state.countToday)
    }

    @Test
    fun a_shown_block_does_spend_the_cooldown() {
        val h = Harness()
        h.enable()
        val first = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall) as InterceptDecision.Block
        // This one really was on screen: it is a block, and a block costs a cooldown.
        assertTrue(h.guard.onPageShown(first.eventId, h.wall))
        assertTrue(h.guard.onExited(first.eventId, h.wall))
        h.wall += 1_000
        val second = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall)
        assertTrue("a real block does arm the cooldown", second is InterceptDecision.Allow)
        assertEquals(InterceptRules.REASON_COOLDOWN, (second as InterceptDecision.Allow).reason)
    }
    @Test
    fun a_guard_that_was_never_asked_keeps_its_budget() {
        val h = Harness()
        h.enable()
        // This is what the adapter does while another surface holds the screen: it does not call
        // onForeground at all. Two window changes later the first real interception still happens.
        h.wall += 30_000
        h.wall += 30_000
        val decision = h.guard.onForeground("tv.danmaku.bili", h.env(), h.wall)
        assertTrue(decision is InterceptDecision.Block)
        assertEquals(1, h.guard.state.countToday)
    }

    @Test
    fun the_surface_slot_is_free_again_after_the_other_feature_releases_it() {
        val slot = SurfaceSlot()
        assertTrue(slot.claim(VisibleSurface.OWNER_PROACTIVE, "tok-1", 100))
        assertFalse(slot.isFree())
        assertTrue(slot.release(VisibleSurface.OWNER_PROACTIVE, "tok-1"))
        assertTrue(slot.isFree())
        assertTrue(slot.claim(VisibleSurface.OWNER_INTERCEPT, "evt-1", 200))
    }
}
