# build-cadence.ps1 — PostToolUse (Write|Edit|Bash|PowerShell): makes ENGINE Ch.4's "verify each increment"
# reflex FIRE during a build instead of being passively forgotten. Counts CODE edits since the last verify;
# every THRESHOLD edits with no verify (test/build/query) in between, NUDGES (non-blocking) to run the real
# signal or justify — and reminds the cross-skill triggers (stuck -> scout UNBLOCK ; reality != approach ->
# re-frame). NEVER blocks (that's stop-gate's job). A verify-like command resets the counter.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$sid = [string]$j.session_id
if (-not $sid) { exit 0 }
$tool = [string]$j.tool_name
$state = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-buildcadence-$sid.json")
$edits = 0
if (Test-Path $state) { try { $edits = [int]((Get-Content $state -Raw | ConvertFrom-Json).edits) } catch { $edits = 0 } }
$THRESHOLD = 5

# A verify-like command (test/build/query) RESETS the counter — the increment was verified.
$cmd = [string]$j.tool_input.command
# Narrowed to REAL test/build runners only (no false reset on 'git commit -m "make…"', 'npm run start', 'dotnet run' app-launch).
if ($cmd -match '(?i)(dotnet\s+(test|build)|pytest|npm\s+(test|run\s+(test|build|ci))|jest|go\s+test|cargo\s+test|msbuild|(^|[;&|]\s*)make(\s|$)|-File\s+\S*test|test-hooks)') {
    @{ edits = 0 } | ConvertTo-Json -Compress | Set-Content $state -Encoding utf8
    exit 0
}

# A CODE edit increments the counter (doc/.md/.json edits don't count).
if ($tool -eq 'Write' -or $tool -eq 'Edit') {
    $fp = [string]$j.tool_input.file_path
    if (-not $fp) { exit 0 }
    $ext = [System.IO.Path]::GetExtension($fp).ToLower()
    if (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js', '.xaml', '.sql') -notcontains $ext) { exit 0 }
    $edits++
    @{ edits = $edits } | ConvertTo-Json -Compress | Set-Content $state -Encoding utf8
    # Fire every THRESHOLD edits-without-verify (5, 10, 15…) — a persistent reminder, not a one-shot.
    if ($edits % $THRESHOLD -eq 0) {
        $msg = "BUILD CADENCE: $edits code edits, no verify since. Run the real signal now (test/build/screenshot/query) or justify. Stuck ~3x on one cause -> scout UNBLOCK. Reality != the approach -> re-frame. (Mechanics: ENGINE Ch.4.)"
        @{ hookSpecificOutput = @{ hookEventName = 'PostToolUse'; additionalContext = $msg } } | ConvertTo-Json -Depth 10 -Compress
    }
}
