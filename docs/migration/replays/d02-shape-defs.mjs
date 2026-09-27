// Phase 930 — z5c.a0 形状定义分发回归
// 证据：docs/migration/evidence/phase-930-shape-defs.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const z5c = rd('z5c.java');
ok(z5c.includes('cee a0(z4d z4dVar)'), 'z5c.a0 = def factory');
ok(z5c.match(/iOrdinal == 0[\s\S]{0,40}return null/), 'ordinal 0 -> NONE null');
ok(z5c.includes('new uf7()') && z5c.includes('new pra()') && z5c.includes('new oz8()'),
  'ordinals -> uf7/pra/oz8');

const z4d = rd('z4d.java');
ok(z4d.includes('NONE((byte) 0)') && z4d.includes('LINE((byte) 1)') &&
   z4d.includes('POLYGON((byte) 2)') && z4d.includes('NORMAL_SHAPE((byte) 3)'),
  'z4d = ShapeDefKind 4 values');

ok(rd('uf7.java').includes('Line(start=') && rd('uf7.java').includes('controlPoint1=') &&
   rd('uf7.java').includes('arrowHead='), 'uf7 = Line bezier + arrowHead');
ok(rd('pra.java').includes('Polygon(points='), 'pra = Polygon points vector');
ok(rd('oz8.java').includes('NormalShape(type=') && rd('oz8.java').includes('size='),
  'oz8 = NormalShape type+size');

ok(z5c.match(/String Z\(cxc cxcVar\)[\s\S]{0,160}ymf\.a\(cxcVar\.c\(\)\)[\s\S]*mmf\.a\(cxcVar\.d\(\)\)[\s\S]*mmf\.a\(cxcVar\.C\(\)\)/),
  'z5c.Z = "{site},{ts},{idx}" cxc stringify');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
