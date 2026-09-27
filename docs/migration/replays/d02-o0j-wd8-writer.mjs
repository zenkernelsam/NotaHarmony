// Phase 946 — o0j.f ModifyInk 写器回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const o0j = readFileSync(join(SRC, 'o0j.java'), 'utf8');

ok(o0j.includes('int f(wd8 wd8Var, a aVar)'), 'o0j.f = wd8 writer');
ok(o0j.match(/aVar\.C\(19\)/), 'wd8 = 19-slot table');
ok(o0j.match(/aVar\.h\(0, numValueOf/), 'f0 inks vector');
ok(o0j.match(/aVar\.j\(1, nti\.X\(/), 'f1 page = nti.X');
ok(o0j.match(/aVar\.j\(2, apb\.Y\(/), 'f2 origin = apb.Y');
ok(o0j.match(/aVar\.j\(6, z5c\.P\(/), 'f6 color = z5c.P');
ok(o0j.match(/aVar\.f\(13, tmfVarA\.I\)/), 'f13 zIndex tmf');
ok(o0j.match(/aVar\.z\(iN, 4\)/), 'z(iN,4) = f0 required');
ok((o0j.match(/aVar\.l = true/g) || []).length >= 2, 'l=true enum force-write used >=2x');
ok(o0j.match(/aVar\.c\(16, ifeVarY\.I, 0\)/), 'f16 tapePattern enum');
ok(o0j.match(/aVar\.f\(17, /) && o0j.match(/aVar\.a\(18, /), 'f17/f18 inkEffects+tinted');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
