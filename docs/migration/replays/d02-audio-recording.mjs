// Phase 1301 — audio recording (foreground service)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/feature/note/toolbox/audio/record/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const rf = R('RecordingForegroundService.java');
t('RecordingForegroundService Service', rf.includes('extends Service'));
t('notification channel notability_recording', rf.includes('notability_recording'));
t('foreground notification', rf.includes('startForeground') || rf.includes('Notification'));
t('onStartCommand', rf.includes('onStartCommand'));
t('onBind', rf.includes('onBind'));
const ac = X('wrapper/audio/AudioCaptureService.java');
t('AudioCaptureService exists', ac);
t('AudioCapture is Service', ac && R('wrapper/audio/AudioCaptureService.java').includes('Service'));
t('recording channel name string', rf.includes('recording_notification_channel_name'));
t('recording title string', rf.includes('recording_notification_title'));
t('wrapper dir', existsSync(S + 'wrapper/audio'));
console.log('audio-recording replay: ' + n + '/10 checks green');
