package io.github.ccch1mneyyy.dsh_app.loop.intercept

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import io.github.ccch1mneyyy.dsh_app.MainActivity
import io.github.ccch1mneyyy.dsh_app.R

/**
 * W2: 拦截没生效时必须让用户看见。
 *
 * 在这之前 `notifyEnforcementUnavailable` 是个空实现，所以 D2 判定"这次没拦住"之后，
 * 用户什么都不会知道 —— 而那正是 D2 任务书最在意的一句："必须提醒用户当前拦截没有成功"。
 *
 * 同一个原因 10 分钟内只发一次：展示失败往往会连续触发（每次切前台都会试一次），
 * 不节流就会变成新的骚扰源。
 */
object EnforcementAlert {

    private const val TAG = "DshIntercept"
    private const val CHANNEL = "intercept_alerts"
    private const val NOTIFICATION_ID = 4711
    private const val REPEAT_WINDOW_MS = 10 * 60_000L

    private var lastReason: String? = null
    private var lastAt = 0L

    fun notify(context: Context, why: String, now: Long = System.currentTimeMillis()) {
        if (why == lastReason && now - lastAt < REPEAT_WINDOW_MS) return
        lastReason = why
        lastAt = now
        runCatching {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            ensureChannel(context, manager)
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val n = NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_dsh)
                .setContentTitle(context.getString(R.string.intercept_alert_title))
                .setContentText(why)
                .setStyle(NotificationCompat.BigTextStyle().bigText(why))
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .setContentIntent(open)
                .build()
            manager.notify(NOTIFICATION_ID, n)
        }.onFailure { Log.w(TAG, "could not post the enforcement alert", it) }
    }

    private fun ensureChannel(context: Context, manager: NotificationManager) {
        if (manager.getNotificationChannel(CHANNEL) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL,
                context.getString(R.string.intercept_alert_channel),
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = context.getString(R.string.intercept_alert_channel_desc)
            },
        )
    }
}
