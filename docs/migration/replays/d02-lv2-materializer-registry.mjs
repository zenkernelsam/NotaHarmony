// Phase 933 — lv2 全量物化器登记回归（Phase 925 单方法样例的全表扩展）
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const lv2 = readFileSync(join(SRC, 'lv2.java'), 'utf8');

const MATERIALIZERS = [
  ['A(dm2)', 'ei7'], ['B(dm2)', 'nl8'], ['C(wd8)', 'nl8'], ['D(dm2)', 'di7'],
  ['E(dm2)', 'nl8'], ['F(wd8)', 'nl8'], ['G(dm2)', 'di7'], ['H(my3)', 'List'],
  ['I(s83)', 'th7'], ['J(s83)', 'th7'], ['W(s83)', 'th7'], ['X(s83)', 'th7'],
  ['M(wd8)', 'List'], ['N(qub)', 'List'], ['O(f2c)', 'List'], ['P(cm2)', 'List'],
  ['Q(vd8)', 'List'], ['S(je8)', 'List'], ['T(r29)', 'List'], ['U(vt9)', 'List'],
  ['V(zgb)', 'List'], ['Y(ge8)', 'List'], ['a0(pra)', 'List'], ['b0(yn2)', 'th7'],
  ['c0(ke8)', 'th7'], ['d0(yda)', 'th7'], ['e0(le8)', 'List'], ['f0(dm2)', 'th7'],
  ['g0(wd8)', 'th7'],
];
for (const [sig, ret] of MATERIALIZERS) {
  const [m, p] = sig.replace(')', '').split('(');
  ok(lv2.match(new RegExp('final ' + ret + ' ' + m + '\\(' + p + ' ')),
     `materializer ${sig} -> ${ret}`);
}
ok((lv2.match(/m18\.S\(\)/g) || []).length >= 15, 'm18.S() builder used >=15x');
ok((lv2.match(/m18\.E\(/g) || []).length >= 15, 'm18.E() freeze used >=15x');
ok((lv2.match(/return hw3\.I/g) || []).length >= 10, 'hw3.I empty sentinel >=10x');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
