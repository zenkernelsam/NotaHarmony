// Phase 575 — audit 3.3 closure: obfuscated-class resolution invariants.
// Original evidence (decompiled_1.0.1 defpackage):
//   hc0.java (implements fc0): SingleAttribute — a()=altitudeAngle,
//     b()=azimuthUnitVectorX, c()=azimuthUnitVectorY, d()=force,
//     e()=strokeWidth.
//   f92.java:71-73: c(d,m,b,dv)=(d*m+b)/dv — affine; xaa.b call args
//     (1.0,0.0,1.0) make it an identity, NOT a clamp (A-19 no-op).
//   dd4.java:46-60: d(d)=clamp(d,2.6,18.0); ms1.java:180 tolerance =
//     0.5/(((clamp(w*zoom,2.6,18)-2.6)/15.4)*1.5+1)/zoom — no Math.log.
//   nnf.java + ekd.java: undo/redo lists are unbounded snapshot-state
//     persistent lists; tzc/nzc CRDT session undo has no numeric cap.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const FITTER = 'note/src/main/ets/core/algorithm/CubicFitter.ets';
const SPLAT = 'note/src/main/ets/core/algorithm/PencilSplatGenerator.ets';
const UNDO = 'note/src/main/ets/rendering/UndoRedoManager.ets';

const fitter = readFileSync(FITTER, 'utf8');
const splat = readFileSync(SPLAT, 'utf8');
const undo = readFileSync(UNDO, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- A-07: tolerance formula = 0.5/(((clamp(w*zoom,2.6,18)-2.6)/15.4)*1.5+1)/zoom
const tol = fitter.slice(
  fitter.indexOf('computeOriginalFitTolerance'),
  fitter.indexOf('export class CubicFitter'));
check(tol.includes('Math.min(18, Math.max(baseWidth * scale, 2.6))'),
  'clamp [2.6,18] on scaled width');
check(tol.includes('(0.5 / ((((screenWidth - 2.6) / 15.4) * 1.5) + 1.0)) / scale'),
  'rational tolerance formula, divided by zoom');
check(!tol.includes('Math.log'), 'no logarithm in tolerance');

// --- A-15: angleDiff and sizeFactor share altitudeAngleRadians ---
check(splat.includes('const angleDiff: number = Math.max(Math.PI / 5 - altitude, 0)'),
  'angleDiff uses altitude (=altitudeAngleRadians)');
check(/altitude: number = attrs\.altitudeAngleRadians/.test(splat),
  'altitude sourced from altitudeAngleRadians');
const sizeBody = splat.slice(splat.indexOf('private sizeFactorOf'),
  splat.indexOf('private generateAtPosition'));
check(sizeBody.includes('attrs.altitudeAngleRadians'),
  'sizeFactorOf tilt input = altitudeAngleRadians (same field as angleDiff)');
check(!sizeBody.includes('attrs.azimuthUnitX') && !sizeBody.includes('orientation'),
  'sizeFactor does not use a divergent field');

// --- A-17: splat offset direction = azimuth unit vector, not curve tangent ---
check(splat.includes('attrs.azimuthUnitX') && splat.includes('attrs.azimuthUnitY'),
  'direction vector from azimuthUnitX/Y');
check(/hasAzimuth.*0\.000001/.test(splat) && splat.includes(': 1,') &&
  splat.includes(': 0,'), '(1,0) fallback when azimuth absent (a61.f)');
check(splat.includes('(len * tx - x * ty)') && splat.includes('(len * ty + x * tx)'),
  'xaa.b L216-218 rotation form preserved');

// --- A-19: no clamp after opacityFactor*edgeFactor*scaleBase (identity call) ---
check(splat.includes('const opacity: number = opacityFactor * edgeFactor * scaleBase'),
  'opacity = factor*edge*base with no extra clamp');

// --- R-32: port-side dual budget exists and is constructor-configurable ---
check(undo.includes('DEFAULT_HISTORY_MAX_ACTIONS: number = 128'),
  'action budget 128');
check(undo.includes('DEFAULT_HISTORY_MAX_BYTES: number = 32 * 1024 * 1024'),
  'byte budget 32MB');
check(/while \(this\.undoStack\.length > this\.maxActions \|\| this\.undoBytes > this\.maxEstimatedBytes\)/
    .test(undo), 'eviction on either budget');
check(!undo.includes('maxStackSize'), 'stale fixed-50 cap removed');

console.log(`D02_ORIGINAL_ATTRIBUTE_RESOLUTION_OK TOTAL=${n} FAILED=0`);
