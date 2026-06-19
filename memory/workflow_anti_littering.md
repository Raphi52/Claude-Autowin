---
name: workflow_anti_littering
description: "Disk hygiene: track the files you create; at the end of a task delete the transient ones (scratch, throwaway scripts, canary copies), keep the deliverable + its RUN.md. Never delete or overwrite anything outside your own scratch without confirmation."
metadata:
  node_type: memory
  type: reference
---

**Leave no litter.** Track every file you create during a task. At the end, delete the TRANSIENT ones (scratch files, throwaway scripts, canary copies, temporary run logs) and keep only the deliverable + its `RUN.md` ledger. Prefer the session scratchpad for temporary work; propose the cleanup rather than doing it silently if the user might want to inspect.

**Trap** — never delete or overwrite anything OUTSIDE your own scratch without confirmation (`rm -Recurse`, `git reset --hard`, overwriting a shared folder); if you didn't create it (or what you find contradicts how it was described), surface it instead of removing it. Code deliverables go to the repo, committed only on explicit request. See [[workflow_files_change_multisession]].
