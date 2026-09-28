// Phase 972 — 41 表写器 C(N)/required 槽总稽查
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

const check = (cls, meth, type, expectC, expectReq) => {
  const src = readFileSync(`${ROOT}/${cls}.java`, 'utf8');
  const m = src.match(new RegExp('static final int ' + meth + '\\(' + type + ' '));
  if (!m) { fail++; console.log(`FAIL ${cls}.${meth}(${type}) not found`); return; }
  const body = src.slice(m.index, m.index + 9000);
  // for writers with nested C() calls, take the max C(N) (table's own)
  const cs = [...body.matchAll(/aVar\.C\((\d+)\)/g)].map(x => +x[1]);
  const cMax = cs.length ? Math.max(...cs) : null;
  const z = [...body.matchAll(/aVar\.z\(iN, (\d+)\)/g)].map(x => +x[1]);
  const cOk = cMax === expectC;
  const zOk = JSON.stringify(z) === JSON.stringify(expectReq);
  if (cOk && zOk) { pass++; console.log(`  ok ${type} ${cls}.${meth} C(${cMax}) req=[${z}]`); }
  else { fail++; console.log(`FAIL ${type} ${cls}.${meth}: got C(${cMax}) req=[${z}] want C(${expectC}) req=[${expectReq}]`); }
};

check('fci', 'd', 'e46', 3, []);
check('kci', 'j', 'f46', 3, [6]);
check('tej', 'g', 'pub', 2, [4]);
check('vej', 'q', 'qub', 2, [4]);
check('wfj', 'b', 'f2c', 2, [4]);
check('iaj', 'c', 'yn2', 6, [4]);
check('z0j', 'l', 'ke8', 4, [4]);
check('haj', 'c', 'ln2', 4, []);
check('r0j', 'd', 'ge8', 4, [4]);
check('o0j', 'f', 'wd8', 19, [4]);
check('laj', 'l', 'ao2', 18, [4, 6, 14, 22]);
check('a1j', 'c', 'le8', 17, [4]);
check('eaj', 'b', 'cm2', 1, [4]);
check('l0j', 'c', 'vd8', 2, [4, 6]);
check('baj', 'c', 'rl2', 21, [8, 10, 16]);
check('j0j', 'e', 'td8', 18, [4]);
check('x0j', 'm', 'je8', 1, [4]);
check('v0j', 'd', 'he8', 10, []);
check('c1j', 'c', 'me8', 15, [4, 6]);
check('q7j', 'c', 'io1', 4, [4, 6]);
check('p0j', 'd', 'ee8', 5, [4, 6]);
check('lti', 'd', 'mqf', 3, []);
check('i9j', 'f', 'yda', 7, []);
check('daj', 'b', 'tl2', 3, [6, 8]);
check('k0j', 'c', 'ud8', 4, [4]);
check('oqi', 'c', 'tdf', 2, [4]);
check('qqi', 'd', 'sdf', 2, []);
check('i1j', 'e', 'ra0', 1, [4]);
check('q5j', 'b', 'q89', 2, [4, 6]);
check('vv7', 'L', 'nz9', 5, []);
check('fag', 'n0', 'k3a', 6, []);
check('j7j', 'c', 'sw9', 6, []);
check('kvi', 'f', 'p9', 1, [4]);
check('qcj', 'c', 'zgb', 3, [4, 6]);
check('tcj', 'c', 'akb', 1, [4]);
check('iuh', 'c', 'dp5', 2, [4, 6]);
check('k1j', 'c', 'wa0', 4, [4, 6, 8]);
check('qdi', 'a', 'lhe', 2, [6]);
check('rr2', 'b', 'my3', 1, []);

// ys2.O = dm2 factory writer with flat 19-arg signature
const ys2 = readFileSync(`${ROOT}/ys2.java`, 'utf8');
ok(/static final int O\(a aVar, cxc cxcVar, fqa fqaVar, Float f, qed qedVar, u16 u16Var, t16 t16Var, ife ifeVar, hu1 hu1Var, float f2, jmf jmfVar, jmf jmfVar2, jmf jmfVar3, hu1 hu1Var2, Integer num, ix4 ix4Var, tmf tmfVar, mmf mmfVar, List list\)/.test(ys2), 'ys2.O: flat 19-arg dm2 writer');
ok(/static final int O\(a aVar, cxc cxcVar[\s\S]{0,9000}aVar\.C\(20\)/.test(ys2), 'ys2.O: C(20) dm2');
ok(/aVar\.z\(iN, 4\);[\s\S]{0,40}aVar\.z\(iN, 6\);[\s\S]{0,40}aVar\.z\(iN, 18\)/.test(ys2), 'ys2.O: required f0+f1+f7');

// v0j.d nested b3d write (phase-949 embedding, live proof)
const v0j = readFileSync(`${ROOT}/v0j.java`, 'utf8');
ok(/aVar\.C\(1\);[\s\S]{0,60}aVar\.l = true;[\s\S]{0,80}aVar\.c\(0, bcgVarK\.I, 0\)/.test(v0j), 'v0j.d: nested b3d writingDirection setter inline');

// fci.d e46 all-optional write
const fci = readFileSync(`${ROOT}/fci.java`, 'utf8');
ok(/if \(cxcVarJ != null\)[\s\S]{0,60}aVar\.j\(0, sg5\.f\(aVar, cxcVarJ\)\)/.test(fci), 'e46: f0 location opt via sg5.f');
ok(/aVar\.e\(1, iL, 0\)/.test(fci), 'e46: f1 unicodeScalar default-0');
ok(/if \(qo5VarK != null\)[\s\S]{0,60}aVar\.j\(2, rh8\.O\(qo5VarK, aVar\)\)/.test(fci), 'e46: f2 textField opt via rh8.O');

console.log(`\nwriter-field-sweep replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
