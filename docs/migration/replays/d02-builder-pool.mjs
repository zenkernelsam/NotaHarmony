// Phase 1100 — dk4/cz8 builder pool + c8d SharedMemory arena + qo5 semantics
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const dk4 = R('dk4'), c8d = R('c8d'), qo5 = R('qo5'), ra = R('ra'), ck4 = R('ck4');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('dk4.b = cz8(ra(28), ck4.P)', dk4.includes('new cz8(new ra(28), ck4.P)'));
t('dk4.a(c8d): x82.x holder → new a(c8d,bb)', dk4.includes('x82.x(b, a[0])') && dk4.includes('new a(c8dVar, (ByteBuffer)'));
t('ra(28): 16KB LITTLE_ENDIAN buffer', ra.includes('ByteBuffer.allocate(16384).order(ByteOrder.LITTLE_ENDIAN)'));
t('ck4.P = ByteBuffer::clear', ck4.includes('ByteBuffer.class') && ck4.includes('"clear"') && ck4.includes('byteBuffer.clear()'));
t('c8d extends ldj AutoCloseable', c8d.includes('extends ldj implements AutoCloseable'));
t('c8d: k1a{ByteBuffer,SharedMemory} list', c8d.includes('SharedMemory') && c8d.includes('k1a'));
t('c8d.close: unmap+close', c8d.includes('SharedMemory.unmap') && c8d.includes('sharedMemory.close()'));
t('qo5: d()=timestamp c()=site', qo5.includes('short c()') && qo5.includes('int d()'));
t('qo5 eq both fields', qo5.includes('d() == qo5Var.d() && c() == qo5Var.c()'));
t('qo5 toString Id(site,timestamp)', qo5.includes('Id(site=') && qo5.includes('timestamp='));
console.log('builder-pool replay: ' + n + '/10 checks green');
