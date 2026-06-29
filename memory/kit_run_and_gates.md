---
name: kit_run_and_gates
description: "How the kit's closure layer works: one work item = one RUN.md (status / regime / signal-cmd / check / gate / session headers); the Stop-gate REPLAYS the proof to verify a 'green'. Trap: a signal-cmd must be a real test/build runner or a script — a vacuous `cmd /c exit 0` proves nothing and is blocked."
metadata:
  node_type: memory
  type: reference
---

**One work item = one `RUN.md`** (under `~\.claude\runs\<session_id>\<subject>-workspace\` — user-global default, out of any project tree; override via env `AUTOWIN_RUN_ROOT`; legacy per-project `<cwd>\Audit\workspaces\` honored during transition). Machine-parseable header:
- `status:` open | green | red | degraded-closed   ·   `regime:` disposable | standard | critical
- `signal-cmd:` an IDEMPOTENT command the Stop-gate REPLAYS to prove green (whitelisted launchers: `dotnet test|build`, `powershell -NoProfile -File`, …)   ·   `check:` lessons promoted to replayed commands   ·   `gate: off` (justified opt-out)   ·   `session:` (scoping).

**The Stop-gate** (Stop hook) blocks end-of-turn unless every owned RUN is `green` (VERIFIED) or `degraded-closed` (USER-OK). A "green" is not believed — the gate **re-runs** the proof. It enforces only THIS session's runs (placed under `~\.claude\runs\<my id>\`, or legacy `<cwd>\Audit\workspaces\<my id>\`, or carrying `session:`).

**Escape hatches** (honest, documented opt-outs — never to hide): `gate: off` · `sleep-ok:` (anti-flaky) · `fix-ok:` / `fix-gate: off` (fix-gate). Always with a real written justification.

**Trap** — a `signal-cmd`/`check` must invoke a real runner (test/build) or a script; a vacuous `cmd /c exit 0` proves nothing and is BLOCKED. On Windows the gate replays under `cmd.exe /c`, so use `powershell -NoProfile -File X.ps1`, not `& "X.ps1"` (`&` is not a cmd operator → false BLOCK). See [[skill_build]] (verify red→green) and [[skill_judge]] (closure authority lives outside the model).
