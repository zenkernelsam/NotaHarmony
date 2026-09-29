// Phase 1040 — ID type taxonomy (ttf/utf/qo5/xwd)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ttf = readFileSync(D + 'ttf.java', 'utf8');
const utf = readFileSync(D + 'utf.java', 'utf8');
const qo5 = readFileSync(D + 'qo5.java', 'utf8');
const xwd = readFileSync(D + 'xwd.java', 'utf8');
const ka4 = readFileSync(D + 'ka4.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ttf: Comparable+Serializable UUID', ttf.includes('implements Comparable') && ttf.includes('Serializable'));
t('ttf: {long I,J} = msb,lsb', /public final long I;/.test(ttf) && /public final long J;/.test(ttf));
t('ttf: zero sentinel K', ttf.includes('new ttf(0, 0)'));
t('ttf.toString: 8-4-4-4-12', ttf.includes('xag.c(') && ttf.includes('bArr[8] = 45') && ttf.includes('bArr[18] = 45'));
t('xwd: FlatBuffer struct base', /public int I;/.test(xwd) && /public ByteBuffer J;/.test(xwd) && xwd.includes('public final void b(int i, ByteBuffer'));
t('utf extends xwd+ka4', utf.includes('extends xwd') && utf.includes('implements ka4'));
t('qo5 extends xwd+ka4', qo5.includes('extends xwd') && qo5.includes('implements ka4'));
t('qo5: site/logicalTime', qo5.includes('public final short c()') && qo5.includes('public final int d()'));
t('ka4: {a()→String} iface', ka4.includes('a()') || ka4.includes('String a('));
const gk4 = readFileSync(D + 'gk4.java', 'utf8');
t('gk4: qo5 pack/unpack', gk4.includes('qo5') && (gk4.includes('<< 32') || gk4.includes('>> 32')));
console.log('id-types replay: ' + n + '/10 checks green');
