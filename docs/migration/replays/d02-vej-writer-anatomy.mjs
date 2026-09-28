// Phase 951 — vej.q 典型 op 写器解剖回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const vej = readFileSync(join(SRC, 'vej.java'), 'utf8');

ok(vej.match(/int q\(qub qubVar, a aVar\)/), 'vej.q = qub writer');
ok(vej.match(/new wj9\(9, sg5\.b\(\), qubVar\)/), 'wj9(9, cxc-scratch, table) element provider');
ok(vej.match(/j\(\) <= 0 \? sg5\.o/), 'empty -> sg5.o sentinel');
ok(vej.match(/aVar\.D\(12, iJ, 4\)/), 'D(12,len,4) = 12B struct vector');
ok(vej.match(/sg5\.f\(aVar, \(exc\)/), 'sg5.f scratch struct writer');
ok(vej.includes('Got negative length'), 'negative length logged');
ok(vej.match(/aVar\.C\(2\)/) && vej.match(/aVar\.j\(1, rh8\.O\(/), 'f0 vector + f1 rh8.O qo5');
ok(vej.match(/aVar\.z\(iN, 4\)/), 'f0 required via z(iN,4)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
