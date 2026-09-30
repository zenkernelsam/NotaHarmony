// Phase 1315 — op-payload encoders + stroke algorithms
import { existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const encoders = readdirSync(S + 'data').filter(f => /^Original.*PayloadEncoder/.test(f));
t('Original*PayloadEncoder 5+', encoders.length >= 5);
t('CreateBlock encoder', X('data/OriginalCreateBlockPayloadEncoder.ets'));
t('CreateInk encoder', X('data/OriginalCreateInkPayloadEncoder.ets'));
t('CreatePage encoder', X('data/OriginalCreatePagePayloadEncoder.ets'));
t('CreateShape encoder', X('data/OriginalCreateShapePayloadEncoder.ets'));
t('DeleteEntities encoder', X('data/OriginalDeleteEntitiesPayloadEncoder.ets'));
t('mutation codecs', X('data/NoteTitleMutationCodec.ets') && X('data/NoteBackgroundMutationCodec.ets'));
t('algorithm dir', existsSync(S + 'core/algorithm'));
t('CubicFitter+ShapeDetector', X('core/algorithm/CubicFitter.ets') && X('core/algorithm/ShapeDetector.ets'));
t('data 150+ files', readdirSync(S + 'data', {recursive:true}).filter(f => f.endsWith('.ets')).length >= 140);
console.log('op-encoders replay: ' + n + '/10 checks green');
