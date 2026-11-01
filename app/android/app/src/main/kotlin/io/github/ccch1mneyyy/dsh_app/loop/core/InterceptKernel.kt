package io.github.ccch1mneyyy.dsh_app.loop.core

import java.io.File

/**
 * 第四阶段 W1: 生产初始化必须走原子快照，而不是两份文件。
 *
 * 到这里之前，`InterceptRepository` 和 `InterceptMigration` 都只有测试在用 ——
 * 线上仍然 new 两个 `AtomicJsonFile`，所以 P0-4 的原子性和旧数据迁移一次都没有真正执行过。
 * 这个工厂就是那条缺失的线。
 *
 * **不得 import 任何 android.*** —— 这个文件要在纯 JVM 上被测（见 InterceptKernelTest）。
 *
 * 装配顺序不可变（与 `InterceptRepositoryCrashTest.Proc.boot()` 一致）：
 *
 *   1. 迁移先跑：它会决定这次用快照还是退回旧文件
 *   2. `repo.load()` 读快照 —— 一个文件，一次读，一份真相
 *   3. 把快照视图交给账本，再让账本 recover
 *   4. 守卫最后 recover，读的是同一份视图
 *
 * **迁移判定为 RecoveryRequired 时退回旧的两文件模式**：宁可不原子，也不丢用户的白名单。
 * 旧文件一个字节都不动。
 */
object InterceptKernel {

    /** 打开后的三件套，外加迁移结果，供调用方决定如何暴露状态。 */
    class Opened(
        val guard: InterceptGuard,
        val ledger: InterceptLedgerBook,
        /** null 表示迁移要求人工介入，已退回旧的两文件模式。 */
        val repo: InterceptRepository?,
        val migration: InterceptMigration.Result,
    ) {
        /** 旧数据需要人工处理时的原因；正常情况下为 null。 */
        val recoveryIssue: String?
            get() = (migration as? InterceptMigration.Result.RecoveryRequired)?.let {
                it.reason + ": " + it.detail
            }
    }

    fun open(dir: File, clock: () -> Long, ids: () -> String): Opened {
        val snapshot = AtomicJsonFile(File(dir, InterceptRepository.FILE_NAME));
        val legacyGuard = File(dir, "guard.json").let { if (it.exists()) AtomicJsonFile(it) else null }
        val legacyLedger = File(dir, "ledger.json").let { if (it.exists()) AtomicJsonFile(it) else null }

        val migration = InterceptMigration.run(snapshot, legacyGuard, legacyLedger);

        return when (migration) {
            is InterceptMigration.Result.RecoveryRequired -> legacyFallback(dir, clock, ids, migration)
            else -> onSnapshot(snapshot, clock, ids, migration)
        }
    }

    /** 正常路径：一份快照，一个事务所有者。 */
    private fun onSnapshot(
        snapshot: AtomicJsonFile,
        clock: () -> Long,
        ids: () -> String,
        migration: InterceptMigration.Result,
    ): Opened {
        val repo = InterceptRepository(snapshot)
        repo.load()
        val ledger = InterceptLedgerBook(snapshot, sharedWithRepository = true)
        // The view must be installed before recover(), or the ledger reads the snapshot as empty.
        ledger.repositoryView = { repo.committed.toMap() }
        ledger.recover()
        val guard = InterceptGuard(snapshot, ledger, clock, repository = repo, ids = ids)
        guard.recover(clock())
        return Opened(guard, ledger, repo, migration)
    }

    /**
     * 迁移要求人工介入：退回旧的两文件模式。
     *
     * 这里显式不用 repository（`repository` 保持默认 null），因为快照的生成条件不成立。
     * 旧文件保持原样，用户的白名单还在，只是暂时没有原子性 —— 这是刻意的取舍。
     */
    private fun legacyFallback(
        dir: File,
        clock: () -> Long,
        ids: () -> String,
        migration: InterceptMigration.Result.RecoveryRequired,
    ): Opened {
        val ledger = InterceptLedgerBook(AtomicJsonFile(File(dir, "ledger.json")))
        ledger.recover()
        val guard = InterceptGuard(
            AtomicJsonFile(File(dir, "guard.json")), ledger, clock, ids = ids,
        ) // legacy-fallback: 快照不成立，只能用旧文件
        guard.recover(clock())
        return Opened(guard, ledger, null, migration)
    }
}
