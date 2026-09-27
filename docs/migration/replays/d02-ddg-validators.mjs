// Phase 895 — ddg 校验助手全集回归
// 证据：docs/migration/evidence/phase-895-ddg-validators.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ddg = rd('ddg.java');
const qed = rd('qed.java');
const vy7 = rd('vy7.java');
const fqa = rd('fqa.java');

// ---- ddg 助手 ----
ok(ddg.includes('Math.abs(f - f2) < 1.0E-4f'), 'ddg.a epsilon 1e-4');
ok(ddg.includes('Cannot be infinite') && ddg.includes('Cannot be NaN'),
  'ddg.d finite rules');
ok(ddg.includes('width must be non-negative') &&
   ddg.includes('height must be non-negative'), 'ddg.i size>=0');
ok(ddg.includes('Scale invalid'), 'ddg.j scale check');
ok(ddg.includes('public static final String k(ka4 ka4Var, String str)'),
  'ddg.k ka4 label delegate');
ok(ddg.includes('l("x", fqaVar.c())') && ddg.includes('l("y", fqaVar.d())'),
  'ddg.h point x/y');
ok(ddg.includes('CenterPath full path error'), 'ddg.m centerPath rule');
ok(ddg.includes('Non-empty styleMap must have one entry per moveto path element in centerpath'),
  'ddg.m styleMap-per-moveto rule');
ok(ddg.includes('Error decoding centerPath'), 'ddg.m decode error wrap');
ok(ddg.includes('l("Rotation"'), 'ddg.e rotation check');
ok(ddg.includes('public static final String o(cxc cxcVar, fqa fqaVar)'),
  'ddg.o pos+point pair check');
ok(ddg.includes('fa2.B(str, ": ", strA)'), 'ddg.k label prefix format');

// ---- ka4 实现者扩展 ----
ok(qed.includes('implements ka4') || qed.includes('String a()'),
  'qed is ka4');
ok(vy7.includes('implements ka4') || vy7.includes('String a()'),
  'vy7 is ka4');
ok(fqa.includes('implements ka4') || fqa.includes('String a()'),
  'fqa is ka4');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
