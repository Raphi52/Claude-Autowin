# precompact-runcheck.ps1 — PreCompact: warn if THIS session still has open RUN.md files, so ## Reprise /
# Journal get updated before the context is summarized away.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$sid = [string]$j.session_id
$cwd = [string]$j.cwd; if (-not $cwd) { $cwd = [string]$PWD }
# Workspaces root(s): default cwd\Audit\workspaces + optional relocated root (env AUTOWIN_RUN_ROOT). ADDITIVE.
$bases = @((Join-Path $cwd 'Audit\workspaces'))
if ($env:AUTOWIN_RUN_ROOT -and $env:AUTOWIN_RUN_ROOT.Trim()) { $bases += $env:AUTOWIN_RUN_ROOT.Trim() }
$open = @()
foreach ($base in $bases) {
    $d = if ($sid) { Join-Path $base $sid } else { $base }
    if (Test-Path $d) {
        $open += @(Get-ChildItem $d -Filter RUN.md -Recurse -ErrorAction SilentlyContinue | Where-Object { (Get-Content $_.FullName -TotalCount 3) -match 'status:\s*open' })
    }
}
$open = @($open | Sort-Object FullName -Unique)
if ($open.Count) { @{ systemMessage = ('PreCompact: ' + $open.Count + ' open RUN.md in THIS session -- update ## Reprise/Journal before losing context.') } | ConvertTo-Json -Compress }
