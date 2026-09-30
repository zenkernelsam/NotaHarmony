// Phase 1274 — cee/vq9/uq9/qo5 FlatBuffers tables
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const cee = R('cee.java');
t('cee Table ByteBuffer+bb_pos', cee.includes('ByteBuffer J') && cee.includes('int I'));
t('cee __offset/__string/__reset', cee.includes('int b(int') && cee.includes('String e(int') && cee.includes('void d(int'));
const uq9 = R('uq9.java');
t('uq9 extends cee ka4', uq9.includes('extends cee implements ka4'));
t('uq9 nested tmf/haa/sdf', uq9.includes('tmf') && uq9.includes('haa') && uq9.includes('sdf'));
t('uq9 qo5 entity + long ts', uq9.includes('qo5') && uq9.includes('long k('));
const qo5 = R('qo5.java');
t('qo5 extends xwd ka4 ID', qo5.includes('extends xwd implements ka4'));
t('qo5 String+short+int', qo5.includes('String a()') && qo5.includes('short c()') && qo5.includes('int d()'));
const vq9 = R('vq9.java');
t('vq9 payload→uq9', vq9.includes('extends cee implements ka4') && vq9.includes('uq9'));
const xwd = R('xwd.java'), zq6 = R('zq6.java');
t('xwd Struct base', xwd.length > 0);
t('zq6 factory i()', zq6.includes('zq6 i(') || /static\s+zq6\s+i\(/.test(zq6));
console.log('flatbuffers-tables replay: ' + n + '/10 checks green');
