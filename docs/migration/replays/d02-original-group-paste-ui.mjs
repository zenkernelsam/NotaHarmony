import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const clipboard = read('note/src/main/ets/rendering/StrokeClipboard.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixtures = read('note/src/test/StrokeClipboard.test.ets');
const originalPaste = original('sources/defpackage/lg2.java');

assert.match(originalPaste, /u5j\.c\(x09Var,/);
assert.match(originalPaste, /\(\(uq9\) next\)\.m\(\) == haa\.CREATE_GROUP/);
assert.match(originalPaste, /ys2\.H\(au1\.X1\(arrayList8\), linkedHashSet\)/);

assert.match(clipboard, /private groupSnapshots: OriginalSelectionGroup\[\]/);
assert.match(clipboard, /copyOriginalGroupGraph\(\s*sourceGroups, topGroupIds, ids\)/);
assert.match(clipboard, /ordered\.push\(cloneSelectionGroup\(group\)\)/);
assert.match(clipboard, /prepareOriginalGroupPaste\(/);
assert.match(clipboard, /materializeAllOriginal \|\| originalCreateKind === PageElementKind\.STROKE/);
assert.match(clipboard, /materializeAllOriginal \|\| originalCreateKind === PageElementKind\.SHAPE/);
assert.match(clipboard, /pasteSequence !== this\.pasteCount \+ 1/);
assert.match(clipboard, /this\.pasteCount = pasteSequence/);

assert.match(canvas, /this\.strokeClipboard\.hasOriginalGroupGraph\(\)/);
assert.match(canvas, /validateOriginalClipboardPastePlan\(plan\)/);
assert.match(canvas, /this\.persistence\.commitOriginalClipboardPaste\(\s*this\.noteId, pageId, plan, prepared\)/);
assert.match(canvas, /commitPreparedPaste\(paste\.pasteSequence\)/);
assert.match(canvas, /type: UndoableActionType\.ORIGINAL_CLIPBOARD_PASTE/);
assert.match(canvas, /operation: result\.operation/);
assert.match(canvas, /this\.elementOrder = clonePageElementOrder\(result\.elementOrder\)/);
assert.match(canvas, /this\.selectionGroups = result\.groups/);
assert.match(canvas, /result\.images\.map\(\(image: ImageElement\)/);
assert.match(canvas, /this\.refreshImageAssets\(this\.pageLoadGeneration, pageId\)/);
assert.match(canvas, /result\.topGroupIds,\s*result\.mathBlocks\.map\(\(math: MathElement\)/);
assert.match(persistence, /groups: activeGroups\.map\(cloneSelectionGroup\)/);
assert.match(fixtures, /commits Paste offsets only after durability/);
assert.match(fixtures, /rejects incomplete or multi-parent original Group snapshots/);

function paste(state, failAt = '') {
  const preview = { sequence: state.pasteCount + 1, offset: 20 * (state.pasteCount + 1) };
  const initial = structuredClone(state);
  try {
    if (failAt === 'TRANSACTION') throw new Error('TRANSACTION');
    state.database = ['leaf-a', 'leaf-b', 'nested', 'top'];
    state.history = ['NCP1'];
    if (failAt === 'AFTER_COMMIT') throw new Error('AFTER_COMMIT');
    state.pasteCount = preview.sequence;
    state.canvas = ['leaf-a', 'leaf-b'];
    state.groups = ['nested', 'top'];
    state.selection = ['top'];
    return state;
  } catch {
    return failAt === 'TRANSACTION' ? initial : state;
  }
}

const empty = { pasteCount: 0, database: [], history: [], canvas: [], groups: [], selection: [] };
assert.deepEqual(paste(structuredClone(empty), 'TRANSACTION'), empty);
const committed = paste(structuredClone(empty));
assert.equal(committed.pasteCount, 1);
assert.deepEqual(committed.database, ['leaf-a', 'leaf-b', 'nested', 'top']);
assert.deepEqual(committed.canvas, ['leaf-a', 'leaf-b']);
assert.deepEqual(committed.groups, ['nested', 'top']);
assert.deepEqual(committed.selection, ['top']);

console.log('originalGroupPasteUi=' +
  'deep-group-graph-preview-no-consume-durable-transaction-complete-state-top-selection-history');
