package io.github.ccch1mneyyy.dsh_app.loop.focus

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import io.github.ccch1mneyyy.dsh_app.MainActivity

/**
 * 离开任务应用后立刻盖上的全屏页。只有三个出口：
 * 回到任务 / 休息 5 分钟 / 结束监督。没有答题，也没有「稍后再问」。
 */
class FocusPageActivity : Activity() {
    private var pkg = ""
    private var label = ""
    private var secondsOff = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        read(intent)
        render()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        read(intent)
        render()
    }

    override fun onDestroy() {
        FocusRuntime.onPageGone()
        super.onDestroy()
    }

    private fun read(intent: Intent?) {
        pkg = intent?.getStringExtra(EXTRA_PACKAGE).orEmpty()
        label = intent?.getStringExtra(EXTRA_LABEL).orEmpty().ifEmpty { FocusRuntime.labelOf(pkg) }
        secondsOff = intent?.getLongExtra(EXTRA_SECONDS, 0L) ?: 0L
    }

    private fun render() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.rgb(11, 18, 32), Color.rgb(16, 27, 51)),
            )
            setPadding(dp(24), dp(48), dp(24), dp(32))
        }

        root.addView(
            TextView(this).apply {
                text = "!"
                textSize = 26f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                background = circle(Color.rgb(37, 99, 235))
                layoutParams = LinearLayout.LayoutParams(dp(56), dp(56))
            },
        )

        root.addView(
            TextView(this).apply {
                text = "你离开了正在做的事"
                textSize = 15f
                setTextColor(MUTED)
                gravity = Gravity.CENTER
                setPadding(0, dp(20), 0, dp(6))
            },
        )
        root.addView(
            TextView(this).apply {
                text = "回到「" + FocusRuntime.state().task.ifBlank { "手头这件事" } + "」"
                textSize = 27f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setLineSpacing(0f, 1.15f)
            },
        )
        root.addView(
            TextView(this).apply {
                text = "刚才在「" + label + "」停留了 " + secondsOff.coerceAtLeast(1) + " 秒"
                textSize = 14f
                setTextColor(SOFT)
                gravity = Gravity.CENTER
                setPadding(0, dp(14), 0, 0)
            },
        )

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(Color.rgb(19, 28, 46), dp(18), Color.rgb(34, 48, 74))
            setPadding(dp(18), dp(16), dp(18), dp(16))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(28) }
        }
        card.addView(
            TextView(this).apply {
                text = "不用从头想。先回到刚才那一步，再决定要不要休息。"
                textSize = 14f
                setTextColor(SOFT)
                setLineSpacing(0f, 1.35f)
            },
        )
        root.addView(card)

        root.addView(button("回到任务", primary = true) {
            FocusRuntime.onReturned()
            val target = FocusRuntime.taskPackage()
            val launch = if (target.isNotBlank()) packageManager.getLaunchIntentForPackage(target) else null
            if (launch != null) {
                startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            } else {
                startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            finish()
        })
        root.addView(button("休息 5 分钟") {
            FocusRuntime.pause(5)
            finish()
        })
        root.addView(button("结束监督", secondary = true) {
            FocusRuntime.stop("user")
            finish()
        })

        root.addView(
            TextView(this).apply {
                text = "监督在后台运行；即使 DSH 引擎被系统清掉，这一页仍然会拦。"
                textSize = 12f
                setTextColor(FAINT)
                gravity = Gravity.CENTER
                setPadding(0, dp(24), 0, 0)
            },
        )

        setContentView(root)
    }

    private fun button(label: String, primary: Boolean = false, secondary: Boolean = false, onTap: () -> Unit): Button =
        Button(this).apply {
            text = label
            textSize = 17f
            isAllCaps = false
            setTextColor(if (secondary) SOFT else Color.WHITE)
            background = rounded(
                when {
                    primary -> Color.rgb(37, 99, 235)
                    secondary -> Color.rgb(19, 28, 46)
                    else -> Color.rgb(30, 41, 59)
                },
                dp(16),
                if (secondary) Color.rgb(34, 48, 74) else Color.TRANSPARENT,
            )
            stateListAnimator = null
            backgroundTintList = null
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(54),
            ).apply { topMargin = dp(12) }
            layoutParams = lp
            setOnClickListener { onTap() }
        }

    private fun rounded(fill: Int, radius: Int, stroke: Int): GradientDrawable =
        GradientDrawable().apply {
            setColor(fill)
            cornerRadius = radius.toFloat()
            if (stroke != Color.TRANSPARENT) setStroke(dp(1), stroke)
        }

    private fun circle(fill: Int): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(fill)
    }

    private fun dp(v: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

    companion object {
        private const val EXTRA_PACKAGE = "focus.package"
        private const val EXTRA_LABEL = "focus.label"
        private const val EXTRA_SECONDS = "focus.seconds"

        private val MUTED = Color.rgb(148, 163, 184)
        private val SOFT = Color.rgb(203, 213, 225)
        private val FAINT = Color.rgb(100, 116, 139)

        fun start(context: Context, pkg: String, label: String, seconds: Long): Boolean = runCatching {
            context.startActivity(
                Intent(context, FocusPageActivity::class.java)
                    .putExtra(EXTRA_PACKAGE, pkg)
                    .putExtra(EXTRA_LABEL, label)
                    .putExtra(EXTRA_SECONDS, seconds)
                    .addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP,
                    ),
            )
            true
        }.getOrDefault(false)
    }
}
