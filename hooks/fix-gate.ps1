# fix-gate.ps1 — hook PreToolUse (Write|Edit) : tarit le BLIND-FIX LOOP a la SOURCE.
# Lecon de la session 2026-06-16 : un skill "fixer" PASSIF n'est jamais invoque ; seul un GATE change le
# comportement (structure > skill, cf. constitution). Ce gate enforce la discipline que le skill decrivait :
#   "avant le Ne fix a l'aveugle sur une cause inconnue -> REPRODUIS + RECHERCHE la cause d'abord".
#
# Regle (v2, 2026-06-18) : a partir de la 4e edition d'un MEME fichier de code dans la session, on BLOQUE
# -- SAUF si la discipline est LIEE A CE FICHIER : un RUN.md de la session qui NOMME le fichier ET porte une
# ligne 'CausalHypothesis:' (cause + source) ou 'check:' ; OU 'fix-gate: off' (escape GLOBAL) ; OU le marqueur
# 'fix-ok:' sur une ligne du diff. De plus, un RUN.md 'status: green' qui NOMME le fichier RESET son compteur
# UNE FOIS par TRANSITION de green (le travail verifie solde la dette ; un churn qui CONTINUE apres le green,
# sans nouvelle verif, re-accumule et re-bloque).
# v2 corrige 2 bugs (trouves par la boucle kaizen + reproduits live) :
#   (a) desarmement GLOBAL : avant, UN token dans N'IMPORTE quel RUN desarmait le gate pour TOUS les fichiers.
#   (b) compteur jamais RESET : le commentaire pretendait que l'iteration de feature etait epargnee via un
#       signal VERIFIED, mais le code ne le lisait jamais -> faux-positif sur une vraie feature.
# v2.1 (2026-06-18, fix #3 boucle kaizen) : le reset-sur-green etait INCONDITIONNEL (a chaque edit) -> il
#   desarmait le gate EN PERMANENCE pour ce fichier (blind-fix loop APRES un green jamais rattrape). Corrige :
#   reset UNE FOIS par transition (signature = nb de lignes GATE-VERIFIED, monotone, ecrites par stop-gate).
# Ne s'applique qu'au code (.ps1 .psm1 .cs .py .ts .js .xaml). Seuil >5 (recalibre 2026-06-18, cf. THRESHOLD).
# v2.2 (2026-06-18, audit kaizen Mode B) : seuil 4->6. Telemetrie = 0 vrai blind-fix sur 8 blocages / 5 sessions
#   (tous = feature/refactor/diag legitime, cause connue, obtempere) -> le cumul d'edits est un proxy FAIBLE qui
#   taxe l'iteration. 6 garde le filet (un loop 10+ edits bloque encore) ; re-mesurer via gate-counters.jsonl.

$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }

$fp = [string]$j.tool_input.file_path
if (-not $fp) { exit 0 }
$ext = [System.IO.Path]::GetExtension($fp).ToLower()
if (-not (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js', '.xaml') -contains $ext)) { exit 0 }

# Echappe explicite sur le diff (comme sleep-ok:)
$text = [string]$j.tool_input.content
if (-not $text) { $text = [string]$j.tool_input.new_string }
if ($text -match 'fix-ok:\s*\S') { exit 0 }   # fix (failles scout 2026-06-18) : exige une justif NON VIDE (un '# fix-ok:' nu ne desarme plus)

$sid = [string]$j.session_id
if (-not $sid) { $sid = 'nosession' }
$base = [System.IO.Path]::GetFileName($fp)

# v2 : discipline LIEE AU FICHIER (token dans un RUN.md qui NOMME ce fichier, ou escape global) ;
#      + un RUN green nommant ce fichier RESET le compteur.
# fix #5 (2026-06-18) : inclure le dossier de session derive de $j.cwd (fourni par le harnais),
# comme stop-gate.ps1:36, afin que les deux gardes lisent le MEME dossier de session quand cwd != $PWD.
$cwd = [string]$j.cwd
$roots = @()
if ($cwd -and (Test-Path $cwd)) { $roots += (Join-Path $cwd "Audit\workspaces\$sid") }
$roots += (Join-Path $PWD "Audit\workspaces\$sid")
# fix (failles scout 2026-06-18) : root machine-specifique 'C:\Code RIG\...' RETIRE (survivait casse a la
# portabilisation -> resolvait faux hors machine auteur ; relatif joint a $PWD, pas au cwd du harnais).
# Dedupe (conserve l'ordre : cwd > $PWD)
$roots = $roots | Select-Object -Unique
$disciplined = $false
$greenForFile = $false
$greenVerifiedCount = 0
foreach ($r in $roots) {
    if (-not (Test-Path $r)) { continue }
    $runs = Get-ChildItem $r -Filter RUN.md -Recurse -EA SilentlyContinue
    foreach ($run in $runs) {
        $c = Get-Content $run.FullName -Raw -EA SilentlyContinue
        if (-not $c) { continue }
        $globalOff = ($c -match '(?im)fix-gate:\s*off')
        $hasCause = ($c -match '(?im)^\s*CausalHypothesis:' -or $c -match '(?im)^\s*check:\s*\S')
        # fix (failles scout 2026-06-18) : le fichier doit etre nomme sur une LIGNE-TOKEN (CausalHypothesis/
        # check/fix-file), pas n'importe ou en prose -> une mention de passage dans le Journal ne desarme plus.
        $namesFile = ($base -and ($c -match ('(?im)^\s*(CausalHypothesis|check|fix-file)\b[^\r\n]*' + [regex]::Escape($base))))
        if ($globalOff -or ($hasCause -and $namesFile)) { $disciplined = $true }
        # v2.1 (fix #3) : un green nommant le fichier solde la dette UNE FOIS par TRANSITION (pas a chaque edit).
        # Signature de transition = nb de lignes GATE-VERIFIED (monotone : stop-gate en ajoute une par green verifie).
        if ($namesFile -and ($c -match '(?im)^\s*status:\s*green')) {
            $greenForFile = $true
            $greenVerifiedCount += ([regex]::Matches($c, 'GATE-VERIFIED')).Count
        }
    }
}
$greenSig = $null
if ($greenForFile) { $greenSig = 'g' + $greenVerifiedCount }

# Compteur d'editions par fichier (etat session dans TEMP).
$stateFile = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-fixgate-$sid.json")
$state = @{}
if (Test-Path $stateFile) { try { (Get-Content $stateFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value } } catch { $state = @{} } }
$key = $fp.ToLower()
$sigKey = $key + '::greensig'
$count = [int]$state[$key] + 1
# v2.1 (fix #3) : reset UNE SEULE FOIS par transition de green (signature differente de la derniere soldee),
# au lieu d'un reset a CHAQUE edit (qui desarmait le gate en permanence pour ce fichier).
if ($greenSig -and ($greenSig -ne [string]$state[$sigKey])) { $count = 1; $state[$sigKey] = $greenSig }
$state[$key] = $count
try { ($state | ConvertTo-Json -Compress) | Set-Content -Path $stateFile -Encoding utf8 } catch { }

$THRESHOLD = 6   # recalibre 4->6 (audit kaizen 2026-06-18) ; cf. commentaire d'en-tete v2.2
if ($disciplined -or $count -lt $THRESHOLD) { exit 0 }

# Telemetrie hors-modele (comme anti-flaky)
$counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
$entry = (@{ ts = (Get-Date -Format o); gate = 'fix-gate'; file = $fp; edits = $count; session = $sid } | ConvertTo-Json -Compress)
Add-Content -Path $counters -Value $entry -Encoding utf8

$reason = "FIX-GATE : $count e edition de '$([System.IO.Path]::GetFileName($fp))' dans cette session sans cause LIEE A CE FICHIER = signe d'un BLIND-FIX LOOP (vecu 2026-06-16). STOP : reproduis le bug + RECHERCHE la cause (ENGINE Ch.4 ; scout mode-debloquer) AVANT de re-coder. Pour debloquer : dans un RUN.md de la session qui NOMME ce fichier, ajoute 'CausalHypothesis: <cause + source>' (ou 'check:'), OU 'fix-ok: <justif>' sur une ligne du diff si c'est une feature/refactor (pas un fix aveugle), OU 'fix-gate: off'. Un RUN 'status: green' nommant le fichier reset le compteur (une fois par green verifie)."
@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $reason } } | ConvertTo-Json -Depth 5 -Compress
