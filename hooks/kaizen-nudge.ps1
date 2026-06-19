# kaizen-nudge.ps1 — Stop hook: DETECTS a RECURRING behavioral failure pattern (via kaizen-detect.ps1) and
# NUDGES (non-blocking) toward the kaizen audit. NEVER BLOCKS (stop-gate holds the blocking authority) and
# NEVER WRITES the kit — it only proposes launching the audit. Writing stays human-gated.
# Anti-noise: 1 nudge max / session (TEMP flag) + cross-session ledger (~/.claude/kaizen-treated.jsonl:
# re-nudge an already-treated pattern only if its count climbed back by >= +5).
$ErrorActionPreference = 'SilentlyContinue'
try {
    $raw = [Console]::In.ReadToEnd()
    $j = $raw | ConvertFrom-Json
    $sid = [string]$j.session_id
    if (-not $sid) { exit 0 }

    # 1 nudge max / session.
    $flag = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-kaizen-nudge-$sid.flag")
    if (Test-Path $flag) { exit 0 }

    # Detection: FRESH behavioral recurrence (>=5 over 30d, anti-flaky/fix-gate only).
    $detect = Join-Path $env:USERPROFILE '.claude\hooks\kaizen-detect.ps1'
    if (-not (Test-Path $detect)) { exit 0 }
    $out = (& $detect -MinCount 5 -SinceDays 30) -join "`n"   # -join : capture mono-string non ambigue
    if (-not $out) { exit 0 }
    # PS5.1: parse into a VARIABLE before filtering (an inline `... | ConvertFrom-Json | Where` emits the
    # array as ONE non-enumerated object -> $_.behavioral becomes a truthy array and stop passes the filter).
    $parsed = $out | ConvertFrom-Json
    $patterns = @($parsed | Where-Object { $_.behavioral -and $_.kind -eq 'gate' })
    if (-not $patterns.Count) { exit 0 }
    $p = ($patterns | Sort-Object count -Descending)[0]

    # Cross-session ledger: don't re-nudge a treated pattern without a >= +5 regain.
    $ledger = Join-Path $env:USERPROFILE '.claude\kaizen-treated.jsonl'
    if (Test-Path $ledger) {
        $prev = Get-Content $ledger | ForEach-Object { try { $_ | ConvertFrom-Json } catch { } } |
            Where-Object { $_.gate -eq $p.gate } | Sort-Object treatedCount -Descending | Select-Object -First 1
        if ($prev -and ($p.count - [int]$prev.treatedCount) -lt 5) { exit 0 }
    }

    # Set the flag BEFORE emitting (idempotence: a single nudge even if the hook re-fires).
    New-Item -ItemType File -Path $flag -Force | Out-Null

    $msg = "KAIZEN -- REAL recurring pattern: the guardrail << $($p.gate) >> blocked $($p.count)x (gate-counters, excluding test/dev). " +
        "Enough real signal accumulated -> launch the TELEMETRY-DRIVEN loop: Workflow name 'improve-from-telemetry' " +
        "(it diagnoses THESE real blocks -- false-positive to relax vs real issue to fix -- and proposes a scored fix, PROPOSE only). " +
        "Alternative: kaizen audit (judge Mode B). Nothing is written without your OK; re-nudge if the pattern regains +5."
    (@{ hookSpecificOutput = @{ hookEventName = 'Stop'; additionalContext = $msg } } | ConvertTo-Json -Depth 6 -Compress)
}
catch { exit 0 }
