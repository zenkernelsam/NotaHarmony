// Phase 910 — wd8=ModifyInk 19 字段读图回归
// 证据：docs/migration/evidence/phase-910-modifyink-wd8.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const wd8 = rd('wd8.java');

ok(wd8.includes('ModifyInk(inks='), 'wd8 toString = ModifyInk');
ok(wd8.includes('inkEffectsTinted=') && wd8.includes('tapePattern=') &&
   wd8.includes('styleMap='), 'wd8 19 named fields');

ok(wd8.match(/void B\(qo5 qo5Var, int i\)[\s\S]{0,120}c\(4\)/), 'B -> c(4) inks vector');
ok(wd8.match(/cxc t\(\)[\s\S]{0,120}c\(6\)/), 't -> c(6) page');
ok(wd8.match(/fqa s\(\)[\s\S]{0,120}c\(8\)/), 's -> c(8) origin');
ok(wd8.match(/k2d u\(\)[\s\S]{0,140}c\(10\)/), 'u -> c(10) rotation setter');
ok(wd8.match(/y2d v\(\)[\s\S]{0,140}c\(12\)/), 'v -> c(12) scale setter');
ok(wd8.match(/t16 w\(\)[\s\S]{0,140}c\(14\)/), 'w -> c(14) style');
ok(wd8.match(/hu1 j\(\)[\s\S]{0,140}c\(16\)/), 'j -> c(16) color');
ok(wd8.match(/Float z\(\)[\s\S]{0,120}c\(18\)/), 'z -> c(18) width');
ok(wd8.match(/Integer k\(\)[\s\S]{0,120}c\(20\)/), 'k -> c(20) centerPath');
ok(wd8.match(/Integer l\(\)[\s\S]{0,120}c\(22\)/), 'l -> c(22) customPath');
ok(wd8.match(/Integer m\(\)[\s\S]{0,120}c\(24\)/), 'm -> c(24) fillPath');
ok(wd8.match(/g2d n\(\)[\s\S]{0,140}c\(26\)/), 'n -> c(26) fillColor setter');
ok(wd8.match(/Integer x\(\)[\s\S]{0,140}c\(28\)/), 'x -> c(28) styleMap');
ok(wd8.match(/tmf A\(\)[\s\S]{0,120}c\(30\)/), 'A -> c(30) zIndex');
ok(wd8.match(/ymf q\(\)[\s\S]{0,120}c\(32\)/), 'q -> c(32) nibAngle');
ok(wd8.match(/ymf r\(\)[\s\S]{0,120}c\(34\)/), 'r -> c(34) nibFlatness');
ok(wd8.match(/ife y\(\)[\s\S]{0,140}c\(36\)/), 'y -> c(36) tapePattern');
ok(wd8.match(/tmf o\(\)[\s\S]{0,120}c\(38\)/), 'o -> c(38) inkEffects');
ok(wd8.match(/Boolean p\(\)[\s\S]{0,120}c\(40\)/), 'p -> c(40) tinted');

ok(wd8.includes('lv2.M(this)') && wd8.includes('lv2.x(this)') &&
   wd8.includes('lv2.C(this)') && wd8.includes('lv2.F(this)') &&
   wd8.includes('lv2.g0(this)'), 'lv2 modify-side materializers');
ok(!wd8.includes('tool=') && !wd8.match(/u16 [a-z]\(\)/),
  'no tool field (existing ink keeps tool)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
