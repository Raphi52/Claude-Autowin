# Changelog

All notable changes to the kit. Versions follow the `VERSION` file.

## 3.6.0 — 2026-06-19

### Documentation coherence (post-churn)
- **Hook count corrected to 16** across `README.md`, `README-INSTALLATION.md`, `VERSION` (the Step 2 list,
  Step 7 verify, contents table, and UPDATE enumeration were stale at 8).
- **`fixer` → `build`** rename completed (a residual `fixer` lingered in `VERSION`).
- **`frame`** — corrected a stale ENGINE reference (`Ch.2 SCORE & RANK` → `Ch.2 JUDGE`).

### Hooks
- **`full-autonomy-directive` + `full-autonomy-allow`** documented — **opt-in, OFF by default**
  (`AUTOWIN_AUTONOMY=1` before launch): injects a "don't ask, drive to completion" directive + auto-approves
  tool calls (deny-gates still win). ⚠ dangerous — see `SECURITY.md`.
- **`build-cadence`** documented — PostToolUse nudge: after N code edits with no verify, reminds to run the
  real signal (ENGINE Ch.4); non-blocking.
- **`judge-nudge`** — no longer burns its once-per-session reminder on `RUN.md` / memory-card writes (it skips
  that pipeline noise while still nudging on a real `.md` doc deliverable).
- **`git-auth-gate`** (NEW) — enforces the kit's cardinal git rule: denies `git commit` / `git push` unless
  the user authorized this session (says commit/push/pousse, or `AUTOWIN_GIT_AUTH=1`); read-only git
  (status/log/diff/…) passes. The #1 rule finally has deterministic enforcement (kaizen finding: lesser rules
  all had hooks, this one didn't). Session class-auth model ("push-as-you-go": grant once, holds for the session).
- Newly documented (previously inline): `model-tier`, `session-inject`, `thinking-mode`, `precompact-runcheck`.

### Reflexes (kaizen — FOLDED into existing reflexes, no new numbers; the trim-or-replace discipline applied to itself)
- **Reflex 1** — a QCM whose "(Recommended)" option you'd pick anyway is a disguised acknowledgment, not a real
  fork → proceed on a stated assumption; surface only if the lead option carries a non-trivial downside.
- **Reflex 2** — a test-harness authored/extended the SAME turn (e.g. `test-hooks` exit 0) is self-consistent,
  not adversarial; the adversarial authority for a hook/security change is an external `judge` pass.
- **Reflex 4** — the agent-bracket gates ONE fan-out's size, not the COMPOUND cost of N pipeline cycles on the
  same artifact → surface session cycle-count + cumulative agents at each new cycle.
- **`kaizen` skill (integrate step)** — trim-or-replace: every reflex/fiche added must FOLD into or RETIRE an
  existing one (finite attention budget) — never proliferate a new number for what an existing reflex frames.
- **memory** — a "confirmation pass" can't produce a STOP (a same-model re-run of a same-model fix always finds
  a residual) → pre-commit a stop threshold; label self-generated debt honestly, not "kit value".

## 3.5.0 — 2026-06-18

### Security
- **stop-gate** — command replay (`signal-cmd:` / `check:`) is now **restricted to `RUN.md` files from the
  current session**; in *legacy* mode (no session id passed to the hook) **no replay occurs**.
  Closes the **RCE-by-clone** vector (a cloned/foreign `RUN.md` no longer launches commands). Single-trusted-machine opt-in:
  `AUTOWIN_TRUST_REPLAY=1`. The open/red block remains active (closure is not disarmed).
- Added **`SECURITY.md`** (trust model, platform, disclosure channel).

### Guard hardening
- **stop-gate** — allowlist proof (a real test/build runner or a script) applied to `signal-cmd`
  **+ `check:` + critical regime**: closes `cmd /c "exit 0"`, `cmd /c call exit 0`, and the empty `check:`
  that used to certify a *critical* green. Allowlist is case-insensitive + supports `pwsh`, with word-boundary.
  **fail-closed** on unreadable stdin **or non-object** (JSON scalar). Reads `RUN.md` files as UTF-8.
- **fix-gate** — `fix-gate: off` is now **anchored** (prose no longer disarms it); `fix-ok:` requires a
  non-empty justification; the file must be named on a token line; project root restored (guarded by `Test-Path`).
- **anti-flaky** — covers `time.sleep` / `setTimeout` / `::Sleep` / `sleep` alias / **floating-point** sleeps /
  `_` separator / parenthesized call (`Start-Sleep([int]5)`).
- **kaizen-detect** — fixture filter configurable via `KAIZEN_FIXTURE_PATHS`.

### Tools & repository
- **`hooks/test-hooks.ps1`** — portable harness (`$PSScriptRoot`) + extended coverage (regressions for all
  bypass cases above).
- **CI** `.github/workflows/test-hooks.yml` — self-test of the hooks on every push.
- `LICENSE` (MIT), `.gitattributes`, `CHANGELOG.md`.
- `workflows/improve-from-telemetry.js` — improvement loop driven by real telemetry (made portable).

### Known limit
"Shippable / perfect" requires **external validation** (real beta users, audit by another model) —
out of scope for self-editing. The *replay-consent* redesign + strict session-scoping on the harness
side remain on the roadmap (see `SECURITY.md`).

## 3.4.0

- Skills `build` (producer loop) + `kaizen` (improve the kit from its own failures).
- Hook `fix-gate` (anti blind-fix loop); kaizen system (`detect` / `nudge` / `revert-log`); `advisory-guard`.
- stop-gate v3.2 — per-session scoping (concurrent sessions no longer cross-block each other).
