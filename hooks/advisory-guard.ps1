# advisory-guard.ps1 — hook UserPromptSubmit (NON bloquant) : tarit a la source le reflexe "process > reponse".
# Kaizen 2026-06-17 (session 937321bc) : une question de conseil ou un signal de frustration a ete traite
# en pipeline (frame/RUN/QCM/judge 100-100) au lieu d'une reponse directe -> "j'ai rien compris" / "pue la merde".
# La fiche memoire feedback_advisory_question_vs_build_task existait DEJA et a ete violee 2x la meme session
# => il faut un DECLENCHEUR cable, pas une fiche passive. Ce hook injecte un rappel quand le prompt porte un
# signal advisory/frustration. Rappel SEULEMENT (additionalContext) : si c'est une vraie tache, Claude ignore.
# ASCII pur volontaire (PS5.1 lit ce fichier en ANSI sans BOM ; le PROMPT, lui, arrive en UTF-8 via ConvertFrom-Json).

$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$p = [string]$j.prompt
if (-not $p) { exit 0 }

# Mode pensee (prefixe ?) deja gere par un autre hook -> ne pas doubler.
if ($p.TrimStart().StartsWith('?')) { exit 0 }

# FRUSTRATION : coupe TOUJOURS la machinerie (CLAUDE.md) -> FIRE meme sur un prompt-tache, AVANT tout
# early-exit verbe d'action (fix regression boucle kaizen 2026-06-18 : l'early-exit verbe tuait la frustration).
$frustration = @('rien compris', 'pas compris', 'rien de plus', 'juste la ', 'trop long', 'trop compliqu', 'pue la merde', '\blol\b')
$isFrustration = $false
foreach ($s in $frustration) { if ($p -imatch $s) { $isFrustration = $true; break } }

if (-not $isFrustration) {
    # fix #1 : un prompt qui COMMENCE par un verbe d'action = TACHE de construction (pas une question conseil)
    # -> ne pas injecter le rappel pour les signaux AMBIGUS. ASCII-safe ('.' pour accents). (La frustration
    # ci-dessus a deja FIRE, donc elle n'est jamais coupee par cet early-exit.)
    if ($p.TrimStart() -imatch '^\s*(cr.?e|fais|ajoute|met|refactor|restructur|optimis|am.?lior|nettoi|migr|g.?n.?r|impl.?ment|code|.cris|corrig|applique|create|add|make|build|write|implement|fix|setup)\b') { exit 0 }
    # Signaux ADVISORY ambigus (question de conseil) : ne FIRE que HORS-tache.
    $advisory = @('meilleur', 'vaut.{0,4}mieux', 'quel choix', 'c.?est quoi', 'sert a quoi')
    $isAdvisory = $false
    foreach ($s in $advisory) { if ($p -imatch $s) { $isAdvisory = $true; break } }
    if (-not $isAdvisory) { exit 0 }
}

$msg = "SIGNAL ADVISORY/FRUSTRATION detecte dans le prompt. Reflexe kaizen : reponds DIRECT et court (utilisable " +
       "en 1 message) -- PAS de frame/RUN/QCM/pipeline/judge. Une question 'quelle est la meilleure X / vaut-il " +
       "mieux / c'est quoi' attend une REPONSE, pas un chantier. Une frustration ('rien compris / juste la reponse / " +
       "trop long') => simplifie, etapes numerotees si on demande une methodo, et verifie que tu reponds a la " +
       "question POSEE (pas a celle que tu aimerais). Le routing agressif vise les TACHES (fais/cree X). Si c'est " +
       "bien une tache de construction, ignore ce rappel."

@{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $msg } } | ConvertTo-Json -Depth 10 -Compress
