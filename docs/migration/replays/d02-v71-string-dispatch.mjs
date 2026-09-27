// Phase 901 — dbj.c 字符串写派发 + v71 回归
// 证据：docs/migration/evidence/phase-901-v71-string-dispatch.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const FB = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/google/flatbuffers';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const dbj = rd('dbj.java');
const v71 = rd('v71.java');
const a = readFileSync(join(FB, 'a.java'), 'utf8');
const k1j = rd('k1j.java');
const sg5 = rd('sg5.java');

// ---- dbj.c 派发 ----
ok(dbj.includes('public static final int c(CharSequence charSequence, a aVar)'),
  'dbj.c(CharSequence,builder)');
ok(dbj.includes('!(charSequence instanceof v71)'), 'dbj.c v71 dispatch');
ok(dbj.includes('aVar.l(charSequence)'), 'dbj.c plain -> builder.l');
ok(dbj.includes('aVar.m(byteBuffer'), 'dbj.c v71 -> builder.m raw');
ok(dbj.includes('sg5.b.get()'), 'dbj.c ThreadLocal scratch');

// ---- v71 ByteBufferBackedCharSequence ----
ok(v71.includes('public interface v71 extends CharSequence'),
  'v71 CharSequence interface');
ok(v71.includes('UnsupportedOperationException') &&
   v71.includes('raw-UTF-8-bytes view for bulk copy'),
  'v71 raw-byte view contract');
ok(v71.includes('ByteBuffer e()') && v71.includes('ByteBuffer f(ByteBuffer byteBuffer)'),
  'v71 e()/f(bb) buffer accessors');

// ---- builder l/m 原语 ----
ok(a.includes('public final int l(CharSequence charSequence)'),
  'builder.l = createString');
ok(a.includes('public final int m(ByteBuffer byteBuffer)'),
  'builder.m = raw byte string');

// ---- 使用点 ----
ok(k1j.includes('dbj.c(strK, aVar)') && k1j.includes('dbj.c(strM, aVar)'),
  'wa0 strings via dbj.c');
ok(sg5.includes('b'), 'sg5 ThreadLocal holder exists');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
