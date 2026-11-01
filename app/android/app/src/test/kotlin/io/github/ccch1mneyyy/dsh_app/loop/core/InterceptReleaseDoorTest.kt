package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 逻辑闭合轮: no door through the block page opens without the guard deciding it may.
 *
 * Round 4 shipped the four ways out, but only `training` was checked. `RELEASE_RULE` granted a
 * timed pass with **no rule configured at all** — the page offered "authorization rule: open it for
 * 10 min" and the guard said yes, so a person (or a patched build, or a mis-tap) got passage by
 * pressing one button. These pin the rule that replaced it: every door is earned, and the page never
 * gets to grant anything itself.
 */
class InterceptReleaseDoorTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private var day = 20_000L
    private val bili = "tv.danmaku.bili"

    private fun book() = InterceptLedgerBook(MemorySnapshotStore()).also { it.recover() }

    private fun guard(book: InterceptLedgerBook = book(), store: MemorySnapshotStore = MemorySnapshotStore()) =
        InterceptGuard(store, book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = day)

    private fun InterceptGuard.armed(cfg: InterceptConfig = InterceptConfig(enabled = true, trainingMs = 0)) =
        also { it.setConfig(cfg, wall) }

    private fun blocked(g: InterceptGuard): InterceptDecision.Block {
        val d = g.onForeground(bili, env(), wall)
        assertTrue("a configured target blocks", d is InterceptDecision.Block)
        return d as InterceptDecision.Block
    }

    private fun InterceptGuard.solve(eventId: String, drill: InterceptDrill) {
        val order = if (drill.ascending) drill.candidates.sorted() else drill.candidates.sortedDescending()
        for (v in order) assertTrue(tapDrill(eventId, v))
        assertTrue(drill2Solved())
    }

    private fun InterceptGuard.drill2Solved(): Boolean = drill()?.solved == true

    // ---- 1. the rule door ------------------------------------------------------------------

    @Test
    fun aRulePassIsRefusedWhenNoRuleIsConfigured() {
        val ledger = book()
        val g = guard(ledger).armed() // no authorizedWindows
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)

        assertFalse(
            "an empty rule list is not a rule",
            g.onReleased(block.eventId, InterceptGuard.RELEASE_RULE, wall),
        )
        assertNull("nothing was recorded as released", g.receipts().firstOrNull())
        assertNotNull("the interception is still open", g.openEventId())
        assertEquals("and nothing was let through", 0L, ledger.state.userReleasedCount)
    }

    @Test
    fun aRulePassIsRefusedOutsideTheConfiguredWindow() {
        val g = guard().armed()
        val now = InterceptGuard.minuteOfDayOf(wall)
        // A window that does not contain this moment: configured, but not applicable now.
        g.setConfig(g.config.copy(authorizedWindows = listOf(now + 120 until now + 180)), wall)
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)

        assertFalse("outside the window there is no rule to use", g.onReleased(block.eventId, InterceptGuard.RELEASE_RULE, wall))
        assertNotNull(g.openEventId())
    }

    @Test
    fun aRulePassIsGrantedInsideTheConfiguredWindow() {
        val g = guard().armed()
        val now = InterceptGuard.minuteOfDayOf(wall)
        g.setConfig(g.config.copy(authorizedWindows = listOf(now until now + 60)), wall)
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)

        assertTrue("inside the window the rule door is real", g.onReleased(block.eventId, InterceptGuard.RELEASE_RULE, wall))
        assertEquals(InterceptOutcome.RELEASED, g.receipts().first().outcome)
        assertEquals(InterceptGuard.RELEASE_RULE, g.receipts().first().releasedBy)
        assertNull("the interception closed", g.openEventId())
    }

    @Test
    fun theSettingsPageCanTellWhetherTheRuleDoorExists() {
        val g = guard().armed()
        assertFalse("no window, no door to offer", g.ruleDoorExists())
        g.setConfig(g.config.copy(authorizedWindows = listOf(0 until 1439)), wall)
        assertTrue("a configured window means the door may be offered", g.ruleDoorExists())
    }

    // ---- 2. an unknown door grants nothing -------------------------------------------------

    @Test
    fun anUnknownReleaseCodeGrantsNothing() {
        val g = guard().armed()
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)
        assertFalse("an invented code is not a door", g.onReleased(block.eventId, "freebie", wall))
        assertFalse("an empty code is not a door", g.onReleased(block.eventId, "", wall))
        assertNotNull("still open", g.openEventId())
    }

    // ---- 3. the whitelist door is explicit, and standing -----------------------------------

    @Test
    fun aWhitelistPassAddsTheAppToTheWhitelistForGood() {
        val g = guard().armed()
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)
        assertTrue(g.onReleased(block.eventId, InterceptGuard.RELEASE_WHITELIST, wall))
        assertTrue("a standing decision, not a timer", bili in g.config.whitelist)

        // Later, well past any release window, the app is still let through - by the whitelist.
        wall += 24 * 3_600_000L
        day += 1
        val again = g.onForeground(bili, env(), wall)
        assertEquals(InterceptDecision.Allow(bili, InterceptRules.REASON_WHITELIST), again)
    }

    // ---- 4. a stale page cannot use a new event's door -------------------------------------

    @Test
    fun aStalePageCannotReleaseAnEventItDoesNotOwn() {
        val g = guard().armed()
        val first = blocked(g)
        g.onPageShown(first.eventId, wall)
        assertTrue(g.onExited(first.eventId, wall))

        // A new interception is open; the first page (still finishing its exit animation, or a
        // replayed intent) tries to release it. It must not: the door belongs to an eventId.
        // Past the cooldown too: this test is about who may release, not about the retry window.
        wall += 10 * 60_000L
        day += 1
        val second = blocked(g)
        assertFalse(
            "the old page cannot release the new interception",
            g.onReleased(first.eventId, InterceptGuard.RELEASE_WHITELIST, wall),
        )
        assertEquals(second.eventId, g.openEventId())
        assertFalse("still no whitelist entry granted by the old page", bili in g.config.whitelist)
    }

    // ---- 5. trainingMs is a real rule ------------------------------------------------------

    @Test
    fun trainingNeedsBothASolvedDrillAndTheConfiguredDwellTime() {
        val g = guard().armed(InterceptConfig(enabled = true, trainingMs = 60_000))
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)
        g.solve(block.eventId, block.drill)

        assertFalse(
            "solved instantly is not training",
            g.onReleased(block.eventId, InterceptGuard.RELEASE_TRAINING, wall + 59_999),
        )
        assertTrue(
            "solved and dwelt for trainingMs",
            g.onReleased(block.eventId, InterceptGuard.RELEASE_TRAINING, wall + 60_000),
        )
    }

    @Test
    fun aZeroDwellTimeMakesTheDrillTheOnlyRequirement() {
        val g = guard().armed(InterceptConfig(enabled = true, trainingMs = 0))
        val block = blocked(g)
        g.onPageShown(block.eventId, wall)
        g.solve(block.eventId, block.drill)
        assertTrue("0 means the dwell rule is off", g.onReleased(block.eventId, InterceptGuard.RELEASE_TRAINING, wall))
    }
}
