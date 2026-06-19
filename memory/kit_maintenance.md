---
name: kit_maintenance
description: "Operating & maintaining the kit: it lives in TWO copies (live `~/.claude` = source of truth, package = redistributable mirror); run `sync-kit.ps1` after editing any live skill/ENGINE/hook; verify hooks out-of-model with `test-hooks.ps1`. Trap: edit live then forget to sync -> the published copy silently diverges."
metadata:
  node_type: memory
  type: reference
---

**Two copies.** LIVE `~/.claude` (what actually runs) is the source of truth; the PACKAGE (the repo) is the redistributable mirror. After editing any live skill / ENGINE / hook / output-style, run `sync-kit.ps1` (live→package, portabilizes machine paths). EXCLUDED from sync (hand-reconciled): `CONSTITUTION.md`, `settings.json` ↔ `hooks/settings-snippet.json`, and `memory/` (this starter set).

**Verify hooks out-of-model.** After editing ANY hook, run `~/.claude/hooks/test-hooks.ps1` (per hook: PARSE / FIRE / SILENT-on-negative-control — it catches a closure hook gone fail-open). A NEW hook must also be ADDED to the sync-kit manifest + the install steps (the manifest is a fixed list — new items are silently missed otherwise).

**Self-contained.** The kit has NO plugin dependency; the execution mechanics live in `ENGINE.md` Ch.4 (BUILD). "Delegate to skill X" → if X isn't in the kit, the logic belongs in ENGINE.

**Trap** — editing live then forgetting `sync-kit` leaves the package stale. On Windows, write a multi-line/accented commit message via a Bash heredoc (UTF-8, no BOM); `Out-File -Encoding utf8` (PS 5.1) prepends a BOM that lands in the commit subject. See [[skill_kaizen]] (it integrates + verifies kit edits).
