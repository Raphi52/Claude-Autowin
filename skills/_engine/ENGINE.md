# ENGINE — le socle (à tenir en tête) + la référence (à consulter au moment où elle sert)

> **Single canonical source**; skills carry a compact summary + a pointer here; on divergence the engine wins.
> Routing by hardness: *structure > blocking gate > annotation > memory > skill > doc*.

---

## ⚡ LE SOCLE — les 7 seules choses à tenir en tête (jour-1 ; tout le reste se CONSULTE)

1. **Un travail = UN fichier** : `RUN.md` dans son workspace **scopé par session** (`Audit\workspaces\<session_id>\<subject>-workspace\` — le `session_id` est injecté chaque tour par le hook UserPromptSubmit ; le Stop-gate v3.2 n'enforce QUE les runs de SA session → fini le cross-block entre sessions concurrentes).
   Header : `status: open|green|red|degraded-closed` · `regime:` · `signal:` · `signal-cmd:` (optionnel) · `session:` (scope ; sinon l'emplacement `<session_id>\` fait foi) · `gate: off` (opt-out justifié).
   ⚠️ `signal-cmd` est exécuté via `cmd /c` EXACTEMENT tel qu'écrit — c'est un artefact aussi : **quote tout
   chemin contenant des espaces**, et ne déclare jamais une commande que tu n'as pas exécutée une fois
   toi-même. (Cicatrice du premier rejeu live : un `C:\Mon Projet\…` non quoté a rendu irrejouable un green
   pourtant vérifié 5× — le gate l'a refusé, à raison.)
2. **Un seul gate bloquant : la clôture.** Run `open`/`red` → la fin de tour est bloquée. Run `green` → le gate
   ne te CROIT pas : il **rejoue** `signal-cmd` (whitelist idempotente), **exécute** tes lignes `check:` et
   vérifie l'anti-fixation — une fois par transition. Tout le reste annote, ou n'existe pas.
3. **Verdict honnête : GREEN / RED / INVALID — INVALID par défaut.** Une absence de preuve n'est jamais un
   vert. Un vert sans artefact hors-modèle se dit : « auto-déclaré, non vérifié ». **Idem pour toute
   conclusion DITE en cours de route** (« c'est X · impossible · intrinsèque · c'est fixé ») : étiquetée
   HYPOTHÈSE + confiance tant qu'aucun artefact hors-modèle ne l'ancre. Un « impossible/intrinsèque » →
   d'abord demander « ça a déjà marché ? » (si oui = RÉGRESSION, pas une limite). Affirmer une hypothèse
   comme un fait coupe la recherche de l'humain et te fait rétracter au tour suivant.
4. **Le régime est LA molette** : `disposable` = zéro cérémonie (pas de RUN, gates désarmés) ·
   `standard` = léger (panel réduit, 1 rejeu à la clôture) · `critical` = tout armé (panel complet, canari,
   source hors-modèle). L'effort suit l'enjeu, mécaniquement.
5. **~10 cardinaux en mémoire** (« AU MOMENT OÙ X → Y ») — les réflexes ; la mémoire propose, le gate dispose.
6. **Une leçon durable devient du code quand c'est possible** : ligne `check: <commande>` dans le RUN
   (le gate l'exécute) ou règle mémoire sinon. Une correction non persistée se régénère.
7. **4 skills accélérateurs** — `frame` (besoin+options) · `terrain` (harnais) · `judge` (review) · `scout`
   (candidats). **Le socle fonctionne avec ZÉRO skill déclenchée** ; leur taux de déclenchement se mesure
   (routeurs), il ne se suppose pas.

**Coût par régime** (la cérémonie n'existe que si l'enjeu la paie) :
| Régime | RUN.md | Gate à la clôture | Panel de review | Canari |
|---|---|---|---|---|
| disposable | non | passe | 1 juge ou skip | non |
| standard | oui | rejeu+checks (1×/transition) | Fidèle + 2-4 dims à risque | échantillonné |
| critical | oui | rejeu+checks | complet + [S] doublés + hors-modèle | **oui** |

---

# RÉFÉRENCE (ne pas mémoriser — consulter quand le moment arrive)

## Ch.1 — GENERATE & GATE *(sert pendant `frame`/`scout` : générer large, ne remonter que le décisif)*

**Pattern** : POOL → SCORE → GATE → auto-résoudre le routinier | remonter le décisif. L'humain est la
ressource la plus rare et le seul vrai oracle — jamais endormi sur des OK-OK. L'autonomie ne s'étend JAMAIS à
la clôture (socle §2-3).

- **Générer large et DIVERS, en parallèle** : 1 générateur par lentille orthogonale (UN message). Lentilles —
  *questions* : Naive · Breaker · Contradictor · Perfectionist · Diplomat · Explorer · Pragmatist · Emotional.
  *Approches* : MVP · robust · perf · lean · reuse · creative · cost · UX · convention · contrarian.
  *Candidats d'amélioration* : familles grep-markers ET lecture-de-flux. Chercher l'existant AVANT de
  proposer, citer les faits ; sortie CONCRÈTE-EXTRÊME (`Dupont,"Le Grand"\nSARL`) — l'abstrait est rejeté à
  réception. **Loop-until-dry** : chaque tour reçoit le déjà-trouvé (« du NEUF ») ; stop à 2 tours secs OU cap
  (~12 candidats / ~10 tours, journaliser le coupé). **Dédup par idée-noyau** avant scoring. Ressources
  exclusives (build/banc/DB/port) : un seul propriétaire — isoler ou sérialiser.
- **Deux échelles /100, jamais fusionnées** : **impact** (80-100 = change la NATURE → remonte d'office ·
  50-79 contrainte forte · 30-49 utile · <30 drop) ⟂ **confiance-autonomie** (mesurée APRÈS recherche :
  ≥80 = fait CITÉ · 50-79 plusieurs lectures · <50 devinette).
- **Board** : 🧠 l'Autonome (cherche d'abord — UN sweep groupé par tour résout les faits de TOUTES les
  candidates ≥30) · 🙋 l'Avocat du silence (rejette tout ≥80 sans fait cité ; flague le strictement-privé) ·
  ⚖️ ≥80 étayé ET rien de privé → hypothèse ANNONCÉE (« je pars du principe que… — corrige »), jamais
  silencieuse. **Override fort-impact** : impact ≥80 → remonter quelle que soit la confiance (carve-out : un
  « pourquoi » explicitement énoncé). **Stop** : meilleur impact brut <30, épuisement du gate, ou cap.
- **⚖️ Pertinence gate (summon-or-not)** : avant d'auto-invoquer un skill sur un besoin, scorer la **valeur
  marginale NETTE du coût** /100 (≥50 = summon). Échelle **3 tiers** (calibrée sur 2 tests) : **(1)** 1 scoreur
  *cheap* — score ≤~35 ou ≥~70 → décide direct (les cas clairs sont **bimodaux**, le panel y est gaspillé) ·
  **(2)** seulement si **35-70** → panel décorrélé (modèles/lentilles ≠) · **(3)** si le panel **split** (vote
  croise le seuil) OU **spread >~20** → **SURFACE à l'humain**, jamais de drop muet. **Unifie** les freins
  épars (advisory-gate, off-ramp trivial, ROI-stop) — ne pas en ajouter un parallèle. Garde-fou : **conservateur
  en veto AMONT** (scout/frame — un besoin mal cadré ne se vétote pas par un jugement non-cadré), **agressif en
  AVAL redondant** (re-panels, boucles en trop). Désarmé en disposable. (producer=scoreur → signal, pas preuve.)
- **⚓ Anti-fixation** (appliquée par le gate à la clôture, socle §2) : pas de décision engagée sans **≥3
  options scorées réellement distinctes** (des options-paille = défaut à flaguer par la review) — désarmée en
  disposable. Annotée à l'écriture, bloquante à la clôture.
- **Schéma `gg-1`** (validé à RÉCEPTION ; *absent* ≠ *présent-mais-non-conforme* ; rejet sur version-skew) :
  `{"schema_version":"gg-1","candidates":[{"id","lens","content","impact","autonomy_confidence","cited_fact","strictly_private","proposed_assumption"}]}`

## Ch.2 — JUDGE *(sert pendant `judge` ; le canari ne sert qu'en critical)*

**Règles fondatrices.** Juge = EXTERNE (n'a pas produit) + INFORMÉ (besoin + décisions délibérées + ledger
`## Défauts`) + jamais amnésique (vérifie d'abord que les fixes tiennent ; ne signale que NOUVEAU /
fix-incomplet / régression). **Un juge ne corrige jamais.** Plafond same-model : aucune combinaison de copies
n'est un oracle — la crédibilité vient de la séparation + l'obligation de preuve ; la clôture reste
hors-modèle (socle §2).

**Classes de preuve** : **REJOUABLE** (CLI sans effet de bord) → rejouée, pas crue (par le gate via
`signal-cmd`, ou un Vérifieur à froid pour le coûteux) · **ATTESTABLE** (screenshot, artefact lu) → doit
s'auto-prouver : fraîcheur (artefact > action) + non-vacuité (N tests >0, log non vide, exit 0 ET stderr
propre) + ciblage (run-stamp) + contre-contrôle négatif. `artifact_based:true` seulement si ça tient.

**Scoring** : retirer d'abord l'objectivable (exit, comptes, pixel-diff → déterministe). [F] = 1 juge,
contre-exemple ou 100. [S] = attaque d'expert hostile puis note ; **2 tirages décorrélés par LENTILLE ORTHOGONALE NOMMÉE** (tirage A et B reçoivent des lentilles
distinctes d'une liste par dimension — p.ex. Fidèle A=« tracer chaque claim→critère du besoin » / B=« trouver un cas du besoin non couvert » — PAS juste « cadrage différent »), **médiane-puis-MIN** ; écart >20 → 3ᵉ tirage MIN ; écart des 3 tirages encore >15 →
**INDÉTERMINÉ + demander** — jamais un vert silencieux. **Variance-gate (kaizen 2026-06-18)** : un /100 d'un
SEUL modèle est un JUGEMENT, pas une mesure — des tirages même-modèle sur UN artefact qui s'écartent de >20
(vécu : 97/72, 96/61/58) prouvent l'instrument peu fiable → titrer **l'écart**, jamais un MIN maquillé en
nombre propre ; surfacer le score en **bande grossière** (keep/maybe/drop) + provenance « auto-jugé, pas
mesuré », pas une fausse précision à 2 chiffres.

**Agrégation** : verdicts PASS/FAIL → MIN de toutes les dimensions — **SAUF** une dimension dont le défaut
bloquant est `nature:intrinsic` (plafond de conception, pas un bug corrigeable) : EXCLUE du MIN global,
portée en **NOTE DE RISQUE** visible (jamais maquillée en vert). **Mode CLASSEMENT** (N candidats) → somme
pondérée post-veto (MIN = veto éliminatoire + intra-[S] seulement). **`[1b]` fail-closed** : N juges ⇒
N JSON `je-1` valides ; manquant/invalide → 1 retry → sinon dimension **INVALID, plafonne et bloque**. Un
majeur RÉEL corrigé laisse un **garde anti-régression permanent** (`check:` dans RUN.md / repro rejouable) —
sinon il peut revenir non-audité (anti-whack-a-mole : un défaut tué ne ressuscite pas).
Schéma : `{"schema_version":"je-1","dimension","note","interval","unstable","artifact_based","defects":[{"severity","nature":"fixable|intrinsic|wont_fix","type","description","to_reach_100"}]}`

**La boucle** : panel ∝ régime (table du socle) ; re-vote à chaque itération (re-audit, pas re-lecture).
**Coût (hors critical)** : panel ESCALADANT (cœur de 2 = Faithful + Real-effect, escalade sur signal — major
surfacé / pivot inquiet / diff touchant la dim) · [F] grunts en modèle CHEAP, [S] pivots en fort — **et DIVERSIFIER pour décorréler** : varier modèle/température entre sièges ([F] répartis sur ≥2 modèles si ≥4 tirent ; les 2 tirages [S] à températures distinctes 0.0/0.7 ou checkpoints ≠ ; même-modèle+même-température = corrélation maximale) · doubler le
SEUL pivot top en standard (tous les [S] seulement en critical) · digest partagé lu UNE fois (pas N re-lectures).
Critical = full panel + doublé + fort d'emblée, PAS d'escalade (on paie la couverture là où c'est irréversible).
**Arrêts** : ROI-stop (disposable/standard : zéro-majeur atteint → stop, pas de re-panel cosmétique) ·
**intrinsèque-tôt** (≥1 majeur `nature:intrinsic` dès le cycle 1 → MODE DÉGRADÉ immédiat, ne PAS attendre le
cap : le renvoyer au producteur = whack-a-mole, il ne peut pas le corriger) · **cap-coût** (audits cumulés
≥ ~15 ET delta min-global <5 sur 2 transitions → ROI-stop forcé même hors zéro-majeur) · **bannière coût
avant relance** (kaizen 2026-06-18 : relancer une boucle coûteuse au tour N≥2 avec delta négatif, OU après
avoir déjà recommandé l'arrêt → AFFICHER « run #N, ~XM tokens cumulés, delta −Y » AVANT de relancer ; le coût
doit être VISIBLE sinon l'humain ne peut pas exercer son autorité d'arrêt — jamais auto-mute « sans insister ») · caps (≈3 standard —
un majeur vivant au cap = sous-classification, re-hausser ; 5 critical) · stagnation (min global plat sur 2
transitions) · régression tournante · conflit de conception → **hard-stop humain en MODE DÉGRADÉ** : sort du
livrable + 2-4 options chiffrées + rien-sans-OK. **Fallback sans sous-agents** : juger
séquentiellement en changeant de lentille (ledger gardé) ; [S] mono-passe = « vote dégradé » ; jamais
l'auto-évaluation du producteur.

**🐤 Canari (critical : systématique · standard : ÉCHANTILLONNÉ)** : avant de croire un vert de panel — défaut planté dans une copie, panel
dessus d'abord ; aucun juge ne le voit → ensemble « aveugle aujourd'hui » → verts non-conclusifs (INVALID) → **ré-escalade FORCÉE** (re-hausser d'un régime : standard→critical, ou hard-stop humain si déjà critical ; jamais juste logguer et continuer),
log `CANARY-BLIND`. **En standard, ÉCHANTILLONNER** : déclencher au moins sur (a) une fois par work-item, tracé dans RUN.md `## Défauts` (état persistant ré-lu au Prélude — sans log, la condition « type nouveau » n'est pas exécutable d'un contexte vierge à l'autre) et (b) quand les 2 tirages [S] s'accordent à <5 (corrélation suspecte). Mesure la corrélation au lieu de la supposer absente. **Toute passe standard SANS canari DOIT porter le marqueur « blind spot not excluded » (silence ≠ sûreté).**

**Livrables-skills** : test de déclenchement (routeur en contexte vierge, devrait/ne-devrait-pas) + 1 run
réel ; re-test après TOUTE édition ; cross-refs résolues. **Revue de diff** avant intégration : surface ∝
besoin, pas de hors-scope, pas de code mort/debug, pas de secrets, pas de reformatage parasite.

## Ch.3 — RUN, détails *(sert aux runs standard/critical ; le socle §1-2 suffit au quotidien)*

**Sections** (single-writer : l'orchestrateur seul écrit ; les sous-agents rendent du JSON typé → événements) :
`## Besoin` (deep-why, scope in/out, critère de succès, décisions délibérées) · `## Options` (≥3 scorées +
`Décision:`) · `## Journal` (append-only : `[ts] unit=<id> run=<stamp> VERIFIED|FAILED|FLAKY|CLAIM|PROOF|USER-OK`) ·
`## Défauts` (le ledger du juge) · `## Reprise` (Goal/Hypothesis/Tried/Next/Blockers + compteurs) ·
`## Cicatrices` (leçons du run — volatiles à l'HYPOTHÈSE) · `## Checks` (`check: <commande>` — socle §6).

**Discipline** : `green` UNIQUEMENT après vérification réelle du signal — jamais pour satisfaire le gate (il
rejoue). `degraded-closed` = clôture honnête sans vert, **USER-OK tracé au Journal** (contrainte d'honneur —
le gate passe, la review vérifie). **FLAKY de 1ʳᵉ classe** : un signal qui flippe entre re-runs est journalisé
FLAKY, listé au récap, jamais absorbé en vert, n'arme jamais un fix. **Confirmer-la-couleur** : re-run de
confirmation avant tout pivot ou clôture. **Idempotence** : clés `unit+run` au Journal — un redispatch ne
double-applique pas ; les commits restent hors zone parallèle (apply série post-barrière). **Multi-workspace** :
un RUN parent reste open tant que TOUS les enfants ne sont pas verts ET l'intégration vérifiée. **Reprise** :
header + `## Reprise` + ~10 derniers événements (~30 s).

---

## Ch.4 — BUILD *(sert pendant l'exécution — entre `terrain` et `judge` ; c'est l'EXÉCUTANT qui le consulte, aucune skill ne se déclenche à cette phase)*

**Plan = incréments porteurs de signal.** Décomposer en **plus petits pas VÉRIFIABLES**, chacun annoté
`{but, signal propre (câblé par terrain), independent | depends-on-X}` ; dépendances d'abord, part
indépendante maximisée délibérément. Le plan vit dans le RUN (`## Reprise` + Journal), pas dans un fichier
à part. Relire la `Décision:` avant de commencer — on exécute l'option choisie, pas une autre.

**Rouge d'abord** *(le contrôle négatif appliqué au build)* : quand le signal d'un incrément est un
test/check exécutable, l'écrire AVANT d'implémenter et le VOIR ÉCHOUER — un check qui n'a jamais été rouge
ne prouve rien (il peut tester le vide ; cicatrice « fixture trop propre »). Puis implémenter jusqu'au
vert, puis re-runner la suite touchée. Ne JAMAIS modifier un test pour le faire passer.
**Couverture adverse sur SON propre fix (kaizen 2026-06-18)** : un test que TU as écrit qui passe prouve le
chemin heureux, PAS l'absence de la classe de bug — pour un fix de frontière/discriminant, NOMME un input qui
DEVRAIT faire échouer le test et confirme qu'il échoue (mutation) ; sinon = « couverture non vérifiée », pas
vert (vécu : un fix faux-green a ré-introduit un faux-green dans sa propre zone morte, attrapé par le judge —
pas par mes 3 tests auto-écrits).

**La boucle d'incrément** : implémenter → vérifier par le SIGNAL RÉEL (jamais du texte auto-jugé) →
rouge ? diagnostiquer puis fixer → re-vérifier → journaliser (`unit=… VERIFIED|FAILED|FLAKY`) → suivant.
**Cadence anti-régression** : à chaque incrément vert, re-vérifier les acquis ADJACENTS (pas seulement à
la fin) ; deux incréments qui se cassent mutuellement 2× = conflit de conception → remonter, pas boucler.

**Dispatch parallèle** : les incréments indépendants partent en sous-agents EN PARALLÈLE (un seul
message) ; chaque sous-agent rend du JSON typé (jamais de la prose à re-parser) ; l'orchestrateur SEUL
écrit le RUN (single-writer, ch.3) ; mutations de fichiers concurrentes → isolation par agent
(worktree/scratch) ; ressource exclusive (build/DB/banc/port) → un seul propriétaire ; applys/commits en
SÉRIE post-barrière.

**Debugging systématique** *(sur échec inattendu — avant tout fix)* : reproduire MINIMALEMENT → poser ≥2
hypothèses DISTINCTES → **AVANT de coder le 1er fix, surtout sur une couche système/plateforme
(rendu/DWM/desktop/focus/IPC/capture/OS) ou une cause inconnue : une passe de RECHERCHE prior-art (doc
officielle / issues / web, cap court). Un fix codé sans cause CITABLE = un coup de dé — et la limite est
souvent DÉJÀ documentée** → instrumenter pour DISCRIMINER avant de toucher au code → fixer la CAUSE, pas le
symptôme → promouvoir la leçon en code (`check:` / test de régression). **Cap-coût : un essai empirique
(édit+build+run) coûte plus qu'une recherche → 2ᵉ fix aveugle sur cause inconnue = STOP code, RECHERCHE
d'abord (l'humain coûte autant qu'un essai : chercher AVANT d'escalader) ; 3 fixes échoués → résolveurs
parallèles à hypothèses orthogonales.** **Anti-dérive de diagnostic : la cause-racine qui CHANGE ≥2× dans un
run → STOP, publier {hypothèse retenue · preuve hors-modèle qui l'ancre · hypothèses écartées} et faire
VALIDER avant de repartir — sinon c'est l'user qui devient ton falsificateur.**

**Checkpoint vert + rollback** : avant chaque incrément risqué, un vert NOMMÉ restaurable (commit/tag —
worktree jetable monté par terrain) ; régression CONFIRMÉE (re-run, pas un flake) → revenir au dernier
vert et ré-attaquer avec une hypothèse DIFFÉRENTE — jamais empiler des fixes sur un état cassé.

*(Ch.4 = l'absorption volontaire de la mécanique d'exécution autrefois déléguée à des skills tierces —
le moteur est self-contained par décision, 2026-06-10.)*

## Télémétrie & cadence *(mesure hors-modèle — pas du quotidien)*
Blocages comptés dans `~/.claude/gate-counters.jsonl` par les hooks — la TENDANCE mesure la discipline, pas
l'auto-rapport. Périodique : audit comportemental (Mode B) · consolidation mémoire (péremption/conflit/dedup) ·
re-baseline au bump de modèle (trigger-tests + calibration des juges).

## Roadmap (nommée, NON câblée — n'en supposez pas la couverture)
Held-out anti-Goodhart (critical) · juge-frais sur saturation · plafonds $ réels + token-bucket 429 ·
A/B pipeline-vs-nu sur cas réel · promotion-leçon mécanique par hook.
