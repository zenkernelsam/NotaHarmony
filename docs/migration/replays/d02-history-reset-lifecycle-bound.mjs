import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

const start = canvas.indexOf('private async resetPersistentHistory(): Promise<void> {');
assert.notEqual(start, -1);
const end = canvas.indexOf('\n  private showHistoryRecoveryToast', start);
assert.notEqual(end, -1);
const body = canvas.slice(start, end);

assert.match(body, /await new OpStoreImpl\(this\.database\)\.resetPersistentHistory\(this\.noteId\);\s+if \(!this\.lifecycleActive\) \{\s+hilog\.info\(0x0001, 'NoteCanvasView',\s+'persistent history reset completed after editor disposed; durable reset retained'\);\s+return;\s+\}\s+this\.undoRedo\.clear\(\);/);

const successIndex = body.indexOf('this.undoRedo.clear();');
assert.ok(successIndex > body.indexOf('resetPersistentHistory(this.noteId)'));
assert.ok(successIndex < body.indexOf('historyRecoveryRequired = false'));
assert.ok(body.indexOf('showHistoryRecoveryToast') > successIndex);
assert.ok(body.includes('finally') && body.includes('this.historyBusy = false;') &&
  body.includes('this.historyRecoveryBusy = false;'));

console.log('D02_HISTORY_RESET_LIFECYCLE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
