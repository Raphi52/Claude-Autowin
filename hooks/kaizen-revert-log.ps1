# kaizen-revert-log.ps1 — PostToolUse (Write|Edit): DETECTS a REVERT (a code file returning to an EARLIER
# state in the session) and logs it to gate-counters.jsonl with gate='revert'. The 2nd kaizen signal channel:
# a revert = an OBJECTIVE, AUTOMATIC trace of a failed fix (e.g. 4 blind capture-fixes = 4 reverts), catching
# the failure class the gates don't see (diagnosis errors). WRITES telemetry only (append-only), never code. Blocks nothing.
$ErrorActionPreference = 'SilentlyContinue'
try {
    $j = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $fp = [string]$j.tool_input.file_path
    $sid = [string]$j.session_id
    if (-not $fp -or -not $sid -or -not (Test-Path $fp)) { exit 0 }
    # Same code extensions as fix-gate (avoid the doc/RUN.md noise that churns a lot).
    $ext = [System.IO.Path]::GetExtension($fp).ToLower()
    if (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js', '.xaml') -notcontains $ext) { exit 0 }

    # Hash on RAW BYTES (not ReadAllText -> UTF8.GetBytes, which depends on the system encoding) -> stable
    # identity cross-encoding/tool for non-ASCII code files.
    $sha = [Security.Cryptography.SHA1]::Create()
    $hash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($fp))).Replace('-', '')

    # Per-file hash history (chronological) for this session.
    $store = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-kaizen-revert-$sid.jsonl")
    $prior = @()
    if (Test-Path $store) {
        $prior = @(Get-Content $store | ForEach-Object { try { $_ | ConvertFrom-Json } catch { } } |
            Where-Object { $_.file -eq $fp } | ForEach-Object { [string]$_.hash })
    }

    # REVERT = current content equals a KNOWN earlier state, but NOT the latest (else = a no-op re-save).
    $isRevert = $false
    if ($prior.Count -ge 1) {
        $last = $prior[$prior.Count - 1]
        if ($hash -ne $last -and ($prior -contains $hash)) { $isRevert = $true }
    }

    # Record this hash in the history (always).
    (@{ file = $fp; hash = $hash } | ConvertTo-Json -Compress) | Add-Content -Path $store -Encoding UTF8

    if ($isRevert) {
        $counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
        $ts = (Get-Date).ToString('o')
        (@{ gate = 'revert'; file = $fp; session = $sid; ts = $ts } | ConvertTo-Json -Compress) |
            Add-Content -Path $counters -Encoding UTF8
    }
}
catch { exit 0 }
