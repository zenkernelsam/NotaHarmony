import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  private resumePendingHistory(): void {');
const end = canvas.indexOf('  private isPageAction(', start);
assert.ok(start !== -1 && end > start);
const body = canvas.slice(start, end);

const pendingCheck = body.indexOf('if (this.pendingHistoryDirection === 0) {');
const lifecycleGate = body.indexOf(
  'if (!this.lifecycleActive || !this.loaded || this.dataLoading || this.dataLoadFailed ||',
  pendingCheck,
);
const identityGate = body.indexOf('if (this.loadedPageId.length === 0 ||', lifecycleGate);
const directionRead = body.indexOf('const isUndo: boolean = this.pendingHistoryDirection < 0;', identityGate);
assert.ok(pendingCheck >= 0 && lifecycleGate > pendingCheck && identityGate > lifecycleGate &&
  directionRead > identityGate,
  'pending history resumes only after lifecycle, health, busy, and page identity authorization');

assert.match(body.slice(lifecycleGate, identityGate),
  /this\.pendingHistoryDirection = 0;\s+return;/,
  'invalid lifecycle consumes the stale pending direction');
assert.match(body.slice(identityGate, directionRead),
  /this\.loadedPageId !== this\.currentPage\.pageId\) \{\s+return;\s+\}/,
  'page mismatch retains the pending move for a matching reload');

console.log('D02_PENDING_HISTORY_RESUME_CONTEXT_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
