package io.github.ccch1mneyyy.dsh_app.loop.core

import io.github.ccch1mneyyy.dsh_app.phone.Json
import java.io.File
import java.io.FileOutputStream

/** Where the kernel keeps its state across process death. One JSON object per store. */
interface SnapshotStore {
    sealed interface Read {
        data object Empty : Read
        data class Loaded(val map: Map<*, *>) : Read
        /** Something was there and could not be read: never the same as [Empty]. */
        data class Unreadable(val error: String) : Read
    }

    fun read(): Read
    fun write(map: Map<String, Any?>)
}

/** Temp file + fsync + rename: after a power cut the file is the old state or the new one. */
class AtomicJsonFile(private val file: File) : SnapshotStore {
    override fun read(): SnapshotStore.Read {
        if (!file.exists()) return SnapshotStore.Read.Empty
        return try {
            SnapshotStore.Read.Loaded(Json.parse(file.readText(Charsets.UTF_8)) as? Map<*, *> ?: error("not an object"))
        } catch (t: Throwable) {
            runCatching { file.renameTo(File(file.parentFile, file.name + ".bad")) }
            SnapshotStore.Read.Unreadable("${t.javaClass.simpleName}: ${t.message}".take(300))
        }
    }

    override fun write(map: Map<String, Any?>) {
        file.parentFile?.mkdirs()
        val tmp = File(file.parentFile, file.name + ".tmp")
        FileOutputStream(tmp).use { out ->
            out.write(Json.write(map).toByteArray(Charsets.UTF_8))
            out.flush()
            out.fd.sync()
        }
        if (!tmp.renameTo(file)) {
            if (file.exists() && !file.delete()) error("cannot replace ${file.name}")
            if (!tmp.renameTo(file)) error("cannot write ${file.name}")
        }
    }
}

/** Tests, and running with storage unavailable. Round-trips through JSON like the file does. */
class MemorySnapshotStore(var text: String? = null, var failWrites: Boolean = false) : SnapshotStore {
    var writes = 0
        private set

    override fun read(): SnapshotStore.Read {
        val t = text ?: return SnapshotStore.Read.Empty
        return try {
            SnapshotStore.Read.Loaded(Json.parse(t) as Map<*, *>)
        } catch (e: Throwable) {
            SnapshotStore.Read.Unreadable(e.toString())
        }
    }

    override fun write(map: Map<String, Any?>) {
        if (failWrites) error("disk full")
        text = Json.write(map)
        writes++
    }
}

/** Small typed readers for maps parsed by [Json] (integers come back as Long). */
internal object M {
    fun str(m: Map<*, *>, k: String): String? = m[k] as? String
    fun long(m: Map<*, *>, k: String, d: Long = 0): Long = (m[k] as? Number)?.toLong() ?: d
    fun longOrNull(m: Map<*, *>, k: String): Long? = (m[k] as? Number)?.toLong()
    fun int(m: Map<*, *>, k: String, d: Int = 0): Int = (m[k] as? Number)?.toInt() ?: d
    fun bool(m: Map<*, *>, k: String, d: Boolean = false): Boolean = m[k] as? Boolean ?: d
    fun map(m: Map<*, *>, k: String): Map<*, *>? = m[k] as? Map<*, *>
    fun list(m: Map<*, *>, k: String): List<*> = m[k] as? List<*> ?: emptyList<Any?>()
    inline fun <reified E : Enum<E>> enum(m: Map<*, *>, k: String): E? = (m[k] as? String)?.let { v -> enumValues<E>().firstOrNull { it.name == v } }
}
