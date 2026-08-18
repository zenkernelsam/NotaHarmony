import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const normalize = value => value.replaceAll('\r\n', '\n');
const readRepo = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const readOriginal = name => normalize(fs.readFileSync(path.join(originalRoot, name), 'utf8'));
const hashOriginal = name => createHash('sha256')
  .update(fs.readFileSync(path.join(originalRoot, name))).digest('hex').toUpperCase();

let total = 0;
let failed = 0;
function check(label, condition) {
  total++;
  if (condition) {
    console.log(`PASS: ${label}`);
  } else {
    failed++;
    console.error(`FAIL: ${label}`);
  }
}

const jc5 = readOriginal('jc5.java');
const rn2 = readOriginal('rn2.java');
const so5 = readOriginal('so5.java');
const wqh = readOriginal('wqh.java');
const pm8 = readOriginal('pm8.java');
const bmb = readOriginal('bmb.java');
const fqa = readOriginal('fqa.java');
const s06 = readOriginal('s06.java');
const parser = readRepo('note/src/main/ets/data/NotabilitySessionParser.ets');
const adapter = readRepo(
  'note/src/main/ets/core/adaptation/OriginalHandwritingSelectionAdapter.ets');
const recognition = readRepo('note/src/main/ets/core/adaptation/OriginalHandwritingRecognition.ets');
const fixture = readRepo('note/src/test/OriginalHandwritingSelectionAdapter.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');
const operationIdentity = readRepo('note/src/main/ets/data/OperationIdentity.ets');
const evidence = readRepo(
  'docs/migration/evidence/original-handwriting-selection-pointer-adapter-jadx-2026-08-18.md');

check('original selection/order source hashes are pinned',
  hashOriginal('jc5.java') ===
    'A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405' &&
  hashOriginal('rn2.java') ===
    'C788B6C5BBED0ACEC45D6217A151701E859EBB5157DF69AE46F4A9047BF1E414' &&
  hashOriginal('so5.java') ===
    'BA88BD05E24494B42D1DF413DB22BBEAE9B96C609AD8518717666BA5C9737E96' &&
  hashOriginal('wqh.java') ===
    'E5D214E59B17ACECC265DF543C544ED3F88ED918EC2E654347DAD0685D8623EB' &&
  hashOriginal('pm8.java') ===
    '96DCE90733FCD3137EC49B31552AC7D85153425D735EDCD308B9536E58778064');
check('jc5 resolves selected IDs, filters unavailable page/highlighter entries, and delegates sort',
  jc5.includes('((a79) x09Var).F.get(qo5Var)') &&
  jc5.includes('!((a79) x09Var).h.keySet().contains(new tz9(s06Var.i()))') &&
  jc5.includes('(z && !wqh.e(s06Var))') &&
  jc5.includes('new rn2(15)'));
check('rn2 case 15 and so5 implement original identity comparison',
  rn2.includes('case 15:') && rn2.includes('so5.a(((s06) obj).getId(), ((s06) obj2).getId())') &&
  so5.includes('Integer.compareUnsigned(qo5Var.d(), qo5Var2.d())') &&
  so5.includes('qo5Var.c() & 65535'));
check('wqh text recognition excludes exactly the highlighter tool',
  wqh.includes('return s06Var.k != u16.HIGHLIGHTER;'));
check('pm8 reads page origin before emitting separate force-bearing pointer streams',
  pm8.includes('byteBuffer.getFloat(i) + fqaVar.c()') &&
  pm8.includes('byteBuffer.getFloat(i + 4) + fqaVar.d()') &&
  pm8.includes('recognizer.pointerDown(') && pm8.includes('recognizer.pointerMove(') &&
  pm8.includes('recognizer.pointerUp(') && pm8.includes('recognizer.pointerCancel()') &&
  pm8.includes('Iterator it = list.iterator()'));
check('bmb/fqa expose a two-float page-frame origin',
  bmb.includes('Rect(origin=') && bmb.includes('fqaVar.b(i, byteBuffer)') &&
  fqa.includes('return this.J.getFloat(this.I)') && fqa.includes('return this.J.getFloat(this.I + 4)'));
check('Harmony imported Session strokes have stable noncanonical nb IDs and page-local identity transforms',
  parser.includes('`nb-${curve.uuid}`') && parser.includes('`nb-${pi}-${curve.index}`') &&
  parser.includes('transform: [1, 0, 0, 0, 1, 0, 0, 0, 1]'));
check('adapter exposes explicit per-stroke skip diagnostics and accepted IDs',
  adapter.includes('OriginalHandwritingSelectionSkipReason') &&
  adapter.includes('acceptedStrokeIds: string[]') && adapter.includes('skipped: OriginalHandwritingSelectionSkip[]'));
check('adapter applies Harmony finished/highlighter/partial/empty gates',
  adapter.includes('!stroke.isFinished') &&
  adapter.includes('stroke.renderSpec.isPartialEraser === true') &&
  adapter.includes('stroke.renderSpec.isHighlighter') &&
  adapter.includes('stroke.pathPoints.length === 0'));
check('adapter validates affine matrices and isolates nonfinite samples',
  adapter.includes('matrix.length !== 9') && adapter.includes('Math.abs(determinant) > AFFINE_EPSILON') &&
  adapter.includes('Number.isFinite(pathPoint.pressure)') &&
  adapter.includes('INVALID_SAMPLE'));
check('adapter uses original operation identity helpers and preserves imported slots',
  adapter.includes('decodeOperationId(strokeId)') && adapter.includes('compareOperationIdentity') &&
  adapter.includes('Replace only canonical slots') && adapter.includes('candidate.identity === null'));
check('adapter applies every affine coefficient and maps pressure directly to force',
  adapter.includes('matrix[0] * point.x + matrix[1] * point.y + matrix[2]') &&
  adapter.includes('matrix[3] * point.x + matrix[4] * point.y + matrix[5]') &&
  adapter.includes('force: pathPoint.pressure'));
check('recognition boundary still fails closed when adaptation produces no strokes',
  recognition.includes('strokes.length === 0') && recognition.includes('return null;'));
check('ArkTS fixture covers ordering, affine, force, filters, malformed isolation, and ambiguity',
  fixture.includes('sorts canonical identities') && fixture.includes('complete affine transform') &&
  fixture.includes('preserves force values') && fixture.includes('explicit reasons') &&
  fixture.includes('ambiguous page identity'));
check('new fixture is registered in the executed Hypium suite',
  fixtureList.includes("import originalHandwritingSelectionAdapterTest from './OriginalHandwritingSelectionAdapter.test';") &&
  fixtureList.includes('originalHandwritingSelectionAdapterTest();'));
check('operation identity decoder remains precision-safe and bounded',
  operationIdentity.includes('MAX_OPERATION_TIMESTAMP') && operationIdentity.includes('decodeOperationId') &&
  operationIdentity.includes('compareOperationIdentity'));
check('evidence records the original hashes and explicit imported-ID policy',
  evidence.includes('A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405') &&
  evidence.includes('nb-*') && evidence.includes('canonical 槽位排序'));

function decode(value) {
  const match = /^op:([0-9a-f]+):([0-9a-f]+)$/.exec(value);
  return match === null ? null : { timestamp: Number.parseInt(match[1], 16), site: Number.parseInt(match[2], 16) };
}
function compare(left, right) {
  return left.timestamp !== right.timestamp ? left.timestamp - right.timestamp : left.site - right.site;
}
function reorder(entries) {
  const canonical = entries.filter(entry => entry.identity !== null)
    .sort((left, right) => compare(left.identity, right.identity));
  let index = 0;
  return entries.map(entry => entry.identity === null ? entry : canonical[index++]);
}
const numericOrder = reorder([
  { id: 'op:2:0', identity: decode('op:2:0') },
  { id: 'nb-imported', identity: null },
  { id: 'op:1:2', identity: decode('op:1:2') },
  { id: 'op:1:1', identity: decode('op:1:1') },
]);
check('numeric replay keeps imported slot and sorts canonical slots',
  numericOrder.map(entry => entry.id).join('|') === 'op:1:1|nb-imported|op:1:2|op:2:0');
const unsignedOrder = reorder([
  { id: 'op:ffffffff:0', identity: decode('op:ffffffff:0') },
  { id: 'op:0:ffff', identity: decode('op:0:ffff') },
]);
check('numeric replay preserves unsigned timestamp ordering at the 32-bit boundary',
  unsignedOrder[0].id === 'op:0:ffff' && unsignedOrder[1].id === 'op:ffffffff:0');
const affine = [0, -2, 10, 3, 0, 20, 0, 0, 1];
const transformed = { x: affine[0] * 1 + affine[1] * 2 + affine[2],
  y: affine[3] * 1 + affine[4] * 2 + affine[5] };
check('numeric replay applies full affine transform to page samples',
  transformed.x === 6 && transformed.y === 23);
check('numeric replay keeps the no-pressure sentinel unchanged', -1 === -1);

console.log(`D02_ORIGINAL_HANDWRITING_SELECTION_ADAPTER_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) process.exit(1);
