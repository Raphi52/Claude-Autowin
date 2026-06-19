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
# TELEMETRY ISOLATION (kaizen) : redirige USERPROFILE vers un sandbox pour TOUT le run -> aucun hook n'ecrit
# dans la VRAIE gate-counters.jsonl (cause racine du 87% de pollution). $H (hooks) reste reel (PSScriptRoot deja capture).
$origUP = $env:USERPROFILE
$sandboxHome = Join-Path $tmp 'home'; New-Item -ItemType Directory -Force (Join-Path $sandboxHome '.claude\hooks') | Out-Null
$env:USERPROFILE = $sandboxHome

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
# green-reset : un RUN green nommant le fichier (sur fix-file:, SANS check/CausalHypothesis -> pas discipline) reset le compteur 1x/transition -> SILENT
@{ 'c:\tmp\gr.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $st -Encoding utf8
Set-Content (Join-Path $df 'RUN.md') -Value "status: green`nsession: $sid`nfix-file: gr.ps1`n[2026-01-01 00:00] GATE-VERIFIED" -Encoding utf8
Check 'green-reset fix-gate SILENT (RUN green nommant le fichier reset le compteur)' (-not ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = $tmp; tool_input = @{ file_path = 'C:\tmp\gr.ps1'; new_string = 'code' } })) -match 'deny'))
Remove-Item -Recurse -Force $df -EA SilentlyContinue
Remove-Item $st -EA SilentlyContinue

# --- anti-flaky : FIRE (sleep brut PS) / FIRE (python, fix #11) / SILENT (poll court) / PARSE ---
Check 'anti-flaky FIRE  (sleep brut PS)' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' -Seconds 5') } })) -match 'deny')  # sleep-ok: fixture (chaine construite)
Check '#11 anti-flaky FIRE (python time.sleep)' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\z.py'; new_string = ('time.' + 'sleep(5)') } })) -match 'deny')  # sleep-ok: fixture python construite
Check 'REG anti-flaky FIRE (Start-Sleep float 1.5)' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' 1.5') } })) -match 'deny')  # sleep-ok: fixture float construite
Check 'REG anti-flaky FIRE (Start-Sleep paren cast)' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + '([int]5)') } })) -match 'deny')  # sleep-ok: fixture paren construite
Check 'REG(Gemini) anti-flaky FIRE (sleep(2) paren nu)' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\z.py'; new_string = ('sleep' + '(2)') } })) -match 'deny')  # sleep-ok: fixture construite
Check 'REG(Gemini) anti-flaky FIRE (sleep (2) espace+paren)' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\z.py'; new_string = ('sleep' + ' (2)') } })) -match 'deny')  # sleep-ok: fixture construite
Check 'anti-flaky SILENT(poll 200ms)' (-not ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\y.ps1'; new_string = ('Start-Sleep' + ' -Milliseconds 200') } })) -match 'deny'))  # sleep-ok: fixture poll
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
Check 'REG stop-gate BLOQUE (stdin scalaire JSON = fail-closed)' ((Run 'stop-gate.ps1' '0') -match 'block')
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
# degraded-closed = USER-OK -> PASS (3e statut, distinct de open/red qui BLOQUENT)
MkRun "status: degraded-closed`nsession: $sid`nregime: standard"
Check 'stop-gate PASSE (degraded-closed = USER-OK honor-bound)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
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
# REG(Gemini) : cmd.exe /c + runner = preuve valide (cmd.exe non-whiteliste -> pas de rejeu)
MkRun "status: green`nsession: $sid`nregime: standard`nsignal-cmd: cmd.exe /c dotnet test"
Check 'REG(Gemini) stop-gate PASSE (cmd.exe /c dotnet test = preuve)' (-not ((Run 'stop-gate.ps1' $sg) -match 'block'))
# REG(Gemini) : GATE-VERIFIED sur sa PROPRE ligne meme si RUN.md sans newline final (disposable -> passe -> stamp)
New-Item -ItemType Directory -Force -Path $d | Out-Null
[IO.File]::WriteAllText((Join-Path $d 'RUN.md'), "status: green`nsession: $sid`nregime: disposable`nderniere ligne SANS NL")
Run 'stop-gate.ps1' $sg | Out-Null
Check 'REG(Gemini) GATE-VERIFIED sur sa propre ligne (RUN.md sans NL final)' ((Get-Content (Join-Path $d 'RUN.md'))[-1] -match '^\s*\[[^\]]*\]\s*GATE-VERIFIED\s*$')

# --- extracted inline hooks (2026-06-18) : model-tier / judge-nudge / precompact-runcheck / thinking-mode / session-inject ---
Check 'model-tier FIRE (Explore, no model -> sonnet)' ((Run 'model-tier.ps1' (J @{ tool_input = @{ subagent_type = 'Explore' } })) -match 'sonnet')
Check 'model-tier SILENT (other agent type)' (-not ((Run 'model-tier.ps1' (J @{ tool_input = @{ subagent_type = 'statusline-setup' } })) -match 'updatedInput'))
Check 'model-tier SILENT (Explore avec model deja set -> pas d override)' (-not ((Run 'model-tier.ps1' (J @{ tool_input = @{ subagent_type = 'Explore'; model = 'opus' } })) -match 'updatedInput'))
$jnflag = Join-Path ([System.IO.Path]::GetTempPath()) ('claude-review-nudge-' + $sid + '.flag'); Remove-Item $jnflag -EA SilentlyContinue
Check 'judge-nudge FIRE (code file, fresh session)' ((Run 'judge-nudge.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\x.py' } })) -match 'additionalContext')
Check 'judge-nudge SILENT (.txt out of scope)' (-not ((Run 'judge-nudge.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\x.txt' } })) -match 'additionalContext'))
Check 'judge-nudge SILENT (2e appel meme session, flag deja pose = 1x/session)' (-not ((Run 'judge-nudge.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\x2.py' } })) -match 'additionalContext'))
Remove-Item $jnflag -EA SilentlyContinue
$pc = Join-Path $tmp "Audit\workspaces\$sid\pc-workspace"; New-Item -ItemType Directory -Force $pc | Out-Null; Set-Content (Join-Path $pc 'RUN.md') "status: open`nsession: $sid" -Encoding utf8
Check 'precompact FIRE (open RUN -> systemMessage)' ((Run 'precompact-runcheck.ps1' (J @{ session_id = $sid; cwd = $tmp })) -match 'systemMessage')
Check 'precompact SILENT (no session dir)' (-not ((Run 'precompact-runcheck.ps1' (J @{ session_id = 'none-xyz'; cwd = $tmp })) -match 'systemMessage'))
Check 'thinking-mode FIRE (? prefix)' ((Run 'thinking-mode.ps1' (J @{ prompt = '? je reflechis' })) -match 'THINKING MODE')
Check 'thinking-mode SILENT (normal prompt)' (-not ((Run 'thinking-mode.ps1' (J @{ prompt = 'cree le module' })) -match 'THINKING MODE'))
Check 'session-inject FIRE (session_id -> SESSION_ID)' ((Run 'session-inject.ps1' (J @{ session_id = 'abc123' })) -match 'SESSION_ID=abc123')
Check 'session-inject SILENT (no session_id)' (-not ((Run 'session-inject.ps1' (J @{ prompt = 'x' })) -match 'SESSION_ID'))

# --- full-autonomy hooks (toggle AUTOWIN_AUTONOMY) : OFF par defaut, ON via env, fail-safe, defere au ? ---
$prevAuto = $env:AUTOWIN_AUTONOMY
$env:AUTOWIN_AUTONOMY = ''   # OFF
Check 'autonomy-directive SILENT (toggle OFF)' (-not ((Run 'full-autonomy-directive.ps1' (J @{ prompt = 'fais le truc' })) -match 'FULL-AUTONOMY'))
Check 'autonomy-allow    SILENT (toggle OFF)' (-not ((Run 'full-autonomy-allow.ps1' (J @{ tool_name = 'Bash'; tool_input = @{ command = 'echo hi' } })) -match 'permissionDecision'))
$env:AUTOWIN_AUTONOMY = '1'  # ON
Check 'autonomy-directive FIRE   (toggle ON)' ((Run 'full-autonomy-directive.ps1' (J @{ prompt = 'fais le truc' })) -match 'FULL-AUTONOMY')
Check 'autonomy-directive SILENT (? prefix defere thinking-mode, meme ON)' (-not ((Run 'full-autonomy-directive.ps1' (J @{ prompt = '? je reflechis' })) -match 'FULL-AUTONOMY'))
Check 'autonomy-allow    FIRE   (toggle ON -> allow)' ((Run 'full-autonomy-allow.ps1' (J @{ tool_name = 'Bash'; tool_input = @{ command = 'rm -rf x' } })) -match '"permissionDecision":\s*"allow"')
Check 'autonomy-allow    PARSE  (malforme -> pas d allow, fail-safe)' (-not ((Run 'full-autonomy-allow.ps1' 'pas du json {{') -match '"permissionDecision"'))
# BORNE (judge fix) : sous AUTOWIN_AUTONOMY=1 les deny-gates MORDENT toujours (le toggle ne les desarme pas ; deny > allow)
Check 'BORNE anti-flaky DENY sous autonomy ON' ((Run 'anti-flaky.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = 'C:\tmp\bnd.ps1'; new_string = ('Start-Sleep' + ' -Seconds 5') } })) -match 'deny')  # sleep-ok: fixture bornee
$stB = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-fixgate-$sid.json"); @{ 'c:\tmp\bnd.ps1' = 5 } | ConvertTo-Json -Compress | Set-Content $stB -Encoding utf8
Check 'BORNE fix-gate DENY sous autonomy ON' ((Run 'fix-gate.ps1' (J @{ session_id = $sid; cwd = 'C:\tmp\nope'; tool_input = @{ file_path = 'C:\tmp\bnd.ps1'; new_string = 'code' } })) -match 'deny')
Remove-Item $stB -EA SilentlyContinue
# toggle robustesse (judge minors) : 'YES' case-insensitive -> FIRE ; valeur non reconnue -> SILENT ; espace trim -> FIRE
$env:AUTOWIN_AUTONOMY = 'YES'
Check 'autonomy-allow FIRE (case-insensitive YES)' ((Run 'full-autonomy-allow.ps1' (J @{ tool_input = @{ command = 'x' } })) -match '"permissionDecision":\s*"allow"')
$env:AUTOWIN_AUTONOMY = ' 1 '
Check 'autonomy-allow FIRE (espace trim -> ON)' ((Run 'full-autonomy-allow.ps1' (J @{ tool_input = @{ command = 'x' } })) -match '"permissionDecision":\s*"allow"')
$env:AUTOWIN_AUTONOMY = 'maybe'
Check 'autonomy-allow SILENT (valeur non reconnue)' (-not ((Run 'full-autonomy-allow.ps1' (J @{ tool_input = @{ command = 'x' } })) -match '"permissionDecision"'))
$env:AUTOWIN_AUTONOMY = $prevAuto

# --- kaizen telemetry hooks (non-blocking) : detection reelle + ne polluent jamais le canal stdout ---
Check 'kaizen-revert-log PARSE  (malforme -> silencieux stdout)' (-not ((Run 'kaizen-revert-log.ps1' 'bad {{') -match '\S'))
# FIRE comportemental : A->B->A = revert. gate-counters redirige vers $tmp\.claude via $env:USERPROFILE (pas de pollution prod).
$prevUP = $env:USERPROFILE
$revFile = Join-Path $tmp 'rev.ps1'
$revStore = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-kaizen-revert-$sid.jsonl"); Remove-Item $revStore -EA SilentlyContinue
$env:USERPROFILE = $tmp; New-Item -ItemType Directory -Force (Join-Path $tmp '.claude') | Out-Null
Set-Content $revFile 'A' -Encoding utf8; Run 'kaizen-revert-log.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = $revFile } }) | Out-Null
Set-Content $revFile 'B' -Encoding utf8; Run 'kaizen-revert-log.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = $revFile } }) | Out-Null
Set-Content $revFile 'A' -Encoding utf8; Run 'kaizen-revert-log.ps1' (J @{ session_id = $sid; tool_input = @{ file_path = $revFile } }) | Out-Null
$gc = Join-Path $tmp '.claude\gate-counters.jsonl'
Check 'kaizen-revert-log FIRE   (A->B->A = revert logge gate-counters)' ((Test-Path $gc) -and ((Get-Content $gc -Raw) -match '"gate":\s*"revert"'))
$env:USERPROFILE = $prevUP; Remove-Item $revStore -EA SilentlyContinue
Check 'kaizen-nudge      PARSE  (malforme -> pas de nudge)' (-not ((Run 'kaizen-nudge.ps1' 'bad {{') -match 'additionalContext|systemMessage'))
# SILENT hermetique : USERPROFILE redirige vers un temp SANS gate-counters -> detect rend [] -> pas de nudge (ne depend PAS de la telemetrie machine reelle).
$knClean = Join-Path $tmp 'kn-clean'; $knCleanH = Join-Path $knClean '.claude\hooks'; New-Item -ItemType Directory -Force $knCleanH | Out-Null
Copy-Item (Join-Path $H 'kaizen-detect.ps1') (Join-Path $knCleanH 'kaizen-detect.ps1') -Force
$prevUP4 = $env:USERPROFILE; $env:USERPROFILE = $knClean
Check 'kaizen-nudge      SILENT (detect ne trouve aucun pattern -> pas de nudge)' (-not ((Run 'kaizen-nudge.ps1' (J @{ session_id = $sid })) -match 'additionalContext|systemMessage'))
$env:USERPROFILE = $prevUP4
# FIRE : pattern recurrent REEL (>=5 fix-gate, fichiers distincts, session non-test) -> nudge. USERPROFILE redirige + kaizen-detect copie ; ledger absent ; flag retire.
$knUP = Join-Path $tmp 'kn-up'; $knH = Join-Path $knUP '.claude\hooks'; New-Item -ItemType Directory -Force $knH | Out-Null
Copy-Item (Join-Path $H 'kaizen-detect.ps1') (Join-Path $knH 'kaizen-detect.ps1') -Force
$knGc = Join-Path $knUP '.claude\gate-counters.jsonl'; $knTs = (Get-Date).ToString('o')
1..5 | ForEach-Object { (@{ ts = $knTs; gate = 'fix-gate'; file = "C:\proj\f$_.ps1"; session = 'realsess' } | ConvertTo-Json -Compress) | Add-Content $knGc -Encoding utf8 }
$knSid = 'kn-fire'; $knFlag = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-kaizen-nudge-$knSid.flag"); Remove-Item $knFlag -EA SilentlyContinue
$prevUP3 = $env:USERPROFILE; $env:USERPROFILE = $knUP
Check 'kaizen-nudge      FIRE   (pattern recurrent reel >=5 -> nudge)' ((Run 'kaizen-nudge.ps1' (J @{ session_id = $knSid })) -match 'additionalContext')
$env:USERPROFILE = $prevUP3; Remove-Item $knFlag -EA SilentlyContinue

# --- build-cadence : nudge mid-build (verify chaque incrément) — FIRE au seuil / SILENT sous / RESET sur verify / non-code SILENT / PARSE ---
$bcState = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-buildcadence-$sid.json"); Remove-Item $bcState -EA SilentlyContinue
@{ edits = 4 } | ConvertTo-Json -Compress | Set-Content $bcState -Encoding utf8
Check 'build-cadence FIRE  (5e edit code sans verify -> nudge)' ((Run 'build-cadence.ps1' (J @{ session_id = $sid; tool_name = 'Edit'; tool_input = @{ file_path = 'C:\tmp\b.ps1' } })) -match 'BUILD CADENCE')
@{ edits = 1 } | ConvertTo-Json -Compress | Set-Content $bcState -Encoding utf8
Check 'build-cadence SILENT (sous le seuil)' (-not ((Run 'build-cadence.ps1' (J @{ session_id = $sid; tool_name = 'Edit'; tool_input = @{ file_path = 'C:\tmp\b.ps1' } })) -match 'BUILD CADENCE'))
@{ edits = 4 } | ConvertTo-Json -Compress | Set-Content $bcState -Encoding utf8
Check 'build-cadence SILENT (.md non-code -> pas d increment)' (-not ((Run 'build-cadence.ps1' (J @{ session_id = $sid; tool_name = 'Edit'; tool_input = @{ file_path = 'C:\tmp\b.md' } })) -match 'BUILD CADENCE'))
@{ edits = 4 } | ConvertTo-Json -Compress | Set-Content $bcState -Encoding utf8
Run 'build-cadence.ps1' (J @{ session_id = $sid; tool_name = 'Bash'; tool_input = @{ command = 'dotnet test' } }) | Out-Null
Check 'build-cadence RESET (verify -> compteur 0)' (([int]((Get-Content $bcState -Raw | ConvertFrom-Json).edits)) -eq 0)
@{ edits = 4 } | ConvertTo-Json -Compress | Set-Content $bcState -Encoding utf8
Run 'build-cadence.ps1' (J @{ session_id = $sid; tool_name = 'Bash'; tool_input = @{ command = 'git commit -m "make it green"' } }) | Out-Null
Check 'build-cadence NO-RESET (make dans un msg git != verify, anti-faux-positif)' (([int]((Get-Content $bcState -Raw | ConvertFrom-Json).edits)) -eq 4)
Check 'build-cadence PARSE (malforme -> pas de nudge)' (-not ((Run 'build-cadence.ps1' 'bad {{') -match 'BUILD CADENCE'))
Remove-Item $bcState -EA SilentlyContinue

$env:USERPROFILE = $origUP
Remove-Item -Recurse -Force $tmp -EA SilentlyContinue

"--- $script:fails echec(s) ---"
exit $script:fails
