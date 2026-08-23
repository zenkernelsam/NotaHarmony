import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async persistCapturedRecording(capture: OriginalRecordingCaptureResult): Promise<void> {');
const end = page.indexOf('\n  private onRecordingSessionSnapshot', start);
assert.ok(start !== -1 && end > start);

const persist = page.slice(start, end);
assert.match(persist,
  /await persistCapturedOriginalRecording\(DatabaseManager\.getInstance\(\), this\.noteId, capture\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+await this\.loadRecordings\(\);/);

console.log('D02_RECORDING_PERSIST_DISPOSAL_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
