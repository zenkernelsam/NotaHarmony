// Phase 911 — gd=AddPathElements 读图回归
// 证据：docs/migration/evidence/phase-911-addpathelements-gd.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const gd = rd('gd.java');
const zq9 = rd('zq9.java');

ok(gd.includes('AddPathElements(ink='), 'gd toString = AddPathElements');
ok(gd.includes('encodedCenterPathElements=') &&
   gd.includes('encodedCenterPathEstimatedElements='),
  'gd dual path vectors (actual + estimated)');

ok(gd.match(/qo5 j\(\)[\s\S]{0,120}c\(4\)/), 'j -> c(4) ink single qo5');
ok(gd.match(/String a\(\)[\s\S]{0,80}c\(6\)/), 'a() validates c(6) elements');
ok(gd.includes('di7') && gd.includes('ldj.I2'),
  'a() iterates path elements via di7/ldj.I2');

// 单目标 vs 向量目标
ok(!gd.match(/qo5 [a-z]\(qo5 qo5Var, int/), 'gd has no parameterized qo5 accessor (single ink)');
ok(rd('wd8.java').match(/void B\(qo5 qo5Var, int i\)/), 'wd8 inks vector accessor parameterized');

ok(zq9.includes('gd.class') && zq9.includes('haa.ADD_PATH_ELEMENTS'),
  'zq9: gd -> ADD_PATH_ELEMENTS');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
