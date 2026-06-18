---
name: scout
description: >-
  Scouts a TARGET (codebase / project / tool) to surface a SHORTLIST of concrete IMPROVEMENT
  candidates — ready to be picked up as a task, presented as ONE ranked table (Type · What · Why · How).
  Each candidate is either a 🔧 FIX on existing code (real, bounded, touchable, with `file:line` + a
  MEASURABLE done-signal) or a 🆕 NEW FEATURE (a missing piece or a bold premise-breaking re-imagining,
  whose How is the first concrete step). This is STEP 0 of the
  pipeline (scout → frame → terrain → build → judge): its candidates feed `frame`. Use when you don't yet
  know WHAT to do on a target: « scoute X », « qu'est-ce que je pourrais améliorer dans X », « trouve-moi
  une tâche / un candidat dans X », « par où commencer sur X », « des opportunités / de la dette dans X »,
  « une vision neuve pour X » / "scout X", "what could I improve in X", "find me a task / a candidate in
  X", "where do I start on X", "any opportunities / tech debt in X", "a fresh vision for X". Looks for ALL
  types: debt/TODO/dead code, bugs/fragilities, unfinished features/UX, missing perf/tests — AND bold
  re-imaginings. Trigger YOURSELF as soon as someone asks "what to improve / which task / where to start /
  what could this become" on a target, without waiting for the word "scout". ALSO has an **UNBLOCK mode**
  (solution-finding for a HARD/blocked technical constraint — "how do I make X work despite Y", not "what to
  improve"): trigger on « trouve un moyen de faire marcher X (malgré Y) », « comment débloquer / contourner
  cette contrainte / limite », « il DOIT y avoir une façon de… » / "find a way to make X work despite Y",
  "how do I get around this limit", "there must be a way to…". In that mode scout RESEARCHES prior-art
  (docs/issues/web) FIRST, breaks the premise of the blocker, and returns ranked SOLUTION-APPROACHES with a
  cited feasibility seed — it never declares "impossible" without a cited source. DO NOT use to: frame a need
  that's ALREADY chosen (→ `frame`); just LOCATE known code (→ `Explore` agent — scout RANKS
  opportunities, it does not locate); review an existing diff (→ code-review); judge the quality of a
  finished deliverable (→ `judge`); audit a behavior / workflow / habit set — « auditer mon workflow / mes
  habitudes » (→ `judge` Mode B); nor to FIX/execute — scout PROPOSES, it touches nothing.
---

# Scout — surfacing actionable improvement candidates

> **Shared engine**: the candidate-pool mechanics (parallel lens fan-out, loop-until-dry, dedup by core
> idea, the two orthogonal /100 scores, and the auto-resolve vs. surface gate) are defined canonically in
> `~/.claude/skills/_engine/ENGINE.md` (Chapter 1 — GENERATE & GATE). On any divergence, the engine wins.
> **Summary**: fan out 1 agent per lens in ONE message → each returns scored JSON candidates (`gg-1`) →
> dedup by core idea → loop-until-dry (stop after 2 dry rounds or ~12 candidates) → rank the survivors.
> **Scout's composition over that primitive**: the lens POOL is MIXED (markers + flow-reading + bold
> re-imaginings) so nothing is missed; the gate is TYPE-AWARE — 🔧 fix vs 🆕 new feature (Steps 2-3). The
> engine supplies the fan-out; scout chooses the lenses + the gate, and presents ONE What/Why/How table.

## Mission

Given a **touchable TARGET**, deliver **ONE ranked table** (Type · What · Why · How) of concrete improvement
candidates — each either a 🔧 **fix** on existing code (real, located, with `file:line` + done-signal) or a
🆕 **new feature** (a missing piece or a bold re-imagining) — to (a) feed `frame` (pipeline step 0 → 1) or
(b) answer "what could I improve / build here". **Read-only: propose, never fix, never frame, never judge.**

## Unblock mode — solution-finding for a HARD/blocked constraint

Triggered when the question is **"how do I make X work despite the blocker Y"** (a desired capability is
stopped by a constraint), NOT "what to improve". Here the candidate is a **solution-approach**, not an
improvement. Three obligations, in order:

1. **RESEARCH ARM FIRST (non-negotiable — operationalizes ENGINE socle §3 + Ch.4 "research before coding").**
   Fan out research agents IN PARALLEL (prior-art: official docs, GitHub/forum issues, web) to establish:
   is the blocker a DOCUMENTED platform limit? what techniques do others use? **Never declare "impossible /
   intrinsic" without a CITED source** — that exact false-conclusion (a documented limit re-discovered by
   blind trial-and-error) is the scar this mode exists to prevent.
2. **PREMISE-BREAKING divergence** (the creative family, ENGINE ch.1): challenge the blocker's premise
   ("why must Y hold? what if it didn't — could the constraint be sidestepped, relocated, or temporarily
   lifted?"), borrow techniques from adjacent domains, invert defaults. Generate DISTINCT approaches, not
   variants of one.
3. **Rank by FEASIBILITY × FIT.** Each approach carries: the technique · the premise it breaks · a
   **feasibility-seed = smallest real step + a CITED fact/source it can work** · the cost/tradeoff · and
   **whether it PRESERVES the constraints the user explicitly cares about** (e.g. isolation, no-monolith-edit).
   An approach that violates a stated must-keep constraint is ranked last or dropped, said so.

**Output** = a ranked table `Approach · How it works · Preserves <constraint>? · Feasibility seed (+source) ·
Cost`, top one pickable by `frame`/`terrain`. **Honest close**: if the research proves a genuine platform
limit, say it WITH the citation (not a guess) + the closest-fitting approach that still honors the must-keep
constraints — never a bare "impossible".

## Step 1 — Locate the TOUCHABLE scope first (anti legacy-trap)

Before any scan, identify **what the user owns and can edit**: build artefacts (`*.sln`, `*.csproj`,
`package.json`, launch scripts) delimit the owned perimeter. Explicitly EXCLUDE legacy, vendored, and
generated code BEFORE scanning — a blind `grep TODO` over the whole tree lands in the untouchable
monolith and wastes the run.

## Step 2 — Multi-angle scan in parallel (via the GENERATE & GATE engine)

Fan out **one agent per lens in a single message**, proportionate to target size. THREE families — do NOT
limit to markers, or perf/UX/edge-case gaps (non-grep-able) and bold opportunities stay invisible:

**Grep-marker family** — (i) `TODO`/`FIXME`/`HACK`/`NotImplementedException`; (ii) stubs / no-ops /
"for now" / "provisional"; (iii) magic numbers, hardcodes, raw fixed timing (`Sleep(2000)`); (iv) empty
`catch {}` swallowing real logic; (v) test-coverage gaps.

**Flow-reading family** — (vi) unfinished features/UX: paths that stop, dead buttons, promised business
actions missing — found by FOLLOWING entry points, not markers; (vii) perf and edge-cases: N+1 loops,
repeated I/O, hot allocations, unhandled null/empty/boundary inputs.

**Bold re-imagining family (the DIVERGENT lens → 🆕 new-feature rows)** — (viii) challenge a PREMISE of the
target ("why is it an X at all? what if constraint Y were false?"), borrow a metaphor from another domain,
invert a default. Run these lenses CLEAN-ROOM (do NOT read the existing — anchoring kills divergence) and
BOLD. They carry NO `file:line` (they don't exist yet) — their **How** is the first concrete step; distinct
lenses must DIVERGE (don't return three variants of one idea).

**Coverage dial** — DEFAULT (scouting for a task): mostly 🔧 fixes **+ >=1-2 bold 🆕 ideas GUARANTEED**, so a
big-lever idea always surfaces (this kills the linter-only blind spot). A "fresh vision / what could this
become" request: tilt toward 🆕. Same fan-out, you pick the ratio.

Each generator receives the already-found list each round ("find something NEW") and runs until 2
consecutive dry rounds or ~12 raw candidates. Dedup by core idea before scoring.

## Step 3 — Filter: a raw hit is NOT a candidate (TYPE-AWARE gate)

This is where value is created. First cull false positives per lens:

- `Sleep(pollMs)` — legitimate poll interval → discard. `Sleep(2000)` — fixed hope-and-wait → keep.
- `try { File.Delete(...); } catch {}` — best-effort cleanup → discard. `catch {}` swallowing a real
  logic error → keep.
- "placeholder" in a comment explaining data → discard. An actual unwired stub → keep.

Then tag each survivor 🔧 **fix** or 🆕 **new feature** — **each faces its OWN gate** (a new-feature idea must
never be killed by a `file:line` test it cannot meet):

- **🔧 fix** survives only if ALL hold: REAL defect + BOUNDED scope + a real `file:line` + a MEASURABLE
  done-signal (build green, test red→green, reproducible screen/metric) — it goes in the **How** column.
  "Improve the UX" with no done-signal → reject.
- **🆕 new feature** survives if: a clear **Why** (the value / problem it addresses) + a concrete first step
  as **How**. No `file:line` required (it doesn't exist yet). Vague "make it better" with no first step → reject.

## Step 4 — Cross-check ownership (does it already EXIST?)

A candidate already covered by a dedicated skill, an existing test, or a known ticket → flag **owned**,
list it separately, exclude from the shortlist. Do not re-propose already-owned work as new.

**Before ANY 🆕 new-feature candidate (or any "create X")** — grep/scan the kit + the live copy + neighbouring
files for an existing version FIRST (constitution reflex 6: check what EXISTS, trap #1 = the duplicate). If it
exists → **reframe to "wire / finish / distribute the existing one", never "create from scratch".** This bites
HARDEST on bold ideas: a "build X" is redundant AND misleading if an X already sits there unwired (real miss:
proposing an outcome-ledger while a `_pipeline-audit/LEDGER` already existed undistributed). A new feature's
**How** must therefore start from what's already there.

## Step 5 — Present ONE table : Score · Type · What · Why · How

A SINGLE table, ranked most-pickable first. **Score = a coarse BAND 🟢 keep / 🟡 maybe / 🔴 drop**
(valeur × faisabilité × fit) — ONE decision-aid to help the user CHOOSE; **NOT a 2-digit /100** (a single-model
self-score spreading wildly across draws is false precision, not a measurement — kaizen 2026-06-18). State it
once as **producer-judged, NOT a verified measure** (the human stays the real picking authority). Keep every
OTHER internal OUT of the output: no second basket, no per-lens scores, **no /100**, no jargon ("taste",
"feasibility-seed", "novelty", "paniers" stay under the hood — only the single Score band surfaces).

| Score | Type | What | Why | How |
|---|---|---|---|---|
| 🟢\|🟡\|🔴 | 🔧 fix \| 🆕 new | what it is, 1 line | the problem it solves / the value | the concrete first step (+ `file:line` if it's a fix) |

- **🔧 fix existing** = bug / debt / perf / fragility / missing test / dead code / UX path that stops — on
  code that ALREADY exists. **How** MUST carry a real `file:line` + the done-signal (how you'll know it's fixed).
- **🆕 new feature** = a missing piece OR a bold re-imagining (premise-breaking ideas land here). No
  `file:line` (it doesn't exist yet) — **How** = the smallest concrete first step.
- **Rank** by band (🟢→🟡→🔴), then value/effort within a band; the **top row must be directly pickable as a `frame` input**.
- Already covered by a skill / test / ticket → don't re-propose (one line "déjà couvert : X" at most).
- If a 🔧 fix and a 🆕 new feature point at the SAME lever, add ONE line under the table saying so.

**Scout stops here.** The user picks a row, then hands it to `frame`.
