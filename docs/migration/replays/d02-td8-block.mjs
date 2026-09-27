// Phase 941 — td8 ModifyBlock 18 槽偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const td8 = readFileSync(join(SRC, 'td8.java'), 'utf8');

const FIELDS = [
  ['ty0 k()', 6, 'corner'], ['cxc s()', 8, 'page'], ['fqa r()', 10, 'origin'],
  ['k2d w()', 12, 'rotation SetFloat'], ['y2d x()', 14, 'scale SetSize'],
  ['qed y()', 16, 'size'], ['ive z()', 18, 'textWrap'], ['Boolean m()', 20, 'enableCaption'],
  ['tmf A()', 22, 'zIndex'], ['z2d q()', 24, 'mathLatex SetString'],
  ['g2d p()', 26, 'mathColor SetColor'], ['p2d l()', 28, 'cropRect SetRect'],
  ['n2d t()', 30, 'paper SetPaper'], ['Boolean n()', 32, 'flipH'],
  ['Boolean o()', 34, 'flipV'], ['Boolean v()', 36, 'resizeToFit'],
  ['Boolean u()', 38, 'positionLocked'],
];
for (const [sig, off, name] of FIELDS) {
  ok(td8.match(new RegExp(sig.replace('(', '\\(').replace(')', '\\)') +
     '[\\s\\S]{0,60}c\\(' + off + '\\)')), `td8 ${name} @c(${off})`);
}
ok(td8.includes('ModifyBlock('), 'td8 = ModifyBlock');
ok(!td8.includes('c(42)') && !td8.match(/vy7.*c\(/), 'td8 has NO margins field (vs Create)');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
