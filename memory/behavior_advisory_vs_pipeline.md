---
name: behavior_advisory_vs_pipeline
description: "An advisory question ('which is the best X / is it better to / what is X / why') expects a direct ANSWER, not a pipeline — answer short and direct, no frame/RUN/QCM/judge. The aggressive skill-routing targets TASKS ('create/build/make X'), not questions. Backed by the advisory-guard hook."
metadata:
  node_type: memory
  type: feedback
---

**Use the pipeline for TASKS, not for ADVICE.** A question with an OPEN whether/what and NO action verb ("which is the best / is it better to / what is X / why") wants an answer usable in one message → answer it directly and short. Do NOT spin up frame + RUN + scored options + a decision QCM.

A request shaped as a SOLUTION with an action verb ("create / build / make / fix X") → that is a task → route to the pipeline ([[skill_frame]] etc.).

A frustration / redirect signal ("just the answer / nothing more / I didn't understand / too long") → STOP the machinery, answer the question ASKED.

**Backed by a hook** — `advisory-guard.ps1` (UserPromptSubmit) injects a reminder on advisory/frustration signals; loading a rule ≠ applying it, so the wired hook is the real net. In light doubt: answer first, then offer in ONE line "I can frame/build it if you want" — let the human trigger the pipeline, don't presume it. See [[behavior_thinking_mode]].
