# test-hooks.ps1 — harnais de verification des hooks (kaizen etape 5 ; durci 2026-06-18 = failles scout).
# fix-ok: outil de test (feature), pas un blind-fix.
# Pour chaque hook : PARSE (json malforme -> pas de faux deny/block) / FIRE (positif -> sortie attendue) /
# SILENT (negatif -> rien). Un hook de cloture casse tombe FAIL-OPEN silencieux : son FIRE echoue alors -> vu.
# PORTABLE (fix #2 failles scout) : $H = $PSScriptRoot (marche installe / en repo / en CI) ; fixtures sous
# $env:TEMP (plus de chemin machine 'C:\Code RIG' qui rendait les FIRE faussement verts hors machine auteur).
# Invoquer : powershell -NoProfile -File <ce fichier>  (exit = nb d'echecs ; 0 = tout vert). Whiteliste stop-gate.
$ErrorActionPreference = 'Stop'
$H = $PSScriptRoot
if (-not $H) { $H = Join-Path $env:USERPROFILE '.claude\hooks' }
$script:fails = 0
function J($o) { $o | ConvertTo-Json -Compress -Depth 8 }
function Run($hook, $stdin) {
    $f = Join-Path $H $hook
    $out = $stdin | & powershell -NoProfile -File $f 2>$null
    return [string]$out
}
function Check($name, $cond) { if ($cond) { "OK   $name" } else { "FAIL $name"; $script:fails++ } }

$sid = 'test-hooks-260618'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) "claude-test-$sid"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# --- fix-gate : FIRE (6e edit non discipline) / SILENT (.md) / PARSE / #7 prose-vs-token ---
$st = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-fixgate-$sid.json")
@{ 'c:\tmp\x.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Check 'fix-gate FIRE  (6e edit code non-discipline)' ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = 'C:\tmp\nope'; tool_input = @{ file_path = 'C:\tmp\x.ps1'; new_string = 'code' } })) -match 'deny')
@{ 'c:\tmp\x.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Check 'fix-gate SILENT(.md hors scope)' (-not ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = 'C:\tmp\nope'; tool_input = @{ file_path = 'C:\tmp\x.md'; new_string = 'doc' } })) -match 'deny'))
Check 'fix-gate PARSE (json malforme)' (-not ((Run 'fix-gate.ps1' 'pas du json {{') -match 'deny'))
# fix #7 (failles scout) : nom du fichier en PROSE seule ne desarme PAS ; sur une ligne-token (CausalHypothesis), si.
$df = Join-Path $tmp "Audit\workspaces\$sid\f-workspace"; New-Item -ItemType Directory -Force $df | Out-Null
@{ 'c:\tmp\x.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Set-Content (Join-Path $df 'RUN.md') -Value "status: open`nsession: $sid`nJournal: on a edite x.ps1 en passant" -Encoding utf8
Check '#7 fix-gate FIRE  (fichier nomme en PROSE seule)' ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = $tmp; tool_input = @{ file_path = 'C:\tmp\x.ps1'; new_string = 'code' } })) -match 'deny')
@{ 'c:\tmp\x.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Set-Content (Join-Path $df 'RUN.md') -Value "status: open`nsession: $sid`nCausalHypothesis: cause X sur x.ps1 (src)" -Encoding utf8
Check '#7 fix-gate SILENT(fichier sur ligne CausalHypothesis)' (-not ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = $tmp; tool_input = @{ file_path = 'C:\tmp\x.ps1'; new_string = 'code' } })) -match 'deny'))
# REG (failles scout SB2) : 'fix-gate: off' en PROSE (pas une ligne dediee) ne desarme PLUS
@{ 'c:\tmp\x.ps1' = 6 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Set-Content (Join-Path $df 'RUN.md') "status: open`nsession: $sid`nJournal: j ai hesite a mettre fix-gate: off mais finalement non" -Encoding utf8
Check 'REG fix-gate:off en PROSE -> DENY' ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = $tmp; tool_input = @{ file_path = 'C:\tmp\x.ps1'; new_string = 'code' } })) -match 'deny')
Remove-Item -Recurse -Force $df -EA SilentlyContinue
Remove-Item $st -EA SilentlyContinue

# --- anti-flaky : FIRE (sleep brut PS) / FIRE (python, fix #11) / SILENT (poll court) / PARSE ---
Check 'anti-flaky FIRE  (sleep brut PS)' ((Run 'anti-flaky.ps1' (J @{ tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' -Seconds 5') } })) -match 'deny')  # sleep-ok: fixture (chaine construite)
Check '#11 anti-flaky FIRE (python time.sleep)' ((Run 'anti-flaky.ps1' (J @{ tool_input = @{ file_path = 'C:\tmp\z.py'; new_string = ('time.' + 'sleep(5)') } })) -match 'deny')  # sleep-ok: fixture python construite
Check 'anti-flaky SILENT(poll 200ms)' (-not ((Run 'anti-flaky.ps1' (J @{ tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' -Milliseconds 200') } })) -match 'deny'))  # sleep-ok: fixture poll
Check 'anti-flaky PARSE (malforme)' (-not ((Run 'anti-flaky.ps1' '{{bad') -match 'deny'))

# --- advisory-guard : FIRE / SILENT / PARSE ---
Check 'advisory  FIRE  (vraie question advisory)' ((Run 'advisory-guard.ps1' (J @{ prompt = 'quelle est la meilleure version du script ?' })) -match 'additionalContext')
Check 'advisory  SILENT(verbe action + meilleur)' (-not ((Run 'advisory-guard.ps1' (J @{ prompt = 'cree la meilleure version du script' })) -match 'additionalContext'))
Check 'advisory  FIRE  (frustration + verbe action)' ((Run 'advisory-guard.ps1' (J @{ prompt = 'corrige ca, j ai rien compris' })) -match 'additionalContext')
Check 'advisory  SILENT(prompt neutre)' (-not ((Run 'advisory-guard.ps1' (J @{ prompt = 'parametre au script de deploiement neutre' })) -match 'additionalContext'))
Check 'advisory  PARSE (malforme)' (-not ((Run 'advisory-guard.ps1' 'nope') -match 'additionalContext'))

# --- stop-gate ---
$d = Join-Path $tmp "Audit\workspaces\$sid\t-workspace"
function MkRun($content) { New-Item -ItemType Directory -Force -Path $d | Out-Null; Set-Content (Join-Path $d 'RUN.md') -Value $content -Encoding utf8 }
$sg = J @{ session_id = $sid; cwd = $tmp }
MkRun "status: open`nsession: $sid"
Check 'stop-gate FIRE  (status open)' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: open`nsession: $sid`ngate: off"
Check 'stop-gate SILENT(gate off)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# fix #8 (failles scout) : stdin illisible = fail-CLOSED (block) ; stdin vide = rien
Check '#8 stop-gate BLOQUE (stdin illisible = fail-closed)' ((Run 'stop-gate.ps1' 'pas du json {{') -match 'block')
Check '#8 stop-gate SILENT(stdin vide)' (-not ((Run 'stop-gate.ps1' '') -match 'block'))
# anti-fixation : placeholder ignore vs vraie decision bloquee
MkRun "status: green`nsession: $sid`nregime: standard`n## Options`nDécision: <laquelle et pourquoi>"
Check 'anti-fixation IGNORE le scaffold placeholder' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
MkRun "status: green`nsession: $sid`nregime: standard`nDécision: Option B parce que cest mieux"
Check 'anti-fixation BLOQUE vraie decision sans 3 options' ((Run 'stop-gate.ps1' $sg) -match 'block')
# fix #1 (failles scout) : signal-cmd VACANT (cmd /c exit 0) ne prouve rien -> BLOCK
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd /c exit 0"
Check '#1 stop-gate BLOQUE (signal-cmd vacant cmd/c exit 0)' ((Run 'stop-gate.ps1' $sg) -match 'block')
$qq=[char]34
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd /c ${qq}exit 0${qq}"
Check 'REG signal-cmd cmd/c quote exit 0 -> BLOCK' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd /c call exit 0"
Check 'REG signal-cmd cmd/c call exit 0 -> BLOCK' ((Run 'stop-gate.ps1' $sg) -match 'block')
# REJEU reel via script whiteliste : echoue -> BLOCK ; reussit -> PASSE ; prefixe mal-casse -> PASSE (fix #3)
$okps1 = Join-Path $tmp 'gate-ok.ps1'; Set-Content $okps1 -Value 'exit 0' -Encoding utf8
$kops1 = Join-Path $tmp 'gate-ko.ps1'; Set-Content $kops1 -Value 'exit 1' -Encoding utf8
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: powershell -NoProfile -File $kops1"
Check '#3 stop-gate BLOQUE (rejeu reel echoue)' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: powershell -NoProfile -File $okps1"
Check '#3 stop-gate PASSE (rejeu reel reussit)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: PowerShell -NoProfile -File $okps1"
Check '#3 stop-gate PASSE (whitelist case-insensitive)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# disposable : aucune preuve requise -> PASSE
MkRun "status: green`nsession: $sid`nregime: disposable"
Check 'stop-gate PASSE (disposable sans preuve)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# critical sans preuve -> block ; avec check:/attestable -> pass
MkRun "status: green`nsession: $sid`nregime: critical"
Check 'stop-gate BLOQUE (critical sans preuve)' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: green`nsession: $sid`nregime: critical`ncheck: powershell -NoProfile -File $okps1"
Check 'stop-gate PASSE (critical + check MEANINGFUL)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# REG (failles scout) : un check VACANT (cmd /c exit 0) ne certifie PLUS un green critical
MkRun "status: green`nsession: $sid`nregime: critical`ncheck: cmd /c exit 0"
Check 'REG critical + check VACANT -> BLOCK' ((Run 'stop-gate.ps1' $sg) -match 'block')
MkRun "status: green`nsession: $sid`nregime: critical`nsignal-attestable: capture lue + run-stamp"
Check 'stop-gate PASSE (critical + signal-attestable)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# re-open : un event unit= APRES GATE-VERIFIED force la re-verif (ici signal vacant -> re-bloque)
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd /c exit 0`n[2026-01-01 00:00] GATE-VERIFIED`n[2026-01-01 00:01] unit=rework"
Check 'stop-gate re-verifie (unit= apres GATE-VERIFIED -> re-block)' ((Run 'stop-gate.ps1' $sg) -match 'block')

Remove-Item -Recurse -Force $tmp -EA SilentlyContinue

"--- $script:fails echec(s) ---"
exit $script:fails
