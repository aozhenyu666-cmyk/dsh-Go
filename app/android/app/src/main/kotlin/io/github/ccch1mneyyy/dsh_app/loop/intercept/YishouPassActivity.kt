package io.github.ccch1mneyyy.dsh_app.loop.intercept

import android.app.Activity
import android.os.Bundle
import android.util.Log
import io.github.ccch1mneyyy.dsh_app.loop.core.YishouProtocol

/**
 * P0-A: where 一手 hands back "the question was answered and verified". No UI: it reads the
 * claim, gives it to [InterceptRuntime.onYishouPass] (which asks the guard to check event id,
 * hand-off secret and age) and closes. A malformed or refused claim changes nothing.
 */
class YishouPassActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val extras = intent?.extras
        val claim = if (savedInstanceState == null && extras != null) {
            @Suppress("DEPRECATION")
            YishouProtocol.parsePass { key -> extras.get(key) }
        } else null
        if (claim == null) {
            Log.w("DshIntercept", "ignored a malformed 一手 pass")
        } else {
            runCatching { InterceptRuntime.onYishouPass(this, claim) }
                .onFailure { Log.w("DshIntercept", "一手 pass failed", it) }
        }
        finish()
    }
}
