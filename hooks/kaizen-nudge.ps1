# kaizen-nudge.ps1 — hook Stop : DÉTECTE un pattern d'échec comportemental RÉCURRENT (via kaizen-detect.ps1)
# et NUDGE (non-bloquant) vers l'audit kaizen. NE BLOQUE JAMAIS (c'est stop-gate qui a l'autorité de blocage)
# et N'ÉCRIT JAMAIS le kit — il propose seulement de lancer l'audit. L'écriture reste gated humain.
# Anti-bruit : 1 nudge max / session (flag TEMP) + ledger cross-session (~/.claude/kaizen-treated.jsonl :
# ne re-nudge un pattern déjà traité que si son count a regrimpé de >= +5).
$ErrorActionPreference = 'SilentlyContinue'
try {
    $raw = [Console]::In.ReadToEnd()
    $j = $raw | ConvertFrom-Json
    $sid = [string]$j.session_id
    if (-not $sid) { exit 0 }

    # 1 nudge max / session.
    $flag = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-kaizen-nudge-$sid.flag")
    if (Test-Path $flag) { exit 0 }

    # Détection : récurrence comportementale FRAÎCHE (>=5 sur 30j, anti-flaky/fix-gate seulement).
    $detect = Join-Path $env:USERPROFILE '.claude\hooks\kaizen-detect.ps1'
    if (-not (Test-Path $detect)) { exit 0 }
    $out = (& $detect -MinCount 5 -SinceDays 30) -join "`n"   # -join : capture mono-string non ambigue
    if (-not $out) { exit 0 }
    # PS5.1 : parser dans une VARIABLE avant de filtrer (un `... | ConvertFrom-Json | Where` inline emet le
    # tableau comme UN objet non-enumere -> $_.behavioral devient un tableau truthy et stop passe le filtre).
    $parsed = $out | ConvertFrom-Json
    $patterns = @($parsed | Where-Object { $_.behavioral -and $_.kind -eq 'gate' })
    if (-not $patterns.Count) { exit 0 }
    $p = ($patterns | Sort-Object count -Descending)[0]

    # Ledger cross-session : ne pas re-nudger un pattern traité sans regain >= +5.
    $ledger = Join-Path $env:USERPROFILE '.claude\kaizen-treated.jsonl'
    if (Test-Path $ledger) {
        $prev = Get-Content $ledger | ForEach-Object { try { $_ | ConvertFrom-Json } catch { } } |
            Where-Object { $_.gate -eq $p.gate } | Sort-Object treatedCount -Descending | Select-Object -First 1
        if ($prev -and ($p.count - [int]$prev.treatedCount) -lt 5) { exit 0 }
    }

    # Poser le flag AVANT d'émettre (idempotence : un seul nudge même si le hook re-tire).
    New-Item -ItemType File -Path $flag -Force | Out-Null

    $msg = "KAIZEN -- pattern recurrent REEL : le garde-fou << $($p.gate) >> a bloque $($p.count)x (gate-counters, hors test/dev). " +
        "Assez de signal reel accumule -> lance la boucle TELEMETRY-DRIVEN : Workflow name 'improve-from-telemetry' " +
        "(elle diagnostique CES blocages reels -- faux-positif a assouplir vs vrai souci a corriger -- et propose un fix score, PROPOSE only). " +
        "Alternative : audit kaizen (judge Mode B). Rien n'est ecrit sans ton OK ; re-nudge si le pattern regagne +5."
    (@{ hookSpecificOutput = @{ hookEventName = 'Stop'; additionalContext = $msg } } | ConvertTo-Json -Depth 6 -Compress)
}
catch { exit 0 }
