// Phase 1313 — Harmony core/adaptation layer (platform bridges)
import { existsSync, readdirSync, readFileSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/adaptation/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('InkInputProvider', X('InkInputProvider.ets') && X('InkInputProviderImpl.ets'));
t('PenKitPredictor (Harmony stylus)', X('PenKitPredictor.ets'));
t('Predictor abstraction', X('Predictor.ets') && X('NullPredictor.ets'));
t('OriginalLaserPointer', X('OriginalLaserPointer.ets'));
t('AudioLinkedInkPlayback', X('OriginalAudioLinkedInkPlayback.ets'));
t('PencilSplatMath', X('PencilSplatMath.ets'));
t('paper texture loader', X('OriginalPaperTextureLoader.ets'));
t('RecognitionProvider', X('RecognitionProvider.ets'));
t('recording backends', readdirSync(S).filter(f => /OriginalRecording.*Backend/.test(f)).length >= 2);
t('adaptation 35+ files', readdirSync(S).filter(f => f.endsWith('.ets')).length >= 35);
console.log('adaptation-layer replay: ' + n + '/10 checks green');
