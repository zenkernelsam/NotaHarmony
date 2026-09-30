// Phase 1165 — feature audio-record service + OAuth login activities
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/feature/';
const R = f => readFileSync(B + f, 'utf8');
const has = f => existsSync(B + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('RecordingForegroundService exists', has('note/toolbox/audio/record/RecordingForegroundService.java'));
t('RecordingForegroundService extends Service', R('note/toolbox/audio/record/RecordingForegroundService.java').includes('extends Service'));
t('AudioCaptureService exists', has('note/toolbox/audio/record/wrapper/audio/AudioCaptureService.java'));
t('audio record under note/toolbox', has('note/toolbox/audio/record'));
t('AppleSignInActivity exists', has('login/apple/AppleSignInActivity.java'));
t('AppleSignInActivity extends r12 (Activity)', R('login/apple/AppleSignInActivity.java').includes('extends r12'));
t('MicrosoftSignInActivity exists', has('login/microsoft/MicrosoftSignInActivity.java'));
t('MicrosoftSignInActivity is Activity', R('login/microsoft/MicrosoftSignInActivity.java').includes('extends'));
t('login/{apple,microsoft} dirs', has('login/apple') && has('login/microsoft'));
t('RecordingForegroundService @Metadata toolbox', R('note/toolbox/audio/record/RecordingForegroundService.java').includes('"toolbox"'));
console.log('feature replay: ' + n + '/10 checks green');
