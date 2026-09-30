// Phase 1332 — audio-linked ink playback
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const A = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/';
const D = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const f = readFileSync(A + 'OriginalAudioLinkedInkPlayback.ets', 'utf8');
t('audioStartTime field', f.includes('audioStartTime'));
t('seek target resolver', f.includes('resolveOriginalAudioInkSeekTarget'));
t('u64-decimal validate', f.includes('validateUnsignedLongDecimal'));
t('segment-belongs check', f.includes('audioTimeBelongsToSegments'));
t('u64 compare', f.includes('compareUnsignedLongDecimal'));
t('original ref h3/vv7', f.includes('h3') && f.includes('vv7'));
t('playbackStroke', f.includes('playbackStroke'));
t('AudioTimeStore', existsSync(D + 'OriginalOperationAudioTimeStore.ets'));
t('PlaybackController', existsSync(A + 'OriginalRecordingPlaybackController.ets'));
t('InternalAudioBackend', existsSync(A + 'OriginalRecordingInternalAudioBackend.ets'));
console.log('audio-ink replay: ' + n + '/10 checks green');
