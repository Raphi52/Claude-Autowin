---
name: terrain
description: >-
  Step 2 of the pipeline (frame→[explore]→terrain→build→judge): from a framed need with a settled approach,
  PREPARE THE SELF-CORRECTION TERRAIN before launching autonomous work — (1) OBSERVABILITY (how Claude gets its
  screenshots + logs to loop on its own real output), (2) the ENVIRONMENT / tech, (3) the resume STATE — and
  BUILD the missing harness if absent; PLUS the loop spec the executor needs (per-increment signal, decompose
  map, cost caps, green-checkpoint, need→loop→judge wiring). The loop's EXECUTION mechanics (decompose into
  signal-bearing increments, red-first then green, parallel dispatch, anti-regression cadence, systematic
  debugging, checkpoint/rollback) are OWNED BY THE ENGINE — Chapter 4 BUILD — consulted by the executor
  during the build phase; no third-party skill is involved. Use when you want to
  launch autonomous/iterative work and must first PREPARE how Claude will loop — especially on a project/PC
  where this harness does not exist yet. Trigger on "prepare the workflow/terrain", "how will Claude loop / get its screenshots-logs", "set up self-correction / the autonomous work environment", "run Claude solo to completion". Chains after `frame` (need scoped, approach settled) and before the build,
  then `judge`. Do NOT use to frame the need or pick the approach (→ `frame`), to execute the loop mechanics
  themselves — decompose/execute a plan, TDD, test-driven increments (→ ENGINE Ch.4 BUILD, the executor's
  manual; no skill fires during the build) — nor to
  judge the finished deliverable (→ `judge`).
---

# terrain — prepare the self-correction terrain (step 2)

## Purpose
**Make the ground ready for Claude to work AUTONOMOUSLY and self-correct — BEFORE the loop starts.** A framed
need with a settled approach isn't enough to run solo: Claude must be able to SEE its own real output
(screenshots + logs), run in the right environment, and resume after interruption. Terrain installs that
observability + harness + resume-state (building what's missing) so the autonomous loop catches its own errors
instead of running blind.

## Procedure

1. **Read the RUN.md first** — header `regime:`, `## Besoin`, and the `Décision:` line of `## Options`. The chosen approach pilots the harness: a CLI approach and a GUI approach demand different observability; mounting the wrong one makes the executor blind. You spec ONLY the signal↔harness bridge specific to this task; the generic loop mechanics are **owned by ENGINE Ch.4 — BUILD**. Never re-specify those.

2. **Ex-ante devis (one line, before locking regime)**: expected turns × fan-out width × judge passes → rough token/time range. The regime dial is the human's; never set it blind without a devis. In doubt **lower + flag**, note the correction in `## Besoin`. *disposable* = minimal terrain to verify one shot (skip skill packaging); *standard* = full terrain + the engine loop (Ch.4); *critical* = full terrain + ≥1 out-of-model source (see `judge`).

3. **Detect the three prerequisites in parallel** — read-only, independent → fan-out 3 explorers in ONE message. Then mount what is missing in serialized, idempotent, reversible steps — **one builder for the build, never two concurrent**. Confirm before any heavy or irreversible action. A loop cannot self-correct without all three:

   - 🔭 **OBSERVABILITY — the feedback the loop reads.** *How does the executor see the REAL effect of its work?* By tech: **UI** → post-action screenshot READ by Claude (PrintWindow → PNG on disk; hunt an existing capture script first); **CLI / service / batch** → logs + exit code; **code / lib** → tests fail→pass (falsifiable); **data / SQL** → verification query on produced state; **doc / plan / skill** → walk ONE concrete case end to end. Two non-negotiables: **ensure-fresh** — never pilot a stale binary, check artifact timestamp and rebuild if older than source (a stale-binary incident has cost days); and a **signal that AUTO-PROVES** (ENGINE Ch.2): fresh (artifact newer than the action), non-vacuous (N>0 tests / non-empty log / exit==0 + clean stderr), run-stamp-bound to THIS run, with a negative control (does the check fail when it should?).

   - 🖥️ **ENVIRONMENT / TECH.** Stack, build/run/test commands, where logs and artifacts physically live, what is authoritative. If `frame` already recorded recon in the RUN.md — read it, don't re-scan; fill only workflow-specific gaps (feedback source, ensure-fresh gesture).

   - 📋 **RESUME STATE = RUN.md itself.** Open it `status: open` (the Stop gate then takes over closure — never set green to satisfy it). The live state lives in `## Journal` (append-only events) and `## Reprise` (Goal / Hypothesis / Tried / Next / Blockers + turn counters) — this is the 30-second resume after compaction. Fill the header `signal:` and, where possible, an **IDEMPOTENT whitelisted `signal-cmd:`** — the gate will REPLAY it rather than believe your green.

4. **Prerequisite deliverable gate**: confirm "feedback via X, env Y, state via RUN.md" is explicit and artifacts are mounted before proceeding to the loop spec.

5. **Per-increment signal** = a real-observation artifact from the harness above (screenshot read, log+exit, green test, query result) — **never self-judged text**. This is the bridge that makes the output judge-able. **It must reproduce the USER's symptom AS THEY LIVE IT** (their scenario, their view, their success criterion) — not a technical proxy adjacent to it. If ≥2 causal steps separate the signal from the terminal effect the user observes, it is NOT a closure signal (scar: "workers dispatched" passed green while the user saw failed/black tiles — the proxy was clean and entirely beside the point).

6. **Test pyramid**: pure logic in unit tests run in the HOT loop (seconds); e2e/UI/integration at the gate.

7. **Decomposition map** for parallelism (only when increments are genuinely parallel; a single deliverable stays a simple flow): annotate each `{independent | depends-on-X}` + its signal; mark **shared resources** (build / DB / bench / port) and prescribe **isolation** (worktree/scratch per increment) — a single builder only. A serial dependency map makes everything downstream serial; maximize the independent ratio deliberately.

8. **Cost caps**: global 12 turns (adjustable) + progress floor **N=3** (3 turns with no failed→done and no signal turning green → hard-stop). Plus anti-destruction (irreversible op → stop + confirm/backup).

9. **Green checkpoint + rollback to last green**: snapshot a NAMED green BEFORE each increment (commit/tag in a **disposable worktree** — abandoning = dropping the branch). On a CONFIRMED regression, REVERT to the last green and re-attack with a different hypothesis — never stack fixes on a broken state. Multi-repo green = a **coordinated TUPLE** (restoring one repo alone restores only half the green).

10. **Blockers → parallel resolvers BEFORE escalation**: on ≥2–3 exhausted distinct approaches, dispatch resolver agents with orthogonal hypotheses. Interrupt the human only for hard-stops (destructive, out-of-scope, legacy untouchable). **Anti-littering**: clean scratch at stop; keep the deliverable + RUN.md.

11. **Wire to `judge` (step 4)**: hand off an **identifiable deliverable + the RUN.md path** (so `judge` can score fidelity to `## Besoin`). Defects returned by `judge` **re-enter as new increments**, each with its own signal — quality climbs by round-trips. The cycle cap that governs the ping-pong is **`judge`'s, authoritative** — do not invent a competing local cap. **Package as a reusable skill ONLY on recurrence ≥2** (else a once-used skill costs more than it returns); name `loop-<task>`, cover frozen terrain + loop spec + handoffs, then trigger-test it.

## Output

Deliver to the user — in **plain words, no internal jargon**:

- Confirmed regime + **up-front estimate** (rough turns × time)
- Loop plan: how Claude sees its real result / the environment / how it resumes
- Terrain artifacts mounted (or proposed, awaiting confirmation)
- Task-specific spec: signal · **task breakdown** (parallel vs sequential) · caps · **last-working-snapshot** checkpoint · judge wiring
- Explicit handoff to the build (ENGINE Ch.4) · loop-skill created OR "no skill — disposable / not recurring"
- The RUN.md path

Never report "done" without a RUN.md that is **open and filled** (signal + Reprise) — the build hasn't started yet. **Exception**: a `disposable` one-shot may need no RUN at all — ENGINE regime-table + `frame` proportionality.

**Next: run the work** (per ENGINE Ch.4 — BUILD, on this terrain), **then `judge`, regime propagated.**

## Don't

- **Frame the need or pick the approach** — that's `frame`'s job; terrain starts with a settled `Décision:`.
- **Execute the loop mechanics** (decompose/execute a plan, TDD, test-driven increments) — those are ENGINE Ch.4 BUILD, the executor's manual; no skill fires during the build.
- **Re-specify generic loop mechanics** — only the task-specific signal↔harness bridge belongs here.
- **Judge the finished deliverable** — that's `judge` (step 4).
- **Set `status: green` to satisfy the Stop hook** — the gate replays `signal-cmd`; a false green blocks.
- **Mount two concurrent builders** — serialized, idempotent, reversible steps only; confirm before irreversible actions.
- **Invent a judge cycle cap** — `judge`'s cap is authoritative; terrain does not duplicate it.

## Engine & reflexes

Loop-execution mechanics — decompose into signal-bearing increments, red-first then green, parallel dispatch, anti-regression cadence, systematic debugging, checkpoint/rollback — are **canonical in `_engine/ENGINE.md` Ch.4 BUILD**. Terrain prepares the ground; the executor consults Ch.4 during the build. On any divergence between this skill and the engine, the engine wins.

Workspace convention and `signal-cmd` whitelist: **ENGINE Ch.3** (RUN.md header `status/regime/signal/signal-cmd/gate`, single-writer, FLAKY, session-scoping + legacy fallback). Signal trustworthiness (proof classes, self-proving, auto-proves): **ENGINE Ch.2**.

Workspace path (session-scoped): `Audit\workspaces\<session_id>\<subject>-workspace\RUN.md` — set the `session:` header. The installed Stop hook reads RUN.md and **blocks end-of-turn while a run is open/red** — that out-of-model gate is the real closure authority, not you.

Reflex anchor: **the signal must reproduce the USER's symptom as they live it** — a proxy two causal steps away from the terminal effect is not a closure signal.
