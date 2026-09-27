// Phase 931 — uf7/pra/oz8 字段级布局回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const uf7 = rd('uf7.java');
ok(uf7.match(/fqa n\(\)[\s\S]{0,120}c\(4\)[\s\S]{0,80}required\) field start/), 'Line start fqa c(4) required');
ok(uf7.match(/fqa k\(\)[\s\S]{0,100}c\(6\)/), 'cp1 fqa c(6)');
ok(uf7.match(/fqa l\(\)[\s\S]{0,100}c\(8\)/), 'cp2 fqa c(8)');
ok(uf7.match(/fqa m\(\)[\s\S]{0,100}c\(10\)/), 'end fqa c(10)');
ok(uf7.match(/z90 j\(\)[\s\S]{0,80}c\(12\)/), 'arrowHead z90 c(12)');
ok(rd('z90.java').includes('NONE((byte) 0)') && rd('z90.java').includes('SINGLE((byte) 1)'),
  'z90 = ArrowHead {NONE,SINGLE}');

const pra = rd('pra.java');
ok(pra.includes('void j(fqa fqaVar, int i)'), 'Polygon elem accessor = fqa');
ok(pra.match(/c\(4\)/) && pra.includes('i * 8'), 'Polygon points vector @c(4), 8B stride');

const oz8 = rd('oz8.java');
ok(oz8.match(/pz8 k\(\)[\s\S]{0,80}c\(4\)/), 'NormalShape type pz8 c(4)');
ok(oz8.match(/qed j\(\)[\s\S]{0,120}c\(6\)[\s\S]{0,80}required\) field size/), 'size qed c(6) required');
ok(rd('pz8.java').includes('new pz8("ELLIPSE", 0)'), 'pz8 = {ELLIPSE=0} only preset');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
