package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * P0-A · DSH Go ↔ 一手 hand-off protocol, version 1. Pure Kotlin (no android.*), so the kernel
 * tests and 一手's side read the same names.
 *
 *   DSH Go block page → 「去一手答题」
 *     startActivity(Intent(ACTION_TRAIN).setPackage(YISHOU_PACKAGE)) with
 *       EXTRA_VERSION, EXTRA_EVENT_ID, EXTRA_NONCE, EXTRA_TARGET_PACKAGE, EXTRA_TARGET_LABEL, EXTRA_REPLY_PACKAGE
 *   一手 asks one question and judges it (一手 alone decides whether it passed)
 *   一手 → startActivity(Intent(ACTION_PASS).setPackage(<EXTRA_REPLY_PACKAGE>)) with
 *       EXTRA_VERSION, EXTRA_EVENT_ID, EXTRA_NONCE (echoed unchanged), EXTRA_PASS_MINUTES, EXTRA_REF
 *   DSH Go checks event id + nonce + hand-off age in [InterceptGuard.onExternalPass] and only then
 *   lets the target app through.
 *
 * The nonce is the only thing that makes a pass claim count. It is minted per interception, sent
 * only to [YISHOU_PACKAGE] by an explicit intent, and accepted once.
 */
object YishouProtocol {
    const val VERSION = 1

    const val YISHOU_PACKAGE = "com.yishou.app"

    /** DSH Go → 一手: "ask the person one question for this interception". */
    const val ACTION_TRAIN = "com.yishou.app.action.TRAIN_FOR_DSH"

    /** 一手 → DSH Go: "the question was answered and verified". */
    const val ACTION_PASS = "io.github.ccch1mneyyy.dsh_app.action.YISHOU_PASS"

    const val EXTRA_VERSION = "dsh_protocol"
    const val EXTRA_EVENT_ID = "dsh_event_id"
    const val EXTRA_NONCE = "dsh_nonce"
    const val EXTRA_TARGET_PACKAGE = "dsh_target_package"
    const val EXTRA_TARGET_LABEL = "dsh_target_label"
    const val EXTRA_REPLY_PACKAGE = "dsh_reply_package"
    const val EXTRA_PASS_MINUTES = "dsh_pass_minutes"
    const val EXTRA_REF = "dsh_ref"

    /** A pass claim as it arrived, before the guard has judged it. */
    data class PassClaim(val eventId: String, val nonce: String, val minutes: Int, val ref: String?)

    /**
     * Shape check only - never a decision. Returns null for anything malformed; the guard still
     * has to match the event id and the nonce. [get] reads one extra by name.
     */
    fun parsePass(get: (String) -> Any?): PassClaim? {
        val version = (get(EXTRA_VERSION) as? Number)?.toInt() ?: return null
        if (version != VERSION) return null
        val eventId = (get(EXTRA_EVENT_ID) as? String)?.takeIf { it.isNotBlank() && it.length <= 64 } ?: return null
        val nonce = (get(EXTRA_NONCE) as? String)?.takeIf { it.length in 16..64 } ?: return null
        val minutes = (get(EXTRA_PASS_MINUTES) as? Number)?.toInt() ?: return null
        val ref = (get(EXTRA_REF) as? String)?.take(120)
        return PassClaim(eventId, nonce, minutes, ref)
    }
}
