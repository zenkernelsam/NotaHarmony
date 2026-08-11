import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const operation = read('note/src/main/ets/data/OriginalRecordingOperation.ets');
const controller = read('note/src/main/ets/core/adaptation/OriginalRecordingPlaybackController.ets');
const tests = read('note/src/test/RecordingPanel.test.ets');
const list = read('note/src/test/List.test.ets');
const strings = JSON.parse(read('note/src/main/resources/base/element/string.json'));

assert.match(page, /new OriginalRecordingStore\(db\)/);
assert.match(page, /recordingStore\.listVisible\(this\.noteId\)/);
assert.match(page, /recordingController\.load\(selected, true\)/);
assert.match(page, /OriginalRecordingPlaybackState\.PLAYING[\s\S]*recordingController\.pause\(\)/);
assert.match(page, /assetAvailabilityHub\.subscribe/);
assert.match(page, /assetAvailabilityHub\.unsubscribe/);
assert.match(page, /generation === this\.recordingLoadGeneration/);
assert.match(page, /recordingController\.release\(\)/);
assert.match(panel, /OriginalRecordingAssetState\.PENDING/);
assert.match(panel, /OriginalRecordingAssetState\.MISSING/);
assert.match(panel, /OriginalRecordingAssetState\.FAILED/);
assert.match(panel, /this\.cumulativeDurationMs > 0/);
assert.match(panel, /onSeek\(value\)/);
assert.match(tests, /3661000/);
assert.match(list, /recordingPanelTest\(\)/);
assert.doesNotMatch(operation, /throw error;/);
assert.match(operation, /applying original Recording operation failed/);
assert.match(controller, /\(\(error: BusinessError\) => void\) \| null/);
assert(strings.string.some(value => value.name === 'recordings'));
assert.match(panel, /onRecord/);
assert.match(panel, /onStopCapture/);
assert.doesNotMatch(panel,
  /OriginalRecordingMicrophoneBackend|persistCapturedOriginalRecording|DatabaseManager|renameRecording/);

console.log('recordingEditor=list-select-toggle-seek-late-asset-release');
