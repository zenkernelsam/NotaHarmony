// Phase 1285 — GLMathNative + SharedMemoryByteArena
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/core/';
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const gn = R('glmath/GLMathNative.java');
t('GLMathNative loadLibrary glmath', gn.includes('loadLibrary("glmath")'));
t('nativeDraw latex→MathDrawTarget', gn.includes('nativeDraw(String latex') && gn.includes('MathDrawTarget'));
t('nativeMeasure latex→float[]', gn.includes('nativeMeasure(String latex'));
t('nativeInit resPath', gn.includes('nativeInit(String resPath'));
const gm = R('glmath/GLMathTextMeasurer.java');
t('GLMathTextMeasurer measure', gm.includes('measure(String text, String fontFile'));
const mdt = R('glmath/MathDrawTarget.java');
t('MathDrawTarget target iface', mdt.length > 0);
const a = R('common/memory/a.java');
t('arena SharedMemory.create', a.includes('SharedMemory.create'));
t('arena mapReadWrite ByteBuffer', a.includes('mapReadWrite') && a.includes('ByteBuffer Q'));
t('arena ReferenceQueue+ArenaClosed', a.includes('ReferenceQueue P') && a.includes('ArenaClosedException'));
t('arena alloc b(i)', a.includes('ByteBuffer b(int'));
console.log('native-math-sharedmem replay: ' + n + '/10 checks green');
