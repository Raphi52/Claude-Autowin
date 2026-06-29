# Claude pipeline kit — workstation install (company-wide)

Installs the **self-correcting work system** on this machine: **6 skills** — the pipeline (scout / frame /
terrain / judge) + `build` (defect loop) + `kaizen` (improve the kit from its own failures) — + shared engine
+ a layer of **guardrail hooks** (stop-gate, anti-flaky, fix-gate, advisory-guard, kaizen system) + a
constitution of reflexes. Designed to be deployed identically on every
workstation. **Current version: see `VERSION` (this kit = 3.6.0).**

---

## 🔄 UPDATE — already have a previous version? — just tell your Claude: "update the kit"

> Claude: if `%USERPROFILE%\.claude\skills\frame` (or older-generation skills like `define-need` /
> `review-work` / `concevoir-boucle-travail`) already exist, this is an **UPDATE**, not a fresh install.
> The update is **version-agnostic** — it upgrades from ANY previous version. Do this, then give the recap:

1. **Overwrite the kit files** with the newer ones in this folder (full-file replacements, not merges):
   `skills\scout|frame|terrain|judge|build|kaizen|_engine` , ALL of `hooks\*.ps1` (**17** — incl.
   `model-tier` `judge-nudge` `precompact-runcheck` `session-inject` `thinking-mode` `build-cadence`
   `git-auth-gate` `full-autonomy-directive` `full-autonomy-allow` on top of `stop-gate` `anti-flaky` `fix-gate`
   `advisory-guard` `kaizen-detect` `kaizen-nudge` `kaizen-revert-log` `test-hooks`),
   and `output-styles\concis-structure.md` (if the user opted into the output-style — see Step 9).
2. **Remove obsolete older-generation skills** no longer shipped here (current pipeline = `scout` `frame`
   `terrain` `judge` `build` + `_engine`). Ask before deleting (e.g. `define-need`, `review-work`, `concevoir-boucle-travail`).
3. **Constitution** — in `%USERPROFILE%\.claude\CLAUDE.md`, **REPLACE** the existing
   `Constitution — cardinal reflexes` section with `CONSTITUTION.md`. **Do NOT append a second copy.** Leave
   any machine-only `## Local` section UNTOUCHED.
4. **Hooks wiring** — make the `hooks` block in `settings.json` match `hooks\settings-snippet.json`. If the
   entries already exist, leave them; **never duplicate**. Validate the JSON parses.
5. **What's new in 3.6.0** — the full **17-hook** set is now documented — NEW `git-auth-gate` enforces the cardinal git rule (no `commit`/`push` without a session authorization) + 8 previously-inline hooks (`model-tier` `judge-nudge` `precompact-runcheck` `session-inject` `thinking-mode` `build-cadence` `full-autonomy-directive` `full-autonomy-allow`); `full-autonomy` is **opt-in, OFF by default** (`AUTOWIN_AUTONOMY=1` — see `SECURITY.md`); `judge-nudge` no longer burns on RUN.md/memory writes. **3.5.0** — security + hook hardening (RCE-by-clone closed, proof allowlist, extended anti-flaky, fail-closed, CI, LICENSE) → details in [`CHANGELOG.md`](CHANGELOG.md). **What's new in 3.4.0 — apply if missing**:
   - **`build` skill** — the producer's named fix loop (reproduce → localize → fix → verify red→green → guard
     → loop back to judge). Copy `skills\build` (Step 1).
   - **`kaizen` skill** — improve the kit from its OWN failures: locate a failed session / recurrent pattern →
     behavioral audit (reuses `judge` Mode B) → PROPOSE kit diffs → human OK → integrate + sync-kit. Never
     auto-writes. Copy `skills\kaizen` (Step 1).
   - **`fix-gate.ps1` hook** (PreToolUse Write|Edit) — denies a blind-fix loop (repeated edits to the same
     code file) unless a verified-cause token is present (`CausalHypothesis:` / `fix-ok:` / `check:`).
   - **Kaizen system** (`kaizen-detect.ps1` + `kaizen-nudge.ps1` + `kaizen-revert-log.ps1`) — auto-PROPOSE
     loop: telemetry of recurrent failures → a non-blocking Stop nudge toward a behavioral audit (judge
     Mode B) → a PROPOSED kit diff → **human OK** → write. **Never auto-writes.** Telemetry is
     `session`-attributed so detection is not cross-session contaminated.
   - **`advisory-guard.ps1` hook** (UserPromptSubmit, non-blocking) — reminds Claude to answer DIRECTLY (no
     frame/RUN/QCM/judge) on advisory/frustration prompts. Backs the new **Advisory hard-gate** (routing) +
     **reflexes 14-18** in `CONSTITUTION.md`.
   - **Stop-gate v3.2 — per-session scoping** (from 3.3.0): concurrent sessions no longer cross-block; skills
     write RUN.md under `~\.claude\runs\<session_id>\<subject>-workspace\` (user-global, out of the project tree).
6. **Reload** — restart Claude Code (hooks + output-style load only at startup).
7. **Verify** — same pipe-tests as Step 7 below + confirm `VERSION` now reads 3.6.0. (Or run the bundled
   harness: `powershell -NoProfile -File hooks\test-hooks.ps1` → exit 0 = all hooks still bite.)

> Check the kit's `VERSION` against what's installed to know the delta. When in doubt, the safe path is
> simply to re-run the full **INSTALLATION** below — every step already asks before overwriting.

---

## 🤖 INSTALLATION — just tell your Claude: "execute this README"

> Claude: you are **installing this kit on this machine**. Source files are in **the folder containing this
> README**. Execute the steps in order, ask before overwriting anything that exists, then give the final recap.

**Step 1 — Skills + engine**
- Copy the folders `skills\scout`, `frame`, `terrain`, `judge`, `build`, `kaizen`, `_engine` → `%USERPROFILE%\.claude\skills\`.
- If a version already exists (including older generations: define-need/review-work/etc.): ask before
  overwriting/removing (this kit REPLACES older generations).

**Step 2 — Hooks (the guardrails)**
- Copy ALL of `hooks\*.ps1` → `%USERPROFILE%\.claude\hooks\` (create the folder) — **17 hooks**:
  `stop-gate.ps1`, `anti-flaky.ps1`, `fix-gate.ps1`, `advisory-guard.ps1`,
  `kaizen-detect.ps1`, `kaizen-nudge.ps1`, `kaizen-revert-log.ps1`,
  `model-tier.ps1`, `judge-nudge.ps1`, `precompact-runcheck.ps1`, `session-inject.ps1`, `thinking-mode.ps1`,
  `build-cadence.ps1`, `git-auth-gate.ps1`, `full-autonomy-directive.ps1`, `full-autonomy-allow.ps1`, `test-hooks.ps1`.

**Step 3 — Wire the hooks (MERGE, never overwrite)**
- Open `%USERPROFILE%\.claude\settings.json` (create `{}` if missing).
- **Merge** the content of `hooks\settings-snippet.json`: append the entries to any existing
  `hooks.PreToolUse` / `hooks.PostToolUse` / `hooks.Stop` / `hooks.PreCompact` / `hooks.UserPromptSubmit`
  arrays (or create the `hooks` block). Touch NO other key. Paths use `$env:USERPROFILE` → portable as-is.
- Validate that the final JSON parses (`ConvertFrom-Json`).

**Step 4 — Constitution (reflexes loaded into every session)**
- APPEND the content of `CONSTITUTION.md` to the end of `%USERPROFILE%\.claude\CLAUDE.md` (create the file if
  missing; if a "Constitution — cardinal reflexes" section already exists, REPLACE it, don't duplicate).

**Step 5 — Workspace root (user-global — NOTHING created in your repo)**
- The skills write their RUN.md / workspaces under `%USERPROFILE%\.claude\runs\<session_id>\<subject>-workspace\`
  (i.e. `~\.claude\runs\`) — **user-global, OUT of any project tree**. Your source folder stays clean; this is
  the DEFAULT baked into the hooks, identical on every machine, **no per-machine setup**.
- Optional override: set env `AUTOWIN_RUN_ROOT` to relocate that root. A legacy per-project
  `<cwd>\Audit\workspaces\` is still honored during transition (so in-flight runs aren't lost).

**Step 6 — Reload**
- Tell the user: **open `/hooks` in Claude Code (or restart)** — hooks only load at startup.

**Step 7 — Verify (for REAL, not on word)**
- Files present: 7 skill folders (6 + `_engine`) + 17 hooks (incl. `test-hooks.ps1`) + a `hooks` block in settings.json (valid JSON).
- **Stop-gate pipe-test**: create a temp folder containing `x-workspace\RUN.md` with `status: open`, pipe
  `{"cwd":"<temp>","stop_hook_active":false}` into `stop-gate.ps1` → must answer `decision:block`;
  with `status: green` → nothing. Clean up the temp.
- **Anti-flaky pipe-test**: a Write payload for a `.ps1` containing a raw `Start-Sleep -Seconds 5` → `deny`;
  with ` # sleep-ok: <justification>` on the line → nothing.
- **Advisory-guard pipe-test**: pipe `{"prompt":"quelle est la meilleure archi"}` into `advisory-guard.ps1`
  → emits an `additionalContext` reminder; `{"prompt":"cree le module"}` → nothing.

**Step 8 — Tell the user how it works**
- Substantial work → the pipeline triggers automatically: `frame` (the WHAT + which approach) → `terrain`
  (the HOW) → build (execution mechanics: ENGINE Ch.4) → `judge` (quality). `scout` at step 0 when the task
  is not yet chosen; `build` to resolve a defect to a verified green. 100% autonomous, no plugins.
- **Stop-gate v3**: Claude can no longer close a turn with an open, non-green run — a `green` is not taken on
  faith: the gate REPLAYS `signal-cmd` (idempotent allowlist), executes the `check:` lines, and checks the
  anti-fixation rule. Honest closure without a green = `degraded-closed` with YOUR consent on record. Per-run
  opt-out: `gate: off`.
- **Anti-flaky**: any raw sleep ≥ 2 s in code is refused — escape hatch: `sleep-ok: <justification>`.
- **Fix-gate**: a blind-fix loop (same repeated edits) is refused without a VERIFIED cause — escape hatch:
  `CausalHypothesis:` / `fix-ok:` / `check:` on a line.
- **Advisory-guard**: an advisory question or a frustration signal ("just the answer / didn't understand")
  reminds Claude to answer DIRECTLY, not via the pipeline.
- **Kaizen (auto-PROPOSE, never auto-write)**: telemetry of recurrent blocks (`gate-counters.jsonl`) triggers
  a non-blocking Stop nudge toward a behavioral audit (judge Mode B) that PROPOSES a kit improvement — YOU
  approve before any write. The loop never rewrites the kit on its own.
- Block counters: `%USERPROFILE%\.claude\gate-counters.jsonl` (the trend is the real measure).

**Step 9 — (OPTIONAL) Readability output-style « Concis-Structure »**
- The pipeline skills produce verbose output. For scannable answers (BLUF + 1-line steps + closing
  `✅ Fait` / `⚡ TL;DR` blocks, readable on their own), install the bundled output-style:
  - Copy `output-styles\concis-structure.md` → `%USERPROFILE%\.claude\output-styles\` (create the folder).
  - In `%USERPROFILE%\.claude\settings.json`, merge `"outputStyle": "Concis-Structure"` (touch no other key).
- **Opt-in**: skip it and Claude Code's default response behavior is unchanged. Loads at session start.

**Step 10 — (OPTIONAL) Starter memories (`memory\`)**
- `memory\` ships a **purpose-built, kit-generic** starter set: one fiche per pipeline skill (when/how + the
  one trap), the kit mechanics (RUN.md & gates, maintenance), the hook-backed behavioral guardrails, and
  generic workflow hygiene — impersonal, no personal preferences. **NOT** here, by design: machine/project-
  specific memories (your app, your test harness, prod access…) and the **cardinal reflexes** (already in
  `CONSTITUTION.md` — don't double them).
- **How to treat them on install**:
  1. Pick the `.md` files you want from `memory\` — the **Pipeline skills** + **Operating the kit** fiches
     are the most broadly useful; the behavioral + workflow ones are optional reinforcement.
  2. Copy them into your project's **autoMemoryDirectory** — `~/.claude/projects/<project>/memory/` (the path
     set by `"autoMemoryDirectory"` in your `settings.json`; create the folder if missing).
  3. **MERGE** (don't overwrite) the corresponding lines from `memory\MEMORY.md` into your own `MEMORY.md`
     index — keep one line per fiche.
  4. Adapt any example path inside a fiche to your project. Fix or drop a `[[link]]` pointing to a fiche you
     didn't copy (a dangling link is harmless, just unresolved).
- **Opt-in**: skipping this changes nothing — memories are reinforcement, not required for the kit to run.

---

## Kit contents
| Item | Role |
|---|---|
| `skills\` (scout/frame/terrain/judge/build/kaizen + `_engine\ENGINE.md`) | the pipeline + build + kaizen + the canonical engine (THE CORE = 7 concepts; the rest = reference by regime) |
| `skills\kaizen` | improve the kit from its own failures: behavioral audit (reuses judge Mode B) → PROPOSE → human OK → integrate + sync-kit (never auto-writes) |
| `hooks\stop-gate.ps1` | **out-of-model closure authority** — a green is REPLAYED/verified, never believed |
| `hooks\anti-flaky.ps1` | refuses raw sleeps in code (kills false signals at the source) |
| `hooks\fix-gate.ps1` | refuses blind-fix loops without a verified cause (`CausalHypothesis:`/`fix-ok:`/`check:`) |
| `hooks\advisory-guard.ps1` | nudge: answer advisory/frustration prompts DIRECTLY, not via the pipeline |
| `hooks\kaizen-detect.ps1` + `kaizen-nudge.ps1` + `kaizen-revert-log.ps1` | **kaizen auto-PROPOSE loop**: recurrent-failure telemetry → Stop nudge → behavioral audit → PROPOSED diff → human OK (never auto-writes) |
| `hooks\model-tier.ps1` · `session-inject.ps1` · `thinking-mode.ps1` · `precompact-runcheck.ps1` | wiring & guards: economical sub-agent model · per-turn session-id injection · `?`-thinking-mode guard · pre-compaction open-RUN reminder |
| `hooks\judge-nudge.ps1` | once-per-session reminder to run a real deliverable through `judge` (skips RUN.md / memory noise) |
| `hooks\build-cadence.ps1` | PostToolUse nudge: after N code edits with no verify, run the real signal (ENGINE Ch.4) — non-blocking |
| `hooks\full-autonomy-directive.ps1` + `full-autonomy-allow.ps1` | **opt-in, OFF by default** (`AUTOWIN_AUTONOMY=1`): "don't ask, drive to completion" + auto-approve tool calls (deny-gates still win). ⚠ see `SECURITY.md` |
| `hooks\git-auth-gate.ps1` | enforces the cardinal git rule: denies `commit`/`push` unless authorized this session (user says commit/push, or `AUTOWIN_GIT_AUTH=1`); read-only git passes |
| `hooks\test-hooks.ps1` | **hook self-test** (PARSE/FIRE/SILENT per hook — catches a fail-open); run in CI (`.github/workflows/test-hooks.yml`) or in a `check:` |
| `hooks\settings-snippet.json` | full hook wiring + economical-model tiering for sub-agents (merge) |
| `CONSTITUTION.md` | the cardinal reflexes (incl. Advisory hard-gate + kaizen reflexes 14-18), loaded every session |
| `output-styles\concis-structure.md` | **(optional, Step 9)** scannable response format |
| `memory\` (+ `MEMORY.md`) | **(optional, Step 10)** curated kit-generic starter memories to merge into your autoMemoryDirectory; machine/RIG-specific fiches + cardinal reflexes excluded (the latter live in `CONSTITUTION.md`) |
| `sync-kit.ps1` | propagates live→package (portabilising paths); `-Check` = drift diff. Run after editing any live skill/ENGINE/hook/output-style |
| `workflows\improve-from-telemetry.js` | **(optional)** kit-improvement loop DRIVEN BY REAL telemetry (`gate-counters.jsonl`), not a speculative scout; PROPOSE only |
| `VERSION` | kit version string |

> **Not shipped (per-machine, by design):** `skills\_pipeline-audit\LEDGER.md` (this machine's improvement
> history); the kaizen runtime state `gate-counters.jsonl` + `kaizen-treated.jsonl` (each install builds its
> own); `sync-kit.ps1` excludes them. Likewise the live `CLAUDE.md` carries a machine-only `## Local` section
> (documents the active hooks on that machine) absent from `CONSTITUTION.md` — on reinstall, do NOT double-append.

> ⚠️ Honest limit (by design): hooks guarantee the deterministic part; JUDGMENT reflexes remain probabilistic
> — the final safety net is the human. Any green not backed by an artifact announces itself as
> "self-declared, unverified".
