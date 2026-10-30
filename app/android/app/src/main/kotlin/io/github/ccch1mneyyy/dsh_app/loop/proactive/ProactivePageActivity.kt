package io.github.ccch1mneyyy.dsh_app.loop.proactive

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.PowerManager
import android.util.TypedValue
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.github.ccch1mneyyy.dsh_app.R
import io.github.ccch1mneyyy.dsh_app.i18n.AppStrings
import io.github.ccch1mneyyy.dsh_app.loop.core.SurfaceReport

/**
 * The proactive page. It knows only its token: every report carries it, and the coordinator
 * refuses any token that is not the current presentation, so a page left over from a withdrawn,
 * restarted or replaced presentation can never answer a newer event.
 *
 * Reports: first resume → Shown; 回应 → Answered("reply"); 稍后 / back / leaving → Dismissed.
 * Screen off is not an answer: the page stays and the coordinator's deadline decides.
 */
class ProactivePageActivity : Activity() {
    private var token: String? = null
    private var reported = false
    private var shown = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setFinishOnTouchOutside(false)
        if (savedInstanceState != null) { finish(); return } // restored by the system: the event is gone
        bind(intent)
    }

    override fun onNewIntent(next: Intent) {
        super.onNewIntent(next)
        // singleInstance: a newer presentation replaces this one; the old token simply goes stale.
        unregister()
        reported = false
        shown = false
        setIntent(next)
        bind(next)
    }

    private fun bind(start: Intent) {
        val t = start.getStringExtra(EXTRA_TOKEN)
        val text = start.getStringExtra(EXTRA_TEXT)
        if (t == null || text == null || start.getLongExtra(EXTRA_DEADLINE, 0) <= System.currentTimeMillis()) { finish(); return }
        token = t
        live[t] = this
        setContentView(content(text))
    }

    override fun onResume() {
        super.onResume()
        val t = token ?: return
        if (!shown) { shown = true; ProactiveRuntime.onSurface(t, SurfaceReport.Shown) }
    }

    @Deprecated("Activity back handling; targetSdk 28")
    override fun onBackPressed() = report(SurfaceReport.Dismissed)

    override fun onStop() {
        super.onStop()
        val screenOn = getSystemService(PowerManager::class.java)?.isInteractive != false
        if (!reported && !isChangingConfigurations && screenOn && !isFinishing) report(SurfaceReport.Dismissed)
    }

    override fun onDestroy() {
        unregister()
        super.onDestroy()
    }

    private fun report(r: SurfaceReport) {
        val t = token ?: return
        if (reported) return
        reported = true
        ProactiveRuntime.onSurface(t, r)
        if (!isFinishing) finish()
    }

    private fun unregister() { token?.let { if (live[it] === this) live.remove(it) } }

    private fun content(text: String): LinearLayout {
        fun dp(v: Int) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
        val ctx = this
        return LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(20), dp(24), dp(12))
            addView(TextView(ctx).apply { this.text = text; setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f); setPadding(0, 0, 0, dp(16)) })
            addView(LinearLayout(ctx).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.END
                addView(Button(ctx).apply {
                    this.text = AppStrings.get(ctx, R.string.proactive_later)
                    setOnClickListener { report(SurfaceReport.Dismissed) }
                })
                addView(Button(ctx).apply {
                    this.text = AppStrings.get(ctx, R.string.proactive_reply)
                    setOnClickListener { report(SurfaceReport.Answered("reply")) }
                })
            })
        }
    }

    companion object {
        private const val EXTRA_TOKEN = "proactive_token"
        private const val EXTRA_TEXT = "proactive_text"
        private const val EXTRA_DEADLINE = "proactive_deadline"
        /** Pages on screen by token, for Withdraw. Main thread only. */
        private val live = HashMap<String, ProactivePageActivity>()

        /** Started from the accessibility service's process; false if the system refused at once. */
        fun start(context: Context, token: String, text: String, deadline: Long): Boolean = runCatching {
            context.startActivity(Intent(context, ProactivePageActivity::class.java)
                .putExtra(EXTRA_TOKEN, token).putExtra(EXTRA_TEXT, text.take(2_000)).putExtra(EXTRA_DEADLINE, deadline)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or Intent.FLAG_ACTIVITY_NO_ANIMATION))
        }.isSuccess

        fun withdraw(token: String) { live.remove(token)?.let { it.reported = true; it.finish() } }

        fun withdrawAll() { live.values.toList().forEach { it.reported = true; it.finish() }; live.clear() }
    }
}
