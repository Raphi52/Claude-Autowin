---
name: scout
description: >-
  Scouts a TARGET (codebase / project / tool) to surface a SHORTLIST of concrete IMPROVEMENT
  candidates — ready to be picked up as a task, presented as ONE ranked table (Type · What · Why · How).
  Each candidate is either a 🔧 FIX on existing code (real, bounded, touchable, with `file:line` + a
  MEASURABLE done-signal) or a 🆕 NEW FEATURE (a missing piece or a bold premise-breaking re-imagining,
  whose How is the first concrete step). This is STEP 0 of the
  pipeline (scout → frame → terrain → build → judge): its candidates feed `frame`. Use when you don't yet
  know WHAT to do on a target: "scout X", "what could I improve in X", "find me a task / a candidate in
  X", "where do I start on X", "any opportunities / tech debt in X", "a fresh vision for X". Looks for ALL
  types: debt/TODO/dead code, bugs/fragilities, unfinished features/UX, missing perf/tests — AND bold
  re-imaginings. Trigger YOURSELF as soon as someone asks "what to improve / which task / where to start /
  what could this become" on a target, without waiting for the word "scout". ALSO has an **UNBLOCK mode**
  (solution-finding for a HARD/blocked technical constraint — "how do I make X work despite Y", not "what to
  improve"): trigger on "find a way to make X work despite Y",
  "how do I get around this limit", "there must be a way to…". In that mode scout RESEARCHES prior-art
  (docs/issues/web) FIRST, breaks the premise of the blocker, and returns ranked SOLUTION-APPROACHES with a
  cited feasibility seed — it never declares "impossible" without a cited source. DO NOT use to: frame a need
  that's ALREADY chosen (→ `frame`); just LOCATE known code (→ `Explore` agent — scout RANKS
  opportunities, it does not locate); review an existing diff (→ code-review); judge the quality of a
  finished deliverable (→ `judge`); audit a behavior / workflow / habit set (→ `judge` Mode B); nor to FIX/execute — scout PROPOSES, it touches nothing.
---

# scout — surface actionable improvement candidates (read-only: propose, never fix/frame/judge)

## Purpose
**Find WHAT is worth doing on a target — surface the real opportunities, not how to do them.** Turn a vague
"what could I improve / where do I start here" into a ranked SHORTLIST of concrete, pickable candidates (debt,
bugs, fragilities, unfinished UX, missing perf/tests — AND bold premise-breaking ideas), each with enough
signal to choose. Read-only: scout PROPOSES the menu; it never frames, fixes, or judges.

## Procedure  (default mode — "what to improve / where to start on TARGET")
1. **Locate the touchable scope FIRST** — the owned/editable perimeter (`*.sln`/`*.csproj`/`package.json`/launch scripts). EXCLUDE legacy/vendored/generated BEFORE scanning — a blind `grep TODO` over the whole tree lands in the untouchable monolith and wastes the run.
2. **Multi-angle scan, IN PARALLEL** (1 agent per lens, ONE message; loop-until-dry: stop at 2 dry rounds or ~12 candidates; dedup by core idea). THREE lens families — do NOT limit to markers (perf/UX gaps + bold ideas are non-grep-able):
   - **grep-markers**: TODO/FIXME/HACK/NotImplemented · stubs/no-ops/"for now" · magic numbers/hardcodes/raw `Sleep(2000)` · empty `catch {}` swallowing logic · test-coverage gaps.
   - **flow-reading**: unfinished UX / dead paths / missing business actions (FOLLOW entry points, not markers) · perf & edges (N+1, repeated I/O, hot allocs, null/empty/boundary).
   - **bold re-imagining (→ 🆕)**: break a PREMISE ("why is it an X at all?"), borrow a metaphor, invert a default — run **CLEAN-ROOM** (do NOT read the existing; anchoring kills divergence), no `file:line`, distinct lenses must DIVERGE.
   - **Coverage dial**: default = mostly 🔧 **+ ≥1-2 bold 🆕 GUARANTEED** (kills the linter-only blind spot); "fresh vision" request → tilt 🆕.
3. **Gate — a raw hit is NOT a candidate (TYPE-AWARE).** First cull false positives (`Sleep(pollMs)` legit → discard vs `Sleep(2000)` → keep; best-effort `catch {}` → discard vs swallowing a real error → keep). Then tag, each faces its OWN gate:
   - **🔧 fix** survives iff: REAL defect + BOUNDED + a real `file:line` + a MEASURABLE done-signal (build green / test red→green / reproducible metric). "Improve the UX" with no done-signal → reject.
   - **🆕 new** survives iff: a clear **Why** + a concrete first step as **How** (no `file:line` — it doesn't exist yet). Vague "make it better" → reject.
4. **Ownership / duplicate check.** Already covered by a skill / test / ticket → flag **owned**, exclude. **Before ANY 🆕** grep the kit + live copy + neighbours for an existing version FIRST (reflex 6 — trap #1 = the duplicate): if it exists → reframe to "wire / finish / distribute it", NEVER "create from scratch".

## Output  (default)
ONE table, ranked most-pickable first; the **top row must be directly pickable as a `frame` input**. Scout STOPS here (the user picks a row → `frame`).
| # | Score | Type | What | Why | How |
|---|---|---|---|---|---|
| 1 | 🟢\|🟡\|🔴 | 🔧 fix \| 🆕 new | what it is, 1 line | the problem it solves / the value | the concrete first step (+ `file:line` if it's a fix) |
- **Number every row** (`#` column, 1..N in final rank order) so the user can pick a candidate by number ("row 3 → `frame`"). The number is the PICK HANDLE, not a priority score — priority is carried by the Score band + rank order.
- **Score = a coarse BAND** 🟢 keep / 🟡 maybe / 🔴 drop (value × feasibility × fit), **producer-judged, NOT a verified measure — never a 2-digit /100**. Rank by band, then value/effort.
- Keep ALL internal machinery OUT of the table (per-lens scores, "taste"/"novelty"/baskets stay under the hood — only the Score band surfaces).
- If a 🔧 and a 🆕 point at the SAME lever, add ONE line under the table saying so. Already-owned items → one line "already covered: X" at most.

## Modes
- **default** (Procedure + Output above) — trigger: "what to improve / which task / where to start / what could this become" on a target.
- **UNBLOCK** — trigger: "how do I make X work despite blocker Y / get around this limit / there must be a way" (a desired capability stopped by a constraint, NOT "what to improve"). The candidate is a **solution-approach**. In ORDER: **(1) RESEARCH ARM FIRST** (parallel prior-art: docs/issues/web — is the blocker a DOCUMENTED platform limit? what techniques do others use? **NEVER declare "impossible/intrinsic" without a CITED source** — the scar this mode prevents). **(2) PREMISE-BREAK** (challenge "why must Y hold?", borrow adjacent domains, invert defaults; DISTINCT approaches, not variants). **(3) Rank by FEASIBILITY × FIT** — each approach carries: technique · premise broken · feasibility-seed (smallest real step + CITED fact) · cost · *does it PRESERVE the user's must-keep constraints?* (a violator is ranked last/dropped, said so). **Output** = table `Approach · How · Preserves <constraint>? · Feasibility-seed (+source) · Cost`. Honest close: a genuine limit → state it WITH the citation + the closest-fitting approach, never a bare "impossible".

## Don't
- **FIX / execute** — scout PROPOSES, touches nothing (read-only).
- Merely **LOCATE** known code → that's the `Explore` agent (scout RANKS opportunities, it doesn't locate).
- **Frame** an already-chosen need → `frame` · review a diff → code-review · judge a deliverable → `judge` · audit a behavior/workflow → `judge` Mode B.
- Emit a **/100**, per-lens scores, or internal jargon in the output table.

## Engine & reflexes
- Pool mechanics — **parallel lens fan-out, loop-until-dry, dedup-by-core-idea, the two /100 scales (impact ⟂ autonomy-confidence), the auto-resolve-vs-surface gate, schema `gg-1`** — are CANONICAL in `_engine/ENGINE.md` **Ch.1 GENERATE & GATE**. On divergence, the engine wins. (Scout's delta = the MIXED lens pool + the type-aware 🔧/🆕 gate + the single ranked table.)
- Reflex anchor: **trap #1 = the duplicate** — check what EXISTS before proposing any 🆕.
