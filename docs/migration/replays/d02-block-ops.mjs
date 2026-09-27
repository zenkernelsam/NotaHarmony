// Phase 918 — rl2=CreateBlock / td8=ModifyBlock 读图回归
// 证据：docs/migration/evidence/phase-918-block-ops.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const rl2 = rd('rl2.java');
const td8 = rd('td8.java');
const zq9 = rd('zq9.java');

ok(rl2.includes('CreateBlock(type='), 'rl2 = CreateBlock');
for (const name of ['corner=', 'page=', 'origin=', 'rotation=', 'scale=',
  'size=', 'textWrap=', 'enableCaption=', 'zIndex=', 'image=', 'cropRect=',
  'webUrl=', 'mathLatex=', 'mathColor=', 'paper=', 'imageFlippedHorizontally=',
  'imageFlippedVertically=', 'resizesWidthToFitText=', 'margins=',
  'positionLocked='])
  ok(rl2.includes(name), `rl2 field ${name}`);

ok(rl2.match(/cz0 B\(\)[\s\S]{0,120}c\(4\)/), 'type cz0 c(4)');
ok(rl2.match(/ty0 j\(\)[\s\S]{0,120}c\(6\)/), 'corner ty0 c(6)');
ok(rl2.match(/cxc t\(\)[\s\S]{0,140}c\(8\)/), 'page cxc c(8)');
ok(rl2.match(/fqa s\(\)[\s\S]{0,140}c\(10\)/), 'origin fqa c(10)');
ok(rl2.includes('No value for (required) field size'), 'size required');
ok(rl2.match(/qed z\(\)[\s\S]{0,200}c\(16\)/), 'size qed c(16)');
ok(rl2.match(/ive A\(\)[\s\S]{0,140}c\(18\)/), 'textWrap ive c(18)');
ok(rl2.match(/tmf D\(\)[\s\S]{0,140}c\(22\)/), 'zIndex tmf c(22)');
ok(rl2.match(/dp5 m\(\)[\s\S]{0,140}c\(24\)/), 'image dp5 c(24)');
ok(rl2.match(/bmb k\(\)[\s\S]{0,140}c\(26\)/), 'cropRect bmb c(26)');
ok(rl2.match(/k3a u\(\)[\s\S]{0,140}c\(34\)/), 'paper k3a c(34)');
ok(rl2.match(/vy7 p\(\)[\s\S]{0,140}c\(42\)/), 'margins vy7 c(42)');

ok(td8.includes('ModifyBlock(blocks=') && td8.includes('lv2.u(this)'),
  'td8 = ModifyBlock blocks vector');
ok(td8.includes('ddg.o('), 'td8 validate via ddg.o joint rule');
ok(!td8.includes('type=') && !td8.includes('webUrl=') &&
   !td8.includes('margins='), 'td8 lacks type/webUrl/margins (immutable)');

ok(zq9.includes('rl2.class') && zq9.includes('haa.CREATE_BLOCK'), 'rl2 -> CREATE_BLOCK');
ok(zq9.includes('td8.class') && zq9.includes('haa.MODIFY_BLOCK'), 'td8 -> MODIFY_BLOCK');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
