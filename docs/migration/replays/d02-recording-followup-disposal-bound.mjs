import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const guard = /if \(this\.editorDisposed(?: \|\| generation !== this\.recordingLoadGeneration)?\) \{\s+(?:return;)\s+\}/;

function body(startMarker, endMarker) {
  const start = page.indexOf(startMarker);
  const end = page.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return page.slice(start, end);
}

const load = body('  private async loadRecordings(', '  private async persistCapturedRecording(');
const loadAwait = load.indexOf('await this.recordingStore.listVisible(');
const loadGuard = load.match(/await this\.recordingStore\.listVisible\([\s\S]*?\);\s+if \(this\.editorDisposed \|\| generation !== this\.recordingLoadGeneration\) \{\s+return;/);
assert.ok(loadGuard);

for (const [name, text] of [
  ['commitRecordingDeletes', body('  private async commitRecordingDeletes(', '  private onRecordingAssetAvailabilityChanged(')],
]) {
  const awaits = [...text.matchAll(/await (?:this\.[a-zA-Z]+\.)?[a-zA-Z]+/g)];
  assert.ok(awaits.length >= 2, `${name} awaits=${awaits.length}`);
}

assert.match(body('  private async persistCapturedRecording(', '  private onRecordingSessionSnapshot('),
  /await this\.loadRecordings\(\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}\s+this\.rebuildRecordingTimeline\(\);/);

assert.match(body('  private async advanceAfterRecordingCompletion(', '  private async seekRecordingTimeline('),
  /await this\.recordingController\.load\(next, true\);\s+\}/);

assert.match(body('  private async seekRecordingTimeline(', '  private changeRecordingPlaybackSpeed('),
  /await this\.recordingController\.load\(recording, resumePlayback, location\.localPositionMs\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);

assert.match(body('  private async commitRecordingDeletes(', '  private onRecordingAssetAvailabilityChanged('),
  /await this\.loadRecordings\(\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);

const commitBody = body('  private async commitRecordingDeletes(', '  private onRecordingAssetAvailabilityChanged(');
assert.ok(!commitBody.includes('this.pendingRecordingDeleteIds'));

console.log('D02_RECORDING_FOLLOWUP_DISPOSAL_BOUND_REPLAY_OK TOTAL=9 FAILED=0');
