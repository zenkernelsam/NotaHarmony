// Phase 995 — uq9 envelope reader: 7-field accessor map + haa bounds fallback
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const uq9 = readFileSync(`${ROOT}/uq9.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// class shape
ok(/class uq9 extends cee implements ka4/.test(uq9), 'uq9 extends cee implements ka4');

// f0 id — required inline struct
ok(/public final qo5 p\(qo5 qo5Var\)[\s\S]{0,160}c\(4\)/.test(uq9), 'uq9.p: id @slot4');
ok(/if \(iC == 0\)[\s\S]{0,60}No value for \(required\) field id/.test(uq9), 'uq9.p: required-id guard');
ok(/qo5Var\.b\(i, byteBuffer\)/.test(uq9), 'uq9.p: qo5.b inline-struct init');
ok(/public final qo5 l\(\)[\s\S]{0,80}p\(qo5Var\)/.test(uq9), 'uq9.l() = p(new qo5)');

// f1 clientTime long
ok(/public final long k\(\)[\s\S]{0,120}c\(6\)/.test(uq9), 'uq9.k: clientTime @slot6 default 0');

// f2 serverTime / f3 audioTime — nullable tmf
ok(/public final tmf n\(\)[\s\S]{0,140}c\(8\)/.test(uq9), 'uq9.n: serverTime @slot8 nullable');
ok(/public final tmf j\(\)[\s\S]{0,140}c\(10\)/.test(uq9), 'uq9.j: audioTime @slot10 nullable');

// f4 payloadType byte -> haa with bounds fallback
ok(/public final haa m\(\)[\s\S]{0,400}c\(12\)/.test(uq9), 'uq9.m: payloadType @slot12');
ok(/\(b & 255\) - \(\(\(haa\) nz3Var\.get\(0\)\)\.I & 255\)/.test(uq9), 'uq9.m: byte - NONE.ordinal delta');
ok(/\(i < 0 \|\| i >= nz3Var\.d\(\)\) \? \(haa\) nz3Var\.get\(0\)/.test(uq9), 'uq9.m: out-of-range -> NONE');

// f5 payload / f6 transient — already pinned (993) re-assert
ok(/int iC = c\(14\) \+ this\.I/.test(uq9), 'uq9.q: payload @slot14');
ok(/int iC = c\(16\);\s*if \(iC == 0\)[\s\S]{0,40}return null/.test(uq9), 'uq9.r: transient @slot16 nullable');

console.log(`\nuq9-envelope-reader replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
