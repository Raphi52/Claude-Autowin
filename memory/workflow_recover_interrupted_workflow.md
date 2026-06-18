---
name: workflow_recover_interrupted_workflow
description: "Récupérer les résultats d'un Workflow multi-agents interrompu (tokens/crash) depuis le disque"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 45ac357c-39a5-4c1f-9b47-7a38ac7d9130
---

Un `Workflow` multi-agents tué en plein vol (tokens épuisés, redémarrage app, `/model` qui tue le run) **ne perd pas** les résultats des agents qui avaient terminé : tout est sur disque, indépendant du compte connecté.

**Où** : `~/.claude/projects/<projet-sanitizé>/<sessionId>/subagents/workflows/<wf_id>/`
- `journal.jsonl` — lignes `{"type":"started"}` (tous les agents lancés) et `{"type":"result",...}` (seulement ceux ayant fini avant la coupure).
- `agent-<id>.jsonl` — transcript complet de chaque agent. **Même si le résultat n'est pas dans le journal**, le `StructuredOutput.findings` est dans le transcript de l'agent s'il a appelé l'outil avant de mourir.
- `../../workflows/scripts/<name>-<wf_id>.js` — le script du workflow persisté (consignes/paths exacts pour relancer une dimension manquante à l'identique).

**Méthode** :
1. Mapper les agents complétés : parser chaque `agent-*.jsonl`, garder ceux dont un bloc `content[].type=="tool_use"` `name=="StructuredOutput"` a un `input.findings`.
2. Identifier la dimension de chaque agent par la **racine dominante des `preuves.fichier`** (plus fiable que grep par phrase de consigne — les agents citent le vocabulaire des autres dimensions → faux positifs).
3. Extraire en **Node** (`JSON.parse` ligne par ligne) — pas Python (absent du poste RIG).
4. Dimensions sans finder complété → relancer un `Agent` read-only par dimension, **en parallèle**, avec la consigne+paths exacts du script. Spot-check un échantillon des preuves contre le code avant de graver (réflexe : vérifier l'artefact, pas le rapport).

**AU MOMENT où l'user dit « reprends le travail / récupère l'analyse » après un run interrompu** → cette procédure AVANT de tout relancer (relancer = tokens ; récupérer = quasi gratuit). Vécu sur [[project_audit_lenteur_rig]] (12 dims, 7 récupérées sur disque, 5 relancées).
