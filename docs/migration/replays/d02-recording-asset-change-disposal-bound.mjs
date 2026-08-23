import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private onRecordingAssetAvailabilityChanged(change: AssetAvailabilityChange): void {');
const end = page.indexOf('\n  build()', start);
assert.ok(start !== -1 && end > start);

const handler = page.slice(start, end);
assert.match(handler,
  /private onRecordingAssetAvailabilityChanged\(change: AssetAvailabilityChange\): void \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+if \(change\.noteIds\.indexOf\(this\.noteId\) >= 0\) \{\s+this\.loadRecordings\(\);/);

console.log('D02_RECORDING_ASSET_CHANGE_DISPOSAL_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
