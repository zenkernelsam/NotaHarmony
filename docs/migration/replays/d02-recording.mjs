// Phase 1346 — recording subsystem + core remainder
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const A = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/';
const M = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/model/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const mic = readFileSync(A + 'OriginalRecordingMicrophoneBackend.ets', 'utf8');
t('AVRecorder', mic.includes('AVRecorder'));
t('mp4 mime', mic.includes('audio/mp4'));
t('AAC codec', mic.includes('AAC') || mic.includes('AUDIO_AAC'));
t('bitrate/channels/rate', mic.includes('BITRATE') && mic.includes('SAMPLE_RATE'));
t('HarmonyGateways', existsSync(A + 'OriginalRecordingHarmonyGateways.ets'));
t('AssetLoader', existsSync(A + 'OriginalRecordingAssetLoader.ets'));
t('CaptureArtifactCleanup', existsSync(A + 'OriginalRecordingCaptureArtifactCleanup.ets'));
t('InkInputProvider', existsSync(A + 'InkInputProviderImpl.ets'));
t('MathBlockGeometry', existsSync(M + 'MathBlockGeometry.ets'));
t('NoteTitlePolicy', existsSync(M + 'OriginalNoteTitlePolicy.ets'));
console.log('recording replay: ' + n + '/10 checks green');
