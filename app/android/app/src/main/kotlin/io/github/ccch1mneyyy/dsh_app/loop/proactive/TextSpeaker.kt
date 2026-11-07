package io.github.ccch1mneyyy.dsh_app.loop.proactive

import android.content.Context
import android.speech.tts.TextToSpeech
import android.util.Log
import java.util.Locale

/**
 * 系统 TTS：15 分钟换渠道那一级，把这一球念出来。
 *
 * 只在 companion 的 `/plan` 回 `channel: "speech"` 时才用（他开了语音，且上一球被漠视到
 * 15 分钟那一级）。念不出来必须如实失败，让内核退回通知，不能假装念过了。
 *
 * 只认系统默认引擎和中文；要"人设语音"就换成引擎侧的 TTS 插件，这里不动。
 *
 * shortcut: 只念不认（不监听念完了没有），也不调语速音色;要按人设换音色再来这里。
 */
class TextSpeaker(private val app: Context) {
    private var tts: TextToSpeech? = null
    private var ready = false
    private var broken = false

    /** 起一次引擎。放在 runtime 启动时调，第一球到来时就不用等初始化的几百毫秒。 */
    fun prepare() {
        if (tts != null || broken) return
        tts = TextToSpeech(app) { status ->
            val engine = tts
            if (status != TextToSpeech.SUCCESS || engine == null) {
                broken = true
                Log.w(TAG, "tts unavailable (status $status)")
                return@TextToSpeech
            }
            val lang = engine.setLanguage(Locale.SIMPLIFIED_CHINESE)
            if (lang == TextToSpeech.LANG_MISSING_DATA || lang == TextToSpeech.LANG_NOT_SUPPORTED) {
                // 没有中文语音包：退回引擎自己的默认语言，总比不念好。
                Log.w(TAG, "tts has no chinese voice ($lang); using default")
            }
            ready = true
        }
    }

    /** True 表示已经交给系统念了。 */
    fun speak(text: String): Boolean {
        val body = text.trim()
        if (body.isEmpty()) return false
        prepare()
        val engine = tts
        if (!ready || engine == null) {
            Log.w(TAG, "tts not ready; ball stays on the screen")
            return false
        }
        val r = engine.speak(body.take(MAX_CHARS), TextToSpeech.QUEUE_FLUSH, null, "dsh-proactive")
        if (r != TextToSpeech.SUCCESS) Log.w(TAG, "tts speak refused ($r)")
        return r == TextToSpeech.SUCCESS
    }

    /** 这一球被撤回（屏上收掉、DSH 要屏幕）：别再念了。 */
    fun stop() {
        runCatching { tts?.stop() }
    }

    private companion object {
        const val TAG = "DshProactive"
        /** 一球念太长没意义，也拖住后面的话。 */
        const val MAX_CHARS = 600
    }
}
