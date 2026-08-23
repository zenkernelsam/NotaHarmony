import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('private onRecordingPlaybackSnapshot(snapshot: OriginalRecordingPlaybackSnapshot): void {');
const end = page.indexOf('\n  private updateCumulativePlaybackPosition', start);
assert.ok(start !== -1 && end > start);

const callback = page.slice(start, end);
assert.match(callback,
  /private onRecordingPlaybackSnapshot\(snapshot: OriginalRecordingPlaybackSnapshot\): void \{\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+this\.playbackSnapshot = snapshot;/);

console.log('D02_RECORDING_PLAYBACK_SNAPSHOT_DISPOSAL_BOUND_REPLAY_OK TOTAL=2 FAILED=0');
