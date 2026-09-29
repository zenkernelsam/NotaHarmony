// Phase 1117 — v71 byte-funnel CharSequence + uq9 op accessors
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const v71 = R('v71'), uq9 = R('uq9'), sg5 = R('sg5');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('v71 = ByteBufferBackedCharSequence iface', v71.includes('interface v71 extends CharSequence'));
t('v71: chars throw "raw-UTF-8-bytes view"', v71.includes('raw-UTF-8-bytes view for bulk copy'));
t('v71: e()+f(bb) ByteBuffer', v71.includes('ByteBuffer e()') && v71.includes('ByteBuffer f(ByteBuffer'));
t('v71: not readable as chars', v71.includes('not readable as chars'));
t('uq9 extends cee implements ka4', uq9.includes('extends cee implements ka4'));
t('uq9.l()→qo5 id via p()', uq9.includes('qo5 l()') && uq9.includes('p(qo5Var)'));
t('uq9.j()→tmf + k()→long', uq9.includes('tmf j()') && uq9.includes('long k()'));
t('uq9 eq on m()+l()', uq9.includes('m() != uq9Var.m()') && uq9.includes('l().equals(uq9Var.l())'));
t('uq9 hashCode id+type*31', uq9.includes('hashCode() + (m().hashCode() * 31)'));
t('sg5.b ThreadLocal + holder registry', sg5.includes('ThreadLocal b = new ThreadLocal()') && sg5.includes('OP_HOLDER') && sg5.includes('ID_HOLDER'));
console.log('byte-funnel replay: ' + n + '/10 checks green');
