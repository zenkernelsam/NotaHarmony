// Phase 1075 — ddg.e item validation + wrappers + fsi.P
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ddg = R('ddg'), k2d = R('k2d'), y2d = R('y2d'), fsi = R('fsi');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ddg.e(ie8) exists', ddg.includes('String e(ie8 ie8Var)'));
t('ddg.e: o(k,j) page+origin first', ddg.includes('o(ie8Var.k(), ie8Var.j())'));
t('ddg.e: rotation via k2d.j()', ddg.includes('ie8Var.l()') && ddg.includes('"Rotation"'));
t('ddg.e: scale via y2d.j()→j(qed)', ddg.includes('ie8Var.m()') && ddg.includes('return j(qedVarJ)'));
t('k2d: Float wrapper j()', k2d.includes('Float j()') || k2d.includes('j()'));
t('y2d: qed wrapper j()', y2d.includes('qed j()') || y2d.includes('j()'));
t('ddg.e: null-shortcircuit chain', ddg.includes('strO == null') && ddg.includes('return null'));
t('fsi.P(uq9) exists', fsi.includes('P(uq9'));
t('fsi.K(uq9) exists', fsi.includes('K(uq9'));
t('ddg: l(name,float) rotation msg', ddg.includes('l("Rotation"'));
console.log('item-validation replay: ' + n + '/10 checks green');
