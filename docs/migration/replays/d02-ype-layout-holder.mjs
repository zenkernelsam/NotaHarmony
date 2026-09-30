// Phase 1219 — ype layout-geometry holder
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ype = R('ype.java');
t('ype yme x2 layout state', ype.includes('yme a') && ype.includes('yme b'));
t('ype p6a x4 LayoutCoordinates', (ype.match(/p6a [c-f]/g)||[]).length>=4);
t('ype q21 callback queue', ype.includes('q21 g'));
t('ype.c()->wpe', ype.includes('wpe c()'));
t('ype.d position->offset', ype.includes('int d(long') && ype.includes('wpeVarC.b.j'));
t('ype.b/e mv6 coords', ype.includes('mv6 b()') && ype.includes('mv6 e()'));
t('ype.a clips via mv6.J', ype.includes('mv6VarB.J(mv6VarE, true)'));
t('ype.f in-bounds', ype.includes('boolean f(long'));
const q21 = R('q21.java');
t('q21 r21[16] listener array', q21.includes('r21[16]') || q21.includes('new r21['));
t('q21 high-bit dispatch flag', q21.includes('-2147483648') || q21.includes('& r2'));
console.log('ype-layout-holder replay: ' + n + '/10 checks green');
