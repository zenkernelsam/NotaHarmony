import assert from 'node:assert/strict';
import fs from 'node:fs';

const view = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function body(startMarker, endMarker) {
  const start = view.indexOf(startMarker);
  assert.ok(start !== -1, startMarker);
  const end = view.indexOf(endMarker, start);
  assert.ok(end !== -1, endMarker);
  return view.slice(start, end);
}

const edit = body('private async confirmMathEditing(): Promise<void> {',
  'private canStartOriginalPhotoInsert(): boolean {');
const insert = body('private async confirmMathInsert(): Promise<void> {',
  'private groupSelectedElements(): void {');

for (const [name, section] of [['edit', edit], ['insert', insert]]) {
  assert.match(section,
    /if \(!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'original Math [^']+ committed after stale page; durable history remains available'\);\s+return;\s+\}/);
}

const editGuardIndex = edit.indexOf("original Math latex committed after stale page");
const editPushIndex = edit.indexOf('this.undoRedo.push(action, prepared);');
const editVisibleIndex = edit.indexOf('this.mathEditorVisible = false;');
const editNotifyIndex = edit.lastIndexOf('this.notifyUndoRedo();');
assert.ok(editGuardIndex !== -1 && editGuardIndex < editPushIndex);
assert.ok(editPushIndex < editVisibleIndex && editVisibleIndex < editNotifyIndex);

const insertGuardIndex = insert.indexOf('original Math insert committed after stale page');
const insertPushIndex = insert.indexOf('const action: UndoableAction = {');
assert.ok(insertGuardIndex !== -1 && insertGuardIndex < insertPushIndex);
assert.ok(insert.includes('this.undoRedo.push(action, prepared);'));
assert.ok(insert.lastIndexOf('this.notifyUndoRedo();') > insertPushIndex);

for (const section of [edit, insert]) {
  const finallyIndex = section.lastIndexOf('.finally');
  assert.equal(finallyIndex, -1);
  assert.match(section,
    /\} finally \{\s+this\.mathEditorBusy = false;\s+this\.historyBusy = false;\s+\}/);
}

console.log('D02_ORIGINAL_MATH_COMMIT_STALE_BOUND_REPLAY_OK TOTAL=8 FAILED=0');