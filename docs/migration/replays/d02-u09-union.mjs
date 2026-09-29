// Phase 1076 — u09 six-variant id union + fsi.D/E destructurers
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const fsi = R('fsi'), p09 = R('p09'), s09 = R('s09'), t09 = R('t09'), q09 = R('q09'), tz9 = R('tz9');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('p09 implements u09 + qo5', p09.includes('implements u09') && p09.includes('qo5 b'));
t('s09 implements u09 + ua0 (asset-hash)', s09.includes('implements u09') && s09.includes('ua0 b'));
t('t09 implements u09 + qo5 (tombstone)', t09.includes('implements u09') && t09.includes('qo5 b'));
t('q09 implements u09 (unit)', q09.includes('implements u09'));
t('tz9: page-ref wraps cxc', tz9.includes('cxc a'));
t('fsi.D: extracts entity ids from F()', fsi.includes('ArrayList D(uq9') && fsi.includes('instanceof o09'));
t('fsi.D: skips t09/r09/q09/s09', fsi.includes('instanceof t09') && fsi.includes('instanceof s09'));
t('fsi.E: r09→tz9 page refs', fsi.includes('ArrayList E(uq9') && fsi.includes('new tz9(cxcVar)'));
t('fsi.D/E: o14.t() unreachable', (fsi.match(/o14\.t\(\)/g) || []).length >= 2);
t('fsi: F feeds D and E', fsi.includes('List<u09> listF = F(uq9Var)'));
console.log('u09-union replay: ' + n + '/10 checks green');
