package io.github.ccch1mneyyy.dsh_app.loop.proactive

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
 * The proactive page. It knows only its token: every report carries it, and the coordinator refuses
 * any token that is not the current presentation, so a page left over from a withdrawn, restarted
 * or replaced presentation can never answer a newer event.
 *
 * Reports: page really visible → Shown; 回应 → Answered("reply"); 稍后 / back / leaving → Dismissed.
 * Screen off is not an answer: the page stays and the coordinator's deadline decides.
 *
 * **`onResume` alone is not "Shown".** The coordinator treats Shown as "the person had this on
 * screen" and feeds it into the scheduler's ignored-message backoff, so claiming it for a page
 * nobody saw would corrupt the schedule. An activity can be resumed without being drawn — started
 * behind the lock screen, covered at once by another activity, or on a ROM that lets it be created
 * but never brought forward (the same restriction that makes background activity starts so
 * confusing). Shown is therefore only reported once the decor view is attached, shown, laid out
 * *and* focused; until then the page has merely been posted, and leaving it reports Dismissed.
 */
class ProactivePageActivity : Activity() {
    private val main = Handler(Looper.getMainLooper())
    private var token: String? = null
    private var reported = false

    /** Shown was reported: the page is proven on screen, not merely resumed. */
    private var shown = false
    private var attempts = 0
    private val proof = Runnable { proveVisible() }

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
        if (t == null || text == null || start.getLongExtra(EXTRA_DEADLINE, 0) <= System.currentTimeMillis()) {
            finish(); return
        }
        token = t
        live[t] = this
        setContentView(content(text))
        awaitVisible()
    }

    override fun onResume() {
        super.onResume()
        if (!reported && !shown) awaitVisible()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && !reported && !shown) awaitVisible()
    }

    /**
     * Report Shown only when the page is provably on screen. Retried briefly, because the first
     * layout pass has not finished when [onResume] returns.
     */
    private fun awaitVisible() {
        attempts = 0
        main.removeCallbacks(proof)
        main.post(proof)
    }

    private fun proveVisible() {
        val t = token ?: return
        if (reported || shown) return
        val decor = runCatching { window?.decorView }.getOrNull()
        val visible = decor != null && decor.isAttachedToWindow && decor.isShown &&
            decor.width > 0 && decor.height > 0 && decor.hasWindowFocus()
        if (visible) {
            shown = true
            main.removeCallbacks(proof)
            ProactiveRuntime.onSurface(t, SurfaceReport.Shown)
            return
        }
        if (++attempts <= MAX_PROOF_ATTEMPTS) main.postDelayed(proof, PROOF_STEP_MS)
    }

    @Deprecated("Activity back handling; targetSdk 28")
    override fun onBackPressed() = report(SurfaceReport.Dismissed)

    override fun onStop() {
        super.onStop()
        val screenOn = getSystemService(PowerManager::class.java)?.isInteractive != false
        if (!reported && !isChangingConfigurations && screenOn && !isFinishing) report(SurfaceReport.Dismissed)
    }

    override fun onDestroy() {
        main.removeCallbacks(proof)
        unregister()
        super.onDestroy()
    }

    private fun report(r: SurfaceReport) {
        val t = token ?: return
        if (reported) return
        reported = true
        main.removeCallbacks(proof)
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

        /** ~2 s of retries for the visibility proof. */
        private const val PROOF_STEP_MS = 100L
        private const val MAX_PROOF_ATTEMPTS = 20

        /** Pages on screen by token, for Withdraw. Main thread only. */
        private val live = HashMap<String, ProactivePageActivity>()

        /** Started from the accessibility service's process; false if the system refused at once. */
        fun start(context: Context, token: String, text: String, deadline: Long): Boolean = runCatching {
            context.startActivity(
                Intent(context, ProactivePageActivity::class.java)
                    .putExtra(EXTRA_TOKEN, token).putExtra(EXTRA_TEXT, text.take(2_000)).putExtra(EXTRA_DEADLINE, deadline)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or Intent.FLAG_ACTIVITY_NO_ANIMATION),
            )
        }.isSuccess

        fun withdraw(token: String) { live.remove(token)?.let { it.reported = true; it.finish() } }

        fun withdrawAll() { live.values.toList().forEach { it.reported = true; it.finish() }; live.clear() }
    }
}
