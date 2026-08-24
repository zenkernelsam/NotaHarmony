import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async toggleRecording(recordingId: string): Promise<void> {');
assert.ok(start !== -1);
const end = page.indexOf('\n  private findRecording', start);
const body = page.slice(start, end);
assert.match(body, /private async toggleRecording\(recordingId: string\): Promise<void> \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+const selected:/);

console.log('D02_RECORDING_TOGGLE_DISPOSAL_BOUND_REPLAY_OK TOTAL=1 FAILED=0');