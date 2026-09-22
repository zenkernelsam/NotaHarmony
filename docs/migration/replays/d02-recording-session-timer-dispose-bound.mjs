import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const disappearStart = page.indexOf('aboutToDisappear(): void {');
assert.notEqual(disappearStart, -1);
const disappearEnd = page.indexOf('\n  onBackPress()', disappearStart);
assert.notEqual(disappearEnd, -1);
const disappear = page.slice(disappearStart, disappearEnd);

// Phase 560 inserted the keep-awake generation bump + keepScreenOn release
// between the recording-generation bump and the refresh cancel — the ordering
// contract (bump before cancel) is preserved, so allow intervening lines.
assert.match(disappear,
  /this\.recordingLoadGeneration\+\+;[\s\S]{0,600}this\.cancelRecordingSessionRefresh\(\);/);
assert.ok(disappear.indexOf('cancelRecordingSessionRefresh()') <
  disappear.indexOf('finishRecordingSession()'));

const scheduleStart = page.indexOf('private scheduleRecordingSessionRefresh(): void {');
const cancelStart = page.indexOf('private cancelRecordingSessionRefresh(): void {');
assert.ok(scheduleStart !== -1 && cancelStart > scheduleStart);

console.log('D02_RECORDING_SESSION_TIMER_DISPOSE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
