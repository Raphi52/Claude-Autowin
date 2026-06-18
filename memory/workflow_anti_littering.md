---
name: workflow_anti_littering
description: "Hygiène disque — tracke ce que tu crées, supprime le transitoire en fin de tâche, garde le livrable + le journal de reprise ; jamais de suppression hors de ton scratch sans confirmation"
metadata:
  type: feedback
---

# Hygiène disque — anti-littering

## Principe
Tracke les fichiers que tu crées pendant une tâche. En fin de tâche :
- supprime le **transitoire** : scratch, sorties intermédiaires, scripts jetables, logs de run temporaires ;
- ne garde que le **livrable** + le **journal de reprise** (le `## Reprise` du RUN.md) ;
- **propose** le nettoyage du scratch (ne le fais pas en douce si l'utilisateur pourrait vouloir inspecter).

## Garde-fou destructif
Jamais de suppression **hors de ton propre scratch** sans confirmation explicite (`rm -Recurse`,
`Stop-Process`, `git reset --hard`, écrasement d'un dossier système). Les livrables de code vont dans le
repo concerné, commités uniquement sur demande explicite.
