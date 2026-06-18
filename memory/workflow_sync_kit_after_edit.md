---
name: workflow_sync_kit_after_edit
description: "AU MOMENT où tu édites un skill/ENGINE/hook LIVE (~/.claude) → lance sync-kit.ps1, ne sync PAS à la main fichier par fichier (tu en rates un)."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 03f892f3-32e4-418a-9341-6d681f9c0413
---

POST 2026-06-15 — erreur vécue. Le kit Autowin a DEUX copies : live `~/.claude/` (chargé par Claude Code,
source de vérité) et package `~/Desktop/Autowin/` (redistribuable). **AU MOMENT où tu modifies un skill /
ENGINE / hook côté LIVE → lance `~/Desktop/Autowin/sync-kit.ps1`** (propage live→package en portabilisant
les chemins ; `-Check` = diff seul).

**Why** : le sync manuel par fichier RATE une copie. Vécu : édité ENGINE live (règles judge nature/intrinsic/
cap-coût/escaladant) + synced `judge/SKILL.md` à la main, mais **oublié `ENGINE.md`** → le package aurait
régressé tout le travail à la réinstall. Un scout des manquements l'a rattrapé.

**How to apply** : après toute édition de `skills/*/SKILL.md`, `skills/_engine/*.md`, `hooks/*.ps1` côté live
→ `& "$env:USERPROFILE\Desktop\Autowin\sync-kit.ps1"`. EXCLUS du script (sync MANUEL, par design) :
`CONSTITUTION.md` (= CLAUDE.md SANS la section `## Local`), `hooks/settings-snippet.json` (vs settings.json),
`skills/_pipeline-audit/` (historique machine). Lien : [[feedback_integrate_into_existing_doc_blocks]] (un seul
CLAUDE.md tracké) ; c'est la généralisation de la divergence kit-sync repérée plusieurs fois.
