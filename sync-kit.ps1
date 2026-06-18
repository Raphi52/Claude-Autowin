# sync-kit.ps1 — propage le kit LIVE (~/.claude) vers le PACKAGE redistribuable (Desktop\Autowin),
# en PORTABILISANT au passage (chemin machine-specifique -> relatif ; le glob du stop-gate fait la
# decouverte reelle). LIVE = source de verite. Repare la derive package-en-retard en une commande.
# EXCLUS (sync MANUEL, par design) :
#   - CONSTITUTION.md = CLAUDE.md SANS la section "## Local (this machine)" -> sync partiel a la main.
#   - hooks/settings-snippet.json vs ~/.claude/settings.json -> a reconcilier a la main.
#   - skills/_pipeline-audit/ = historique machine (LEDGER), pas distribue.
#   - memory/ = sous-ensemble CURE A LA MAIN (starter kit-generique) -> peut deriver des fiches live ;
#       rafraichir manuellement (pas dans $files). Les fiches CARDINALES vivent dans CONSTITUTION.md, pas ici.
# Usage : .\sync-kit.ps1            (propage) ; .\sync-kit.ps1 -Check   (diff seulement, n'ecrit rien)
param([switch]$Check)
$ErrorActionPreference = 'Stop'
$live = Join-Path $env:USERPROFILE '.claude'
$pkg = Join-Path $env:USERPROFILE 'Desktop\Autowin'
$enc = New-Object System.Text.UTF8Encoding($false)
$files = @(
  'skills\scout\SKILL.md', 'skills\frame\SKILL.md', 'skills\terrain\SKILL.md', 'skills\judge\SKILL.md',
  'skills\build\SKILL.md', 'skills\kaizen\SKILL.md',
  'skills\_engine\ENGINE.md', 'skills\_engine\RUN-template.md',
  'hooks\anti-flaky.ps1', 'hooks\stop-gate.ps1', 'hooks\fix-gate.ps1', 'hooks\advisory-guard.ps1',
  'hooks\kaizen-detect.ps1', 'hooks\kaizen-nudge.ps1', 'hooks\kaizen-revert-log.ps1', 'hooks\test-hooks.ps1',
  'hooks\model-tier.ps1', 'hooks\judge-nudge.ps1', 'hooks\precompact-runcheck.ps1', 'hooks\thinking-mode.ps1', 'hooks\session-inject.ps1',
  'output-styles\concis-structure.md',
  'workflows\improve-from-telemetry.js'
)
$changed = 0; $drift = 0
foreach ($rel in $files) {
  $src = Join-Path $live $rel; $dst = Join-Path $pkg $rel
  if (-not (Test-Path $src)) { Write-Host "  ! source absente: $rel" -ForegroundColor Yellow; continue }
  $content = [IO.File]::ReadAllText($src).Replace('C:\Code RIG\Audit\workspaces', 'Audit\workspaces').Replace($live, '%USERPROFILE%\.claude')
  $old = if (Test-Path $dst) { [IO.File]::ReadAllText($dst) } else { '' }
  if ($content -ne $old) {
    $drift++
    if ($Check) { Write-Host "  DRIFT : $rel" -ForegroundColor Yellow }
    else {
      $dstDir = Split-Path $dst -Parent
      if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
      [IO.File]::WriteAllText($dst, $content, $enc); Write-Host "  synced: $rel" -ForegroundColor Green; $changed++
    }
  }
  else { Write-Host "  ok    : $rel" }
}
Write-Host ""
if ($Check) { Write-Host "$drift fichier(s) en derive (rien ecrit). Lance sans -Check pour propager." }
else { Write-Host "$changed fichier(s) propage(s) live->package (portabilise)." }
Write-Host "EXCLUS (sync manuel) : CONSTITUTION.md, hooks/settings-snippet.json, skills/_pipeline-audit/."

# --- Detection hors-manifeste (stray files) ---
# Scanne les dossiers geres (hooks/*.ps1 + skills/*/SKILL.md) et WARN pour tout fichier
# present dans LIVE mais absent du manifeste $files. N'auto-ajoute rien.
$manifestSet = @{}
foreach ($rel in $files) { $manifestSet[$rel.ToLower()] = $true }

$excludedRelPrefixes = @('skills\_pipeline-audit\')
$excludedFiles = @('hooks\settings-snippet.json')

$strayCount = 0

# Scan hooks/*.ps1
$hooksLiveDir = Join-Path $live 'hooks'
if (Test-Path $hooksLiveDir) {
  foreach ($f in (Get-ChildItem -Path $hooksLiveDir -Filter '*.ps1' -File)) {
    $rel = 'hooks\' + $f.Name
    if (-not $manifestSet.ContainsKey($rel.ToLower())) {
      Write-Host "  WARN hors-manifeste: $rel" -ForegroundColor Cyan
      $strayCount++
    }
  }
}

# Scan skills/*/SKILL.md (un niveau de sous-dossier)
$skillsLiveDir = Join-Path $live 'skills'
if (Test-Path $skillsLiveDir) {
  foreach ($skillDir in (Get-ChildItem -Path $skillsLiveDir -Directory)) {
    $dirName = $skillDir.Name
    # Exclure _pipeline-audit
    $dirRelPrefix = 'skills\' + $dirName + '\'
    $skip = $false
    foreach ($excl in $excludedRelPrefixes) {
      if ($dirRelPrefix.ToLower().StartsWith($excl.ToLower())) { $skip = $true; break }
    }
    if ($skip) { continue }
    $skillMdRel = 'skills\' + $dirName + '\SKILL.md'
    if (-not $manifestSet.ContainsKey($skillMdRel.ToLower())) {
      $skillMdPath = Join-Path $skillDir.FullName 'SKILL.md'
      if (Test-Path $skillMdPath) {
        Write-Host "  WARN hors-manifeste: $skillMdRel" -ForegroundColor Cyan
        $strayCount++
      }
    }
  }
}

if ($strayCount -gt 0) {
  Write-Host ""
  Write-Host "$strayCount fichier(s) hors-manifeste detecte(s) dans LIVE -> ajoutez-les au tableau files dans sync-kit.ps1 si necessaire." -ForegroundColor Cyan
}
