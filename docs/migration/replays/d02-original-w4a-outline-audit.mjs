// Phase 579 — w4a variable-width outline pipeline audit pins.
// Original evidence (decompiled_1.0.1/sources/defpackage — the audit's w4a
// reference is the 1.0.1 obfuscation map; 1.0.3's w4a is an unrelated
// synthetic switchmap):
//   w4a.a(xw0, d2): cumulative-distance simplification. Callers:
//     y5a.n:  pre-outline normalize with d2=0 (keeps everything);
//     lqh.b:  post-outline simplify with d2=0.1.
//   w4a.b(xw0, scale): outline builder over attributed components (ic0).
//     - degenerate: single-element/single-point component with equal
//       first/last width attrs and extent <= 1e-4 -> emits circle
//       radius = widthAttr * 0.5 * globalScale * componentScale (z71 ellipse).
//     - width chain: per-element arc lengths clamped >= 1e-6, PCHIP
//       derivatives (3(h1+h2)/((2h1+h2)/m2 + (2h2+h1)/m1)), probes at
//       oki.a={0.25,0.5,0.75}, deviation*1.2 vs max(maxW,0.05)*0.005,
//       subdivisions ceil(sqrt(dev/tol)) clamped 2..6 — identical to the
//       Phase 269 constants already in WidthOutlineBuilder.
//   y5a.n:   DASH/DOTS strokes take the raw centerline path (stroked), only
//            solid strokes go through w4a.b (filled outline).
//   lqh.b:   eraser outline -> simplify(0.1) -> b2j.a simplicity check ->
//            if self-intersecting, recursive splitAtMiddleElement bisection.
//            Harmony instead uses drawing.Path.op booleans which resolve
//            self-intersection natively (documented divergence, ADR-0550).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const BUILDER = 'note/src/main/ets/core/algorithm/WidthOutlineBuilder.ets';
const RENDERER = 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets';
const ERASER = 'note/src/main/ets/rendering/OriginalInkPartialEraser.ets';

const builder = readFileSync(BUILDER, 'utf8');
const renderer = readFileSync(RENDERER, 'utf8');
const eraser = readFileSync(ERASER, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// Degenerate single-point stroke -> circle of half effective width
// (w4a.b z71 branch: radius = w * 0.5 * scale).
check(builder.includes('cleaned.length === 1'),
  'single surviving sample detected');
check(/buildDegenerateCircle\(cleaned\[0\]\.position,\s*cleaned\[0\]\.widthFactor \* baseWidth \/ 2\)/.test(builder),
  'degenerate circle radius = widthFactor * baseWidth / 2 (w4a.b z71)');
check(builder.includes('buildDegenerateCircle'),
  'degenerate circle emitter present');

// Degenerate-sample merge retains the larger widthFactor — superset of the
// original's cumulative-distance simplify (pressure peak preserved).
check(/result\[result\.length - 1\]\.widthFactor = Math\.max/.test(builder),
  'near-duplicate merge keeps max widthFactor');

// Width-chain constants verbatim (PCHIP 1e-6 / 1.2 / 0.5% / 0.05 / probes / 2..6).
check(/ORIGINAL_WIDTH_MIN_COMPONENT_LENGTH: number = 0\.000001/.test(builder), 'min component length 1e-6');
check(/ORIGINAL_WIDTH_DEVIATION_SCALE: number = 1\.2/.test(builder), 'deviation scale 1.2');
check(/ORIGINAL_WIDTH_RELATIVE_TOLERANCE: number = 0\.005/.test(builder), 'relative tolerance 0.5%');
check(/ORIGINAL_WIDTH_MIN_REFERENCE: number = 0\.05/.test(builder), 'min width reference 0.05');
check(/ORIGINAL_WIDTH_PROBES: number\[\] = \[0\.25, 0\.5, 0\.75\]/.test(builder), 'probes 0.25/0.5/0.75');
check(/ORIGINAL_WIDTH_MIN_SUBDIVISIONS: number = 2/.test(builder) &&
  /ORIGINAL_WIDTH_MAX_SUBDIVISIONS: number = 6/.test(builder), 'subdivision clamp 2..6');

// y5a.n parity: dash/dots strokes render the raw stroked centerline, not a
// filled outline — Harmony renderCenterPath path (Phase 574 c5g/e16 decode).
check(renderer.includes('renderCenterPath'),
  'dash/dots use stroked centerline (y5a.n z-branch)');

// Eraser leg: original resolves self-intersecting outlines by recursive
// bisection + b2j.a simplicity check; Harmony uses drawing.Path.op booleans.
check(eraser.includes('drawing.PathOp') || eraser.includes('PathOp'),
  'eraser uses native PathOp booleans (ADR-0550 divergence)');

console.log(`D02_ORIGINAL_W4A_OUTLINE_AUDIT_OK TOTAL=${n} FAILED=0`);
