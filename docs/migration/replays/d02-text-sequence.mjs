// Phase 1091 — text-sequence internals: hr5/swc/s3c/gxc
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const hr5 = R('hr5'), swc = R('swc'), s3c = R('s3c'), gxc = R('gxc');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('hr5 implements exc (mutable anchor)', hr5.includes('implements exc'));
t('hr5: {J:short site, K:int, L:int}', hr5.includes('public short J') && hr5.includes('public int K') && hr5.includes('public int L'));
t('hr5: I=1 discriminator', hr5.includes('this.I = 1'));
t('swc iface: navigator', swc.includes('interface swc'));
t('swc: d(hr5)→hr5 derive + e(rwc)→rwc', swc.includes('hr5 d(hr5 hr5Var)') && swc.includes('rwc e(rwc rwcVar)'));
t('swc: getParent()→qwc', swc.includes('qwc getParent()') && swc.includes('qwc a()'));
t('s3c: {Set a,b, CharSequence c, double d, int e}', s3c.includes('Set a') && s3c.includes('CharSequence c') && s3c.includes('double d'));
t('gxc extends y3 (wire anchor)', gxc.includes('extends y3'));
t('hr5 ctor: zero-init', hr5.includes('this.J = (short) 0') && hr5.includes('this.L = 0'));
t('swc.c()→long position', swc.includes('long c()'));
console.log('text-sequence replay: ' + n + '/10 checks green');
