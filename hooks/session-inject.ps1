# session-inject.ps1 — UserPromptSubmit: inject SESSION_ID into context (the basis of stop-gate v3.2
# per-session scoping). Extracted from inline (2026-06-18). PURE ECHO of the stdin session_id — it does NOT
# generate the id, so extraction is side-effect-free.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$sid = [string]$j.session_id
if ($sid) {
    @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = ('SESSION_ID=' + $sid + '. To isolate concurrent sessions: write every RUN.md under Audit\workspaces\' + $sid + '\<subject>-workspace\RUN.md (the Stop-gate v3.2 only enforces runs of this session).') } } | ConvertTo-Json -Depth 10 -Compress
}
