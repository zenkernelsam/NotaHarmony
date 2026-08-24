import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private async seekRecordingTimeline(positionMs: number): Promise<void> {');
const end = page.indexOf('\n  private changeRecordingPlaybackSpeed', start);
assert.ok(start !== -1 && end > start);

const seek = page.slice(start, end);
const guards = (seek.match(/if \(this\.editorDisposed\) \{\s+return;\s+\}/g) ?? []).length;
assert.ok(guards >= 1);
assert.match(seek,
  /private async seekRecordingTimeline\(positionMs: number\): Promise<void> \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+const location/);
assert.match(seek, /await this\.recordingController\.load\(recording, resumePlayback, location\.localPositionMs\);/);

console.log('D02_RECORDING_SEEK_DISPOSAL_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
