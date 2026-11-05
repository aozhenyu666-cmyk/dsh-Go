param(
    [string]$Serial = '',
    [string]$Out = ''
)

# P0 companion audit: collect the real-device chain state with adb and write a
# markdown report. ASCII-only source so PowerShell 5.1 can parse it regardless
# of the console code page; the report file is written as UTF-8 without BOM.

$ErrorActionPreference = 'Continue'
$adb = 'D:\code\android-sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }
$pkg = 'io.github.ccch1mneyyy.dsh_app'
$dsh = 'files/runtime/rootfs/root/.dsh'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $Out) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $Out = Join-Path $root "app\build\P0-AUDIT-$stamp.md"
}

if (-not $Serial) {
    $lines = & $adb devices 2>&1
    $device = $lines | Where-Object { $_ -match "^(\S+)\s+device$" } | Select-Object -First 1
    if ($device -and $device -match "^(\S+)") { $Serial = $Matches[1] }
}
if (-not $Serial) {
    Write-Host 'No adb device. Connect the phone and retry.'
    exit 2
}

function A([string]$command) {
    & $adb -s $Serial shell $command 2>&1 | Out-String
}

function R([string]$path) {
    A "run-as $pkg sh -c 'cat $path 2>/dev/null'"
}

function Section([string]$title, [string]$body) {
    "## $title`n`n``````text`n$($body.Trim())`n``````n" | Out-String
}

$model = (A 'getprop ro.product.model').Trim()
$sdk = (A 'getprop ro.build.version.sdk').Trim()
$update = (A "dumpsys package $pkg") -split "`n" | Where-Object { $_ -match 'versionName=|lastUpdateTime=' } | ForEach-Object { $_.Trim() }
$a11y = (A 'settings get secure enabled_accessibility_services').Trim()
$notif = A "cmd appops get $pkg POST_NOTIFICATION"
$battery = (A 'dumpsys deviceidle whitelist') -split "`n" | Where-Object { $_ -match [regex]::Escape($pkg) }
$node = (A "ps -A") -split "`n" | Where-Object { $_ -match '\snode\s*$' }
$logs = (A "run-as $pkg sh -c 'grep -a -E ""\[companion\]|\[memory\]|\[relationship\]|\[strict\]"" files/runtime/logs/dsh.log | tail -30'")
$cfg = R "$dsh/companion/config.json"
$ledger = R "$dsh/companion/ledger.jsonl"
$mem = A "run-as $pkg ls -l $dsh/fish-memory"

$entries = @()
foreach ($line in ($ledger -split "`n")) {
    $t = $line.Trim()
    if (-not $t.StartsWith('{')) { continue }
    try { $entries += ($t | ConvertFrom-Json) } catch { }
}
$states = @{}
$requests = @{}
foreach ($e in $entries) {
    if ($e.state) { $states[$e.state] = 1 + [int]$states[$e.state] }
    if ($e.requestId) { $requests[$e.requestId] = 1 }
}
$stateRows = ($states.GetEnumerator() | Sort-Object Name | ForEach-Object { "- $($_.Key): $($_.Value)" }) -join "`n"

$findings = New-Object System.Collections.Generic.List[string]
if (-not $node) { $findings.Add('engine: no node process (engine not running)') }
if ($logs -notmatch '\[companion\] loaded') { $findings.Add('plugin: no "[companion] loaded" in the engine log') }
if ($cfg -notmatch '"sessionId"') { $findings.Add('target: companion config has no sessionId') }
if ($mem -notmatch 'fish-memory.sqlite') { $findings.Add('memory: fish-memory.sqlite missing (no topics to talk about)') }
if ($entries.Count -eq 0) { $findings.Add('ledger: empty (no proactive attempt reached the plugin)') }
if ($states['accepted'] -gt 0 -and $states['generated'] -eq 0) { $findings.Add('turn: accepted but never generated (model/turn/deadline)') }
if ($states['generated'] -gt 0 -and -not $states['displayed']) { $findings.Add('surface: generated but not displayed (notification/page path)') }
if ($findings.Count -eq 0) { $findings.Add('no obvious break point in the collected data') }

$md = @()
$md += '# P0 companion audit'
$md += ''
$md += "- device: $model (API $sdk)"
$md += "- serial: $Serial"
$md += "- time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$md += ''
$md += '## First break point'
$md += ''
$md += ($findings | ForEach-Object { "- $_" }) -join "`n"
$md += ''
$md += Section 'Package' (($update -join "`n") + "`n`n" + (A "pm path $pkg"))
$md += Section 'Accessibility' $a11y
$md += Section 'Notification permission' $notif
$md += Section 'Battery whitelist' (($battery -join "`n"))
$md += Section 'Engine process' (($node -join "`n"))
$md += Section 'Engine log (companion/memory/relationship/strict)' $logs
$md += Section 'Companion config' $cfg
$md += Section 'Memory database' $mem
$md += Section 'Ledger counts' ("requests: $($requests.Count)`n`n$stateRows")
$md += Section 'Ledger tail (last 30 lines)' (($ledger -split "`n" | Select-Object -Last 30) -join "`n")
$md += ''
$md += '## Manual checks'
$md += ''
$md += '- Open DSH Go -> Settings -> phone control -> proactive: target session chosen, enabled.'
$md += '- Tap "try once"; then check whether a notification/page appears within ~30 s.'
$md += '- Send a substantive reply and re-run this script: ledger should add replied/substantive.'
$md += '- Lock the screen for 2 h and repeat: this tells whether the alarm actually wakes the engine.'

New-Item -ItemType Directory -Force (Split-Path $Out) | Out-Null
[IO.File]::WriteAllText($Out, ($md -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host "wrote $Out"
Write-Host ''
Write-Host 'First break point:'
$findings | ForEach-Object { Write-Host "  - $_" }
