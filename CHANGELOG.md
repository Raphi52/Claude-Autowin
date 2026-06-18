# Changelog

Toutes les évolutions notables du kit. Les versions suivent le fichier `VERSION`.

## 3.5.0 — 2026-06-18

### Sécurité
- **stop-gate** — le rejeu d'une commande (`signal-cmd:` / `check:`) est désormais **restreint aux `RUN.md`
  de la session courante** ; en mode *legacy* (pas de session id transmise au hook) **aucun rejeu** n'a lieu.
  Ferme le vecteur **RCE-by-clone** (un `RUN.md` cloné/étranger ne lance plus de commande). Opt-in mono-poste
  de confiance : `AUTOWIN_TRUST_REPLAY=1`. Le blocage open/red reste actif (la clôture n'est pas désarmée).
- Ajout de **`SECURITY.md`** (modèle de confiance, plateforme, canal de divulgation).

### Durcissement des gardes
- **stop-gate** — preuve en **allowlist** (un vrai runner test/build ou un script) appliquée à `signal-cmd`
  **+ `check:` + régime critical** : ferme `cmd /c "exit 0"`, `cmd /c call exit 0`, et le `check:` vacant qui
  certifiait un green *critical*. Whitelist insensible à la casse + `pwsh`, avec word-boundary. **fail-closed**
  sur stdin illisible **ou non-objet** (scalaire JSON). Lecture des `RUN.md` en UTF-8.
- **fix-gate** — `fix-gate: off` **ancré** (la prose ne désarme plus) ; `fix-ok:` exige une justification
  non vide ; le fichier doit être nommé sur une ligne-token ; root projet restauré (guardé par `Test-Path`).
- **anti-flaky** — couvre `time.sleep` / `setTimeout` / `::Sleep` / alias `sleep` / sleeps **flottants** /
  séparateur `_` / appel parenthésé (`Start-Sleep([int]5)`).
- **kaizen-detect** — filtre de fixtures configurable via `KAIZEN_FIXTURE_PATHS`.

### Outils & dépôt
- **`hooks/test-hooks.ps1`** — harness portable (`$PSScriptRoot`) + couverture étendue (régressions de tous
  les bypass ci-dessus).
- **CI** `.github/workflows/test-hooks.yml` — self-test des hooks à chaque push.
- `LICENSE` (MIT), `.gitattributes`, `CHANGELOG.md`.
- `workflows/improve-from-telemetry.js` — boucle d'amélioration pilotée par la télémétrie réelle (portabilisé).

### Limite assumée
« Commercialisable / parfait » exige une **validation externe** (bêta réels, audit par un autre modèle) hors
de portée d'une auto-édition. Le redesign *consentement-au-replay* + le scope-session strict côté harnais
restent sur la roadmap (cf. `SECURITY.md`).

## 3.4.0

- Skills `fixer` (boucle producteur) + `kaizen` (amélioration du kit depuis ses échecs).
- Hook `fix-gate` (anti blind-fix loop) ; système kaizen (`detect` / `nudge` / `revert-log`) ; `advisory-guard`.
- stop-gate v3.2 — scope par session (sessions concurrentes ne se cross-bloquent plus).
