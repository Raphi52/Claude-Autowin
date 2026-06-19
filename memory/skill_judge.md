---
name: skill_judge
description: "A substantial deliverable is 'done' -> reach for judge (the final gate): adversarial EXTERNAL review, scored per dimension, LOOPED to the regime threshold; it sends defects back to the producer and NEVER fixes what it audits. Trap: producer=judge is NOT proof — don't self-certify."
metadata:
  node_type: memory
  type: reference
---

**Use when** — any non-trivial artifact (code / script / doc / skill / plan / spec) is produced and must be validated BEFORE it counts as done: "is this good / audit the quality / is it really done / validate this / up to standard". (Mode B audits a behavior/habit/skill-set instead of a deliverable.)

**You get** — a per-dimension verdict surfaced as a coarse BAND (not false-precision digits) + defects WITH PROOF, sent back to the producer to fix, in a loop to threshold.

**Trap** — producer=judge is NOT proof -> **don't self-certify; run judge** (or at minimum require an out-of-model artifact). 100 on TEXT alone is forbidden for anything executable — confront the real (run it on a case). judge NEVER repairs what it audits (-> [[skill_build]]); switching hats same-session is fine, but a judge never audits work it just produced. The single most common miss: shipping a self-declared green that a real adversarial pass would have caught.
