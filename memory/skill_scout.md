---
name: skill_scout
description: "When you don't yet know WHAT to do on a target ('what to improve / where to start / find a task / any tech debt / a fresh vision') -> reach for scout BEFORE asking the user or jumping to frame. Trap: scout RANKS opportunities, it does not locate code (->Explore) or fix/frame/judge."
metadata:
  node_type: memory
  type: reference
---

**Use when** — you face a touchable target and the WHAT is undecided: "what could I improve in X / where do I start / any debt or opportunities / what could this become". Also UNBLOCK mode: "how do I make X work despite Y" -> scout researches prior-art FIRST, never declares "impossible" without a cited source.

**You get** — ONE ranked table (Score band · Type · What · Why · How): each row a 🔧 fix (with a real `file:line` + a measurable done-signal) or a 🆕 new feature (the first concrete step).

**Trap** — a "what should I do here?" question is scout's JOB: derive it, don't ask the user. scout RANKS; it does NOT locate known code (-> the Explore agent), fix (-> [[skill_build]]), frame (-> [[skill_frame]]), or judge. Read-only. Hand the top row to frame. The aggregate Score is a coarse band (keep/maybe/drop), producer-judged — a decision aid, not a measurement.
