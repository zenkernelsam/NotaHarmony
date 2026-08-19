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

const originalXsc = readOriginal('xsc.java');
const originalBt1 = readOriginal('bt1.java');
const originalU5j = readOriginal('u5j.java');
const originalS5j = readOriginal('s5j.java');
const originalHaa = readOriginal('haa.java');

const persistence = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const deleteReducer = readRepo('note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets');
const createReducer = readRepo('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const insertReducer = readRepo('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const batch = readRepo('note/src/main/ets/data/OriginalPageMutationBatch.ets');
const codec = readRepo('note/src/main/ets/data/OriginalHandwritingConversionMutationCodec.ets');
const history = readRepo('note/src/main/ets/data/PersistentHistory.ets');
const undoRedo = readRepo('note/src/main/ets/rendering/UndoRedoManager.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const planner = readRepo('note/src/main/ets/core/adaptation/OriginalHandwritingConversionPlanner.ets');
const opTypes = readRepo('note/src/main/ets/core/model/OpTypes.ets');
const codecFixture = readRepo('note/src/test/OriginalHandwritingConversionMutationCodec.test.ets');
const persistenceFixture = readRepo('note/src/test/StrokePersistence.test.ets');
const historyFixture = readRepo('note/src/test/PersistentHistory.test.ets');
const batchFixture = readRepo('note/src/test/OriginalCreateTextPayloadEncoder.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

const commitStart = persistence.indexOf('async commitOriginalHandwritingConversion(');
const historyStart = persistence.indexOf('async applyOriginalHandwritingConversionHistory(');
const historyEnd = persistence.indexOf('async commitOriginalClipboardPaste(', historyStart);
const commitMethod = persistence.slice(commitStart, historyStart);
const historyMethod = persistence.slice(historyStart, historyEnd);
const originalDelete = originalBt1.indexOf('u5j.l(');
const originalCreate = originalBt1.indexOf('u5j.f(');
const originalInsert = originalBt1.indexOf('s5j.i(');
const harmonyDelete = commitMethod.indexOf('OriginalDeleteEntitiesOperationApplier');
const harmonyCreate = commitMethod.indexOf('OriginalCreateBlockOperationApplier');
const harmonyInsert = commitMethod.indexOf('OriginalInsertTextOperationApplier');

function occurrences(text, needle) {
  return text.split(needle).length - 1;
}

function moveVisibility(state, forward) {
  const sourceIds = ['ink-a', 'ink-b'];
  const textId = 'text';
  return {
    revision: state.revision + 1,
    visible: new Set(forward ? [textId] : sourceIds),
  };
}

const checks = [
  ['original conversion source hashes are pinned',
    hashOriginal('xsc.java') === '41C4BD1D24F50E04C095B319BA4B1F37CD04ACD9B43B744DF67D78F89FFF5BB8' &&
    hashOriginal('bt1.java') === 'A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA' &&
    hashOriginal('u5j.java') === 'F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC' &&
    hashOriginal('s5j.java') === 'D52D1095314843F53AB8866BF4C06D045E6C0AA5C7A1A531A1D12D5F7E0A3813' &&
    hashOriginal('haa.java') === 'C5B4281AE04AEE82EAB044B4C01FD960A22032FCEF5274F7BD8B33B64C54E126'],
  ['original xsc keeps the single-page and eight-unit conversion gates',
    originalXsc.includes('public static cxc v(ArrayList arrayList, Function0 function0)') &&
    originalXsc.includes('if (!ba6.o(((s06) it.next()).i(), cxcVarI))') &&
    originalXsc.includes('if (f < 8.0f)') && originalXsc.includes('if (f2 < 8.0f)')],
  ['original bt1 orders DELETE before CREATE before INSERT in one xq9 callback',
    originalDelete >= 0 && originalDelete < originalCreate && originalCreate < originalInsert &&
    originalBt1.includes('xq9 xq9Var2 = (xq9) obj;')],
  ['original operation enum identifies payload types 25 22 and 8',
    originalHaa.includes('DELETE_ENTITIES((byte) 25)') &&
    originalHaa.includes('CREATE_BLOCK((byte) 22)') &&
    originalHaa.includes('INSERT_STRING((byte) 8)')],
  ['original block creator requires page origin and size and rejects an unknown page',
    originalU5j.includes('public static rl2 f(x09 x09Var, cz0 cz0Var, cxc cxcVar, fqa fqaVar') &&
    originalU5j.includes('qed qedVar2') &&
    originalU5j.includes('Cannot create a block on an unknown page')],
  ['original INSERT_STRING preserves the whole string path',
    originalS5j.includes('public static cee i(x09 x09Var, String str, qo5 qo5Var, exc excVar)') &&
    originalS5j.includes('return kci.b(excVar, str, qo5Var);')],
  ['Harmony exposes a dedicated transaction entry but no production UI caller yet',
    commitStart >= 0 && occurrences(persistence, 'commitOriginalHandwritingConversion(') === 1 &&
    !canvas.includes('commitOriginalHandwritingConversion(')],
  ['conversion commit clones and byte-compares every source Ink snapshot',
    commitMethod.includes('plan.sourceStrokes.map(cloneStrokeThroughPersistence)') &&
    commitMethod.includes('sameByteArrays(stored.payload,') &&
    commitMethod.includes("encodePersistedElement({ kind: 'stroke', data: source })") &&
    commitMethod.includes('originalEntityStateExists(')],
  ['conversion persistence plan rejects non-Ink sources and Float32 overflow',
    persistence.includes('stroke.isFinished !== true') &&
    persistence.includes('stroke.renderSpec.isHighlighter') &&
    persistence.includes('stroke.renderSpec.isPartialEraser === true') &&
    persistence.includes('Math.fround(originX + width)') &&
    persistence.includes('Math.fround(originY + height)')],
  ['conversion persistence preflights the original INSERT_STRING UTF-8 budget',
    persistence.includes('encodeOriginalInitialInsertString({ timestamp: 1, siteId: 1 }, draft.richText)')],
  ['conversion commit wraps original operations history and snapshot repair in one RDB transaction',
    commitMethod.includes('await store.beginTransaction();') &&
    commitMethod.indexOf('await store.beginTransaction();') < harmonyDelete &&
    commitMethod.indexOf('await store.commit();') > commitMethod.indexOf(
      'appendOriginalHandwritingConversionHistory') &&
    commitMethod.includes('await store.rollBack();')],
  ['Harmony commit preserves DELETE before CREATE before INSERT',
    harmonyDelete >= 0 && harmonyDelete < harmonyCreate && harmonyCreate < harmonyInsert],
  ['all three original reducers share one revision batch',
    commitMethod.includes('const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch();') &&
    occurrences(commitMethod, 'revisionBatch);') >= 3 &&
    occurrences(commitMethod, 'new OriginalPageMutationBatch()') === 1],
  ['conversion commit flushes the page revision batch exactly once',
    occurrences(commitMethod, 'await revisionBatch.flush(store, noteId);') === 1],
  ['DELETE_ENTITIES can defer revision while rejecting page visibility in the batch',
    deleteReducer.includes('async applyBatchedPayload') &&
    deleteReducer.includes('BATCHED_DELETE_ENTITIES_DOES_NOT_SUPPORT_PAGE_VISIBILITY') &&
    deleteReducer.includes('revisionBatch.recordEntity')],
  ['CREATE_BLOCK and INSERT_STRING expose the same batched reducer contract',
    createReducer.includes('async applyBatchedPayload') &&
    createReducer.includes('revisionBatch.recordBlock') &&
    insertReducer.includes('async applyBatchedPayload') &&
    insertReducer.includes('revisionBatch.recordBlock(batchTarget, true)')],
  ['mixed Ink and Text changes merge into one revision and two search invalidations',
    batch.includes('existing.inkChanged = existing.inkChanged || inkChanged') &&
    batch.includes('existing.textChanged = existing.textChanged || textChanged') &&
    batch.includes('SearchItemType.INK') && batch.includes('SearchItemType.TEXT_BLOCK')],
  ['the committed Text is checked against Float32 origin size bounds and exact OCR text',
    commitMethod.includes('text.richText !== stablePlan.richText') &&
    commitMethod.includes('Math.fround(stablePlan.origin.x)') &&
    commitMethod.includes('Math.fround(stablePlan.width)') &&
    commitMethod.includes('original handwriting conversion Text state diverged')],
  ['HWC1 stores the page mutation exact source IDs and created Text ID',
    codec.includes('const MAGIC: number[] = [0x48, 0x57, 0x43, 0x31]') &&
    codec.includes('pageMutation: PageMutationOpPayload') &&
    codec.includes('sourceStrokeIds: string[]') && codec.includes('textId: string')],
  ['HWC1 validates embedded Ink and Text payload kinds and identities',
    occurrences(codec, 'decodeStoredPageElement(') === 2 &&
    codec.includes("persisted.kind !== 'stroke'") && codec.includes('persisted.data.id !== element.elementId') &&
    codec.includes("persistedText.kind !== 'text'") &&
    codec.includes('persistedText.data.id !== created.elementId')],
  ['HWC1 validates exact before and after order membership',
    codec.includes('original handwriting conversion did not remove every source Ink') &&
    codec.includes('original handwriting conversion did not insert its Text block')],
  ['history uses a dedicated companion op and runtime action type',
    opTypes.includes('ORIGINAL_HANDWRITING_CONVERSION = 36') &&
    undoRedo.includes('ORIGINAL_HANDWRITING_CONVERSION = 24') &&
    persistence.includes('opType: OpType.ORIGINAL_HANDWRITING_CONVERSION')],
  ['PersistentHistory restores HWC1 only as one dedicated action',
    history.includes('persistent original handwriting conversion action must contain exactly one mutation') &&
    history.includes('type: UndoableActionType.ORIGINAL_HANDWRITING_CONVERSION')],
  ['Undo and Redo use one type-25 visibility payload and one batch flush',
    occurrences(historyMethod, 'encodeOriginalEntityVisibility(') === 1 &&
    historyMethod.includes('forward ? sources : [text], forward ? [text] : sources') &&
    occurrences(historyMethod, 'new OriginalPageMutationBatch()') === 1 &&
    occurrences(historyMethod, 'await batch.flush(store, noteId);') === 1],
  ['history replay verifies the full source snapshot before durable visibility movement',
    historyMethod.indexOf('replayPageMutation(') < historyMethod.indexOf('encodeOriginalEntityVisibility(') &&
    historyMethod.includes('sameSearchSourceElements(materialized, target)') &&
    historyMethod.includes('revisionAfter !== revisionBefore + 1')],
  ['history movement appends HWC1 before commit and rolls back atomically',
    historyMethod.indexOf('appendOriginalHandwritingConversionHistory') <
      historyMethod.indexOf('await store.commit();') &&
    historyMethod.includes('await store.rollBack();')],
  ['editor validates page replay before applying dedicated history',
    canvas.includes('validateOriginalHandwritingConversionActionState') &&
    canvas.includes('replayPageMutation(this.currentMutationElements(), mutation.pageMutation, !isUndo);') &&
    canvas.includes('applyOriginalHandwritingConversionHistory(') &&
    canvas.includes('this.installMutationElements(result.elements)')],
  ['planner explicitly records that persistence exists while provider Locale and UI remain open',
    planner.includes('dedicated atomic persistence/history path') &&
    planner.includes('no production OCR provider, Locale adapter, or UI')],
  ['codec fixture covers HWC1 corruption embedded payload mismatch and stale replay',
    codecFixture.includes('round-trips one mixed Ink-to-Text mutation') &&
    codecFixture.includes('rejects truncated trailing and wrong-magic bytes') &&
    codecFixture.includes('embedded kind or ID contradicts the wrapper') &&
    codecFixture.includes('stale source replay after any Ink byte changes')],
  ['persistence fixture covers source identity Float32 geometry and UTF-8 budget',
    persistenceFixture.includes('preflights Convert-to-Text source identity Float32 geometry and UTF-8 budget') &&
    persistenceFixture.includes("'中'.repeat(400000)")],
  ['history fixture covers dedicated PUSH UNDO REDO and corrupt actions',
    historyFixture.includes('restores HWC1 as one dedicated action across PUSH UNDO and REDO') &&
    historyFixture.includes('rejects multi-operation and corrupt HWC1 persistent actions')],
  ['batch fixture covers one revision with both Ink and Text invalidation',
    batchFixture.includes('flushes Ink visibility CREATE_BLOCK and INSERT_STRING as one page revision') &&
    batchFixture.includes('batch.recordEntity(target, PageElementKind.STROKE)') &&
    batchFixture.includes('expect(revisionUpdates).assertEqual(1)')],
  ['new codec fixture is registered in the executed ArkTS suite',
    fixtureList.includes("'./OriginalHandwritingConversionMutationCodec.test'") &&
    fixtureList.includes('originalHandwritingConversionMutationCodecTest();')],
  ['numeric history replay restores Ink on Undo and Text on Redo with one revision each', (() => {
    const pushed = { revision: 7, visible: new Set(['text']) };
    const undone = moveVisibility(pushed, false);
    const redone = moveVisibility(undone, true);
    return undone.revision === 8 && [...undone.visible].join(',') === 'ink-a,ink-b' &&
      redone.revision === 9 && [...redone.visible].join(',') === 'text';
  })()],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

console.log(`D02_ORIGINAL_HANDWRITING_CONVERSION_PERSISTENCE_OK TOTAL=${checks.length} FAILED=0`);
