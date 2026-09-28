// Phase 973 — ie8 ModifyPosition + w0j.d/e 写器
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const ie8 = readFileSync(`${ROOT}/ie8.java`, 'utf8');
const w0j = readFileSync(`${ROOT}/w0j.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

ok(/ModifyPosition\(target=/.test(ie8), 'ie8 = ModifyPosition');
ok(/page=/.test(ie8) && /zIndex=/.test(ie8), 'ie8: page+zIndex fields');

// w0j.d delegates to e()
ok(/static final int d\(ie8 ie8Var, a aVar\)[\s\S]{0,150}return e\(aVar/.test(w0j), 'w0j.d -> e()');
ok(/static final int e\(a aVar, qo5 qo5Var, cxc cxcVar, fqa fqaVar, k2d k2dVar, y2d y2dVar, tmf tmfVar\)/.test(w0j), 'w0j.e: 6-param signature');

// setter subtables written first
ok(/k2dVar != null \? Integer\.valueOf\(ngh\.d\(k2dVar, aVar\)\)/.test(w0j), 'w0j: rotation via ngh.d (k2d)');
ok(/y2dVar != null \? Integer\.valueOf\(zgh\.c\(y2dVar, aVar\)\)/.test(w0j), 'w0j: scale via zgh.c (y2d)');

// field writes
ok(/aVar\.C\(6\)/.test(w0j), 'w0j.e: C(6)');
ok(/aVar\.j\(0, rh8\.O\(qo5Var, aVar\)\)/.test(w0j), 'w0j: f0 = rh8.O(target qo5)');
ok(/aVar\.j\(1, nti\.X\(cxcVar, aVar\)\)/.test(w0j), 'w0j: f1 = nti.X(page cxc)');
ok(/aVar\.j\(2, apb\.Y\(fqaVar, aVar\)\)/.test(w0j), 'w0j: f2 = apb.Y(origin fqa)');
ok(/aVar\.h\(3, numValueOf\.intValue\(\)\)/.test(w0j), 'w0j: f3 = rotation setter offset');
ok(/aVar\.h\(4, numValueOf2\.intValue\(\)\)/.test(w0j), 'w0j: f4 = scale setter offset');
ok(/aVar\.f\(5, tmfVar\.I\)/.test(w0j), 'w0j: f5 = zIndex long (tmf.I)');
ok(/aVar\.z\(iN, 4\)/.test(w0j), 'w0j: required f0 only');

// layer-mapping helper
ok(/static int f\(int i\)[\s\S]{0,80}case 0:[\s\S]{0,40}return 1/.test(w0j), 'w0j.f: 0..5 -> 1..6 mapping');

console.log(`\nmodify-position replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
