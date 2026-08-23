import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const leaveStart = page.indexOf('private leaveEditor(): Promise<void> {');
const performStart = page.indexOf('private async performLeaveEditor(): Promise<void> {');
assert.notEqual(leaveStart, -1);
assert.ok(performStart > leaveStart);

const guard = page.slice(leaveStart, performStart);
assert.match(guard, /if \(this\.editorLeavePromise !== null\)/);
assert.match(guard, /return this\.editorLeavePromise;/);
assert.match(guard, /this\.editorLeavePromise = this\.performLeaveEditor\(\);/);
assert.match(guard, /return this\.editorLeavePromise;/);

const performEnd = page.indexOf('\n  private async loadPages', performStart);
assert.notEqual(performEnd, -1);
const perform = page.slice(performStart, performEnd);
assert.match(perform,
  /if \(this\.editingTitle\) \{\s+await this\.saveTitle\(\);\s+\} else \{[\s\S]*?await this\.titleSaveQueue;/);
assert.match(perform, /await this\.historyBridge\.flushCurrentPage\(\)/);
assert.match(perform, /await this\.viewModel\.flushToolState\(\);/);
assert.match(perform, /await this\.recordingDeleteController\.flush\(\);/);
assert.match(perform, /await this\.finishRecordingSession\(\);/);
assert.match(perform, /await this\.recordingController\.release\(\);/);
assert.match(perform, /router\.back\(\);/);

console.log('D02_EDITOR_LEAVE_REENTRANCY_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
