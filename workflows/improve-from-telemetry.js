export const meta = {
  name: 'improve-from-telemetry',
  description: 'Variante TELEMETRY-DRIVEN de improve-system : les candidats viennent des gate-counters REELS (les hooks qui mordent en usage reel) via kaizen-detect, PAS d un scout speculatif. Diagnostic faux-positif (assouplir le hook) vs vrai souci recurrent (corriger la cause). PROPOSE only, jamais auto-applique.',
  phases: [
    { title: 'Telemetry', detail: 'kaizen-detect sur gate-counters.jsonl -> patterns reels (hors test)' },
    { title: 'Diagnose', detail: 'par pattern: faux-positif (loosen) vs vrai souci (fix la cause)' },
    { title: 'Verify', detail: 'la premisse tient ? (lit hook + fichier)' },
    { title: 'Stress-test', detail: 'casser chaque candidat verifie' },
    { title: 'Judge', detail: 'judge BLIND la valeur + reconcile en code -> best' },
  ],
}

const KIT = "Cible = LE KIT: skills sous %USERPROFILE%\\.claude\\\\skills\\\\ + hooks PowerShell sous %USERPROFILE%\\.claude\\\\hooks\\\\*.ps1 + routing CLAUDE.md. Philosophie: un-skill-un-job; cloture hors-modele (RUN.md + stop-gate); PROPOSE jamais auto-write. LIS les vrais fichiers, cite file:line."
const MUST_KEEP = "Must-keep (un candidat qui viole = penalise): lean / un-skill-un-job ; un producteur/executeur non-negociable ; self-contained ; proportionnel ; cloture = humain + hooks ; honnetete producer=juge. NB: assouplir un GARDE-FOU (gate) est risque -> exiger que le faux-positif soit PROUVE recurrent et que l'assouplissement ne cree pas de fail-open."

const TELE_SCHEMA = { type: 'object', additionalProperties: false, properties: { patterns: { type: 'array', items: { type: 'object', additionalProperties: false, properties: { gate: { type: 'string' }, file: { type: 'string' }, count: { type: 'number' }, kind: { type: 'string' }, behavioral: { type: 'boolean' }, sample_reason: { type: 'string' } }, required: ['gate', 'count', 'sample_reason'] } } }, required: ['patterns'] }
const CAND_SCHEMA = { type: 'object', additionalProperties: false, properties: { what: { type: 'string' }, why: { type: 'string' }, type: { type: 'string', enum: ['fix', 'new'] }, where: { type: 'string' }, how: { type: 'string' }, diagnosis: { type: 'string', enum: ['false-positive-loosen', 'real-issue-fix'] }, evidence: { type: 'string' }, runtime_consequence: { type: 'string' }, confidence: { type: 'number' } }, required: ['what', 'why', 'type', 'where', 'how', 'diagnosis', 'evidence', 'runtime_consequence', 'confidence'] }
const VERIFY_SCHEMA = { type: 'object', additionalProperties: false, properties: { premise_verified: { type: 'boolean' }, evidence_real: { type: 'string' }, note: { type: 'string' } }, required: ['premise_verified', 'evidence_real', 'note'] }
const STRESS_SCHEMA = { type: 'object', additionalProperties: false, properties: { survives: { type: 'boolean' }, weaknesses: { type: 'array', items: { type: 'string' } }, severity: { type: 'string', enum: ['none', 'minor', 'major', 'fatal'] }, note: { type: 'string' } }, required: ['survives', 'weaknesses', 'severity', 'note'] }
const JUDGE_SCHEMA = { type: 'object', additionalProperties: false, properties: { value_score: { type: 'number' }, verdict: { type: 'string' }, why: { type: 'string' } }, required: ['value_score', 'verdict', 'why'] }

// PHASE 1 — TELEMETRY : la source de candidats = les gate-counters REELS (out-of-model), pas un scout.
phase('Telemetry')
const tele = await agent(
  `Tu lis la TELEMETRIE REELLE des gates du kit. Lance EXACTEMENT :\n` +
  `  powershell -NoProfile -File %USERPROFILE%\\.claude\\hooks\\kaizen-detect.ps1 -MinCount 2 -SinceDays 30\n` +
  `(il agrege ~/.claude/gate-counters.jsonl en patterns recurrents ; il EXCLUT deja les sessions 'test-' et les chemins C:\\x\\ / C:\\tmp\\ = fixtures de test). Lis AUSSI les ~40 dernieres lignes de ~/.claude/gate-counters.jsonl pour recuperer un 'reason'/'details' d'exemple par gate. ` +
  `Rends patterns = [{gate, file, count, kind, behavioral, sample_reason}] (sample_reason = un exemple de motif de blocage reel). ` +
  `IMPORTANT : ne garde QUE des blocages d'usage REEL ; ecarte tout ce qui pue le dev-du-kit / le test (chemins de fixture, sessions test-). Si apres ce tri il ne reste rien de significatif, retourne patterns: [].`,
  { label: 'telemetry', model: 'sonnet', phase: 'Telemetry', schema: TELE_SCHEMA })

let patterns = (tele && Array.isArray(tele.patterns)) ? tele.patterns : []
log(`Telemetry: ${patterns.length} pattern(s) reel(s) hors test`)
if (!patterns.length) {
  log('Telemetrie insuffisante (aucun pattern reel hors test). Accumule de l usage REEL du kit puis relance. Rien a proposer.')
  return { ranked: [], best: null, reason: 'telemetry-empty', total_raw: 0 }
}
patterns.sort((a, b) => (b.count || 0) - (a.count || 0))
if (patterns.length > 8) patterns = patterns.slice(0, 8)

// PHASE 2 — DIAGNOSE : par pattern, faux-positif (assouplir le hook) vs vrai souci (corriger la cause).
phase('Diagnose')
const candidates = (await parallel(patterns.map(pt => () =>
  agent(
    `Le gate '${pt.gate}' a MORDU ${pt.count}x ${pt.file ? ('sur ' + pt.file) : '(sans fichier attribue)'} en usage REEL (exemple de motif: ${pt.sample_reason}). ${KIT}\n${MUST_KEEP}\n` +
    `LIS le hook concerne (~/.claude/hooks/${pt.gate}.ps1, ou stop-gate.ps1 si gate='stop') ET, si un fichier est cite, ce fichier. DIAGNOSTIC obligatoire : ce blocage recurrent est-il\n` +
    ` (A) un FAUX-POSITIF -> le hook sur-mord du travail legitime -> propose de l'ASSOUPLIR MINIMALEMENT (sans creer de fail-open) ; ou\n` +
    ` (B) un VRAI souci recurrent -> la cause (code/skill/habitude) derriere doit etre corrigee.\n` +
    `Produis 1 candidat: what / why (A ou B + raison citee) / type(fix|new) / where(file:section) / how(1er pas concret) / diagnosis(false-positive-loosen|real-issue-fix) / evidence (= '${pt.gate} x${pt.count}' + le motif reel) / runtime_consequence / confidence 0-100. Si le pattern est en fait du bruit (test, dev-du-kit), confidence<30.`,
    { label: `diagnose:${pt.gate}`, model: 'opus', phase: 'Diagnose', schema: CAND_SCHEMA })
    .then(c => (c && c.confidence >= 30) ? c : null))) ).filter(Boolean)

log(`Diagnose: ${candidates.length} candidat(s) (confidence >=30)`)
if (!candidates.length) {
  log('Aucun candidat significatif apres diagnostic -> rien a proposer.')
  return { ranked: [], best: null, reason: 'no-candidate', total_raw: patterns.length }
}

// PHASE 3+4+5 — VERIFY (cheap) -> STRESS (sonnet) -> JUDGE BLIND (opus) + reconcile EN CODE (meme tail que improve-system)
phase('Verify')
const verifiedAll = (await parallel(candidates.map(c => () =>
  agent(`Tu es un VERIFICATEUR de premisse, rapide et factuel. Candidat (issu de la telemetrie ${c.evidence}):\n- what: ${c.what}\n- where: ${c.where}\n- diagnosis: ${c.diagnosis}\nLIS le(s) fichier(s) cite(s). premise_verified=true SEULEMENT si: (a) le hook fait bien ce que le candidat decrit a l'endroit cite, (b) le diagnostic (faux-positif vs vrai souci) est plausible vu le code, (c) le fix ne cree pas de fail-open sur un garde-fou. Sinon false. evidence_real = ce que tu trouves ; note = pourquoi.`,
    { label: `verify:${c.type}`, model: 'haiku', phase: 'Verify', schema: VERIFY_SCHEMA })
    .then(v => ({ cand: c, v })))) ).filter(Boolean)
const passedV = verifiedAll.filter(x => x.v.premise_verified)
const droppedFalse = verifiedAll.filter(x => !x.v.premise_verified)
// Kaizen 2026-06-18 (self-gate over own work): un Verify cheap (haiku) n'est PAS l'autorite FINALE qui TUE un
// candidat -> chaque premisse jugee FAUSSE repasse par un 2e verificateur DECORRELE (sonnet). On ne drop QUE si
// les DEUX confirment ; au moindre doute on PROMEUT au stress/judge (un gate cheap PASSE en aval, il ne TUE pas).
const rechecked = droppedFalse.length ? ((await parallel(droppedFalse.map(x => () =>
  agent(`2e VERIFICATEUR DECORRELE. Le 1er a juge la premisse de ce candidat FAUSSE - RE-CHALLENGE-le (surtout si ca touche du code recemment modifie : un producteur rate souvent le bug de sa propre edition). ${KIT}\nCandidat: what=${x.cand.what} / where=${x.cand.where} / diagnosis=${x.cand.diagnosis}. Motif du 1er rejet: ${x.v.note}. LIS le(s) fichier(s) cite(s). premise_verified=true si la premisse tient EN FAIT (le 1er s'est trompe) ; false SEULEMENT si tu CONFIRMES qu'elle ne tient pas. Au moindre doute -> true.`,
    { label: `recheck:${x.cand.type}`, model: 'sonnet', phase: 'Verify', schema: VERIFY_SCHEMA })
    .then(v2 => ({ ...x, v2 })))) ).filter(Boolean)) : []
const revived = rechecked.filter(x => x.v2 && x.v2.premise_verified).map(x => ({ cand: x.cand, v: x.v2 }))
const reallyDropped = rechecked.filter(x => !(x.v2 && x.v2.premise_verified))
if (revived.length) log(`Re-challenge: ${revived.length} premisse(s) RESSUSCITEE(s) par le 2e verificateur decorrele (le gate cheap s'etait trompe)`)
const passed = passedV.concat(revived)
log(`Verify: ${passed.length}/${verifiedAll.length} premisses tiennent (dont ${revived.length} ressuscitee(s)). Tues: ${reallyDropped.map(x => x.cand.what).join(' | ') || 'aucun'}`)

const results = await pipeline(
  passed,
  (x, _o, i) => agent(
    `Tu es un STRESS-TESTER ADVERSARIAL. ${KIT}\n${MUST_KEEP}\nCANDIDAT (telemetrie ${x.cand.evidence}, premisse verifiee):\n- what: ${x.cand.what}\n- why: ${x.cand.why}\n- where: ${x.cand.where}\n- how: ${x.cand.how}\n- diagnosis: ${x.cand.diagnosis}\nEssaie de le CASSER en lisant les VRAIS fichiers: (1) contredit une mecanique existante? (2) duplique l'existant? (3) bloat? (4) effet de bord sur un autre skill/hook? (5) SI c'est un assouplissement de gate: cree-t-il un FAIL-OPEN / affaiblit-il la cloture? (6) survit-il aux lanes Lean+Conformer? Verdict: survives, weaknesses, severity (none|minor|major|fatal), note.`,
    { label: `stress:${i}`, model: 'sonnet', phase: 'Stress-test', schema: STRESS_SCHEMA }
  ).then(s => ({ ...x, stress: s })),
  (x, _o, i) => agent(
    `Tu es un JUGE de VALEUR impartial. ${MUST_KEEP}\nEvalue UNIQUEMENT la valeur intrinseque (NE juge PAS la solidite technique, deja faite):\n- what: ${x.cand.what}\n- why: ${x.cand.why}\n- where: ${x.cand.where}\n- evidence telemetrie: ${x.cand.evidence}\n- runtime_consequence: ${x.cand.runtime_consequence}\nvalue_score /100 = IMPACT reel (un pattern a fort count = forte douleur reelle) x FAISABILITE x FIT must-keep. verdict (1 ligne), why. Score la VALEUR brute.`,
    { label: `judge:${i}`, model: 'opus', phase: 'Judge', schema: JUDGE_SCHEMA }
  ).then(j => {
    const pen = x.stress.severity === 'fatal' ? 60 : x.stress.severity === 'major' ? 35 : x.stress.severity === 'minor' ? 10 : 0
    const final = Math.max(0, Math.min(j.value_score, 100) - pen)
    return { what: x.cand.what, type: x.cand.type, where: x.cand.where, how: x.cand.how, diagnosis: x.cand.diagnosis, evidence: x.cand.evidence, runtime_consequence: x.cand.runtime_consequence, value_score: j.value_score, stress: x.stress, judge: j, final }
  })
)

const ranked = results.filter(Boolean).sort((a, b) => b.final - a.final)
log(`Pipeline: ${ranked.length} candidats stress+juges (judge BLIND, reconcile code)`)
return {
  ranked,
  best: ranked[0] || null,
  dropped_false_premise: reallyDropped.map(x => ({ what: x.cand.what, why: x.v2.note })),
  total_raw: patterns.length,
}
