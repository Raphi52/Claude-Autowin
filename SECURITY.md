# Security Policy

## Trust model — READ THIS

Autowin installs **PowerShell hooks** into Claude Code. The Stop hook (`stop-gate.ps1`) **executes commands**
declared in `RUN.md` files — the `signal-cmd:` and `check:` lines — by replaying them at turn-close to verify
a "green" out-of-model. **Therefore a `RUN.md` is executable input.**

- **Only use this kit in projects you TRUST.** Treat a cloned or shared repository's `RUN.md` as **untrusted
  input**: opening such a project and letting a turn close can run its `signal-cmd:` / `check:` commands.
- The replay is constrained to a whitelist of *launchers* (`dotnet test|build|run`, `powershell`/`pwsh -File`,
  `cmd /c`) and to commands that look like a real test/build runner or a script — but the whitelist gates the
  **launcher, not the payload**: a whitelisted launcher can still run arbitrary project code (a script you
  point it at, a build target, a test fixture).
- **Review `hooks/*.ps1` and `hooks/settings-snippet.json` before installing**, and prefer pinning to a tagged
  release / a verified commit over installing from an arbitrary fork.

## Platform

Hooks are **Windows / PowerShell only**. On macOS/Linux the skills and the constitution still load, but the
deterministic hooks (the closure layer — the headline feature) **do not fire**.

## Escape hatches (intentional, documented)

`sleep-ok:` · `fix-ok:` · `fix-gate: off` · `gate: off` deliberately relax specific gates for a justified
case — see `README-INSTALLATION.md`. They are honest opt-outs, not bypasses to hide.

## Known limitation (on the roadmap, not yet fixed)

When the harness does not supply a session id to a hook, session-scoping can fall back to a broader scan of
`RUN.md` files under the working directory. A hardened *per-session-only* scoping plus an explicit
**consent prompt before any command replay** are planned. Until then, the trust model above applies.

## Reporting a vulnerability

Open a **private Security Advisory** on the GitHub repository (Security tab → *Report a vulnerability*), or a
regular issue for non-sensitive reports. Supported version: the latest `main` / newest tag.
