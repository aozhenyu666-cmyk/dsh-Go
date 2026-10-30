package io.github.ccch1mneyyy.dsh_app.loop

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.github.ccch1mneyyy.dsh_app.R
import io.github.ccch1mneyyy.dsh_app.i18n.AppStrings

/**
 * The interaction page of the first loop: says which app was opened, offers one 返回 button.
 * Its own task (manifest: taskAffinity, excludeFromRecents), so finishing it puts the person back
 * in the test app, and it never touches DSH's main Flutter task.
 *
 * Every way out closes the event once: button → RETURNED, back → BACK, leaving the screen →
 * DISMISSED, deadline → TIMEOUT. A page whose event is already closed (stale intent) finishes
 * at once.
 */
class InteractionActivity : Activity() {
    private val main = Handler(Looper.getMainLooper())
    private var eventId: String? = null
    private var closed = false
    private val timeout = Runnable { close(EventResult.TIMEOUT) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setFinishOnTouchOutside(false)
        // Recreated after process death: recovery already closed that event.
        if (savedInstanceState != null) { closed = true; finish(); return }
        bind(intent)
    }

    /** singleInstance: a start while an older page is still finishing lands here. */
    override fun onNewIntent(next: Intent) {
        super.onNewIntent(next)
        if (!closed) close(EventResult.DISMISSED, finish = false, reason = "replaced")
        setIntent(next)
        bind(next)
    }

    private fun bind(start: Intent) {
        val id = start.getStringExtra(InteractionHub.EXTRA_EVENT)
        // A stale start (its event already closed, e.g. by the not-shown watchdog) shows nothing.
        if (id == null || !LoopRuntime.engine(this).shown(id)) { closed = true; finish(); return }
        eventId = id
        closed = false
        val pkg = start.getStringExtra(InteractionHub.EXTRA_PACKAGE)
        val label = pkg?.let { p -> runCatching { packageManager.getApplicationLabel(packageManager.getApplicationInfo(p, 0)).toString() }.getOrNull() } ?: pkg.orEmpty()
        setContentView(content(label))
        val ms = start.getLongExtra(InteractionHub.EXTRA_TIMEOUT, LoopConfig.DEFAULT_TIMEOUT_MS)
        main.removeCallbacks(timeout)
        main.postDelayed(timeout, ms.coerceIn(5_000, 10 * 60_000L))
    }

    private fun content(label: String): LinearLayout {
        fun dp(v: Int) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(20), dp(24), dp(12))
            addView(TextView(this@InteractionActivity).apply {
                text = AppStrings.get(this@InteractionActivity, R.string.loop_page_title)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            })
            addView(TextView(this@InteractionActivity).apply {
                text = AppStrings.get(this@InteractionActivity, R.string.loop_page_text, label)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setPadding(0, dp(12), 0, dp(16))
            })
            addView(Button(this@InteractionActivity).apply {
                text = AppStrings.get(this@InteractionActivity, R.string.loop_page_return)
                setOnClickListener { close(EventResult.RETURNED) }
            }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                gravity = Gravity.END
            })
        }
    }

    @Deprecated("Activity back handling; targetSdk 28")
    override fun onBackPressed() = close(EventResult.BACK)

    override fun onStop() {
        super.onStop()
        // Home, recents, another app or screen off took the page away without an answer.
        if (!closed && !isChangingConfigurations) close(EventResult.DISMISSED)
    }

    override fun onDestroy() {
        main.removeCallbacks(timeout)
        if (!closed && !isChangingConfigurations) close(EventResult.DISMISSED, finish = false)
        super.onDestroy()
    }

    private fun close(result: EventResult, finish: Boolean = true, reason: String? = null) {
        if (closed) return
        closed = true
        main.removeCallbacks(timeout)
        eventId?.let { LoopRuntime.engine(this).answer(it, result, reason) }
        if (finish && !isFinishing) finish()
    }
}
