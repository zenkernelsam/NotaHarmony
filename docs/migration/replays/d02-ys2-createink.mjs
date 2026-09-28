// Phase 947 — ys2.d/O CreateInk 工厂+写器回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const ys2 = readFileSync(join(SRC, 'ys2.java'), 'utf8');

ok(ys2.match(/static dm2 d\(cxc cxcVar, fqa fqaVar/), 'ys2.d = CreateInk factory');
ok(ys2.includes('ybg.c(dm2Var)'), 'factory validates via ybg.c');
ok(ys2.match(/int O\(a aVar, cxc cxcVar/), 'ys2.O = CreateInk writer');
ok(ys2.match(/aVar\.C\(20\)/), 'dm2 = 20-slot table');
ok(ys2.match(/aVar\.j\(0, nti\.X\(/), 'f0 page = nti.X');
ok(ys2.match(/aVar\.j\(1, apb\.Y\(/), 'f1 origin = apb.Y');
ok(ys2.match(/aVar\.j\(3, apb\.Z\(/), 'f3 scale = apb.Z (qed writer)');
ok(ys2.match(/aVar\.c\(4, u16Var\.I, 0\)/), 'f4 tool u16 enum');
ok(ys2.match(/aVar\.c\(5, t16Var\.I, 0\)/), 'f5 style t16');
ok(ys2.match(/aVar\.h\(9, /) && ys2.match(/aVar\.h\(10, /) && ys2.match(/aVar\.h\(11, /),
  'f9-11 path vectors');
ok(ys2.match(/aVar\.f\(18, rz1\.h0/) && ys2.match(/aVar\.a\(19, rz1\.g0/), 'f18/19 inkEffects+tinted');
ok(ys2.match(/zwd\.a\(\(xwd\)/), 'styleMap elems via zwd.a dispatch');
ok(ys2.match(/D\(1, iA\d, 1\)/), 'path vectors = 1-byte elements');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
