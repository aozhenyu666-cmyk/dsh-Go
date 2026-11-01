package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The shared visible-surface slot (round 4 integration).
 *
 * The point of these tests is the *conflict*: 主动搭话 and 娱乐拦截 are two activities that can both
 * ask for the screen in the same window-change. Without one slot they stack. These pin the rules
 * that keep them from doing so, and the stale-release guard that stops a dying page from freeing
 * the page that replaced it.
 */
class SurfaceSlotTest {

    private fun slot() = SurfaceSlot()

    @Test
    fun a_free_slot_is_claimed_by_the_first_caller() {
        val s = slot()
        assertTrue(s.isFree())
        assertTrue(s.claim("proactive", "tok-1", 100))
        assertEquals("proactive", s.holder)
        assertEquals("tok-1", s.holderToken)
        assertEquals(100L, s.heldSince())
        assertFalse(s.isFree())
    }

    @Test
    fun the_second_feature_cannot_take_a_slot_that_is_already_held() {
        val s = slot()
        assertTrue(s.claim("proactive", "tok-1", 100))
        // The person opens a target app while the proactive page is up: the intercept must not stack.
        assertFalse(s.claim("intercept", "evt-1", 200))
        assertEquals("proactive", s.holder)
        assertEquals("tok-1", s.holderToken)
    }

    @Test
    fun the_same_instance_may_claim_again() {
        val s = slot()
        assertTrue(s.claim("intercept", "evt-1", 100))
        // A repeated Present for the same token is not a conflict; it is the same surface.
        assertTrue(s.claim("intercept", "evt-1", 150))
        assertEquals(100L, s.heldSince())
    }

    @Test
    fun a_new_token_from_the_same_owner_still_conflicts() {
        val s = slot()
        assertTrue(s.claim("proactive", "tok-1", 100))
        // A different presentation replaces the old one in the activity (singleInstance); the slot
        // must be released by the old page first, so the kernel does not silently drop the new one.
        assertFalse(s.claim("proactive", "tok-2", 200))
    }

    @Test
    fun only_the_holder_can_release() {
        val s = slot()
        assertTrue(s.claim("proactive", "tok-1", 100))
        assertFalse(s.release("intercept", null))
        assertEquals("proactive", s.holder)
        assertTrue(s.release("proactive", "tok-1"))
        assertTrue(s.isFree())
    }

    @Test
    fun a_stale_release_cannot_free_the_replacement_surface() {
        val s = slot()
        assertTrue(s.claim("intercept", "evt-1", 100))
        assertTrue(s.release("intercept", "evt-1"))
        assertTrue(s.claim("intercept", "evt-2", 200))
        // The first page's onDestroy arrives late; it must not free evt-2.
        assertFalse(s.release("intercept", "evt-1"))
        assertEquals("evt-2", s.holderToken)
    }

    @Test
    fun releasing_without_a_token_frees_whatever_the_owner_holds() {
        val s = slot()
        assertTrue(s.claim("proactive", "tok-1", 100))
        // withdrawAll() does not know individual tokens; it clears the whole owner.
        assertTrue(s.release("proactive", null))
        assertTrue(s.isFree())
    }

    @Test
    fun a_freed_slot_can_be_taken_by_the_other_feature() {
        val s = slot()
        assertTrue(s.claim("proactive", "tok-1", 100))
        assertTrue(s.release("proactive", "tok-1"))
        assertTrue(s.claim("intercept", "evt-1", 300))
        assertEquals("intercept", s.holder)
    }

    @Test
    fun the_slot_reports_which_feature_is_holding_it() {
        val s = slot()
        assertNull(s.holder)
        assertTrue(s.claim("intercept", "evt-1", 100))
        assertTrue(s.isHeldBy("intercept"))
        assertFalse(s.isHeldBy("proactive"))
    }

    @Test
    fun clearing_drops_the_holder_and_the_timestamp() {
        val s = slot()
        assertTrue(s.claim("proactive", "tok-1", 100))
        s.clear()
        assertTrue(s.isFree())
        assertNull(s.holderToken)
        assertEquals(0L, s.heldSince())
    }
}
