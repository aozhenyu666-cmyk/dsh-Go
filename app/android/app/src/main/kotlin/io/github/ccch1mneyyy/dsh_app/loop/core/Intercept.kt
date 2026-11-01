package io.github.ccch1mneyyy.dsh_app.loop.core

// 娱乐 APP 拦截, pure half (M1, round 4).
//
//   verified foreground package
//     → [InterceptRules.decide]   (target list? whitelist? paused? released? authorized window?)
//     → [InterceptGuard]          (one open interception at a time, cooldown, ledger writes)
//     → the adapter shows one blocking page with a token
//     → 训练通过 / 授权规则 / 加入白名单 / 暂停 / 紧急退出
//     → one receipt in 行为拦截账 ([InterceptLedgerBook])
//
// Nothing here touches the proactive schedule: the intercept book owns its own counters, and the
// only thing shared with [ProactiveScheduler] is the notion of "quiet hours", which the caller
// passes in as an [InterceptEnv] fact rather than the guard reading a second scheduler.

/** One package the person asked to be interrupted when they open it. */
data class InterceptTarget(
    /** Android package name, e.g. "tv.danmaku.bili". */
    val packageName: String,
    /** What to call it on the blocking page ("哔哩哔哩"). */
    val label: String,
) {
    fun toMap(): Map<String, Any?> = linkedMapOf("packageName" to packageName, "label" to label)

    companion object {
        fun fromMap(m: Map<*, *>): InterceptTarget? {
            val p = M.str(m, "packageName")?.trim()?.takeIf { it.isNotEmpty() } ?: return null
            return InterceptTarget(p, M.str(m, "label")?.takeIf { it.isNotBlank() } ?: p)
        }
    }
}

/**
 * 拦截配置. The target list is the only thing that decides *what* is entertainment, and it is a
 * value the person edits: nothing hard-codes a behaviour on a package name.
 */
data class InterceptConfig(
    val enabled: Boolean = false,
    /** 目标包名清单. Defaults to the common short-video apps; the person may replace it entirely. */
    val targets: List<InterceptTarget> = DEFAULT_TARGETS,
    /** 白名单: never intercepted, whatever else says otherwise. */
    val whitelist: Set<String> = emptySet(),
    /** 暂停 until this wall time: every target is let through meanwhile. */
    val pauseUntilWall: Long = 0,
    /** How long one release lasts (training passed, an authorization rule, or a whitelist add). */
    val releaseMs: Long = 10 * 60_000L,
    /** How long the training page must be kept up before it counts as passed. */
    val trainingMs: Long = 60_000L,
    /** No second interception of the same app within this gap (after a release or an exit). */
    val cooldownMs: Long = 2 * 60_000L,
    /** Interceptions per local day; 0 = no limit. */
    val dailyMax: Int = 0,
    /** 授权规则 windows as minute-of-day ranges, during which a target is let through. */
    val authorizedWindows: List<IntRange> = emptyList(),
) {
    fun normalized(): InterceptConfig = copy(
        targets = targets.map { it.copy(packageName = it.packageName.trim(), label = it.label.trim().take(48)) }
            .filter { it.packageName.isNotEmpty() && it.packageName.length <= 255 }
            .distinctBy { it.packageName }.take(MAX_TARGETS),
        whitelist = whitelist.map { it.trim() }.filter { it.isNotEmpty() && it.length <= 255 }.toSet(),
        releaseMs = releaseMs.coerceIn(0, 6 * 3_600_000L),
        // 0 is allowed and means "no dwell requirement": the drill alone decides. Without the 0
        // the setting could never be turned off, and a floor of 5 s silently overrode the person.
        trainingMs = trainingMs.coerceIn(0L, 30 * 60_000L),
        cooldownMs = cooldownMs.coerceIn(0, 24 * 3_600_000L),
        dailyMax = dailyMax.coerceIn(0, 200),
        authorizedWindows = authorizedWindows
            .filter { it.first in 0..1439 && it.last in 1..1440 && it.first < it.last }.take(8),
    )

    /** The target for a package, or null when this app is not one of them. */
    fun targetFor(packageName: String): InterceptTarget? = targets.firstOrNull { it.packageName == packageName }

    fun toMap(): Map<String, Any?> = linkedMapOf(
        "enabled" to enabled, "targets" to targets.map { it.toMap() }, "whitelist" to whitelist.toList(),
        "pauseUntilWall" to pauseUntilWall, "releaseMs" to releaseMs, "trainingMs" to trainingMs,
        "cooldownMs" to cooldownMs, "dailyMax" to dailyMax,
        "authorizedWindows" to authorizedWindows.map { listOf(it.first, it.last) },
    )

    companion object {
        const val MAX_TARGETS = 50

        /** B站 / 抖音 / 快手 / 小红书 / 抖音极速版: the usual short-video holes. Editable by the person. */
        val DEFAULT_TARGETS: List<InterceptTarget> = listOf(
            InterceptTarget("tv.danmaku.bili", "哔哩哔哩"),
            InterceptTarget("com.ss.android.ugc.aweme", "抖音"),
            InterceptTarget("com.smile.gifmaker", "快手"),
            InterceptTarget("com.xingin.xhs", "小红书"),
            InterceptTarget("com.ss.android.ugc.aweme.lite", "抖音极速版"),
        )

        fun fromMap(m: Map<*, *>): InterceptConfig {
            val d = InterceptConfig()
            val targets = M.list(m, "targets").mapNotNull { (it as? Map<*, *>)?.let(InterceptTarget::fromMap) }
            return InterceptConfig(
                enabled = M.bool(m, "enabled"),
                // An empty list in the file means "the person removed everything", not "use defaults".
                targets = if (m.containsKey("targets")) targets else d.targets,
                whitelist = M.list(m, "whitelist").filterIsInstance<String>().toSet(),
                pauseUntilWall = M.long(m, "pauseUntilWall"),
                releaseMs = M.long(m, "releaseMs", d.releaseMs),
                trainingMs = M.long(m, "trainingMs", d.trainingMs),
                cooldownMs = M.long(m, "cooldownMs", d.cooldownMs),
                dailyMax = M.int(m, "dailyMax"),
                authorizedWindows = M.list(m, "authorizedWindows").mapNotNull { w ->
                    val l = w as? List<*> ?: return@mapNotNull null
                    val a = (l.getOrNull(0) as? Number)?.toInt() ?: return@mapNotNull null
                    val b = (l.getOrNull(1) as? Number)?.toInt() ?: return@mapNotNull null
                    a..b
                },
            ).normalized()
        }
    }
}

/** Facts the adapter reads just before asking, exactly like [Gate] for the proactive kernel. */
data class InterceptEnv(
    val screenOn: Boolean = true,
    val unlocked: Boolean = true,
    /** DSH itself is operating the phone or asking something: never cover it with a block page. */
    val dshBusy: Boolean = false,
    /** Local minute of the day (0..1439), -1 when unknown. */
    val minuteOfDay: Int = -1,
    /** Local calendar day number; only ever moves forward. */
    val dayKey: Long = Long.MIN_VALUE,
)

/**
 * 训练题: the checkable half of "training passed".
 *
 * Round 4 shipped a page that passed on a countdown, so "训练通过" meant nothing more than "the page
 * stayed up for a minute" — the person could put the phone down and come back to a pass. A pass has
 * to be earned by doing something, and it has to be verifiable *by the guard*, not just claimed by
 * the page: the page only reports button presses, and [InterceptGuard.onReleased] refuses
 * [InterceptGuard.RELEASE_TRAINING] until this record says the drill is solved.
 *
 * The drill: several numbers are shown out of order; press them from small to large (or large to
 * small, which the eventId decides). A wrong press resets the progress and counts, so a fail means
 * "keep training" and never "through". Generated purely from the eventId, so it is reproducible in a
 * test and needs no random source at runtime.
 */
data class InterceptDrill(
    /** The buttons on screen, in display order (never the answer order). */
    val candidates: List<Int>,
    /** True when the answer is ascending; false when it is descending. */
    val ascending: Boolean,
    /** How many presses were correct in a row. */
    val cursor: Int = 0,
    /** Wrong presses so far. Never a way through; only ever a reason to start again. */
    val wrongAttempts: Int = 0,
) {
    /** The drill is done only when every candidate was pressed in the required order. */
    val solved: Boolean get() = candidates.isNotEmpty() && cursor >= candidates.size

    /** The value that should be pressed now, or null once solved. */
    val expected: Int?
        get() = when {
            solved -> null
            ascending -> candidates.sorted().getOrNull(cursor)
            else -> candidates.sortedDescending().getOrNull(cursor)
        }

    /** One press. Wrong restarts the sequence — the person trains again instead of getting through. */
    fun tap(value: Int): InterceptDrill = when {
        solved -> this
        value == expected -> copy(cursor = cursor + 1)
        else -> copy(cursor = 0, wrongAttempts = wrongAttempts + 1)
    }

    fun toMap(): Map<String, Any?> = linkedMapOf(
        "candidates" to candidates, "ascending" to ascending, "cursor" to cursor,
        "wrongAttempts" to wrongAttempts,
    )

    companion object {
        /** Four numbers: enough to need a look, short enough not to be a chore. */
        const val SIZE = 4

        /** Candidates are drawn from 1..9 so each is one readable digit. */
        private const val POOL = 9

        /**
         * The value a [InterceptDecision.Block] carries while it is still only a *decision*:
         * [InterceptRules.decide] knows the target but not the eventId, and the drill is minted
         * from the eventId by [InterceptGuard.onForeground]. Never shown to anybody.
         */
        val NONE: InterceptDrill = InterceptDrill(candidates = emptyList(), ascending = true)

        /** Stable across platforms and app versions — unlike a hash of the object identity. */
        private fun seedOf(text: String): Long {
            var h = 0xcbf29ce484222325uL
            for (b in text.encodeToByteArray()) {
                h = h xor b.toUByte().toULong()
                h *= 0x100000001b3uL
            }
            return h.toLong()
        }

        /**
         * A drill for [eventId]. Deterministic: the same interception always shows the same numbers
         * in the same order, so a retried page cannot "reroll" for an easier one.
         */
        fun of(eventId: String): InterceptDrill {
            var state = seedOf(eventId)
            fun next(bound: Int): Int {
                // SplitMix64: tiny, deterministic, and good enough for picking four digits.
                state += -0x61c8864680b583ebL
                var z = state
                z = (z xor (z ushr 30)) * -0x40a7b892e31b1a47L
                z = (z xor (z ushr 27)) * -0x6b2fb644ecceee15L
                z = z xor (z ushr 31)
                return ((z ushr 1) % bound).toInt()
            }
            val picked = LinkedHashSet<Int>()
            while (picked.size < SIZE) picked.add(next(POOL) + 1)
            val ascending = next(2) == 0
            return InterceptDrill(candidates = picked.toList(), ascending = ascending)
        }

        fun fromMap(m: Map<*, *>?): InterceptDrill? {
            if (m == null) return null
            val candidates = M.list(m, "candidates").mapNotNull { (it as? Number)?.toInt() }
            if (candidates.isEmpty()) return null
            return InterceptDrill(
                candidates = candidates,
                ascending = M.bool(m, "ascending"),
                cursor = M.int(m, "cursor").coerceIn(0, candidates.size),
                wrongAttempts = M.int(m, "wrongAttempts").coerceAtLeast(0),
            )
        }
    }
}

/** What the guard decided about the app the person just opened. */
sealed interface InterceptDecision {
    /**
     * Show the blocking page for [packageName] under [eventId].
     *
     * [drill] is the 训练题 the page must render; it is minted with the eventId and can only be
     * *solved* through [InterceptGuard.tapDrill], never claimed.
     */
    data class Block(
        val eventId: String,
        val target: InterceptTarget,
        val reason: String,
        val drill: InterceptDrill,
    ) : InterceptDecision
    /** Let it through, with the reason (for the settings page and the receipts). */
    data class Allow(val packageName: String, val reason: String) : InterceptDecision
    /** Not a target at all: nothing to decide. */
    data object Ignore : InterceptDecision
}

object InterceptRules {
    const val REASON_WHITELIST = "whitelist"
    const val REASON_RELEASED = "released"
    const val REASON_PAUSED = "paused"
    const val REASON_AUTHORIZED_WINDOW = "authorized_window"
    const val REASON_DAILY_MAX = "daily_max"
    const val REASON_COOLDOWN = "cooldown"

    /** The same app is still on screen under the open interception: not a second one. */
    const val REASON_ALREADY_OPEN = "already_open"

    /**
     * A *different* target app was opened while an interception is still open. One interception at
     * a time is a rule of the guard, not of the adapter: opening Douyin while the B站 page is up
     * must not open a second page, spend the cooldown, spend today's count, or — worst of all —
     * overwrite [InterceptState.openEventId] and leave the first event without any receipt.
     */
    const val REASON_ANOTHER_OPEN = "another_open"
    const val REASON_SCREEN_OFF = "screen_off"
    const val REASON_LOCKED = "locked"
    const val REASON_DSH_BUSY = "dsh_busy"
    const val REASON_DISABLED = "disabled"

    /** True when [minute] falls in one of the person's authorization windows. */
    fun inAuthorizedWindow(config: InterceptConfig, minute: Int): Boolean {
        if (minute !in 0..1439) return false
        return config.authorizedWindows.any { minute in it }
    }

    /**
     * The order is the rule: the first failing gate names the reason, and every allow path is a
     * person's own decision (whitelist, release, authorization window, pause) rather than a guess.
     */
    fun decide(
        config: InterceptConfig,
        packageName: String?,
        env: InterceptEnv,
        now: Long,
        releasedUntilWall: Long = 0,
        lastTriggerAt: Long = 0,
        lastTriggerPackage: String? = null,
        countToday: Int = 0,
    ): InterceptDecision {
        if (packageName.isNullOrBlank()) return InterceptDecision.Ignore
        val target = config.targetFor(packageName) ?: return InterceptDecision.Ignore
        if (!config.enabled) return InterceptDecision.Allow(packageName, REASON_DISABLED)
        if (packageName in config.whitelist) return InterceptDecision.Allow(packageName, REASON_WHITELIST)
        if (config.pauseUntilWall > now) return InterceptDecision.Allow(packageName, REASON_PAUSED)
        if (releasedUntilWall > now) return InterceptDecision.Allow(packageName, REASON_RELEASED)
        if (inAuthorizedWindow(config, env.minuteOfDay)) return InterceptDecision.Allow(packageName, REASON_AUTHORIZED_WINDOW)
        if (!env.screenOn) return InterceptDecision.Allow(packageName, REASON_SCREEN_OFF)
        if (!env.unlocked) return InterceptDecision.Allow(packageName, REASON_LOCKED)
        if (env.dshBusy) return InterceptDecision.Allow(packageName, REASON_DSH_BUSY)
        // 第四阶段 4B · D5: the two branches that used to be here both returned
        // InterceptDecision.Allow, and both were wrong in the same way — they turned a way of
        // REDUCING NAGGING into a grant of ACCESS:
        //
        //   * dailyMax reached  -> Allow(REASON_DAILY_MAX): "do not interrupt more today" became
        //     "use it freely today";
        //   * still inside the cooldown -> Allow(REASON_COOLDOWN): "do not re-prompt just yet"
        //     became "use it freely for two minutes", which is also how pressing emergency-exit
        //     used to buy a free window.
        //
        // Neither is an authorisation, so neither may produce Allow. What they legitimately do is
        // suppress the QUESTION. That is Ignore: no interception is raised, and — just as important
        // — nothing is marked as permitted either, so a later reading is still free to block.
        //
        // Real permissions are enumerated above this point and only there: whitelist, pause window,
        // earned release window, authorized time window.
        if (config.dailyMax > 0 && countToday >= config.dailyMax) {
            return InterceptDecision.Ignore
        }
        if (lastTriggerPackage == packageName && lastTriggerAt != 0L && now - lastTriggerAt in 0 until config.cooldownMs) {
            return InterceptDecision.Ignore
        }
        // The eventId — and with it the drill — is minted by the guard. This is a decision, not
        // yet an interception.
        return InterceptDecision.Block("", target, "target", InterceptDrill.NONE)
    }
}

/** What the guard remembers across process death. */
data class InterceptState(
    val lastTriggerAt: Long = 0,
    val lastTriggerPackage: String? = null,
    /** packageName → wall time passage must be re-earned after. */
    val releases: Map<String, Long> = emptyMap(),
    val dayKey: Long = Long.MIN_VALUE,
    val countToday: Int = 0,
    /** The interception currently on screen, if any. */
    val openEventId: String? = null,
    val openPackage: String? = null,
    val openSinceWall: Long = 0,
    /**
     * When the page was *proved* on screen (the adapter's attached+shown+laid-out+focused proof),
     * 0 while it has only been triggered. This is the fact that separates "triggered" from
     * "really blocked", and it is what recovery reads: a process killed before the proof must not
     * come back claiming the person was blocked.
     */
    val openShownAt: Long = 0,
    val lastReason: String? = null,
    /** 训练题 for the open interception; null when nothing is open. */
    val drill: InterceptDrill? = null,
) {
    fun toMap(): Map<String, Any?> = linkedMapOf(
        "lastTriggerAt" to lastTriggerAt, "lastTriggerPackage" to lastTriggerPackage,
        "releases" to releases, "dayKey" to dayKey, "countToday" to countToday,
        "openEventId" to openEventId, "openPackage" to openPackage, "openSinceWall" to openSinceWall,
        "openShownAt" to openShownAt,
        "lastReason" to lastReason, "drill" to drill?.toMap(),
    )

    companion object {
        fun fromMap(m: Map<*, *>) = InterceptState(
            lastTriggerAt = M.long(m, "lastTriggerAt"), lastTriggerPackage = M.str(m, "lastTriggerPackage"),
            releases = (M.map(m, "releases") ?: emptyMap<String, Any?>()).entries
                .mapNotNull { (k, v) -> if (k is String && v is Number) k to v.toLong() else null }.toMap(),
            dayKey = M.long(m, "dayKey", Long.MIN_VALUE), countToday = M.int(m, "countToday"),
            openEventId = M.str(m, "openEventId"), openPackage = M.str(m, "openPackage"),
            openSinceWall = M.long(m, "openSinceWall"), openShownAt = M.long(m, "openShownAt"), lastReason = M.str(m, "lastReason"),
            drill = InterceptDrill.fromMap(M.map(m, "drill")),
        )
    }
}

/**
 * 拦截守卫. One interception at a time; every state change is written before the call returns and
 * every fact goes into 行为拦截账 through [ledger], keyed by the eventId it belongs to.
 *
 * The eventId is minted here, at the producing end; the page is only ever given a token, and its
 * reports carry no timestamps of their own.
 */
class InterceptGuard(
    private val store: SnapshotStore,
    private val ledger: InterceptLedgerBook,
    private val clock: () -> Long,
    /**
     * 第四阶段 4B: 有仓库时，**所有**持久化都经它一次提交（P0-4）。
     *
     * 没有仓库时保持旧的「守卫自己写 guard.json」行为，现有的纯逻辑测试因此不需要改。
     * 生产路径（InterceptRuntime）永远建仓库，所以真实运行只有一条写路径。
     */
    private val repository: InterceptRepository? = null,
    private val ids: () -> String = { java.util.UUID.randomUUID().toString() },
) {
    private val lock = Any()

    var config = InterceptConfig()
        private set
    var state = InterceptState()
        private set

    /** What the current Block charged, so NOT_SHOWN can restore it (P0-3). Memory only. */
    private var chargedLastTriggerAt = 0L
    private var chargedLastTriggerPackage: String? = null
    private var chargedCountToday = 0

    @Volatile var storageError: String? = null
        private set
    @Volatile var recoveryIssue: String? = null
        private set

    /**
     * Set when this guard's file and the ledger's file disagree after a restart. Two files, two
     * renames: a crash between them leaves one of them ahead. Reported, never silently repaired,
     * because guessing which side is right is how a lost whitelist becomes invisible.
     */
    @Volatile var splitWrite: String? = null
        private set

    /** Process start. An interception that was on screen died with the old process. */
    fun recover(now: Long): InterceptState = synchronized(lock) {
        // 第四阶段 4B: with a repository the snapshot is authoritative, because it is the only thing
        // that was ever committed atomically. Reading guard.json here as well would resurrect the
        // split this class exists to remove - and would read a file that is no longer written.
        val repo = repository
        if (repo != null) {
            val snap = repo.load()
            if (snap != null) {
                M.map(snap.toMap(), "config")?.let { config = InterceptConfig.fromMap(it) }
                M.map(snap.toMap(), "guardState")?.let { state = InterceptState.fromMap(it) }
            } else {
                repo.recoveryIssue?.let { recoveryIssue = it }
            }
        } else {
            when (val r = store.read()) {
                SnapshotStore.Read.Empty -> Unit
                is SnapshotStore.Read.Unreadable -> recoveryIssue = "intercept_unreadable: ${r.error}"
                is SnapshotStore.Read.Loaded -> {
                    M.map(r.map, "config")?.let { config = InterceptConfig.fromMap(it) }
                    M.map(r.map, "state")?.let { state = InterceptState.fromMap(it) }
                }
            }
        }
        val s = state
        if (s.openEventId != null) {
            // The page died with the process. What it was is decided by whether it was ever
            // proved on screen: a trigger that never reached the screen is NOT_SHOWN (nothing was
            // owed), one that did is BLOCKED (it really did stop the person). Recording both as
            // BLOCKED is how "the app was killed before showing anything" turned into a block.
            val shown = s.openShownAt != 0L
            ledger.onEnded(
                InterceptReceipt(
                    eventId = s.openEventId, packageName = s.openPackage.orEmpty(), triggeredAt = s.openSinceWall,
                    endedAt = now,
                    outcome = if (shown) InterceptOutcome.BLOCKED else InterceptOutcome.NOT_SHOWN,
                    reason = if (shown) "process_restart" else "process_restart_before_shown",
                ),
            )
            state = s.copy(
                openEventId = null, openPackage = null, openSinceWall = 0, openShownAt = 0,
                lastReason = if (shown) "open_lost" else "open_lost_unshown", drill = null,
            )
            if (!shown) {
                // The same refund [onUnavailable] makes, for the same reason: this trigger charged
                // a cooldown and a slot of the daily budget, and it never reached the screen. A
                // restarted process cannot know what the pre-trigger values were, so it does the
                // one thing it can prove: it takes this trigger's charge back out.
                //
                // lastTriggerAt = 0 means "no cooldown is running"; countToday loses the one this
                // event added. Both are floored, so a corrupt file cannot make them negative.
                state = state.copy(
                    lastTriggerAt = 0L,
                    lastTriggerPackage = null,
                    countToday = (state.countToday - 1).coerceAtLeast(0),
                )
            }
        }
        // The two files that describe one interception are written one after the other, so a crash
        // between the renames leaves them ahead of each other in one direction or the other. Now
        // that both have been read back, ask the ledger whether the pair is coherent.
        // A whitelist entry is a standing permission, and the only evidence it was granted through
        // the page is the ledger's release count. If the guard holds whitelist entries the ledger
        // has no release for, one of the two writes was lost - and the whitelist is exactly what
        // must never be silently lost.
        val whitelistedNow = config.whitelist.size.toLong()
        ledger.checkConsistency(countedBlocks = 0L, releasedByPerson = whitelistedNow)
        splitWrite = ledger.splitWrite
        // The daily bucket is only rolled from [InterceptEnv.dayKey], which the caller reads from the
        // same calendar it uses for quiet hours; computing a second day number here would make the
        // two disagree and hand out a second day's budget.
        persist()
        state
    }

    fun setConfig(next: InterceptConfig, now: Long): InterceptConfig = synchronized(lock) {
        config = next.normalized()
        // A target removed from the list must not leave its page standing.
        val open = state.openPackage
        if (open != null && config.targetFor(open) == null) {
            endOpen(now, InterceptOutcome.RELEASED, "target_removed", releasedBy = "rule")
        }
        persist()
        config
    }

    /**
     * One verified foreground reading. [InterceptDecision.Block] means: start the blocking page now
     * with this eventId; the caller reports back through [onPageShown] / [onReleased] / [onExited].
     */
    fun onForeground(packageName: String?, env: InterceptEnv, now: Long): InterceptDecision = synchronized(lock) {
        rollDay(env.dayKey)
        val s = state
        // One interception at a time — whatever app is in front. This is checked *before*
        // [InterceptRules.decide] because a Block would stamp lastTriggerAt, increment countToday
        // and, above all, overwrite openEventId: the interception already on screen would then
        // never get an ending, and the new one could not be shown either (the visible-surface slot
        // is still held by the old eventId). Both facts are a person's, not ours to spend:
        // nothing is consumed here, and no receipt is written for a page that never appears.
        // A package that is not a target at all is none of our business, open interception or not:
        // returning Allow here would claim a decision about an app this feature never configured.
        if (packageName.isNullOrBlank()) return@synchronized InterceptDecision.Ignore
        if (config.targetFor(packageName) == null) return@synchronized InterceptDecision.Ignore
        if (s.openEventId != null) {
            val same = s.openPackage == packageName
            return@synchronized InterceptDecision.Allow(
                packageName,
                if (same) InterceptRules.REASON_ALREADY_OPEN else InterceptRules.REASON_ANOTHER_OPEN,
            )
        }
        val d = InterceptRules.decide(
            config, packageName, env, now,
            releasedUntilWall = packageName?.let { s.releases[it] ?: 0 } ?: 0,
            lastTriggerAt = s.lastTriggerAt, lastTriggerPackage = s.lastTriggerPackage, countToday = s.countToday,
        )
        if (d is InterceptDecision.Block) {
            val eventId = ids()
            // Remember what this trigger is about to charge, so a NOT_SHOWN can give it back
            // (P0-3). Kept in memory only: a process death means recover() settles the event,
            // and that path records NOT_SHOWN from the persisted openShownAt instead.
            chargedLastTriggerAt = s.lastTriggerAt
            chargedLastTriggerPackage = s.lastTriggerPackage
            chargedCountToday = s.countToday
            state = s.copy(
                openEventId = eventId, openPackage = packageName, openSinceWall = now,
                lastTriggerAt = now, lastTriggerPackage = packageName, lastReason = d.reason,
                countToday = s.countToday + 1,
                // Minted here, at the producing end, from the eventId: the page can only *press*
                // the drill, never invent or reroll it.
                drill = InterceptDrill.of(eventId),
            )
            // triggerCount counts ATTEMPTS, not blocks: it is incremented the moment a Block is
            // decided, before anything is on screen. blockedCount is what the shown proof adds.
            // dailyMax therefore limits attempts; the settings page says so in those words, and
            // the ledger keeps the two numbers apart so nobody has to guess which one it is.
            ledger.onTriggered(eventId, now)
            persist()
            return@synchronized InterceptDecision.Block(eventId, d.target, d.reason, state.drill!!)
        }
        if (state != s) persist()
        d
    }

    /**
     * Whether an "authorization rule" pass exists at all: the person must have configured at least
     * one window, and this moment must be inside one. An empty rule list is not a rule — offering
     * the door anyway is exactly the bypass this round removes.
     */
    fun hasUsableRule(now: Long): Boolean =
        config.authorizedWindows.isNotEmpty() && InterceptRules.inAuthorizedWindow(config, minuteOfDayOf(now))

    /** Whether the settings page should even offer the rule door. */
    fun ruleDoorExists(): Boolean = config.authorizedWindows.isNotEmpty()


    /** The blocking page is provably on screen (the adapter's visibility proof, not "resumed"). */
    fun onPageShown(eventId: String, now: Long): Boolean = synchronized(lock) {
        if (state.openEventId != eventId) return@synchronized false
        // The evidence of the only fact the block ledger counts as a block: the page was proved
        // on screen. Recorded once, so a repeated Shown cannot inflate blockedCount.
        if (state.openShownAt == 0L) {
            state = state.copy(openShownAt = now)
            ledger.onBlocked(eventId, now)
            persist()
        }
        true
    }

    /**
     * 训练通过 / 授权规则放行. Grants passage for [InterceptConfig.releaseMs] and closes it.
     *
     * [RELEASE_TRAINING] is refused while the 训练题 is unsolved: "the page stayed up long enough"
     * is not training, and a person who leaves the page alone must not come back to a pass.
     */
    fun onReleased(eventId: String, how: String, now: Long): Boolean = synchronized(lock) {
        if (state.openEventId != eventId) return@synchronized false
        // Every way through is earned here, and only here. The page reports *which* door the
        // person chose; whether that door exists is the guard's decision, because the page is
        // the one surface an untrusted build could fake.
        //
        //   training   the drill minted for this event is solved
        //   rule       the person configured at least one authorization window, and this moment
        //              is inside one (a "rule" with no rules is not a rule, it is a free pass)
        //   whitelist  an explicit standing decision: the package leaves the target list
        //
        // Anything else (an unknown code, a typo, a future value) grants nothing.
        //
        // And before any of them: the page must have been *proved* on screen (P0-5).
        // openShownAt is stamped by the adapter's attached+shown+laid-out+focused proof, which is
        // the only evidence that the person actually saw the question. A page that was triggered
        // but never appeared can therefore not walk through any door - it has no door to walk
        // through, because nobody was asked anything.
        if (state.openShownAt == 0L) return@synchronized false
        when (how) {
            RELEASE_TRAINING -> {
                if (state.drill?.solved != true) return@synchronized false
                // trainingMs means what its name says: the drill must have been on screen at least
                // that long before the pass is granted, so speed-tapping four buttons is not a
                // substitute for stopping. 0 disables it.
                //
                // The old form was `shownAt != 0L && now - shownAt < trainingMs`, and that made an
                // unseen page the FASTEST way through: shownAt == 0 skipped the dwell entirely.
                // It is unreachable now - the gate above already refused an unseen page - so the
                // condition reads plainly instead of hiding a bypass.
                if (config.trainingMs > 0L && now - state.openShownAt < config.trainingMs) {
                    return@synchronized false
                }
            }
            RELEASE_RULE -> if (!hasUsableRule(now)) return@synchronized false
            RELEASE_WHITELIST -> Unit
            else -> return@synchronized false
        }
        val pkg = state.openPackage ?: return@synchronized false
        val until = now + config.releaseMs
        state = state.copy(releases = state.releases + (pkg to until))
        // An explicit whitelist add is a standing decision, not a timed one.
        if (how == RELEASE_WHITELIST) config = config.copy(whitelist = config.whitelist + pkg)
        endOpen(
            now, InterceptOutcome.RELEASED, how, releasedBy = how,
            releasedUntilWall = if (how == RELEASE_WHITELIST) 0 else until,
        )
        persist()
        true
    }

    /** 紧急退出: the person leaves at once; recorded as an exit, never as a normal release. */
    fun onExited(eventId: String, now: Long): Boolean = synchronized(lock) {
        if (state.openEventId != eventId) return@synchronized false
        // An exit is the person choosing to leave something they were shown. Without the
        // visibility proof there is nobody leaving and nothing to leave, so this settles the
        // event honestly as NOT_SHOWN instead of recording a walk-away that never happened (P0-5).
        if (state.openShownAt == 0L) {
            endOpen(now, InterceptOutcome.NOT_SHOWN, "exit_before_shown")
            persist()
            return@synchronized true
        }
        endOpen(now, InterceptOutcome.EXITED, "emergency_exit")
        persist()
        true
    }

    /**
     * 暂停: stop intercepting everything for [pauseMs]. [eventId] null pauses from the settings
     * page; a page's own pause button must name the interception it belongs to, so a stale page
     * cannot grab the setting.
     */
    fun onPaused(eventId: String?, pauseMs: Long, now: Long): Boolean = synchronized(lock) {
        if (eventId != null && state.openEventId != eventId) return@synchronized false
        // A page's own pause is the person pressing a button they were shown. Without the
        // visibility proof it settles as NOT_SHOWN and changes no setting (P0-5). The settings
        // page passes eventId = null and is unaffected: that is the person acting in the app.
        if (eventId != null && state.openShownAt == 0L) {
            endOpen(now, InterceptOutcome.NOT_SHOWN, "pause_before_shown")
            persist()
            return@synchronized true
        }
        val until = now + pauseMs.coerceIn(60_000L, 24 * 3_600_000L)
        config = config.copy(pauseUntilWall = until)
        if (eventId != null) {
            endOpen(now, InterceptOutcome.PAUSED, "paused", releasedUntilWall = until)
        } else {
            ledger.onEnded(
                InterceptReceipt(
                    eventId = "pause-${now}", packageName = "", triggeredAt = now, endedAt = now,
                    outcome = InterceptOutcome.PAUSED, reason = "paused", releasedUntilWall = until,
                ),
            )
        }
        persist()
        true
    }

    /**
     * The page could not be shown: the interception did not happen and nothing is owed.
     *
     * "Nothing is owed" has to be made true, not just stated. [onForeground] stamps
     * [InterceptState.lastTriggerAt] and increments [InterceptState.countToday] the moment it
     * decides to block, long before anything is on screen. Ending as NOT_SHOWN therefore has to
     * give both back - otherwise a ROM that refuses the page launch silently costs the person a
     * cooldown and a slot of the daily budget for a block that never happened, and the target app
     * is then let through for the whole cooldown. That was P0-3.
     *
     * The rollback restores what the *previous* interception left behind rather than zeroing, so an
     * earlier genuine block keeps its effect.
     */
        /**
     * 页面在屏上待满上限（D1）：由运行时判定，不由页面报告。
     *
     * 结局是 BLOCKED，理由是 page_ttl —— **不给放行**。这与"超时就放行"正相反：页面被撤下、回桌面、
     * 重新判定前台；目标 APP 如果还在前台就立刻再被拦。
     */
    fun expireOpen(eventId: String, now: Long): Boolean = synchronized(lock) {
        if (state.openEventId != eventId) return@synchronized false
        endOpen(now, InterceptOutcome.BLOCKED, "page_ttl")
        persist()
        true
    }

fun onUnavailable(eventId: String, code: String, now: Long): Boolean = synchronized(lock) {
        if (state.openEventId != eventId) return@synchronized false
        endOpen(now, InterceptOutcome.NOT_SHOWN, code)
        // Give back exactly what this trigger charged.
        state = state.copy(
            lastTriggerAt = chargedLastTriggerAt,
            lastTriggerPackage = chargedLastTriggerPackage,
            countToday = chargedCountToday,
        )
        chargedLastTriggerAt = 0L
        chargedLastTriggerPackage = null
        chargedCountToday = 0
        persist()
        true
    }

    fun openEventId(): String? = synchronized(lock) { state.openEventId }

    fun openPackage(): String? = synchronized(lock) { state.openPackage }

    /** The 训练题 the page must show, or null when nothing is open. */
    fun drill(): InterceptDrill? = synchronized(lock) { if (state.openEventId == null) null else state.drill }

    /**
     * One press of the 训练题. False when the page names an interception that is not the open one —
     * a stale page cannot drill its way into a pass for somebody else's interception.
     *
     * A wrong press resets the progress and is recorded; it never grants anything. The result is
     * persisted with the rest of the state, so a process that dies mid-drill comes back to the same
     * sequence rather than to a fresh, easier one.
     */
    fun tapDrill(eventId: String, value: Int): Boolean = synchronized(lock) {
        if (state.openEventId != eventId) return@synchronized false
        val current = state.drill ?: return@synchronized false
        val next = current.tap(value)
        if (next == current) return@synchronized true
        state = state.copy(drill = next)
        persist()
        true
    }

    fun receipts(limit: Int = 50): List<InterceptReceipt> = synchronized(lock) {
        ledger.state.receipts.takeLast(limit.coerceAtLeast(0)).reversed()
    }

    // ---------------------------------------------------------------- internals

    private fun endOpen(
        now: Long,
        outcome: InterceptOutcome,
        reason: String?,
        releasedBy: String? = null,
        releasedUntilWall: Long = 0,
    ) {
        val s = state
        val id = s.openEventId ?: return
        ledger.onEnded(
            InterceptReceipt(
                eventId = id, packageName = s.openPackage.orEmpty(), triggeredAt = s.openSinceWall, endedAt = now,
                outcome = outcome, reason = reason, releasedUntilWall = releasedUntilWall, releasedBy = releasedBy,
            ),
        )
        state = s.copy(
            openEventId = null, openPackage = null, openSinceWall = 0, openShownAt = 0,
            lastReason = reason, drill = null,
            // 第四阶段 4B · D5: only a RELEASED / PAUSED ending may leave a reason for the app to be
            // let through. BLOCKED and EXITED must not, and the cooldown timestamp is exactly what
            // made an exit behave like a grant: lastTriggerAt stayed set, `decide()` saw "inside the
            // cooldown" and answered Allow, so pressing emergency-exit bought a free window.
            //
            // Clearing it here means an exit neither blocks nor permits: the next reading decides
            // from scratch (and, by D5, blocks again because nothing was earned).
            lastTriggerAt = if (outcome == InterceptOutcome.NOT_SHOWN ||
                outcome == InterceptOutcome.BLOCKED ||
                outcome == InterceptOutcome.EXITED
            ) {
                0L
            } else {
                s.lastTriggerAt
            },
            lastTriggerPackage = if (outcome == InterceptOutcome.NOT_SHOWN ||
                outcome == InterceptOutcome.BLOCKED ||
                outcome == InterceptOutcome.EXITED
            ) {
                null
            } else {
                s.lastTriggerPackage
            },
        )
        // The event is over one way or another: whatever it charged is now this event's business,
        // and a later NOT_SHOWN must not restore a stale snapshot of it.
        chargedLastTriggerAt = 0L
        chargedLastTriggerPackage = null
        chargedCountToday = 0
    }

    /** The local day only moves forward: setting the clock back cannot refill the daily count. */
    private fun rollDay(day: Long) {
        if (day == Long.MIN_VALUE) return
        if (day > state.dayKey) state = state.copy(dayKey = day, countToday = 0)
    }

    /**
     * 持久化。有仓库时**只**经仓库提交一次（P0-4）：config、guard state、ledger state、已应用事件
     * 一起写进同一份快照。没有仓库时退化为旧的单文件写，供纯逻辑测试使用。
     *
     * storageError 记录的是「这一次写有没有成功」。仓库模式下提交是同步回读验证的，所以这里的
     * 失败意味着磁盘上仍然是上一份快照 —— 内存与新值不一致是由调用方负责的（见各 mutating 方法）。
     */
    private fun persist() {
        val repo = repository
        if (repo != null) {
            val ok = repo.commit(
                config = config.toMap(),
                guardState = state.toMap(),
                ledgerState = ledger.state.toMap(),
                appliedEventIds = ledger.appliedIds(),
            )
            storageError = if (ok) null else (repo.lastCommitError ?: "commit failed")
            return
        }
        storageError = try {
            store.write(linkedMapOf("version" to 1, "config" to config.toMap(), "state" to state.toMap())); null
        } catch (t: Throwable) {
            "${t.javaClass.simpleName}: ${t.message}".take(300)
        }
    }

    companion object {
        const val RELEASE_TRAINING = "training"
        const val RELEASE_RULE = "rule"
        const val RELEASE_WHITELIST = "whitelist"

        /** How long a 暂停 lasts by default when the page asks for one. */
        const val DEFAULT_PAUSE_MS = 30 * 60_000L

        /**
         * Local minute of the day, on the same calendar the daily bucket uses. One calendar, so a
         * rule window and a day rollover can never disagree about what time it is.
         */
        fun minuteOfDayOf(wall: Long): Int = java.util.Calendar.getInstance(java.util.TimeZone.getDefault()).run {
            timeInMillis = wall
            get(java.util.Calendar.HOUR_OF_DAY) * 60 + get(java.util.Calendar.MINUTE)
        }
    }
}
