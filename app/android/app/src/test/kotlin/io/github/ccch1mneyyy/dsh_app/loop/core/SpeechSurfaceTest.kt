package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * P4 语音渠道：15 分钟换渠道那一级念出来，而不是等屏幕亮。
 *
 * 关键几条：
 *  - 锁着、灭屏也能到耳朵里（这正是阶梯存在的原因）；
 *  - DSH 自己在用屏幕时照样让开，不念；
 *  - 念不成退回通知，不浪费这一球；
 *  - 念出去的球没有「看到」这回事，只算送达。
 */
class SpeechSurfaceTest {
    private var now = 1_700_000_000_000L
    private var seq = 0
    private fun coordinator(cfg: CoordinatorConfig = CoordinatorConfig()) =
        Coordinator(MemorySnapshotStore(), cfg, { now }, { "id${++seq}" })

    private fun req(id: String, source: String = Switches.SOURCE_SCHEDULER) =
        EventRequest(id, source, "chat", id, Priority.NORMAL, now, 600_000, false, "hi")

    private fun Step.present() = commands.filterIsInstance<Command.Present>().single()

    @Test fun aLockedPhoneStillGetsTheBallSpoken() {
        val locked = Gate(screenOn = false, unlocked = false, speech = true)
        assertEquals(Surface.SPEECH, locked.surface())
        // 同一个锁屏现场，没有语音渠道时什么都不能出。
        assertNull(Gate(screenOn = false, unlocked = false).surface())
    }

    @Test fun speechGivesWayToDshItself() {
        assertNull("DSH 在跑任务时别念", Gate(screenOn = false, speech = true, dshTaskActive = true).surface())
        assertNull("DSH 开着问句时别念", Gate(screenOn = false, speech = true, dshPromptOpen = true).surface())
        assertNull("整块关掉时不念", Gate(screenOn = false, speech = true, featureEnabled = false).surface())
    }

    @Test fun aSpokenBallIsDeliveredButNeverSeen() {
        val c = coordinator().also { it.recover(Gate(screenOn = false, unlocked = false, speech = true)) }
        val p = c.submit(req("a")).second.present()
        assertEquals(Surface.SPEECH, p.surface)

        c.onSurface(p.token, SurfaceReport.Posted)
        val e = c.active()!!
        assertEquals(Stage.DELIVERED, e.stage)
        assertEquals(now, e.deliveredAt)
        assertNull("念出来不等于他看到了", e.shownAt)
        assertEquals("等同一个回应窗口", now + 10 * 60_000, e.interactionDeadline)

        // 页面才有的「我看到了」对念出去的球无效。
        c.onSurface(p.token, SurfaceReport.Acked)
        assertNull(c.active()!!.acknowledgedAt)
    }

    @Test fun aSpokenBallIsWithdrawnWhenNobodyAnswers() {
        val c = coordinator().also { it.recover(Gate(screenOn = false, speech = true)) }
        val p = c.submit(req("a")).second.present()
        c.onSurface(p.token, SurfaceReport.Posted)
        now += 10 * 60_000
        val closed = c.tick().commands.filterIsInstance<Command.Withdraw>().single()
        assertEquals(Surface.SPEECH, closed.surface)
        assertEquals(Outcome.TIMEOUT, c.find("a")!!.outcome)
    }

    @Test fun aFailedVoiceFallsBackToTheNotificationOnce() {
        val c = coordinator().also { it.recover(Gate(screenOn = false, speech = true)) }
        val p = c.submit(req("a")).second.present()
        assertEquals(Surface.SPEECH, p.surface)

        val after = c.onSurface(p.token, SurfaceReport.Failed("no_tts"))
        assertEquals("念不成也要到达他", Surface.NOTIFICATION, after.present().surface)

        // 通知也失败就收手，不再来回试。
        val token = c.active()!!.token!!
        c.onSurface(token, SurfaceReport.Failed("no_notification"))
        assertEquals(Outcome.UNAVAILABLE, c.find("a")!!.outcome)
    }

    @Test fun speechIsOnlyTheChannelItWasAskedFor() {
        // 没点过语音的球，锁屏时仍然什么都不出：不因为「有个语音渠道」就自己开口。
        val c = coordinator().also { it.recover(Gate(screenOn = false, unlocked = false)) }
        val step = c.submit(req("a")).second
        assertTrue(step.commands.filterIsInstance<Command.Present>().isEmpty())
        assertEquals(Stage.QUEUED, c.find("a")!!.stage)
    }

    @Test fun anotherProducersBallIsNeverSpoken() {
        // 「刚念过一球」不该扩散：走进某个 App 触发的球照旧显示，锁着屏就等着。
        val c = coordinator().also { it.recover(Gate(screenOn = false, unlocked = false, speech = true)) }
        val step = c.submit(req("a", source = Switches.SOURCE_APP_ENTER)).second
        assertTrue(step.commands.filterIsInstance<Command.Present>().isEmpty())
        assertEquals(Stage.READY, c.find("a")!!.stage)
    }
}
