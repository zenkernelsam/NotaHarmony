import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const editor = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const reducer = read('note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const opTypes = original('sources/defpackage/haa.java');
const originalPaste = original('sources/defpackage/lg2.java');

assert.match(opTypes, /DELETE_ENTITIES\(\(byte\) 25\)/);
assert.match(originalPaste, /fsi\.d\(/);
assert.match(persistence, /async applyOriginalClipboardPasteHistory\(/);
assert.match(persistence, /replayPageMutation\(\s*current, mutation\.pageMutation, forward\)/);
assert.match(persistence, /encodeOriginalEntityVisibility\(\s*forward \? \[\] : targets, forward \? targets : \[\]\)/);
assert.match(persistence, /targets\.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT/);
assert.match(persistence, /leafCount \+ plan\.groups\.length > MAX_ORIGINAL_DELETE_ENTITY_COUNT/);
assert.match(persistence, /revisionAfter !== revisionBefore \+ 1/);
assert.match(persistence, /appendOriginalClipboardPasteHistory\(/);
assert.match(reducer, /const affectedPages: Map<string, StoredEntityTarget>/);
assert.match(reducer, /groupVisibilityMayChange/);
assert.match(history, /type: UndoableActionType\.ORIGINAL_CLIPBOARD_PASTE/);
assert.match(editor, /action\.type === UndoableActionType\.ORIGINAL_CLIPBOARD_PASTE/);
assert.match(editor, /validateOriginalClipboardPasteActionState\(action, isUndo\)/);
assert.match(editor, /applyOriginalClipboardPasteHistory\(\s*this\.noteId, mutation, !isUndo, history\)/);
assert.match(editor, /this\.installMutationElements\(result\.elements\)/);

const mutation = {
  beforeOrder: ['old'],
  afterOrder: ['old', 'leaf-a', 'leaf-b'],
  inserted: ['leaf-a', 'leaf-b'],
  groups: ['nested', 'top'],
};

function move(state, forward, failAt = '') {
  const sourceOrder = forward ? mutation.beforeOrder : mutation.afterOrder;
  assert.deepEqual(state.order, sourceOrder);
  const initial = structuredClone(state);
  try {
    const targets = [...mutation.inserted, ...mutation.groups];
    if (failAt === 'TYPE25') throw new Error('TYPE25');
    state.order = forward ? [...mutation.afterOrder] : [...mutation.beforeOrder];
    state.visible = new Set(forward ? targets : []);
    state.revision++;
    if (failAt === 'VERIFY') throw new Error('VERIFY');
    state.history.push(forward ? 'REDO:NCP1' : 'UNDO:NCP1');
    return state;
  } catch {
    return initial;
  }
}

const afterPaste = {
  order: [...mutation.afterOrder],
  visible: new Set([...mutation.inserted, ...mutation.groups]),
  revision: 8,
  history: ['PUSH:NCP1'],
};
const undone = move(structuredClone(afterPaste), false);
assert.deepEqual(undone.order, ['old']);
assert.equal(undone.visible.size, 0);
assert.equal(undone.revision, 9);
const redone = move(undone, true);
assert.deepEqual(redone.order, ['old', 'leaf-a', 'leaf-b']);
assert.deepEqual([...redone.visible], ['leaf-a', 'leaf-b', 'nested', 'top']);
assert.equal(redone.revision, 10);
assert.deepEqual(move(structuredClone(afterPaste), false, 'VERIFY'), afterPaste);

console.log('originalGroupPasteUndoRedo=' +
  'single-type25-leaves-groups-page-replay-one-revision-ncp1-history-durable-before-ui');
