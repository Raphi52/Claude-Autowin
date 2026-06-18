---
name: frame
description: >-
  Step 1 of the pipeline (frame → terrain → build → judge). FRAMES a need in depth AND, if the framed need
  leaves an open choice of approach, EXPLORES the options — two passes inside ONE skill. Trigger on TWO trigger
  families. (a) FRAMING — whenever a request is phrased as a SOLUTION ("create X" / « crée X », "add Y" /
  « ajoute Y », "make the script Z" / « fais le script Z », "set up..." / « mets en place... » — but setting up the autonomous LOOP/harness for an already-framed need → `terrain`), when a need is
  vague (vague about a CHOSEN task → frame; vague about WHICH task to pick → `scout` first), or on "define/frame the need" / « définis/cadre le besoin ». EXPLICITLY includes creating a
  doc/README/CLAUDE.md/config: trigger to CHECK it doesn't already exist and to frame its content — creating a
  file that already exists (or that misses its real content) is a classic expensive trap. This is THE default
  entry point on any substantial work — trigger YOURSELF on a solution-shaped request, without waiting for the
  word "frame". (b) APPROACH CHOICE — the HOW for an ALREADY-chosen task (choosing WHICH task to pick → `scout`) — "which approach / architecture / library to choose for X" / « quelle
  approche / archi / lib choisir pour X », "explore the options" (of the already-chosen approach) / « explore les options » (de l'approche déjà choisie), "compare the
  approaches" / « compare les approches », "generate lots of solutions and have them vote" / « génère plein de
  solutions et fais-les voter », "help me decide between several designs" / « aide-moi à trancher entre
  designs ». DO NOT use to: prepare the HOW of autonomous execution (→ `terrain`); judge the quality of a
  finished deliverable (→ `judge`); find WHAT to do on a target when no task is chosen yet (→ `scout`); run the
  heavy protocol on an obviously trivial, disposable AND already-precise one-shot (say it's oversized, offer
  direct implementation); nor throw 2-3 ideas around with no scoring process.
---

# frame

Frame the need, then (only if the choice of approach is open) explore options — **two passes, one skill**.
The mechanics live in `_engine/ENGINE.md`; below is the operating summary. **On divergence, the engine wins.**

## The single RUN file
Open or complete the **one** living file — `Audit\workspaces\<session_id>\<subject>-workspace\RUN.md`
(kebab-case slug; set the `session:` header; session-scoping mechanics + legacy fallback: **ENGINE ch.3 /
socle §1**). You write the `## Besoin` and (if reached) `## Options` sections **in that
file** — never separate need/options/ledger files. Set the header `regime:` (disposable | standard | critical)
on entry; a `disposable` one-shot may need no RUN file at all (proportionality).

## Pass A — the need (always)
**Pre-checks, before any question:**
- **Solution in disguise** — a request shaped as "create/add/make X" is an answer, not a problem. Trace it back
  to the underlying problem; impact of skipping this ≥80 → surface it. Never start framing the artifact before
  the problem is named.
- **Check the EXISTING first** — single recon fan-out (ENGINE ch.1 generate, parallel) before framing
  anything, ESPECIALLY for a doc/README/config: does it already exist, what does it already cover. Cite facts.
- **Impact surface (blast-radius)** — beyond *does it exist* (above): MAP the EXISTING the need will AFFECT —
  files/modules/configs/callers/docs/tests it touches, breaks, or must stay coherent with — **plus what
  CONSTRAINS it** (upstream deps, platform limits, policies); single recon fan-out, parallel; cite
  `file:line`. Feeds scope-out (what stays INTACT) + the success criterion; an empty map is itself a finding
  (isolated change). **Re-run (overwriting) if anything before `## Besoin` shifts the need** — a new
actor/output, an overturned constraint, or a changed delivery medium (the question phase OR an asked-now
blind spot).
- **Trivial off-ramp** — obviously trivial + disposable + already-precise (one-shot, no reuse) → say the
  framing is oversized and offer direct implementation. Do not run the heavy protocol on it.

**EXTRACTION vs ANALYSIS** — two question kinds, never confused. EXTRACTION pulls what the user already holds
in their head (intent, constraints, taste) → ask them. ANALYSIS settles what only investigation can
(what exists, what's feasible, what costs) → you go find out, you don't outsource it. Never dress an analysis
question as a fake multiple-choice the user can't actually answer (a "faux-QCM").

**Question phase** — pool of archetype generators via ENGINE ch.1 (Naive · Breaker · Contradictor ·
Perfectionist · Diplomat · Explorer · Pragmatist · Emotional), generated in parallel (one message). **Naive
opens** (decompose every term, surface every presupposition); then questions are scored on merit (impact ×
autonomy-confidence). The **board-gate auto-answers** the self-evident as **stated assumptions** ("I'm assuming
X, based on <fact> — correct me", never silently), and surfaces to the human ONLY the strictly-private /
high-impact / genuinely uncertain — never lull them with OK-OK-OK. **High-impact override**: impact ≥80 →
surface regardless of confidence (sole carve-out: a "why" they already stated). **Stop** when best raw impact
<30, gate exhaustion, or the round cap.

**Discipline (non-negotiable):**
- QCM-first — offer concrete choices before open prose; **one question at a time**, never a wall of them.
  BUT QCM only when the intent space is BOUNDED (by an artifact: log / diff / repro / a stated constraint).
  Space still OPEN → an OPEN question, never a QCM — a QCM there locks the user into YOUR categories. And
  **the MOMENT the user rejects or redirects a QCM = your categories are wrong**: drop the options, go back
  to the open question; do NOT re-offer the same choices reworded.
- Refuse the vague — "three-nothings" (no nothing / no idea / whatever in a row) → reframe, never accept fog.
- **No solution during the framing** — proposing a HOW is forbidden here. The instant a solution is on the
  table you've flipped from PRODUCTION (you drive) to REACTION (you defend an artifact) — and the need stops
  being framed. Catch yourself and pull back to the problem.
- Anti-drift on opening: decompose each term and its presuppositions rather than widening the scope.

**Blind-spot sweep** (Fusion-inspired — *what no question touched*) — before writing the need: which facet of
the problem did NO archetype/question probe **and no board-gate stated-assumption already cover** (an
auto-answered facet is visible, not a blind spot)? These are the **UNASKED** (unknown-unknowns), DISTINCT from
open questions (known-unknowns deferred to `terrain`). **Loop, don't one-shot** (unknown-unknowns hide past
the first look): re-sweep, each round re-using a DIFFERENT archetype as a coverage *lens* (Breaker = a failure
mode unprobed, Naive = an unexamined presupposition — its analysis use, not question-generation), stopping
when a round finds nothing new (no facet with impact ≥30 not already listed) — **disposable = 1 pass ·
standard = max 2 rounds · critical = until 2 dry rounds, max 3**. Name them so they surface instead of dying silently; one that scores
high-impact → ask it now rather than defer.

**Risk pass** — before writing the need, list the **threats to the success criterion**: what could make this
FAIL or go wrong (dependency not ready, perf/scale ceiling, data loss / irreversibility, a stated assumption
that turns out false, an external blocker, scope creep). Each = a **severity** (likelihood × impact) + a
one-line **mitigation/watch**. DISTINCT from blind spots (unprobed facets) and impact surface (existing
affected): a risk is a KNOWN threat you can already name. A high-severity risk with no mitigation → surface it
(a need isn't fully framed while a fatal risk is unowned).

**Write `## Besoin`** (plain words the user reads — no internal labels): **the real problem** (not the
requested solution) · scope in / out · a **verifiable** success criterion (how you'll know it's done) ·
deliberate decisions · stated assumptions · **impact surface** (existing affected, cited) · **risks** (threats
to success: severity + mitigation) · **blind spots** (the Pass-A sweep's unknown-unknowns) · open questions
left for `terrain`. **Short retro**: what
signals showed up this run (a recurring vague answer, an assumption that was wrong) → patch the thresholds so
next time bites earlier.

## Between passes — is the choice of approach actually open?
After `## Besoin` is written, decide: does the framed need leave a real, unsettled choice of HOW (which
architecture / library / pattern), OR does a single obvious path already fall out of the constraints? Forced
path, or trigger family (a) only with no design question → **skip Pass B**, hand straight to `terrain`. A
genuine fork — or trigger family (b) ("which approach", "compare", "explore options") — → run Pass B.

## Pass B — the options (ONLY if an open choice of approach remains; else skip)
- **Generate** by approach-lenses (ENGINE ch.1: MVP · robust · perf · lean · reuse-existing · creative ·
  cost-first · UX-first · convention · contrarian), loop-until-dry, **dedup by core idea**.
- **Score** in RANKING mode (ENGINE ch.2): typed criteria, fidelity as the eliminatory veto (~0 disqualifies),
  weighted sum post-veto; 2 decorrelated draws on subjective dims, median-then-MIN.
- **Top-K (3-5)** with trade-offs + grafts of the discarded ones' best parts.
- **Blind-spot check across options** — a need-case that NONE of the top-K covers = a coverage gap, not a
  ranking detail: note it in `## Options` (label `Cas non couvert`) and, if it implies a genuinely distinct
  option, add that option before finalizing the ranking — don't let the leaderboard hide it.
- **The human decides.** Present the ranked top and let them pick. Only on an explicit "decide for me" /
  « décide pour moi » do you pick the top-ranked and state why.
- **Write `## Options`** — ≥3 scored, genuinely distinct options (the gate's ⚓ ANTI-FIXATION will verify this
  before any engaged decision; straw options are a defect) + a `Décision:` line.

## Done
Hand off to `terrain` (regime propagated through the RUN header). **Never report "done"** until the
`## Besoin` (and, when Pass B ran, `## Options` + `Décision:`) sections are actually written in RUN.md.
