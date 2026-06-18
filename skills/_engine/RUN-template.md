<!-- RUN-template.md — copy this file to Audit\workspaces\<session_id>\<sujet>-workspace\RUN.md
     (<session_id> = injected each turn by the UserPromptSubmit hook; ONE folder per session; Stop-gate
     v3.2 enforces ONLY the runs of its own session). Fallback: flat path if no session_id.
     Full convention: _engine/ENGINE.md ch.3.
     The Stop hook reads the header: open/red block end-of-turn; green is REPLAYED, not trusted at face value. -->
status: open
session: <session_id>       <!-- scopes the run to this session (otherwise the <session_id>\ location is authoritative) -->
regime: standard            <!-- disposable | standard | critical — the effort dial -->
signal: <the OUT-OF-MODEL artifact that will prove green — e.g. "test-x.ps1 exit 0", "capture read", "SQL query n>0">
signal-cmd: <optional but powerful — IDEMPOTENT command the gate will REPLAY via cmd /c; whitelisted prefixes:
  dotnet test | dotnet build | cmd /c | powershell -NoProfile -File | powershell -File —
  QUOTE any path containing spaces, and run it yourself once before declaring it>
signal-attestable: <optional — non-replayable out-of-model proof (e.g. "capture read + run-stamp", "SQL query
  n>0 read"); in CRITICAL regime, satisfies the proof requirement when there is neither signal-cmd nor check:>
gate: on                    <!-- on (default) | off — opt-out for a throwaway run: the Stop hook skips the ENTIRE gate if 'off' appears in the first 14 lines (cf. stop-gate.ps1) -->

## Besoin
**Deep-why** : <the real problem, not the solution requested>
**Scope IN** : <what is covered> / **Scope OUT** : <what is not, and why>
**Critere de succes verifiable** : <how we will KNOW it is done>
**Decisions deliberees** : <deliberate choices the review should not re-flag>
**Hypotheses annoncees** : <"I am assuming X (fact: ...) — correct me">

## Options
<!-- if an approach choice is ENGAGED: >=3 GENUINELY distinct scored options + Décision: line
     (the gate checks at closure; strawman options = a defect the judge will flag) -->
- Option A — <desc> score: NN
- Option B — <desc> score: NN
- Option C — <desc> score: NN
Décision: <which one and why>

## Journal
<!-- append-only : [ts] unit=<id> run=<stamp> VERIFIED|FAILED|FLAKY|CLAIM|PROOF|USER-OK -->

## Défauts
<!-- judge ledger: [severity, status] description — never erased, resolved or accepted-with-reason -->

## Reprise
Goal:
Hypothesis:
Tried:
Next:
Blockers:

## Cicatrices
<!-- lessons from the run (volatile -> treat as HYPOTHESIS); promote to check: or memory when durable (ENGINE ch.3) -->

## Checks
<!-- lessons promoted to code, EXECUTED by the gate at every closure: check: <command exit!=0 = blocks> -->
