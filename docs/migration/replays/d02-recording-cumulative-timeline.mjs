import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const timeline = read('note/src/main/ets/core/adaptation/OriginalRecordingTimeline.ets');
const controller = read('note/src/main/ets/core/adaptation/OriginalRecordingPlaybackController.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const tests = read('note/src/test/OriginalRecordingTimeline.test.ets');

assert.match(timeline, /recording\.segments\.length > 0[\s\S]*recording\.segments\[0\]/);
assert.match(timeline, /boundaryTimesMs: boundaries/);
assert.match(timeline, /for \(let index: number = timeline\.entries\.length - 1; index >= 0; index--\)/);
assert.match(timeline, /entry\.startMs <= target/);
assert.match(controller, /initialPositionMs: number = 0/);
assert.match(controller, /state === 'prepared'[\s\S]*this\.finishPreparedLoad\(player, generation\)/);
assert.match(controller, /finishPreparedLoad[\s\S]*player\.seek\(this\.initialPositionMs\)[\s\S]*this\.playPrepared/);
assert.match(page, /nextTimelineRecordingId\(this\.recordingTimeline, recordingId\)/);
assert.match(page, /this\.recordingController\.load\(next, true\)/);
assert.match(page, /locateOriginalRecordingTimeline\(this\.recordingTimeline, positionMs\)/);
assert.match(page, /this\.recordingController\.load\(recording, resumePlayback, location\.localPositionMs\)/);
assert.match(page, /await this\.leaveEditor\(\)/);
assert.match(panel, /value: this\.cumulativePositionMs/);
assert.match(panel, /max: Math\.max\(1, this\.cumulativeDurationMs\)/);
assert.match(tests, /18446744073709551615/);

console.log('recordingTimeline=first-segment-boundaries-global-seek-auto-advance');
