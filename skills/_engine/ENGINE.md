# ENGINE — the foundation (to keep in mind) + the reference (to consult when the moment comes)

> **Single canonical source**; skills carry a compact summary + a pointer here; on divergence the engine wins.
> Routing by hardness: *structure > blocking gate > annotation > memory > skill > doc*.

## Purpose — the orchestrator (the main session that drives everything)
**Turn a request into work that is actually DONE and VERIFIED.** Drive the pipeline (scout → frame → terrain →
build → judge), delegate in parallel, and **SELF-CORRECT on real out-of-model output** — while keeping
**closure authority OUTSIDE the model** (the hooks + the human). Never trust your own "green": a *done* is
proven by an artifact, or it is labeled "self-declared, unverified". Everything below — the 7 foundation
concepts, the skills, the reflexes — is HOW.

---

## ⚡ THE FOUNDATION — the only 7 things to keep in mind (day-1; everything else is CONSULTED)

1. **One task = ONE file**: `RUN.md` in its **session-scoped** workspace (`~\.claude\runs\<session_id>\<subject>-workspace\` — the `session_id` is injected every turn by the UserPromptSubmit hook; Stop-gate v3.2 enforces ONLY the runs of its own session → no more cross-blocking between concurrent sessions).
   Header: `status: open|green|red|degraded-closed` · `regime:` · `signal:` · `signal-cmd:` (optional, REPLAYABLE) · `signal-attestable:` (optional — non-replayable out-of-model proof, e.g. capture read + run-stamp; in CRITICAL, satisfies the proof requirement when there is neither `signal-cmd` nor `check:`) · `session:` (scope; otherwise the `<session_id>\` location is authoritative) · `gate: off` (justified opt-out).
   ⚠️ `signal-cmd` is executed via `cmd /c` EXACTLY as written — it is an artifact too: **quote every
   path containing spaces**, and never declare a command you have not run yourself at least once.
   (Scar from the first live replay: an unquoted `C:\Mon Projet\…` made a green unrepayable even though
   it had been verified 5× — the gate rejected it, rightly.)
2. **One blocking gate: closure.** Run `open`/`red` → the end of turn is blocked. Run `green` → the gate
   does NOT take your word for it: it **replays** `signal-cmd` (idempotent whitelist), **executes** your `check:` lines,
   verifies anti-fixation, and **blocks an unchecked real-content DoD box (`- [ ]`) in `## Besoin`** (box-state only;
   the proof behind a checked box stays judge+human) — once per transition. Everything else annotates, or does not exist.
3. **Honest verdict: GREEN / RED / INVALID — INVALID by default.** Absence of proof is never a
   green. A green without an out-of-model artifact is stated as: "self-declared, unverified". **Same for every
   conclusion stated along the way** ("it's X · impossible · intrinsic · it's fixed"): labeled
   HYPOTHESIS + confidence until an out-of-model artifact anchors it. An "impossible/intrinsic" →
   first ask "has this ever worked?" (if yes = REGRESSION, not a limit). Asserting a hypothesis
   as a fact cuts off the human's investigation and forces a retraction the next turn.
4. **Regime is THE dial**: `disposable` = zero ceremony (no RUN, gates disarmed) ·
   `standard` = light (reduced panel, 1 replay at closure) · `critical` = fully armed (full panel, canary,
   out-of-model source). Effort follows stakes, mechanically.
5. **~10 cardinals in memory** ("THE MOMENT X → Y") — the reflexes; memory proposes, the gate disposes.
6. **A durable lesson becomes code when possible**: a `check: <command>` line in the RUN
   (the gate executes it) or a memory rule otherwise. An unpersisted correction regenerates.
7. **4 accelerator skills** — `frame` (need+options) · `terrain` (harness) · `judge` (review) · `scout`
   (candidates). **The foundation works with ZERO skill triggered**; their trigger rate is measured
   (routers), not assumed.

**Cost per regime** (ceremony only exists if the stakes justify it):
| Regime | RUN.md | Gate at closure | Review panel | Canary |
|---|---|---|---|---|
| disposable | no | passes | 1 judge or skip | no |
| standard | yes | replay+checks (1×/transition) | Faithful + 2-4 risk dims | sampled |
| critical | yes | replay+checks | full + doubled [S] + out-of-model | **yes** |

---

# REFERENCE (do not memorize — consult when the moment comes)

## Ch.1 — GENERATE & GATE *(used during `frame`/`scout`: generate broadly, surface only the decisive)*

**Pattern**: POOL → SCORE → GATE → auto-resolve the routine | surface the decisive. The human is the
scarcest resource and the only true oracle — never lulled with OK-OK. Autonomy NEVER extends to
closure (foundation §2-3).

- **Generate broadly and DIVERSELY, in parallel**: 1 generator per orthogonal lens (ONE message), each in the **SHARPEST expert posture of its lens** ("you are the Breaker/Naive/… — find what a generalist misses"); a sharpened posture is a free quality lever on the PRODUCER/generator side (NOT on the judge — Ch.2 has its own). Lenses —
  *questions*: Naive · Breaker · Contradictor · Perfectionist · Diplomat · Explorer · Pragmatist · Emotional.
  *Approaches*: MVP · robust · perf · lean · reuse · creative · cost · UX · convention · contrarian.
  *Improvement candidates*: grep-markers families AND stream-reading AND **bold/ambition lenses** (10x-not-10% · cross-discipline transfer · remove-the-biggest-constraint · fuse-two-parts · scale ×1000 · "if you rebuilt this today" · **anchored-ambition** = read ONLY the target's central goal, ask for the 10x of THAT goal — creative AND on-target, distinct from the blind clean-room) AND (relevance-gated) web-anchored prior-art (external tools/techniques mapped onto the target, CITED — scout default mode). Search for what EXISTS before
  proposing, cite the facts; output CONCRETE-EXTREME (`Dupont,"Le Grand"\nSARL`) — abstractions are rejected on receipt. **Loop-until-dry**: each turn receives what was already found ("NEW only"); stop at 2 dry turns OR cap
  (~12 candidates / ~10 turns, log what was cut). The **bold/ambition arm loops to its OWN dry-round (separate cap + reserved output slots)** — else cheap incremental fixes saturate the shared cap before the hard/creative ideas emerge (the incremental trap, generator side). **The bold arm runs anchoring-free by default (CLEAN-ROOM)** — EXCEPT anchored-ambition, which reads ONLY the central goal (never the TODOs/impl); neither derives from the target's TODOs/limits (that yields "complete-the-planned" candidates, NOT divergence); **SELF-GATE before finalizing: if every bold 🆕 merely extends something already named in the target, you did NOT diverge — re-run forcing each named lens (10x / anchored-ambition / rebuild-today) to BREAK a premise.** (Listing the lenses ≠ executing them — a fresh run defaults to TODO-reading unless this gate bites; lived 2026-06-30.) **Dedup by core-idea** before scoring. Exclusive resources
  (build/bench/DB/port): one owner only — isolate or serialize.
- **Two /100 scales, never merged**: **impact** (80-100 = changes the NATURE → surfaced unconditionally ·
  50-79 strong constraint · 30-49 useful · <30 drop) ⟂ **autonomy-confidence** (measured AFTER research:
  ≥80 = CITED fact · 50-79 multiple readings · <50 guess).
- **DISPLAYING a shortlist for a human pick (scout candidates; the top-K options PRESENTED in frame Pass-B): rank by IMPACT, show EFFORT as a SEPARATE visible axis — NEVER hand the human a single collapsed band.** A collapsed value×effort band BURIES the high-impact/hard candidate under safe small fixes → the picker always picks small (the **incremental trap**). Two bands (Impact · Effort), ordered impact-then-effort; a high-impact candidate stays in the TOP even when hard, cost shown honestly — the human, not a merged number, decides if the ambition is worth the effort. **This governs the DISPLAY only**: internal scoring may still COMPUTE the order (Ch.2's weighted-sum for Pass-B options), but what's SHOWN separates impact from effort. (Orthogonal to autonomy-confidence above, which gates *surfacing*.) **Impact calibration for bold/ambition lenses**: judge Impact against the target's CENTRAL-GOAL ceiling, NOT the safe-fix baseline — a candidate that 10x's the central goal is 🟢 impact even if uncertain/hard; uncertainty feeds EFFORT, it NEVER deflates Impact (else the producer re-buries the bold by conservative scoring — the trap moves from display to scoring).
- **Board**: 🧠 the Autonomous (search first — ONE grouped sweep per turn resolves facts for ALL
  candidates ≥30) · 🙋 the Silence Advocate (rejects anything ≥80 without a cited fact; flags the strictly-private) ·
  ⚖️ ≥80 supported AND nothing private → ANNOUNCED assumption ("I'm assuming… — correct me"), never
  silent. **High-impact override**: impact ≥80 → surface regardless of confidence (carve-out: an explicitly
  stated "why"). **Stop**: best raw impact <30, gate exhausted, or cap.
- **⚖️ Pertinence gate (summon-or-not)**: before auto-invoking a skill on a need, score the **net marginal value minus cost** /100 (≥50 = summon). **3-tier scale** (calibrated on 2 tests): **(1)** 1 *cheap* scorer — score ≤~35 or ≥~70 → decide directly (clear cases are **bimodal**, panel is wasted there) ·
  **(2)** only if **35-70** → decorrelated panel (different models/lenses) · **(3)** if the panel **splits** (vote
  crosses the threshold) OR **spread >~20** → **SURFACE to the human**, never a silent drop. **Unifies** the scattered brakes (advisory-gate, trivial off-ramp, ROI-stop) — do not add a parallel one. Guardrail: **conservative in UPSTREAM veto** (scout/frame — a poorly framed need is not vetoed by an unframed judgment), **aggressive on DOWNSTREAM redundancy** (re-panels, excess loops). Disarmed in disposable. (producer=scorer → signal, not proof.)
- **⚓ Anti-fixation** (applied by the gate at closure, foundation §2): no decision committed without **≥3
  genuinely distinct scored options** (straw options = a defect to flag in review) — disarmed in
  disposable. Annotated at write-time, blocking at closure.
- **Schema `gg-1`** (INTERNAL generator output, model-side only — never emitted in a skill's final user-facing result, nor machine-validated by any hook; "validated ON RECEIPT" = the consuming step's own check: *absent* ≠ *present-but-non-conforming*, rejected on version-skew):
  `{"schema_version":"gg-1","candidates":[{"id","lens","content","impact","autonomy_confidence","cited_fact","strictly_private","proposed_assumption"}]}`
  *Few-shot `content` — ✅ concret/ancré: «`auth.ts:88` : le retry ne borne pas le backoff → boucle serrée sur un 429» · ❌ vague (rejeté à réception): «améliorer la robustesse réseau».*

## Ch.2 — JUDGE *(used during `judge`; the canary is only used in critical)*

**Founding rules.** Judge = EXTERNAL (did not produce) + INFORMED (need + deliberate decisions + ledger
`## Défauts`) + never amnesiac (first verifies that fixes held; only reports NEW /
incomplete-fix / regression). **A judge never repairs.** Same-model ceiling: no combination of copies
is an oracle — credibility comes from separation + the obligation of proof; closure stays
out-of-model (foundation §2).

**Proof classes**: **REPLAYABLE** (CLI with no side-effect) → replayed, not believed (by the gate via
`signal-cmd`, or a cold Verifier for expensive ones) · **ATTESTABLE** (screenshot, read artifact) → must
self-prove: freshness (artifact > action) + non-vacuity (N tests >0, log non-empty, exit 0 AND clean stderr)
+ targeting (run-stamp) + negative counter-check. `artifact_based:true` only if it holds.

**Scoring**: first remove the objectifiable (exit, counts, pixel-diff → deterministic). [F] = 1 judge,
counterexample or 100. [S] = hostile expert attack then score; **2 decorrelated draws per NAMED ORTHOGONAL LENS** (draw A and B receive
distinct lenses from a per-dimension list — e.g. Faithful A="trace each claim→need criterion" / B="find a case of the need not covered" — NOT just "different framing"), **median-then-MIN**; spread >20 → 3rd draw MIN; spread of all 3 draws still >15 →
**INDETERMINATE + ask** — never a silent green. **Ask BEFORE the 1st draw** if a missing fact would move the note >20 pts (grounding-poor case) — cheaper than burning 3 divergent draws to reach INDETERMINATE. **Variance-gate (kaizen 2026-06-18)**: a /100 from a
SINGLE model is a JUDGMENT, not a measurement — same-model draws on ONE artifact that diverge by >20
(lived: 97/72, 96/61/58) prove the instrument unreliable → report **the spread**, never a MIN dressed up as a clean
number; surface the score as a **coarse band** (keep/maybe/drop) + provenance "self-judged, not measured", not a 2-digit false precision.

**Aggregation**: PASS/FAIL verdicts → MIN of all dimensions — **EXCEPT** a dimension whose blocking defect is `nature:intrinsic` (design ceiling, not a fixable bug): EXCLUDED from the global MIN,
carried as a visible **RISK NOTE** (never dressed up as green). **RANKING mode** (N candidates) → weighted sum post-veto (MIN = eliminatory veto + intra-[S] only). **`[1b]` fail-closed**: N judges ⇒
N valid `je-1` JSON; missing/invalid → 1 retry → else dimension **INVALID, caps and blocks**. A REAL major
that is fixed leaves a **permanent anti-regression guard** (`check:` in RUN.md / replayable repro) —
otherwise it can return unaudited (anti-whack-a-mole: a killed defect does not resurrect).
Schema: `{"schema_version":"je-1","dimension","note","interval","unstable","unstable_reason","artifact_based","defects":[{"severity","nature":"fixable|intrinsic|wont_fix","type","description","to_reach_100"}]}` (`unstable_reason` non vide si `unstable:true` — preuve-manquante vs critère-mal-défini — sinon le consommateur re-lit tout le journal).
*Few-shot `defects[].description` — ✅ «ligne 42 : pas de null-guard sur `user.id` → TypeError sur appel anonyme» · ❌ «le code est fragile» (rejeté : ni lieu ni déclencheur nommé).*

**The loop**: panel ∝ regime (foundation table); re-vote at each iteration (re-audit, not re-reading).
**Cost (outside critical)**: ESCALATING panel (core of 2 = Faithful + Real-effect, escalates on signal — major
surfaced / worried pivot / diff touching the dim) · [F] grunts in CHEAP model, [S] pivots in strong — **and DIVERSIFY to decorrelate**: vary model/temperature across seats ([F] spread over ≥2 models if ≥4 draw; the 2 [S] draws at distinct temperatures 0.0/0.7 or different checkpoints; same-model+same-temperature = maximum correlation) · double the
SINGLE top pivot in standard (all [S] only in critical) · shared digest read ONCE (not N re-reads).
Critical = full panel + doubled + strong from the start, NO escalation (we pay for coverage where it is irreversible).
**Stops**: ROI-stop (disposable/standard: zero-major reached → stop, no cosmetic re-panel) ·
**intrinsic-early** (≥1 major `nature:intrinsic` from cycle 1 → DEGRADED MODE immediately, do NOT wait for the
cap: sending it back to the producer = whack-a-mole, they cannot fix it) · **cost-cap** (cumulative audits
≥ ~15 AND global-min delta <5 over 2 transitions → forced ROI-stop even without zero-major) · **cost banner
before relaunch** (kaizen 2026-06-18: relaunching a costly loop at turn N≥2 with a negative delta, OR after
having already recommended stopping → DISPLAY "run #N, ~XM cumulative tokens, delta −Y" BEFORE relaunching; cost
must be VISIBLE otherwise the human cannot exercise stop-authority — never self-mute it) · caps (≈3 standard —
a live major at cap = mis-classification, re-escalate; 5 critical) · stagnation (global min flat over 2
transitions) · rotating regression · design conflict → **human hard-stop in DEGRADED MODE**: deliverable output + 2-4 costed options + nothing-without-OK. **Fallback without sub-agents**: judge
sequentially by changing lens (ledger kept); [S] single-pass = "degraded vote"; never the producer's
self-assessment.

**🐤 Canary (critical: systematic · standard: SAMPLED)**: before trusting a panel green — defect planted in one copy, panel
runs on it first; no judge sees it → ensemble "blind today" → non-conclusive greens (INVALID) → **FORCED re-escalation** (escalate one regime: standard→critical, or human hard-stop if already critical; never just log and continue),
log `CANARY-BLIND`. **In standard, SAMPLE**: trigger at least on (a) once per work-item, traced in RUN.md `## Défauts` (persistent state re-read at Prelude — without a log, the "new type" condition is not executable from a fresh context to another) and (b) when the 2 [S] draws agree within <5 (suspicious correlation). Measures correlation instead of assuming it absent. **Any standard pass WITHOUT a canary MUST carry the marker "blind spot not excluded" (silence ≠ safety).**

**Skill deliverables**: trigger test (router in fresh context, should/should-not) + 1 real run;
re-test after ANY edit; cross-refs resolved. **Diff review** before integration: surface ∝
need, no out-of-scope, no dead/debug code, no secrets, no spurious reformatting.

## Ch.3 — RUN, details *(used for standard/critical runs; foundation §1-2 is enough for daily work)*

**Sections** (single-writer: the orchestrator alone writes; sub-agents return typed JSON → events):
`## Besoin` (deep-why, scope in/out, success criterion = cochable DoD checklist judge ticks item-by-item — disposable: one-liner, deliberate decisions) · `## Options` (≥3 scored +
`Décision:`) · `## Journal` (append-only: `[ts] unit=<id> run=<stamp> VERIFIED|FAILED|FLAKY|CLAIM|PROOF|USER-OK`) ·
`## Défauts` (the judge's ledger) · `## Reprise` (Goal/Hypothesis/Tried/Next/Blockers + counters) ·
`## Cicatrices` (run lessons — volatile to HYPOTHESIS) · `## Checks` (`check: <command>` — foundation §6).

**Discipline**: `green` ONLY after real signal verification — never to satisfy the gate (it
replays). `degraded-closed` = honest closure without a green, **USER-OK traced in the Journal** (honor constraint —
the gate passes, the review verifies). **First-class FLAKY**: a signal that flips between re-runs is journaled
FLAKY, listed in the recap, never absorbed as green, never arms a fix. **Confirm-the-color**: confirmation re-run
before any pivot or closure. **Idempotence**: `unit+run` keys in the Journal — a redispatch does not
double-apply; commits stay outside the parallel zone (apply series post-barrier). **Multi-workspace**:
a parent RUN stays open as long as ALL children are not green AND integration is verified. **Resume**:
header + `## Reprise` + ~10 last events (~30 s).

---

## Ch.4 — BUILD *(used during execution — between `terrain` and `judge`; the EXECUTOR consults it, no skill fires during this phase)*

**Plan = signal-bearing increments.** Decompose into **smallest VERIFIABLE steps**, each annotated
`{goal, own signal (wired by terrain), independent | depends-on-X}`; dependencies first, independent part
maximized deliberately. The plan lives in the RUN (`## Reprise` + Journal), not in a separate file.
Re-read the `Décision:` before starting — execute the chosen option, not another.

**Red first** *(the negative control applied to the build)*: when the signal of an increment is an
executable test/check, write it BEFORE implementing and SEE IT FAIL — a check that was never red
proves nothing (it may be testing a vacuum; scar "overly clean fixture"). Then implement to
green, then re-run the touched suite. NEVER modify a test to make it pass.
**Adversarial coverage on YOUR OWN fix (kaizen 2026-06-18)**: a test YOU wrote that passes proves the
happy path, NOT the absence of the bug class — for a boundary/discriminant fix, NAME an input that
SHOULD make the test fail and confirm it fails (mutation); otherwise = "coverage unverified", not
green (lived: a false-green fix reintroduced a false-green in its own dead zone, caught by the judge —
not by my 3 self-written tests).

**The increment loop**: implement → verify via the REAL SIGNAL (never self-judged text) →
red? diagnose then fix → re-verify → journal (`unit=… VERIFIED|FAILED|FLAKY`) → next.
**Anti-regression cadence**: at each green increment, re-verify ADJACENT wins (not only at
the end); two increments that break each other 2× = design conflict → escalate, do not loop.

**Parallel dispatch**: independent increments go to sub-agents IN PARALLEL (one single
message); each sub-agent returns typed JSON (never prose to re-parse); the orchestrator ALONE
writes the RUN (single-writer, ch.3); concurrent file mutations → agent isolation
(worktree/scratch); exclusive resource (build/DB/bench/port) → one owner only; applies/commits in
SERIES post-barrier.

**Systematic debugging** *(on unexpected failure — before any fix)*: reproduce MINIMALLY → form ≥2
DISTINCT hypotheses → **BEFORE coding the 1st fix, especially on a system/platform layer
(rendering/DWM/desktop/focus/IPC/capture/OS) or an unknown cause: a prior-art RESEARCH pass (official
docs / issues / web, short cap). A fix coded without a CITABLE cause = a dice roll — and the limit is
often ALREADY documented** → instrument to DISCRIMINATE before touching the code → fix the CAUSE, not the
symptom → promote the lesson to code (`check:` / regression test). **Cost cap: one empirical trial
(edit+build+run) costs more than research → 2nd blind fix on unknown cause = STOP code, RESEARCH
first (the human costs as much as one trial: search BEFORE escalating); 3 failed fixes → parallel resolvers with orthogonal hypotheses.** **Anti-diagnostic-drift: root cause that CHANGES ≥2× in a
run → STOP, publish {retained hypothesis · out-of-model proof that anchors it · discarded hypotheses} and get
it VALIDATED before resuming — otherwise the user becomes your falsifier.** **fix-gate disarm tokens**
*(operational — `fix-gate.ps1`)*: the gate blocks >6 same-file edits with no cause. Disarm a legit iteration
via a TOKEN LINE in the session RUN.md — `CausalHypothesis:` / `check:` (real cause + names the file →
disarms mid-flight) — or, for non-bug churn on a long-lived UI/layout file, `fix-file: <basename>` (names the
file, but ALONE only **resets** the counter on a `status: green` RUN, once per verified-green transition — it
does NOT disarm mid-flight). One-off on a single edit: inline `fix-ok: <why>` in the edited file.

**Green checkpoint + rollback**: before each risky increment, a NAMED restorable green (commit/tag —
disposable worktree mounted by terrain); CONFIRMED regression (re-run, not a flake) → return to the last
green and re-attack with a DIFFERENT hypothesis — never stack fixes on a broken state.

*(Ch.4 = the deliberate absorption of the execution mechanics previously delegated to third-party skills —
the engine is self-contained by design decision, 2026-06-10.)*

## Telemetry & cadence *(out-of-model measurement — not daily use)*
Blocks counted in `~/.claude/gate-counters.jsonl` by the hooks — the TREND measures discipline, not
self-reporting. Periodic: behavioral audit (Mode B) · memory consolidation (expiry/conflict/dedup) ·
re-baseline on model bump (trigger-tests + judge calibration).

## Roadmap (named, NOT wired — do not assume coverage)
Held-out anti-Goodhart (critical) · fresh-judge on saturation · real $ caps + token-bucket 429 ·
A/B pipeline-vs-bare on real case · mechanical lesson-promotion by hook.
