import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const requestStart = page.indexOf('private async requestRecordingDelete(recordingId: string): Promise<void> {');
const undoStart = page.indexOf('private undoRecordingDelete(recordingId: string): void {', requestStart);
const commitStart = page.indexOf('private async commitRecordingDeletes', undoStart);
assert.ok(requestStart !== -1 && undoStart > requestStart && commitStart > undoStart);

const request = page.slice(requestStart, undoStart);
assert.match(request,
  /private async requestRecordingDelete\(recordingId: string\): Promise<void> \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);

const undo = page.slice(undoStart, commitStart);
assert.match(undo,
  /private undoRecordingDelete\(recordingId: string\): void \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+this\.recordingDeleteController\.undo\(recordingId\);/);

console.log('D02_RECORDING_DELETE_REQUEST_DISPOSAL_BOUND_REPLAY_OK TOTAL=3 FAILED=0');
