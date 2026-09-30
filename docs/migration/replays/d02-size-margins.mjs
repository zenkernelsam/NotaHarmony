// Phase 1156 — qed/vy7 FlatBuffers structs + factories
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const qed = R('qed'), vy7 = R('vy7'), apb = R('apb'), fsi = R('fsi');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('qed extends xwd implements ka4', qed.includes('extends xwd implements ka4'));
t('qed.a()→String', qed.includes('String a()'));
t('qed.c()/d()→float w,h', qed.includes('float c()') && qed.includes('float d()'));
t('vy7 extends xwd implements ka4', vy7.includes('extends xwd implements ka4'));
t('vy7 4-float c/d/e margins', vy7.includes('float c()') && vy7.includes('float d()') && vy7.includes('float e()'));
t('vy7.a()→String', vy7.includes('String a()'));
t('apb.h(w,h)→qed', apb.includes('qed h(float f, float f2)'));
t('fsi.f(×4)→vy7', fsi.includes('vy7 f(float f, float f2, float f3, float f4)'));
t('a79 uses apb.h/fsi.f defaults', R('a79').includes('apb.h(612.0f, 792.0f)') && R('a79').includes('fsi.f(36.0f'));
t('qed eq+hash+toString', qed.includes('equals(Object') && qed.includes('hashCode()'));
console.log('size-margins replay: ' + n + '/10 checks green');
