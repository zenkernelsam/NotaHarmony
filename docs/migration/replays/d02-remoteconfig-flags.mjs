// D02 RemoteConfig 特性开关面 delta — Phase 802
import assert from 'node:assert/strict';
import fs from 'node:fs';

const load = (v) => {
  const x = fs.readFileSync(
    `C:/Users/Cisco He/Desktop/Notability/decompiled_${v}/resources/res/xml/core_remoteconfig__remote_config_defaults.xml`,
    'utf8');
  const entries = [...x.matchAll(/<key>([a-zA-Z0-9]+)\s*<\/key>\s*<value>([^<]*)<\/value>|<key>([a-zA-Z0-9]+)\s*<\/key>\s*<value\/>/g)];
  const m = {};
  for (const e of entries) m[e[1] ?? e[3]] = (e[2] ?? '').trim();
  return m;
};
const A = load('1.0.3');
const B = load('1.4.2');
const S103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const S142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const keysA = Object.keys(A); const keysB = Object.keys(B);
const added = keysB.filter((k) => !(k in A));
const removed = keysA.filter((k) => !(k in B));
const shared = keysA.filter((k) => k in B);

check('flag inventory: 1.0.3=52 keys, 1.4.2=58 keys (+32/-26)',
  keysA.length === 52 && keysB.length === 58 && added.length === 32 && removed.length === 26);

check('zero default-value flips on shared flags',
  shared.every((k) => A[k] === B[k]));

check('1.4.2 headline features ship default-OFF (server-gated)',
  ['androidGallery', 'androidCalendarTimeline', 'androidFinishMyNotes',
    'androidShapeTool', 'androidTextOnlyMode', 'androidTypingSettings',
    'androidHandwritingRecognitionOutOfProcess', 'androidLearnSyllabusImport',
    'androidMarkdownAutoformat', 'androidMultiSelectInkEffects',
    'androidPhoneDifferentiatedUx', 'androidScopedTileInvalidation']
    .every((k) => B[k] === 'false'));

check('androidImageBlockOcr + androidImeSessionTelemetry ship default-ON',
  B.androidImageBlockOcr === 'true' && B.androidImeSessionTelemetry === 'true');

check('scalar defaults: StarterNoteLimit=30, MinLineSpacing=1.0, IdleTeardown=0, offer IDs empty',
  B.androidStarterNoteLimit === '30' && B.androidMinLineSpacing === '1.0'
  && B.androidRealtimeIdleTeardownSeconds === '0'
  && ['Lite', 'Plus', 'Pro'].every((t) => ['Annual', 'Monthly']
    .every((p) => B[`androidPlayOfferIds${t}${p}`] === '')));

check('26 removed flags = graduated features still present in 1.4.2 strings',
  removed.length === 26
  && removed.includes('androidZoomView') && removed.includes('androidPartialEraser')
  && removed.includes('androidSnapToGrid') && removed.includes('androidShareNote')
  && removed.includes('androidNoteLimit') && B.androidStarterNoteLimit === '30'
  && S142.includes('zoom_view') && S142.includes('eraser_partial')
  && S142.includes('ui_share__'));

check('ruler ungated in 1.0.3 -> re-gated androidRuler=false in 1.4.2',
  !('androidRuler' in A) && B.androidRuler === 'false'
  && S103.includes('ruler'));

check('Learn flag family graduated (LearnChat/Quizzes/Summary removed, keys live in ui_learn)',
  removed.includes('androidLearnChat') && removed.includes('androidLearnQuizzes')
  && removed.includes('androidLearnSummary') && S142.includes('ui_learn__'));

console.log(`remoteconfig-flags replay: ${checks.length}/${checks.length} checks green`);
