# thinking-mode.ps1 — UserPromptSubmit: a prompt prefixed with '?' = the user thinking out loud, NOT an
# order. Discuss/structure; launch NO Write/Edit/Agent tool and NO irreversible action until an explicit
# order WITHOUT the '?'. Extracted from inline (2026-06-18).
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$p = [string]$j.prompt
if ($p.TrimStart().StartsWith('?')) {
    @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = 'THINKING MODE (prefix ?): the user is thinking out loud. Discuss/structure; launch NO Write/Edit/Agent tool and NO irreversible action until they give an explicit order WITHOUT the ?.' } } | ConvertTo-Json -Depth 10 -Compress
}
