// Phase 1357 — outline/splat baseline attribution fix
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('w4a = synthetic when-map (mislabel)', readFileSync(D + 'w4a.java', 'utf8').includes('synthetic'));
t('bw0 = Bernstein pool (real bezierkit)', readFileSync(D + 'bw0.java', 'utf8').includes('BernsteinPolynomial'));
t('q8a = Cubic/Quadratic pool', readFileSync(D + 'q8a.java', 'utf8').includes('CubicCurve'));
t('lq2 = Quadratic pool', readFileSync(D + 'lq2.java', 'utf8').includes('QuadraticCurve'));
t('bezierkit pkg path', readFileSync(D + 'bw0.java', 'utf8').includes('bezierkit'));
t('CGPoint pool', readFileSync(D + 'cw0.java', 'utf8').includes('CGPoint') || readFileSync(D + 'ky0.java', 'utf8').includes('CGPoint'));
t('LineSegment pool', readFileSync(D + 'q8a.java', 'utf8').includes('LineSegment'));
t('y5a/te6 not outline (mislabel)', !readFileSync(D + 'y5a.java', 'utf8').includes('Bernstein'));
const wob = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/core/algorithm/WidthOutlineBuilder.ets', 'utf8');
t('harmony outline builder', wob.includes('outline') || wob.includes('appendArc') || wob.includes('width'));
t('bezierkit real baseline found', existsSync(D + 'bw0.java'));
console.log('outline-baseline-fix replay: ' + n + '/10 checks green');
