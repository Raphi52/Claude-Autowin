<!-- RUN-template.md — copie ce fichier en Audit\workspaces\<session_id>\<sujet>-workspace\RUN.md
     (<session_id> = injecte chaque tour par le hook UserPromptSubmit ; UN folder par session ; le Stop-gate
     v3.2 n'enforce QUE les runs de SA session). Fallback : chemin plat si pas de session_id.
     Convention complete : _engine/ENGINE.md ch.3.
     Le Stop hook lit le header : open/red bloquent la fin de tour ; green est REJOUE, pas cru. -->
status: open
session: <session_id>       <!-- scope du run a cette session (sinon l'emplacement <session_id>\ fait foi) -->
regime: standard            <!-- disposable | standard | critical — la molette d'effort -->
signal: <l'artefact HORS-modele qui prouvera le vert — ex : "test-x.ps1 exit 0", "capture lue", "requete SQL n>0">
signal-cmd: <optionnel mais puissant — commande IDEMPOTENTE que le gate REJOUERA via cmd /c, prefixes
  whitelistes : dotnet test | dotnet build | cmd /c | powershell -NoProfile -File | powershell -File —
  QUOTE tout chemin contenant des espaces, et execute-la une fois TOI-MEME avant de la declarer>
signal-attestable: <optionnel — preuve hors-modele NON rejouable (ex : "capture lue + run-stamp", "requete SQL
  n>0 lue") ; en regime CRITICAL, satisfait l'exigence de preuve quand il n'y a ni signal-cmd ni check:>
gate: on                    <!-- on (defaut) | off — opt-out pour un run jetable : le Stop hook saute TOUT le gate si 'off' apparait dans les 14 premieres lignes (cf. stop-gate.ps1) -->

## Besoin
**Deep-why** : <le probleme reel, pas la solution demandee>
**Scope IN** : <ce qui est couvert> / **Scope OUT** : <ce qui ne l'est pas, et pourquoi>
**Critere de succes verifiable** : <comment on SAURA que c'est fini>
**Decisions deliberees** : <choix volontaires que la review ne doit pas re-flaguer>
**Hypotheses annoncees** : <"je pars du principe que X (fait : ...) — corrige">

## Options
<!-- si un choix d'approche est ENGAGE : >=3 options REELLEMENT distinctes scorees + ligne Décision:
     (le gate verifie a la cloture ; des options-paille = defaut que le judge flague) -->
- Option A — <desc> score: NN
- Option B — <desc> score: NN
- Option C — <desc> score: NN
Décision: <laquelle et pourquoi>

## Journal
<!-- append-only : [ts] unit=<id> run=<stamp> VERIFIED|FAILED|FLAKY|CLAIM|PROOF|USER-OK -->

## Défauts
<!-- ledger du judge : [gravite, statut] description — jamais efface, resolu ou accepte-avec-raison -->

## Reprise
Goal:
Hypothesis:
Tried:
Next:
Blockers:

## Checks
<!-- lecons promues en code, EXECUTEES par le gate a chaque cloture : check: <commande exit!=0 = bloque> -->
