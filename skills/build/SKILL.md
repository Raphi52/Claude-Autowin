---
name: build
description: >-
  The PRODUCER's named loop (frame → terrain → build → judge): resolve a DEFECT into a VERIFIED green.
  Invoked TWO ways — by `judge` (which sends prioritized defects back; judge NEVER repairs what it audits) AND
  by the user directly with a raw bug. REPRODUCES first (red before any fix — a fix on an unreproduced bug
  repairs a maybe-non-bug), LOCALIZES the REAL cause (confirm which view/module/branch/build ACTUALLY runs
  before static diagnosis — never assume), fixes the NAMED cause MINIMALLY (no opportunistic refactor),
  VERIFIES red→green with an OUT-OF-MODEL artifact (test/exit code/screenshot READ/query — never self-judged
  text), GUARDS against regression, then LOOPS BACK to `judge`. Execution mechanics are CANONICAL in
  `_engine/ENGINE.md` Ch.4 — BUILD; the build wires them and carries only the delta: defect intake, triage,
  the anti-blind reflexes, and the loop-back. Trigger on "fix the bug / make it green / the test fails repair it / apply the judge's findings / resolve the defects / it's still
  broken", or right after `judge` returns defects to the producer. Do NOT use to: AUDIT quality or decide if a
  deliverable is done → `judge` (the build fixes, it NEVER judges its own fix); frame a need or decide WHAT to
  build → `frame`; prepare the observability harness / autonomous loop → `terrain`.
---

# build — resolve a defect into a VERIFIED green (the producer's loop)

## Purpose
**Take ONE defect to a green that is VERIFIED out-of-model — not self-declared.** Reproduce the bug red FIRST,
localize the REAL cause (the code that actually runs), fix only what's named, then prove red→green with a real
artifact (test / exit code / screenshot READ / query). The producer's loop: it fixes, it NEVER signs its own
quality verdict (that's `judge`) — so a defect is "done" only when an external signal says so.

## Procedure  (per defect — one at a time)

**0. Intake & triage.** One work item = one `RUN.md`; each defect = one entry in its `## Défauts` ledger (cite the proof the judge/hook gave). Several defects → order by severity / blast-radius and fix ONE at a time (a batch fix hides which change did what). Set the RUN header `regime:`. Place the RUN.md at `Audit\workspaces\<session_id>\<subject>-workspace\RUN.md` and set the `session:` header (session-scoping mechanics + legacy fallback: **ENGINE ch.3 / socle §1**). **A mono-defect fix has NO approach fork** → DELETE the template's `## Options`/`Décision:` scaffold (a repair scores no options; a leftover `Décision:` placeholder used to arm the closure anti-fixation gate — now also ignored gate-side).

**1. REPRODUCE — red FIRST.** Before touching anything, make the bug FAIL observably: a failing test, a non-zero exit, a screenshot READ, a query. A fix applied to an UNreproduced bug repairs a maybe-non-bug. No red → no fix; if you can't reproduce, investigate the repro, do not guess-patch.

**2. LOCALIZE the REAL cause.** Confirm which view / module / branch / config / **build** ACTUALLY runs BEFORE any static diagnosis — never assume the code you're reading is the code that executes (stale binary, wrong path, wrong project, another session's copy). Trace the live execution to the NAMED cause.

**3. FIX the named cause, MINIMALLY.** Touch ONLY what the defect names (reflex 11 — the unnamed stays intact). No opportunistic refactor, no "while I'm at it". Smallest change that flips red→green.

**4. VERIFY red→green OUT-OF-MODEL.** Re-run the SAME artifact from step 1 → it must now pass. The proof is the artifact (test/exit/screenshot/query), never self-judged text (reflexes 2 & 3). Without a real artifact: say "self-declared, unverified" — do not claim green. Close the RUN `green` only here (the Stop-gate replays the signal). **Adversarial coverage on YOUR own test (kaizen 2026-06-18)**: a test YOU wrote passing proves the happy path, not the absence of the bug class — for a boundary/discriminant fix, NAME an input that SHOULD make the test fail and confirm it does (mutation); if you can't construct one, status = "self-declared, coverage-unverified", not green. A self-Verify gate may PASS work downstream but is never the final authority that KILLS a finding about your own recent edit → re-challenge it (decorrelated pass / human), don't drop it.

**5. GUARD against regression.** Run the surrounding tests / a quick smoke to confirm a neighbour didn't break. A recurring class of bug worth catching → promote it into a `check:` line (the gate replays it).

**6. LOOP BACK to `judge`.** The build never decides "done". Hand the verified fix back to `judge`; if the judge sent a batch, fix the next defect and re-submit the set. `judge` re-audits — an incomplete fix or a regression comes back here.

## Output

A defect is `green` in its `## Défauts` ledger entry ONLY after step 4's artifact passed, recording: named cause + minimal fix + proof artifact. Then `judge` owns the closure verdict — never the build. The RUN.md `status: green` is the machine-readable signal the Stop-gate replays.

## Don't

- **No red → no fix** — never guess-patch an unreproduced bug.
- **The code you read ≠ the code that runs** — confirm the live path / build / branch FIRST (the #1 trap); never diagnose statically before verifying the live execution.
- **No bundled changes** — one cause, one fix; a green that bundles N changes can't attribute the fix or catch a regression.
- **No self-verdict** — the build NEVER judges its own fix; that is `judge`'s job. Relayed report ≠ truth: verify the REAL artifact (diff / file / output), never the report on its word.
- **STOP-and-ask**: outside the harness · 3+ fixes failed in a row · genuine ambiguity · destructive/prod auth. Blocked (2-3 distinct approaches exhausted) → parallel resolver sub-agents BEFORE interrupting the human (reflex 9). Interrupt only for: destructive, out-of-scope, external dependency.

## Engine & reflexes

BUILD mechanics — decompose into signal-bearing increments, red-first then green, systematic debugging, checkpoint/rollback, anti-regression cadence — are CANONICAL in `~/.claude/skills/_engine/ENGINE.md` **Ch.4 (BUILD)**. This skill wires them and adds only the build-specific delta. On divergence, the engine wins.

Reflex anchor: **`CausalHypothesis:` before any edit** — a fix without a verified cause is a guess; the fix-gate blocks blind-fix loops.
