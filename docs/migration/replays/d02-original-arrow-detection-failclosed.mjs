// Phase 578 — original arrow-detection audit: fail-closed pin.
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   y90.c() (mode 0) = arrow detector: corner scan (turn angle >= π/2 runs,
//   max-angle index per run) → split stroke at corner → cg7 shaft must be a
//   t06 LINE + br9 head fit (two ba0 wing recognizers) → combined confidence
//   0.5·shaft + 0.5·min(head, 0.5→clamped-to-1) → t06.g(mask 31) forces
//   s16.J = ARROW.
//   ba0.b() / 1.0.1 analog e90.b(): UnsupportedOperationException — the wing
//   scorer is unrecoverable in both decompilations → detection cannot be
//   ported faithfully → fail-closed (no invented heuristic).
// Verified complete legs that this fixture pins:
//   - l96.W/d1j render: shaft trimmed by scale·46, V head spread scale·20
//     (ShapeGeometry.lineRenderGeometry / originalShapeArrowScale).
//   - inbound op decode accepts arrowHead 0/1 (OriginalShapeGroupOperation).
//   - partial eraser unions the arrow V into the erase outline.
//   - encoder emits the arrow flag for outbound ops.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DET = 'note/src/main/ets/core/algorithm/ShapeDetector.ets';
const GEO = 'note/src/main/ets/core/model/ShapeGeometry.ets';
const OPS = 'note/src/main/ets/data/OriginalShapeGroupOperation.ets';
const ENC = 'note/src/main/ets/data/OriginalCreateShapePayloadEncoder.ets';
const ERASER = 'note/src/main/ets/rendering/OriginalShapePartialEraser.ets';
const PARSER = 'note/src/main/ets/data/NotabilitySessionParser.ets';

const det = readFileSync(DET, 'utf8');
const geo = readFileSync(GEO, 'utf8');
const ops = readFileSync(OPS, 'utf8');
const enc = readFileSync(ENC, 'utf8');
const eraser = readFileSync(ERASER, 'utf8');
const parser = readFileSync(PARSER, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- fail-closed contract: the local detector NEVER produces arrows ---
check(!/ShapeArrowHead\.SINGLE/.test(det),
  'ShapeDetector never emits SINGLE (arrow detector undecompilable — fail-closed)');
check((det.match(/ShapeArrowHead\.NONE/g) || []).length >= 2,
  'all detector results carry explicit NONE');

// --- render leg (l96.W + d1j) is live for decoded/imported arrows ---
check(geo.includes('lineRenderGeometry') &&
  geo.includes('shape.arrowHead === ShapeArrowHead.SINGLE'),
  'render geometry splits SINGLE lines');
check(/scale \* 46/.test(geo) && /scale \* 20/.test(geo),
  'd1j scales: head length c(w)·46, half-spread c(w)·20');
check(/adjusted - 2\)\s*\/\s*2/.test(geo) && /adjusted - 4\)\s*\/\s*4/.test(geo),
  'd1j.c piecewise normalization verbatim ((f-2)/2+2, (f-4)/4+4)');
check(geo.includes('mainPathEndParameter'),
  'shaft trim parameter preserved for PathMeasure parity');
// The V head is open: wing → tip → wing (three points, not closed).
const arrowFn = geo.slice(geo.indexOf('export function lineRenderGeometry'),
  geo.indexOf('function sampleLine'));
check(/base\.x \+ perpendicularX[\s\S]*clonePoint\(tip\)[\s\S]*base\.x - perpendicularX/
  .test(arrowFn), 'V head = base±perp → tip (open path, l96.W)');

// --- op decode leg accepts SINGLE ---
check(/arrowHead === 1 \? ShapeArrowHead\.SINGLE : ShapeArrowHead\.NONE/.test(ops),
  'inbound op decoder maps flag 1 → SINGLE');
check(ops.includes('Line arrow is invalid'), 'op decoder validates arrow range');

// --- encode leg emits the flag ---
check(enc.includes('line.arrowHead === ShapeArrowHead.NONE ? 0 : 36'),
  'encoder emits arrow field offset 36');
check(enc.includes('builder.uint8(table + 36, 1)'),
  'encoder writes SINGLE=1');

// --- eraser leg unions the head into the erase outline ---
check(/shape\.arrowHead === ShapeArrowHead\.SINGLE/.test(eraser) &&
  eraser.includes('shapeArrowPath'), 'partial eraser unions the V head');

// --- parser leg: plist arrow flag has no decompiled evidence → NONE pinned ---
check(parser.includes('arrowHead: ShapeArrowHead.NONE'),
  'session parser stays NONE (plist arrow key is native-side, no evidence)');

console.log(`D02_ORIGINAL_ARROW_DETECTION_FAILCLOSED_OK TOTAL=${n} FAILED=0`);
