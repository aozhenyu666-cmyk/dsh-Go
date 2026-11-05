package io.github.ccch1mneyyy.dsh_app.runtime

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BuiltinPluginGuestTest {
    private val launch = "echo $$ > /tmp/dsh-web.pid; exec /usr/local/bin/dsh web --patch /etc/dsh-app/dsh-web.patch.yml --host 127.0.0.1 --port 3080 --no-open"

    @Test fun addsTheOverlayRightAfterTheAppsOwnPatch() {
        assertEquals(
            "echo $$ > /tmp/dsh-web.pid; exec /usr/local/bin/dsh web --patch /etc/dsh-app/dsh-web.patch.yml " +
                "--patch /opt/dsh-app/plugins/plugins.patch.yml --host 127.0.0.1 --port 3080 --no-open",
            BuiltinPluginGuest.launchArg(launch),
        )
    }

    @Test fun chainsWithTheOtherOverlaysWithoutDuplicatingItself() {
        val searched = SessionSearchGuest.launchArg(launch)!!
        val once = BuiltinPluginGuest.launchArg(searched)!!
        assertNull(BuiltinPluginGuest.launchArg(once))
        assertTrue(once.contains("--patch /opt/dsh-app/search.patch.yml"))
        assertTrue(once.contains("--patch /opt/dsh-app/plugins/plugins.patch.yml"))
        assertEquals(1, Regex("plugins\\.patch\\.yml").findAll(once).count())
    }

    @Test fun leavesOtherArgumentsAndSafeModeAlone() {
        assertNull(BuiltinPluginGuest.launchArg("/usr/bin/env"))
        assertNull(BuiltinPluginGuest.launchArg("exec /usr/local/bin/dsh web --profile safe --port 1"))
    }

    @Test fun overlayInsertsEveryBundledPluginByAbsolutePath() {
        val yaml = BuiltinPluginGuest.PATCH_YAML
        assertTrue(yaml.contains("- id: dsh-go-relationship\n"))
        assertTrue(yaml.contains("      name: /opt/dsh-app/plugins/dsh-go-relationship/lib/index.js\n"))
        assertTrue(yaml.contains("- id: dsh-speak-up\n"))
        assertTrue(yaml.contains("      name: /opt/dsh-app/plugins/dsh-speak-up/lib/host.js\n"))
        assertTrue(yaml.contains("- id: dsh-feiyu-mood\n"))
        assertTrue(yaml.contains("      name: /opt/dsh-app/plugins/dsh-feiyu-mood/lib/index.js\n"))
        assertTrue(yaml.contains("- id: dsh-fish-strict\n"))
        assertTrue(yaml.contains("      name: /opt/dsh-app/plugins/dsh-fish-strict/lib/index.js\n"))
        assertTrue(yaml.contains("- id: dsh-go-memory\n"))
        assertTrue(yaml.contains("      name: /opt/dsh-app/plugins/dsh-go-memory/lib/index.js\n"))
        assertTrue(yaml.contains("- id: dsh-go-companion\n"))
        assertTrue(yaml.contains("      name: /opt/dsh-app/plugins/dsh-go-companion/lib/index.js\n"))
        // package.json is what makes the copied .js files ESM on the guest.
        assertTrue(BuiltinPluginGuest.PLUGINS.all { it.files.contains("package.json") })
        assertEquals(6, BuiltinPluginGuest.PLUGINS.size)
    }
}
