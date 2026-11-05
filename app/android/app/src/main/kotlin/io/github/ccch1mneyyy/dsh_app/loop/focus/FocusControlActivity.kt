package io.github.ccch1mneyyy.dsh_app.loop.focus

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.provider.Settings
import android.view.Gravity
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import io.github.ccch1mneyyy.dsh_app.loop.LoopRuntime
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 专注监督的主界面（总控的第一块）：设任务、抓当前应用、开始/暂停/结束、看偏离。
 *
 * 入口：快捷设置磁贴「专注监督」、进行中的通知。不依赖 DSH 引擎。
 */
class FocusControlActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var taskInput: EditText
    private lateinit var minutesInput: EditText
    private lateinit var appLine: TextView
    private lateinit var metrics: TextView
    private lateinit var guide: TextView
    private var capturedPackage = ""
    private var capturedLabel = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FocusRuntime.ensure(this)
        render()
    }

    override fun onResume() {
        super.onResume()
        refresh()
    }

    private fun render() {
        val pad = (20 * resources.displayMetrics.density).toInt()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(9, 14, 24))
            setPadding(pad, pad, pad, pad)
        }

        root.addView(text("专注监督", 26f, Color.WHITE))
        status = text("", 14f, Color.rgb(148, 163, 184)).apply { setPadding(0, pad / 3, 0, pad / 2) }
        root.addView(status)
        metrics = text("", 14f, Color.rgb(203, 213, 225)).apply { setPadding(0, 0, 0, pad / 2) }
        root.addView(metrics)

        root.addView(text("这一段只做一件事", 14f, Color.rgb(148, 163, 184)))
        taskInput = EditText(this).apply {
            hint = "例：第 3 题图形推理，做到选出答案"
            setTextColor(Color.WHITE)
            setHintTextColor(Color.rgb(100, 116, 139))
            textSize = 16f
            setSingleLine(false)
            maxLines = 3
            setPadding(0, pad / 3, 0, pad / 3)
        }
        root.addView(taskInput)

        root.addView(text("离开这个应用超过 5 秒就全屏拉回；电话、输入法、DSH 自己永远放行。", 12f, Color.rgb(100, 116, 139)))
        appLine = text("", 14f, Color.rgb(203, 213, 225)).apply { setPadding(0, pad / 3, 0, 0) }
        root.addView(appLine)

        root.addView(button("把当前前台应用设为任务应用") {
            val front = LoopRuntime.lastForeground
            if (front.isNullOrBlank() || front == packageName) {
                toast("现在读不到前台应用：先打开要专注的那个应用，再回来点一次")
            } else {
                capturedPackage = front
                capturedLabel = FocusRuntime.labelOf(front)
                refresh()
            }
        })

        root.addView(text("结束后自动停止（分钟，0 = 不设）", 12f, Color.rgb(100, 116, 139)).apply {
            setPadding(0, pad / 2, 0, 0)
        })
        minutesInput = EditText(this).apply {
            setText("0")
            setTextColor(Color.WHITE)
            textSize = 16f
            inputType = android.text.InputType.TYPE_CLASS_NUMBER
        }
        root.addView(minutesInput)

        root.addView(button("开始监督", primary = true) {
            val task = taskInput.text.toString().trim()
            if (task.isEmpty()) {
                toast("先写这一段的完成条件")
                return@button
            }
            val minutes = minutesInput.text.toString().toIntOrNull() ?: 0
            val endAt = if (minutes > 0) System.currentTimeMillis() + minutes * 60_000L else 0L
            FocusRuntime.start(task, capturedPackage, endAt)
            toast("已开始；现在切走会立刻拉回")
            refresh()
        })

        root.addView(button("暂停 5 分钟 / 继续") {
            if (FocusRuntime.isPaused()) FocusRuntime.resume() else FocusRuntime.pause(5)
            refresh()
        })
        root.addView(button("结束监督", secondary = true) {
            FocusRuntime.stop("user")
            refresh()
        })

        root.addView(text("后台存活", 16f, Color.WHITE).apply { setPadding(0, pad, 0, pad / 3) })
        root.addView(button("允许后台运行（忽略电池优化）") {
            FocusRuntime.requestBatteryExemption(this)
        })
        root.addView(button("打开应用详情") { FocusRuntime.openAppDetails(this) })
        root.addView(button("打开无障碍设置") {
            runCatching { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
        })
        guide = text(
            "vivo / iQOO：i 管家 → 应用管理 → 权限管理 → 自启动、后台高耗电、关联启动全部打开；" +
                "设置 → 电池 → 后台耗电管理 → DSH Go → 允许后台高耗电。" +
                "无障碍服务不会因为引擎被清而停止，但系统把整个应用冻住时，前台读数也会停；" +
                "这份监督页是为此准备的第二层。",
            12f, Color.rgb(148, 163, 184),
        ).apply { setPadding(0, pad / 2, 0, pad) }
        root.addView(guide)

        root.addView(text(
            "离开任务应用时：全屏拉回 → 回到任务 / 休息 5 分钟 / 结束监督。不答题、不等 15 分钟。",
            12f, Color.rgb(100, 116, 139),
        ))

        setContentView(ScrollView(this).apply {
            setBackgroundColor(Color.rgb(9, 14, 24))
            addView(root)
        })
    }

    private fun refresh() {
        val now = System.currentTimeMillis()
        val s = FocusRuntime.state()
        status.text = when {
            !s.active -> "未开始"
            FocusRuntime.isPaused(now) -> "已暂停到 " + clock(s.pausedUntil)
            else -> "监督中 · 已 " + FocusRuntime.elapsedMinutes(now) + " 分钟" +
                if (s.endAt > 0) " · 还剩 " + FocusRuntime.remainingMinutes(now) + " 分钟" else ""
        }
        metrics.text = "偏离 " + s.deviations + " 次" +
            (if (s.lastBlockAt > 0) " · 最近 " + clock(s.lastBlockAt) else "")
        if (s.active) taskInput.setText(s.task)
        if (capturedPackage.isBlank() && s.taskPackage.isNotBlank()) {
            capturedPackage = s.taskPackage
            capturedLabel = FocusRuntime.labelOf(s.taskPackage)
        }
        appLine.text = if (capturedPackage.isBlank()) {
            "任务应用：未指定（只允许 DSH / 电话 / 输入法）"
        } else {
            "任务应用：" + capturedLabel + "（" + capturedPackage + "）"
        }
        guide.text = if (FocusRuntime.isIgnoringBattery(this)) {
            "后台优化：已忽略电池优化\n" + VIVO_GUIDE
        } else {
            "后台优化：仍会被系统限制，点上面的「允许后台运行」\n" + VIVO_GUIDE
        }
    }

    private fun clock(at: Long): String = SimpleDateFormat("HH:mm", Locale.US).format(Date(at))

    private fun text(value: String, size: Float, color: Int): TextView = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(color)
    }

    private fun button(label: String, primary: Boolean = false, secondary: Boolean = false, onTap: () -> Unit): Button =
        Button(this).apply {
            text = label
            textSize = 16f
            isAllCaps = false
            setTextColor(Color.WHITE)
            setBackgroundColor(
                when {
                    primary -> Color.rgb(37, 99, 235)
                    secondary -> Color.rgb(51, 65, 85)
                    else -> Color.rgb(30, 41, 59)
                },
            )
            val p = (12 * resources.displayMetrics.density).toInt()
            setPadding(p, p, p, p)
            val lp = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
            lp.setMargins(0, (8 * resources.displayMetrics.density).toInt(), 0, 0)
            layoutParams = lp
            setOnClickListener { onTap() }
        }

    private fun toast(value: String) {
        Toast.makeText(this, value, Toast.LENGTH_SHORT).show()
    }

    companion object {
        private const val VIVO_GUIDE =
            "vivo / iQOO：i 管家 → 应用管理 → 权限管理 → 自启动、后台高耗电、关联启动全部打开；" +
                "设置 → 电池 → 后台耗电管理 → DSH Go → 允许后台高耗电。" +
                "无障碍不会因为引擎被清而停，但整个应用被冻住时前台读数也会停。"
    }
}
