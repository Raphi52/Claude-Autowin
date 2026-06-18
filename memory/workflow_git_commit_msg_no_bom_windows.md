---
name: workflow_git_commit_msg_no_bom_windows
description: "Message de commit git multi-ligne/accentué sur Windows → Bash heredoc, JAMAIS PowerShell Out-File -Encoding utf8 (ajoute un BOM dans le sujet)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c94cd422-c5f3-49ff-91d1-41b9f24cec59
---

Pour un message de commit git multi-ligne ou accentué sur cette machine Windows : écrire le fichier
de message via **Bash heredoc** (`cat > f <<'EOF' ... EOF` → UTF-8 SANS BOM) puis `git commit -F f`.

**Why:** `Out-File -Encoding utf8` en PowerShell 5.1 préfixe un **BOM** (EF BB BF) ; avec `git commit -F`,
ce BOM atterrit EN TÊTE DU SUJET du commit (visible `﻿Audit…` sur GitHub). Vécu 2026-06-16 : a forcé un
`--amend`. Alternative PS si pas de Bash : `[System.IO.File]::WriteAllText($path,$msg)` (UTF-8 no BOM).

**How to apply:**
- Vérifier l'absence de BOM par hexdump du sujet : `git log --format=%s -1 | od -An -tx1 | head -1`
  → doit commencer par les octets du 1er caractère, PAS `ef bb bf`.
- PIÈGE de vérif : `$s = git log --format=%s -1` en PowerShell **mange** un BOM en tête lors de la
  capture du flux natif → un test d'octets sur `$s` dit faussement « pas de BOM ». Tester via pipe
  direct (`git log ... | Format-Hex`) ou en Bash (`od`/`head -c`), pas via une variable PS.
- Hook protecteur Remove-Item : un `Remove-Item` dans le MÊME bloc qu'un here-string contenant un
  motif type chemin (`/api`) peut être bloqué (faux positif) → séparer le nettoyage du temp.

Autres pièges PS5.1 connexes : em-dash, ternaire, `Start-Process -Redirect` (mêmes précautions encodage/syntaxe).
