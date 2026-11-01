package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * 第四阶段 4B · P0-4: 从旧的两份文件迁移到单一快照。
 *
 * 旧版本把状态写在 `guard.json` 与 `ledger.json` 里。迁移必须**同时**读两份，检查它们互相
 * 说得通，才生成快照。任何说不通的地方都停下来交给人，理由很简单：
 *
 *   如果两份文件已经不一致，那么"哪一份是对的"这件事**没有答案**。猜一个就等于用程序
 *   替用户决定他的白名单是不是存在、他的拦截记录是不是发生过。这比什么都不做更糟。
 *
 * 所以这里的三条规则：
 *   1. 不一致 → RECOVERY_REQUIRED，**不写快照**，旧文件原样留着，用户仍能读到自己的数据
 *   2. 一致 → 生成快照、写入、**回读验证**，通过后才标记完成
 *   3. 已迁移 → 再启动是 no-op（看标记，不重复迁移）
 *
 * 中断安全：迁移的唯一副作用是"写快照 + 写标记"。快照先写、标记后写，所以
 * 中断在两者之间 = 下次重跑（幂等）；中断在写快照之前 = 什么都没变。
 */
object InterceptMigration {

    /** 迁移结果。调用方据此决定继续用快照还是进入人工恢复。 */
    sealed interface Result {
        /** 没有旧文件：全新安装，建空快照即可。 */
        data object Fresh : Result

        /** 旧文件存在且一致，已写入快照。 */
        data class Migrated(val snapshot: InterceptRepository.Snapshot) : Result

        /** 快照已存在，旧文件忽略。 */
        data object AlreadyMigrated : Result

        /** 旧文件互相矛盾：不迁移、不删除、不猜。 */
        data class RecoveryRequired(val reason: String, val detail: String) : Result
    }

    /**
     * @param snapshotStore 快照的存储
     * @param legacyGuardStore 旧 guard.json 的存储（没有就传 null）
     * @param legacyLedgerStore 旧 ledger.json 的存储（没有就传 null）
     */
    fun run(
        snapshotStore: SnapshotStore,
        legacyGuardStore: SnapshotStore?,
        legacyLedgerStore: SnapshotStore?,
    ): Result {
        val repo = InterceptRepository(snapshotStore)
        // A snapshot already on disk wins: migration is not re-run, and the legacy files are left
        // untouched as evidence rather than deleted.
        if (repo.load() != null) return Result.AlreadyMigrated

        val guardRead = legacyGuardStore?.read() ?: SnapshotStore.Read.Empty
        val ledgerRead = legacyLedgerStore?.read() ?: SnapshotStore.Read.Empty

        // Nothing to migrate.
        if (guardRead is SnapshotStore.Read.Empty && ledgerRead is SnapshotStore.Read.Empty) {
            return Result.Fresh
        }

        // One side unreadable is already an inconsistency: we cannot tell what it said, so we must
        // not invent it.
        if (guardRead is SnapshotStore.Read.Unreadable) {
            return Result.RecoveryRequired(
                "legacy guard.json is unreadable",
                guardRead.error,
            )
        }
        if (ledgerRead is SnapshotStore.Read.Unreadable) {
            return Result.RecoveryRequired(
                "legacy ledger.json is unreadable",
                ledgerRead.error,
            )
        }

        val guardMap = (guardRead as? SnapshotStore.Read.Loaded)?.map
        val ledgerMap = (ledgerRead as? SnapshotStore.Read.Loaded)?.map

        val config = guardMap?.let { M.map(it, "config") }
        val guardState = guardMap?.let { M.map(it, "state") }
        val ledgerState = ledgerMap?.let { M.map(it, "ledger") }
        val applied = ledgerMap?.let { M.list(it, "applied").filterIsInstance<String>() } ?: emptyList()

        // 一致性检查 1: 两边的 eventId 必须说得通。
        // 守卫有 open 事件时，账本必须至少有一次触发（触发先于展示）。
        val openId = guardState?.let { M.str(it, "openEventId") }
        val triggerCount = ledgerState?.let { M.long(it, "triggerCount") } ?: 0L
        if (openId != null && triggerCount == 0L) {
            return Result.RecoveryRequired(
                "guard has an open interception but the ledger recorded no trigger",
                "openEventId=" + openId + " triggerCount=" + triggerCount,
            )
        }

        // 一致性检查 2: 计数与回执。
        val receipts = ledgerState?.let { M.list(it, "receipts") } ?: emptyList<Any?>()
        // 这里原本是把四个计数**相加**再和回执数比。那个式子会拒绝一切正常数据：
        //
        //   blockedCount 在 onBlocked() 时 +1（页面真上屏了），而 userReleasedCount 等是在
        //   onEnded() 时 +1 —— **同一个事件同时进了两个计数**。所以一次「展示后放行」的事件，
        //   计数总和是 2，回执只有 1 条。
        //
        // 我在 InterceptRepository.validate() 里犯过同一个错（相位 4B），修好后又在这里原样
        // 复制了一遍。教训是：只要校验条件写的是"和"，就要问一句"这些量能相加吗"。
        //
        // 现在改成两条真正不可能成立的关系：
        //   * 每个结局计数各自 <= 回执数（单个计数不可能超过总回执）
        //   * 触发数 >= 回执数（每次结束都必然先有触发）
        val maxSingle = ledgerState?.let {
            maxOf(
                M.long(it, "blockedCount"), M.long(it, "userReleasedCount"),
                M.long(it, "userExitedCount"), M.long(it, "pausedCount"),
            )
        } ?: 0L
        if (maxSingle > receipts.size) {
            return Result.RecoveryRequired(
                "an outcome count is larger than the number of receipts",
                "max=" + maxSingle + " receipts=" + receipts.size,
            )
        }
        // Settings-page pauses write a receipt without a trigger (see InterceptLedger.SETTINGS_PAUSE_PREFIX).
        val triggered = receipts.count { r ->
            val id = (r as? Map<*, *>)?.let { M.str(it, "eventId") }
            id == null || !id.startsWith(InterceptLedger.SETTINGS_PAUSE_PREFIX)
        }
        if (triggerCount < triggered) {
            return Result.RecoveryRequired(
                "the ledger has more receipts than triggers",
                "triggerCount=" + triggerCount + " receipts=" + triggered,
            )
        }

        // 一致性检查 3: 白名单必须能对应上放行记录。
        // 白名单是永久授权，它只能由一次 RELEASED 产生；账本的放行数少于白名单条目，
        // 说明有一条白名单的写入丢了。**这时绝不"补一条放行"** —— 那是在伪造历史。
        val whitelist = config?.let { M.list(it, "whitelist") } ?: emptyList<Any?>()
        val released = ledgerState?.let { M.long(it, "userReleasedCount") } ?: 0L
        if (whitelist.size.toLong() > released) {
            return Result.RecoveryRequired(
                "the whitelist has entries the ledger never recorded a release for",
                "whitelist=" + whitelist.size + " userReleasedCount=" + released,
            )
        }

        val snapshot = InterceptRepository.Snapshot(
            schemaVersion = InterceptRepository.SCHEMA,
            config = asStringMap(config),
            guardState = asStringMap(guardState),
            ledgerState = asStringMap(ledgerState),
            appliedEventIds = applied,
            lastCommittedTransactionId = 0L,
        )

        // Write it, then read it back. Only a snapshot we can actually read is a finished migration.
        if (!repo.commit(
                config = snapshot.config,
                guardState = snapshot.guardState,
                ledgerState = snapshot.ledgerState,
                appliedEventIds = snapshot.appliedEventIds,
            )
        ) {
            return Result.RecoveryRequired(
                "the migrated snapshot could not be committed",
                repo.lastCommitError ?: "unknown",
            )
        }
        val back = repo.load()
            ?: return Result.RecoveryRequired(
                "the migrated snapshot could not be read back",
                repo.recoveryIssue ?: "unknown",
            )
        return Result.Migrated(back)
    }

    private fun asStringMap(m: Map<*, *>?): Map<String, Any?> {
        if (m == null) return emptyMap()
        val out = LinkedHashMap<String, Any?>()
        for ((k, v) in m) if (k is String) out[k] = v
        return out
    }
}
