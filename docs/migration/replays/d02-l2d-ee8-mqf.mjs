// Phase 938 — l2d/ee8/mqf 字段级偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rd = (f) => readFileSync(join(SRC, f), 'utf8');

const l2d = rd('l2d.java');
const L2D = [
  ['z2d q()', 4, 'title SetString'], ['m2d p()', 6, 'pageBackground'],
  ['z2d n()', 8, 'handwritingLanguage'], ['Boolean j()', 10, 'alignTextToLines'],
  ['String l()', 12, 'defaultFontFamily'], ['Float m()', 14, 'defaultFontSize'],
  ['tv6 o()', 16, 'layoutMode'], ['dz0 k()', 18, 'blockWrapSupport'],
];
for (const [sig, off, name] of L2D) {
  ok(l2d.match(new RegExp(sig.replace('(', '\\(').replace(')', '\\)') +
     '[\\s\\S]{0,60}c\\(' + off + '\\)')), `l2d ${name} @c(${off})`);
}
ok(l2d.includes('SetMetadata(title='), 'l2d = SetMetadata');

const ee8 = rd('ee8.java');
ok(ee8.match(/ua0 j\(\)[\s\S]{0,80}c\(4\)/), 'ee8 assetHash @c(4)');
ok(ee8.match(/String k\(\)[\s\S]{0,80}c\(6\)/), 'ee8 key @c(6)');
ok(ee8.match(/ww9 n\(\)[\s\S]{0,80}c\(8\)/), 'ee8 valueType @c(8)');
ok(ee8.match(/String m\(\)[\s\S]{0,80}c\(10\)/), 'ee8 valueString @c(10)');
ok(ee8.match(/Boolean l\(\)[\s\S]{0,80}c\(12\)/), 'ee8 valueBoolean @c(12)');

const mqf = rd('mqf.java');
ok(mqf.match(/qo5 k\(\)[\s\S]{0,80}c\(4\)/), 'mqf textField @c(4)');
ok(mqf.match(/cxc j\(\)[\s\S]{0,80}c\(6\)/), 'mqf location @c(6)');
ok(mqf.match(/boolean l\(\)[\s\S]{0,80}c\(8\)/), 'mqf isChecked @c(8)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
