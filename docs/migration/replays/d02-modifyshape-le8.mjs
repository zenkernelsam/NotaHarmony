// Phase 913 — le8=ModifyShape 17 槽读图回归
// 证据：docs/migration/evidence/phase-913-modifyshape-le8.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const le8 = rd('le8.java');

ok(le8.includes('ModifyShape(shapes='), 'le8 toString = ModifyShape');
ok(le8.includes('positionLocked=') && le8.includes('inkEffectsTinted=') &&
   !le8.includes('smartHighlight=') && !le8.includes('force='),
  'le8 fields (no smartHighlight/force vs CreateShape)');

ok(le8.match(/void B\(qo5 qo5Var, int i\)[\s\S]{0,120}c\(4\)/), 'B -> c(4) shapes vector');
ok(le8.match(/cxc r\(\)[\s\S]{0,140}c\(6\)/), 'r -> c(6) page');
ok(le8.match(/fqa q\(\)[\s\S]{0,140}c\(8\)/), 'q -> c(8) origin');
ok(le8.match(/k2d z\(k2d|k2d t\(\)/), 'rotation k2d setter present');
ok(le8.match(/A\(y2d y2dVar\)[\s\S]{0,120}c\(12\)/), 'A -> c(12) scale setter');
ok(le8.match(/z4d m\(\)[\s\S]{0,140}c\(14\)/), 'm -> c(14) z4d discriminator');
ok(le8.match(/u16 x\(\)[\s\S]{0,140}c\(18\)/), 'x -> c(18) tool');
ok(le8.match(/t16 v\(\)[\s\S]{0,140}c\(20\)/), 'v -> c(20) style');
ok(le8.match(/ife w\(\)[\s\S]{0,140}c\(22\)/), 'w -> c(22) tapePattern');
ok(le8.match(/hu1 l\(\)[\s\S]{0,140}c\(24\)/), 'l -> c(24) color');
ok(le8.match(/Float k\(\)[\s\S]{0,120}c\(26\)/), 'k -> c(26) borderWidth');
ok(le8.match(/g2d j\(g2d|g2d n\(\)/), 'fillColor g2d setter present');
ok(le8.match(/j\(g2d g2dVar\)[\s\S]{0,120}c\(28\)/), 'j -> c(28) fillColor setter');
ok(le8.match(/tmf y\(\)[\s\S]{0,140}c\(30\)/), 'y -> c(30) zIndex');
ok(le8.match(/Boolean s\(\)[\s\S]{0,120}c\(32\)/), 's -> c(32) positionLocked');
ok(le8.match(/tmf o\(\)[\s\S]{0,120}c\(34\)/), 'o -> c(34) inkEffects as ULong');
ok(le8.match(/Boolean p\(\)[\s\S]{0,120}c\(36\)/), 'p -> c(36) tinted');
ok(le8.includes('lv2.e0(this)') && le8.includes('z5c.w(this)'),
  'lv2.e0 targets + z5c.w definition');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
