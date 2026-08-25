import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf(
  '  private async advanceAfterRecordingCompletion(recordingId: string): Promise<void> {');
const end = page.indexOf('  private async seekRecordingTimeline(', start);
assert.ok(start !== -1 && end > start);
const advance = page.slice(start, end);

const disposedIndex = advance.indexOf('if (this.editorDisposed) {');
const pendingIndex = advance.indexOf(
  "if (this.pendingRecordingDeleteIds.indexOf(recordingId) >= 0) {");
const nextIndex = advance.indexOf('const nextId: string | null =', pendingIndex);
assert.ok(pendingIndex > disposedIndex && nextIndex > pendingIndex,
  'disposal and pending-delete gates precede timeline selection');
assert.match(advance,
  /if \(this\.pendingRecordingDeleteIds\.indexOf\(recordingId\) >= 0\) \{\s+return;\s+\}\s+const nextId: string \| null = nextTimelineRecordingId\(this\.recordingTimeline, recordingId\);/,
  'a completed recording requested for deletion cannot auto-advance');

console.log('D02_RECORDING_ADVANCE_PENDING_DELETE_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
