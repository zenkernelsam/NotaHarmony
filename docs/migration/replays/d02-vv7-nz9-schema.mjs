// Phase 886 — vv7/nz9 页背景构造与序列化回归
// 证据：docs/migration/evidence/phase-886-vv7-nz9-schema.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const vv7 = rd('vv7.java');
const a79 = rd('a79.java');

// ---- vv7.M 五字段写侧 ----
ok(vv7.includes('public static final int M(a aVar, k3a k3aVar, sw9 sw9Var, Float f, qed qedVar, vy7 vy7Var)'),
  'vv7.M field-writer signature');
ok(vv7.includes('aVar.C(5)'), 'nz9 C(5) fields');
ok(vv7.includes('Integer.valueOf(fag.n0(k3aVar, aVar))'), 'f0 k3a via fag.n0');
ok(vv7.includes('Integer.valueOf(j7j.c(sw9Var, aVar))'), 'f1 sw9 via j7j.c');
ok(vv7.includes('aVar.d(2, f.floatValue(), 0.0d)'), 'f2 float default 0.0');
ok(vv7.includes('aVar.j(3, apb.Z(qedVar, aVar))'), 'f3 qed via apb.Z');
ok(vv7.includes('aVar.j(4, fsi.b0(vy7Var, aVar))'), 'f4 vy7 via fsi.b0');

// ---- vv7.L 再序列化器 ----
ok(vv7.includes('public static final int L(nz9 nz9Var, a aVar)'), 'vv7.L reserializer');
ok(vv7.includes('nz9Var.k(), nz9Var.l(), Float.valueOf(nz9Var.m()), nz9Var.n(), nz9Var.j()'),
  'vv7.L maps k3a/sw9/float/qed/vy7 accessors');

// ---- vv7.f 存根 ----
ok(vv7.includes('public static nz9 f(k3a k3aVar, sw9 sw9Var, Float f, qed qedVar, vy7 vy7Var, int i)'),
  'vv7.f stub signature');
ok(/\(i & 1\) != 0\) \{\s*k3aVar = null/.test(vv7), 'mask bit0 -> k3a null');
ok(/\(i & 2\) != 0\) \{\s*sw9Var = null/.test(vv7), 'mask bit1 -> sw9 null');
ok(/\(i & 4\) != 0\) \{\s*f = null/.test(vv7), 'mask bit2 -> float null');
ok(/\(i & 8\) != 0\) \{\s*qedVar = null/.test(vv7), 'mask bit3 -> qed null');
ok(vv7.includes('(i & 16) != 0 ? null : vy7Var'), 'mask bit4 -> vy7 null');
ok(vv7.includes('aVarA.p(M(aVarA, k3aVar2, sw9Var2, f2, qedVar2, vy7Var2))'),
  'vv7.f delegates to M');
ok(vv7.includes('ybg.c(nz9Var)'), 'vv7.f ybg.c validation');

// ---- a79.Q 默认背景 ----
ok(a79.includes('vv7.f(fag.k(null, null, null, (hu1) tu1.a.getValue(), null, 111), null, null, qedVarH, null, 54)'),
  'a79.Q = vv7.f(tu1 paper, Letter, mask 54)');

// ---- vv7.N 收集器 ----
ok(vv7.includes('public static final ArrayList N(x09 x09Var)') &&
   vv7.includes('a79Var.J') && vv7.includes('a79Var.D'),
  'vv7.N collects backgrounds from a79.J/D');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
