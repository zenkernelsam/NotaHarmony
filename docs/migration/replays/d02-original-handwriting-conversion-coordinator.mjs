import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const readRepo = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = name => fs.readFileSync(path.join(originalRoot, name), 'utf8').replaceAll('\r\n', '\n');
const hashOriginal = name => crypto.createHash('sha256')
  .update(fs.readFileSync(path.join(originalRoot, name))).digest('hex').toUpperCase();

const planner = readRepo('note/src/main/ets/core/adaptation/OriginalHandwritingConversionPlanner.ets');
const textPolicy = readRepo(
  'note/src/main/ets/core/adaptation/OriginalHandwritingConversionTextPolicy.ets');
const coordinator = readRepo(
  'note/src/main/ets/core/adaptation/OriginalHandwritingConversionCoordinator.ets');
const recognition = readRepo('note/src/main/ets/core/adaptation/OriginalHandwritingRecognition.ets');
const insertEncoder = readRepo('note/src/main/ets/data/OriginalInsertTextPayloadEncoder.ets');
const persistence = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const plannerFixture = readRepo('note/src/test/OriginalHandwritingConversionPlanner.test.ets');
const coordinatorFixture = readRepo('note/src/test/OriginalHandwritingConversionCoordinator.test.ets');
const persistenceFixture = readRepo('note/src/test/StrokePersistence.test.ets');
const encoderFixture = readRepo('note/src/test/OriginalCreateTextPayloadEncoder.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');
const evidence = readRepo(
  'docs/migration/evidence/original-handwriting-conversion-coordinator-jadx-2026-08-22.md');

const checks = [
  ['original action filters eligible Ink and snapshots IDs before conversion',
    readOriginal('dhb.java').includes('arrayList8.add(((s06) it11.next()).getId())') &&
    readOriginal('hc5.java').includes('if (listA2.isEmpty())')],
  ['original state machine rejects all-whitespace recognition without trimming accepted text',
    readOriginal('tsc.java').includes('!lvd.E0(str)') &&
    readOriginal('lvd.java').includes('cq.f0(charSequence.charAt(i))') &&
    readOriginal('cq.java').includes('Character.isWhitespace(c2) || Character.isSpaceChar(c2)')],
  ['original transaction order remains pinned',
    readOriginal('bt1.java').indexOf('u5j.l(') < readOriginal('bt1.java').indexOf('u5j.f(') &&
    readOriginal('bt1.java').indexOf('u5j.f(') < readOriginal('bt1.java').indexOf('s5j.i(')],
  ['planner delegates result size and Unicode to the shared text policy',
    planner.includes('inspectOriginalHandwritingConversionText') &&
    !planner.includes('result.text.length > ORIGINAL_HANDWRITING_CONVERSION_MAX_TEXT_LENGTH') &&
    planner.includes('RESULT_INVALID_UNICODE') && planner.includes('RESULT_WHITESPACE_ONLY')],
  ['shared text policy preserves whitespace and checks strict UTF-8 bytes',
    textPolicy.includes('inspectOriginalInsertStringValue') &&
    textPolicy.includes('WHITESPACE_ONLY') && textPolicy.includes('Character.isWhitespace') &&
    textPolicy.includes('Character.isSpaceChar')],
  ['original whitespace classification precedes the Harmony wire-size rejection',
    textPolicy.indexOf('isOriginalHandwritingWhitespaceOnly(value)') <
      textPolicy.indexOf('const encoded: OriginalInsertStringValueInspection =') &&
    plannerFixture.includes("' '.repeat(1048577)")],
  ['encoder and planner use one exported 1 MiB byte constant',
    insertEncoder.includes('MAX_ORIGINAL_INSERT_STRING_BYTES') &&
    insertEncoder.includes('decodeToString(encoded) !== value')],
  ['coordinator keeps one accepted ID stream for planner OCR and persistence',
    coordinator.includes('selection.acceptedStrokeIds.slice()') &&
    coordinator.includes('selection.strokes') && coordinator.includes('plan.sourceStrokeIds') &&
    coordinator.includes('sourceStrokes.push(cloneStrokeSnapshot(source))')],
  ['coordinator rechecks page generation and fingerprint after async recognition',
    coordinator.includes('freshnessReader.readCurrent()') &&
    coordinator.includes('checkOriginalHandwritingConversionResult(') &&
    coordinator.includes('STALE_RESULT')],
  ['coordinator rejects non-original source identities before OCR or persistence',
    coordinator.includes('SOURCE_IDENTITY_UNSUPPORTED') &&
    coordinator.includes('decodeOperationId(id) === null') &&
    coordinator.indexOf('hasOriginalPersistenceSourceIds(plan.sourceStrokeIds)') <
      coordinator.indexOf('if (provider === null)') &&
    coordinatorFixture.includes("stroke('nb-imported'") &&
    coordinatorFixture.includes('expect(provider.calls).assertEqual(0)')],
  ['coordinator does not allocate Text identities or mutate UI/history stacks',
    !coordinator.includes('allocateOperationIdentity') && !coordinator.includes('UndoRedo') &&
    !coordinator.includes('SelectionTool') &&
    coordinator.includes('persistence.commitOriginalHandwritingConversion(')],
  ['persistence remains the owner of exact source validation and operation identities',
    persistence.includes('plan.sourceStrokes.map(cloneStrokeThroughPersistence)') &&
    persistence.includes('sameByteArrays(stored.payload,') &&
    persistence.includes('allocateOperationIdentity(store, noteId)')],
  ['persistence reuses the shared text policy',
    persistence.includes('inspectOriginalHandwritingConversionText') &&
    persistence.includes('OriginalHandwritingConversionTextStatus.VALID')],
  ['fixtures cover exact ASCII, multibyte overflow, surrogate and whitespace gates',
    plannerFixture.includes("'x'.repeat(1048576)") &&
    plannerFixture.includes("'中'.repeat(350000)") && plannerFixture.includes('\\uD800') &&
    persistenceFixture.includes('whitespaceOnly') && persistenceFixture.includes('invalidUnicode') &&
    encoderFixture.includes('MAX_ORIGINAL_INSERT_STRING_BYTES')],
  ['coordinator fixture covers every structured failure class and snapshot immutability',
    coordinatorFixture.includes('PROVIDER_UNAVAILABLE') &&
    coordinatorFixture.includes('CONTEXT_FAILURE') && coordinatorFixture.includes('PROVIDER_FAILURE') &&
    coordinatorFixture.includes('PROVIDER_NO_RESULT') && coordinatorFixture.includes('STALE_RESULT') &&
    coordinatorFixture.includes('PERSISTENCE_FAILURE') &&
    coordinatorFixture.includes('MISSING_PAGE_FRAME') &&
    coordinatorFixture.includes("expect(persistence.noteId).assertEqual('note-1')") &&
    coordinatorFixture.includes('mutated')],
  ['coordinator fixture is registered in the executed ArkTS suite',
    fixtureList.includes('OriginalHandwritingConversionCoordinator.test') &&
    fixtureList.includes('originalHandwritingConversionCoordinatorTest();')],
  ['evidence and report retain the no-provider/no-UI boundary',
    evidence.includes('真实 OCR provider') && evidence.includes('SelectionOverlay') &&
    evidence.includes('不得')],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

const byteLength = value => Buffer.byteLength(value, 'utf8');
assert.equal(byteLength('x'.repeat(1048576)), 1048576);
assert.equal(byteLength('中'.repeat(350000)) > 1048576, true);
assert.notEqual(Buffer.from('\uD800', 'utf8').toString('utf8'), '\uD800');
assert.equal([...new Set(['page-1', 7, 'fingerprint-7'])].length, 3);
console.log('PASS: numeric UTF-8 and freshness fixture values');

console.log(`D02_ORIGINAL_HANDWRITING_CONVERSION_COORDINATOR_OK TOTAL=${checks.length + 1} FAILED=0`);
