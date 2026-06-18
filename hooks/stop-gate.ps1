# stop-gate.ps1 v3.2 — hook Stop : l'autorite de cloture sort du modele, et le VERT n'est pas cru, il est VERIFIE.
#
# Convention RUN.md (header machine-parseable, premieres lignes ; convention complete : _engine/ENGINE.md ch.3) :
#   status: open | green | red | degraded-closed
#   regime: disposable | standard | critical
#   signal: <artefact qui prouve le vert>
#   signal-cmd: <commande IDEMPOTENTE optionnelle que le gate REJOUE (prefixes whitelistes)>
#   gate: off   (opt-out justifie)
#   session: <id>  (v3.2 — SCOPE : ce run n'est enforce QUE pour la session <id>. A defaut de header, un run
#                   place sous Audit\workspaces\<session_id>\ est scope a cette session PAR SON EMPLACEMENT.)
# Sections lues : "## Options" (lignes contenant "score:"), ligne "Décision:", "## Checks" (lignes "check: <cmd>").
#
# v3.2 SCOPE PAR SESSION : sous un meme cwd, plusieurs sessions concurrentes ne se cross-bloquent plus —
#   le gate n'enforce QUE les runs de SA session (par emplacement <session_id>\ ou header session:). Filet :
#   session_id absent du stdin => comportement LEGACY (scanne+enforce tout) pour ne jamais desarmer le gate.
#
# Regles :
#   open|red -> BLOCK. degraded-closed -> pass (USER-OK = contrainte d'honneur, verifiee par la review).
#   green -> VERIFIE une fois par transition. v3.1 : le marqueur GATE-VERIFIED ne vaut que s'il est
#     POSTERIEUR au dernier evenement "[ts] unit=..." du Journal (run rouvert apres marqueur = RE-verifie).
#     (a) rejoue signal-cmd si whitelistee -> exit != 0 = BLOCK ; plafond GATE_REPLAY_TIMEOUT_MS
#         (defaut 120000 ms) -> depassement = kill arbre + BLOCK (exit 124) ;
#     (b) execute chaque "check: <cmd>" (lecons promues en code) -> exit != 0 = BLOCK, meme plafond ;
#     (c) anti-fixation : decision engagee + <3 lignes d'OPTION scorees ancrees ("- ... score: N", pas de
#         la prose) + regime != disposable = BLOCK.
#     Succes -> append "[ts] GATE-VERIFIED" au fichier (les passages suivants ne rejouent pas).
#   stop_hook_active -> pass (anti-boucle).
# Limite honnete : un signal-cmd absent/non-whiteliste laisse le green sur l'auto-preuve (artefact frais) —
# le residuel est alors VISIBLE via artifact_based cote review, jamais masque.

$ErrorActionPreference = 'SilentlyContinue'
$raw = ''
try { $raw = [Console]::In.ReadToEnd() } catch { $raw = '' }
try { $j = $raw | ConvertFrom-Json } catch { $j = $null }
# fix #8 (failles scout 2026-06-18) : l'AUTORITE de cloture ne fail-OPEN pas sur un stdin illisible OU non-objet.
# Un payload NON VIDE qui n'est pas un objet JSON (null, scalaire 0/"x", tableau []) -> fail-CLOSED (block).
# stdin vide = pas un vrai event -> exit 0. (Ferme le bypass : un scalaire JSON valide echappait au fail-closed.)
if ($null -eq $j -or ($j -isnot [System.Management.Automation.PSCustomObject])) {
    if ($raw.Trim()) { @{ decision = 'block'; reason = 'STOP-GATE : stdin illisible ou non-objet (JSON malforme/scalaire) -- fail-closed.' } | ConvertTo-Json -Compress }
    exit 0
}
if ($j.stop_hook_active) { exit 0 }

$cwd = [string]$j.cwd
if (-not $cwd -or -not (Test-Path $cwd)) { exit 0 }

$replayWhitelist = @('dotnet test', 'dotnet build', 'cmd /c', 'powershell -NoProfile -File', 'powershell -File', 'pwsh -NoProfile -File', 'pwsh -File')

# v3.1 : plafond d'execution des rejeux/checks — un signal-cmd qui pend ne doit pas geler la session
$replayTimeoutMs = 120000
if ($env:GATE_REPLAY_TIMEOUT_MS -match '^\d+$') { $replayTimeoutMs = [int]$env:GATE_REPLAY_TIMEOUT_MS }

function Invoke-GateCmd([string]$c) {
    # >NUL dans la ligne cmd : aucun flux a drainer (anti-deadlock buffer), zero pollution du stdout du hook
    $psi = New-Object System.Diagnostics.ProcessStartInfo('cmd.exe', ('/c ' + $c + ' >NUL 2>&1'))
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    if (-not $p) { return 125 }
    if (-not $p.WaitForExit($script:replayTimeoutMs)) {
        cmd.exe /c ('taskkill /PID ' + $p.Id + ' /T /F') | Out-Null
        return 124
    }
    return $p.ExitCode
}

# fix (failles scout 2026-06-18, ALLOWLIST de preuve) : une PREUVE doit invoquer un vrai runner test/build OU
# un SCRIPT (.ps1/.cmd/.bat/.py/.js). Le denylist de vacuite fuyait (cmd /c "exit 0" / call / wrapping) ->
# on exige le positif. Sert a (a) signal-cmd ET (d) la preuve CRITICAL + les check:.
$script:proofRunners = @('dotnet test', 'dotnet build', 'dotnet run', 'pytest', 'npm test', 'npm run', 'jest', 'go test', 'cargo test', 'msbuild', 'make ')
function Test-MeaningfulProof([string]$c) {
    if (-not $c) { return $false }
    $e = ($c -replace '^(?i)\s*cmd\s+/c\s+', '').Trim().Trim('"').Trim()
    if ($e -match '(?i)(^|\s)-File\s+\S+\.(ps1|cmd|bat)(\b|$)') { return $true }
    if ($e -match '(?i)\.(ps1|cmd|bat|py|js)(\s|$)') { return $true }
    foreach ($r in $script:proofRunners) { if ($e -match ('(?i)^' + [regex]::Escape($r))) { return $true } }
    return $false
}

# v3.2 — SCOPE PAR SESSION. On ajoute la racine de session Audit\workspaces\<session_id>\ aux roots scannes
# (ses runs sont "a moi" par emplacement) ; cwd + Audit\workspaces top-level restent scannes mais seront
# filtres par appartenance dans la boucle (header session: == mon id). Filet legacy si session_id absent.
$sid = [string]$j.session_id
$central = Join-Path $cwd 'Audit\workspaces'
$roots = @($cwd)
if (Test-Path $central) { $roots += $central }
if ($sid) { $sessionRoot = Join-Path $central $sid; if (Test-Path $sessionRoot) { $roots += $sessionRoot } }
$wsDirs = @()
foreach ($r in $roots) {
    $wsDirs += Get-ChildItem -Path $r -Directory -Filter '*-workspace' -ErrorAction SilentlyContinue
}
$wsDirs = @($wsDirs | Sort-Object FullName -Unique)

$bad = @()
foreach ($d in $wsDirs) {
    $run = Join-Path $d.FullName 'RUN.md'
    if (-not (Test-Path $run)) { continue }
    $all = @(Get-Content $run -Encoding UTF8 -ErrorAction SilentlyContinue)
    if (-not $all) { continue }
    $head = $all | Select-Object -First 14
    if (($head | Where-Object { $_ -match '^\s*gate:\s*off\s*$' })) { continue }
    # v3.2 — n'enforce QUE les runs de CETTE session : a moi si sous Audit\workspaces\<mon id>\ OU header
    # "session: <mon id>". Sinon (autre session / legacy non-stampe) => IGNORE. Filet : pas de session_id => legacy.
    $owned = $false
    if ($sid) {
        $underMySession = ($d.FullName -like ('*\Audit\workspaces\' + $sid + '\*'))
        $sessLine = $head | Where-Object { $_ -match '^\s*session:\s*\S' } | Select-Object -First 1
        $runSession = if ($sessLine) { ($sessLine -replace '^\s*session:\s*', '').Trim() } else { '' }
        $owned = ($underMySession -or ($runSession -and $runSession -eq $sid))
        if (-not $owned) { continue }
    }
    # fix SECURITE (failles scout 2026-06-18, RCE-by-clone) : on n'EXECUTE (rejeu signal-cmd/check) QUE les RUN
    # de CETTE session (owned). En legacy (sid absent) => owned=false => AUCUN rejeu : un RUN.md clone/etranger
    # ne lance plus de commande chez la victime. Opt-in mono-poste de confiance : env AUTOWIN_TRUST_REPLAY=1.
    # (Le blocage open/red reste actif meme non-owned : la securite de cloture n'est pas desarmee, seul le rejeu l'est.)
    $mayReplay = ($owned -or ($env:AUTOWIN_TRUST_REPLAY -eq '1'))
    $statusLine = $head | Where-Object { $_ -match '^\s*status:' } | Select-Object -First 1
    if (-not $statusLine) { continue }
    $status = ($statusLine -replace '^\s*status:\s*', '').Trim().ToLower()

    if ($status -eq 'open' -or $status -eq 'red') {
        $bad += ($d.Name + ' (status: ' + $status + ')')
        continue
    }
    if ($status -ne 'green') { continue }

    # GREEN : verifier une fois par transition. v3.1 : le marqueur ne vaut que s'il est POSTERIEUR au
    # dernier evenement de travail — un event "unit=" apres le marqueur = run rouvert -> re-verifier.
    $lastVerified = -1; $lastEvent = -1
    for ($i = 0; $i -lt $all.Count; $i++) {
        # marqueur = la ligne ENTIERE "[ts] GATE-VERIFIED" (telle qu'apposee par ce hook) — une ligne de
        # Journal qui MENTIONNE le mot en prose n'est pas un marqueur
        if ($all[$i] -match '^\s*\[[^\]]*\]\s*GATE-VERIFIED\s*$') { $lastVerified = $i }
        elseif ($all[$i] -match '^\s*\[[^\]]*\]\s*unit=') { $lastEvent = $i }
    }
    if ($lastVerified -gt $lastEvent) { continue }

    $regimeLine = $head | Where-Object { $_ -match '^\s*regime:' } | Select-Object -First 1
    $regime = if ($regimeLine) { ($regimeLine -replace '^\s*regime:\s*', '').Trim().ToLower() } else { 'standard' }
    $failures = @()

    # (a) REJEU du signal-cmd (regimes standard/critical, prefixe whiteliste)
    if ($regime -ne 'disposable') {
        $cmdLine = $head | Where-Object { $_ -match '^\s*signal-cmd:' } | Select-Object -First 1
        if ($cmdLine) {
            $cmd = ($cmdLine -replace '^\s*signal-cmd:\s*', '').Trim()
            # fix (failles scout 2026-06-18, ALLOWLIST) : un signal-cmd present doit PROUVER (runner/script) ;
            # sinon (cmd /c exit 0, "exit 0", call exit 0, echo...) = ne prouve rien -> BLOCK (non-disposable).
            if (-not (Test-MeaningfulProof $cmd)) {
                $failures += ('signal-cmd ne PROUVE rien (ni runner test/build ni script .ps1/.bat/.cmd/.py/.js) : ' + $cmd)
            }
            $white = $false
            foreach ($p in $replayWhitelist) { if ($cmd -match ('(?i)^' + [regex]::Escape($p) + '(\s|$)')) { $white = $true; break } }   # fix (failles scout) : word-boundary -> 'dotnet testxyz' ne matche plus
            if ($white -and $mayReplay) {
                $rc = Invoke-GateCmd $cmd
                if ($rc -ne 0) {
                    $tag = ''
                    if ($rc -eq 124) { $tag = ' TIMEOUT>' + $replayTimeoutMs + 'ms' }
                    $failures += ('REJEU signal-cmd ECHOUE (exit ' + $rc + $tag + '): ' + $cmd)
                }
            }
        }
    }

    # (b) CHECKS (lecons promues en code) — EXECUTES seulement si rejeu autorise (fix securite : un check d'un
    # RUN non-owned/legacy n'est PAS execute -> RCE-by-clone ferme ; la presence sert encore a (d) critical).
    $checkLines = $all | Where-Object { $_ -match '^\s*check:\s*\S' }
    if ($mayReplay) {
        foreach ($cl in $checkLines) {
            $c = ($cl -replace '^\s*check:\s*', '').Trim()
            $rc = Invoke-GateCmd $c
            if ($rc -ne 0) {
                $tag = ''
                if ($rc -eq 124) { $tag = ' TIMEOUT>' + $replayTimeoutMs + 'ms' }
                $failures += ('CHECK ECHOUE (exit ' + $rc + $tag + '): ' + $c)
            }
        }
    }

    # (c) ANTI-FIXATION : decision engagee sans >=3 options scorees (hors disposable)
    if ($regime -ne 'disposable') {
        # Motif sans non-ASCII (PS5.1 lit ce fichier en ANSI si pas de BOM) : couvre Decision / Décision / mojibake
        # fix #2 (boucle kaizen 2026-06-18) : un Decision PLACEHOLDER du scaffold (valeur commencant par '<',
        # ex "Décision: <laquelle et pourquoi>") ne compte PAS — seule une decision REELLEMENT engagee arme
        # l'anti-fixation. Evite le faux-BLOCK d'un fix mono-defaut qui a garde le scaffold du template.
        $hasDecision = ($all | Where-Object { $_ -match '^\s*D\S{0,2}cision\s*:\s*[^<\s]' })
        if ($hasDecision) {
            # v3.1 : ancre — seules des lignes d'OPTION comptent ("- ... score: 78"), pas de la prose
            $optCount = @($all | Where-Object { $_ -match '^\s*([-*]|\d+[.)]).*\bscore\s*:\s*\d' }).Count
            if ($optCount -lt 3) { $failures += ('ANTI-FIXATION: decision engagee avec ' + $optCount + ' option(s) scoree(s) (<3)') }
        }
    }

    # (d) CRITICAL = preuve hors-modele OBLIGATOIRE (fix boucle kaizen 2026-06-18). Sans signal-cmd whiteliste
    # NI check: NI header signal-attestable: -> le green critical s'auto-certifie (faux-green sur le regime
    # irreversible, contre ENGINE Ch.2). On BLOQUE ; l'humain ajoute un signal ou clot en degraded-closed.
    if ($regime -eq 'critical') {
        $cmdL2 = $head | Where-Object { $_ -match '^\s*signal-cmd:' } | Select-Object -First 1
        $cmdMeaningful = $false
        if ($cmdL2) { $cc2 = ($cmdL2 -replace '^\s*signal-cmd:\s*', '').Trim(); $cmdMeaningful = (Test-MeaningfulProof $cc2) }
        # fix (failles scout 2026-06-18) : un check ne compte comme PREUVE critical que s'il est MEANINGFUL
        # (un 'check: cmd /c exit 0' vacant ne certifie plus un green critical).
        $hasMeaningfulCheck = $false
        foreach ($cl in $checkLines) { if (Test-MeaningfulProof (($cl -replace '^\s*check:\s*', '').Trim())) { $hasMeaningfulCheck = $true; break } }
        $hasAttest = [bool]($head | Where-Object { $_ -match '^\s*signal-attestable:\s*\S' })
        if (-not ($cmdMeaningful -or $hasMeaningfulCheck -or $hasAttest)) {
            $failures += 'CRITICAL sans preuve hors-modele MEANINGFUL (signal-cmd/check = runner test/build ou script, ou signal-attestable: requis)'
        }
    }

    if ($failures.Count -gt 0) {
        $bad += ($d.Name + ' (green NON VERIFIE -> ' + ($failures -join ' ; ') + ')')
    } else {
        $stamp = '[' + (Get-Date -Format 'yyyy-MM-dd HH:mm') + '] GATE-VERIFIED'
        Add-Content -Path $run -Value $stamp -Encoding utf8
    }
}

if ($bad.Count -eq 0) { exit 0 }

$counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
# v3.1 : telemetrie ATTRIBUABLE — quel run a bloque et pourquoi, pas juste un compteur
# v3.2.1 (kaizen 2026-06-17) : + session => attribution cross-session correcte pour kaizen-detect
$entry = (@{ ts = (Get-Date -Format o); gate = 'stop'; blocked = $bad.Count; session = $sid; file = (($bad[0] -split ' \(')[0]); details = $bad } | ConvertTo-Json -Compress)
Add-Content -Path $counters -Value $entry -Encoding utf8

$reason = 'STOP-GATE v3 : ' + ($bad -join ' | ') + '. Un done sans VERT VERIFIE ne passe pas. Options : (1) corriger puis re-verifier reellement le signal ; (2) continuer le travail ; (3) clore honnetement en degraded-closed avec USER-OK trace au Journal. Ne maquille JAMAIS un status.'
@{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress
