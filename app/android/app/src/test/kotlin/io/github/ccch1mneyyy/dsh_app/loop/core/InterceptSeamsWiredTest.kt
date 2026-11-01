package io.github.ccch1mneyyy.dsh_app.loop.core

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * 第四阶段 W2/W3: 接缝必须被接线。
 *
 * 这条测试的由来：D2 的三个接缝都写了默认值，其中 `currentForeground = { null }`
 * 和 `notifyEnforcementUnavailable = { }` 在生产里从来没被替换过。结果 D2 看起来"做完了"，
 * 实际每次展示失败都会多按两次 HOME 然后静默放弃。
 *
 * JVM 上拿不到 Android 的接缝实例，所以这里做**源码检查**：读 InterceptRuntime.kt 的文本，
 * 断言那些"看起来成功"的空默认值已经不存在。这不是优雅的测试，但它能挡住同类问题第四次发生。
 */
class InterceptSeamsWiredTest {

    private fun runtimeSource(): String {
        // The test runs from the repository root (run-kernel-tests.sh compiles sources there).
        val f = File(
            "app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/loop/intercept/InterceptRuntime.kt",
        )
        assertTrue("cannot find InterceptRuntime.kt at " + f.absolutePath + " (run from the repo root)", f.isFile)
        return f.readText()
    }

    @Test
    fun the_foreground_seam_is_not_a_null_default() {
        val src = runtimeSource()
        assertTrue(
            "currentForeground still defaults to { null }: D2 would treat every read as \"not left\"",
            !src.contains("var currentForeground: () -> String? = { null }"),
        )
    }

    @Test
    fun the_notification_seam_is_not_an_empty_default() {
        val src = runtimeSource()
        assertTrue(
            "notifyEnforcementUnavailable is still { }: the person would never be told",
            !src.contains("var notifyEnforcementUnavailable: (String) -> Unit = { }"),
        )
    }

    @Test
    fun the_production_guard_is_built_with_a_repository() {
        val src = runtimeSource()
        assertTrue(
            "InterceptRuntime must not build its own guard: it delegates to InterceptKernel.open",
            src.contains("InterceptKernel.open("),
        )
    }
}
