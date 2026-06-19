# kaizen-detect.ps1 — DETERMINISTIC detector of RECURRING failure patterns (substrate of the auto-propose).
# Reads ~/.claude/gate-counters.jsonl (logged by anti-flaky/fix-gate/stop-gate) and emits as JSON the patterns
# that RECUR (same gate, or same gate+file, >= threshold) over a window. The Stop hook calls it to decide
# whether to NUDGE toward the kaizen audit (judge Mode B). PROPOSES and WRITES NOTHING — it detects, period.
# Anti-noise: ignores test sessions (session starting with 'test-').
param([int]$MinCount = 3, [int]$SinceDays = 0)   # SinceDays 0 = tout l'historique

$ErrorActionPreference = 'SilentlyContinue'
$f = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
if (-not (Test-Path $f)) { '[]'; exit 0 }
$cutoff = if ($SinceDays -gt 0) { (Get-Date).AddDays(-$SinceDays) } else { [datetime]::MinValue }
# Fixture globs CONFIGURABLE via env KAIZEN_FIXTURE_PATHS (';'-separated) instead of hardcoded machine paths.
# Default = the test-hooks fixtures (under %TEMP% since the portable hardening) + legacy C:\x\ / C:\tmp\.
# Another machine sets ITS own fixture paths.
$fixtureGlobs = if ($env:KAIZEN_FIXTURE_PATHS) { $env:KAIZEN_FIXTURE_PATHS -split ';' } else { @('C:\x\*', 'C:\tmp\*', ((Join-Path ([System.IO.Path]::GetTempPath()) 'claude-test*'))) }

$rows = @()
foreach ($line in ([System.IO.File]::ReadLines($f))) {   # streaming: does not load the whole file in memory
    if (-not $line.Trim()) { continue }
    try { $o = $line | ConvertFrom-Json } catch { continue }
    $ts = [datetime]::MinValue; try { $ts = [datetime]$o.ts } catch { }
    if ($ts -lt $cutoff) { continue }
    if (([string]$o.session) -match '^test-') { continue }   # anti-noise: the gate's own test runs
    $fpv = [string]$o.file; if ($fpv -and ($fixtureGlobs | Where-Object { $fpv -like $_ })) { continue }  # anti-noise: fixtures (KAIZEN_FIXTURE_PATHS globs)
    # anti-noise: UNATTRIBUTABLE entries (no file and no session) = the gate's own dev/test era, not a real
    # decision -> inadmissible for concluding a habit.
    if (-not ([string]$o.file) -and -not ([string]$o.session)) { continue }
    $rows += [pscustomobject]@{ gate = [string]$o.gate; file = [string]$o.file; ts = $ts }
}

# Dedup RETRIES: 2 events of the same (gate, file) < 5 min apart = ONE decision (a retried edit), not N.
# Otherwise a fix retried 3x inflates the counter toward a fake "systemic habit".
$rows = @($rows | Sort-Object gate, file, ts)
$dedup = @(); $lastKey = $null; $lastTs = $null
foreach ($r in $rows) {
    $key = "$($r.gate)|$($r.file)"
    if ($key -eq $lastKey -and $lastTs -and ($r.ts - $lastTs).TotalMinutes -lt 5) { $lastTs = $r.ts; continue }
    $dedup += $r; $lastKey = $key; $lastTs = $r.ts
}
$rows = $dedup

$patterns = @()
# Recurrence by GATE (a failure type that recurs globally = a systemic habit).
foreach ($g in ($rows | Group-Object gate)) {
    if ($g.Count -ge $MinCount) {
        $patterns += [pscustomobject]@{ kind = 'gate'; gate = $g.Name; file = '';
            count = $g.Count; lastTs = (($g.Group.ts | Measure-Object -Maximum).Maximum).ToString('o');
            behavioral = (@('anti-flaky', 'fix-gate', 'revert', 'stop') -contains $g.Name) }
    }
}
# Recurrence by GATE+FILE (a file re-triggering the same gate = a precise, very actionable pattern).
foreach ($gf in ($rows | Where-Object { $_.file } | Group-Object { $_.gate + '|' + $_.file })) {
    if ($gf.Count -ge $MinCount) {
        $p = $gf.Group[0]
        $patterns += [pscustomobject]@{ kind = 'gate+file'; gate = $p.gate; file = $p.file;
            count = $gf.Count; lastTs = (($gf.Group.ts | Measure-Object -Maximum).Maximum).ToString('o');
            behavioral = (@('anti-flaky', 'fix-gate', 'revert', 'stop') -contains $p.gate) }
    }
}

# Stable pattern signature (for the hook's anti-noise: don't re-nudge the already-treated).
foreach ($p in $patterns) { $p | Add-Member -NotePropertyName sig -NotePropertyValue ("$($p.kind):$($p.gate):$($p.file):$($p.count)") }

# -InputObject + -Compress: JSON array on ONE line, deterministic even empty ('[]') or singleton ('[{...}]')
# -> unambiguous `& detect` capture (a pipe `@()|ConvertTo-Json` emits nothing on empty / unrolls a singleton).
$arr = @($patterns | Sort-Object count -Descending)
ConvertTo-Json -InputObject $arr -Depth 5 -Compress
