# stop-gate.ps1 — Stop hook: closure authority lives OUTSIDE the model. A "green" is not believed, it is VERIFIED.
#
# RUN.md header convention (machine-parseable, first lines; full spec: _engine/ENGINE.md ch.3):
#   status: open | green | red | degraded-closed   |   regime: disposable | standard | critical
#   signal: <artifact proving green>   |   signal-cmd: <idempotent cmd the gate REPLAYS (whitelisted launchers)>
#   check: <cmd(s) replayed as promoted lessons>   |   gate: off  (justified opt-out)
#   session: <id> — SCOPE: this run is enforced ONLY for session <id> (by header, or by placement under
#                   Audit\workspaces\<id>\). No session id in stdin => LEGACY: scan + enforce everything (never disarm).
# Sections read: "## Options" (lines with "score:"), the "Décision:" line, "check: <cmd>" lines.
#
# Rules:
#   open|red -> BLOCK.  degraded-closed -> pass (USER-OK, honor-bound, verified by the review).
#   green -> VERIFIED once per transition. A "[ts] GATE-VERIFIED" marker only counts if POSTERIOR to the last
#     "[ts] unit=" Journal event (a run re-opened after the marker is RE-verified). Verification:
#     (a) replay signal-cmd if whitelisted -> exit != 0 = BLOCK ; cap GATE_REPLAY_TIMEOUT_MS (default 120000 ms) -> kill tree + BLOCK ;
#     (b) run each "check: <cmd>" (lessons promoted to code) -> exit != 0 = BLOCK (same cap) ;
#     (c) anti-fixation: an engaged Décision with <3 anchored scored options ("- ... score: N", not prose) + regime != disposable -> BLOCK.
#     Success -> append "[ts] GATE-VERIFIED" (later passes don't replay).
#   stop_hook_active -> pass (anti-loop).
#
# Security (a RUN.md is executable input): commands are REPLAYED only for runs OWNED by this session (under
#   <id>\ or header session: == my id); a foreign/cloned RUN.md never triggers a replay (RCE-by-clone closed).
#   Trusted single host opt-in: env AUTOWIN_TRUST_REPLAY=1. The open/red BLOCK stays active even for non-owned runs.
# Fail-closed: unreadable or non-object stdin (null / scalar / array) -> BLOCK (a valid scalar JSON used to escape this).
# Honest limit: an absent/non-whitelisted signal-cmd leaves green on self-proof (fresh artifact) — the residue
#   stays VISIBLE via artifact_based in the review, never disguised.

$ErrorActionPreference = 'SilentlyContinue'
$raw = ''
try { $raw = [Console]::In.ReadToEnd() } catch { $raw = '' }
try { $j = $raw | ConvertFrom-Json } catch { $j = $null }
# Closure authority does NOT fail-OPEN on unreadable or non-object stdin.
# A NON-EMPTY payload that is not a JSON object (null, scalar 0/"x", array []) -> fail-CLOSED (block).
# Empty stdin = not a real event -> exit 0. (Closes the bypass: a valid JSON scalar used to escape fail-closed.)
if ($null -eq $j -or ($j -isnot [System.Management.Automation.PSCustomObject])) {
    if ($raw.Trim()) { @{ decision = 'block'; reason = 'STOP-GATE: unreadable or non-object stdin (malformed JSON / scalar) -- fail-closed.' } | ConvertTo-Json -Compress }
    exit 0
}
if ($j.stop_hook_active) { exit 0 }

$cwd = [string]$j.cwd
if (-not $cwd -or -not (Test-Path $cwd)) { exit 0 }
# Anchor replays/checks on the session cwd (kaizen 2026-06-23, gate-counters stop x2): Invoke-GateCmd otherwise
# inherits an UNDEFINED cwd, so a RELATIVE check:/signal-cmd (e.g. `node tools/smoke.mjs`) was a latent false-BLOCK.
# $cwd is already Test-Path-validated above. (Cross-project RUN-vs-target stays a convention matter: absolute paths.)
$script:gateCwd = $cwd

$replayWhitelist = @('dotnet test', 'dotnet build', 'cmd /c', 'powershell -NoProfile -File', 'powershell -File', 'pwsh -NoProfile -File', 'pwsh -File')

# Execution cap for replays/checks — a hanging signal-cmd must not freeze the session
$replayTimeoutMs = 120000
if ($env:GATE_REPLAY_TIMEOUT_MS -match '^\d+$') { $replayTimeoutMs = [int]$env:GATE_REPLAY_TIMEOUT_MS }

function Invoke-GateCmd([string]$c) {
    # >NUL in the cmd line: no stream to drain (anti-deadlock buffer), zero pollution of the hook's stdout
    $psi = New-Object System.Diagnostics.ProcessStartInfo('cmd.exe', ('/c ' + $c + ' >NUL 2>&1'))
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    # Anchor on the session cwd (kaizen 2026-06-23) -> a relative-path replay no longer false-BLOCKs from an
    # undefined inherited cwd. An ABSOLUTE path stays cwd-insensitive; a real failure still returns its non-zero exit.
    if ($script:gateCwd) { $psi.WorkingDirectory = $script:gateCwd }
    $p = [System.Diagnostics.Process]::Start($psi)
    if (-not $p) { return 125 }
    if (-not $p.WaitForExit($script:replayTimeoutMs)) {
        cmd.exe /c ('taskkill /PID ' + $p.Id + ' /T /F') | Out-Null
        return 124
    }
    return $p.ExitCode
}

# A PROOF must invoke a real test/build runner OR a SCRIPT (.ps1/.cmd/.bat/.py/.js).
# The emptiness denylist leaked (cmd /c "exit 0" / call / wrapping) -> we require the positive allowlist.
# Used for (a) signal-cmd AND (d) CRITICAL proof + check: lines.
$script:proofRunners = @('dotnet test', 'dotnet build', 'dotnet run', 'pytest', 'npm test', 'npm run', 'jest', 'go test', 'cargo test', 'msbuild', 'make ')
function Test-MeaningfulProof([string]$c) {
    if (-not $c) { return $false }
    # Tolerates 'cmd.exe' + optional space around /c; normalizes internal spaces
    # (a double-space 'dotnet  test' no longer breaks the runner match).
    $e = ($c -replace '(?i)^\s*cmd(\.exe)?\s*/c\s*', '').Trim().Trim('"').Trim()
    $e = ($e -replace '\s+', ' ')
    if ($e -match '(?i)(^|\s)-File\s+\S+\.(ps1|cmd|bat)(\b|$)') { return $true }
    if ($e -match '(?i)\.(ps1|cmd|bat|py|js)(\s|$)') { return $true }
    foreach ($r in $script:proofRunners) { if ($e -match ('(?i)^' + [regex]::Escape($r))) { return $true } }
    return $false
}

# SESSION SCOPE. Add the session root Audit\workspaces\<session_id>\ to scanned roots
# (its runs are "mine" by placement); cwd + Audit\workspaces top-level remain scanned but are
# filtered by ownership in the loop (header session: == my id). Legacy fallback if session_id absent.
$sid = [string]$j.session_id
$central = Join-Path $cwd 'Audit\workspaces'
$roots = @($cwd)
if (Test-Path $central) { $roots += $central }
if ($sid) { $sessionRoot = Join-Path $central $sid; if (Test-Path $sessionRoot) { $roots += $sessionRoot } }
$wsDirs = @()
foreach ($r in $roots) {
    $wsDirs += Get-ChildItem -Path $r -Directory -Filter '*-workspace' -ErrorAction SilentlyContinue
}
$wsDirs = @($wsDirs | Sort-Object FullName -Unique)

$bad = @()
foreach ($d in $wsDirs) {
    $run = Join-Path $d.FullName 'RUN.md'
    if (-not (Test-Path $run)) { continue }
    $all = @(Get-Content $run -Encoding UTF8 -ErrorAction SilentlyContinue)
    if (-not $all) { continue }
    $head = $all | Select-Object -First 14
    # 'gate: off' disarms the gate. Tolerate a TRAILING HTML COMMENT (the natural justified-opt-out form,
    # e.g. 'gate: off <!-- why -->') but NOT arbitrary junk ('gate: off blah' / 'gate: offset' still enforce).
    if (($head | Where-Object { $_ -match '^\s*gate:\s*off\s*(<!--.*)?$' })) { continue }
    # Enforce ONLY runs of THIS session: mine if under Audit\workspaces\<my id>\ OR header
    # "session: <my id>". Otherwise (other session / legacy unstamped) => IGNORE. Fallback: no session_id => legacy.
    $owned = $false
    if ($sid) {
        $underMySession = ($d.FullName -like ('*\Audit\workspaces\' + $sid + '\*'))
        $sessLine = $head | Where-Object { $_ -match '^\s*session:\s*\S' } | Select-Object -First 1
        $runSession = if ($sessLine) { ($sessLine -replace '^\s*session:\s*', '').Trim() } else { '' }
        $owned = ($underMySession -or ($runSession -and $runSession -eq $sid))
        if (-not $owned) { continue }
    }
    # SECURITY: replay (signal-cmd/check execution) ONLY for runs of THIS session (owned). In legacy (no sid)
    # => owned=false => NO replay: a cloned/foreign RUN.md no longer executes commands on the victim machine.
    # Single trusted host opt-in: env AUTOWIN_TRUST_REPLAY=1.
    # (The open/red block remains active even when not owned: closure security is not disarmed, only replay is.)
    $mayReplay = ($owned -or ($env:AUTOWIN_TRUST_REPLAY -eq '1'))
    $statusLine = $head | Where-Object { $_ -match '^\s*status:' } | Select-Object -First 1
    if (-not $statusLine) { continue }
    $status = ($statusLine -replace '^\s*status:\s*', '').Trim().ToLower()

    if ($status -eq 'open' -or $status -eq 'red') {
        $bad += ($d.Name + ' (status: ' + $status + ')')
        continue
    }
    if ($status -ne 'green') { continue }

    # GREEN: verify once per transition. The marker only counts if it is POSTERIOR to the last
    # work event — a "unit=" event after the marker means the run was re-opened -> re-verify.
    $lastVerified = -1; $lastEvent = -1
    for ($i = 0; $i -lt $all.Count; $i++) {
        # marker = the ENTIRE line "[ts] GATE-VERIFIED" (as appended by this hook) — a Journal line that
        # merely MENTIONS the word in prose is not a marker
        if ($all[$i] -match '^\s*\[[^\]]*\]\s*GATE-VERIFIED\s*$') { $lastVerified = $i }
        elseif ($all[$i] -match '^\s*\[[^\]]*\]\s*unit=') { $lastEvent = $i }
    }
    if ($lastVerified -gt $lastEvent) { continue }

    $regimeLine = $head | Where-Object { $_ -match '^\s*regime:' } | Select-Object -First 1
    $regime = if ($regimeLine) { ($regimeLine -replace '^\s*regime:\s*', '').Trim().ToLower() } else { 'standard' }
    $failures = @()

    # (a) REPLAY signal-cmd (standard/critical regimes, whitelisted prefix)
    if ($regime -ne 'disposable') {
        $cmdLine = $head | Where-Object { $_ -match '^\s*signal-cmd:' } | Select-Object -First 1
        if ($cmdLine) {
            $cmd = ($cmdLine -replace '^\s*signal-cmd:\s*', '').Trim()
            # A present signal-cmd must PROVE (runner/script);
            # otherwise (cmd /c exit 0, "exit 0", call exit 0, echo...) = proves nothing -> BLOCK (non-disposable).
            if (-not (Test-MeaningfulProof $cmd)) {
                $failures += ('signal-cmd ne PROUVE rien (ni runner test/build ni script .ps1/.bat/.cmd/.py/.js) : ' + $cmd)
            }
            $white = $false
            $cmdN = ($cmd -replace '\s+', ' ')   # double-space ('dotnet  test') no longer misses the whitelist
            foreach ($p in $replayWhitelist) { if ($cmdN -match ('(?i)^' + [regex]::Escape($p) + '(\s|$)')) { $white = $true; break } }   # word-boundary -> 'dotnet testxyz' no longer matches
            if ($white -and $mayReplay) {
                $rc = Invoke-GateCmd $cmd
                if ($rc -ne 0) {
                    $tag = ''
                    if ($rc -eq 124) { $tag = ' TIMEOUT>' + $replayTimeoutMs + 'ms' }
                    $failures += ('REJEU signal-cmd ECHOUE (exit ' + $rc + $tag + '): ' + $cmd)
                }
            }
        }
    }

    # (b) CHECKS (lessons promoted to code) — EXECUTED only when replay is authorized (a check from a
    # non-owned/legacy RUN is NOT executed -> RCE-by-clone closed; presence still matters for (d) critical).
    $checkLines = $all | Where-Object { $_ -match '^\s*check:\s*\S' }
    if ($mayReplay) {
        foreach ($cl in $checkLines) {
            $c = ($cl -replace '^\s*check:\s*', '').Trim()
            $rc = Invoke-GateCmd $c
            if ($rc -ne 0) {
                $tag = ''
                if ($rc -eq 124) { $tag = ' TIMEOUT>' + $replayTimeoutMs + 'ms' }
                $failures += ('CHECK ECHOUE (exit ' + $rc + $tag + '): ' + $c)
            }
        }
    }

    # (c) ANTI-FIXATION: decision committed with fewer than 3 scored options (non-disposable)
    if ($regime -ne 'disposable') {
        # Pattern avoids non-ASCII (PS5.1 reads this file as ANSI without BOM): covers Decision / Décision / mojibake
        # A scaffold PLACEHOLDER (value starting with '<', e.g. "Décision: <which and why>") does NOT count —
        # only a TRULY committed decision arms the anti-fixation check.
        # Prevents false-BLOCK on a single-default fix that kept the template scaffold.
        $hasDecision = ($all | Where-Object { $_ -match '^\s*D\S{0,2}cision\s*:\s*[^<\s]' })
        if ($hasDecision) {
            # Anchor — only OPTION lines count ("- ... score: 78"), not prose
            $optCount = @($all | Where-Object { $_ -match '^\s*([-*]|\d+[.)]).*\bscore\s*:\s*\d' }).Count
            if ($optCount -lt 3) { $failures += ('ANTI-FIXATION: decision engagee avec ' + $optCount + ' option(s) scoree(s) (<3)') }
        }
    }

    # (d) CRITICAL = out-of-model proof MANDATORY. Without a whitelisted signal-cmd NOR check: NOR
    # signal-attestable: header -> a critical green self-certifies (false-green on an irreversible regime,
    # against ENGINE Ch.2). We BLOCK; the human adds a signal or closes as degraded-closed.
    if ($regime -eq 'critical') {
        $cmdL2 = $head | Where-Object { $_ -match '^\s*signal-cmd:' } | Select-Object -First 1
        $cmdMeaningful = $false
        if ($cmdL2) { $cc2 = ($cmdL2 -replace '^\s*signal-cmd:\s*', '').Trim(); $cmdMeaningful = (Test-MeaningfulProof $cc2) }
        # A check only counts as CRITICAL proof if it is MEANINGFUL
        # (a vacuous 'check: cmd /c exit 0' no longer certifies a critical green).
        $hasMeaningfulCheck = $false
        foreach ($cl in $checkLines) { if (Test-MeaningfulProof (($cl -replace '^\s*check:\s*', '').Trim())) { $hasMeaningfulCheck = $true; break } }
        $hasAttest = [bool]($head | Where-Object { $_ -match '^\s*signal-attestable:\s*\S' })
        if (-not ($cmdMeaningful -or $hasMeaningfulCheck -or $hasAttest)) {
            $failures += 'CRITICAL without MEANINGFUL out-of-model proof (signal-cmd/check = test/build runner or script, or signal-attestable: required)'
        }
    }

    # (e) DoD CHECKLIST (non-disposable): a REAL-CONTENT unchecked box "- [ ]" inside ## Besoin = an unmet
    # exit condition -> BLOCK. DETERMINISTIC and BOX-STATE ONLY (the gate cannot read the PROOF behind a
    # checked box -> that stays judge+human). Scoped to ## Besoin (the DoD's home). A PLACEHOLDER box
    # ("- [ ] <...>", value starting with '<') does NOT count (mirror anti-fixation) -> no false-block on an
    # unfilled scaffold. Legacy RUN with a prose criterion (no boxes) = nothing to match -> passes. ASCII-only.
    if ($regime -ne 'disposable') {
        $inBesoin = $false
        foreach ($ln in $all) {
            if ($ln -match '^\s*##\s+Besoin\b') { $inBesoin = $true; continue }
            if ($inBesoin -and $ln -match '^\s*##\s') { $inBesoin = $false }
            if ($inBesoin -and $ln -match '^\s*[-*+]\s*\[\s*\]\s*[^<\s]') {
                $failures += ('DoD item NON TENU (case non cochee) dans ## Besoin: ' + $ln.Trim())
            }
        }
    }

    if ($failures.Count -gt 0) {
        $bad += ($d.Name + ' (green NON VERIFIE -> ' + ($failures -join ' ; ') + ')')
    } else {
        $stamp = '[' + (Get-Date -Format 'yyyy-MM-dd HH:mm') + '] GATE-VERIFIED'
        # If RUN.md does not end with a newline, Add-Content GLUES the tag to the last line ->
        # the marker (anchor ^...$) is no longer recognized on the next pass. Prefix a newline if needed.
        $rawRun = ''; try { $rawRun = [IO.File]::ReadAllText($run) } catch { }
        $lead = if ($rawRun.Length -gt 0 -and $rawRun[-1] -ne "`n") { "`r`n" } else { '' }
        Add-Content -Path $run -Value ($lead + $stamp) -Encoding utf8
    }
}

if ($bad.Count -eq 0) { exit 0 }

$counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
# Attributable telemetry — which run blocked and why, not just a counter; + session => correct cross-session attribution for kaizen-detect
$entry = (@{ ts = (Get-Date -Format o); gate = 'stop'; blocked = $bad.Count; session = $sid; file = (($bad[0] -split ' \(')[0]); details = $bad } | ConvertTo-Json -Compress)
Add-Content -Path $counters -Value $entry -Encoding utf8

$reason = 'STOP-GATE: ' + ($bad -join ' | ') + '. A done without a VERIFIED green does not pass. Options: (1) fix then really re-verify the signal; (2) keep working; (3) close honestly as degraded-closed with USER-OK traced in the Journal. NEVER disguise a status.'
@{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress
