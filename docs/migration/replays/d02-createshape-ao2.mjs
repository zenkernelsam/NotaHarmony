// Phase 912 — ao2=CreateShape 18 字段读图回归
// 证据：docs/migration/evidence/phase-912-createshape-ao2.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const ao2 = rd('ao2.java');
const z5c = rd('z5c.java');

ok(ao2.includes('CreateShape(page='), 'ao2 toString = CreateShape');
ok(ao2.includes('smartHighlight=') && ao2.includes('positionLocked=') &&
   ao2.includes('borderWidth=') && ao2.includes('definition='),
  'ao2 17 named fields + definition');

ok(ao2.match(/cxc r\(\)[\s\S]{0,140}c\(4\)/), 'r -> c(4) page');
ok(ao2.match(/fqa q\(\)[\s\S]{0,140}c\(6\)/), 'q -> c(6) origin');
ok(ao2.match(/Float t\(\)[\s\S]{0,120}c\(8\)/), 't -> c(8) rotation');
ok(ao2.match(/qed u\(\)[\s\S]{0,140}c\(10\)/), 'u -> c(10) scale');
ok(ao2.match(/z4d l\(\)[\s\S]{0,160}c\(12\)/), 'l -> c(12) z4d definition kind');
ok(ao2.match(/u16 y\(\)[\s\S]{0,140}c\(16\)/), 'y -> c(16) tool');
ok(ao2.match(/t16 w\(\)[\s\S]{0,160}c\(18\)/), 'w -> c(18) style');
ok(ao2.match(/ife x\(\)[\s\S]{0,140}c\(20\)/), 'x -> c(20) tapePattern');
ok(ao2.match(/hu1 k\(\)[\s\S]{0,200}c\(22\)/), 'k -> c(22) color');
ok(ao2.includes('No value for (required) field color'), 'color is required');
ok(ao2.match(/float j\(\)[\s\S]{0,120}c\(24\)/), 'j -> c(24) borderWidth');
ok(ao2.includes('4.0f'), 'borderWidth default 4.0f');
ok(ao2.match(/hu1 m\(\)[\s\S]{0,140}c\(26\)/), 'm -> c(26) fillColor');
ok(ao2.match(/tmf z\(\)[\s\S]{0,140}c\(28\)/), 'z -> c(28) zIndex');
ok(ao2.match(/boolean v\(\)[\s\S]{0,120}c\(30\)/), 'v -> c(30) smartHighlight');
ok(ao2.match(/Float n\(\)[\s\S]{0,120}c\(32\)/), 'n -> c(32) force');
ok(ao2.match(/boolean s\(\)[\s\S]{0,120}c\(34\)/), 's -> c(34) positionLocked');
ok(ao2.match(/long o\(\)[\s\S]{0,120}c\(36\)/), 'o -> c(36) inkEffects');
ok(ao2.match(/boolean p\(\)[\s\S]{0,120}c\(38\)/), 'p -> c(38) inkEffectsTinted');

// z5c polymorphic definition dispatch
ok(z5c.includes('cee v(ao2 ao2Var)') && z5c.includes('ao2Var.c(14)'),
  'z5c.v reads definition subtable at c(14)');
ok(z5c.includes('mpb.a.b(ao2Var.l().getClass())'),
  'z4d kind -> class-key dispatch');
ok(z5c.includes('cee w(le8 le8Var)') && z5c.includes('le8Var.c(16)'),
  'z5c.w same pattern for ModifyShape at c(16)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
