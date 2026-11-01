package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 4B · D5: 授权语义。**只有用户真的授权了，才放行。**
 *
 * 这一组测试盯的是两条"technically 合理、语义上错误"的返回：
 *
 *   * `cooldownMs` 到点 → Allow。冷却的本意是"别马上再弹一次题"，它变成了"这段时间随便用"。
 *   * `dailyMax` 到量 → Allow。每日上限的本意是"今天别再打扰了"，它变成了"今天全部放行"。
 *
 * 两者都是把**降噪手段**冒充成**访问许可**。D5 要求：放行只来自 WHITELIST / RELEASED /
 * PAUSED / 授权时段。冷却与日上限只影响"还弹不弹题"，绝不能自行下发许可。
 */
class InterceptAuthorizationSemanticsTest {

    private var wall = 1_793_340_000_000L
    private var seq = 0
    private val bili = "tv.danmaku.bili"

    private fun env() = InterceptEnv(screenOn = true, unlocked = true, dshBusy = false, minuteOfDay = 720, dayKey = 20_000L)

    private inner class Rig(cooldownMs: Long = 0, dailyMax: Int = 0, releaseMs: Long = 600_000L) {
        val book = InterceptLedgerBook(MemorySnapshotStore()).also { it.recover() }
        val guard = InterceptGuard(MemorySnapshotStore(), book, { wall }) { "evt-" + (++seq) }.also { it.recover(wall) }
        init {
            guard.setConfig(
                InterceptConfig(
                    enabled = true,
                    targets = listOf(InterceptTarget(bili, "Bilibili")),
                    cooldownMs = cooldownMs,
                    dailyMax = dailyMax,
                    releaseMs = releaseMs,
                    trainingMs = 0,
                ),
                wall,
            )
        }

        fun shownBlock(): InterceptDecision.Block {
            val d = guard.onForeground(bili, env(), wall)
            assertTrue("blocks", d is InterceptDecision.Block)
            val b = d as InterceptDecision.Block
            assertTrue(guard.onPageShown(b.eventId, wall))
            return b
        }
    }

    // ---- EXITED 之后立刻重开：必须再拦 ------------------------------------------------

    @Test
    fun after_an_exit_the_app_is_intercepted_again_not_let_through() {
        val r = Rig(cooldownMs = 2 * 60_000L) // a real cooldown configured, as a user would
        val b = r.shownBlock();
        assertTrue(r.guard.onExited(b.eventId, wall))
        wall += 1_000L
        val again = r.guard.onForeground(bili, env(), wall)
        assertTrue(
            "D5: an exit grants no passage, cooldown or not",
            again is InterceptDecision.Block,
        )
    }

    // ---- BLOCKED 之后立刻重开：必须再拦 ----------------------------------------------

    @Test
    fun after_a_block_that_reached_its_ttl_the_app_is_intercepted_again() {
        val r = Rig(cooldownMs = 2 * 60_000L)
        val b = r.shownBlock();
        assertTrue(r.guard.expireOpen(b.eventId, wall + 10 * 60_000L))
        val again = r.guard.onForeground(bili, env(), wall + 10 * 60_000L + 1_000L)
        assertTrue("a blocked interception grants nothing", again is InterceptDecision.Block)
    }

    // ---- NOT_SHOWN 之后立刻重开：必须再拦 --------------------------------------------

    @Test
    fun after_a_not_shown_the_app_is_intercepted_again() {
        val r = Rig(cooldownMs = 2 * 60_000L)
        val d = r.guard.onForeground(bili, env(), wall) as InterceptDecision.Block
        assertTrue(r.guard.onUnavailable(d.eventId, "no_visibility_proof", wall))
        wall += 500L
        assertTrue("a page that never appeared grants nothing", r.guard.onForeground(bili, env(), wall) is InterceptDecision.Block)
    }

    // ---- dailyMax=1：EXITED 之后再开仍要拦，且不再弹题 -------------------------------

    @Test
    fun daily_max_of_one_does_not_become_a_free_pass_after_an_exit() {
        val r = Rig(cooldownMs = 0, dailyMax = 1)
        val b = r.shownBlock();
        assertTrue(r.guard.onExited(b.eventId, wall))
        wall += 1_000L
        val again = r.guard.onForeground(bili, env(), wall)
        // The daily budget is spent, so no new question can be asked today. That is a limit on
        // INTERRUPTIONS. It must not read as permission, so the answer is neither a new Block nor
        // an Allow: it is Ignore — leave the app alone, but do not claim it was authorised.
        assertTrue(
            "the daily cap limits interruptions, it does not authorise passage: " + again,
            again is InterceptDecision.Ignore,
        )
    }

    // ---- RELEASED 之后放行，到点重新拦 -----------------------------------------------

    @Test
    fun a_solved_drill_releases_for_the_window_and_then_intercepts_again() {
        val r = Rig(cooldownMs = 0, releaseMs = 60_000L)
        val b = r.shownBlock();
        val order = if (b.drill.ascending) b.drill.candidates.sorted() else b.drill.candidates.sortedDescending()
        for (v in order) assertTrue(r.guard.tapDrill(b.eventId, v))
        assertTrue(r.guard.onReleased(b.eventId, InterceptGuard.RELEASE_TRAINING, wall))

        val during = r.guard.onForeground(bili, env(), wall + 1_000L)
        assertTrue("the release is a real permission", during is InterceptDecision.Allow)
        assertEquals(InterceptRules.REASON_RELEASED, (during as InterceptDecision.Allow).reason)

        val after = r.guard.onForeground(bili, env(), wall + 61_000L)
        assertTrue("and it expires", after is InterceptDecision.Block)
    }

    // ---- PAUSED 到期后重新拦 --------------------------------------------------------

    @Test
    fun a_pause_expires_and_the_app_is_intercepted_again() {
        val r = Rig(cooldownMs = 0)
        assertTrue(r.guard.onPaused(null, 60_000L, wall))
        val during = r.guard.onForeground(bili, env(), wall + 1_000L)
        assertTrue("a pause is a real permission", during is InterceptDecision.Allow)
        assertEquals(InterceptRules.REASON_PAUSED, (during as InterceptDecision.Allow).reason)

        val after = r.guard.onForeground(bili, env(), wall + 61_000L + 60_000L)
        assertTrue("and it expires", after is InterceptDecision.Block)
    }

    // ---- WHITELIST 永久 ------------------------------------------------------------

    @Test
    fun a_whitelist_entry_is_a_permanent_permission_until_removed() {
        val r = Rig(cooldownMs = 0)
        val b = r.shownBlock();
        assertTrue(r.guard.onReleased(b.eventId, InterceptGuard.RELEASE_WHITELIST, wall))
        val far = wall + 30L * 24 * 3_600_000L
        val later = r.guard.onForeground(bili, env(), far)
        assertTrue("still allowed a month later", later is InterceptDecision.Allow)
        assertEquals(InterceptRules.REASON_WHITELIST, (later as InterceptDecision.Allow).reason)
    }

    // ---- 技术退避不等于授权：这些 Allow 的理由不得是冷却/日上限 ----------------------

    @Test
    fun no_allow_is_ever_reasoned_from_a_cooldown_or_a_daily_cap() {
        // Sweep the states that used to produce Allow(cooldown)/Allow(daily_max) and assert that
        // whatever comes back, it never claims passage for a technical reason.
        val r = Rig(cooldownMs = 5 * 60_000L, dailyMax = 1)
        val b = r.shownBlock();
        r.guard.onExited(b.eventId, wall)
        for (step in listOf(0L, 1_000L, 60_000L, 5 * 60_000L, 10 * 60_000L)) {
            val d = r.guard.onForeground(bili, env(), wall + step)
            if (d is InterceptDecision.Allow) {
                assertTrue(
                    "an Allow must never cite a cooldown: " + d.reason,
                    d.reason != InterceptRules.REASON_COOLDOWN,
                )
                assertTrue(
                    "an Allow must never cite a daily cap: " + d.reason,
                    d.reason != InterceptRules.REASON_DAILY_MAX,
                )
            }
        }
    }
}
