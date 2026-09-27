// Phase 887 — 叶级字段序列化器回归
// 证据：docs/migration/evidence/phase-887-leaf-serializers.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const apb = rd('apb.java');
const fsi = rd('fsi.java');
const rh8 = rd('rh8.java');
const fag = rd('fag.java');
const j7j = rd('j7j.java');
const vv7 = rd('vv7.java');

// ---- qed 8B ----
ok(apb.includes('public static final int Z(qed qedVar, a aVar)') ||
   apb.includes('int Z(qed'), 'apb.Z qed serializer');
ok(apb.includes('aVar.t(4, 8)') && apb.includes('aVar.v(fC)') && apb.includes('aVar.v(fD)'),
  'apb.Z prep(4,8) + 2 floats');
ok(apb.includes('float fD = qedVar.d()') && apb.includes('float fC = qedVar.c()'),
  'qed accessors c()/d()');

// ---- vy7 16B ----
ok(fsi.includes('int b0(vy7') || /b0\(vy7 vy7Var, a aVar\)/.test(fsi), 'fsi.b0 vy7 serializer');
ok(fsi.includes('aVar.t(4, 16)') && fsi.includes('aVar.v(fE)') && fsi.includes('aVar.v(fD)') &&
   fsi.includes('aVar.v(fC)') && fsi.includes('aVar.v(f)'),
  'fsi.b0 prep(4,16) + 4 floats');
ok(fsi.includes('float fE = vy7Var.e()'), 'vy7.e() accessor');

// ---- qo5 8B ----
ok(rh8.includes('int O(qo5'), 'rh8.O qo5 serializer');
ok(rh8.includes('short sC = qo5Var.c()') && rh8.includes('int iD = qo5Var.d()') &&
   /aVar\.t\(4, 8\)[\s\S]{0,80}aVar\.w\(iD\)[\s\S]{0,80}aVar\.s\(2\)[\s\S]{0,80}aVar\.y\(sC\)/.test(rh8),
  'rh8.O prep(4,8) int+pad2+short = {site,pad,timestamp}');
ok(rh8.includes('public static qo5 b(int i, short s)'), 'rh8.b qo5 ctor');

// ---- cxc 12B vs qo5 8B 分层 ----
ok(rd('nti.java').includes('aVar.t(4, 12)'), 'cxc 12B (vs qo5 8B)');

// ---- k3a 六访问器 ----
ok(fag.includes('o0(aVar, k3aVar.k(), k3aVar.n(), k3aVar.l(), k3aVar.m(), k3aVar.j(), k3aVar.o())'),
  'k3a six accessors -> fag.o0');

// ---- sw9 资产+向量 ----
ok(j7j.includes('int iC = k1j.c(wa0VarM, aVar)') && j7j.includes('aVar.D(8, iK, 4)'),
  'sw9 = wa0 + 8B-elem struct vector');
ok(j7j.includes('zwd.a((xwd)'), 'sw9 elements via zwd.a(xwd)');
ok(j7j.includes('Got negative length'), 'sw9 negative-length guard');

// ---- vv7.M 委托 ----
ok(vv7.includes('apb.Z(qedVar, aVar)') && vv7.includes('fsi.b0(vy7Var, aVar)') &&
   vv7.includes('fag.n0(k3aVar, aVar)') && vv7.includes('j7j.c(sw9Var, aVar)'),
  'vv7.M delegates to all four leaf writers');

// ---- 构造器 ----
ok(apb.includes('apb.h') || /public static.*h\(/.test(apb), 'apb.h qed ctor present');
ok(fsi.includes('fsi.f') || /static.* f\(float f, float f2, float f3, float f4\)/.test(fsi),
  'fsi.f 4-float ctor present');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
