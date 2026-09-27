// Phase 884 — ye9/led/ttf 标识层回归
// 证据：docs/migration/evidence/phase-884-note-identity.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const HARM = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ttf = rd('ttf.java');
const led = rd('led.java');
const ye9 = rd('ye9.java');
const tzc = rd('tzc.java');

// ---- ttf = UUID 值类 ----
ok(ttf.includes('public final class ttf implements Comparable, Serializable'),
  'ttf = Comparable Serializable value class');
ok(ttf.includes('public final long I') && ttf.includes('public final long J'),
  'ttf {I,J:long} 128-bit');
ok(ttf.includes('public static final ttf K = new ttf(0, 0)'), 'ttf.K = NIL UUID');
ok(ttf.includes('public ttf(long j, long j2)'), 'ttf ctor (long,long)');
ok(ttf.includes('byte[] bArr = new byte[16]'), 'ttf.a() -> 16B big-endian');
ok(/\(this\.I >> \(i3 << 3\)\)/.test(ttf), 'ttf.a() I big-endian bytes');
ok(ttf.includes('byte[] bArr = new byte[36]') && ttf.includes("bArr[8] = 45"),
  'ttf.toString = 36-char UUID with - separators');
ok(ttf.includes('xag.c(this.I'), 'ttf hex via xag.c');

// ---- led = site 值类 ----
ok(led.includes('public final class led') && led.includes('public final short a'),
  'led = {a:short} site wrapper');
ok(led.includes('return a(this.a);'), 'led.toString = a(short) format');

// ---- ye9 接口 ----
ok(ye9.includes('public interface ye9'), 'ye9 = interface');
ok(ye9.includes('ttf c();') && ye9.includes('led d();'),
  'ye9.c()->ttf, ye9.d()->led');

// ---- tzc 派生 ----
ok(tzc.includes('led ledVarD = ye9Var.d()') && tzc.includes('this.O = s;') &&
   tzc.includes('short s = ledVarD.a;'), 'tzc.O = ye9.d().a');
ok(tzc.includes('ttf ttfVarC = ye9Var.c()'), 'tzc reads ye9.c() -> ttf');

// ---- sxe k1a 目标 ----
ok(rd('sxe.java').includes('new o69(ttfVarR0)'), 'sxe wraps ttf in o69 for k1a');

// ---- Harmony 16B UUID ----
const ident = readFileSync(join(HARM, 'OriginalNoteBundlePageIdentity.ets'), 'utf8');
ok(ident.includes('readInlineBytes(0, 16)'), 'Harmony reads 16B inline uuid @f0');
ok(ident.includes('decodeOriginalUuid'), 'Harmony decodeOriginalUuid');
ok(ident.includes('originalNoteIdsMatch'), 'Harmony uuid compare helper');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
