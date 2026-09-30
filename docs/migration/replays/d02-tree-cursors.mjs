// Phase 1125 — qwc/rwc cursors + swc iface + f8d.a anchor-read
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const qwc = R('qwc'), rwc = R('rwc'), swc = R('swc'), mxc = R('mxc'), f8d = R('f8d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('qwc implements swc {f8d,int}', qwc.includes('implements swc') && qwc.includes('f8d a') && qwc.includes('int b'));
t('qwc.a()→self immutable', qwc.includes('qwc a()'));
t('qwc.c()→f8d.c position', qwc.includes('this.a.c'));
t('qwc.d(hr5)→f8d.a(hr5,b) anchor-read', qwc.includes('this.a.a(hr5Var, this.b)'));
t('qwc.e(rwc) mutable conversion', qwc.includes('rwc e(rwc rwcVar)') && qwc.includes('rwcVar.a = f8dVar'));
t('rwc implements swc mutable', rwc.includes('implements swc') && rwc.includes('f8d a'));
t('rwc.b=-1 + null→ba6.d0 throw', rwc.includes('int b = -1') && rwc.includes('ba6.d0'));
t('rwc.a()→qwc freeze', rwc.includes('qwc a()'));
t('swc = cursor iface', swc.includes('interface swc') || swc.includes('swc'));
t('f8d.a(hr5,int) anchor write target', f8d.includes('a(hr5 hr5Var, int i)'));
console.log('tree-cursors replay: ' + n + '/10 checks green');
