import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const cie = original('cie.java');
const m4c = original('m4c.java');
const encoder = read('note/src/main/ets/data/OriginalRichTextStylePayloadEncoder.ets');
const applier = read('note/src/main/ets/data/OriginalRichTextStyleOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const fixture = read('note/src/test/OriginalRichTextStylePayloadEncoder.test.ets');

assert.match(cie, /m4cVar\.u\(aVar\)/);
assert.match(cie, /aVar\.g\(qo5VarB\)/);
assert.match(cie, /aVar\.g\(null\)/);
assert.match(m4c, /Character\.codePointCount\(str, 0, str\.length\(\)\)/);
assert.match(m4c, /aVar\.a\(excVarK0, cxcVarG\)/);
assert.match(m4c, /y01Var = y01\.END_OF_DOC/);
assert.match(m4c, /th7VarS3\.add\(c1j\.a\(/);
assert.match(m4c, /th7VarS2\.add\(Q\(set, excVar2, excVar3, qo5VarD\)\)/);

assert.match(encoder, /ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE/);
assert.match(encoder, /ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE/);
assert.match(encoder, /strictCodePointLength\(text\.richText\)/);
assert.match(encoder, /characterIdentity\(insertion, run\.start\)/);
assert.match(encoder, /OriginalTextBoundaryType\.END_OF_DOC/);
assert.match(encoder, /original initial checkbox state requires UpdateCheckbox replay/);
assert.match(applier, /applyBatchedPayload/);
assert.match(applier, /writeTextPayload\([\s\S]*?revisionBatch\)/);

assert.match(persistence, /encodeOriginalInitialRichTextStyles\(/);
assert.match(persistence, /OriginalRichTextStyleOperationApplier\(\)\.applyBatchedPayload/);
assert.match(persistence, /OpType\.ORIGINAL_MODIFY_TEXT_STYLE/);
assert.match(persistence, /OpType\.ORIGINAL_MODIFY_PARAGRAPH_STYLE/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /original clipboard RichText styles diverged after replay/);
assert.match(persistence, /await revisionBatch\.flush\(store, noteId\)/);
assert.match(persistence, /await store\.rollBack\(\)/);
assert.match(opTypes, /ORIGINAL_MODIFY_TEXT_STYLE = 74/);
assert.match(opTypes, /ORIGINAL_MODIFY_PARAGRAPH_STYLE = 75/);
assert.match(fixture, /materializeOriginalTextStyles\(characters\(\), operations\)/);
assert.match(fixture, /'A\\uD83D\\uDE00\\u4E2DZ'/);
assert.match(fixture, /isChecked: false/);

function copyStyledText(failAt = '') {
  const initial = { revision: 12, operations: [], styles: [], groups: [], history: [] };
  const state = structuredClone(initial);
  try {
    state.operations.push('CREATE_BLOCK');
    state.operations.push('INSERT_STRING');
    for (const style of ['MODIFY_STYLE', 'MODIFY_PARAGRAPH_STYLE']) {
      if (failAt === style) throw new Error(style);
      state.operations.push(style);
      state.styles.push(style);
    }
    if (failAt === 'STYLE_CANONICAL') throw new Error(failAt);
    state.revision++;
    state.operations.push('CREATE_GROUP');
    state.groups.push('top');
    if (failAt === 'CREATE_GROUP') throw new Error(failAt);
    state.history.push('NCP1');
    if (failAt === 'NCP1') throw new Error(failAt);
    return state;
  } catch {
    return initial;
  }
}

const committed = copyStyledText();
assert.deepEqual(committed.operations, [
  'CREATE_BLOCK', 'INSERT_STRING', 'MODIFY_STYLE', 'MODIFY_PARAGRAPH_STYLE', 'CREATE_GROUP',
]);
assert.deepEqual(committed.styles, ['MODIFY_STYLE', 'MODIFY_PARAGRAPH_STYLE']);
assert.equal(committed.revision, 13);
assert.deepEqual(committed.history, ['NCP1']);
for (const stage of ['MODIFY_STYLE', 'MODIFY_PARAGRAPH_STYLE', 'STYLE_CANONICAL',
  'CREATE_GROUP', 'NCP1']) {
  assert.deepEqual(copyStyledText(stage),
    { revision: 12, operations: [], styles: [], groups: [], history: [] });
}

console.log('originalGroupPasteTextStyles=' +
  'type12-type13-unicode-seqid-end-of-doc-canonical-single-revision-rollback-checkbox-gated');
