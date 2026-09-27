// Phase 942 — me8/he8/io1 样式 op 偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const me8 = rd('me8.java');
const ME8 = [
  ['v01 s()', 4, 'start'], ['v01 l()', 6, 'end'], ['qo5 w()', 8, 'textField'],
  ['z1d j()', 10, 'bold'], ['z1d p()', 12, 'italic'], ['z1d x()', 14, 'underline'],
  ['g2d o()', 16, 'highlight'], ['z2d m()', 18, 'familyName'], ['k2d r()', 20, 'size'],
  ['g2d n()', 22, 'foregroundColor'], ['z2d q()', 24, 'link'], ['z1d v()', 26, 'superscript'],
  ['z1d u()', 28, 'subscript'], ['z1d t()', 30, 'strikethrough'], ['z1d k()', 32, 'code'],
];
for (const [sig, off, name] of ME8) {
  ok(me8.match(new RegExp(sig.replace('(', '\\(').replace(')', '\\)') +
     '[\\s\\S]{0,60}c\\(' + off + '\\)')), `me8 ${name} @c(${off})`);
}
ok(me8.includes('ModifyStyle(start='), 'me8 = ModifyStyle 15 fields');

const he8 = rd('he8.java');
const HE8 = [
  ['cxc p()', 4, 'start'], ['cxc l()', 6, 'end'], ['a3d m()', 8, 'indentLevel'],
  ['o2d j()', 10, 'alignment'], ['k2d n()', 12, 'lineSpacing'],
  ['j2d k()', 14, 'decoratorStyle'], ['Boolean s()', 16, 'isChecked'],
  ['qo5 q()', 18, 'textField'], ['z2d o()', 20, 'programmingLanguage'],
  ['b3d r()', 22, 'writingDirection'],
];
for (const [sig, off, name] of HE8) {
  ok(he8.match(new RegExp(sig.replace('(', '\\(').replace(')', '\\)') +
     '[\\s\\S]{0,60}c\\(' + off + '\\)')), `he8 ${name} @c(${off})`);
}
ok(he8.includes('ModifyParagraphStyle(start='), 'he8 = ModifyParagraphStyle');

const io1 = rd('io1.java');
ok(io1.match(/v01 l\(\)[\s\S]{0,60}c\(4\)/) && io1.match(/v01 j\(\)[\s\S]{0,60}c\(6\)/),
  'io1 start/end v01 @c(4)/c(6)');
ok(io1.match(/boolean k\(\)[\s\S]{0,60}c\(8\)/) && io1.match(/qo5 m\(\)[\s\S]{0,60}c\(10\)/),
  'io1 paragraph+textField');
ok(io1.includes('ClearStyle(start='), 'io1 = ClearStyle');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
