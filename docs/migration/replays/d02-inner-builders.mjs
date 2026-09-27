// Phase 878 — u5j→*0j/baj 内层构造器映射回归
// 证据：docs/migration/evidence/phase-878-inner-builders.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const u5j = rd('u5j.java');
const r0j = rd('r0j.java');
const v0j = rd('v0j.java');
const x0j = rd('x0j.java');
const o0j = rd('o0j.java');
const baj = rd('baj.java');

// ---- u5j 委托点 ----
ok(u5j.includes('return r0j.a(list, lxcVarA, m2dVar, oz9Var);'), 'u5j.s -> r0j.a');
ok(u5j.includes('return r0j.a(list, lxcVar, m2dVar, oz9Var);'), 'u5j.t -> r0j.a');
ok(u5j.includes('return v0j.b(excVar, excVar2'), 'u5j.u -> v0j.b');
ok(u5j.includes('return x0j.a(list, true);'), 'u5j.v -> x0j.a writeAll=true');
ok(/return o0j\.a\(/.test(u5j), 'u5j.r -> o0j.a');
ok(u5j.includes('return baj.a(cz0Var, ty0.SQUARE'), 'u5j.f -> baj.a with SQUARE');
ok(u5j.includes('2883584'), 'u5j.f passes mask 2883584');
ok(u5j.includes('return haj.a(cxcVarB'), 'u5j.i -> haj.a');

// ---- r0j ge8 ----
ok(r0j.includes('public static ge8 a(List list, lxc lxcVar, m2d m2dVar, oz9 oz9Var)'),
  'r0j.a ge8 builder');
ok(r0j.includes('public static final int d(ge8 ge8Var, a aVar)'), 'r0j.d ge8 serializer');
ok(r0j.includes('Got negative length'), 'r0j negative-length guard');

// ---- v0j he8 ----
ok(v0j.includes('public static he8 b(exc excVar, exc excVar2'), 'v0j.b he8 builder');
ok(v0j.includes('public static final int d(he8 he8Var, a aVar)'), 'v0j.d he8 serializer');
ok(v0j.includes('Boolean bool, qo5 qo5Var'), 'v0j.b has extra Boolean slot');

// ---- x0j je8 ----
ok(x0j.includes('public static final je8 a(List list, boolean z)'), 'x0j.a je8 builder');

// ---- o0j wd8 ----
ok(o0j.includes('public static wd8 a(List list, cxc cxcVar'), 'o0j.a wd8 builder');
ok(o0j.includes('new tmf(xgbVar.I)'), 'o0j wraps xgb -> tmf');
ok(o0j.includes('rz1.i0(list2, null)'), 'o0j defensive copy list2');
ok(o0j.includes('jmf jmfVar3'), 'o0j jmf triple params');

// ---- baj rl2 ----
ok(baj.includes('public static rl2 a(cz0 cz0Var, ty0 ty0Var'), 'baj.a rl2 builder');
ok(baj.includes('(i & 262144) != 0 ? null : vy7Var'), 'baj mask bit18 -> vy7');
ok(baj.includes('(i & 524288) != 0 ? false : z4'), 'baj mask bit19 -> z4 false');
ok(baj.includes('(i & 1048576) != 0 ? false : z5'), 'baj mask bit20 -> z5 false');
ok(baj.includes('new tmf(xgbVar.I)'), 'baj wraps xgb -> tmf');

// ---- o0j 补丁应用器 ----
ok(o0j.includes('i != -771763713'), 'o0j.b magic 0xD1FFD1FF');
ok(o0j.includes('i2 != 4'), 'o0j.b version 4');
ok(o0j.includes('Patch file overrun'), 'o0j.b patch-overrun guard');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
