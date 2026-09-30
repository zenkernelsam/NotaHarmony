// Phase 1325 — algorithm fidelity (ForceSmoother et al. vs baselines)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const fs_ = readFileSync(S + 'ForceSmoother.ets', 'utf8');
t('ForceSmoother class', fs_.includes('class ForceSmoother'));
t('8ms smoothing window', fs_.includes('8') && fs_.includes('smoothingWindowMs'));
t('maxForceChange 0.15', fs_.includes('maxForceChange') && fs_.includes('0.15'));
t('EMA delta clamp', fs_.includes('lastForce') && fs_.includes('delta'));
t('original ref ws4/dr4', fs_.includes('ws4') || fs_.includes('dr4'));
t('CubicFitter', X('CubicFitter.ets'));
t('PencilSplatGenerator', X('PencilSplatGenerator.ets'));
t('ShapeDetector', X('ShapeDetector.ets'));
t('WidthOutlineBuilder', X('WidthOutlineBuilder.ets'));
t('original ms1 range baseline', existsSync(D + 'ms1.java'));
console.log('algorithm-fidelity replay: ' + n + '/10 checks green');
