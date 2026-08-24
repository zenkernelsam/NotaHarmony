import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function section(startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  assert.ok(start !== -1, startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(end !== -1, endMarker);
  return source.slice(start, end);
}

const edit = section('private async confirmMathEditing(): Promise<void> {',
  'private canStartOriginalPhotoInsert(): boolean {');
const insert = section('private async confirmMathInsert(): Promise<void> {',
  'private groupSelectedElements(): void {');

function assertBound(body) {
  const staleGuard = body.lastIndexOf("if (!this.isHistoryPageContextCurrent(generation, pageId)) {");
  const push = body.lastIndexOf('this.undoRedo.push(mathAction, prepared);');
  const notify = body.lastIndexOf('this.notifyUndoRedo();');
  assert.ok(staleGuard !== -1 && push > staleGuard, 'history push follows current-page gate');
  assert.ok(notify > push, 'global undo notification follows history push');
  const activeBranch = body.slice(push, notify);
  assert.ok(activeBranch.includes('if (this.isHistoryPageContextCurrent(generation, pageId)) {'));
  assert.equal(activeBranch.indexOf('this.notifyUndoRedo();'),
    activeBranch.lastIndexOf('this.notifyUndoRedo();'));
}

assertBound(edit);
assertBound(insert);

for (const body of [edit, insert]) {
  assert.match(body,
    /if \(!this\.isHistoryPageContextCurrent\(generation, pageId\)\) \{\s+hilog\.error\(0x0001, 'NoteCanvasView',\s+'original Math [^']+ committed after stale page; durable history remains available'\);\s+(?:return;\s+\}|return \{ insertedCount)/);
}

console.log('D02_MATH_COMMIT_PUBLICATION_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
