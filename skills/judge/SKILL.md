---
name: judge
description: >-
  Step 4 — the FINAL step of the pipeline (frame → terrain → build → judge). ADVERSARIAL, EXTERNAL
  review of a deliverable Claude produced, scored per dimension (surfaced as a verdict band, not false-precision digits) and LOOPED to the regime threshold.
  A panel of independent specialist-judges — each an EXTERNAL subagent (separate from the producer) but
  INFORMED of the need, the deliberate decisions, and the defect ledger — scores the work, lists defects
  WITH PROOF, and SENDS them back to the producer to fix, in a loop. The judge NEVER repairs what it
  audits. DIFFERS from code-review/verify/security-review (single-pass PR, one lens): judge is
  multi-dimension, adversarial, LOOPED. Use when a SUBSTANTIAL deliverable (any non-trivial artifact meant
  to be used/shipped: skill, script, code, doc, architecture, plan, spec — NOT a conversational reply)
  must be validated BEFORE it is considered done, OR when you want an IMPARTIAL quality look rather than
  the producer's complacent self-assessment. Trigger on "review / audit the QUALITY of X", "review the
  quality", "is this work good?", "validate this deliverable", "is it really done?", "is it up to
  standard?" ("review/audite la QUALITÉ de X", "est-ce que ce travail est bon ?", "valide ce livrable",
  "c'est vraiment fini ?"), or right after a substantial deliverable is produced. ALSO has a **Mode B —
  behavioral audit**: trigger on "find my blind spots", "what do I/Claude (systematically) miss", "audit
  my workflow / my habits" ("détecte mes angles morts", "qu'est-ce que je/Claude rate", "audite mon
  workflow / mes habitudes"). DISAMBIGUATE "audit": audit the QUALITY of a DELIVERABLE → Mode A; audit my
  WORKFLOW / behavior / habits → Mode B (target is a parameter: Claude's behavior, OR a codebase, OR a
  skill set — do NOT assume "the repo", derive/ask the target). Do NOT use to: frame a need (→ `frame`),
  prepare the autonomous loop / observability (→ `terrain`), run a single-pass code PR (→ code-review),
  nor to FIX — this skill JUDGES, it never repairs: fixing always goes back to the producer = the `fixer` skill (the executor following ENGINE Ch.4 — BUILD).
---

# judge — ORCHESTRATOR, external adversarial review, looped to threshold (step 4)

> **Engine**: every scoring mechanic — proof classes (REPLAYABLE vs ATTESTABLE), `[F]`/`[S]` scoring with
> decorrelated draws, MIN aggregation, fail-closed `[1b]`, the `je-1` verdict OBJECT, the loop stops
> (ROI-stop / cap / stagnation / regression / conflict), degraded mode, the canary, fallback without
> subagents — is CANONICAL in `~/.claude/skills/_engine/ENGINE.md` (ch.2 JUDGE, ch.3 RUN). Read it at the
> Prelude. On divergence the engine wins. **Exception: the full judge prompt template lives HERE as the
> operating copy — it is the injected instruction; the engine carries only the `je-1` schema.**

## Mission

You are the **ORCHESTRATOR** (main session). Bring the deliverable to its regime threshold under adversarial
angles, then **send defects back to the producer — never fix them yourself**. Sole excellence gate of the
pipeline. Changing hats is allowed same-session: fix as producer (ENGINE Ch.4 — BUILD) between audits, then
relaunch external judges — but a judge NEVER audits work it just produced.

## Prelude (once per run)

**1. Deliverable.** Obtain its path/content. Missing → ask once.

**2. The RUN.md** — the one file matching glob `*-workspace\RUN.md` under `Audit\workspaces\<session_id>\` (the session folder injected by the UserPromptSubmit hook — one folder per session; Stop-gate v3.2 scopes enforcement to it). Fallback: the legacy flat `Audit\workspaces\*-workspace\RUN.md` if no session folder exists. Repo-root cwd; no machine-specific absolute path baked into the skill.
  - `## Besoin` = **the fidelity reference**: deep-why, scope in/out, success criterion. The Faithful judge
    has the RIGHT to flag a **stale/contradicted need** as a MAJOR defect — never judge blindly against it.
  - **Deliberate decisions** (in `## Besoin`/`## Options`) = voluntary choices → judges must NOT re-flag.
  - `## Défauts` = **the ledger**, re-read cross-session (cycles consumed, global-min trajectory,
    resolutions). Create it if absent (autonomous). It makes cap/stagnation/regression watertight.
  - No RUN.md → ask once (Faithful cannot judge without the need).
  - **Evaluate the stop criteria BEFORE launching judges** — any already met → degraded mode now (engine).

**3. Bar = regime** (header `regime:`). disposable → 1 pass, zero-major (or skip at your discretion).
  standard → zero-major, residual minors listed non-blocking, ROI-stop once zero-major. critical → full panel + doubled [S] draws + ≥1 out-of-model
  source + canary; closure via engine stops (stagnation / cap / regression), not a self-awarded
  numeric ceiling.

## Panel (selection by nature, size ∝ regime — engine)

| Judge | Dimension | Type |
|---|---|---|
| 🎯 Faithful **(ALWAYS)** | truly answers the need? | [S] |
| 🌍 Real-effect **(executable — MANDATORY)** | observed effect matches expected? | [F] |
| 🐛 Corrector | correctness, edge cases | [F] |
| 🔒 Guardian | security, sensitive data, abuse | [F] |
| ⚡ Optimizer | performance, efficiency, cost | [F] |
| 📐 Conformer | conventions, coherence with existing | [F] |
| 📖 Readable | readability, 6-month maintainability | [S] |
| 🧹 Lean | over-engineering, needless complexity | [S] |

**Exclusion zones (disjoint scopes — kill correlated triple-votes under MIN)**: each judge owns ONE lane and is told what it is NOT responsible for — Readable = clarity/naming readability ONLY (not complexity → Lean, not conventions → Conformer) · Lean = over-engineering/duplication ONLY (not style → Readable) · Conformer = conventions/coherence-with-existing ONLY (not subjective readability) · Corrector = correctness/edge-cases ONLY (not perf → Optimizer). Inject the "you are NOT responsible for X (→ Y)" line into each judge's prompt.

**By nature**: code/script → +Corrector, Guardian, Optimizer, Conformer, Readable · doc/plan/arch/spec →
+Readable, Lean, Conformer (+Corrector if logic is described) · executable/UI/runtime/skill → +Real-effect
MANDATORY. When in doubt at CRITICAL, include; at standard, **start lean and ESCALATE**. **Size ∝ regime**
(engine): disposable = Faithful (+Real-effect if it executes), no [S] vote · **standard = ESCALATING —
launch a CORE of 2 (Faithful + Real-effect) first; add a risk dim ONLY on a signal (a major surfaced, a
pivot flags concern, or the diff touches that dim's scope); double only the SINGLE most decision-load-bearing
[S] pivot, not every [S]** · critical = full panel upfront + systematic [S] doubling + ≥1 out-of-model
source (no escalation — pay for full coverage where it's irreversible).

## Confront the real

**100 on TEXT alone is FORBIDDEN for any executable.** Two proof classes (engine ch.2): **REPLAYABLE** (a
CLI run/build/query with no side effects) → the proof is REPLAYED not believed — the closure gate replays
`signal-cmd:` when whitelisted-idempotent, a cold Verifier agent for the expensive ones · **ATTESTABLE**
(UI screenshot, human-read artifact) → must self-prove: fresh, non-vacuous (N>0, exit==0, clean stderr),
run-stamp-targeted, negative control. The **observation artifact is provided by the producer**; absent →
**send back immediately** (not a sterile low note).

Recipes: **skill** → trigger test (router in blank context on should/should-not phrases) + 1 real run +
**re-test after ANY edit** + cross-refs resolve · **script/code** → run on ≥1 input vs expected · **UI** →
post-action screenshot READ · **doc/process** → walk it on 1 concrete case. Tooling unavailable → mark
"triggering NON-VERIFIED" in the report; do not block 100 on an unavailable tool.

**Review the DIFF, not only the result** (engine): change surface ∝ the need, no out-of-scope files, no
dead code/leftover debug, no secrets/credentials, no parasitic reformatting. Autonomous producers drift
into opportunistic refactors — gate them here.

## 🐤 Canary (critical: systematic · standard: SAMPLED — engine ch.2)

Before trusting a critical-panel green: inject ONE planted defect into a **copy** and run the panel on that
copy first. The defect must be REALISTIC, not trivially-syntactic — a broken brace any Corrector catches
measures nothing. **Plant-recipes by nature (inline)**: code → invert a condition / off-by-one; doc → a plausible-but-false claim; script → a broken idempotency or wrong exit code; skill → a wrong trigger phrase; UI → a silent no-op binding. No judge
flags it → the ensemble is **blind today** → every green of that panel is downgraded to non-conclusive
(INVALID) → **FORCED re-escalation**: bump one regime (standard→critical) and re-run, or human hard-stop if already critical — never just log and proceed. Log `CANARY-BLIND`. This measures judge correlation instead of assuming it away. (disposable → NO canary = an **assumed blind spot**, stated as such.) **Thresholds and the exact standard-sampling sub-conditions are CANONICAL in ENGINE Ch.2** — single source; don't re-spell the values here (judge keeps the plant-recipes inline above + the operating gist).

## Launching judges

Launch the selected judges **IN PARALLEL** (one message, multiple subagent calls — never serial). **Model & temperature
DIVERSITY (decorrelation, not just economy)**: [F] grunt dims (Corrector, Guardian, Optimizer, Conformer,
Real-effect) → cheap model, but SPLIT across ≥2 models when ≥4 fire (e.g. haiku + sonnet) so a single-model
blind spot can't sink the whole [F] tier; [S] pivots (Faithful, Lean, Readable) → strong model, the 2 draws
at DIFFERENT temperatures (e.g. 0.0 / 0.7) or checkpoints. Same-model+same-temperature judges are maximally
correlated — vary deliberately. **[S] doubling**: 2 decorrelated draws via a NAMED ORTHOGONAL LENS each
(draw A and B get DIFFERENT lenses from a per-dimension list — e.g. Faithful: A="trace every claim back to a
need-criterion" / B="find a need-case the deliverable doesn't cover"; Lean: A="what's over-built" /
B="what's duplicated"; Readable: A="newcomer at 6 months" / B="maintainer debugging at 2am" — NOT merely
"different framing") for ALL [S] in critical, but only the SINGLE top pivot in standard. **Shared digest**: read the deliverable ONCE and inline it (or the
relevant slice) into every judge's prompt — don't make N agents each re-Read the same small files. Stable
prefix (need + criteria + decisions) then the volatile last-cycle delta only.

**Prompt template (injected per judge — full operating copy):**

> *You are an **EXPERT SPECIALIST** of the dimension **\<DIMENSION\>**, and of NOTHING else. Sharpest
> posture — a generalist who dilutes attention misses the real defects; you look ONLY at \<DIMENSION\>,
> better than anyone. You are **EXTERNAL** (you did not produce this and defend none of its choices — that
> is what makes you incorruptible) and **INFORMED**, not amnesiac: your role is to make the note
> **CONVERGE**, not restart the debate.*
>
> *[**Posture** (assigned per draw — rotate the stance; a shared posture flattens the council into ONE blind spot): default = **adversarial expert** (hunt the defect); draw B / canary = a **contrarian** (assume it is CORRECT, find the ONE scenario where it silently fails) OR a **naive reader** (no domain expertise — does it hold for someone who doesn't already know the answer?).]*
>
> *[**Exclusion zone** (injected per judge — keep scopes disjoint under MIN): you are NOT responsible for `<X>` (→ `<other judge>`); score ONLY your own lane, stay silent on the rest.]*
>
> *Read the deliverable: `<path/content>`.
> [Faithful only: read the need (`## Besoin` of `<RUN.md path>`). You have the RIGHT to flag a
> stale/suspect/contradicted need as a MAJOR defect.]
> [Real-effect only: do NOT score on reading — confront ≥1 concrete case with the observation artifact
> PROVIDED BY THE PRODUCER; artifact ABSENT → SEND BACK (do not loop a low note).]*
>
> *You receive: (a) **need/intent**: `<Besoin>`; (b) **deliberate decisions + scope**: `<decisions +
> out-of-scope>` — voluntary, do NOT re-flag; (c) **ledger**: `<Défauts: defects raised + resolution>`.*
>
> ***Investigate context** — repo conventions, neighboring files, the existing code/doc this deliverable
> must respect. Do NOT judge in a vacuum; open useful files. (Crucial for Conformer and Faithful.)*
>
> ***Convergence discipline.** Do NOT re-litigate settled or deliberate points. FIRST verify that prior
> ledger fixes HOLD (falsifiable re-check). THEN report ONLY: a real **NEW** defect, an **incomplete/wrong**
> prior fix, or a **REGRESSION**. "Already accepted" NEVER excuses a regression. PROVE every defect.*
>
> *[F]: hunt a counter-example; found → note <100 with the case as proof; none after a serious search →
> 100. [S]: write the hardest hostile-expert attack FIRST, THEN score.*
>
> ***Calibration**: MAJOR (breaks/contradicts the need, blocking hole, regression) → **low note**; MINOR
> (friction) → **near 100**; 100 = no new/unresolved/regressed defect after a serious search. No note <100
> without a named defect.*
>
> *Reply ONLY in JSON:
> `{"schema_version":"je-1","dimension":"...","note":0-100,"interval":"...","unstable":bool,"artifact_based":bool,"defects":[{"severity":"major|minor","nature":"fixable|intrinsic|wont_fix","type":"new|incomplete_fix|regression","description":"...","to_reach_100":"..."}]}`
> (`je-1` canonical in `_engine/ENGINE.md`. `artifact_based:false` = self-declared, unverified out-of-model.
> **`nature`**: `fixable` (producer can correct it) · `intrinsic` (design ceiling, NOT a bug — excluded from
> the global MIN, carried as a risk note) · `wont_fix` (deliberate). `to_reach_100` may be `""` for a minor
> in a ≤standard regime — do NOT manufacture a cosmetic path to 100.)*

## Loop

**[1] AUDIT** — launch judges in parallel with `## Défauts` ledger + decisions injected (stable summary +
last-cycle delta only, never the verbatim history — bounds per-cycle cost).

**[1b] COUNT & VALIDATE** — N dispatched ⇒ N schema-valid `je-1` replies before aggregating; missing/invalid
→ 1 retry → else that dimension is **INVALID** (caps the global, blocks the verdict — never silent 100).

**[2] AGGREGATE** — each [S] = median-then-MIN of its 2 decorrelated draws (gap >20 → 3rd draw MIN; spread of the 3 still >15 → INDETERMINATE + stop-ask);
each [F] = its single judge; global = **MIN of all dimensions** (engine) — EXCEPT a dimension whose blocking
defect is `nature:intrinsic`, which is EXCLUDED from the MIN and carried as a visible RISK NOTE (never
disguised green). Compile defects to `## Défauts`.
**Early-out**: one consolidated, unambiguous MAJOR → send it back at once, don't wait for full aggregation.

**[2b] BLIND-SPOT SWEEP** (Fusion-inspired — *what no reviewer covered*) — the disjoint exclusion zones
guarantee each lane is examined, but also risk an in-scope aspect that NO lane owns slipping through
**unjudged**. **Runs before any verdict ships green (or ROI-stop / degraded-closes) — NOT on an early-out
send-back** (there a major already returns to the producer; the sweep guards the final clean cycle).
Cross-check the UNION of the dispatched dimensions against `## Besoin` scope + success-criteria: any in-scope
facet or need-criterion that NO judge examined = a **blind spot** (a coverage GAP, not a scored defect). This
is **orthogonal to the canary** (which measures panel *sensitivity*, not *coverage* — a sensitive panel can
still leave an aspect nobody was assigned). Record them in `## Défauts` under `### Angles morts`; a blind spot
over a high-risk area → **add the owning dimension (panel table) and re-run from [1]** rather than ship over
an unexamined gap. Empty after a real look → state "aucun angle mort détecté" (silence ≠ full coverage).

**[3] VERDICT** by threshold. Met → in *critical* only, run global cross-dimension verification first. Not
met → **send back** prioritized defects to the producer — the `fixer` skill (or you switching hats; never fix as judge): same session = switch hats, fix,
update ledger, re-run from [1] · other session/user = emit the prioritized final report (ledger included)
and END, a new invocation re-audits.

**[4] RE-AUDIT** — evaluate stops FIRST, then degraded mode if any fires (engine, 1 line each): ROI-stop
(zero-major reached → STOP, no cosmetic re-panels) · **intrinsic-early** (≥1 `nature:intrinsic` major at
cycle 1 → degraded mode NOW, don't wait for the cap — sending an unfixable major back = whack-a-mole) ·
**cost-cap** (cumulative audits ≥ ~15 AND global-min delta <5 over 2 transitions → forced ROI-stop even
without zero-major) · cap (≈3 standard / 5 critical — a major alive at cap = under-classification,
re-raise) · stagnation (global-min flat over 2 transitions) · rotating regression · design conflict.
Degraded mode = **human hard-stop**: deliverable fate + 2-4 COSTED options + ship NOTHING without OK. Re-audit is **bounded to the diff**: re-judge a 100 dimension only if the diff touches its scope.
(No subagents → judge sequentially yourself, one lens per pass, keep ledger+decisions; single-pass [S] =
"degraded vote"; never producer self-assessment.) The orchestrator is the **single writer** of `## Défauts`.

## Mode B — Behavioral audit

Target is a deliverable's quality? → Mode A above. Target is a behavior/habit/skill-set? → here.

**Parameterize the target** — confirm: (i) Claude's behavior/workflow, (ii) a codebase, or (iii) a skill
set. Do NOT assume "the repo".

**Preload "already covered"** (replaces ledger round 1): the machine's global `%USERPROFILE%\.claude\CLAUDE.md`,
any project CLAUDE.md, the auto-memory index if present, installed skills. Inject into every judge so it does
not re-flag the known.

**Behavioral lenses** (6-9, parallel): Anchoring & honesty · Communication & user attention · Cost &
efficiency · State/resume/capitalization · Scope & over-engineering · Reversibility & checkpoint · Error &
silent failure · Safety/secrets/PII · Tool-use & idempotence · Premature-stop & iteration · **Model-shared
blind spot** (assumptions the WHOLE panel holds for granted — same-model ceiling, engine). Each lens finds
1-2 NEW blind spots, high-impact, with a **falsifiable example anchored** in repo/scripts/transcripts (not
armchair reasoning), plus a severity.

**Convergence**: re-loop with NEW lenses until a round is dry; **2 dry rounds = stop, cap 3 rounds**.
**Canary (Mode B — same-model self-audit ⇒ MANDATORY)**: before accepting a clean verdict (no / few blind
spots), PLANT one realistic blind-spot into one lens's input (a fabricated anchor, or a deliberately-missed
habit) and confirm ≥1 lens flags it. None do → the panel is **blind today**: log `CANARY-BLIND`, mark the
findings **non-conclusive** ("correlated same-model angle — blind spot not excluded"), and surface that caveat.
Skipped → state "sensibilité du panel non testée" (never silent). (This closes the producer=judge hole on the
kit's most self-referential audit.)
**Output = PROPOSE, never impose**: table `blind spot | proposed rule | anchor | impact` + a proposed
integration point (hard rule / skill guardrail / memory / just known / nowhere). NEVER write to CLAUDE.md,
a skill, or memory without user OK.

## Report

Final message to the user — **in PLAIN words, NO internal jargon**. Never show raw labels (`[S]/[F]`,
`artifact_based`, `je-1`, "out-of-model", "MIN", "ROI-stop", "canary/CANARY-BLIND", "verdict OBJECT") — translate them:
- **Global result** + one line per dimension: score + the defect (with proof) + **what to fix to pass**
  (not "to_reach_100"). Never a bare number.
- **Blind spots (what no reviewer examined)**, in plain words: the in-scope facets no lane covered (the
  `### Angles morts` sweep), or "aucun angle mort détecté". Never silently drop an uncovered gap.
- **Confidence caveats, said plainly** when they apply:
  - same-AI only (no planted-defect check) → "tous les relecteurs tournent sur la même IA — angles morts
    corrélés possibles, pas confirmé indépendamment" (MANDATORY on a standard run with no canary pass — silence ≠ safety).
  - one reviewer instead of two (judgment dimension) → "une seule passe — moins de confiance".
  - no execution proof → "relu le code seulement, comportement pas observé" (was `artifact_based:false`).
  - trigger test not run → "pas pu confirmer que le skill se déclenche bien".
  - planted-defect check missed → "test de sensibilité des relecteurs raté — ces notes ne sont pas concluantes".
- **Verdict + next step, plainly**: shipped / renvoyé au producteur avec les corrections priorisées / bloqué
  — demande ta décision avant de livrer. + cycles consumed.

**Start with the Prelude.**
