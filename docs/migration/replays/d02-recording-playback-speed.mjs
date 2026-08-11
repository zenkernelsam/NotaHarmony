import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const controller = read('note/src/main/ets/core/adaptation/OriginalRecordingPlaybackController.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const tests = read('note/src/test/OriginalRecordingPlaybackController.test.ets');

assert.match(controller, /SPEED_1_0 = 0[\s\S]*SPEED_1_5 = 1[\s\S]*SPEED_2_0 = 2/);
assert.match(controller, /player\.state === 'prepared'[\s\S]*player\.state === 'playing'[\s\S]*player\.state === 'paused'[\s\S]*player\.state === 'completed'/);
assert.match(controller, /player\.setSpeed\(toMediaPlaybackSpeed\(speed\)\)/);
assert.match(controller, /finishPreparedLoad[\s\S]*player\.setSpeed\(toMediaPlaybackSpeed\(this\.playbackSpeed\)\)[\s\S]*this\.playPrepared/);
assert.match(controller, /player\.on\('speedDone', this\.speedHandler\)/);
assert.match(controller, /player\.off\('speedDone', this\.speedHandler\)/);
assert.match(controller, /speedHandler[\s\S]*!isOriginalMediaPlaybackSpeed\(speed\)/);
assert.match(controller, /SPEED_FORWARD_1_00_X/);
assert.match(controller, /SPEED_FORWARD_1_50_X/);
assert.match(controller, /SPEED_FORWARD_2_00_X/);
assert.match(page, /recordingController\.setSpeed\(speed\)/);
assert.match(panel, /SpeedButton\('1x', OriginalRecordingPlaybackSpeed\.SPEED_1_0\)/);
assert.match(panel, /SpeedButton\('1\.5x', OriginalRecordingPlaybackSpeed\.SPEED_1_5\)/);
assert.match(panel, /SpeedButton\('2x', OriginalRecordingPlaybackSpeed\.SPEED_2_0\)/);
assert.match(tests, /accepts only the three playback speeds exposed by the original app/);

console.log('recordingSpeed=original-three-modes-prepared-before-play-speedDone');
