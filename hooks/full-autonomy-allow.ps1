# full-autonomy-allow.ps1 — PreToolUse hook (matcher "*"): PERMISSION-level full-autonomy toggle.
# When ON (env AUTOWIN_AUTONOMY in 1/on/true/yes, OR sentinel ~/.claude/autonomy.on), auto-approves EVERY
# tool call (permissionDecision allow) so users WITHOUT defaultMode=bypassPermissions get full autonomy.
# NOTE: redundant on a machine already running defaultMode=bypassPermissions (no prompt left to bypass).
# OFF by default -> emits nothing (normal permission flow). Fail-safe: unreadable stdin -> nothing (NEVER
# auto-approve on garbage). Safety net intact: deny > allow and ALL PreToolUse hooks run, so anti-flaky /
# fix-gate still BLOCK their cases; settings.json deny/ask permission RULES still override this allow.
# WARNING: when ON this grants destructive Bash (rm -rf, git push, prod, network egress) UNLESS a deny rule
# or hook catches it — the kit only denies Write|Edit cases. Keep deny/ask rules in settings.json as the
# hard stop for the dangerous Bash surface. See SECURITY.md.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$on = ($env:AUTOWIN_AUTONOMY -match '^(1|on|true|yes)$') -or (Test-Path (Join-Path $env:USERPROFILE '.claude\autonomy.on'))
if (-not $on) { exit 0 }
@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'allow'; permissionDecisionReason = 'AUTOWIN full-autonomy: auto-approved (deny-gates + deny/ask rules still apply; deny > allow).' } } | ConvertTo-Json -Depth 10 -Compress
