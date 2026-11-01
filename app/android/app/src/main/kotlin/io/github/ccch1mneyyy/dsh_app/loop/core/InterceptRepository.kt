package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * 第四阶段 4B · P0-4: 拦截状态的**唯一**事务所有者。
 *
 * 一次拦截由两组状态描述（guard: config / open 事件 / 冷却 / 白名单；ledger: 回执与计数），
 * 原来它们各写各的文件。两份各自原子，**合起来不原子** —— 崩在两次 rename 之间就留下
 * 「计数有、回执无」「白名单丢了」这类矛盾状态。
 *
 * 这个类把它们绑成**一次提交**：一份快照、一个文件、一次原子替换。
 *
 * 提交协议（顺序不可变）：
 *   1. 由内存算出新快照（不读盘：内存就是上一份成功提交的结果）
 *   2. 校验内部一致性
 *   3. 交给 [SnapshotStore.write] —— 它负责 临时文件 → flush → fsync → 原子替换 → 目录 fsync
 *   4. **回读并比对**：落盘的必须就是刚算出来的那份
 *   5. 只有第 4 步通过，才把内存切到新值并返回成功
 *
 * 任何一步失败：内存不动、返回失败、旧快照仍可读。**绝不提前改内存** —— 那会让「写失败」
 * 看起来像「提交成功」，正是要消灭的那类错误。
 */
class InterceptRepository(
    private val store: SnapshotStore,
) {

    /** 快照的结构版本。改变持久化形状时 +1。 */
    data class Snapshot(
        val schemaVersion: Int = SCHEMA,
        val config: Map<String, Any?> = emptyMap(),
        val guardState: Map<String, Any?> = emptyMap(),
        val ledgerState: Map<String, Any?> = emptyMap(),
        val appliedEventIds: List<String> = emptyList(),
        val lastCommittedTransactionId: Long = 0L,
    ) {
        fun toMap(): Map<String, Any?> = linkedMapOf(
            "schemaVersion" to schemaVersion,
            "config" to config,
            "guardState" to guardState,
            "ledgerState" to ledgerState,
            "appliedEventIds" to appliedEventIds,
            "lastCommittedTransactionId" to lastCommittedTransactionId,
        )

        companion object {
            fun fromMap(m: Map<*, *>) = Snapshot(
                schemaVersion = M.int(m, "schemaVersion", SCHEMA),
                config = asAnyMap(M.map(m, "config")),
                guardState = asAnyMap(M.map(m, "guardState")),
                ledgerState = asAnyMap(M.map(m, "ledgerState")),
                appliedEventIds = M.list(m, "appliedEventIds").filterIsInstance<String>(),
                lastCommittedTransactionId = M.long(m, "lastCommittedTransactionId"),
            )

            private fun asAnyMap(m: Map<*, *>?): Map<String, Any?> {
                if (m == null) return emptyMap()
                val out = LinkedHashMap<String, Any?>()
                for ((k, v) in m) if (k is String) out[k] = v
                return out
            }
        }
    }

    /** 最近一次成功提交的快照（内存中的权威值）。 */
    var committed = Snapshot()
        private set

    /** 最近一次提交失败的原因；成功后清空。 */
    @Volatile var lastCommitError: String? = null
        private set

    /** 已经成功的提交次数，用作事务编号。 */
    var transactions = 0L
        private set

    /** 快照读不懂时的原因。非空即 RECOVERY_REQUIRED。 */
    @Volatile var recoveryIssue: String? = null
        private set

    /**
     * 读取磁盘上已有的快照。返回 null 表示「没有快照」（首次安装）。
     *
     * 读不懂时**不抛**：设置 [recoveryIssue] 并返回 null，调用方据此进入 RECOVERY_REQUIRED，
     * 而不是拿一份空状态假装是新装。
     */
    fun load(): Snapshot? {
        when (val r = store.read()) {
            SnapshotStore.Read.Empty -> return null
            is SnapshotStore.Read.Unreadable -> {
                recoveryIssue = "intercept snapshot unreadable: " + r.error
                return null
            }
            is SnapshotStore.Read.Loaded -> {
                val snap = try {
                    Snapshot.fromMap(r.map)
                } catch (t: Throwable) {
                    recoveryIssue = ("intercept snapshot malformed: " + t.message).take(300)
                    return null
                }
                if (snap.schemaVersion > SCHEMA) {
                    // A newer build wrote it. Refusing is the only safe answer: writing our older
                    // shape over it would drop whatever the newer schema added.
                    recoveryIssue = "intercept snapshot schemaVersion=" + snap.schemaVersion + " > " + SCHEMA
                    return null
                }
                committed = snap
                transactions = snap.lastCommittedTransactionId
                return snap
            }
        }
    }

    /**
     * 一次提交。true 表示**已被可靠写入并回读验证**。
     */
    fun commit(
        config: Map<String, Any?>,
        guardState: Map<String, Any?>,
        ledgerState: Map<String, Any?>,
        appliedEventIds: List<String>,
    ): Boolean {
        val next = Snapshot(
            schemaVersion = SCHEMA,
            config = config,
            guardState = guardState,
            ledgerState = ledgerState,
            appliedEventIds = appliedEventIds,
            lastCommittedTransactionId = transactions + 1,
        )
        val problem = validate(next)
        if (problem != null) {
            // Refusing here beats writing an incoherent snapshot: the next process would read it
            // back as if it were true.
            lastCommitError = problem
            return false
        }
        return try {
            store.write(next.toMap())
            // Read back. A store that "succeeded" without persisting is exactly the failure mode
            // this step exists for, and nothing else can detect it.
            val readBack = store.read()
            val landed = when (readBack) {
                is SnapshotStore.Read.Loaded -> Snapshot.fromMap(readBack.map)
                is SnapshotStore.Read.Unreadable -> {
                    lastCommitError = "commit read-back failed: " + readBack.error
                    return false
                }
                SnapshotStore.Read.Empty -> {
                    lastCommitError = "commit read-back found nothing"
                    return false
                }
            }
            // Compare the serialised form, not the Map objects: JSON round-trips numbers as Long,
            // so a value written as Int reads back as Long and Map equality would differ for a
            // reason that has nothing to do with persistence.
            val expectedText = io.github.ccch1mneyyy.dsh_app.phone.Json.write(next.toMap())
            val actualText = io.github.ccch1mneyyy.dsh_app.phone.Json.write(landed.toMap())
            if (expectedText != actualText) {
                lastCommitError = "commit read-back differs from what was written"
                return false
            }
            // Only now may memory move.
            committed = next
            transactions = next.lastCommittedTransactionId
            lastCommitError = null
            true
        } catch (t: Throwable) {
            lastCommitError = (t.javaClass.simpleName + ": " + t.message).take(300)
            false
        }
    }

    /**
     * 提交前的自洽检查。它是**快照**的性质，不属于某一次操作。
     *
     * 第一版这里写错了，值得记下来：我原本要求「各结局计数之和 <= 回执数」，看起来天经地义，
     * 实际上会把每一次正常提交都拒掉 —— 因为 blockedCount 数的是**页面真的上屏了**，而回执要到
     * 事件**结束**才写。所以"已展示、尚未结束"这个中间态合法地满足 blockedCount=1、receipts=0。
     * 校验太严的后果不是"更安全"，而是"所有提交都失败，状态永远停在第一次" —— 比不校验更糟。
     *
     * 现在的三条只保留真正不可能成立的关系：
     *   * triggerCount 是尝试次数，必须 >= 回执数（每次结束都必然先有触发）
     *   * 已应用事件键不得重复（去重表是 Set，重复说明写坏了）
     *   * 未结束的 open 事件必须同时有包名（只有 eventId 是半条记录）
     */
    private fun validate(s: Snapshot): String? {
        val ledger = s.ledgerState
        val receipts = M.list(ledger, "receipts")
        val trigger = M.long(ledger, "triggerCount")
        if (trigger < receipts.size) {
            return "triggerCount (" + trigger + ") is smaller than receipts (" + receipts.size + ")"
        }
        if (s.appliedEventIds.distinct().size != s.appliedEventIds.size) {
            return "appliedEventIds has duplicates"
        }
        val guard = s.guardState
        val openId = M.str(guard, "openEventId")
        if (openId != null && M.str(guard, "openPackage") == null) {
            return "an open interception has an eventId but no package"
        }
        return null
    }

    companion object {
        const val SCHEMA = 1

        /** 快照文件名。旧的两个文件由迁移层读取，不再写入。 */
        const val FILE_NAME = "intercept.snapshot.json"
    }
}
