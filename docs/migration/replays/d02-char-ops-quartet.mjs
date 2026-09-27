// Phase 915 — e46/f46/qub/f2c 字符 op 四表回归
// 证据：docs/migration/evidence/phase-915-char-ops-quartet.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const e46 = rd('e46.java');
const f46 = rd('f46.java');
const qub = rd('qub.java');
const f2c = rd('f2c.java');
const zq9 = rd('zq9.java');

ok(e46.includes('InsertChar(location=') && e46.includes('unicodeScalar='),
  'e46 = InsertChar');
ok(e46.includes('mmf.a('), 'unicodeScalar as mmf UInt');
ok(e46.match(/c\(4\)/) && e46.match(/c\(6\)/) && e46.match(/c\(8\)/),
  'e46 3-slot (location@4, textField@6, scalar@8)');

ok(f46.includes('InsertString(location=') && f46.includes('string='),
  'f46 = InsertString');

ok(qub.includes('RemoveChars(locations='), 'qub = RemoveChars');
ok(f2c.includes('ReviveChars(locations='), 'f2c = ReviveChars');
ok(qub.includes('(i * 12) + f(iC)') && f2c.includes('(i * 12) + f(iC)'),
  'locations = cxc 12B inline-struct vectors');
ok(qub.match(/qo5 k\(\)[\s\S]{0,140}c\(6\)/) &&
   f2c.match(/qo5 k\(\)[\s\S]{0,140}c\(6\)/), 'textField qo5 at c(6) both');
ok(qub.includes('lv2.N(this)') && f2c.includes('lv2.O(this)'),
  'lv2.N/O location materializers');

ok(zq9.includes('e46.class') && zq9.includes('haa.INSERT_CHAR'), 'e46 -> INSERT_CHAR');
ok(zq9.includes('f46.class') && zq9.includes('haa.INSERT_STRING'), 'f46 -> INSERT_STRING');
ok(zq9.includes('qub.class') && zq9.includes('haa.REMOVE_CHARS'), 'qub -> REMOVE_CHARS');
ok(zq9.includes('f2c.class') && zq9.includes('haa.REVIVE_CHARS'), 'f2c -> REVIVE_CHARS');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
