import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /private completionAdvanceCount: number = 0;/);
assert.doesNotMatch(page, /completionAdvanceInFlight/);

const listenerStart = page.indexOf(
  'private onRecordingPlaybackSnapshot(snapshot: OriginalRecordingPlaybackSnapshot): void {');
const advanceStart = page.indexOf(
  'private async advanceAfterRecordingCompletion(recordingId: string): Promise<void> {', listenerStart);
const seekStart = page.indexOf(
  'private async seekRecordingTimeline(positionMs: number): Promise<void> {', advanceStart);
assert.ok(listenerStart >= 0 && advanceStart > listenerStart && seekStart > advanceStart);

const listener = page.slice(listenerStart, advanceStart);
const completedGate = listener.indexOf(
  "if (snapshot.state !== OriginalRecordingPlaybackState.COMPLETED) {");
const ownershipBlock = listener.indexOf("if (snapshot.recordingId !== null) {", completedGate);
const increment = listener.indexOf('this.completionAdvanceCount++;', ownershipBlock);
const finallyRelease = listener.indexOf('.finally((): void => {', increment);
const decrement = listener.indexOf('this.completionAdvanceCount--;', finallyRelease);
const close = listener.indexOf('});\n    }\n  }', decrement);
assert.ok(completedGate >= 0 && ownershipBlock > completedGate && increment > ownershipBlock &&
  finallyRelease > increment && decrement > finallyRelease && close > decrement);
assert.equal(listener.slice(close).includes('completionAdvanceCount'), false);

const advance = page.slice(advanceStart, seekStart);
const disposedReturn = advance.indexOf('if (this.editorDisposed) {');
const loadAwait = advance.indexOf('await this.recordingController.load(next, true);', disposedReturn);
assert.ok(disposedReturn >= 0 && loadAwait > disposedReturn);
assert.doesNotMatch(advance, /completionAdvanceCount\s*(\+\+|--|=)/,
  'each async advance owns its release through the caller finally');

const seek = page.slice(seekStart,
  page.indexOf('  private changeRecordingPlaybackSpeed(', seekStart));
assert.match(seek,
  /await this\.recordingController\.load\(recording, resumePlayback, location\.localPositionMs\);\s+if \(this\.editorDisposed\) \{\s+return;\s+\}/);
assert.doesNotMatch(seek, /completionAdvanceCount/,
  'user seek invalidates automatic advancement without stealing another task ownership');

console.log('D02_RECORDING_COMPLETION_ADVANCE_COUNT_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
