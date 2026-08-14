import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalRecorder = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/tr8.java', 'utf8');
const originalState = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/wr8.java', 'utf8');
const originalStop = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ky.java', 'utf8');
const controller = read('note/src/main/ets/core/adaptation/OriginalRecordingCaptureController.ets');
const backend = read('note/src/main/ets/core/adaptation/OriginalRecordingMicrophoneBackend.ets');
const manifest = read('note/src/main/module.json5');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const tests = read('note/src/test/OriginalRecordingCaptureController.test.ets');
const sessionTests = read('note/src/test/OriginalRecordingSessionController.test.ets');

assert.match(originalRecorder, /setAudioSource\(6\)/);
assert.match(originalRecorder, /setOutputFormat\(2\)/);
assert.match(originalRecorder, /setAudioEncoder\(3\)/);
assert.match(originalRecorder, /setAudioChannels\(1\)/);
assert.match(originalRecorder, /setAudioSamplingRate\(44100\)/);
assert.match(originalRecorder, /setAudioEncodingBitRate\(96000\)/);
assert.match(originalRecorder, /mediaRecorder3\.start\(\)[\s\S]*System\.currentTimeMillis\(\)[\s\S]*SystemClock\.elapsedRealtime\(\)/);
assert.match(originalRecorder, /mediaRecorder\.pause\(\)[\s\S]*wr8Var\.m = SystemClock\.elapsedRealtime\(\)/);
assert.match(originalRecorder, /mediaRecorder2\.resume\(\)[\s\S]*wr8Var\.l = \(SystemClock\.elapsedRealtime\(\) - wr8Var\.m\) \+ wr8Var\.l/);
assert.match(originalState, /return g3j\.b\(SystemClock\.elapsedRealtime\(\), this\.k, this\.l, this\.m/);
assert.match(originalStop, /extractMetadata\(9\)/);
assert.match(originalStop, /strExtractMetadata != null \? Long\.parseLong\(strExtractMetadata\) : wr8Var\.e\(\)/);
assert.match(originalStop, /long j2 = wr8Var\.j;[\s\S]*j2 \+ j/);

assert.match(backend, /AUDIO_SOURCE_TYPE_VOICE_RECOGNITION/);
assert.match(backend, /audioSampleRate: ORIGINAL_RECORDING_AUDIO_SAMPLE_RATE/);
assert.match(backend, /audioChannels: ORIGINAL_RECORDING_AUDIO_CHANNELS/);
assert.match(backend, /audioBitrate: ORIGINAL_RECORDING_AUDIO_BITRATE/);
assert.match(backend, /AUDIO_AAC/);
assert.match(backend, /CFT_MPEG_4A/);
assert.match(backend, /fileIo\.OpenMode\.TRUNC/);
assert.match(backend, /recorder\.on\('error'/);
assert.match(backend, /recorder\.on\('stateChange'/);
assert.match(backend, /reason !== media\.StateChangeReason\.BACKGROUND/);
assert.match(backend, /state !== 'paused' && state !== 'stopped'/);
assert.match(backend, /recorder\.state !== 'started' && recorder\.state !== 'paused' &&[\s\S]*recorder\.state !== 'stopped'/);
assert.match(backend, /if \(recorder\.state !== 'stopped'\) \{[\s\S]*await recorder\.stop\(\)/);
assert.match(backend, /recorder\.off\('stateChange'/);
assert.match(backend, /AVMetadataExtractor/);
assert.match(backend, /await this\.dispose\(true, true\)/);
assert.match(backend, /fileIo\.unlinkSync\(path\)/);

assert.match(controller, /new AsyncMutex\(\)/);
assert.match(controller, /accumulatedPauseMs \+= Math\.max\(0, now - this\.pausedAtUptime\)/);
assert.match(controller, /mediaDuration === null \? fallbackDuration : mediaDuration/);
assert.match(controller, /endTime: this\.startWallTime \+ duration/);
assert.match(controller, /this\.backend\.setErrorListener\(null\)/);
assert.match(controller, /OriginalRecordingCaptureState\.RELEASED/);
assert.match(manifest, /ohos\.permission\.MICROPHONE/);
assert.match(manifest, /abilities[\s\S]*NoteAbility/);
assert.match(manifest, /when[\s\S]*inuse/);
assert.match(page, /new OriginalRecordingMicrophoneBackend\(context\.tempDir\)/);
assert.match(page, /new OriginalRecordingSessionController\(/);
assert.match(page, /session\.finishAndRelease\(\)/);
assert.doesNotMatch(page, /capture\.start\(\)/);
assert.match(tests, /asynchronous recorder error/);
assert.match(tests, /start,pause,resume,stop/);
assert.match(sessionTests, /microphone backend is interrupted/);
assert.doesNotMatch(read('note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets'),
  /private onCaptureInterrupted\(\): void \{\s*this\.focusActive = false;/);

console.log('recordingCapture=original-aac-pause-duration-temp-cleanup');
