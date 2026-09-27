// Phase 929 — lxc/th7/ume/m15 尾类回归
// 证据：docs/migration/evidence/phase-929-lxc-th7-tail.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const lxc = rd('lxc.java');
ok(lxc.includes('SeqMove(toId='), 'lxc = SeqMove');
ok(lxc.match(/c\(4\)/), 'lxc single field c(4)');

const th7 = rd('th7.java');
ok(th7.includes('extends u4') && th7.includes('implements RandomAccess'),
  'th7 = mutable Object[] list (u4 subclass)');
ok(th7.includes('Object[] I') && th7.includes('boolean K'),
  'th7 array-backed mutable');

const lv2 = rd('lv2.java');
ok(lv2.includes('m18.S()') && lv2.includes('m18.E('),
  'm18.S/E builder->immutable pair');

const ume = rd('ume.java');
ok(ume.includes('Attached(alwaysMinimize'), 'ume = UI Attached (non-wire)');

const m15 = rd('m15.java');
ok(m15.includes('extends p15'), 'm15 = serializer context family');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
