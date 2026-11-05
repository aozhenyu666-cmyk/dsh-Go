package io.github.ccch1mneyyy.dsh_app.loop.focus

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
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
        val pad = (24 * resources.displayMetrics.density).toInt()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(9, 14, 24))
            setPadding(pad, pad, pad, pad)
        }
        root.addView(text("你离开了正在做的事", 15f, Color.rgb(148, 163, 184)))
        root.addView(text("回到「" + FocusRuntime.state().task + "」", 30f, Color.WHITE).apply {
            setPadding(0, pad / 2, 0, pad / 2)
            gravity = Gravity.CENTER
        })
        root.addView(text("刚才在「" + label + "」停留了 " + secondsOff.coerceAtLeast(1) + " 秒", 15f, Color.rgb(203, 213, 225)))
        root.addView(text("不用从头想：先回到刚才那一步。", 14f, Color.rgb(148, 163, 184)).apply {
            setPadding(0, pad / 3, 0, pad)
        })

        root.addView(button("回到任务") {
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

        root.addView(text(
            "监督在后台运行；即使 DSH 引擎被系统清掉，这一页仍然会拦。",
            12f, Color.rgb(100, 116, 139),
        ).apply { setPadding(0, pad, 0, 0); gravity = Gravity.CENTER })

        setContentView(root)
    }

    private fun text(value: String, size: Float, color: Int): TextView = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(color)
        gravity = Gravity.CENTER
    }

    private fun button(label: String, secondary: Boolean = false, onTap: () -> Unit): Button =
        Button(this).apply {
            text = label
            textSize = 17f
            isAllCaps = false
            setTextColor(if (secondary) Color.rgb(203, 213, 225) else Color.WHITE)
            setBackgroundColor(if (secondary) Color.rgb(30, 41, 59) else Color.rgb(37, 99, 235))
            val p = (14 * resources.displayMetrics.density).toInt()
            setPadding(p, p, p, p)
            val margin = (10 * resources.displayMetrics.density).toInt()
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
            lp.setMargins(0, margin, 0, 0)
            layoutParams = lp
            setOnClickListener { onTap() }
        }

    companion object {
        private const val EXTRA_PACKAGE = "focus.package"
        private const val EXTRA_LABEL = "focus.label"
        private const val EXTRA_SECONDS = "focus.seconds"

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
