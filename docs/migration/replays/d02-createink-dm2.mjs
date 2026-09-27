// Phase 909 — dm2=CreateInk 20 字段读图回归
// 证据：docs/migration/evidence/phase-909-createink-dm2.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const dm2 = rd('dm2.java');

ok(dm2.includes('CreateInk(page='), 'dm2 toString = CreateInk');
ok(dm2.includes('encodedCenterPath=') && dm2.includes('encodedCustomPath=') &&
   dm2.includes('encodedFillPath=') && dm2.includes('styleMap=') &&
   dm2.includes('inkEffectsTinted='), 'dm2 20 named fields');

// accessor->c(N) pins
ok(dm2.match(/cxc t\(\)[\s\S]{0,140}c\(4\)/), 't -> c(4) page');
ok(dm2.match(/fqa C\(fqa[\s\S]{0,140}c\(6\)/), 'C -> c(6) origin');
ok(dm2.match(/Float u\(\)[\s\S]{0,120}c\(8\)/), 'u -> c(8) rotation');
ok(dm2.match(/qed v\(\)[\s\S]{0,140}c\(10\)/), 'v -> c(10) scale');
ok(dm2.match(/u16 z\(\)[\s\S]{0,140}c\(12\)/), 'z -> c(12) tool');
ok(dm2.match(/t16 w\(\)[\s\S]{0,140}c\(14\)/), 'w -> c(14) style');
ok(dm2.match(/ife y\(\)[\s\S]{0,140}c\(16\)/), 'y -> c(16) tapePattern');
ok(dm2.match(/hu1 k\(\)[\s\S]{0,140}c\(18\)/), 'k -> c(18) color');
ok(dm2.match(/float A\(\)[\s\S]{0,120}c\(20\)/), 'A -> c(20) width');
ok(dm2.match(/Integer l\(\)[\s\S]{0,120}c\(24\)/), 'l -> c(24) customPath');
ok(dm2.match(/Integer m\(\)[\s\S]{0,120}c\(26\)/), 'm -> c(26) fillPath');
ok(dm2.match(/hu1 n\(\)[\s\S]{0,140}c\(28\)/), 'n -> c(28) fillColor');
ok(dm2.match(/Integer x\(\)[\s\S]{0,140}c\(30\)/), 'x -> c(30) styleMap');
ok(dm2.match(/tmf B\(\)[\s\S]{0,120}c\(32\)/), 'B -> c(32) zIndex');
ok(dm2.match(/mmf j\(\)[\s\S]{0,120}c\(34\)/), 'j -> c(34) audioDuration');
ok(dm2.match(/ymf q\(\)[\s\S]{0,120}c\(36\)/), 'q -> c(36) nibAngle');
ok(dm2.match(/ymf r\(\)[\s\S]{0,120}c\(38\)/), 'r -> c(38) nibFlatness');
ok(dm2.match(/long o\(\)[\s\S]{0,120}c\(40\)/), 'o -> c(40) inkEffects');
ok(dm2.match(/boolean p\(\)[\s\S]{0,120}c\(42\)/), 'p -> c(42) inkEffectsTinted');

// 枚举回退
ok(dm2.includes('nz3Var.d()') && dm2.includes('nz3Var.get(0)'),
  'enum out-of-range -> entries[0] (u16/t16/ife)');
ok(dm2.includes('lv2.w(this)') && dm2.includes('lv2.B(this)') &&
   dm2.includes('lv2.E(this)') && dm2.includes('lv2.f0(this)'),
  'lv2 path-vector materializers');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
