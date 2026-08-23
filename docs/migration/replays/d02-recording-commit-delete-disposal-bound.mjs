import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async commitRecordingDeletes(recordingIds: string[]): Promise<void> {');
const end = page.indexOf('\n  private onRecordingAssetAvailabilityChanged', start);
assert.ok(start !== -1 && end > start);

const commit = page.slice(start, end);
assert.match(commit,
  /await this\.recordingStore\.deleteVisible\([\s\S]*?\)\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+await this\.loadRecordings\(\);/);

console.log('D02_RECORDING_COMMIT_DELETE_DISPOSAL_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
