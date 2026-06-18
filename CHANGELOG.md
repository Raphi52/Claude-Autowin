# Changelog

All notable changes to the kit. Versions follow the `VERSION` file.

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

- Skills `fixer` (producer loop) + `kaizen` (improve the kit from its own failures).
- Hook `fix-gate` (anti blind-fix loop); kaizen system (`detect` / `nudge` / `revert-log`); `advisory-guard`.
- stop-gate v3.2 — per-session scoping (concurrent sessions no longer cross-block each other).
