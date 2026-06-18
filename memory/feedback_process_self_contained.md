---
name: feedback-process-self-contained
description: "Le système de travail (skills/ENGINE/kit) doit être 100% autonome — aucune délégation à un plugin tiers ; absorber la mécanique utile dans ENGINE, pas la référencer"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 533a942b-93e8-4fd9-9743-f371ee517677
---

POST 2026-06-10 — directive user : « enlève complètement superpowers de la boucle et refais à la main et
incorpore dans notre process ce pour quoi il était important. » Le plugin superpowers a été retiré du
pipeline ; sa valeur (mécanique d'exécution : décomposer-faire-vérifier, rouge-d'abord/TDD, dispatch
parallèle, cadence anti-régression, debugging systématique) a été réécrite from scratch dans
`~/.claude/skills/_engine/ENGINE.md` **Ch.4 — BUILD** (consulté par l'exécutant, aucune skill ne se
déclenche à la phase build).

**Why** : un kit déployé sur tous les postes de la boîte ne doit dépendre que de lui-même — une référence
tierce = handoff pendable sur les postes où le plugin manque + dérive de version hors de notre contrôle.

**How to apply** : AU MOMENT d'écrire « delegate to / voir skill X » dans une skill ou un doc du système →
si X n'est pas DANS le kit, réécrire la mécanique dans ENGINE (chapitre dédié) et pointer le chapitre.
Garde-fou exécutable : `verify-selfcontained.ps1` (workspace build-mechanics) greppe skills/ + kit pour
toute réf superpowers/writing-plans/subagent-driven-development/test-driven-development → exit 1 si trouvée.
Lié : [[workflow_closure_authority]], [[feedback_corrections_evaporate]].
