# test-hooks.ps1 — harnais de verification des hooks (kaizen etape 5 ; fix #1 boucle kaizen 2026-06-18).
# fix-ok: nouvel outil de test (feature), pas un blind-fix.
# Pour chaque hook deny/nudge : PARSE (json malforme -> exit 0 propre), FIRE (entree positive -> sortie
# attendue), SILENT (entree negative -> aucune sortie). Un hook de cloture casse (regex morte / crash parse)
# tombe FAIL-OPEN silencieux : le test FIRE echoue alors -> on le voit. Bootstrap : les cas FIRE prouvent
# que le hook mord encore (un hook toujours-exit-0 fait echouer tous ses FIRE).
# Invoquer : powershell -NoProfile -File <ce fichier>  (exit = nb d'echecs ; 0 = tout vert). Forme whitelistee
# par stop-gate (utilisable en 'check:'). Isole : session de test prefixee 'test-' (kaizen-detect l'ignore).
$ErrorActionPreference = 'Stop'
$H = Join-Path $env:USERPROFILE '.claude\hooks'
$script:fails = 0
function J($o) { $o | ConvertTo-Json -Compress -Depth 8 }
function Run($hook, $stdin) {
    $f = Join-Path $H $hook
    $out = $stdin | & powershell -NoProfile -File $f 2>$null
    return [string]$out
}
function Check($name, $cond) { if ($cond) { "OK   $name" } else { "FAIL $name"; $script:fails++ } }

$sid = 'test-hooks-260618'

# --- fix-gate : FIRE (code, 6e edit, non discipline) / SILENT (.md) / PARSE (malforme) ---
$st = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-fixgate-$sid.json")
@{ 'c:\tmp\x.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Check 'fix-gate FIRE  (6e edit code non-discipline)' ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = 'C:\tmp\nope'; tool_input = @{ file_path = 'C:\tmp\x.ps1'; new_string = 'code' } })) -match 'deny')
@{ 'c:\tmp\x.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Check 'fix-gate SILENT(.md hors scope)' (-not ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = 'C:\tmp\nope'; tool_input = @{ file_path = 'C:\tmp\x.md'; new_string = 'doc' } })) -match 'deny'))
Check 'fix-gate PARSE (json malforme)' (-not ((Run 'fix-gate.ps1' 'pas du json {{') -match 'deny'))
Remove-Item $st -EA SilentlyContinue

# --- anti-flaky : FIRE (sleep brut) / SILENT (poll court) / PARSE ---
Check 'anti-flaky FIRE  (sleep brut)' ((Run 'anti-flaky.ps1' (J @{ tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' -Seconds 5') } })) -match 'deny')  # sleep-ok: fixture de test (chaine construite, pas un vrai sleep)
Check 'anti-flaky SILENT(poll 200ms)' (-not ((Run 'anti-flaky.ps1' (J @{ tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' -Milliseconds 200') } })) -match 'deny'))  # sleep-ok: fixture poll legitime
Check 'anti-flaky PARSE (malforme)' (-not ((Run 'anti-flaky.ps1' '{{bad') -match 'deny'))

# --- advisory-guard : FIRE (signal) / SILENT (neutre) / PARSE ---
Check 'advisory  FIRE  (vraie question advisory)' ((Run 'advisory-guard.ps1' (J @{ prompt = 'quelle est la meilleure version du script ?' })) -match 'additionalContext')
Check 'advisory  SILENT(fix #1: verbe action + meilleur)' (-not ((Run 'advisory-guard.ps1' (J @{ prompt = 'cree la meilleure version du script' })) -match 'additionalContext'))
Check 'advisory  FIRE  (regression: frustration + verbe action)' ((Run 'advisory-guard.ps1' (J @{ prompt = 'corrige ca, j ai rien compris' })) -match 'additionalContext')
Check 'advisory  SILENT(prompt neutre)' (-not ((Run 'advisory-guard.ps1' (J @{ prompt = 'parametre au script de deploiement neutre' })) -match 'additionalContext'))
Check 'advisory  PARSE (malforme)' (-not ((Run 'advisory-guard.ps1' 'nope') -match 'additionalContext'))

# --- stop-gate : FIRE (open) / SILENT (gate off) / fix #2 (placeholder ignore vs vraie decision bloquee) ---
$ws = "Audit\workspaces\$sid"
$d = Join-Path $ws 't-workspace'
function MkRun($content) { New-Item -ItemType Directory -Force -Path $d | Out-Null; Set-Content (Join-Path $d 'RUN.md') -Value $content -Encoding utf8 }
$sg = J @{ session_id = $sid; cwd = 'C:\Code RIG' }
MkRun "status: open`nsession: $sid"
Check 'stop-gate FIRE  (status open)' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: open`nsession: $sid`ngate: off"
Check 'stop-gate SILENT(gate off)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
MkRun "status: green`nsession: $sid`nregime: standard`n## Options`nDécision: <laquelle et pourquoi>"
Check '#2 anti-fixation IGNORE le scaffold placeholder' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
MkRun "status: green`nsession: $sid`nregime: standard`nDécision: Option B parce que cest mieux"
Check '#2 anti-fixation BLOQUE vraie decision sans 3 options' ((Run 'stop-gate.ps1' $sg) -match 'block')
# fix #3 : couverture du REJEU signal-cmd (le mecanisme de cloture le + consequent)
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd /c exit 1"
Check '#3 stop-gate BLOQUE (signal-cmd rejoue echoue)' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd /c exit 0"
Check '#3 stop-gate PASSE (signal-cmd rejoue reussit)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# fix #1 : critical sans preuve hors-modele -> block ; avec check:/attestable -> pass
MkRun "status: green`nsession: $sid`nregime: critical"
Check '#1 stop-gate BLOQUE (critical sans preuve)' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: green`nsession: $sid`nregime: critical`ncheck: cmd /c exit 0"
Check '#1 stop-gate PASSE (critical + check rejouable)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
MkRun "status: green`nsession: $sid`nregime: critical`nsignal-attestable: capture lue + run-stamp"
Check '#1 stop-gate PASSE (critical + signal-attestable)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
Remove-Item -Recurse -Force $ws -EA SilentlyContinue

"--- $script:fails echec(s) ---"
exit $script:fails
