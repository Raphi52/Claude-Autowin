---
name: feedback_utility_over_sophistication
description: "Kaizen 937321bc — mesurer l'utilité à ce que l'user peut UTILISER, pas à la sophistication produite ; répondre à la question POSÉE, pas à celle qu'on aimerait."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 741654f7-f79a-4f15-aca2-931d850cab28
---

Racine d'un échec de session (937321bc, kaizen 2026-06-17 : « pue la merde », « j'ai rien compris ») :
**je mesure mon utilité à la sophistication de ce que je produis, pas à ce que l'user peut utiliser tout de
suite.** Je réponds à la question que j'aimerais qu'on me pose (cadre-moi / juge-moi / donne une méthodo
parfaite) au lieu de celle posée. Preuve : « méthodologie pour une giga app ? » → 40k caractères, 25
sous-agents, 4 boucles judge 100/100, ZÉRO code livré.

**Why :** une question de conseil ou un signal de frustration traité en pipeline (frame/RUN/QCM/judge) =
sur-production qui ENTERRE la réponse. Un score /100 producteur=juge qui monte pendant que l'user décroche est
un faux-vert. Une fiche mémoire seule ne suffit pas (celle-ci a été violée 2× la même session) → câblé.

**How to apply :**
- Question *whether/what* sans verbe d'action (« quelle est la meilleure / vaut-il mieux / c'est quoi ») =
  ADVISORY → réponds DIRECT, court, utilisable en 1 message. Pas de frame/RUN/QCM. Voir [[feedback_advisory_question_vs_build_task]].
- Signal de frustration/redirection (« juste la réponse / rien de plus / rien compris / trop long ») = STOP la
  machinerie, réponds à la question POSÉE. Hook `advisory-guard.ps1` (UserPromptSubmit) injecte ce rappel.
- Demande « méthodo / étapes / comment » → liste NUMÉROTÉE, jamais du narratif.
- Un /100 auto-attribué n'est pas une preuve d'utilité → exiger un signal user hors-modèle avant d'itérer un
  judge en autonomie. Lié à [[workflow_closure_authority]].
- Une leçon fraîchement écrite = réflexe ACTIF les ~3 tours suivants (charger ≠ appliquer) ; les prompts que je
  construis pour mes sous-juges obéissent aussi aux règles d'honnêteté (pas de label « ultime/parfait »).
- Sur un pivot de sujet avant clôture : checkpoint 1 ligne (« tâche X : livrée/suspendue/abandonnée »). Quand
  on demande un ARTEFACT (screenshot/fichier), le LIVRER, pas le décrire + re-demander la cible.

Gravé dans CLAUDE.md (réflexes 14-18 + Advisory hard-gate dans routing). Voir [[feedback_corrections_evaporate]].
