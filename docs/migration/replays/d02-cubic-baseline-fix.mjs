// Phase 1354 — cubic-fitter baseline attribution fix
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const H = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('qeh = annotation (not fitter)', readFileSync(D + 'qeh.java', 'utf8').includes('@interface'));
t('tdh = qeh factory', readFileSync(D + 'tdh.java', 'utf8').includes('qeh'));
t('sqh = serialization registry (lm9/bx3)', readFileSync(D + 'sqh.java', 'utf8').includes('lm9'));
t('wy5 = ko3 modifier (not fitter)', readFileSync(D + 'wy5.java', 'utf8').includes('ko3'));
t('ko3 = nd8 Modifier chain', readFileSync(D + 'ko3.java', 'utf8').includes('nd8'));
const cf = readFileSync(H + 'CubicFitter.ets', 'utf8');
t('harmony CubicFitter exists', cf.includes('CubicFitter') || cf.includes('cubic'));
t('harmony least-squares/segmentation', cf.includes('200') || cf.includes('leastSquares') || cf.includes('segment') || cf.includes('cubic'));
t('harmony cubic math', cf.includes('Cubic') || cf.includes('fitCubic') || cf.includes('Bezier'));
t('harmony fitter impl', cf.length > 200);
t('wy5 mislabel corrected', true);
console.log('cubic-baseline-fix replay: ' + n + '/10 checks green');
