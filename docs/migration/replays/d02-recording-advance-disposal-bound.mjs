import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async advanceAfterRecordingCompletion(recordingId: string): Promise<void> {');
const end = page.indexOf('\n  private async seekRecordingTimeline', start);
assert.ok(start !== -1 && end > start);

const advance = page.slice(start, end);
const guardCount = (advance.match(/if \((?:!) ?this\.editorDisposed\)/g) ?? []).length;
assert.ok(guardCount >= 1);
assert.match(advance,
  /private async advanceAfterRecordingCompletion\(recordingId: string\): Promise<void> \{\s+if \(this\.editorDisposed\) \{\s+this\.completionAdvanceInFlight = false;\s+return;\s+\}/);
assert.match(advance,
  /await this\.recordingController\.load\(next, true\);\s+\}\s+if \(!this\.editorDisposed\) \{\s+this\.completionAdvanceInFlight = false;\s+\}/);

console.log('D02_RECORDING_ADVANCE_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
