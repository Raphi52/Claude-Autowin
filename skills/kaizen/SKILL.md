---
name: kaizen
description: >-
  Continuous-improvement loop on Claude's OWN behavior: turn a session (BY DEFAULT the CURRENT one it is
  invoked in) into VERIFIED, human-approved EDITS to the kit files — `skills/` · `hooks/*.ps1` ·
  `settings.json` · `CLAUDE.md` (+ `CONSTITUTION.md` mirror) · memory — that improve Claude's FUTURE behavior.
  ORCHESTRATES, never re-implements the audit: (1) LOCATE the target — BY DEFAULT the CURRENT session it is
  invoked in (reconstruct it from its OWN transcript `~/.claude/projects/<project>/<SESSION_ID>.jsonl`, the
  `SESSION_ID` injected each turn by the UserPromptSubmit hook); OR a named PAST session ("kaizen session X /
  the last one I tried to kaizen" → find by first-prompt / topic / a prior `kaizen`-fork); OR a named
  behavior; OR a recurrent telemetry pattern surfaced by the `kaizen-nudge` Stop hook; (2) AUDIT behaviorally by REUSING
  `judge` Mode B (parallel behavioral lenses — anchoring/honesty, communication, scope-drift, cross-session
  state, model-shared blind spot… — each finding 1-2 blind spots with a FALSIFIABLE anchor quoted from the
  transcript + a severity; loop with new lenses until 2 dry rounds); (3) CONSOLIDATE to ONE root cause + a
  ranked table (blind spot · anchor · proposed rule · integration point); (4) PROPOSE — never impose, NEVER
  auto-write (closure authority is the human — a self-audit that auto-edits its own rules would cause serious damage,
  proven: producer=judge is not proof). On EXPLICIT human OK only: (5) INTEGRATE the approved diffs, preferring
  a WIRED trigger (hook + CLAUDE.md hard rule) over a passive memory fiche (loading ≠ applying — a fiche alone
  was violated twice the same session), VERIFY each edited hook with an out-of-model signal (parse + behavior +
  negative control), then run `sync-kit.ps1` (live→package) and log the treated signature to
  `kaizen-treated.jsonl`. Mechanics are CANONICAL in `_engine/ENGINE.md` + `judge` Mode B; kaizen carries only
  the delta: target-location, the integrate-on-approval step, sync-kit, and the never-auto-write constraint.
  Trigger on "kaizen this session", "improve the kit from my recurring failures", "audit
  my habits / workflow / blind spots", "what do I systematically miss", OR right after the `kaizen-nudge` hook
  surfaces a recurrent failure pattern. Do NOT use to: audit the QUALITY of a one-off deliverable → `judge`
  (Mode A); fix a single code defect → `fixer`; frame a new need → `frame`. Kaizen targets the BEHAVIOR/kit,
  not a specific artifact.
---

# kaizen — improve the system from its own failures (behavioral audit → propose → human-OK → integrate)

## Purpose
**Make the SYSTEM learn from its own failures — so the same mistake doesn't recur next session.** Turn a
session's blind spots (defects Claude hit, corrections the user gave) into VERIFIED, human-approved edits to
the kit (CLAUDE.md reflexes / hooks / skills / memory) that change FUTURE behavior. It only PROPOSES — it NEVER
auto-writes its own rules (closure authority is the human; a self-editing audit would grave noise on a misread).

## Procedure
1. **LOCATE the target** (the step judge Mode B doesn't carry). **DEFAULT = the CURRENT session** — the conversation `/kaizen` is invoked in. Read its OWN transcript on disk: `~/.claude/projects/<project>/<SESSION_ID>.jsonl` (+ `subagents/`, `tool-results/`), where `<SESSION_ID>` is the id injected each turn by the UserPromptSubmit hook (also visible in any `SESSION_ID=…` system reminder). The transcript is written as the session runs, so it's available mid-session — point the audit lenses at THAT file. No need to ask which session; "kaizen" alone = kaizen THIS one. Other targets, only if the user names them (confirm, don't assume):
   - **a named PAST session** — "kaizen session X / the last one I tried to kaizen". Find it by first user prompt, dominant topic, or a prior `kaizen`/`kaizen-past-session` fork. **Cite the evidence** (first prompt + a topic line) and CONFIRM before auditing — a wrong target wastes the whole fan-out. Given a disambiguator (a remembered first prompt, a topic), grep all `projects/*/*.jsonl` for it.
   - **a named behavior / habit / skill-set** — pass straight to Mode B's behavioral lenses.
   - **a recurrent telemetry pattern** — the `kaizen-nudge` Stop hook fired on `gate-counters.jsonl` (anti-flaky / fix-gate / revert recurring ≥ threshold). The pattern IS the target; audit whether it's a real habit or inflated noise (the detector itself can be the defect).
2. **AUDIT — reuse `judge` Mode B (do NOT reimplement).** Run judge Mode B on the target: preload "already covered" (global `CLAUDE.md` + memory index + installed skills) so lenses don't re-flag the known; fan out 6-9 behavioral lenses IN PARALLEL (one message), model-diverse to decorrelate; each returns 1-2 NEW blind spots, each with a **falsifiable anchor** (exact quote + line) + severity + a proposed rule + an integration point. Loop with NEW lenses until 2 dry rounds (cap 3).
3. **CONSOLIDATE.** Dedup across lenses; surface the ONE root cause (what a single specialist would miss) + a ranked table: `blind spot · anchor · severity · proposed rule · integration point (hook / CLAUDE.md hard-rule / memory / just-known)`. **Adjudicate** the lenses — reject a finding that re-flags a deliberate decision or overstates (you verify the real artifact, never a lens's word). State honest caveats (same-AI correlation; no planted-defect canary run).
4. **PROPOSE — never impose, NEVER auto-write** (CARDINAL — closure authority is the human). Present the table in PLAIN words. **Ship nothing to CLAUDE.md / CONSTITUTION / a skill / a hook / memory without explicit human OK.** The model NEVER auto-rewrites its own rules; a self-audit that auto-edits its own rules would cause serious damage. A producer=judge "100" is not proof; an auto-write loop would cause serious damage on a mis-read (lived: "intrinsic" concluded wrongly 3× — a human gate caught it). Kaizen detects + proposes; a human approves; only then is anything written.
5. **INTEGRATE — edit the kit to change FUTURE behavior (only on explicit human OK).** The deliverable IS the edit. Each approved blind spot maps to a concrete edit in one of the kit files — pick the target by the kind of fix (the **target-map**):
   - **a triggered reflex / hard rule** → `CLAUDE.md` (+ mirror `CONSTITUTION.md`) — the reflexes loaded every session.
   - **an automatic, deterministic guardrail** → a **hook** (`hooks/*.ps1`) + its **wiring in `settings.json`** (and the package `hooks/settings-snippet.json`). This is the STRONGEST fix — code that fires on its own.
   - **a workflow/skill behavior** → the relevant `skills/<x>/SKILL.md` (or a new skill).
   - **a recall-only nuance** → a `memory/` fiche + the `MEMORY.md` index.

   Then:
   - **Prefer a WIRED trigger** (a hook + a CLAUDE.md/CONSTITUTION hard rule) over a passive memory fiche — loading ≠ applying (a fresh fiche was violated twice the same session). Memory fiche = reinforcement, not the primary enforcement.
   - **Edit on the REAL file** (read it first — never edit on a sub-agent's report), surgically, on what is NAMED. Don't redesign deliberate, hardened mechanisms in passing (that's a blind-fix — flag it as a design question to the human instead).
   - **VERIFY each edited hook out-of-model** via `~/.claude/hooks/test-hooks.ps1` (per hook: parses, fires on the right input, SILENT on the negative control — it catches a closure hook gone fail-open). Extend its fixtures when you add/edit a hook, and add a `check: powershell -NoProfile -File <…>\hooks\test-hooks.ps1` line to the RUN so closure re-runs it. Never break the closure-authority hooks.
   - **Propagate**: `sync-kit.ps1` (live→package) after editing any live skill/ENGINE/hook/output-style; a NEW file (skill/hook) must also be ADDED to the sync-kit manifest + the README install steps (the manifest is a fixed list — new items are silently missed otherwise).
   - **Close the loop**: append the mandatory JSONL line to `~/.claude/kaizen-treated.jsonl` (schema in **Output**).

## Output
The deliverable is the PROPOSE table (presented in PLAIN words) → on human-OK, the integrated edits + the close-the-loop log line.

**PROPOSE table** — ranked, one row per consolidated blind spot:

| blind spot | anchor | severity | proposed rule | integration point |
|---|---|---|---|---|
| what a single specialist would miss | exact quote + line from the transcript | sev | the rule to install | hook / CLAUDE.md hard-rule / memory / just-known |

**Mandatory `kaizen-treated.jsonl` schema** — append ONE line to `~/.claude/kaizen-treated.jsonl` per treated signal:
`{"gate":"<fix-gate|anti-flaky|stop>","treatedCount":<count at treatment>,"ts":"<iso>","note":"<what changed>"}`
`gate` + `treatedCount` are REQUIRED: `kaizen-nudge.ps1` filters by `gate` and reads `treatedCount` to gate the re-nudge (≥ +5) — a line missing either silently breaks the anti-spam. The nudge then goes silent on the resolved (re-nudge only if the count climbs ≥ +5 again).

**Done** — recap in plain words: root cause, what was integrated + where, what was VERIFIED (the out-of-model signal), caveats. **Never report "integrated/done"** without the verification artifact. The human is the final net.

## Don't
- **Auto-write / impose** — kaizen PROPOSES; nothing reaches CLAUDE.md / CONSTITUTION / a skill / a hook / memory without explicit human OK (closure authority is the human; producer=judge is not proof).
- **Reimplement the audit** — reuse `judge` Mode B; kaizen orchestrates, it doesn't re-derive the lens machinery.
- **Trust a lens's word** — adjudicate; reject a finding that re-flags a deliberate decision or overstates; edit on the REAL file, never a sub-agent's report.
- **Prefer a passive fiche to a WIRED trigger** — loading ≠ applying; a hook + hard rule beats a memory fiche alone.
- **Report "integrated/done"** without the out-of-model verification (`test-hooks.ps1`) AND `sync-kit.ps1` propagation AND the `kaizen-treated.jsonl` line.

## Engine & reflexes
- Mechanics are CANONICAL in `~/.claude/skills/_engine/ENGINE.md` and in `judge` **Mode B** (behavioral audit). Kaizen ORCHESTRATES them and carries only its delta: target-location, the integrate-on-approval step, sync-kit, and the never-auto-write constraint. **On divergence, the engine + judge Mode B win.**
- Cardinal constraint (constitution): the model NEVER auto-rewrites its own rules — closure authority is the human. Kaizen detects + proposes; a human approves; only then is anything written.
