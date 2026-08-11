import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const originalSource = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/bkb.java', 'utf8');
const originalDispatch = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/xjb.java', 'utf8');
const originalInternal = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vp8.java', 'utf8');
const originalService = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/feature/note/toolbox/audio/record/wrapper/audio/AudioCaptureService.java', 'utf8');
const nativeBridge = read('note/src/main/cpp/nota_recording.cpp');
const cmake = read('note/src/main/cpp/CMakeLists.txt');
const internalBackend = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingInternalAudioBackend.ets');
const sourceBackend = read(
  'note/src/main/ets/core/adaptation/OriginalRecordingSourceBackend.ets');
const session = read('note/src/main/ets/core/adaptation/OriginalRecordingSessionController.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/editor/RecordingPanel.ets');
const tests = read('note/src/test/OriginalRecordingSessionController.test.ets');

assert.match(originalSource, /MIC\(R\.string\.feature_note_toolbox__recording_audio_source_microphone\)/);
assert.match(originalSource, /DEVICE_ONLY\(R\.string\.feature_note_toolbox__recording_audio_source_internal\)/);
assert.match(originalDispatch, /isMusicActive\(\)/);
assert.match(originalDispatch, /skbVar\.m\(bkb\.MIC, ttfVar\)/);
assert.match(originalInternal, /public final boolean a\(\) \{\s*return false;/);
assert.match(originalInternal, /Pause not supported for internal audio recorder/);
assert.match(originalInternal, /Resume not supported for internal audio recorder/);
assert.match(originalService, /AudioPlaybackCaptureConfiguration\.Builder/);
assert.match(originalService, /addMatchingUsage\(1\)/);
assert.match(originalService, /setAudioFormat[\s\S]*44100[\s\S]*16[\s\S]*4/);

assert.match(cmake, /libnative_avscreen_capture\.so/);
assert.match(nativeBridge, /OH_CAPTURE_FILE/);
assert.match(nativeBridge, /OH_ALL_PLAYBACK/);
assert.match(nativeBridge, /OH_AAC_LC/);
assert.match(nativeBridge, /CFT_MPEG_4A/);
assert.match(nativeBridge, /SAMPLE_RATE = 44100/);
assert.match(nativeBridge, /CHANNELS = 1/);
assert.match(nativeBridge, /BITRATE = 96000/);
assert.match(nativeBridge,
  /void OnStateChange[\s\S]*SendEvent\(EVENT_STATE, static_cast<int32_t>\(state\)\)/);
assert.match(nativeBridge, /capture != gCapture/);
assert.match(nativeBridge, /gExternallyStopped/);
assert.match(nativeBridge, /IsCaptureActive/);

assert.match(internalBackend, /supportsPause\(\): boolean \{\s*return false;/);
assert.match(internalBackend, /isCaptureActive\(\)/);
assert.match(internalBackend, /startCapture\(`fd:\/\/\$\{this\.outputFile\.fd\}`\)/);
assert.match(internalBackend, /SCREEN_CAPTURE_STARTED/);
assert.match(internalBackend, /SCREEN_CAPTURE_CANCELED/);
assert.match(internalBackend, /interruptionListener\(\)/);
assert.match(internalBackend, /fetchMetadata\(\)/);
assert.match(sourceBackend, /OriginalRecordingAudioSource\.DEVICE_ONLY/);
assert.match(sourceBackend, /selected recording source does not support pause/);

assert.match(session,
  /source === OriginalRecordingAudioSource\.MICROPHONE[\s\S]*requestMicrophonePermission/);
assert.match(session,
  /source === OriginalRecordingAudioSource\.MICROPHONE[\s\S]*focus\.activate/);
assert.match(session, /canPause\(\): boolean[\s\S]*capture\.canPause\(\)/);
assert.match(page, /isStreamActive\([\s\S]*STREAM_USAGE_MUSIC/);
assert.match(page, /select_audio_source/);
assert.match(page, /OriginalRecordingAudioSource\.MICROPHONE/);
assert.match(page, /OriginalRecordingAudioSource\.DEVICE_ONLY/);
assert.match(panel, /capturePauseSupported/);
assert.match(panel, /if \(this\.capturePauseSupported\)/);
assert.match(tests, /matches original internal audio capability permission and focus behavior/);
assert.match(tests, /expect\(session\.canPause\(\)\)\.assertFalse\(\)/);
assert.match(tests, /internalAudio\.interrupt\(\)/);
assert.match(tests, /interruptDuringStart/);
assert.match(tests, /saves when internal audio is interrupted immediately after native start/);
assert.match(read('note/src/main/ets/core/adaptation/OriginalRecordingCaptureController.ets'),
  /isCaptureRunning[\s\S]*OriginalRecordingCaptureState\.STARTING/);

console.log('recordingInternalAudio=music-gated-source-native-m4a-no-mic-no-focus-no-pause-save-on-stop');
