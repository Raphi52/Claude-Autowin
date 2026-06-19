# advisory-guard.ps1 — UserPromptSubmit (NON-blocking): dries up the "process > answer" reflex at the source.
# Root cause: an advisory question or a frustration signal was handled as a pipeline (frame/RUN/QCM/judge)
# instead of a direct answer -> "I didn't understand anything". A passive memory note alone was violated 2x
# the same session => a WIRED trigger is needed. This hook injects a reminder when the prompt carries an
# advisory/frustration signal. Reminder ONLY (additionalContext): if it is a real task, Claude ignores it.
# Deliberately pure ASCII (PS5.1 reads this file as ANSI without a BOM; the PROMPT arrives as UTF-8 via ConvertFrom-Json).

$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$p = [string]$j.prompt
if (-not $p) { exit 0 }

# Thinking mode (prefix ?) already handled by another hook -> don't double it.
if ($p.TrimStart().StartsWith('?')) { exit 0 }

# FRUSTRATION: ALWAYS cuts the machinery (CLAUDE.md) -> FIRE even on a task-prompt, BEFORE the action-verb
# early-exit (the verb early-exit used to swallow frustration).
$frustration = @('rien compris', 'pas compris', 'rien de plus', 'juste la ', 'trop long', 'trop compliqu', 'pue la merde', '\blol\b')
$isFrustration = $false
foreach ($s in $frustration) { if ($p -imatch $s) { $isFrustration = $true; break } }

if (-not $isFrustration) {
    # A prompt that STARTS with an action verb = a build TASK (not an advisory question) -> don't inject the
    # reminder for AMBIGUOUS signals. ASCII-safe ('.' for accents). (Frustration above already FIRED, so it is
    # never cut by this early-exit.)
    if ($p.TrimStart() -imatch '^\s*(cr.?e|fais|ajoute|met|refactor|restructur|optimis|am.?lior|nettoi|migr|g.?n.?r|impl.?ment|code|.cris|corrig|applique|create|add|make|build|write|implement|fix|setup)\b') { exit 0 }
    # Ambiguous ADVISORY signals (advisory question): FIRE only OUTSIDE a task.
    $advisory = @('meilleur', 'vaut.{0,4}mieux', 'quel choix', 'c.?est quoi', 'sert a quoi')
    $isAdvisory = $false
    foreach ($s in $advisory) { if ($p -imatch $s) { $isAdvisory = $true; break } }
    if (-not $isAdvisory) { exit 0 }
}

$msg = "ADVISORY/FRUSTRATION signal detected in the prompt. Kaizen reflex: answer DIRECTLY and short (usable " +
       "in 1 message) -- NO frame/RUN/QCM/pipeline/judge. A question 'which is the best X / is it better to / " +
       "what is X' expects an ANSWER, not a project. A frustration ('didn't understand / just the answer / " +
       "too long') => simplify, numbered steps if a method is requested, and check you answer the question " +
       "ASKED (not the one you wish). Aggressive routing targets TASKS (do/create X). If it really is a build " +
       "task, ignore this reminder."

@{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $msg } } | ConvertTo-Json -Depth 10 -Compress
