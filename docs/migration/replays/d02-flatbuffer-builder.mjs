// Phase 892 — a=FlatBufferBuilder 原语 + hu1=Color 回归
// 证据：docs/migration/evidence/phase-892-flatbuffer-builder.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const FB = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/google/flatbuffers';
const DEF = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };

const a = readFileSync(join(FB, 'a.java'), 'utf8');
const hu1 = readFileSync(join(DEF, 'hu1.java'), 'utf8');
const k1j = readFileSync(join(DEF, 'k1j.java'), 'utf8');
const j7j = readFileSync(join(DEF, 'j7j.java'), 'utf8');

// ---- 原语语义 ----
ok(a.includes('public final void C(int i)'), 'C = startTable');
ok(a.includes('must not be nested'), 'C/D nested guard');
ok(a.includes('public final void D(int i, int i2, int i3)'), 'D = startVector');
ok(a.includes('this.k = i2'), 'D stores count');
ok(a.includes('public final int n()'), 'n = endTable');
ok(a.includes('endTable called without startTable'), 'n startTable guard');
ok(a.includes('public final void z(int i, int i2)'), 'z = required');
ok(a.includes(' must be set'), 'z required error');
ok(a.includes('public final void a(int i, boolean z, boolean z2)'),
  'a = addBoolean');
ok(a.includes('this.d[i] = r()'), 'B = slot record');

// ---- required 公式 4+2i 验证 ----
ok(k1j.includes('aVar.z(iN, 4)') && k1j.includes('aVar.z(iN, 6)') &&
   k1j.includes('aVar.z(iN, 8)'), 'wa0 required = f0/1/2');
ok(j7j.includes('aVar.z(iN2, 4)') && j7j.includes('aVar.z(iN2, 14)'),
  'sw9 required = f0/5');
ok(!j7j.includes('aVar.z(iN2, 6)') && !j7j.includes('aVar.z(iN2, 8)') &&
   !j7j.includes('aVar.z(iN2, 10)') && !j7j.includes('aVar.z(iN2, 12)'),
  'sw9 f1-4 not required');

// ---- hu1 = Color ----
ok(hu1.includes('public final class hu1 extends xwd implements ka4'),
  'hu1 xwd struct');
ok(hu1.includes('Color(bitsR='), 'hu1 toString = Color');
ok(hu1.includes('bitsG=') && hu1.includes('bitsB=') && hu1.includes('bitsA='),
  'hu1 RGBA four channels');
ok(hu1.includes('public final byte c()') && hu1.includes('public final byte d()') &&
   hu1.includes('public final byte e()') && hu1.includes('public final byte f()'),
  'hu1 four byte accessors');
ok(hu1.includes('cmf.a(f())'), 'hu1 unsigned byte format via cmf.a');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
