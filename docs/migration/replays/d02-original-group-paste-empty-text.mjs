import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const baj = original('baj.java');
const rl2 = original('rl2.java');
const createReducer = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const insertEncoder = read('note/src/main/ets/data/OriginalInsertTextPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixtures = read('note/src/test/StrokePersistence.test.ets');

assert.match(baj, /aVar\.C\(21\)/);
assert.match(rl2, /if \(B\(\) == cz0\.TEXT \|\| u\(\) == null\)/);
assert.match(createReducer, /richText: ''/);
assert.match(insertEncoder, /encoded\.length === 0/);
assert.match(insertEncoder, /original INSERT_STRING value is invalid/);

assert.doesNotMatch(persistence, /empty Text is unsupported/);
assert.match(persistence, /if \(text\.richText\.length > 0\)/);
assert.match(persistence, /const canonicalText: TextBlockElement = await this\.readOriginalClipboardText\(/);
assert.match(persistence, /createdTexts\.push\(canonicalText\)/);
assert.match(persistence, /private async readOriginalClipboardText\(/);
assert.doesNotMatch(persistence, /function materializeOriginalTextCreate/);
assert.match(fixtures, /originalText\('op:73:2', ''\)/);

function pasteText(value, failAt = '') {
  const initial = { revision: 8, operations: [], text: [], groups: [], history: [] };
  const state = structuredClone(initial);
  try {
    state.operations.push('CREATE_BLOCK');
    state.text.push(value);
    if (failAt === 'CREATE_BLOCK') throw new Error(failAt);
    if (value.length > 0) {
      state.operations.push('INSERT_STRING');
      if (failAt === 'INSERT_STRING') throw new Error(failAt);
    }
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

const empty = pasteText('');
assert.deepEqual(empty.operations, ['CREATE_BLOCK', 'CREATE_GROUP']);
assert.deepEqual(empty.text, ['']);
assert.equal(empty.revision, 9);
assert.deepEqual(pasteText('text').operations,
  ['CREATE_BLOCK', 'INSERT_STRING', 'CREATE_GROUP']);
for (const stage of ['CREATE_BLOCK', 'CREATE_GROUP', 'NCP1']) {
  assert.deepEqual(pasteText('', stage),
    { revision: 8, operations: [], text: [], groups: [], history: [] });
}

console.log('originalGroupPasteEmptyText=' +
  'create-block-without-empty-insert-single-revision-canonical-group-ncp1-rollback');
