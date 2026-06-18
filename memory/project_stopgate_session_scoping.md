---
name: project_stopgate_session_scoping
description: "Stop-gate v3.2 scope les RUN.md PAR SESSION — chemin workspace per-session, fini le cross-block entre sessions concurrentes"
metadata:
  type: reference
---

Le `stop-gate.ps1` (v3.2) n'enforce QUE les runs de SA session : un run est « à moi » s'il est placé sous
`Audit\workspaces\<session_id>\<subject>-workspace\` (par emplacement) OU si son header `session: <id>` ==
le `session_id` courant ; tout autre run (autre session / legacy non-stampé) est **ignoré**. **Filet** :
`session_id` absent du stdin → comportement LEGACY (scanne + enforce tout) pour ne JAMAIS désarmer le gate.

Avant ce fix, sous un même répertoire racine plusieurs sessions concurrentes se cross-bloquaient (chaque
session butait sur les RUN.md ouverts des AUTRES sessions). Le `session_id` est injecté chaque tour par un
hook `UserPromptSubmit` ; écris tes RUN.md sous `Audit\workspaces\<session_id>\<subject>-workspace\RUN.md`
(l'emplacement fait foi ; header `session:` optionnel). Voir [[workflow_sync_kit_after_edit]] et
[[workflow_runmd_signalcmd_form]].
