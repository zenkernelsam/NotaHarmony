// Phase 925 — lv2 物化器族回归
// 证据：docs/migration/evidence/phase-925-lv2-materializers.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const lv2 = rd('lv2.java');

// canonical materializer pattern (N/qub)
ok(lv2.includes('List N(qub qubVar)'), 'lv2.N materializes qub locations');
ok(lv2.includes('hw3.I'), 'empty list constant hw3.I');
ok(lv2.includes('m18.S()') && lv2.includes('m18.E('),
  'm18.S/E = Kotlin buildList pair');
ok(lv2.includes('qubVar.l(i2, cxcVar)'), 'per-index struct accessor loop');

// registry coverage
for (const m of ['N(qub', 'O(f2c', 'P(cm2', 'Q(vd8', 'M(wd8', 'S(je8',
  'T(r29', 'U(vt9', 'Y(ge8', 'I(s83', 'J(s83', 'W(s83', 'X(s83'])
  ok(lv2.includes(m), `lv2.${m.slice(0, -1)} registered`);

// path vector wrappers exist
for (const m of ['A(dm2', 'B(dm2', 'E(dm2', 'C(wd8', 'F(wd8'])
  ok(lv2.includes(m), `lv2 path materializer ${m.slice(0, -1)}`);

// di7 iterator + th7 builder
ok(rd('di7.java').includes('implements hmf'), 'di7 = range iterator');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
