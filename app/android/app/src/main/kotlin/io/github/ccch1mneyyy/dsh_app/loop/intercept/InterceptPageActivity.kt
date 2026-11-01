package io.github.ccch1mneyyy.dsh_app.loop.intercept

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
import io.github.ccch1mneyyy.dsh_app.loop.core.InterceptDrill
import io.github.ccch1mneyyy.dsh_app.i18n.AppStrings

/**
 * 濞变箰 APP 鎷︽埅椤?(round 4, M1). One page per interception, bound to the eventId the guard minted
 * when the rule matched 鈥?the same discipline as ProactivePageActivity: the page never invents an id
 * or a timestamp, and every report names the interception it belongs to.
 *
 * **onResume alone is not "the page is on screen".** The intercept ledger counts a *block* only
 * when this page proves it is really in front of the person (decor attached + shown + laid out +
 * focused), because "we showed a blocking page" is a claim about the person's attention. A page
 * started behind the lock screen, or covered at once, must not be recorded as a block.
 *
 * The five ways out, all reported to the guard (which owns the policy and the receipt):
 *
 *   training passed  -> Released("training")   the training page stayed up long enough
 *   authorization    -> Released("rule")       passage for InterceptConfig.releaseMs
 *   whitelist        -> Released("whitelist")  a standing decision, not a timer
 *   pause            -> Paused                 every target let through for a while
 *   emergency exit   -> Exited                 leave at once; never a release
 */
class InterceptPageActivity : Activity() {
    private val main = Handler(Looper.getMainLooper())
    private var eventId: String? = null
    private var packageName: String? = null
    private var reported = false

    /** The block was proven on screen and reported; the page may now offer its ways out. */
    private var shown = false
    private var attempts = 0
    private val proof = Runnable { proveVisible() }

    /**
     * 训练题: the checkable door. The guard mints it from the eventId and only accepts
     * [InterceptRuntime.RELEASE_TRAINING] once every candidate was pressed in order, so this page
     * renders and forwards presses - it never decides whether training was passed.
     */
    private var drill: InterceptDrill? = null
    private var trainingButton: Button? = null
    private var drillStatus: TextView? = null
    private val drillButtons = LinkedHashMap<Int, Button>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setFinishOnTouchOutside(false)
        if (savedInstanceState != null) { finish(); return } // restored by the system: the interception is gone
        bind(intent)
    }

    override fun onNewIntent(next: Intent) {
        super.onNewIntent(next)
        // singleInstance: a newer interception replaces this one; the old eventId simply goes stale.
        unregister()
        reported = false
        shown = false
        setIntent(next)
        bind(next)
    }

    private fun bind(start: Intent) {
        val id = start.getStringExtra(EXTRA_EVENT_ID)
        val label = start.getStringExtra(EXTRA_LABEL)
        if (id == null || label == null || start.getLongExtra(EXTRA_DEADLINE, 0) <= System.currentTimeMillis()) {
            finish(); return
        }
        eventId = id
        packageName = start.getStringExtra(EXTRA_PACKAGE)
        drill = InterceptRuntime.drill(id)
        live[id] = this
        setContentView(content(label))
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

    private fun awaitVisible() {
        attempts = 0
        main.removeCallbacks(proof)
        main.post(proof)
    }

    /** Same proof as the proactive page: attached, shown, laid out and focused - nothing less. */
    private fun proveVisible() {
        val id = eventId ?: return
        if (reported || shown) return
        val decor = runCatching { window?.decorView }.getOrNull()
        val visible = decor != null && decor.isAttachedToWindow && decor.isShown &&
            decor.width > 0 && decor.height > 0 && decor.hasWindowFocus()
        if (visible) {
            shown = true
            main.removeCallbacks(proof)
            InterceptRuntime.onPageShown(id)
            render()
            return
        }
        if (++attempts <= MAX_PROOF_ATTEMPTS) main.postDelayed(proof, PROOF_STEP_MS)
    }

    /** Leaving the page without choosing anything is an exit: the person went away from the app. */
    @Deprecated("Activity back handling; targetSdk 28")
    override fun onBackPressed() = exit()

    override fun onStop() {
        super.onStop()
        val screenOn = getSystemService(PowerManager::class.java)?.isInteractive != false
        if (!reported && !isChangingConfigurations && screenOn && !isFinishing) exit()
    }

    override fun onDestroy() {
        main.removeCallbacks(proof)
        // Free the shared visible-surface slot before unregistering: whichever way this page ended
        // (released, exited, paused, back-press, destroyed by the system), the screen is free again.
        InterceptRuntime.onPageGone(eventId)
        unregister()
        super.onDestroy()
    }


    private fun release(how: String) {
        val id = eventId ?: return
        if (reported) return
        reported = true
        main.removeCallbacks(proof)
        val opened = InterceptRuntime.onReleased(id, how)
        val pkg = packageName
        if (!isFinishing) finish()
        // A release is meant to work: if the guard accepted it, put the app back in front.
        if (opened && pkg != null) InterceptRuntime.openTarget(this, pkg)
    }

    private fun exit() {
        val id = eventId ?: return
        if (reported) return
        reported = true
        main.removeCallbacks(proof)
        InterceptRuntime.onExited(id)
        if (!isFinishing) finish()
        // The emergency exit goes home, never back into the app it just refused.
        runCatching {
            startActivity(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    private fun pause() {
        val id = eventId ?: return
        if (reported) return
        reported = true
        main.removeCallbacks(proof)
        InterceptRuntime.onPaused(id)
        val pkg = packageName
        if (!isFinishing) finish()
        if (pkg != null) InterceptRuntime.openTarget(this, pkg)
    }

    private fun unregister() { eventId?.let { if (live[it] === this) live.remove(it) } }

    private fun render() {
        val d = drill
        val solved = d?.solved == true
        trainingButton?.let { b ->
            b.text = AppStrings.get(
                this,
                if (solved) R.string.intercept_training else R.string.intercept_training_locked,
            )
            // The button only ever offers what the guard will accept: a solved drill.
            b.isEnabled = shown && solved
        }
        drillStatus?.let { t ->
            t.text = when {
                d == null -> ""
                solved -> AppStrings.get(this, R.string.intercept_training)
                d.wrongAttempts > 0 && d.cursor == 0 -> AppStrings.get(this, R.string.intercept_drill_wrong)
                else -> AppStrings.get(this, R.string.intercept_drill_progress, d.cursor, d.candidates.size)
            }
        }
        renderDrillButtons()
    }

    /** The candidate buttons: pressed ones go quiet, and the order is never hinted. */
    private fun renderDrillButtons() {
        val d = drill ?: return
        val order = if (d.ascending) d.candidates.sorted() else d.candidates.sortedDescending()
        val done = order.take(d.cursor).toSet()
        drillButtons.forEach { (value, button) ->
            button.isEnabled = shown && !d.solved && value !in done
        }
    }

    /** One press: forwarded to the guard, which is the only thing that can accept a pass. */
    private fun tapDrill(value: Int) {
        val id = eventId ?: return
        if (InterceptRuntime.tapDrill(id, value)) {
            drill = InterceptRuntime.drill(id)
            render()
        }
    }

    private fun drillRow(ctx: android.content.Context, dp: (Int) -> Int): LinearLayout {
        val d = drill ?: return LinearLayout(ctx)
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 0, 0, dp(12))
        }
        for (value in d.candidates) {
            row.addView(Button(ctx).apply {
                text = value.toString()
                minimumWidth = dp(56)
                setOnClickListener { tapDrill(value) }
                drillButtons[value] = this
            })
        }
        return row
    }


    private fun content(label: String): LinearLayout {
        fun dp(v: Int) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
        val ctx = this
        val releaseMinutes = (InterceptRuntime.releaseMs() / 60_000L).coerceAtLeast(1L).toInt()
        return LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(20), dp(24), dp(12))
            addView(TextView(ctx).apply {
                text = AppStrings.get(ctx, R.string.intercept_title, label)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            })
            addView(TextView(ctx).apply {
                text = AppStrings.get(ctx, R.string.intercept_body, label)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                setPadding(0, dp(8), 0, dp(16))
            })
            // The 训练题: the only door that does not spend money or time, and it has to be earned.
            drill?.let { d ->
                addView(TextView(ctx).apply {
                    text = AppStrings.get(
                        ctx, R.string.intercept_drill_prompt,
                        AppStrings.get(
                            ctx,
                            if (d.ascending) R.string.intercept_drill_ascending else R.string.intercept_drill_descending,
                        ),
                    )
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                    setPadding(0, 0, 0, dp(8))
                })
                addView(drillRow(ctx, ::dp))
                addView(TextView(ctx).apply {
                    drillStatus = this
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
                    setPadding(0, 0, 0, dp(12))
                })
            }
            // The ways out, in increasing order of commitment: the drill, timed pass, standing pass,
            // pause everything, leave. Every button names this page's eventId, never a new one.
            addView(Button(ctx).apply {
                trainingButton = this
                isEnabled = false
                setOnClickListener { if (drill?.solved == true) release(InterceptRuntime.RELEASE_TRAINING) }
            })
            addView(Button(ctx).apply {
                text = AppStrings.get(ctx, R.string.intercept_rule, releaseMinutes)
                setOnClickListener { release(InterceptRuntime.RELEASE_RULE) }
            })
            addView(Button(ctx).apply {
                text = AppStrings.get(ctx, R.string.intercept_whitelist)
                setOnClickListener { release(InterceptRuntime.RELEASE_WHITELIST) }
            })
            addView(LinearLayout(ctx).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.END
                addView(Button(ctx).apply {
                    text = AppStrings.get(ctx, R.string.intercept_pause)
                    setOnClickListener { pause() }
                })
                addView(Button(ctx).apply {
                    text = AppStrings.get(ctx, R.string.intercept_exit)
                    setOnClickListener { exit() }
                })
            })
        }
    }

    companion object {
        private const val EXTRA_EVENT_ID = "intercept_event_id"
        private const val EXTRA_PACKAGE = "intercept_package"
        private const val EXTRA_LABEL = "intercept_label"
        private const val EXTRA_TRAINING_MS = "intercept_training_ms"
        private const val EXTRA_DEADLINE = "intercept_deadline"

        /** ~2 s of retries for the visibility proof, like the proactive page. */
        private const val PROOF_STEP_MS = 100L
        private const val MAX_PROOF_ATTEMPTS = 20

        /** Pages on screen by eventId, so a withdrawal can close them. Main thread only. */
        private val live = HashMap<String, InterceptPageActivity>()

        /** Started from DSH's own process; false if the system refused at once. */
        fun start(context: Context, eventId: String, pkg: String, label: String, trainingMs: Long, deadline: Long): Boolean = runCatching {
            context.startActivity(
                Intent(context, InterceptPageActivity::class.java)
                    .putExtra(EXTRA_EVENT_ID, eventId).putExtra(EXTRA_PACKAGE, pkg)
                    .putExtra(EXTRA_LABEL, label.take(64)).putExtra(EXTRA_TRAINING_MS, trainingMs)
                    .putExtra(EXTRA_DEADLINE, deadline)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or Intent.FLAG_ACTIVITY_NO_ANIMATION),
            )
        }.isSuccess

        fun withdraw(eventId: String) { live.remove(eventId)?.let { it.reported = true; it.finish() } }

        fun withdrawAll() {
            live.values.toList().forEach { it.reported = true; it.finish() }
            live.clear()
            InterceptRuntime.onPageGone(null)
        }
    }
}

