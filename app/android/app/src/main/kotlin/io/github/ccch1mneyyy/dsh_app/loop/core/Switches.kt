package io.github.ccch1mneyyy.dsh_app.loop.core

/**
 * Who each switch is for. Two switches the person sees, four jobs:
 *
 * | job                     | runs when                         | owner                          |
 * |-------------------------|-----------------------------------|--------------------------------|
 * | foreground observation  | either feature is on              | LoopRuntime (package name only)|
 * | app-enter trigger       | 触发测试 is on                     | LoopEngine visit + TriggerRules|
 * | random attempts         | 主动搭话 is on                     | ProactiveScheduler             |
 * | interaction arbitration | either feature is on              | Coordinator (sole result owner)|
 *
 * Turning one feature off cancels only that feature's events in the coordinator; the other
 * feature keeps working. Protected-page detection depends on observation only, never on
 * which feature asked for it.
 */
data class Switches(val triggerTest: Boolean, val proactive: Boolean) {
    val observeForeground: Boolean get() = triggerTest || proactive
    val arbitrate: Boolean get() = triggerTest || proactive

    /** Whether events from [source] may be accepted / kept. */
    fun accepts(source: String): Boolean = when (source) {
        SOURCE_APP_ENTER -> triggerTest
        SOURCE_SCHEDULER -> proactive
        else -> arbitrate
    }

    /** Sources whose events must be cancelled now. */
    fun disabledSources(): List<Pair<String, String>> = buildList {
        if (!triggerTest) add(SOURCE_APP_ENTER to "trigger_test_off")
        if (!proactive) add(SOURCE_SCHEDULER to "proactive_off")
    }

    companion object {
        const val SOURCE_APP_ENTER = "A11Y_WINDOW"
        const val SOURCE_SCHEDULER = "SCHEDULER"
    }
}
