---
name: workflow_runmd_signalcmd_form
description: "signal-cmd d'un RUN.md doit être `powershell -NoProfile -File \"...ps1\"`, JAMAIS la forme PowerShell `& \"...ps1\"` — le stop-gate rejoue sous cmd.exe."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ae4d3ceb-cc88-4ac0-a901-c577f1b43871
---

Le `signal-cmd:` d'un RUN.md (rejoué par `stop-gate.ps1` comme autorité de clôture hors-modèle) doit utiliser un préfixe whitelisté qui tourne **sous `cmd.exe /c`** : pour un script PowerShell → `powershell -NoProfile -File "C:\chemin avec espaces\verify.ps1"`. **NE PAS** utiliser la forme call-operator PowerShell `& "...ps1"`.

**Why:** le hook rejoue via `ProcessStartInfo('cmd.exe', '/c ' + $cmd + ' >NUL 2>&1')` (stop-gate.ps1 ligne 41, `Invoke-GateCmd`). Sous **cmd**, `&` est un séparateur de commandes et cmd ne sait pas exécuter un `.ps1` directement → exit 1 → BLOCK, alors que le travail est réellement vert. La whitelist inclut pourtant `& "` (utile pour un `.exe` à chemin quoté, PAS un `.ps1`), ce qui induit en erreur. Vérifié empiriquement 2026-06-14 : forme `& "...ps1"` → exit 1 ; forme `powershell -NoProfile -File "...ps1"` → exit 0 (whitelist hook ligne 33).

**How to apply:** avant de clore un RUN.md en `green`, rejouer le signal-cmd EXACTEMENT comme le gate : `Invoke-GateCmd` réplique (cmd.exe /c, UseShellExecute=$false) en lisant la ligne `signal-cmd:` réelle du fichier → exiger exit 0. Si verifier = .ps1, préfixe `powershell -NoProfile -File`. Préfixes whitelistés du gate : `dotnet test`, `dotnet build`, `cmd /c`, `powershell -NoProfile -File`, `powershell -File`, `& "`. Lié à [[workflow_closure_authority]] et [[workflow_loop_fix_verify_default]].
