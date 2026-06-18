---
name: workflow_resume_full_not_tail
description: "AU MOMENT où l'user dit « reprends/resume <session-id> » → reconstruire le FLUX COMPLET du transcript, jamais juste le tail (qui peut être une question abandonnée)."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 03f892f3-32e4-418a-9341-6d681f9c0413
---

POST 2026-06-14 — erreur vécue. **AU MOMENT où l'user dit « reprends / resume <session-id> »** → parser le
FLUX COMPLET du `.jsonl` (tous les prompts user réels + invocations skill via `"skill":"X"` + dernier
`RUN.md` au statut `open`), PAS seulement les 12 dernières lignes.

**Why** : le tail peut être une `AskUserQuestion` **abandonnée** (suivie de `[Request interrupted by user]`).
La re-poser = reprendre le mauvais fil. Vécu : j'ai resumé sur le tail → re-posé une question CLAUDE.md que
l'user avait abandonnée, alors que le vrai fil ouvert était 4 sujets plus loin (frame `pipeline-optimal`,
réponse « B » jamais traitée).

**How to apply** : (1) `node` pour dumper user-prompts + tool_use skill/AskUserQuestion dans l'ordre ;
(2) repérer les `[Request interrupted by user]` = fils MORTS, ne pas les reprendre ; (3) le vrai point de
reprise = le dernier RUN.md `open` + la dernière intention user non satisfaite. Distinct de
[[workflow_recover_interrupted_workflow]] (lui = findings d'un Workflow tué ; ici = session conversationnelle).
