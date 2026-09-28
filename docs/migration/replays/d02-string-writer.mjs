// Phase 971 — dbj.c 字符串双路径 + v71 零拷贝 + a.m byte-vector
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const FB = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/google/flatbuffers';
const dbj = readFileSync(`${ROOT}/dbj.java`, 'utf8');
const v71 = readFileSync(`${ROOT}/v71.java`, 'utf8');
const a = readFileSync(`${FB}/a.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// dbj.c two-path dispatch
ok(/static final int c\(CharSequence charSequence, a aVar\)/.test(dbj), 'dbj.c = string writer');
ok(/!\(charSequence instanceof v71\)/.test(dbj), 'dbj: v71 instanceof check');
ok(/return aVar\.l\(charSequence\)/.test(dbj), 'dbj: plain -> a.l (UTF-8 encode)');
ok(/sg5\.b\.get\(\)/.test(dbj), 'dbj: sg5.b pooled ByteBuffer');
ok(/\(\(v71\) charSequence\)\.f\(byteBuffer\)/.test(dbj), 'dbj: v71.f(bb) into pooled buffer');
ok(/\(\(v71\) charSequence\)\.e\(\)/.test(dbj), 'dbj: v71.e() fallback');
ok(/aVar\.m\(byteBuffer/.test(dbj), 'dbj: a.m byte-vector write');

// v71 = ByteBufferBackedCharSequence raw UTF-8 view
ok(/ByteBuffer f\(ByteBuffer byteBuffer\)/.test(v71) && /ByteBuffer e\(\)/.test(v71), 'v71: e()/f(bb) return UTF-8 buffer');
ok(/ByteBufferBackedCharSequence is a raw-UTF-8-bytes view/.test(v71), 'v71: raw-UTF-8 bulk-copy doc');

// a.m = createByteVector: NUL + D(1,len,1) + put + o()
ok(/int m\(ByteBuffer byteBuffer\)[\s\S]{0,120}b\(\(byte\) 0\)/.test(a), 'a.m: NUL terminator first');
ok(/D\(1, iRemaining, 1\)/.test(a), 'a.m: D(1,len,1) byte vector');
ok(/this\.a\.put\(byteBuffer\)/.test(a), 'a.m: bulk put(bb)');
ok(/this\.a\.put\(byteBuffer\)[\s\S]{0,40}return o\(\)/.test(a), 'a.m: ends with o()');

// a.l uses zq6 utf8 helper + ASCII fast path
ok(/zq6 zq6Var = this\.n/.test(a), 'a.l: zq6 utf8 helper');
ok(/charSequence\.charAt\(i5\) < 128/.test(a), 'a.l: ASCII fast-path scan');

console.log(`\nstring-writer replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
