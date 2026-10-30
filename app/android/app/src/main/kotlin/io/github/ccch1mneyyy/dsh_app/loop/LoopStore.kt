package io.github.ccch1mneyyy.dsh_app.loop

import io.github.ccch1mneyyy.dsh_app.phone.Json
import java.io.File
import java.io.FileOutputStream

/** Everything the loop must remember across a process restart. */
data class LoopSnapshot(
    val config: LoopConfig = LoopConfig(),
    val tracker: ForegroundTracker.State = ForegroundTracker.State(),
    val lastTriggerAt: Long = 0L,
    /** Oldest first, at most [LoopStore.MAX_EVENTS]. */
    val events: List<LoopEvent> = emptyList(),
) {
    fun toMap(): Map<String, Any?> = linkedMapOf(
        "version" to 1, "config" to config.toMap(), "tracker" to tracker.toMap(),
        "lastTriggerAt" to lastTriggerAt, "events" to events.map { it.toMap() },
    )

    companion object {
        fun fromMap(m: Map<*, *>): LoopSnapshot = LoopSnapshot(
            config = LoopConfig.fromMap(m["config"] as? Map<*, *>),
            tracker = ForegroundTracker.State.fromMap(m["tracker"] as? Map<*, *>),
            lastTriggerAt = (m["lastTriggerAt"] as? Number)?.toLong() ?: 0L,
            events = (m["events"] as? List<*>)?.mapNotNull { (it as? Map<*, *>)?.let(LoopEvent::fromMap) }.orEmpty(),
        )
    }
}

interface LoopStore {
    sealed interface Read {
        data object Empty : Read
        data class Loaded(val snapshot: LoopSnapshot) : Read
        /** A file was there but could not be read: never treated as "nothing saved". */
        data class Unreadable(val error: String) : Read
    }

    fun read(): Read
    fun write(snapshot: LoopSnapshot)

    companion object {
        const val MAX_EVENTS = 200
    }
}

/** Temp file + fsync + rename: a power cut leaves the old file or the new one, never half. */
class FileLoopStore(private val file: File) : LoopStore {
    override fun read(): LoopStore.Read {
        if (!file.exists()) return LoopStore.Read.Empty
        return try {
            val map = Json.parse(file.readText(Charsets.UTF_8)) as? Map<*, *> ?: error("not an object")
            LoopStore.Read.Loaded(LoopSnapshot.fromMap(map))
        } catch (t: Throwable) {
            // Keep the bad file for diagnosis; the next write starts a fresh one.
            runCatching { file.renameTo(File(file.parentFile, file.name + ".bad")) }
            LoopStore.Read.Unreadable("${t.javaClass.simpleName}: ${t.message}".take(300))
        }
    }

    override fun write(snapshot: LoopSnapshot) {
        file.parentFile?.mkdirs()
        val tmp = File(file.parentFile, file.name + ".tmp")
        FileOutputStream(tmp).use { out ->
            out.write(Json.write(snapshot.toMap()).toByteArray(Charsets.UTF_8))
            out.flush()
            out.fd.sync()
        }
        if (!tmp.renameTo(file)) {
            if (file.exists() && !file.delete()) error("cannot replace ${file.name}")
            if (!tmp.renameTo(file)) error("cannot write ${file.name}")
        }
    }
}

/** For tests and for running with storage unavailable. */
class MemoryLoopStore(var saved: LoopSnapshot? = null, var failWrites: Boolean = false) : LoopStore {
    var writes = 0
        private set

    override fun read(): LoopStore.Read = saved?.let { LoopStore.Read.Loaded(it) } ?: LoopStore.Read.Empty
    override fun write(snapshot: LoopSnapshot) {
        if (failWrites) error("disk full")
        saved = snapshot
        writes++
    }
}
