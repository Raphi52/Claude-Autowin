---
name: workflow_files_change_multisession
description: "In a repo where several sessions/agents run concurrently a file can change under you: grep the folder YOURSELF before creating (a sub-agent's '0 matches' can be stale), re-read a file just before writing it, and if a file you're editing changes under you, STOP — a concurrent writer is active."
metadata:
  node_type: memory
  type: reference
---

**A file can change under you.** When several agents/sessions share a repo: grep the target folder YOURSELF before creating something (a sub-agent's "0 matches" can be stale or wrong); re-read a file just before you edit it.

**Trap** — if a file you're working on changes under you mid-task, that's a concurrent writer → STOP, remove any duplicates you made, and surface it rather than fighting the other writer. See [[workflow_anti_littering]].
