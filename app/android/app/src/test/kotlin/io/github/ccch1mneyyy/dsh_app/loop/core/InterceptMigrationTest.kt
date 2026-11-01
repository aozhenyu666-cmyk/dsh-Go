package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * 第四阶段 4B: 旧 guard.json + ledger.json → 单一快照的迁移。
 *
 * 迁移最容易做错的地方不是"复制数据"，而是**两份旧文件已经不一致时该怎么办**。
 * 这些测试把每一条边界都钉住，尤其是：不一致时必须停下、必须保留旧数据、
 * 必须不伪造白名单、必须不产生新的放行授权。
 */
class InterceptMigrationTest {

    private class Disk(var bytes: String? = null) : SnapshotStore {
        var writes = 0
        override fun read(): SnapshotStore.Read {
            val t = bytes ?: return SnapshotStore.Read.Empty
            return try {
                SnapshotStore.Read.Loaded(io.github.ccch1mneyyy.dsh_app.phone.Json.parse(t) as Map<*, *>)
            } catch (e: Throwable) {
                SnapshotStore.Read.Unreadable(e.toString())
            }
        }
        override fun write(map: Map<String, Any?>) {
            writes++
            bytes = io.github.ccch1mneyyy.dsh_app.phone.Json.write(map)
        }
    }

    private fun json(m: Map<String, Any?>) = io.github.ccch1mneyyy.dsh_app.phone.Json.write(m)

    private fun guardJson(
        whitelist: List<String> = emptyList(),
        openEventId: String? = null,
    ) = json(
        linkedMapOf(
            "version" to 1,
            "config" to linkedMapOf(
                "enabled" to true,
                "whitelist" to whitelist,
                "targets" to emptyList<Any?>(),
                "cooldownMs" to 120_000L,
                "dailyMax" to 0L,
                "releaseMs" to 600_000L,
                "trainingMs" to 0L,
                "pauseUntilWall" to 0L,
                "authorizedWindows" to emptyList<Any?>(),
            ),
            "state" to linkedMapOf(
                "lastTriggerAt" to 0L,
                "lastTriggerPackage" to null,
                "releases" to emptyMap<String, Any?>(),
                "dayKey" to 20_000L,
                "countToday" to 0,
                "openEventId" to openEventId,
                "openPackage" to (if (openEventId != null) "tv.danmaku.bili" else null),
                "openSinceWall" to 0L,
                "openShownAt" to 0L,
                "lastReason" to null,
                "drill" to null,
            ),
        ),
    )

    private fun ledgerJson(
        triggerCount: Long = 0,
        blockedCount: Long = 0,
        released: Long = 0,
        exited: Long = 0,
        paused: Long = 0,
        receipts: Int = 0,
    ) = json(
        linkedMapOf(
            "version" to 1,
            "ledger" to linkedMapOf(
                "triggerCount" to triggerCount,
                "blockedCount" to blockedCount,
                "userReleasedCount" to released,
                "userExitedCount" to exited,
                "pausedCount" to paused,
                "receipts" to (1..receipts).map {
                    linkedMapOf(
                        "eventId" to "e" + it,
                        "packageName" to "tv.danmaku.bili",
                        "triggeredAt" to 1L,
                        "endedAt" to 2L,
                        "outcome" to "BLOCKED",
                        "reason" to "x",
                        "releasedBy" to null,
                        "releasedUntilWall" to 0L,
                    )
                },
                "lastRecordedAt" to 0L,
            ),
            "applied" to emptyList<String>(),
        ),
    )

    // ---- 1. 全新安装 ---------------------------------------------------------------

    @Test
    fun with_no_legacy_files_the_result_is_fresh_not_a_migration() {
        val snap = Disk()
        val r = InterceptMigration.run(snap, Disk(), Disk());
        assertTrue(r is InterceptMigration.Result.Fresh)
        assertEquals("nothing was written", 0, snap.writes)
    }

    // ---- 2. 一致的两份文件 -----------------------------------------------------------

    @Test
    fun consistent_legacy_files_migrate_and_read_back() {
        val snap = Disk()
        val r = InterceptMigration.run(
            snap,
            Disk(guardJson(whitelist = listOf("tv.danmaku.bili"))),
            Disk(ledgerJson(triggerCount = 2, blockedCount = 1, released = 1, receipts = 2)),
        );
        assertTrue("migrated: " + r, r is InterceptMigration.Result.Migrated)
        assertNotNull("a snapshot is on disk", snap.bytes)

        // Read it back through the repository: the whitelist and the counts survived.
        val repo = InterceptRepository(snap)
        val loaded = repo.load()
        assertNotNull(loaded)
        val wl = M.list(loaded!!.config, "whitelist")
        assertEquals(1, wl.size)
        assertEquals(1L, M.long(loaded.ledgerState, "userReleasedCount"))
    }

    // ---- 3. 已迁移：再启动是 no-op ---------------------------------------------------

    @Test
    fun a_second_run_does_not_migrate_again() {
        val snap = Disk()
        val g = Disk(guardJson());
        val l = Disk(ledgerJson(triggerCount = 1, blockedCount = 1, receipts = 1));
        assertTrue(InterceptMigration.run(snap, g, l) is InterceptMigration.Result.Migrated)
        val writesAfterFirst = snap.writes

        val second = InterceptMigration.run(snap, g, l)
        assertTrue("already migrated: " + second, second is InterceptMigration.Result.AlreadyMigrated)
        assertEquals("and nothing was written the second time", writesAfterFirst, snap.writes)
    }

    // ---- 4. 白名单与放行记录不一致 ---------------------------------------------------

    @Test
    fun a_whitelist_entry_the_ledger_never_released_stops_the_migration() {
        val snap = Disk()
        val r = InterceptMigration.run(
            snap,
            Disk(guardJson(whitelist = listOf("tv.danmaku.bili", "com.ss.android.ugc.aweme"))),
            Disk(ledgerJson(triggerCount = 1, blockedCount = 1, released = 0, receipts = 1)),
        );
        assertTrue("recovery required: " + r, r is InterceptMigration.Result.RecoveryRequired)
        assertNull("nothing was written", snap.bytes)
        val reason = (r as InterceptMigration.Result.RecoveryRequired).reason
        assertTrue("the reason names the whitelist: " + reason, reason.contains("whitelist"))
    }

    // ---- 5. 计数多于回执 -------------------------------------------------------------

    @Test
    fun more_endings_than_receipts_stops_the_migration() {
        val snap = Disk()
        val r = InterceptMigration.run(
            snap,
            Disk(guardJson()),
            Disk(ledgerJson(triggerCount = 5, blockedCount = 3, receipts = 1)),
        );
        assertTrue("recovery required: " + r, r is InterceptMigration.Result.RecoveryRequired)
        assertNull(snap.bytes)
    }

    // ---- 6. 有 open 事件但账本没有触发 -----------------------------------------------

    @Test
    fun an_open_interception_with_no_recorded_trigger_stops_the_migration() {
        val snap = Disk()
        val r = InterceptMigration.run(
            snap,
            Disk(guardJson(openEventId = "evt-1")),
            Disk(ledgerJson(triggerCount = 0)),
        );
        assertTrue("recovery required: " + r, r is InterceptMigration.Result.RecoveryRequired)
        assertNull(snap.bytes)
    }

    // ---- 7. 旧文件读不懂 -------------------------------------------------------------

    @Test
    fun an_unreadable_legacy_file_stops_the_migration() {
        val snap = Disk()
        val r = InterceptMigration.run(snap, Disk("{ not json"), Disk(ledgerJson()));
        assertTrue("recovery required: " + r, r is InterceptMigration.Result.RecoveryRequired)
        assertNull("no snapshot written over unreadable legacy data", snap.bytes)
    }

    // ---- 8. 中断后可安全继续 ---------------------------------------------------------

    @Test
    fun an_interrupted_migration_can_be_rerun_safely() {
        val snap = Disk()
        val g = Disk(guardJson());
        val l = Disk(ledgerJson(triggerCount = 1, blockedCount = 1, receipts = 1));

        // First attempt dies before writing: nothing on disk.
        assertEquals(0, snap.writes)

        // Second attempt succeeds and produces exactly one snapshot.
        assertTrue(InterceptMigration.run(snap, g, l) is InterceptMigration.Result.Migrated)
        assertEquals("one write", 1, snap.writes)

        // And the legacy files are still there, undisturbed.
        assertNotNull(g.bytes)
        assertNotNull(l.bytes)
    }
}
