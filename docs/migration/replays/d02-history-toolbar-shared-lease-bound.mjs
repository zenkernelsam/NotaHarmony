import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

for (const [label, propertyName] of [
  ['undo', 'onUndo'],
  ['redo', 'onRedo'],
]) {
  const start = page.indexOf(`          ${propertyName}: () => {`);
  const end = page.indexOf('\n          },\n', start);
  assert.ok(start >= 0 && end > start, `${label} callback`);
  const body = page.slice(start, end);
  const guardStart = body.indexOf('if (');
  const guardEnd = body.indexOf('{', guardStart);
  assert.ok(guardStart >= 0 && guardEnd > guardStart, `${label} guard`);
  const guard = body.slice(guardStart, guardEnd);
  assert.ok(
    guard.includes('!this.photoImportLeaseActive') &&
      guard.includes('!this.pageOperationBusy') &&
      guard.includes('!this.historyPending'),
    `${label} checks shared photo ingress lease`,
  );
}

const historyStart = canvas.indexOf('  private performHistory(isUndo: boolean): void {');
assert.ok(historyStart >= 0);
const historyEnd = canvas.indexOf('\n  private commitHistory(', historyStart);
assert.ok(historyEnd > historyStart);
const historyBody = canvas.slice(historyStart, historyEnd);

const guardStart = historyBody.indexOf('if (this.');
const guardEnd = historyBody.indexOf('{\n      return;', guardStart);
assert.ok(guardStart >= 0 && guardEnd > guardStart);
const guard = historyBody.slice(guardStart, guardEnd);
assert.match(guard, /this\.photoImportBusy \|\| this\.historyBusy/);
assert.ok(
  guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'),
  'shared photo ingress lease is rejected before the internal history guard',
);
for (const effect of [
  'this.pendingHistoryDirection',
  'this.undoRedo.peekUndoGroup()',
  'this.undoRedo.peekRedoGroup()',
]) {
  assert.ok(historyBody.includes(effect), `history path reaches ${effect}`);
}

console.log('D02_HISTORY_TOOLBAR_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
