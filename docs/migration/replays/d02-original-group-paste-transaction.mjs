import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixtures = read('note/src/test/StrokePersistence.test.ets');
const lg2 = original('sources/defpackage/lg2.java');
const u5j = original('sources/defpackage/u5j.java');

assert.match(lg2, /u5j\.c\(x09Var,/);
assert.match(lg2, /\(\(uq9\) next\)\.m\(\) == haa\.CREATE_GROUP/);
assert.match(u5j, /return b\.b\(\(a79\) x09Var, arrayList, aVar\)/);
assert.match(persistence, /async commitOriginalClipboardPaste\(/);
assert.match(persistence, /validateOriginalClipboardPastePlan\(plan\);[\s\S]*?cloneOriginalClipboardPastePlan\(plan\)[\s\S]*?await this\.flush/);
assert.match(persistence, /await store\.beginTransaction\(\)[\s\S]*?for \(const ref of stablePlan\.elementOrder\)/);
assert.match(persistence, /applyBatchedPayload\([\s\S]*?ORIGINAL_CREATE_INK/);
assert.match(persistence, /applyCreateShapeBatchedPayload\([\s\S]*?ORIGINAL_CREATE_SHAPE/);
assert.match(persistence, /ORIGINAL_CREATE_BLOCK[\s\S]*?ORIGINAL_INSERT_TEXT/);
assert.match(persistence, /await revisionBatch\.flush\(store, noteId\);[\s\S]*?for \(const sourceGroup of stablePlan\.groups\)/);
assert.match(persistence, /validateOriginalClipboardPasteMutation\(mutation\)/);
assert.match(persistence, /opType: OpType\.ORIGINAL_CLIPBOARD_PASTE/);
assert.match(persistence, /await store\.commit\(\)/);
assert.match(persistence, /await store\.rollBack\(\)/);
assert.match(persistence, /encodeOriginalLocalCreateImageBlock\(page, image\)/);
assert.match(persistence, /Shape RichText is unsupported/);
assert.match(persistence, /empty Text is unsupported/);
assert.match(fixtures, /validates bottom-up original clipboard Paste plans before persistence/);

function transact(failAt = '') {
  const initial = { revision: 7, operations: [], groups: [], history: [] };
  const state = structuredClone(initial);
  try {
    for (const op of ['CREATE_INK', 'CREATE_BLOCK', 'INSERT_STRING', 'CREATE_SHAPE',
      'CREATE_IMAGE_BLOCK', 'CREATE_MATH_BLOCK']) {
      if (failAt === op) throw new Error(op);
      state.operations.push(op);
    }
    if (failAt === 'FLUSH') throw new Error('FLUSH');
    state.revision++;
    for (const group of ['nested', 'top']) {
      if (failAt === group) throw new Error(group);
      state.groups.push(group);
      state.operations.push('CREATE_GROUP');
    }
    if (failAt === 'NCP1') throw new Error('NCP1');
    state.history.push('NCP1');
    return state;
  } catch {
    return initial;
  }
}

const committed = transact();
assert.equal(committed.revision, 8);
assert.deepEqual(committed.operations, [
  'CREATE_INK', 'CREATE_BLOCK', 'INSERT_STRING', 'CREATE_SHAPE',
  'CREATE_IMAGE_BLOCK', 'CREATE_MATH_BLOCK',
  'CREATE_GROUP', 'CREATE_GROUP',
]);
assert.deepEqual(committed.groups, ['nested', 'top']);
assert.deepEqual(committed.history, ['NCP1']);
for (const stage of ['CREATE_INK', 'INSERT_STRING', 'FLUSH', 'top', 'NCP1']) {
  assert.deepEqual(transact(stage), { revision: 7, operations: [], groups: [], history: [] });
}

console.log('originalGroupPasteTransaction=' +
  'stable-plan-in-transaction-identities-mixed-leaf-create-single-revision-bottom-up-groups-ncp1-rollback');
