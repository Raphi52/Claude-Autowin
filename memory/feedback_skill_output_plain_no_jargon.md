---
name: feedback_skill_output_plain_no_jargon
description: "Sortie de skill = table simple What/Why/How, ZÉRO jargon interne (goût/feasibility-seed/novelty/paniers) qui n'évoque rien à l'user."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5544b29d-805f-4e7a-ab13-1d8272abea12
---

POST 2026-06-15 — l'user a trouvé la sortie de `scout` « bizarre » (2 paniers grounded/créatif) et les termes
**« goût », « feasibility-seed », « novelty/10 »** vides de sens (« ça ne m'évoque rien à chaque fois »). Il
voulait **JUSTE une table `Type · What · Why · How`** (🔧 fix existing / 🆕 new feature).

**Why** : le vocabulaire INTERNE d'un skill (grounded/creative, taste, feasibility-seed, scores /100, « 2
paniers ») fuit dans la sortie VISIBLE et ne transmet rien d'actionnable. L'user veut *de quoi juger* (le
fait concret), pas *comment juger* (la méta-consigne).

**How to apply** :
1. **Sortie de skill = plate, concrète, évocable** : What (quoi) · Why (le problème/valeur) · How (1er pas
   concret + `file:line` si ça existe). La mécanique maligne (lentilles de génération, scores de tri) reste
   SOUS LE CAPOT — jamais surfacée. Bannir de l'output : goût/taste, feasibility-seed, novelty/N, « paniers ».
2. **META (le vrai défaut récurrent)** : quand l'user donne un feedback de FORMAT → **simplifier direct**, ne
   PAS répondre par un framework multi-options / markers / axes (j'ai sur-bâti 2 tours avant qu'il coupe :
   « ca sert a rien je veux juste un tableau what why how »). Proposer le plus simple d'abord ; il enrichira
   s'il veut.

Prolonge [[feedback_tldr_block_each_response]] + [[feedback_integrate_into_existing_doc_blocks]] (BLUF, signal
pur). Appliqué à `scout/SKILL.md` 2026-06-15 (table unique) ; **vérifier si frame/terrain/judge ont le même
jargon en sortie** et le simplifier pareil si l'user le demande.

**MAJ 2026-06-18** : l'user veut UNE colonne **Score** (valeur × faisabilité × fit, producteur-jugé) dans la
sortie de `scout` comme **aide à choisir**. Ce n'est PAS un revirement : le ban 2026-06-15 visait les **scores
INTERNES par-lentille + le jargon** (novelty/10, taste, feasibility-seed, paniers) — du bruit opaque. UN
agrégat-décision unique = « de quoi juger » → autorisé ; le reste reste sous le capot, seul le Score surface.

**MAJ 2026-06-18 (kaizen session 7f4514bd — variance-gate)** : le Score N'EST PAS un /100 mais une **BANDE
grossière 🟢 keep / 🟡 maybe / 🔴 drop** — un /100 d'un seul modèle est un JUGEMENT, pas une mesure (des tirages
même-modèle qui s'écartent de >20 = fausse précision). Provenance affichée « auto-jugé, pas mesuré ». Voir
[[feedback_passive_guardrails_fail]] (le même réflexe : ne pas maquiller un self-score en mesure).
