# git-auth-gate.ps1 — enforces the kit's CARDINAL git rule: no `git commit` / `git push` without the
# user's authorization. SESSION class-auth model (kaizen 2026-06-19, session 7f4514bd): the user authorizes
# ONCE (says commit / push / pousse, or sets AUTOWIN_GIT_AUTH=1) and it holds for the SESSION
# ("push-as-you-go"); read-only git (status / log / diff / show / blame / ls-remote / fetch) is NEVER gated.
# Wired to BOTH events, routed by the input shape:
#   UserPromptSubmit -> a grant token in the prompt arms the session (writes the grant file ; silent).
#   PreToolUse (Bash|PowerShell) -> a `git commit`/`git push` is DENIED unless a grant exists.
# Safe DEFAULT = DENY (the cardinal rule). Escape: AUTOWIN_GIT_AUTH=1 (env, before launch) = standing grant.
# Known limits (accepted — kit philosophy = guardrail, not a sandbox; the human is the final net):
#   (a) a model in bypass mode could forge the grant file directly (like writing `gate: off`) = a DELIBERATE
#       circumvention, not an accident ; (b) an exotic negation the guard misses could arm the grant — but
#       deny-by-default still requires the model to explicitly push ; (c) a read-only git whose ARGS contain
#       'commit'/'push' (e.g. `git log --grep=push`) is over-blocked (safe-direction: grant once, re-run) ;
#   (d) subshell / grouping / variable-alias forms (`$(git push)`, `(git push)`, `g=git; $g push`) evade the
#       regex = same DELIBERATE-circumvention class as (a) — out of scope, the human is the net.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$sid = [string]$j.session_id
$grant = if ($sid) { Join-Path ([System.IO.Path]::GetTempPath()) ("claude-gitauth-$sid.flag") } else { '' }

# Env escape = a standing session authorization (like AUTOWIN_AUTONOMY).
$envAuth = (([string]$env:AUTOWIN_GIT_AUTH).Trim() -match '^(1|on|true|yes)$')

# --- UserPromptSubmit branch: a grant token in the user's prompt arms the session ---
if ($j.PSObject.Properties.Name -contains 'prompt') {
    $p = [string]$j.prompt
    # Skip arming on a NEGATED authorization ("ne push pas" / "don't push" / "jamais commit" / "pas de push").
    $neg = $p -match '(?i)(ne\s+\w*\s*(push|commit|committe|pousse)|(push|commit|committe|pousse)\s+(pas|jamais)|don.?t\s+(push|commit)|do\s+not\s+(push|commit)|jamais\s+(de\s+)?(push|commit|pousse)|pas\s+(de\s+)?(push|commit|pousse)|no\s+(push|commit))'
    if ($grant -and (-not $neg) -and ($p -match '(?i)\b(commit|committe|commite|push|pushe|pousse|poussez|pousser)\b' -or $p -match '(?i)(push as you go|au fil de l|a chaque etape|à chaque étape)')) {
        New-Item -ItemType File -Path $grant -Force | Out-Null
    }
    exit 0
}

# --- PreToolUse branch: gate WRITE git ops only ---
$cmd = [string]$j.tool_input.command
if (-not $cmd) { exit 0 }
# git as the COMMAND of a segment (line start incl. multi-line, or after ; && || newline), optionally
# env-prefixed (VAR=val git ...), with commit/push later in that segment. Catches `git push`, `git commit`,
# `git -C dir push`, `cd x && git push`, `git status\ngit push` (newline), `GIT_DIR=. git push` (env-prefix) ;
# ignores `echo "git push"` (quoted, not a segment start). Over-blocks read-only git with commit/push in ARGS (safe).
if ($cmd -match '(?im)(^\s*|[;&|\n]\s*)(\w+=\S+\s+)*git\b[^;&|\n]*\b(commit|push)\b') {
    $granted = $envAuth -or ($grant -and (Test-Path $grant))
    if (-not $granted) {
        $reason = "GIT-AUTH-GATE : pas d'autorisation git cette session. Regle cardinale : pas de commit/push sans accord. L'utilisateur autorise UNE fois (dire commit/push/pousse, ou AUTOWIN_GIT_AUTH=1) -> tient pour la session. Demande l'accord AVANT de committer/pousser."
        @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $reason } } | ConvertTo-Json -Depth 10 -Compress
    }
}
exit 0
