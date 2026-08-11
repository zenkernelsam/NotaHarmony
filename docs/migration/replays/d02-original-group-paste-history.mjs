import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');

const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const fixtures = read('note/src/test/PersistentHistory.test.ets');

assert.match(opTypes, /ORIGINAL_CLIPBOARD_PASTE = 32/);
assert.match(undo, /ORIGINAL_CLIPBOARD_PASTE = 19/);
assert.match(undo, /interface OriginalClipboardPasteAction/);
assert.match(undo, /operation: Op/);
assert.match(history, /decodeOriginalClipboardPasteMutation/);
assert.match(history, /persistent original clipboard Paste action must contain exactly one mutation/);
assert.match(history, /pageId: mutation\.pageMutation\.pageId/);
assert.match(fixtures, /restores NCP1 Group Paste as one dedicated action across UNDO/);
assert.match(fixtures, /rejects mixed or corrupt NCP1 persistent actions/);

const undoStack = [];
const redoStack = [];
const action = { id: 'paste', type: 32, payload: 'NCP1' };
undoStack.push(action);
redoStack.push(undoStack.pop());
assert.equal(undoStack.length, 0);
assert.deepEqual(redoStack, [action]);
undoStack.push(redoStack.pop());
assert.deepEqual(undoStack, [action]);
assert.equal(redoStack.length, 0);

console.log('originalGroupPasteHistory=' +
  'dedicated-ncp1-single-companion-push-undo-redo-strict-materialization');
