package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * 第四阶段 P0-1: 一次拦截必须**一定会结束**。
 *
 * 现在的形状是"谁先动谁结算"：页面在 release/exit/pause/onStop/onDestroy 里报告，守卫等它报。
 * 只要有一条路径没报，`openEventId` 就永远非空 —— 而守卫对每个目标 APP 的回答都是
 * `Allow(already_open)`，于是悬挂期间**所有目标 APP 都被放行**，直到进程重启。
 *
 * 不结算的路径在真机上有五条（架构审查 §2.1 逐条列出），全部与"页面没按预期活着"有关：
 * Activity 没被创建、Activity 被系统回收、Intent 迟到、可见性证明用完重试、熄屏后从锁屏进目标 APP。
 * 这些都不是页面能自己报告的，因为**页面不在**。
 *
 * 所以到期判定不能放在页面里。这里给纯逻辑的三条规则，由运行时（不是页面）驱动：
 *
 *   1. **证明窗口**：从展示请求开始算，超过 [proofWindowMs] 还没有"页面在屏上"的证据 →
 *      NOT_SHOWN。这条覆盖 a/b/e：启动了但没起来。
 *   2. **展示上限**：已经证明在屏上后，超过 [pageTtlMs] 仍未结束 → BLOCKED(page_ttl)。
 *      这条覆盖"人什么都不做"和熄屏悬挂（D1）。
 *   3. **重试退避**：NOT_SHOWN 之后同一包名在 [retryBackoffMs] 内不再尝试。
 *      **这不是放行**：不写 `releases`，目标 APP 维持现状，到点再判（D2）。
 *
 * 纯函数、无时钟、无 Android 类型：给一个"现在"，它给出"该做什么"。
 * 运行时负责按 [Due] 去调用守卫；页面完全不必参与。
 */
object InterceptDeadline {

    /** 展示证明的等待上限。与 D2 的 5 秒一致。 */
    const val DEFAULT_PROOF_WINDOW_MS = 5_000L

    /** 一次拦截在屏上的上限。与 D1 的 10 分钟一致。 */
    const val DEFAULT_PAGE_TTL_MS = 10 * 60_000L

    /** NOT_SHOWN 之后同包的退避。不是放行窗口。 */
    const val DEFAULT_RETRY_BACKOFF_MS = 15_000L

    /** 每包每分钟最多尝试次数；超过记故障（D2）。 */
    const val DEFAULT_MAX_ATTEMPTS_PER_MINUTE = 3

    /** 该结束这次拦截了，以及为什么。 */
    sealed interface Due {
        /** The page was never proved on screen within the window. */
        data object NotShown : Due

        /** The page was proved on screen and has been there longer than the TTL. */
        data object Expired : Due

        /** Nothing to do yet. */
        data object Nothing : Due
    }

    /**
     * What an open interception looks like to this policy. [shownAt] is 0 while the page has not
     * been proved on screen; [requestedAt] is when the runtime asked for the page.
     */
    data class Open(
        val requestedAt: Long,
        val shownAt: Long = 0L,
    )

    /**
     * @param now a monotonic clock reading (elapsedRealtime), in ms; **not** wall time, so a
     *   time-zone change or a manual clock change cannot skip or stall a deadline.
     */
    fun due(
        open: Open?,
        now: Long,
        proofWindowMs: Long = DEFAULT_PROOF_WINDOW_MS,
        pageTtlMs: Long = DEFAULT_PAGE_TTL_MS,
    ): Due {
        if (open == null) return Due.Nothing
        // Not shown yet: the proof window is what decides, not the TTL.
        if (open.shownAt == 0L) {
            return if (now - open.requestedAt >= proofWindowMs) Due.NotShown else Due.Nothing
        }
        return if (now - open.shownAt >= pageTtlMs) Due.Expired else Due.Nothing
    }

    /**
     * The next moment [due] could change its answer, so the runtime can set one timer instead of
     * polling. Null when nothing is open.
     */
    fun nextDeadline(
        open: Open?,
        proofWindowMs: Long = DEFAULT_PROOF_WINDOW_MS,
        pageTtlMs: Long = DEFAULT_PAGE_TTL_MS,
    ): Long? {
        if (open == null) return null
        return if (open.shownAt == 0L) open.requestedAt + proofWindowMs else open.shownAt + pageTtlMs
    }

    /**
     * Attempt bookkeeping per package, so a page that can never be shown cannot be retried forever.
     * One window of one minute; [record] returns false when the package has already used its tries.
     */
    class Attempts(
        private val maxPerMinute: Int = DEFAULT_MAX_ATTEMPTS_PER_MINUTE,
        private val windowMs: Long = 60_000L,
    ) {
        private val at = LinkedHashMap<String, ArrayDeque<Long>>()

        /** Records an attempt; false when this package is over its budget for the window. */
        fun record(pkg: String, now: Long): Boolean {
            val q = at.getOrPut(pkg) { ArrayDeque() }
            while (q.isNotEmpty() && now - q.first() >= windowMs) q.removeFirst()
            if (q.size >= maxPerMinute) return false
            q.addLast(now)
            return true
        }

        fun count(pkg: String, now: Long): Int {
            val q = at[pkg] ?: return 0
            while (q.isNotEmpty() && now - q.first() >= windowMs) q.removeFirst()
            return q.size
        }

        fun clear() = at.clear()
    }

    /**
     * The per-package retry backoff after a NOT_SHOWN. Deliberately **not** a release: the guard
     * keeps deciding normally, this only says "do not ask again for a moment" so a page that
     * cannot be shown does not spin. Stored separately from `releases` on purpose — writing a
     * release here would turn "could not show" into "let them through", which is D2's last line.
     */
    class Backoff(private val backoffMs: Long = DEFAULT_RETRY_BACKOFF_MS) {
        private val until = HashMap<String, Long>()

        fun note(pkg: String, now: Long) {
            until[pkg] = now + backoffMs
        }

        fun isHoldingOff(pkg: String, now: Long): Boolean {
            val t = until[pkg] ?: return false
            if (now >= t) {
                until.remove(pkg)
                return false
            }
            return true
        }

        fun clear() = until.clear()
    }
}
