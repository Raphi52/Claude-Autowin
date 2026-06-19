# Autowin — a self-correcting work system for Claude Code

[![test-hooks](https://github.com/Raphi52/Claude-Autowin/actions/workflows/test-hooks.yml/badge.svg)](https://github.com/Raphi52/Claude-Autowin/actions/workflows/test-hooks.yml) · [MIT](LICENSE) · [CHANGELOG](CHANGELOG.md) · [SECURITY](SECURITY.md)

> A pipeline of *skills* + deterministic guardrails that move **closure authority OUTSIDE the
> model**: a "it's green" claim is never taken at face value — it is **replayed**. Producer and judge are the
> same model → no self-awarded "100" constitutes proof. The last line of defense is the human.

**Version: 3.5.0** · 100% self-contained, **no plugins** · Windows / PowerShell.

> ⚠️ **Security & scope** — hooks **execute commands** read from `RUN.md` files (`signal-cmd:` / `check:`) at closure time to verify a "green" state outside the model: only use this kit in **trusted projects** (a cloned `RUN.md` is an untrusted input). The guardrail layer is **Windows/PowerShell only** (skills + the constitution are portable; hooks are not). Details: [`SECURITY.md`](SECURITY.md).

**Prerequisites**: **Claude Code** (CLI / desktop / IDE) · **Windows** + **PowerShell 5.1+** (hooks are `.ps1` files) · a project folder as `cwd`. *macOS/Linux: skills + the constitution load fine, but hooks — the guardrail layer — do not fire.*

---

## The idea

An agent that self-evaluates drifts: it certifies "done" on text alone, chases off-topic perfection,
rewrites its own rules on a faulty diagnosis. Autowin puts critical decisions **in deterministic code**
(hooks) and **with the human** — never in the model's judgment alone.

- One work item = **one `RUN.md` file** (need, options, journal, defects, closure signal).
- The **stop-gate** blocks end-of-turn until a run is *verified* `green`: it **replays** the
  `signal-cmd` (build/test), runs every `check:` line, and rejects anti-fixation. No artifact → honest
  status "self-declared, unverified"; closing without green = `degraded-closed` with your explicit sign-off traced.

## The pipeline (6 skills + engine)

| Skill | Role |
|---|---|
| `scout` | surface improvement candidates on a target (scored table) |
| `frame` | define the **NEED** (the WHAT), then — if the choice is open — the **approach OPTIONS** |
| `terrain` | the **HOW**: prepare an observable autonomous loop (harness) |
| `build` | resolve **ONE** defect through to verified green (red first → green → regression guard) |
| `judge` | **adversarial external** review, uncorrelated multi-lens, up to the regime threshold |
| `kaizen` | improve the kit from **its own failures** → PROPOSE → human OK → integrate |
| `_engine/ENGINE.md` | shared canonical mechanics (THE CORE = 7 concepts; the rest = regime reference) |

Chain: **scout → frame → terrain → build → judge** (`build` for a defect; `kaizen` for a recurring failure).

## The guardrails (deterministic closure authority — `hooks/`)

| Hook | What it enforces |
|---|---|
| `stop-gate.ps1` | a `green` is **replayed / verified**, never trusted; open or red run → end-of-turn blocked |
| `anti-flaky.ps1` | rejects raw `sleep` calls in code (escape hatch: `sleep-ok: <reason>`) |
| `fix-gate.ps1` | rejects a blind fix loop without a verified cause (`CausalHypothesis:` / `fix-ok:` / `check:`) |
| `advisory-guard.ps1` | reminds Claude to answer **DIRECTLY** on advisory questions / frustration signals (not via pipeline) |
| `kaizen-detect` + `kaizen-nudge` + `kaizen-revert-log` | telemetry on recurring blockers → nudge → behavioral audit → **PROPOSED diff** → human OK (**never auto-write**) |
| `full-autonomy-*.ps1` | **opt-in, OFF by default** (`AUTOWIN_AUTONOMY=1`, set before launch): injects a "don't ask, drive to completion" directive + auto-approves tool calls. ⚠ dangerous — see [`SECURITY.md`](SECURITY.md) |

`hooks/test-hooks.ps1` verifies every hook out-of-model (parse / fires / silent on negative control).

## Demo — the gate in action

```text
# Claude attempts to close a turn with this RUN.md:
status: green
regime: standard
signal-cmd: dotnet test
# → the stop-gate REPLAYS `dotnet test`. Fails? End-of-turn is BLOCKED:
{"decision":"block","reason":"STOP-GATE : ... green NON VERIFIE -> REJEU signal-cmd ECHOUE"}
# Green only when the artifact genuinely passes. A vacuous signal (cmd /c exit 0) is rejected,
# and a command from a cloned/unattributed RUN.md is NEVER executed (see SECURITY.md).
```

Verify the install yourself: `powershell -NoProfile -File hooks\test-hooks.ps1` → `0 echec` = all hooks bite.

## Installation

Clone this repo onto your machine, open Claude Code **in the folder**, and simply tell it:

> **"execute README-INSTALLATION.md"**

It copies the skills + hooks, wires `settings.json` (merge, never overwrite), adds the constitution, then
**verifies every hook** with pipe-tests. Full installation + upgrade from a previous version:
**[`README-INSTALLATION.md`](README-INSTALLATION.md)**.

## Repository structure

```
skills/          scout · frame · terrain · build · judge · kaizen  + _engine/ENGINE.md
hooks/           *.ps1 (guardrails) + settings-snippet.json (wiring) + test-hooks.ps1
workflows/       improve-from-telemetry.js  (improvement loop driven by real telemetry)
output-styles/   concis-structure.md        (scannable response format — optional)
memory/          kit-generic starter memory cards (optional) + MEMORY.md
CONSTITUTION.md  cardinal reflexes, loaded every session
sync-kit.ps1     propagates live (~/.claude) → package, portabilizing paths; -Check = diff
VERSION          kit version
.github/         workflows/test-hooks.yml — CI: hook self-test on every push
LICENSE · SECURITY.md · CHANGELOG.md · .gitattributes
```

## The honest limit (by design)

Hooks guarantee the **deterministic** part; **judgment** reflexes remain probabilistic —
producer and judges are the same model, so no self-awarded score is a measurement. Any green not backed
by a real artifact is declared "self-declared, unverified". **The final safety net is the human.**
