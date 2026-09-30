// Phase 1188 — op payload readback (vq9/ka4/cee → uq9)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const vq9 = R('vq9.java');
t('vq9 extends cee implements ka4', vq9.includes('extends cee') && vq9.includes('implements ka4'));
t('vq9 k()→qo5 opId readback', vq9.includes('qo5 k()'));
t('vq9 binds byteBuffer to qo5', vq9.includes('qo5Var.b('));
t('vq9 l() reads slot 8', vq9.includes('c(8)'));
t('vq9 m()/n()→uq9 wrap', vq9.includes('uq9 m()') && vq9.includes('uq9 n('));
t('vq9 a()/j() field accessors', vq9.includes('String a()') && vq9.includes('Boolean j()'));
t('ka4 payload iface', R('ka4.java').includes('interface ka4'));
t('eg5 uq9 factory lambda', R('eg5.java').includes('uq9.class') && R('eg5.java').includes('invoke()'));
t('cee table base present', R('cee.java').length>0);
t('vq9 equals/hashCode', vq9.includes('equals') && vq9.includes('hashCode'));
console.log('op-readback replay: ' + n + '/10 checks green');
