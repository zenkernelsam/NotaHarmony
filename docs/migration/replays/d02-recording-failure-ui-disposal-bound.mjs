import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private showRecordingFailure(failure: OriginalRecordingSessionFailure): void {');
const end = page.indexOf('\n  private async startRecording', start);
assert.ok(start !== -1 && end > start);

const handler = page.slice(start, end);
assert.match(handler,
  /private showRecordingFailure\(failure: OriginalRecordingSessionFailure\): void \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+if \(failure === OriginalRecordingSessionFailure\.NONE\)/);
assert.match(handler, /promptAction\.showDialog\(/);
assert.match(handler, /promptAction\.showToast\(/);

console.log('D02_RECORDING_FAILURE_UI_DISPOSAL_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
