# anti-flaky.ps1 — PreToolUse (Write|Edit): dries up mechanical flakiness at the source.
# Denies a CODE diff introducing a raw sleep / blind timing:
#   - Start-Sleep -Seconds N / -s N / positional N (N >= 2)   - Start-Sleep -Milliseconds >= 1000
#   - Thread.Sleep / Task.Delay (>= 4 digits)   - time/asyncio.sleep, setTimeout, ::Sleep
# Known limit (accepted): a sleep via a variable ($n = 5; Start-Sleep $n) escapes static analysis.
# Escape (= the rule "justify in writing any sleep > 1s", enforced by the harness):
#   the offending line contains  sleep-ok: <justification>
# Scope: code files only (.ps1 .psm1 .cs .py .ts .js) — .md/.sql/doc pass.
# Right pattern: poll-until-condition with a cap + short sleeps (<= 500ms).

$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }

$fp = [string]$j.tool_input.file_path
if (-not $fp) { exit 0 }
$ext = [System.IO.Path]::GetExtension($fp).ToLower()
if (-not (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js') -contains $ext)) { exit 0 }

# NEW text introduced: Write -> content ; Edit -> new_string
$text = [string]$j.tool_input.content
if (-not $text) { $text = [string]$j.tool_input.new_string }
if (-not $text) { exit 0 }

$patterns = @(
    'Start-Sleep\s+-Seconds\s+([2-9]\b|\d{2,})',
    'Start-Sleep\s+-s\s+([2-9]\b|\d{2,})',
    'Start-Sleep\s+([2-9]\b|\d{2,})',
    'Start-Sleep\s+-Milliseconds\s+\d{4,}',
    'Start-Sleep\s+(-Seconds\s+)?[1-9]\d*\.\d',
    'Start-Sleep\s*\([^)]*\d',
    'Thread\.Sleep\(\s*[\d_]{4,}',
    'Task\.Delay\(\s*[\d_]{4,}',
    '\bsleep(\s+|\s*\()\s*([2-9]\b|\d{2,})',
    '\]?::Sleep\(\s*[\d_]{4,}',
    '(time|asyncio)\.sleep\(\s*([2-9]|\d{2,})',
    'setTimeout\([^,]+,\s*[\d_]{4,}'
)

$offenders = @()
foreach ($line in ($text -split "`n")) {
    if ($line -match 'sleep-ok:') { continue }
    foreach ($p in $patterns) {
        if ($line -match $p) { $offenders += $line.Trim(); break }
    }
}

if ($offenders.Count -eq 0) { exit 0 }

# Out-of-model telemetry
$counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
# Attributable telemetry: which file, which lines + session_id (so kaizen-detect scopes per session).
$entry = (@{ ts = (Get-Date -Format o); gate = 'anti-flaky'; blocked = $offenders.Count; file = $fp; session = [string]$j.session_id; sample = @($offenders | Select-Object -First 2) } | ConvertTo-Json -Compress)
Add-Content -Path $counters -Value $entry -Encoding utf8

$sample = ($offenders | Select-Object -First 3) -join ' | '
$reason = 'ANTI-FLAKY: raw sleep/timing introduced in code -> ' + $sample + '. Replace with a poll-until-condition (cap 30-60s, sleep <= 500ms as the poll frequency). COMMON LEGITIMATE CASE: waiting for a UI SETTLE after an action with NO end-signal to poll (WPF render post-InitializeAsync, FlaUI/legacy driver) -> do NOT invent a fake poll, annotate the line: sleep-ok: <reason>. Otherwise a long sleep justified another way: sleep-ok: <written justification>.'
@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $reason } } | ConvertTo-Json -Depth 5 -Compress
