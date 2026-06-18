# Autowin — un système de travail auto-correctif pour Claude Code

[![test-hooks](https://github.com/Raphi52/Claude-Autowin/actions/workflows/test-hooks.yml/badge.svg)](https://github.com/Raphi52/Claude-Autowin/actions/workflows/test-hooks.yml) · [MIT](LICENSE) · [CHANGELOG](CHANGELOG.md) · [SECURITY](SECURITY.md)

> Un pipeline de *skills* + des garde-fous déterministes qui déplacent l'**autorité de clôture HORS du
> modèle** : un « c'est vert » n'est pas cru, il est **rejoué**. Producteur et juge sont le même modèle →
> aucun « 100 » auto-attribué ne fait preuve. Le dernier filet, c'est l'humain.

**Version : 3.5.0** · 100 % autonome, **aucun plugin** · Windows / PowerShell.

> ⚠️ **Sécurité & portée** — les hooks **exécutent des commandes** lues dans les `RUN.md` (`signal-cmd:` / `check:`) à la clôture pour vérifier un « vert » hors-modèle : n'utilise ce kit que dans des **projets de confiance** (un `RUN.md` cloné = entrée non fiable). La couche de garde est **Windows/PowerShell uniquement** (les skills + la constitution sont portables, pas les hooks). Détail : [`SECURITY.md`](SECURITY.md).

**Prérequis** : **Claude Code** (CLI / desktop / IDE) · **Windows** + **PowerShell 5.1+** (les hooks sont des `.ps1`) · un dossier de projet comme `cwd`. *macOS/Linux : les skills + la constitution se chargent, mais les hooks — la couche de garde — ne se déclenchent pas.*

---

## L'idée

Un agent qui s'auto-évalue dérive : il certifie « fait » sur du texte, vise la perfection hors-sujet,
ré-écrit ses propres règles sur un mauvais diagnostic. Autowin met les décisions critiques **dans du code
déterministe** (des hooks) et **chez l'humain** — jamais dans le seul jugement du modèle.

- Un travail = **un fichier `RUN.md`** (besoin, options, journal, défauts, signal de clôture).
- Le **stop-gate** bloque la fin de tour tant qu'un run n'est pas `green` *vérifié* : il **rejoue** le
  `signal-cmd` (build/test), exécute les lignes `check:`, et refuse l'anti-fixation. Pas d'artefact → statut
  honnête « auto-déclaré, non vérifié » ; clôture sans vert = `degraded-closed` avec ton accord tracé.

## Le pipeline (6 skills + moteur)

| Skill | Rôle |
|---|---|
| `scout` | faire émerger les candidats d'amélioration sur une cible (table scorée) |
| `frame` | cadrer le **BESOIN** (le QUOI), puis — si le choix est ouvert — les **OPTIONS** d'approche |
| `terrain` | le **COMMENT** : préparer une boucle autonome observable (harnais) |
| `fixer` | résoudre **UN** défaut jusqu'au vert vérifié (rouge d'abord → vert → garde anti-régression) |
| `judge` | revue **adverse externe**, multi-lentilles décorrélées, jusqu'au seuil du régime |
| `kaizen` | améliorer le kit depuis **SES propres échecs** → PROPOSE → OK humain → intègre |
| `_engine/ENGINE.md` | les mécaniques canoniques partagées (THE CORE = 7 concepts ; le reste = référence par régime) |

Chaîne : **scout → frame → terrain → build → judge** (`fixer` sur un défaut ; `kaizen` sur un échec récurrent).

## Les garde-fous (autorité de clôture déterministe — `hooks/`)

| Hook | Ce qu'il garantit |
|---|---|
| `stop-gate.ps1` | un `green` est **rejoué / vérifié**, jamais cru ; run ouvert ou rouge → fin de tour bloquée |
| `anti-flaky.ps1` | refuse les `sleep` bruts dans le code (échappatoire : `sleep-ok: <raison>`) |
| `fix-gate.ps1` | refuse une boucle de fix aveugle sans cause vérifiée (`CausalHypothesis:` / `fix-ok:` / `check:`) |
| `advisory-guard.ps1` | rappelle de répondre **DIRECT** à une question de conseil / un signal de frustration (pas en pipeline) |
| `kaizen-detect` + `kaizen-nudge` + `kaizen-revert-log` | télémétrie des blocages récurrents → nudge → audit comportemental → **diff PROPOSÉ** → OK humain (**jamais d'auto-write**) |

`hooks/test-hooks.ps1` vérifie chaque hook hors-modèle (parse / déclenche / silencieux sur le contrôle négatif).

## Démo — le gate en action

```text
# Claude tente de clore un tour avec ce RUN.md :
status: green
regime: standard
signal-cmd: dotnet test
# → le stop-gate REJOUE `dotnet test`. Rouge ? la fin de tour est BLOQUÉE :
{"decision":"block","reason":"STOP-GATE : ... green NON VERIFIE -> REJEU signal-cmd ECHOUE"}
# Vert seulement quand l'artefact passe pour de vrai. Un signal vacant (cmd /c exit 0) est refusé,
# et une commande d'un RUN.md cloné/non-attribué n'est JAMAIS exécutée (cf. SECURITY.md).
```

Vérifie l'install toi-même : `powershell -NoProfile -File hooks\test-hooks.ps1` → `0 echec` = tous les hooks mordent.

## Installation

Pose ce dépôt sur la machine, ouvre Claude Code **dans le dossier**, et dis-lui simplement :

> **« exécute le README-INSTALLATION.md »**

Il copie les skills + hooks, câble `settings.json` (merge, jamais d'écrasement), ajoute la constitution, puis
**vérifie chaque hook** par des pipe-tests. Installation complète + mise à jour depuis une version antérieure :
**[`README-INSTALLATION.md`](README-INSTALLATION.md)**.

## Structure du dépôt

```
skills/          scout · frame · terrain · fixer · judge · kaizen  + _engine/ENGINE.md
hooks/           *.ps1 (garde-fous) + settings-snippet.json (câblage) + test-hooks.ps1
workflows/       improve-from-telemetry.js  (boucle d'amélioration pilotée par la télémétrie réelle)
output-styles/   concis-structure.md        (format de réponse scannable — optionnel)
memory/          fiches mémoire kit-génériques de démarrage (optionnel) + MEMORY.md
CONSTITUTION.md  les réflexes cardinaux, chargés à chaque session
sync-kit.ps1     propage live (~/.claude) → package en portabilisant les chemins ; -Check = diff
VERSION          version du kit
.github/         workflows/test-hooks.yml — CI : self-test des hooks à chaque push
LICENSE · SECURITY.md · CHANGELOG.md · .gitattributes
```

## La limite honnête (par design)

Les hooks garantissent la partie **déterministe** ; les réflexes de **jugement** restent probabilistes —
producteur et juges sont le même modèle, donc aucun score auto-attribué n'est une mesure. Tout vert non
adossé à un artefact s'annonce « auto-déclaré, non vérifié ». **Le filet final, c'est l'humain.**
