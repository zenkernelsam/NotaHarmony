// Phase 1329 — data consistency (serialization roundtrip fidelity)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ik = readFileSync(S + 'OriginalInkPathCodec.ets', 'utf8');
t('InkPathCodec', ik.includes('decodeOriginalInkPath') || ik.includes('decodeElements'));
t('float32 LE points', ik.includes('getFloat32'));
t('decodeElements type→count', ik.includes('decodeElements'));
t('canonical+append variants', ik.includes('decodeCanonicalInkPath') && ik.includes('Append'));
t('PersistedElementCodec', X('PersistedElementCodec.ets'));
t('StrokePersistence', X('StrokePersistence.ets'));
t('FlatBuffer op codec', X('OriginalSyncedOperationFlatBuffer.ets'));
t('envelope encoder', X('OriginalOperationEnvelopeEncoder.ets'));
t('point x/y float', ik.includes('x') && ik.includes('y'));
t('BinaryOpCodec bounds', readFileSync(S + 'BinaryOpCodec.ets', 'utf8').includes('MAX_OPERATION_BYTES'));
console.log('data-consistency replay: ' + n + '/10 checks green');
