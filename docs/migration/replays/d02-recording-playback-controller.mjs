import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const controller = read('note/src/main/ets/core/adaptation/OriginalRecordingPlaybackController.ets');
const tests = read('note/src/test/OriginalRecordingPlaybackController.test.ets');
const list = read('note/src/test/List.test.ets');
const adr = read('docs/migration/adr/ADR-0067-original-recording-single-player-controller.md');

assert.match(controller, /private mutex: AsyncMutex = new AsyncMutex\(\)/);
assert.match(controller, /const requestGeneration: number = \+\+this\.generation/);
assert.match(controller, /requestGeneration !== this\.generation/);
assert.match(controller, /player\.fdSrc = opened\.lease\.descriptor/);
assert.match(controller, /player\.on\('stateChange'/);
assert.match(controller, /state === 'initialized'[\s\S]*this\.prepare\(player, generation\)/);
assert.match(controller, /state === 'prepared'[\s\S]*OriginalRecordingPlaybackState\.READY/);
assert.match(controller, /player\.state === 'completed'[\s\S]*player\.seek\(0\)/);
assert.match(controller, /await player\.release\(\)[\s\S]*lease\.close\(\)/);
assert.match(controller, /this\.permanentlyReleased = true/);
assert.match(controller, /player\.off\('error'/);
assert.match(tests, /clampRecordingSeek\(101, 100\)/);
assert.match(list, /originalRecordingPlaybackControllerTest\(\)/);
assert.match(adr, /cross-recording sequencing belongs above/);
assert.doesNotMatch(controller, /NotePage/);

console.log('recordingPlayback=single-player-generation-release-before-fd-close');
