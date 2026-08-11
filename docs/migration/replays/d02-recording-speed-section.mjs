import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalPanel = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/n05.java', 'utf8');
const originalSpeed = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/wna.java', 'utf8');
const originalStrings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const strings = read('note/src/main/resources/base/element/string.json');
const tests = read('note/src/test/RecordingPanel.test.ets');

assert.match(originalPanel,
  /feature_note_toolbox__playback_speed[\s\S]*?b\(null, kpaVar2\.b, ix4Var5/);
assert.match(originalSpeed,
  /SPEED_1_0[\s\S]*SPEED_1_5[\s\S]*SPEED_2_0/);
assert.match(originalStrings,
  /name="feature_note_toolbox__playback_speed">Playback speed<\/string>/);

assert.match(panel, /this\.PlaybackControls\(\)/);
assert.match(panel,
  /if \(shouldShowRecordingTimeline\(this\.snapshot\.recordingId\)\)[\s\S]*?Slider\([\s\S]*?Row\(\) \{[\s\S]*?recording_playback_speed/);
assert.match(panel, /SpeedButton\('1x', OriginalRecordingPlaybackSpeed\.SPEED_1_0\)/);
assert.match(panel, /SpeedButton\('1\.5x', OriginalRecordingPlaybackSpeed\.SPEED_1_5\)/);
assert.match(panel, /SpeedButton\('2x', OriginalRecordingPlaybackSpeed\.SPEED_2_0\)/);
assert.match(strings, /"name": "recording_playback_speed", "value": "Playback speed"/);
assert.match(tests, /keeps only the timeline conditional on a selected recording/);
assert.match(tests, /shouldShowRecordingTimeline\(null\)\)\.assertFalse\(\)/);

console.log('recordingSpeedSection=always-visible-timeline-selection-only');
