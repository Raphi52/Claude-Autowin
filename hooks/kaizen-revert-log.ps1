# kaizen-revert-log.ps1 — PostToolUse Write|Edit : DÉTECTE un REVERT (retour d'un fichier code à un état
# antérieur de la session) et le logge dans gate-counters.jsonl avec gate='revert'. C'est le 2e canal de
# signal du kaizen : un revert = trace OBJECTIVE et AUTOMATIQUE d'un fix raté (ex. mes 4 fixes capture
# aveugles = 4 reverts), capte la classe d'échec que les gates ne voient pas (erreurs de diagnostic).
# N'ÉCRIT que la télémétrie (append-only), jamais de code. Ne bloque rien.
$ErrorActionPreference = 'SilentlyContinue'
try {
    $j = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $fp = [string]$j.tool_input.file_path
    $sid = [string]$j.session_id
    if (-not $fp -or -not $sid -or -not (Test-Path $fp)) { exit 0 }
    # Mêmes extensions code que fix-gate (éviter le bruit doc/RUN.md qui churn beaucoup).
    $ext = [System.IO.Path]::GetExtension($fp).ToLower()
    if (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js', '.xaml') -notcontains $ext) { exit 0 }

    # fix #12 (failles scout 2026-06-18) : hash sur les BYTES bruts (pas ReadAllText -> UTF8.GetBytes, qui
    # depend de l'encodage systeme) -> identite stable cross-encodage/outil pour les fichiers code non-ASCII.
    $sha = [Security.Cryptography.SHA1]::Create()
    $hash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($fp))).Replace('-', '')

    # Historique des hashes par fichier (chronologique) pour cette session.
    $store = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-kaizen-revert-$sid.jsonl")
    $prior = @()
    if (Test-Path $store) {
        $prior = @(Get-Content $store | ForEach-Object { try { $_ | ConvertFrom-Json } catch { } } |
            Where-Object { $_.file -eq $fp } | ForEach-Object { [string]$_.hash })
    }

    # REVERT = le contenu actuel égale un état ANTÉRIEUR connu, MAIS pas le tout dernier (sinon = re-save no-op).
    $isRevert = $false
    if ($prior.Count -ge 1) {
        $last = $prior[$prior.Count - 1]
        if ($hash -ne $last -and ($prior -contains $hash)) { $isRevert = $true }
    }

    # Tracer ce hash dans l'historique (toujours).
    (@{ file = $fp; hash = $hash } | ConvertTo-Json -Compress) | Add-Content -Path $store -Encoding UTF8

    if ($isRevert) {
        $counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
        $ts = (Get-Date).ToString('o')
        (@{ gate = 'revert'; file = $fp; session = $sid; ts = $ts } | ConvertTo-Json -Compress) |
            Add-Content -Path $counters -Encoding UTF8
    }
}
catch { exit 0 }
