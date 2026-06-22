# fix-gate.ps1 — PreToolUse (Write|Edit): dries up the BLIND-FIX LOOP at the source.
# A PASSIVE "fix carefully" skill is never invoked; only a GATE changes behavior (structure > skill). This
# gate enforces the discipline the skill described: before re-coding on an unknown cause -> REPRODUCE +
# RESEARCH the cause first.
#
# Rule: from the THRESHOLD-th edit of the SAME code file in a session -> BLOCK, UNLESS the discipline is
# BOUND TO THAT FILE: a session RUN.md that NAMES the file AND carries a 'CausalHypothesis:' (cause + source)
# or a 'check:' line ; OR 'fix-gate: off' (global escape) ; OR a 'fix-ok:' marker on a diff line ; OR a
# 'fix-ok:' ALREADY PRESENT in the edited file's BODY (disarms that file — rationale written once, e.g. a comment).
# A RUN.md 'status: green' that NAMES the file RESETS its counter ONCE per green TRANSITION (verified work
# clears the debt; churn that CONTINUES past the green, without a new verification, re-accumulates and
# re-blocks). Two properties make this sound: the discipline is PER-FILE (a token in one run never disarms the
# gate for other files), and the reset is ONCE per transition (signature = count of GATE-VERIFIED lines,
# monotone, written by stop-gate) — not every edit, which would disarm the gate permanently for that file.
#
# Scope: code only (.ps1 .psm1 .cs .py .ts .js .xaml). THRESHOLD = 6: recalibrated from 4 because telemetry
# showed 0 true blind-fix over 8 blocks / 5 sessions (all legit feature/refactor/diag) — edit-count is a WEAK
# proxy that taxed legitimate iteration; 6 keeps the net for a real 10+ edit loop. Re-measure via gate-counters.jsonl.

$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }

$fp = [string]$j.tool_input.file_path
if (-not $fp) { exit 0 }
$ext = [System.IO.Path]::GetExtension($fp).ToLower()
if (-not (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js', '.xaml') -contains $ext)) { exit 0 }

# Explicit escape on the diff (like sleep-ok:)
$text = [string]$j.tool_input.content
if (-not $text) { $text = [string]$j.tool_input.new_string }
if ($text -match 'fix-ok:\s*\S') { exit 0 }   # Requires a NON-EMPTY justification (a bare '# fix-ok:' no longer disarms the gate)

$sid = [string]$j.session_id
if (-not $sid) { $sid = 'nosession' }
$base = [System.IO.Path]::GetFileName($fp)

# Discipline BOUND TO THE FILE (token in a RUN.md that NAMES this file, or global escape);
# + a green RUN naming this file RESETS the counter.
# Include the session folder derived from $j.cwd (provided by the harness),
# so both gates read the SAME session folder when cwd != $PWD.
$cwd = [string]$j.cwd
$roots = @()
if ($cwd -and (Test-Path $cwd)) { $roots += (Join-Path $cwd "Audit\workspaces\$sid") }
$roots += (Join-Path $PWD "Audit\workspaces\$sid")
# The project root 'C:\Code RIG\...' had been REMOVED for portability, but it was LOAD-BEARING:
# PreToolUse stdin does not always provide $cwd (unlike the Stop hook) -> without this root the
# discipline found NO RUN and blocked at >=6 with no possible disarm (observed this session).
# It is GUARDED by Test-Path below -> non-existent elsewhere = skipped, ZERO distribution impact.
# Real portability = harness provides cwd; until then, keep this fallback.
$roots += "Audit\workspaces\$sid"
# Dedupe (preserves order: cwd > $PWD > project)
$roots = $roots | Select-Object -Unique
$disciplined = $false
$greenForFile = $false
$greenVerifiedCount = 0
foreach ($r in $roots) {
    if (-not (Test-Path $r)) { continue }
    $runs = Get-ChildItem $r -Filter RUN.md -Recurse -EA SilentlyContinue
    foreach ($run in $runs) {
        $c = Get-Content $run.FullName -Raw -EA SilentlyContinue
        if (-not $c) { continue }
        $globalOff = ($c -match '(?im)^\s*fix-gate:\s*off\s*$')   # Anchored -> 'fix-gate: off' in prose no longer disarms
        $hasCause = ($c -match '(?im)^\s*CausalHypothesis:' -or $c -match '(?im)^\s*check:\s*\S')
        # The file must be named on a TOKEN LINE (CausalHypothesis/check/fix-file),
        # not anywhere in prose -> a passing mention in the Journal no longer disarms the gate.
        $namesFile = ($base -and ($c -match ('(?im)^\s*(CausalHypothesis|check|fix-file)\b[^\r\n]*' + [regex]::Escape($base))))
        if ($globalOff -or ($hasCause -and $namesFile)) { $disciplined = $true }
        # A green naming the file clears the debt ONCE per TRANSITION (not on every edit).
        # Transition signature = number of GATE-VERIFIED lines (monotone: stop-gate appends one per verified green).
        if ($namesFile -and ($c -match '(?im)^\s*status:\s*green')) {
            $greenForFile = $true
            $greenVerifiedCount += ([regex]::Matches($c, 'GATE-VERIFIED')).Count
        }
    }
}
$greenSig = $null
if ($greenForFile) { $greenSig = 'g' + $greenVerifiedCount }

# Per-file edit counter (session state in TEMP).
$stateFile = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-fixgate-$sid.json")
$state = @{}
if (Test-Path $stateFile) { try { (Get-Content $stateFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value } } catch { $state = @{} } }
$key = $fp.ToLower()
$sigKey = $key + '::greensig'
$count = [int]$state[$key] + 1
# Reset ONLY ONCE per green transition (different signature from the last cleared one),
# instead of resetting on EVERY edit (which would permanently disarm the gate for that file).
if ($greenSig -and ($greenSig -ne [string]$state[$sigKey])) { $count = 1; $state[$sigKey] = $greenSig }
$state[$key] = $count
try { ($state | ConvertTo-Json -Compress) | Set-Content -Path $stateFile -Encoding utf8 } catch { }

$THRESHOLD = 6   # recalibrated 4->6; see header comment
if ($disciplined -or $count -lt $THRESHOLD) { exit 0 }

# Body-level escape (kaizen 2026-06-22, gate-counters fix-gate x12): a `fix-ok:` justification ALREADY IN the
# edited file disarms the gate for THIS file. The author writes the rationale once (e.g. a comment), but it
# only rode in the diff of the edit that ADDED it; later edits elsewhere in the same file don't re-carry it and
# were re-blocked (lived: MosaicView.xaml:7 had a fix-ok: comment yet edits #8/#9/#10 still blocked). Read here
# only (we already passed the threshold -> gate would otherwise block -> no I/O on edits below threshold).
# Per-file ($fp only), NON-EMPTY token (same regex as the diff). Counter / RUN.md-cause / green-reset untouched
# -> a file with no token stays protected at THRESHOLD. Scope = file-lifetime within the session (consistent
# with the diff fix-ok: being explicit + hand-written; the per-work-item RUN.md path remains for renewed justification).
if ((Test-Path $fp) -and ((Get-Content $fp -Raw -EA SilentlyContinue) -match 'fix-ok:\s*\S')) { exit 0 }

# Out-of-model telemetry (like anti-flaky)
$counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
$entry = (@{ ts = (Get-Date -Format o); gate = 'fix-gate'; file = $fp; edits = $count; session = $sid } | ConvertTo-Json -Compress)
Add-Content -Path $counters -Value $entry -Encoding utf8

$reason = "FIX-GATE: edit #$count of '$([System.IO.Path]::GetFileName($fp))' this session with no cause BOUND TO THIS FILE = sign of a BLIND-FIX LOOP. STOP: reproduce the bug + RESEARCH the cause (ENGINE Ch.4; scout unblock mode) BEFORE re-coding. To unblock: in a session RUN.md that NAMES this file, add 'CausalHypothesis: <cause + source>' (or 'check:'), OR 'fix-ok: <justification>' on a diff line OR already present in the file body if it is a feature/refactor (not a blind fix), OR 'fix-gate: off'. A RUN 'status: green' naming the file resets the counter (once per verified green)."
@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $reason } } | ConvertTo-Json -Depth 5 -Compress
