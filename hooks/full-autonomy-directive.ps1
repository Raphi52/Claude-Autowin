# full-autonomy-directive.ps1 — UserPromptSubmit hook: BEHAVIORAL full-autonomy toggle.
# When ON (env AUTOWIN_AUTONOMY in 1/on/true/yes, OR sentinel ~/.claude/autonomy.on exists), injects a
# directive telling Claude to STOP asking the user and drive each task to completion. Permission prompts are
# handled separately (native bypassPermissions / full-autonomy-allow.ps1); this hook only changes BEHAVIOR.
# OFF by default (no env, no sentinel) -> emits nothing. Fail-safe: unreadable stdin -> nothing.
# Safety net is unaffected: anti-flaky / fix-gate (deny > allow) and the Stop-gate still fire; closure still
# requires a verified out-of-model artifact. Defers to thinking-mode: a '?'-prefixed prompt -> no directive.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$p = [string]$j.prompt
if ($p.TrimStart().StartsWith('?')) { exit 0 }   # thinking mode owns this turn
$on = ($env:AUTOWIN_AUTONOMY -match '^(1|on|true|yes)$') -or (Test-Path (Join-Path $env:USERPROFILE '.claude\autonomy.on'))
if (-not $on) { exit 0 }
$msg = 'FULL-AUTONOMY MODE is ON. Do NOT ask the user questions (no AskUserQuestion / QCM) — auto-decide via the board-gate at maximum aggression: answer every evident point yourself as a STATED ASSUMPTION and proceed. Drive each task to completion without stopping to confirm intermediate steps. Surface to the human ONLY: a destructive/irreversible action, something out of the requested scope, or a genuine external blocker. When blocked, spawn parallel resolver sub-agents BEFORE interrupting. The safety net still applies (anti-flaky, fix-gate, Stop-gate) — closure still requires a verified out-of-model artifact; never disguise a self-declared green.'
@{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $msg } } | ConvertTo-Json -Depth 10 -Compress
