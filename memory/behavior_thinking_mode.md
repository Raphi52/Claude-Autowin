---
name: behavior_thinking_mode
description: "A prompt starting with `?` = the user thinking out loud, NOT an order — discuss/structure, launch NO Write/Edit/Agent tool and NO irreversible action until an explicit order WITHOUT the `?`. Backed by the thinking-mode hook."
metadata:
  node_type: memory
  type: feedback
---

**`?`-prefix = think-with-me, not do.** When a prompt starts with `?`, the user is reasoning out loud, not commanding. Discuss, structure, weigh options — but launch NO Write/Edit/Agent tool and NO irreversible action until they give an explicit order WITHOUT the `?`.

**Backed by a hook** — `thinking-mode.ps1` (UserPromptSubmit) injects the reminder when it sees the `?` prefix. The full-autonomy directive (if enabled) defers to it — `?` always wins. See [[behavior_advisory_vs_pipeline]].
