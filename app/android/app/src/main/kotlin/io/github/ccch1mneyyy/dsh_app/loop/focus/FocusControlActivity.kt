package io.github.ccch1mneyyy.dsh_app.loop.focus

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.provider.Settings
import android.text.InputType
import android.util.TypedValue
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
 * 入口：快捷设置磁贴「专注监督」、进行中的通知。不依赖 DSH 引擎。
 */
class FocusControlActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var taskInput: EditText
    private lateinit var minutesInput: EditText
    private lateinit var appLine: TextView
    private lateinit var metricElapsed: TextView
    private lateinit var metricDeviations: TextView
    private lateinit var metricRemaining: TextView
    private lateinit var batteryLine: TextView
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
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.rgb(11, 18, 32), Color.rgb(9, 14, 24)),
            )
            setPadding(dp(20), dp(28), dp(20), dp(36))
        }

        root.addView(text("专注监督", 28f, Color.WHITE))
        root.addView(text("离开任务应用 5 秒就全屏拉回 · 不依赖 DSH 引擎", 13f, MUTED).apply {
            setPadding(0, dp(6), 0, dp(18))
        })

        // 状态卡
        val statusCard = card()
        status = text("", 15f, SOFT)
        statusCard.addView(status)
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(14), 0, 0)
        }
        metricElapsed = metric(row, "已进行")
        metricDeviations = metric(row, "偏离")
        metricRemaining = metric(row, "剩余")
        statusCard.addView(row)
        root.addView(statusCard)

        // 任务
        val taskCard = card()
        taskCard.addView(section("这一段只做一件事"))
        taskInput = EditText(this).apply {
            hint = "例：第 3 题图形推理，做到选出答案"
            setTextColor(Color.WHITE)
            setHintTextColor(FAINT)
            textSize = 16f
            setSingleLine(false)
            maxLines = 3
            background = rounded(Color.rgb(11, 18, 32), dp(12), Color.rgb(34, 48, 74))
            setPadding(dp(14), dp(12), dp(14), dp(12))
        }
        taskCard.addView(taskInput)
        appLine = text("", 13f, SOFT).apply { setPadding(0, dp(10), 0, 0) }
        taskCard.addView(appLine)
        taskCard.addView(button("把当前前台应用设为任务应用") {
            val front = LoopRuntime.lastForeground
            if (front.isNullOrBlank() || front == packageName) {
                toast("现在读不到前台应用：先打开要专注的那个应用，再回来点一次")
            } else {
                capturedPackage = front
                capturedLabel = FocusRuntime.labelOf(front)
                refresh()
            }
        })
        taskCard.addView(text("电话、输入法、系统 UI、DSH 自己永远放行。", 12f, FAINT).apply {
            setPadding(0, dp(10), 0, 0)
        })
        root.addView(taskCard)

        // 结束时间
        val timeCard = card()
        timeCard.addView(section("结束后自动停止"))
        minutesInput = EditText(this).apply {
            setText("0")
            setTextColor(Color.WHITE)
            textSize = 16f
            inputType = InputType.TYPE_CLASS_NUMBER
            background = rounded(Color.rgb(11, 18, 32), dp(12), Color.rgb(34, 48, 74))
            setPadding(dp(14), dp(10), dp(14), dp(10))
        }
        timeCard.addView(minutesInput)
        timeCard.addView(text("分钟，0 = 不设结束时间", 12f, FAINT).apply { setPadding(0, dp(6), 0, 0) })
        root.addView(timeCard)

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
        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(4), 0, 0)
        }
        actions.addView(button("暂停 5 分钟 / 继续", weight = 1f) {
            if (FocusRuntime.isPaused()) FocusRuntime.resume() else FocusRuntime.pause(5)
            refresh()
        })
        actions.addView(button("结束", weight = 1f, secondary = true) {
            FocusRuntime.stop("user")
            refresh()
        })
        root.addView(actions)

        // 后台
        val backgroundCard = card()
        backgroundCard.addView(section("后台存活"))
        batteryLine = text("", 13f, SOFT).apply { setPadding(0, dp(8), 0, dp(6)) }
        backgroundCard.addView(batteryLine)
        backgroundCard.addView(button("允许后台运行（忽略电池优化）") {
            FocusRuntime.requestBatteryExemption(this)
        })
        backgroundCard.addView(button("打开应用详情") { FocusRuntime.openAppDetails(this) })
        backgroundCard.addView(button("打开无障碍设置") {
            runCatching { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)) }
        })
        root.addView(backgroundCard)

        // vivo 指引
        val guideCard = card()
        guideCard.addView(section("vivo / iQOO"))
        guide = text(VIVO_GUIDE, 12f, MUTED).apply { setLineSpacing(0f, 1.4f) }
        guideCard.addView(guide)
        root.addView(guideCard)

        root.addView(text(
            "离开任务应用时：全屏拉回 → 回到任务 / 休息 5 分钟 / 结束监督。不答题、不等 15 分钟。",
            12f,
            FAINT,
        ).apply { setPadding(0, dp(18), 0, 0) })

        setContentView(ScrollView(this).apply {
            setBackgroundColor(Color.rgb(9, 14, 24))
            isFillViewport = true
            addView(root)
        })
    }

    private fun refresh() {
        val now = System.currentTimeMillis()
        val s = FocusRuntime.state()
        status.text = when {
            !s.active -> "未开始 · 设好任务后点下面的开始"
            FocusRuntime.isPaused(now) -> "已暂停到 " + clock(s.pausedUntil)
            else -> "监督中"
        }
        metricElapsed.text = metricText("已进行", FocusRuntime.elapsedMinutes(now).toString() + " 分")
        metricDeviations.text = metricText("偏离", s.deviations.toString() + " 次")
        metricRemaining.text = metricText(
            "剩余",
            if (s.endAt > 0) FocusRuntime.remainingMinutes(now).toString() + " 分" else "不限",
        )
        if (s.active) taskInput.setText(s.task)
        if (capturedPackage.isBlank() && s.taskPackage.isNotBlank()) {
            capturedPackage = s.taskPackage
            capturedLabel = FocusRuntime.labelOf(s.taskPackage)
        }
        appLine.text = if (capturedPackage.isBlank()) {
            "任务应用：未指定（只允许 DSH / 电话 / 输入法）"
        } else {
            "任务应用：" + capturedLabel
        }
        batteryLine.text = if (FocusRuntime.isIgnoringBattery(this)) {
            "后台优化：已忽略电池优化"
        } else {
            "后台优化：仍会被系统限制，点下面允许"
        }
    }

    private fun metric(row: LinearLayout, label: String): TextView {
        val cell = TextView(this).apply {
            text = metricText(label, "0")
            textSize = 14f
            setTextColor(SOFT)
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.25f)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        row.addView(cell)
        return cell
    }

    private fun metricText(label: String, value: String) = label + "\n" + value

    private fun card(): LinearLayout = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        background = rounded(Color.rgb(19, 28, 46), dp(18), Color.rgb(34, 48, 74))
        setPadding(dp(16), dp(16), dp(16), dp(16))
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(14) }
    }

    private fun section(title: String): TextView = text(title, 15f, Color.WHITE).apply {
        setPadding(0, 0, 0, dp(10))
    }

    private fun clock(at: Long): String = SimpleDateFormat("HH:mm", Locale.US).format(Date(at))

    private fun text(value: String, size: Float, color: Int): TextView = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(color)
    }

    private fun button(
        label: String,
        primary: Boolean = false,
        secondary: Boolean = false,
        weight: Float = 0f,
        onTap: () -> Unit,
    ): Button = Button(this).apply {
        text = label
        textSize = 15f
        isAllCaps = false
        setTextColor(if (secondary) SOFT else Color.WHITE)
        background = rounded(
            when {
                primary -> Color.rgb(37, 99, 235)
                secondary -> Color.rgb(19, 28, 46)
                else -> Color.rgb(30, 41, 59)
            },
            dp(14),
            if (secondary) Color.rgb(34, 48, 74) else Color.TRANSPARENT,
        )
        stateListAnimator = null
        backgroundTintList = null
        val lp = if (weight > 0f) {
            LinearLayout.LayoutParams(0, dp(48), weight).apply {
                topMargin = dp(10)
                marginEnd = dp(5)
            }
        } else {
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(48)).apply { topMargin = dp(10) }
        }
        layoutParams = lp
        setOnClickListener { onTap() }
    }

    private fun rounded(fill: Int, radius: Int, stroke: Int): GradientDrawable = GradientDrawable().apply {
        setColor(fill)
        cornerRadius = radius.toFloat()
        if (stroke != Color.TRANSPARENT) setStroke(dp(1), stroke)
    }

    private fun dp(v: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

    private fun toast(value: String) {
        Toast.makeText(this, value, Toast.LENGTH_SHORT).show()
    }

    companion object {
        private val MUTED = Color.rgb(148, 163, 184)
        private val SOFT = Color.rgb(203, 213, 225)
        private val FAINT = Color.rgb(100, 116, 139)
        private const val VIVO_GUIDE =
            "i 管家 → 应用管理 → 权限管理 → 自启动、后台高耗电、关联启动全部打开；\n" +
                "设置 → 电池 → 后台耗电管理 → DSH Go → 允许后台高耗电。\n" +
                "无障碍不会因为引擎被清而停；整个应用被系统冻住时，前台读数也会停。"
    }
}
