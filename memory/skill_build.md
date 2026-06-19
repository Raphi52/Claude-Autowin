---
name: skill_build
description: "A bug/defect — 'make it green / the test fails / apply the judge's findings / it's still broken' -> reach for build (the producer's loop): reproduce RED first, localize the REAL cause, fix minimally, verify red->green with an OUT-OF-MODEL artifact, then loop back to judge. Trap: the code you READ is not always the code that RUNS."
metadata:
  node_type: memory
  type: reference
---

**Use when** — a defect to resolve: "fix the bug / make it green / the test fails, repair it / it's still broken / apply the judge's findings / resolve the defects". Also fires right after `judge` returns defects to the producer.

**You get** — the defect marked `green` in the RUN ledger ONLY after a real artifact passed (test red->green / non-zero->zero exit / screenshot READ / query) — never on self-judged text.

**Trap** — no red -> no fix (don't patch an unreproduced bug). **The code you read != the code that runs** — confirm the live path / build / branch FIRST (the #1 trap: stale binary, wrong project, another copy). One cause, one fix (a bundled green can't attribute the fix or catch a regression). A self-written test passing proves the happy path, not the absence of the bug class. build NEVER signs its own quality verdict -> loop back to [[skill_judge]].
