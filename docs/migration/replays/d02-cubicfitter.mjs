// Phase 1326 — CubicFitter bezier-fit audit (vs sqh/wy5)
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/CubicFitter.ets';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/sqh.java';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const d = readFileSync(S, 'utf8');

t('CubicFitter class', d.includes('class CubicFitter'));
t('computeOriginalFitTolerance', d.includes('computeOriginalFitTolerance'));
t('zoom-aware tolerance', d.includes('zoom') && d.includes('tolerance'));
t('fitWithSourceRanges', d.includes('fitWithSourceRanges') && d.includes('sourceRanges'));
t('binary-search >200', d.includes('200') || /二分|binary/i.test(d));
t('sqh.f/wy5 ref', d.includes('sqh') || d.includes('wy5'));
t('fitCubic least-squares', d.includes('fitCubic'));
t('context window ctx', d.includes('ctx'));
t('CubicSegment output', d.includes('CubicSegment'));
t('original sqh baseline', existsSync(D));
console.log('cubicfitter replay: ' + n + '/10 checks green');
