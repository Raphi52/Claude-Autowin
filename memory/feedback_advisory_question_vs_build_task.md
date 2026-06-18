---
name: feedback_advisory_question_vs_build_task
description: "Une question « quelle est la meilleure X / quel choix » qui attend une RÉPONSE n'est PAS un ordre de PRODUIRE → répondre direct et court, ne pas dérouler frame+RUN+QCM. Le routing agressif vise les TÂCHES, pas les questions advisory."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 937321bc-67fe-4b42-8698-38289d784a76
---

AU MOMENT où l'user pose une question de type « quelle est la meilleure architecture / approche / quel choix ? »
qui attend une **réponse/opinion** (pas un mandat de CONSTRUIRE) → **répondre directement et brièvement**.
NE PAS lancer frame + RUN.md + options scorées + QCM de décision.

**Why** : vécu 2026-06-16 — après avoir réglé le skill-routing en « agressif », j'ai transformé une question
« quelle est la meilleure archi doc ? » en pipeline complet (recon sous-agent + RUN + 5 options + AskUserQuestion).
Réaction user : « je voulais juste la réponse à la question rien de plus ». Le routing agressif s'applique aux
TÂCHES à produire un livrable, pas aux questions de connaissance/conseil.

**How to apply** : distinguer « réponds-moi X » (advisory → réponse directe, proportionnée) de « fais/construis X »
(production → pipeline). En cas de doute léger, répondre d'abord, puis proposer EN UNE LIGNE « je peux le cadrer/
le construire si tu veux » — laisser l'user déclencher le pipeline, ne pas le présumer. Le bloc « Skill routing
(aggressive) » de CLAUDE.md/CONSTITUTION devrait porter ce garde-fou (advisory ≠ build) si l'over-trigger récidive.
Voir [[feedback_diverge_on_open_goals]] et [[feedback_skill_output_plain_no_jargon]].

**RENFORCÉ (kaizen 2026-06-17)** — cette fiche a été ÉCRITE pendant 937321bc PUIS violée 2× la même session
(charger ≠ appliquer). Gate falsifiable désormais gravé dans CLAUDE.md (Advisory hard-gate, routing) + **câblé
par un hook** `advisory-guard.ps1` (UserPromptSubmit) : *whether/what ouvert + aucun verbe d'action* (« quelle
est la meilleure / vaut-il mieux / c'est quoi ») = advisory → réponse directe ; *how sur tâche décidée*
(« fais/crée X ») = build. Signaux de frustration (« juste la réponse / rien compris / trop long ») = STOP la
machinerie. Voir [[feedback_utility_over_sophistication]].
