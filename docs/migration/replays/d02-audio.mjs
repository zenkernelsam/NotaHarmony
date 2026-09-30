// Phase 1196 — audio record engine (AudioCaptureService + RecordingForegroundService)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/feature/note/toolbox/audio/record/';
const has = f => existsSync(B + f);
const R = f => readFileSync(B + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const acs = R('wrapper/audio/AudioCaptureService.java');
t('AudioCaptureService extends Service', acs.includes('extends Service'));
t('uses android.media.AudioRecord', acs.includes('AudioRecord'));
t('AudioRecord.Builder', acs.includes('AudioRecord.Builder'));
t('sampleRate 44100', acs.includes('setSampleRate(44100)'));
t('channelMask 16 + buffer 2048', acs.includes('setChannelMask(16)') && acs.includes('2048'));
t('AudioPlaybackCaptureConfig', acs.includes('AudioPlaybackCaptureConfig') || acs.includes('PlaybackCapture'));
t('audioRecord.read(short[])', acs.includes('audioRecord.read(') || acs.includes('.read(sArr'));
t('PCM→AAC conversion', acs.includes('PCM to AAC'));
t('RecordingForegroundService extends Service', R('RecordingForegroundService.java').includes('extends Service'));
t('RecordingForegroundService onStartCommand', R('RecordingForegroundService.java').includes('onStartCommand'));
console.log('audio replay: ' + n + '/10 checks green');
