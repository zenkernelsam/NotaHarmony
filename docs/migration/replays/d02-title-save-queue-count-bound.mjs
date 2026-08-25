import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /private titleSaveInFlightCount: number = 0;/);
assert.doesNotMatch(page, /titleSaveInFlight(?![A-Za-z])/);

const saveStart = page.indexOf('  private saveTitle(): Promise<void> {');
const commitStart = page.indexOf('  private async commitTitle(', saveStart);
const saveBody = page.slice(saveStart, commitStart);
assert.equal((saveBody.match(/this\.titleSaveInFlightCount\+\+/g) ?? []).length, 1);
assert.equal((saveBody.match(/this\.titleSaveInFlightCount--/g) ?? []).length, 1);
const increment = saveBody.indexOf('this.titleSaveInFlightCount++;');
const decrement = saveBody.indexOf('void queued.finally((): void => {', increment);
assert.ok(increment >= 0 && decrement > increment);
assert.match(saveBody.slice(decrement),
  /this\.titleSaveInFlightCount--;\s+\}\);/,
  'each queued save owns exactly one finally decrement');

for (const callbackName of [
  'onApplyNoteTitleHistory:',
  'onApplyNoteMetadataHistory:',
]) {
  const start = page.indexOf(callbackName);
  const end = page.indexOf('\n          on', start + 1);
  const body = page.slice(start, end);
  assert.match(body,
    /if \(this\.pageOperationBusy \|\| this\.titleSaveInFlightCount > 0\) \{\s+return Promise\.resolve\(false\);\s+\}/,
    `${callbackName} remains fail closed until every queued title save settles`);
}

const branchStart = canvas.indexOf('if (this.isPageAction(action.type)) {');
const groupStart = canvas.indexOf('if (action.type === UndoableActionType.GROUP_ELEMENTS) {', branchStart);
const branch = canvas.slice(branchStart, groupStart);
assert.ok(branch.includes('this.onApplyNoteTitleHistory(action, isUndo, history)'));
assert.ok(branch.includes('this.onApplyNoteMetadataHistory(action, isUndo, history)'));

console.log('D02_TITLE_SAVE_QUEUE_COUNT_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
