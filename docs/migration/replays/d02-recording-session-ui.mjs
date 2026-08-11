import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalActions = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/xjb.java', 'utf8');
const originalFocus = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/wr8.java', 'utf8');
const originalStart = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/tr8.java', 'utf8');
const originalPermission = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/fha.java', 'utf8');
const originalStrings = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const session = read('note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets');
const gateways = read('note/src/main/ets/core/adaptation/OriginalRecordingHarmonyGateways.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const strings = read('note/src/main/resources/base/element/string.json');
const tests = read('note/src/test/OriginalRecordingSessionController.test.ets');

assert.match(originalActions, /vjbVar instanceof tjb/);
assert.match(originalActions, /vjbVar\.equals\(ujb\.a\)/);
assert.match(originalActions, /vjbVar\.equals\(rjb\.a\)/);
assert.match(originalActions, /vjbVar\.equals\(sjb\.a\)/);
assert.match(originalFocus, /new AudioFocusRequest\.Builder\(1\)/);
assert.match(originalFocus, /setUsage\(1\)\.setContentType\(1\)/);
assert.match(originalStart, /requestAudioFocus\(wr8Var\.h\)/);
assert.match(originalPermission, /RECORD_AUDIO\(iha\.RECORD_AUDIO/);
assert.match(originalStrings, /ui_permissions__microphone_access_required/);
assert.match(originalStrings, /feature_note_toolbox__recording_start_failed/);
assert.match(originalStrings, /feature_note_toolbox__recording_save_failed/);

assert.match(gateways, /requestPermissionsFromUser\(this\.context, \[MICROPHONE_PERMISSION\]\)/);
assert.match(gateways, /AUDIO_SESSION_SCENE_MEDIA/);
assert.match(gateways, /CONCURRENCY_PAUSE_OTHERS/);
assert.match(gateways, /audioSessionDeactivated/);
assert.match(session, /new AsyncMutex\(\)/);
assert.match(session,
  /requestMicrophonePermission\(\)[\s\S]*beforeStart\(\)[\s\S]*focus\.activate[\s\S]*capture\.start\(\)/);
assert.match(session, /capture\.stop\(\)[\s\S]*deactivateFocus\(\)[\s\S]*persistCapture\(result\)/);
assert.match(session, /onAudioInterrupted\(\)[\s\S]*this\.stop\(\)/);
assert.match(session, /finishAndRelease\(\)[\s\S]*stopInternal\(\)[\s\S]*capture\.release\(\)/);

assert.match(page, /new OriginalRecordingSessionController\([\s\S]*recordingController\.unload\(\)/);
assert.match(page, /closeRecordings\(\)[\s\S]*await session\.stop\(\)/);
assert.match(page, /if \(this\.showRecordings\)[\s\S]*this\.closeRecordings\(\)/);
assert.match(page, /leaveEditor\(\)[\s\S]*await this\.finishRecordingSession\(\)/);
assert.match(page, /aboutToDisappear\(\)[\s\S]*this\.finishRecordingSession\(\)/);
assert.match(panel, /onRecord/);
assert.match(panel, /onPauseCapture/);
assert.match(panel, /onResumeCapture/);
assert.match(panel, /onStopCapture/);
assert.match(panel, /captureSnapshot\.saving/);
assert.match(strings, /Microphone Access Required/);
assert.match(strings, /Couldn't start recording/);
assert.match(strings, /Couldn't save recording/);
assert.match(tests, /queues close-time stop behind an in-flight start/);
assert.match(tests, /reports a capture start failure only once/);
assert.match(tests, /classifies an active recorder failure as save failure/);

console.log('recordingSession=permission-focus-interruption-controls-close-save-release');
