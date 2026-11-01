package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * 第四阶段 4B · D2: 展示失败时**不得隐形放行**。
 *
 * 页面启动失败时目标 APP 仍在前台可交互。旧实现在 `backoff.isHoldingOff()` 处直接 return，
 * 行为上就是"放弃了但放行了"——技术上没有授权，效果上却是通行。
 *
 * 这条链必须走完，缺一步就等于留了个洞：
 *
 *   启动失败 → 记 NOT_SHOWN（退还额度与冷却）→ 尝试回 HOME → 重新读前台 → 确认已离开
 *
 * 回 HOME 也可能失败（ROM 限制、无障碍服务被回收）。那时**不能**假装成功：
 * 记 ENFORCEMENT_UNAVAILABLE，如实告诉用户这次没拦住，且不产生任何授权回执。
 *
 * 这个类只管"该下什么结论"，真正的 HOME 动作与前台读取由运行时注入，因此它可以被纯逻辑测试。
 */
object EnforcementOutcome {

    /** 展示失败之后应当发生什么。 */
    sealed interface Step {
        /** 请运行时执行回 HOME，随后再读一次前台。 */
        data object SendHome : Step

        /** 回 HOME 不可用：如实报告，不记拦截成功。 */
        data class Unavailable(val reason: String) : Step
    }

    /**
     * 展示失败之后的第一步。失败原因只影响措辞，不影响"不给授权"这个结论。
     */
    fun afterShowFailure(code: String): Step {
        // A start that the system refused and a page that never proved itself are the same story
        // from here: nothing was shown, so nothing is owed, and the app is still in front.
        val known = code == "no_visibility_proof" || code == "start_failed" ||
            code == "surface_busy" || code == "attempt_budget" || code == "stopped_before_shown"
        if (!known) {
            // An unknown code is not a reason to do nothing: the page is gone either way.
            return Step.SendHome
        }
        return Step.SendHome
    }

    /**
     * 回 HOME 之后，前台读到的还是目标 APP 吗？
     *
     * 这里刻意把"读不到前台"当成**未确认离开**，而不是"离开了"。差别很大：
     * 前者会再试一次并最终如实报错，后者会把一次失败说成成功。
     */
    fun stillInFront(foregroundAfterHome: String?, target: String): Boolean {
        if (foregroundAfterHome == null) return true
        return foregroundAfterHome == target
    }

    /** 降级处理用的一句话理由，进日志与用户可见提示。 */
    /** 失败的两类原因，设置页要能区分"读不到"和"没走"。 */
    const val REASON_UNREADABLE = "foreground_unreadable"
    const val REASON_STILL_IN_FRONT = "still_in_front"

    /**
     * 把一次前台读取结果分成两类。**两类都不是成功**，只是原因不同：
     *   * `foreground_unreadable` —— 我们不知道在哪，不能声称离开了；
     *   * `still_in_front`       —— 明确还在目标 APP 里。
     */
    fun failureKind(foregroundAfterHome: String?, target: String): String =
        if (foregroundAfterHome == null) REASON_UNREADABLE else REASON_STILL_IN_FRONT

    fun unavailableReason(code: String, attempts: Int, kind: String = REASON_UNREADABLE): String =
        "could not show the block page (" + code + ") and " + kind + " after " +
            attempts + " attempt(s); this interception did not take effect"
}
