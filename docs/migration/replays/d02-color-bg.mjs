// Phase 1157 — hu1 Color + tu1 color facade + nz9 PageBackground
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const hu1 = R('hu1'), tu1 = R('tu1'), nz9 = R('nz9'), a79 = R('a79');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hu1 extends xwd implements ka4', hu1.includes('extends xwd implements ka4'));
t('hu1.a()→String', hu1.includes('String a()'));
t('hu1 RGBA byte c/d/e', hu1.includes('byte c()') && hu1.includes('byte d()') && hu1.includes('byte e()'));
t('tu1 color facade class', tu1.includes('abstract class tu1'));
t('tu1.a(float×4)→hu1 pack', tu1.includes('hu1 a(float f, float f2, float f3, float f4)'));
t('tu1.b(hu1)→int / c(int)→hu1', tu1.includes('int b(hu1') && tu1.includes('hu1 c(int i)'));
t('tu1 lazy default pce(ra(13))', tu1.includes('new pce(new ra(13))'));
t('nz9 PageBackground table (cee,ka4)', nz9.includes('extends cee implements ka4'));
t('nz9.a()→String', nz9.includes('String a()'));
t('a79.Q via vv7.f+fag.k+tu1.a', a79.includes('vv7.f(fag.k(null, null, null, (hu1) tu1.a.getValue()'));
console.log('color-bg replay: ' + n + '/10 checks green');
