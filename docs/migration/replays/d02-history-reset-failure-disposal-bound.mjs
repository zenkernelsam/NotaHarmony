import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  private async resetPersistentHistory(): Promise<void> {');
const end = canvas.indexOf('  private showHistoryRecoveryToast(message: ResourceStr): void {', start);
assert.ok(start !== -1 && end > start, 'resetPersistentHistory section exists');
const body = canvas.slice(start, end);

assert.match(body,
  /await new OpStoreImpl\(this\.database\)\.resetPersistentHistory\(this\.noteId\);\s+if \(!this\.lifecycleActive\) \{\s+hilog\.info\(0x0001, 'NoteCanvasView',\s+'persistent history reset completed after editor disposed; durable reset retained'\);\s+return;\s+\}/,
  'successful disposal continuation remains guarded');

const logIndex = body.indexOf("hilog.error(0x0001, 'NoteCanvasView',", body.indexOf('catch (e)'));
const guardIndex = body.indexOf('if (!this.lifecycleActive) {', logIndex);
const toastIndex = body.indexOf('this.showHistoryRecoveryToast(', guardIndex);
const finallyIndex = body.indexOf('    } finally {');
assert.ok(logIndex >= 0 && guardIndex > logIndex && toastIndex > guardIndex && finallyIndex > toastIndex,
  'failure logs first, guards disposal, and finally cleanup remains');

assert.doesNotMatch(body.slice(logIndex, guardIndex), /showHistoryRecoveryToast|return;/,
  'guard immediately follows failure logging');

console.log('D02_HISTORY_RESET_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
