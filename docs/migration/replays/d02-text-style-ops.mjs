// Phase 916 — pub/me8/he8/io1 文本样式 op 回归
// 证据：docs/migration/evidence/phase-916-text-style-ops.md
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const pub = rd('pub.java');
const me8 = rd('me8.java');
const he8 = rd('he8.java');
const io1 = rd('io1.java');
const zq9 = rd('zq9.java');

ok(pub.includes('RemoveChar(location='), 'pub = RemoveChar');
ok(pub.match(/c\(4\)/) && pub.match(/c\(6\)/), 'pub 2-slot');

ok(me8.includes('ModifyStyle(start=') && me8.includes('strikethrough=') &&
   me8.includes('code='), 'me8 = ModifyStyle 15 fields');
// all setter-wrapped types present
for (const t of ['z1d j()', 'z1d k()', 'v01 l()', 'z2d m()', 'g2d n()',
                 'g2d o()', 'z1d p()', 'z2d q()', 'k2d r()', 'v01 s()',
                 'z1d t()', 'z1d u()', 'z1d v()', 'qo5 w()', 'z1d x()'])
  ok(me8.includes(t), `me8 accessor ${t}`);
ok(me8.match(/v01 s\(\)[\s\S]{0,140}c\(4\)/), 'start v01 c(4)');
ok(me8.match(/qo5 w\(\)[\s\S]{0,140}c\(8\)/), 'textField c(8)');

ok(he8.includes('ModifyParagraphStyle(start=') &&
   he8.includes('writingDirection=') && he8.includes('programmingLanguage='),
  'he8 = ModifyParagraphStyle 10 fields');
ok(he8.match(/cxc p\(\)[\s\S]{0,140}c\(4\)/), 'he8 start cxc c(4)');
ok(he8.match(/o2d j\(\)/) && he8.match(/j2d k\(\)/) &&
   he8.match(/a3d m\(\)/) && he8.match(/b3d r\(\)/),
  'he8 enum setters o2d/j2d/a3d/b3d');
ok(he8.match(/Boolean s\(\)[\s\S]{0,140}c\(16\)/), 'he8 isChecked c(16)');

ok(io1.includes('ClearStyle(start=') && io1.includes('paragraph=') &&
   io1.includes('textField='), 'io1 = ClearStyle 4 fields');

ok(zq9.includes('pub.class') && zq9.includes('haa.REMOVE_CHAR'), 'pub -> REMOVE_CHAR');
ok(zq9.includes('me8.class') && zq9.includes('haa.MODIFY_STYLE'), 'me8 -> MODIFY_STYLE');
ok(zq9.includes('he8.class') && zq9.includes('haa.MODIFY_PARAGRAPH_STYLE'),
  'he8 -> MODIFY_PARAGRAPH_STYLE');
ok(zq9.includes('io1.class') && zq9.includes('haa.CLEAR_STYLE'), 'io1 -> CLEAR_STYLE');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
