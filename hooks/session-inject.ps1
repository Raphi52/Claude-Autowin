# session-inject.ps1 — UserPromptSubmit: inject SESSION_ID into context (the basis of stop-gate v3.2
# per-session scoping). PURE ECHO of the stdin session_id — it does NOT generate the id.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$sid = [string]$j.session_id
if ($sid) {
    # Workspaces root: default 'Audit\workspaces' (per-project, portable). A machine MAY relocate it out of the
    # project tree via env AUTOWIN_RUN_ROOT; the injected instruction follows that override so RUN.md land there.
    $wsRoot = if ($env:AUTOWIN_RUN_ROOT -and $env:AUTOWIN_RUN_ROOT.Trim()) { $env:AUTOWIN_RUN_ROOT.Trim() } else { 'Audit\workspaces' }
    @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = ('SESSION_ID=' + $sid + '. To isolate concurrent sessions: write every RUN.md under ' + $wsRoot + '\' + $sid + '\<subject>-workspace\RUN.md (the Stop-gate v3.2 only enforces runs of this session).') } } | ConvertTo-Json -Depth 10 -Compress
}
