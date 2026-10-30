package io.github.ccch1mneyyy.dsh_app.loop

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * InteractionHub v1: one surface (a small DSH page), one button. Later surfaces (overlay,
 * notification) plug in behind [show] with the same rule: the page answers through
 * [LoopEngine.answer], and whoever answers first wins.
 *
 * Started from the accessibility service, which Android lets start activities from the
 * background. If the page is not on screen within [SHOW_DEADLINE_MS] the event closes as
 * UNAVAILABLE (e.g. a ROM that blocks "show pop-up windows while running in the background").
 */
object InteractionHub {
    private const val TAG = "DshLoop"
    private const val SHOW_DEADLINE_MS = 3_000L
    internal const val EXTRA_EVENT = "loop_event_id"
    internal const val EXTRA_TIMEOUT = "loop_timeout_ms"
    internal const val EXTRA_PACKAGE = "loop_package"

    private val main = Handler(Looper.getMainLooper())

    fun show(context: Context, engine: LoopEngine, show: LoopEngine.Outcome.Show) {
        val id = show.event.eventId
        val intent = Intent(context, InteractionActivity::class.java)
            .putExtra(EXTRA_EVENT, id)
            .putExtra(EXTRA_TIMEOUT, show.timeoutMs)
            .putExtra(EXTRA_PACKAGE, show.event.packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or Intent.FLAG_ACTIVITY_NO_ANIMATION)
        try {
            context.startActivity(intent)
        } catch (t: Throwable) {
            Log.w(TAG, "start page", t)
            engine.answer(id, EventResult.UNAVAILABLE, reason = "start_failed", error = t.javaClass.simpleName)
            return
        }
        main.postDelayed({
            // Still TRIGGERED (never SHOWN) after the deadline: the start was swallowed.
            if (engine.stateOf(id) == EventState.TRIGGERED) {
                engine.answer(id, EventResult.UNAVAILABLE, reason = "not_shown")
            }
        }, SHOW_DEADLINE_MS)
    }
}
