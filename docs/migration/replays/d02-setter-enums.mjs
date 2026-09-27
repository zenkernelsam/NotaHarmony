// Phase 920 — setter 包装布局 + v01/tv6/dz0/y01 回归
// 证据：docs/migration/evidence/phase-920-setter-enums.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

// setter wrappers: single {value@c(4)} slot
ok(rd('z1d.java').includes('SetBool(value='), 'z1d = SetBool');
ok(rd('z2d.java').includes('SetString(value='), 'z2d = SetString');
ok(rd('k2d.java').includes('SetFloat(value='), 'k2d = SetFloat');
ok(rd('y2d.java').includes('SetSize(value='), 'y2d = SetSize');
ok(rd('g2d.java').includes('SetColor(value='), 'g2d = SetColor');
ok(rd('m2d.java').includes('SetPageBackground(value='), 'm2d = SetPageBackground');

// v01 Boundary inline struct
const v01 = rd('v01.java');
ok(v01.includes('Boundary(location=') && v01.includes('type='),
  'v01 = Boundary{location,type}');
ok(v01.includes('this.J.get(this.I + 12)'), 'Boundary type at offset 12 (after 12B cxc)');
ok(v01.includes('y01'), 'Boundary type is y01 enum');

// enums
const y01 = rd('y01.java');
ok(y01.includes('BEFORE((byte) 0)') && y01.includes('AFTER((byte) 1)') &&
   y01.includes('START_OF_DOC((byte) 2)') && y01.includes('END_OF_DOC((byte) 3)'),
  'y01 = BoundaryType BEFORE/AFTER/START_OF_DOC/END_OF_DOC');

const tv6 = rd('tv6.java');
ok(tv6.includes('PAGED((byte) 0)') && tv6.includes('PAGELESS((byte) 1)'),
  'tv6 = LayoutMode PAGED/PAGELESS');

const dz0 = rd('dz0.java');
ok(dz0.includes('WRAP_ENABLED((byte) 0)') && dz0.includes('WRAP_DISABLED((byte) 1)') &&
   dz0.includes('LEGACY_WRAP_ENABLED((byte) 2)'),
  'dz0 = BlockWrapSupport 3-state incl LEGACY');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
