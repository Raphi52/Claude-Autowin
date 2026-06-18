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
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
if ($j.stop_hook_active) { exit 0 }

$cwd = [string]$j.cwd
if (-not $cwd -or -not (Test-Path $cwd)) { exit 0 }

$replayWhitelist = @('dotnet test', 'dotnet build', 'cmd /c', 'powershell -NoProfile -File', 'powershell -File')

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
    $all = @(Get-Content $run -ErrorAction SilentlyContinue)
    if (-not $all) { continue }
    $head = $all | Select-Object -First 14
    if (($head | Where-Object { $_ -match '^\s*gate:\s*off\s*$' })) { continue }
    # v3.2 — n'enforce QUE les runs de CETTE session : a moi si sous Audit\workspaces\<mon id>\ OU header
    # "session: <mon id>". Sinon (autre session / legacy non-stampe) => IGNORE. Filet : pas de session_id => legacy.
    if ($sid) {
        $underMySession = ($d.FullName -like ('*\Audit\workspaces\' + $sid + '\*'))
        $sessLine = $head | Where-Object { $_ -match '^\s*session:\s*\S' } | Select-Object -First 1
        $runSession = if ($sessLine) { ($sessLine -replace '^\s*session:\s*', '').Trim() } else { '' }
        if (-not ($underMySession -or ($runSession -and $runSession -eq $sid))) { continue }
    }
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
            $white = $false
            foreach ($p in $replayWhitelist) { if ($cmd.StartsWith($p)) { $white = $true; break } }
            if ($white) {
                $rc = Invoke-GateCmd $cmd
                if ($rc -ne 0) {
                    $tag = ''
                    if ($rc -eq 124) { $tag = ' TIMEOUT>' + $replayTimeoutMs + 'ms' }
                    $failures += ('REJEU signal-cmd ECHOUE (exit ' + $rc + $tag + '): ' + $cmd)
                }
            }
        }
    }

    # (b) CHECKS (lecons promues en code) — toujours, tous regimes
    $checkLines = $all | Where-Object { $_ -match '^\s*check:\s*\S' }
    foreach ($cl in $checkLines) {
        $c = ($cl -replace '^\s*check:\s*', '').Trim()
        $rc = Invoke-GateCmd $c
        if ($rc -ne 0) {
            $tag = ''
            if ($rc -eq 124) { $tag = ' TIMEOUT>' + $replayTimeoutMs + 'ms' }
            $failures += ('CHECK ECHOUE (exit ' + $rc + $tag + '): ' + $c)
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
        $cmdWhite = $false
        if ($cmdL2) { $cc2 = ($cmdL2 -replace '^\s*signal-cmd:\s*', '').Trim(); foreach ($pp in $replayWhitelist) { if ($cc2.StartsWith($pp)) { $cmdWhite = $true; break } } }
        $hasAttest = [bool]($head | Where-Object { $_ -match '^\s*signal-attestable:\s*\S' })
        if (-not ($cmdWhite -or ($checkLines.Count -gt 0) -or $hasAttest)) {
            $failures += 'CRITICAL sans preuve hors-modele (signal-cmd whiteliste, check:, ou signal-attestable: requis)'
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
