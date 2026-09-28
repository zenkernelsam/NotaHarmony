// Phase 968 — x6j.b OpsBundle 写器 + w6j.c OpAck 写器
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const x6j = readFileSync(`${ROOT}/x6j.java`, 'utf8');
const w6j = readFileSync(`${ROOT}/w6j.java`, 'utf8');
const z0c = readFileSync(`${ROOT}/z0c.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// x6j.b = vt9 OpsBundle writer — CAS-guarded ops vector
ok(/static final int b\(vt9 vt9Var, a aVar\)/.test(x6j), 'x6j.b = vt9 writer');
ok(/new wj9\(1, \(uq9\) x82\.x\(sg5\.n, sg5\.a\[12\]\), vt9Var\)/.test(x6j), 'x6j: wj9(1, OP_HOLDER, vt9) provider');
ok(/vt9Var\.j\(\) <= 0 \? sg5\.o/.test(x6j), 'x6j: empty ops -> sg5.o');
ok(/sg5\.e\(\)\.compareAndSet\(false, true\)/.test(x6j), 'x6j: CAS reentry guard');
ok(/ree\.a\(\(cee\) wj9Var\.invoke/.test(x6j), 'x6j: per-op ree.a');
ok(/aVar\.D\(4, iJ, 4\)/.test(x6j), 'x6j: D(4,iJ,4) reverse offsets');
ok(/sg5\.e\(\)\.set\(false\)/.test(x6j), 'x6j: CAS release');

// w6j.c = vq9 OpAck writer — embeds full op via zq9.d
ok(/static final int c\(vq9 vq9Var, a aVar\)/.test(w6j), 'w6j.c = vq9 writer');
ok(/uq9VarM != null \? Integer\.valueOf\(zq9\.d\(uq9VarM, aVar\)\)/.test(w6j), 'w6j: f1 embeds op via zq9.d');
ok(/strL != null \? Integer\.valueOf\(dbj\.c\(strL, aVar\)\)/.test(w6j), 'w6j: f2 errorMessage via dbj.c');
ok(/aVar\.C\(4\)/.test(w6j), 'w6j: C(4)');
ok(/aVar\.j\(0, rh8\.O\(qo5VarK, aVar\)\)/.test(w6j), 'w6j: f0 = rh8.O(opId qo5)');
ok(/aVar\.h\(1, numValueOf\.intValue\(\)\)/.test(w6j), 'w6j: f1 = embedded op offset');
ok(/aVar\.h\(2, numValueOf2\.intValue\(\)\)/.test(w6j), 'w6j: f2 = errorMessage');
ok(/aVar\.l = true;[\s\S]{0,80}aVar\.a\(3, zBooleanValue, false\);[\s\S]{0,40}aVar\.l = false;/.test(w6j), 'w6j: f3 = tri-state acknowledged');
ok(/aVar\.z\(iN, 4\)/.test(w6j), 'w6j: required f0 only');

// registry bindings for the tail writers
for (const [type, writer] of [['vt9','x6j'], ['vq9','w6j'], ['q89','q5j'], ['nz9','vv7'], ['k3a','fag'], ['sw9','j7j'], ['p9','kvi'], ['sdf','qqi']]) {
  ok(new RegExp(`put\\(${type}\\.class`).test(z0c), `registry: ${type} registered`);
}

console.log(`\ntail-writers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
