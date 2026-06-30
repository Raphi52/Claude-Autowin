# precompact-runcheck.ps1 — PreCompact: warn if THIS session still has open RUN.md files, so ## Reprise /
# Journal get updated before the context is summarized away.
$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }
$sid = [string]$j.session_id
$cwd = [string]$j.cwd; if (-not $cwd) { $cwd = [string]$PWD }
# RUN root: DEFAULT <userprofile>\.claude\runs (user-global). The shared global root is scanned ONLY at my
# session subtree <root>\<sid> (never its top-level — cross-session). + LEGACY per-project $cwd\Audit\workspaces.
$runRoot = if ($env:AUTOWIN_RUN_ROOT -and $env:AUTOWIN_RUN_ROOT.Trim()) { $env:AUTOWIN_RUN_ROOT.Trim() } else { Join-Path $env:USERPROFILE '.claude\runs' }
$dirs = @()
if ($sid) { $dirs += (Join-Path $runRoot $sid) }
$legacy = Join-Path $cwd 'Audit\workspaces'
if (Test-Path $legacy) { $dirs += $(if ($sid) { Join-Path $legacy $sid } else { $legacy }) }
$open = @()
foreach ($d in $dirs) {
    if (Test-Path $d) {
        # Scan the first 14 lines (aligned with stop-gate's header window) — a `status:` pushed past line 3 by a
        # preamble/comment was previously MISSED here while stop-gate still blocked it (kit-coherence N3).
        $open += @(Get-ChildItem $d -Filter RUN.md -Recurse -ErrorAction SilentlyContinue | Where-Object { (Get-Content $_.FullName -TotalCount 14) -match 'status:\s*open' })
    }
}
$open = @($open | Sort-Object FullName -Unique)
if ($open.Count) { @{ systemMessage = ('PreCompact: ' + $open.Count + ' open RUN.md in THIS session -- update ## Reprise/Journal before losing context.') } | ConvertTo-Json -Compress }
