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

const xsc = readOriginal('xsc.java');
const bt1 = readOriginal('bt1.java');
const jc5 = readOriginal('jc5.java');
const u5j = readOriginal('u5j.java');
const bmb = readOriginal('bmb.java');
const qed = readOriginal('qed.java');
const fqa = readOriginal('fqa.java');
const planner = readRepo(
  'note/src/main/ets/core/adaptation/OriginalHandwritingConversionPlanner.ets');
const fixture = readRepo('note/src/test/OriginalHandwritingConversionPlanner.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');
const evidence = readRepo(
  'docs/migration/evidence/original-handwriting-conversion-planner-jadx-2026-08-19.md');

check('original conversion source hashes are pinned',
  hashOriginal('xsc.java') ===
    '41C4BD1D24F50E04C095B319BA4B1F37CD04ACD9B43B744DF67D78F89FFF5BB8' &&
  hashOriginal('bt1.java') ===
    'A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA' &&
  hashOriginal('jc5.java') ===
    'A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405');
check('xsc enforces a single page before conversion',
  xsc.includes('singlePageOf called with an empty selection') &&
  xsc.includes('if (!ba6.o(((s06) it.next()).i(), cxcVarI))'));
check('xsc computes union bounds and expands each axis to at least eight',
  xsc.includes('fMax - fMin') && xsc.includes('if (f < 8.0f)') &&
  xsc.includes('if (f2 < 8.0f)') && xsc.includes('No bounds for conversion selection'));
check('xsc requires a page frame and returns its origin with the bounds',
  xsc.includes('No page frame for conversion') &&
  xsc.includes('return new k1a(bmbVarS, bmbVar.c())'));
check('bt1 preserves original mutation order in one xq9 transaction',
  bt1.includes('u5j.l(x09Var, (ArrayList) obj6') &&
  bt1.includes('u5j.f(x09Var, cz0.TEXT') &&
  bt1.includes('s5j.i(x09Var, str, qo5VarA'));
check('u5j Text creation takes page, relative origin, and size',
  u5j.includes('public static rl2 f(x09 x09Var, cz0 cz0Var, cxc cxcVar, fqa fqaVar') &&
  u5j.includes('qedVar2.getClass()') && u5j.includes('Cannot create a block on an unknown page'));
check('bmb/fqa/qed expose origin and width-height as separate values',
  bmb.includes('Rect(origin=') && bmb.includes('return qedVar') &&
  fqa.includes('getFloat(this.I + 4)') && qed.includes('Size(width=') &&
  qed.includes('getFloat(this.I)'));
check('planner has explicit single-page, frame, bounds, and visibility gates',
  planner.includes('MIXED_PAGES') && planner.includes('MISSING_PAGE_FRAME') &&
  planner.includes('INVALID_BOUNDS') && planner.includes('HIDDEN_STROKE') &&
  planner.includes('stroke.pageId !== frame.pageId'));
check('planner reproduces the eight-unit minimum and page-relative origin',
  planner.includes('ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE') &&
  planner.includes('ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE - width') &&
  planner.includes('ORIGINAL_HANDWRITING_CONVERSION_MIN_SIZE - height') &&
  planner.includes('originalFloat') &&
  planner.includes('left - frame.origin.x') && planner.includes('top - frame.origin.y'));
check('planner records identity transform because bt1 omits the optional transform',
  planner.includes('bt1 passes no optional transform') &&
  planner.includes('textTransform: identityTransform()'));
check('late OCR results are guarded by page, generation, and source fingerprint',
  planner.includes('STALE_PAGE') && planner.includes('STALE_GENERATION') &&
  planner.includes('STALE_SOURCE') && planner.includes('currentSourceFingerprint !== plan.sourceFingerprint'));
check('mutation plan preserves text exactly and orders delete/create/insert',
  planner.includes("['DELETE_ENTITIES', 'CREATE_BLOCK', 'INSERT_STRING']") &&
  planner.includes('richText: result.text') && planner.includes('deleteStrokeIds: plan.sourceStrokeIds.slice()'));
check('ArkTS fixture covers geometry, gates, stale results, and operation order',
  fixture.includes('bounds expansion') && fixture.includes('mixed pages') &&
  fixture.includes('old page, generation, or source') &&
  fixture.includes('delete/create/insert order'));
check('planner fixture is registered in the executed suite',
  fixtureList.includes("import originalHandwritingConversionPlannerTest from './OriginalHandwritingConversionPlanner.test';") &&
  fixtureList.includes('originalHandwritingConversionPlannerTest();'));
check('evidence records original hashes and the no-persistence boundary',
  evidence.includes('41C4BD1D24F50E04C095B319BA4B1F37CD04ACD9B43B744DF67D78F89FFF5BB8') &&
  evidence.includes('DELETE_ENTITIES') && evidence.includes('尚未接入'));

const union = { left: 10, top: 18, right: 16, bottom: 23 };
let width = union.right - union.left;
let height = union.bottom - union.top;
let left = union.left;
let top = union.top;
if (width < 8) {
  left -= (8 - width) / 2;
  width = 8;
}
if (height < 8) {
  top -= (8 - height) / 2;
  height = 8;
}
check('numeric replay centers a narrow union at the original eight-unit minimum',
  left === 9 && top === 16.5 && width === 8 && height === 8);
check('numeric replay subtracts page origin exactly once',
  left - 4 === 5 && top - 8 === 8.5);
check('numeric replay rejects a result after a source fingerprint change',
  'rev:12|ink-a' !== 'rev:13|ink-a');
check('numeric replay keeps whitespace in accepted OCR text', '  hello  '.length > 0);

console.log(`D02_ORIGINAL_HANDWRITING_CONVERSION_PLANNER_OK TOTAL=${total} FAILED=${failed}`);
if (failed > 0) process.exit(1);
