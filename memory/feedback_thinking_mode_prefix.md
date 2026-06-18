---
name: feedback_thinking_mode_prefix
description: "Un message commençant par \"?\" = MODE PENSÉE — discuter/structurer, ne lancer AUCUN outil Write/Edit/Agent ni action irréversible."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 03f892f3-32e4-418a-9341-6d681f9c0413
---

POST 2026-06-15 — convention adoptée par l'user. **Un message qui commence par `?` = MODE PENSÉE** :
l'utilisateur réfléchit à voix haute, ne donne PAS un ordre. → Discute, structure, propose ; **ne lance
AUCUN outil Write/Edit/Agent ni action irréversible** tant qu'il n'a pas redonné un ordre explicite SANS le
`?`. Un message sans `?` = comportement normal (ordre exécutable).

**Why** : le kit confondait « penser tout haut » et « commander » — chaque pensée risquait de déclencher une
action. Le `?` est la *poignée* déclarée hors-modèle (pas une devinette d'humeur).

**How to apply** : câblé aussi en hook `UserPromptSubmit` (settings.json + Autowin/hooks/settings-snippet.json)
qui injecte le contexte — MAIS le hook ne tire qu'après reload `/hooks`/redémarrage, donc honore la convention
TOI-MÊME en attendant. Lien : [[workflow_maximize_autonomy]] (board-gate : le `?` dit explicitement « je
n'attends pas une action »).
