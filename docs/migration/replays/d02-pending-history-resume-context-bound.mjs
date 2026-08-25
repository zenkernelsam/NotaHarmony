import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const switchStart = canvas.indexOf('  private async switchPageData(): Promise<void> {');
const resumeStart = canvas.indexOf('  private resumePendingHistory(): void {');
assert.ok(switchStart >= 0 && resumeStart > switchStart);
const switchBody = canvas.slice(switchStart, resumeStart);

const failureBranch = switchBody.indexOf('if (previousPageSaved) {');
const recoveryRequest = switchBody.indexOf('this.onRequestPage(fromPageId);', failureBranch);
const recoveryLeaseRelease = switchBody.lastIndexOf(
  'this.onPageHistorySettled(false);',
  recoveryRequest,
);
const recoveryDirectionDrop = switchBody.lastIndexOf(
  'this.pendingHistoryDirection = 0;',
  recoveryLeaseRelease,
);
const recoveryGate = switchBody.lastIndexOf(
  'if (fromPageId !== this.currentPage.pageId) {',
  recoveryDirectionDrop,
);
assert.ok(failureBranch >= 0 && recoveryGate > failureBranch &&
    recoveryDirectionDrop > recoveryGate && recoveryLeaseRelease > recoveryDirectionDrop &&
    recoveryRequest > recoveryLeaseRelease,
  'page-switch recovery drops pending history and releases the parent lease before requesting source selection');

const terminalFailureSettle = switchBody.indexOf(
  'this.onPageHistorySettled(false);',
  recoveryRequest,
);
assert.ok(terminalFailureSettle > recoveryRequest,
  'the residual-direction guard remains after source-page recovery for non-history failures');

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
  /this\.pendingHistoryDirection = 0;\s+this\.onPageHistorySettled\(false\);\s+return;/,
  'invalid lifecycle consumes the stale pending direction');
assert.match(body.slice(identityGate, directionRead),
  /this\.loadedPageId !== this\.currentPage\.pageId\) \{\s+return;\s+\}/,
  'page mismatch retains the pending move for a matching reload');

console.log('D02_PENDING_HISTORY_RESUME_CONTEXT_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
