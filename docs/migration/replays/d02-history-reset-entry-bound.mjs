import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const dialogStart = source.indexOf('private promptPersistentHistoryRecovery(): void {');
const requestStart = source.indexOf('private requestPersistentHistoryReset(): Promise<void> {');
const resetStart = source.indexOf('private async resetPersistentHistory(): Promise<void> {');
assert.ok(dialogStart !== -1 && requestStart > dialogStart && resetStart > requestStart,
  'recovery entry helpers are ordered');

const callback = source.slice(dialogStart, requestStart);
assert.ok(callback.includes('this.requestPersistentHistoryReset()'));
assert.ok(!callback.includes('this.resetPersistentHistory()'),
  'dialog action cannot bypass the entry gate');

const request = source.slice(requestStart, resetStart);
for (const condition of [
  '!this.lifecycleActive',
  '!this.historyRecoveryRequired',
  'this.historyRecoveryBusy',
  'this.historyBusy',
  'this.database === null',
]) {
  const conditionIndex = request.indexOf(condition);
  const resetIndex = request.indexOf('return this.resetPersistentHistory();');
  assert.ok(conditionIndex !== -1 && conditionIndex < resetIndex, condition);
}
assert.match(request,
  /if \(!this\.lifecycleActive \|\| !this\.historyRecoveryRequired \|\|\s+this\.historyRecoveryBusy \|\| this\.photoImportBusy \|\| this\.historyBusy \|\|\s+this\.database === null\) \{\s+return Promise\.resolve\(\);\s+\}\s+return this\.resetPersistentHistory\(\);/);

console.log('D02_HISTORY_RESET_ENTRY_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
