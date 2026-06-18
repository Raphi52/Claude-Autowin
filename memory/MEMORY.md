# Memory index — STARTER kit-generic (à fusionner, voir README-INSTALLATION § « Shared memories »)

> Sous-ensemble PARTAGEABLE des fiches mémoire : uniquement le **kit-générique** (mécanique des hooks/RUN.md,
> workflow, préférences). **Les réflexes cardinaux NE sont PAS ici** — ils vivent déjà dans `CONSTITUTION.md`.
> Les fiches **spécifiques machine/projet** (RIG, TestViewer, Rapture, accès prod, builds locaux) ne sont
> volontairement PAS distribuées. Une ligne par fiche. Sur install : copier ces `.md` dans ton
> `autoMemoryDirectory` et fusionner ces lignes dans TON `MEMORY.md`.

## Mécanique du kit (hooks / RUN.md / maintenance) — recommandé
- [signal-cmd RUN.md = `powershell -NoProfile -File`, pas `& "...ps1"`](workflow_runmd_signalcmd_form.md) — le stop-gate rejoue sous `cmd.exe /c` ; `&` y est un séparateur → faux BLOCK. Répliquer `Invoke-GateCmd` avant de clore green.
- [Stop-gate v3.2 scope les RUN.md par session](project_stopgate_session_scoping.md) — n'enforce que les runs de SA session (emplacement `Audit\workspaces\<session_id>\` ou header `session:`) ; session_id injecté chaque tour ; filet legacy.
- [Après édition kit LIVE → lance sync-kit.ps1](workflow_sync_kit_after_edit.md) — kit = 2 copies (live `~/.claude` ; package `~/Desktop/Autowin`). Après édition skill/ENGINE/hook → `sync-kit.ps1`. EXCLUS : CONSTITUTION.md, settings-snippet.json.
- [Process self-contained — aucune délégation tierce](feedback_process_self_contained.md) — le kit n'a AUCUNE dépendance plugin ; la mécanique d'exécution vit dans ENGINE Ch.4 BUILD.
- [Message de commit git sans BOM sur Windows](workflow_git_commit_msg_no_bom_windows.md) — message multi-ligne/accentué → Bash heredoc (UTF-8 no BOM), JAMAIS `Out-File -Encoding utf8` (PS5.1 ajoute un BOM qui pourrit le sujet).

## Workflow générique — recommandé
- [Récupérer un Workflow interrompu depuis le disque](workflow_recover_interrupted_workflow.md) — « reprends » après run tué : parser les `StructuredOutput.findings` des `agent-*.jsonl` AVANT de relancer.
- [Reprendre une session = flux COMPLET, pas le tail](workflow_resume_full_not_tail.md) — reconstruire tout le `.jsonl` (prompts + skills + dernier RUN open), pas les 12 dernières lignes.
- [Hygiène disque — anti-littering](workflow_anti_littering.md) — tracke ce que tu crées ; en fin de tâche supprime le transitoire, garde le livrable + `## Reprise` ; jamais de suppression hors de ton scratch sans confirmation.
- [Repo multi-sessions : un fichier change sous toi](feedback_files_change_under_you_multisession.md) — grep TOI-MÊME le dossier avant de créer (le « 0 match » d'un Explore peut être stale) ; re-lis juste avant d'écrire.

## Comportement adossé à un hook du kit — recommandé
- [Question advisory ≠ tâche à construire](feedback_advisory_question_vs_build_task.md) — « quelle est la meilleure X / quel choix ? » → réponse directe et courte, PAS de frame+RUN+QCM. Adossé au hook `advisory-guard.ps1` + Advisory hard-gate.
- [Utilité > sophistication](feedback_utility_over_sophistication.md) — mesurer l'utilité à ce que l'user peut UTILISER, pas au volume ; répondre à la question POSÉE ; méthodo → liste numérotée. Gravé CONSTITUTION réflexes 14-18.
- [Préfixe `?` = mode pensée](feedback_thinking_mode_prefix.md) — message commençant par `?` = réflexion à voix haute, PAS un ordre → discuter, aucune action irréversible. Adossé au hook `?` (settings-snippet).

## Préférences (ce sont CELLES de l'auteur — adopte ou ignore selon ton équipe)
- [Sortie de skill = table simple, zéro jargon](feedback_skill_output_plain_no_jargon.md) — sortie = table `Type · What · Why · How`, zéro jargon interne. *(préférence)*
- [Comms signées par l'user = SA voix](feedback_user_voice_comms.md) — texte qu'il signera (Teams/mail) : partir de SON texte, corriger SEULEMENT l'orthographe, zéro restructuration sauf demande. *(préférence)*
