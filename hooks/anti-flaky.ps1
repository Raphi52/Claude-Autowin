# anti-flaky.ps1 — hook PreToolUse (Write|Edit) : tarit la flakiness mecanique a la SOURCE.
# Refuse un diff de CODE introduisant un sleep brut / timing aveugle :
#   - Start-Sleep -Seconds N / -s N / N positionnel (N >= 2)   - Start-Sleep -Milliseconds >= 1000
#   - Thread.Sleep(>= 4 chiffres)       - Task.Delay(>= 4 chiffres)
# Limite connue (acceptee, v1.1) : un sleep via variable ($n = 5; Start-Sleep $n) echappe a l'analyse statique.
# Echappatoire (= la regle "justifier par ecrit tout sleep > 1s", executee par le harnais) :
#   la ligne fautive contient  sleep-ok: <justification>
# Ne s'applique qu'aux fichiers code (.ps1 .psm1 .cs .py .ts .js) — les .md/.sql/doc passent.
# Le bon pattern reste : poll-jusqu'a-condition avec plafond + sleeps courts (<= 500ms).

$ErrorActionPreference = 'SilentlyContinue'
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
if ($null -eq $j) { exit 0 }

$fp = [string]$j.tool_input.file_path
if (-not $fp) { exit 0 }
$ext = [System.IO.Path]::GetExtension($fp).ToLower()
if (-not (@('.ps1', '.psm1', '.cs', '.py', '.ts', '.js') -contains $ext)) { exit 0 }

# Texte NOUVEAU introduit : Write -> content ; Edit -> new_string
$text = [string]$j.tool_input.content
if (-not $text) { $text = [string]$j.tool_input.new_string }
if (-not $text) { exit 0 }

$patterns = @(
    'Start-Sleep\s+-Seconds\s+([2-9]\b|\d{2,})',
    'Start-Sleep\s+-s\s+([2-9]\b|\d{2,})',
    'Start-Sleep\s+([2-9]\b|\d{2,})',
    'Start-Sleep\s+-Milliseconds\s+\d{4,}',
    'Start-Sleep\s+(-Seconds\s+)?[1-9]\d*\.\d',
    'Start-Sleep\s*\([^)]*\d',
    'Thread\.Sleep\(\s*[\d_]{4,}',
    'Task\.Delay\(\s*[\d_]{4,}',
    '\bsleep\s+([2-9]\b|\d{2,})',
    '\]?::Sleep\(\s*[\d_]{4,}',
    '(time|asyncio)\.sleep\(\s*([2-9]|\d{2,})',
    'setTimeout\([^,]+,\s*[\d_]{4,}'
)

$offenders = @()
foreach ($line in ($text -split "`n")) {
    if ($line -match 'sleep-ok:') { continue }
    foreach ($p in $patterns) {
        if ($line -match $p) { $offenders += $line.Trim(); break }
    }
}

if ($offenders.Count -eq 0) { exit 0 }

# Telemetrie hors-modele (P5)
$counters = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
# v1.1 : telemetrie ATTRIBUABLE — quel fichier, quelles lignes
# v1.2 (kaizen 2026-06-17) : + session_id => kaizen-detect ne compte plus les entrees d'AUTRES sessions
$entry = (@{ ts = (Get-Date -Format o); gate = 'anti-flaky'; blocked = $offenders.Count; file = $fp; session = [string]$j.session_id; sample = @($offenders | Select-Object -First 2) } | ConvertTo-Json -Compress)
Add-Content -Path $counters -Value $entry -Encoding utf8

$sample = ($offenders | Select-Object -First 3) -join ' | '
$reason = 'ANTI-FLAKY : sleep/timing brut introduit dans du code -> ' + $sample + '. Remplace par un poll-jusqu''a-condition (plafond 30-60s, sleep <= 500ms comme frequence). CAS LEGITIME FREQUENT : attente de SETTLE UI apres une action SANS signal de fin a poller (rendu WPF post-InitializeAsync, driver FlaUI/legacy) -> n''invente PAS un faux poll, annote la ligne : sleep-ok: <raison>. Sinon, sleep long justifie autrement : sleep-ok: <justification ecrite>.'
@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = $reason } } | ConvertTo-Json -Depth 5 -Compress
