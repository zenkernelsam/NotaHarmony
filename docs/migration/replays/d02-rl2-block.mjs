// Phase 940 — rl2 CreateBlock 21 字段偏移回归
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
let pass = 0, fail = 0;
const ok = (cond, label) => { if (cond) pass++; else { fail++; console.log('FAIL', label); } };
const rl2 = readFileSync(join(SRC, 'rl2.java'), 'utf8');

const FIELDS = [
  ['cz0 B()', 4, 'type'], ['ty0 j()', 6, 'corner'], ['cxc t()', 8, 'page'],
  ['fqa s()', 10, 'origin'], ['Float x()', 12, 'rotation'], ['qed y()', 14, 'scale'],
  ['qed z()', 16, 'size'], ['ive A()', 18, 'textWrap'], ['boolean l()', 20, 'enableCaption'],
  ['tmf D()', 22, 'zIndex'], ['dp5 m()', 24, 'image'], ['bmb k()', 26, 'cropRect'],
  ['String C()', 28, 'webUrl'], ['String r()', 30, 'mathLatex'], ['hu1 q()', 32, 'mathColor'],
  ['k3a u()', 34, 'paper'], ['boolean n()', 36, 'flipH'], ['boolean o()', 38, 'flipV'],
  ['boolean w()', 40, 'resizeToFit'], ['vy7 p()', 42, 'margins'], ['boolean v()', 44, 'positionLocked'],
];
for (const [sig, off, name] of FIELDS) {
  ok(rl2.match(new RegExp(sig.replace('(', '\\(').replace(')', '\\)') +
     '[\\s\\S]{0,60}c\\(' + off + '\\)')), `rl2 ${name} @c(${off})`);
}
ok(rl2.includes('CreateBlock('), 'rl2 = CreateBlock');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
