import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('this.recordingDeleteController.setFailureListener(');
const end = page.indexOf('\n    if (this.assetAvailabilitySubscription < 0)', start);
assert.ok(start !== -1 && end > start);

const listener = page.slice(start, end);
assert.match(listener,
  /console\.error\(`Recording delete failed[^\n]+\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);
assert.match(listener, /promptAction\.showToast\(\{ message: \$r\('app\.string\.recording_delete_failed'\)/);

const disposeStart = page.indexOf('aboutToDisappear(): void {');
const disposeEnd = page.indexOf('\n  onBackPress()', disposeStart);
assert.match(page.slice(disposeStart, disposeEnd), /this\.editorDisposed = true;/);
assert.ok(disposeEnd > disposeStart);

console.log('D02_RECORDING_DELETE_FAILURE_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
