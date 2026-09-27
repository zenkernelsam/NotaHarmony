// Phase 899 — ie8=ModifyPosition(type24)+tmf=ULong 回归
// 证据：docs/migration/evidence/phase-899-modifyposition-ie8.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ie8 = rd('ie8.java');
const k2d = rd('k2d.java');
const y2d = rd('y2d.java');
const tmf = rd('tmf.java');
const w0j = rd('w0j.java');
const x0j = rd('x0j.java');
const ddg = rd('ddg.java');

// ---- ie8 = ModifyPosition ----
ok(ie8.includes('ModifyPosition(target='), 'ie8 toString = ModifyPosition');
ok(ie8.includes('public final qo5 n()') && ie8.includes('public final cxc k()') &&
   ie8.includes('public final fqa j()'), 'ie8 target/page/origin accessors');
ok(ie8.includes('public final k2d l()') && ie8.includes('public final y2d m()') &&
   ie8.includes('public final tmf o()'), 'ie8 rotation/scale/zIndex accessors');
ok(x0j.includes('new q5(24, (ie8)'), 'ie8 = payload type 24');
ok(w0j.includes('public static ie8 a(qo5 qo5Var, cxc cxcVar, fqa fqaVar, k2d k2dVar, y2d y2dVar, xgb xgbVar, int i)'),
  'w0j.a factory 7-arg+mask');
ok(w0j.includes('public static final int d(ie8 ie8Var, a aVar)'),
  'w0j.d serializer');
ok(w0j.includes('ybg.c(ie8Var)'), 'w0j post-parse ybg.c validation');

// ---- setters ----
ok(k2d.includes('SetFloat(value='), 'k2d = SetFloat');
ok(y2d.includes('SetSize(value='), 'y2d = SetSize');

// ---- ddg.e validation map ----
ok(ddg.includes('o(ie8Var.k(), ie8Var.j())'), 'ddg.e pos+origin pair');
ok(ddg.includes('l("Rotation", fJ.floatValue())'), 'ddg.e rotation check');
ok(ddg.includes('j(qedVarJ)'), 'ddg.e scale check');

// ---- tmf = ULong ----
ok(tmf.includes('public final class tmf implements Comparable') &&
   tmf.includes('public final long I'), 'tmf long value class');
ok(tmf.includes('njj.h0(this.I'), 'tmf unsigned long compare');
ok(tmf.includes('njj.j0(10, this.I)'), 'tmf unsigned format radix10');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
