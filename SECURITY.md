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

## Full-autonomy hooks (OPT-IN, OFF by default) — ⚠ dangerous

Two hooks implement a "full-autonomy" toggle, both **inert unless you opt in**:
- `full-autonomy-directive.ps1` (UserPromptSubmit) — injects a "don't ask the user, drive each task to
  completion" directive. **Behavioral only** — it changes how Claude works, not permissions.
- `full-autonomy-allow.ps1` (PreToolUse `*`) — returns `permissionDecision: allow` for **every** tool call,
  so users WITHOUT `defaultMode: bypassPermissions` get unattended approval. (Redundant if you already run
  `bypassPermissions`.)

**Toggle**: env var `AUTOWIN_AUTONOMY=1` (case-insensitive; **set before launching Claude Code**) — env-var
ONLY. Unset → the hooks emit nothing (normal flow). Fail-safe: an unreadable payload never auto-approves.
*(An earlier file-sentinel toggle (`~/.claude/autonomy.on`) was removed: Claude could write that file mid-session
to self-enable full autonomy without consent. Env-var-only closes it — the hooks read the parent Claude Code
process environment, which Claude cannot change mid-session.)*

**What stays as your net even when ON:** `deny` beats `allow` and **all** matching PreToolUse hooks still
run → `anti-flaky` and `fix-gate` keep BLOCKING their `Write|Edit` cases; `deny`/`ask` **permission rules** in
`settings.json` still override the hook's `allow`; the Stop-gate still blocks a false "green".

**Trust assumptions** (Claude Code runtime contracts — checked against the docs and observed live): (1) when
several PreToolUse hooks fire, `deny` beats `allow` and ALL hooks run — so the deny-gates bite even under
full-autonomy. The per-hook *non-disarm* is unit-tested (the gates still emit `deny` with the toggle ON); the
`deny>allow` ordering itself is the CC contract, not unit-testable in the harness. (2) The Stop-gate is
**structural** (a Stop hook enforced by exit code), not behavioral — the directive's "always surface a
Stop-gate block" line is defense-in-depth, not the primary enforcement.

**⚠ The real hole:** the kit only gates `Write|Edit`. With the allow hook ON, **destructive `Bash`
(`rm -rf`, `git push`, prod commands, network egress) is auto-approved** — no kit hook gates Bash. If you
enable it, keep explicit `deny`/`ask` permission rules for the dangerous Bash surface in `settings.json`
(those win over the hook), and prefer disposable / sandboxed environments.

## Known limitation (on the roadmap, not yet fixed)

When the harness does not supply a session id to a hook, session-scoping can fall back to a broader scan of
`RUN.md` files under the working directory. A hardened *per-session-only* scoping plus an explicit
**consent prompt before any command replay** are planned. Until then, the trust model above applies.

## Reporting a vulnerability

Open a **private Security Advisory** on the GitHub repository (Security tab → *Report a vulnerability*), or a
regular issue for non-sensitive reports. Supported version: the latest `main` / newest tag.
