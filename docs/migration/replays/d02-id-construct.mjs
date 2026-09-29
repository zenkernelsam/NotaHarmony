// Phase 1099 — rh8.b opId pipeline + rh8.a float-pack + au1.c1
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const rh8 = R('rh8'), au1 = R('au1');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('rh8.b(int,short)→qo5 ctor', rh8.includes('qo5 b(int i, short s)'));
t('rh8.b: dk4.a builder pool', rh8.includes('dk4.a(c8dVar)'));
t('rh8.b: writes 8B struct t(4,8)+w+s+y', rh8.includes('t(4, 8)') && rh8.includes('aVarA.w(i)') && rh8.includes('aVarA.y(s)'));
t('rh8.b: LITTLE_ENDIAN wrap', rh8.includes('ByteOrder.LITTLE_ENDIAN'));
t('rh8.b: qo5.b(pos,bb) bind', rh8.includes('qo5Var.b(byteBufferWrap.getInt'));
t('rh8.b: ybg.c validate', rh8.includes('ybg.c(qo5Var)'));
t('rh8.b: q(c8d) recycle builder', rh8.includes('q(c8dVar, null)'));
t('rh8.a(f,f)→long float-pack', rh8.includes('long a(float f, float f2)') && rh8.includes('floatToRawIntBits'));
t('rh8.a: f2 low | f1 high', rh8.includes('& 4294967295L') && rh8.includes('<< 32'));
t('au1.c1(List)=first() + empty error', au1.includes('c1(List list)') && au1.includes('List is empty'));
console.log('id-construct replay: ' + n + '/10 checks green');
