---
name: front-converge
description: Use when the user wants to DESIGN or iterate a UI/layout and the visual intent is NOT yet settled — "fais-moi une interface / un écran / une page", "propose des layouts", "je sais pas quel design / à quoi ça doit ressembler", "itère sur le design", "trouve le bon agencement", "refais le look de X". Drives a VISUAL ELICITATION LOOP: diverge ~3 distinct layout/design directions as rendered mockups → user keeps/kills/mixes → refine → converge to explicit approval → port the approved design to the target tech. TECH-NEUTRAL (web / WinForms / WPF). Do NOT use when the user already DESCRIBES the layout structure (where the sidebar/header/grid go) or hands a finished spec — that is an implementation order, go to `frontend-design` directly; nor for back-end/logic work.
---

# front-converge — visual elicitation through iterative mockups

## Purpose
**Surface the user's REAL visual intent by SHOWING it, not guessing it.** Describing a UI in words is lossy;
the user recognizes what they want when they SEE it. This skill DIVERGES into distinct directions, renders
them as mockups the user can compare, captures the choice, NARROWS, and converges to explicit approval — then
materializes the winner in the target tech.

This is NOT "produce one good UI" (that is `frontend-design`, which we INVOKE per variant). The new thing here
is **the convergence loop**. The loop is the invariant; the render+capture backend is PLUGGABLE.

## When NOT to use (boundary with frontend-design)
- The user already DESCRIBES the layout (e.g. "sidebar left, card grid, blue header") → that is a spec →
  `frontend-design` directly.
- A finished design/spec to implement → `frontend-design`.
- Back-end / data / logic → not this skill.
Use `front-converge` only while the visual intent is OPEN and worth diverging on.

## The loop (procedure)

1. **Frame the minimum** — which screen/surface, the REAL content to place, the TARGET TECH (web / WinForms /
   WPF — ASK if not obvious, never assume web), hard constraints (existing design system? responsive?). Do
   NOT over-frame the style: that is what the loop discovers.
2. **Read the user's taste FIRST** — do not hardcode it: recall it from memory (e.g. `[[feedback_portail_design_lineaire]]`)
   so the divergence stays within the user's taste and its anti-patterns, and stays current if the taste evolves.
3. **Diverge K=3 DISTINCT directions** (not cosmetic variants of one idea). Within the taste guardrails, each
   direction MUST differ on **≥2 of these axes**: information density · typographic hierarchy · accent-color
   usage · spatial structure (grid / columns / cards) · motion/restraint. Invoke `frontend-design` for the
   execution quality of EACH direction. Round 1 = broad divergence (layout + tone).
   **Shared vocabulary**: the named directions/structures/details (Linéaire, editorial, dense, rail, hairline,
   status-stripe…) with RENDERED examples live in `design-glossary.html` (bundled next to this file) — use its
   terms so you and the user mean the same thing; it marks the user's default direction + the banned anti-patterns.
4. **Render + CAPTURE + READ** each direction (backend per tech, below). **Self-check BEFORE showing the user**:
   not broken (non-empty render, glyphs OK, no dead binding/layout), and the taste guardrails are respected. A
   capture that is not READ has no value.
5. **Present for CHOICE** — one comparison artifact (side-by-side gallery) + ask the user to **keep / kill /
   mix** (+ free comment). Prefer `AskUserQuestion` if available; otherwise ask plainly in the reply. If the
   user rejects all 3, the directions miss the target → re-diverge differently, never re-offer the same set.
6. **Narrow** — refine the kept direction + GRAFT the liked parts of the others. Later rounds = narrowing
   (style, density, detail), no longer broad divergence.
7. **Converge → STOP at EXPLICIT user approval** (never auto-stop: aesthetics is not auto-provable, the human
   eye closes). Cap ~4-5 rounds; if it does not converge → "lock the layout, iterate only the style" or raise
   the need back to the user.
8. **Freeze + PORT** — produce a **design spec** (template below) and hand it to `frontend-design` / `build`
   for implementation in the target tech. This skill does not rewrite the implementation engine; it delivers
   the settled design and ports it.

### Design-spec template (the freeze handed to the port)
```
TARGET TECH : web (React/Next…) | WinForms | WPF
LAYOUT      : grid/structure (regions + their placement)
TOKENS      : colors (bg / surface / accent / text) · typography (display / body) · spacing scale · radius
TONE        : the chosen aesthetic direction in one line
GUARDRAILS  : the taste rules that must hold (from memory)
KEPT/KILLED : elements grafted in, elements rejected
```
**Porting notes per tech** (the HTML mockup conveys layout + intent, not pixel-exact):
- **web** → pass the HTML Artifact + spec to `frontend-design`; it is the closest target.
- **WPF** → map layout to `Grid`/`StackPanel`/`DockPanel`; tokens to a `ResourceDictionary` (brushes, styles);
  drop web-only effects. **MANDATORY**: do at least ONE real-render capture (build → `capture-window.ps1` →
  Read) before presenting the ported result — the HTML mockup cannot faithfully represent native control
  layout, so validating only the HTML would leave the WPF loop unexercised.
- **WinForms** → map to `TableLayoutPanel`/`FlowLayoutPanel`/`Panel`; ignore CSS; same MANDATORY real-render capture.

## Render+capture backends (pluggable per tech)

| Target | Render | Capture READ by Claude |
|---|---|---|
| **web / HTML** | `Artifact` tool (publishes a self-contained page) | render locally with **Claude Preview** and screenshot it. These are deferred tools — load the schema first: `ToolSearch "select:mcp__Claude_Preview__preview_start,mcp__Claude_Preview__preview_screenshot,mcp__Claude_Preview__preview_stop"`. Full per-round cycle: `preview_start` → `preview_screenshot` → **Read** the PNG → **`preview_stop`** (always stop before the next round, else a stale preview can block the next `preview_start`) |
| **WPF / WinForms** | build + launch the project | `capture-window.ps1` (bundled here): `-Exe <path>` or `-WindowTitle <substring>` or `-ProcId <pid>` → PrintWindow → PNG → **Read** |
| any target | per-variant quality | invoke `frontend-design` (do NOT reimplement) |

Note: `visualize.show_widget` renders INLINE in chat (for presenting to the user) — it does NOT produce a
PNG on disk, so it is NOT a substitute for the READ self-check; use Claude Preview for that.

`capture-window.ps1` (next to this file): generic (by title / PID / exe), detects the "exited early" crash and
near-black renders. Example: `powershell -NoProfile -File capture-window.ps1 -Exe "C:\proj\bin\Debug\App.exe" -KillFirst`.

## Taste guardrails (diverge WITHIN the taste, not at random)
Do NOT bake taste values into this skill — **read them from memory at runtime** (`[[feedback_portail_design_lineaire]]`).
The fiche is the single source of truth; do not copy its values here (they would go stale if the taste evolves).
They bound the divergence; they do not cancel it (the 3 directions stay distinct on ≥2 axes). Always validate
against the read capture.

## Caps
- K = **3** directions / round · cap ~**4-5 rounds** · variants generated in parallel.
- Closure = **explicit user approval** (attestable signal, not replayable — assumed honestly).

## Don't
- **Do NOT reimplement `frontend-design`** (per-variant quality) nor the `Artifact` tool — ORCHESTRATE them.
- **Do NOT converge at random**: respect the taste guardrails read from memory.
- **Do NOT show a mockup that was not CAPTURED+READ** (dead binding/layout is invisible otherwise).
- **Do NOT declare "done" without explicit user approval.**
- **Do NOT assume the tech** (web vs WinForms vs WPF) — ask.
- Implementing an ALREADY-settled design → `frontend-design` directly (not this loop).

## Engine & reflexes
- Parallel variant generation, loop-until-dry, dedup-by-core-idea → **ENGINE Ch.1 (GENERATE & GATE)**. The
  freeze→port handoff and any code increments produced from the spec → **ENGINE Ch.4 (BUILD)**. On divergence,
  the engine wins.
- Reflex anchor: a capture that is not READ has no value (screenshot-loop); closure of aesthetics is the
  human eye, not a self-judged "looks good".
