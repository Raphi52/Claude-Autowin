---
name: workflow_resume_and_recover
description: "Resuming a session = reconstruct the FULL flow (user prompts + invoked skills + the last OPEN RUN.md), not the last few lines (which may be an abandoned question). Recovering a killed Workflow = parse the agents' structured findings from disk BEFORE relaunching the missing parts."
metadata:
  node_type: memory
  type: reference
---

**Resume = full reconstruction, not the tail.** "Resume session X" → rebuild the WHOLE picture: the user prompts, the skills invoked, and the last OPEN `RUN.md` — not the last dozen lines (which might be an abandoned QCM). The true resume point = the last open RUN + the unmet intent behind it.

**Recover a killed Workflow from disk** — before relaunching, parse the already-produced structured findings from the run's agent journals on disk (don't redo finished work); relaunch only the missing parts, in parallel. See [[kit_run_and_gates]].
