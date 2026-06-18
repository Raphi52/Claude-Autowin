# kaizen-detect.ps1 — détecteur DÉTERMINISTE de patterns d'échec RÉCURRENTS (substrat de l'auto-propose).
# Lit ~/.claude/gate-counters.jsonl (loggé par anti-flaky/fix-gate/stop-gate) et sort en JSON les patterns
# qui RÉCURRENT (même gate, ou même gate+fichier, >= seuil) sur une fenêtre. Le hook Stop l'appelle pour
# décider s'il NUDGE vers l'audit kaizen (judge Mode B). NE PROPOSE NI N'ÉCRIT RIEN — il détecte, point.
# Anti-bruit : ignore les sessions de test (session commençant par 'test-').
param([int]$MinCount = 3, [int]$SinceDays = 0)   # SinceDays 0 = tout l'historique

$ErrorActionPreference = 'SilentlyContinue'
$f = Join-Path $env:USERPROFILE '.claude\gate-counters.jsonl'
if (-not (Test-Path $f)) { '[]'; exit 0 }
$cutoff = if ($SinceDays -gt 0) { (Get-Date).AddDays(-$SinceDays) } else { [datetime]::MinValue }

$rows = @()
foreach ($line in (Get-Content $f)) {
    if (-not $line.Trim()) { continue }
    try { $o = $line | ConvertFrom-Json } catch { continue }
    $ts = [datetime]::MinValue; try { $ts = [datetime]$o.ts } catch { }
    if ($ts -lt $cutoff) { continue }
    if (([string]$o.session) -match '^test-') { continue }   # anti-bruit : runs de test du gate lui-même
    if (([string]$o.file) -like 'C:\x\*' -or ([string]$o.file) -like 'C:\tmp\*') { continue }  # anti-bruit : fixtures de test (C:\x\, C:\tmp\ — harnais test-hooks)
    # anti-bruit : entrees INATTRIBUABLES (ni file ni session) = ere de dev/test du gate lui-meme, pas une
    # decision reelle -> inadmissibles pour conclure a une habitude (audit kaizen 2026-06-16).
    if (-not ([string]$o.file) -and -not ([string]$o.session)) { continue }
    $rows += [pscustomobject]@{ gate = [string]$o.gate; file = [string]$o.file; ts = $ts }
}

# Dedup RETRIES : 2 events du meme (gate, file) a < 5 min = UNE decision (un edit re-tente), pas N.
# Sinon un fix re-tente 3x gonfle le compteur vers un faux "habitude systemique" (audit kaizen 2026-06-16).
$rows = @($rows | Sort-Object gate, file, ts)
$dedup = @(); $lastKey = $null; $lastTs = $null
foreach ($r in $rows) {
    $key = "$($r.gate)|$($r.file)"
    if ($key -eq $lastKey -and $lastTs -and ($r.ts - $lastTs).TotalMinutes -lt 5) { $lastTs = $r.ts; continue }
    $dedup += $r; $lastKey = $key; $lastTs = $r.ts
}
$rows = $dedup

$patterns = @()
# Récurrence par GATE (un type d'échec qui revient globalement = habitude systémique).
foreach ($g in ($rows | Group-Object gate)) {
    if ($g.Count -ge $MinCount) {
        $patterns += [pscustomobject]@{ kind = 'gate'; gate = $g.Name; file = '';
            count = $g.Count; lastTs = (($g.Group.ts | Measure-Object -Maximum).Maximum).ToString('o');
            behavioral = (@('anti-flaky', 'fix-gate', 'revert', 'stop') -contains $g.Name) }
    }
}
# Récurrence par GATE+FICHIER (un fichier qui re-déclenche le même gate = pattern précis, très actionnable).
foreach ($gf in ($rows | Where-Object { $_.file } | Group-Object { $_.gate + '|' + $_.file })) {
    if ($gf.Count -ge $MinCount) {
        $p = $gf.Group[0]
        $patterns += [pscustomobject]@{ kind = 'gate+file'; gate = $p.gate; file = $p.file;
            count = $gf.Count; lastTs = (($gf.Group.ts | Measure-Object -Maximum).Maximum).ToString('o');
            behavioral = (@('anti-flaky', 'fix-gate', 'revert', 'stop') -contains $p.gate) }
    }
}

# Signature stable d'un pattern (pour l'anti-bruit du hook : ne pas re-nudger le déjà-traité).
foreach ($p in $patterns) { $p | Add-Member -NotePropertyName sig -NotePropertyValue ("$($p.kind):$($p.gate):$($p.file):$($p.count)") }

# -InputObject + -Compress : tableau JSON sur UNE ligne, deterministe meme vide ('[]') ou singleton ('[{...}]')
# -> capture `& detect` non ambigue (un pipe `@()|ConvertTo-Json` n'emet rien sur vide / desenroule un singleton).
$arr = @($patterns | Sort-Object count -Descending)
ConvertTo-Json -InputObject $arr -Depth 5 -Compress
