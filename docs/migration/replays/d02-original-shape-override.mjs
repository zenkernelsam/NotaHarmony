// Phase 577 — original shape-detection arbitration (e5d.b) parity.
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   e5d.b: candidates compete on confidence; final accept gate is
//     confidence > 0.2 (strict).
//   Override: best LINE → first ELLIPSE candidate with confidence > 0.3
//     wins; best POLYGON with b16.h() (uneven edges) → first candidate
//     > 0.3 wins, then specifically first circle-ELLIPSE (m06.h==m06.i)
//     > 0.3 wins.
//   s16: I=LINE J=ARROW K=POLYGON L=ELLIPSE M=BEZIERGON.
//   b16.h(): min|edge|/max|edge| < 0.25 over segment lengths
//     (gih.g = mih.c = segment distance; g() wraps first→last when closed).
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const DET = 'note/src/main/ets/core/algorithm/ShapeDetector.ets';
const det = readFileSync(DET, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- thresholds ---
check(det.includes('ORIGINAL_SHAPE_RECOGNITION_CONFIDENCE_THRESHOLD: number = 0.2'),
  'accept gate 0.2 (e5d f4 > 0.2f)');
check(det.includes('ORIGINAL_SHAPE_OVERRIDE_CONFIDENCE: number = 0.3'),
  'override gate 0.3 (e5d a > 0.3f loops)');
check(det.includes('ORIGINAL_POLYGON_UNEVEN_EDGE_RATIO: number = 0.25'),
  'b16.h uneven-edge ratio 0.25');

// --- candidate metadata + arbitration wiring ---
check(/kind: number;[\s\S]*closed: boolean;[\s\S]*circle: boolean;[\s\S]*unevenEdges: boolean;/
  .test(det), 'DetectionResult carries arbitration metadata');
check(det.includes('this.applyOriginalOverride(candidates, best)'),
  'override runs after argmax, before accept gate');

// --- override rules ---
const ov = det.slice(det.indexOf('private applyOriginalOverride'),
  det.indexOf('private firstStrongCandidate'));
check(ov.includes('best.kind === SHAPE_KIND_LINE'),
  'LINE winner eligible for ellipse override');
check(/firstStrongCandidate\(candidates, SHAPE_KIND_ELLIPSE, false\)/.test(ov),
  'LINE → first ELLIPSE > 0.3');
check(ov.includes('best.kind === SHAPE_KIND_POLYGON && best.unevenEdges'),
  'uneven POLYGON winner eligible for override');
check(/firstStrongCandidate\(candidates, -1, false\)/.test(ov),
  'uneven POLYGON → first candidate > 0.3 (any kind)');
check(/firstStrongCandidate\(candidates, SHAPE_KIND_ELLIPSE, true\)/.test(ov),
  'uneven POLYGON → first circle-ELLIPSE > 0.3');
check(ov.indexOf('SHAPE_KIND_ELLIPSE, true') > ov.indexOf('candidates, -1'),
  'circle override evaluated after the any-kind override (e5d order)');

// --- uneven-edge gate (b16.h: min/max < 0.25; closed wraps last→first) ---
const ue = det.slice(det.indexOf('private hasUnevenEdges'));
check(ue.includes('closed ? vertices.length : vertices.length - 1'),
  'closed ring includes wrap edge, open excludes it');
check(ue.includes('Math.abs(minEdge) / Math.abs(maxEdge) < ORIGINAL_POLYGON_UNEVEN_EDGE_RATIO'),
  'min/max edge ratio gate');

// --- circle flag: m06.h == m06.i after normalization ---
check(/const circle: boolean = rx === ry;/.test(det),
  'circle = post-normalization rx === ry (m06 major==minor)');

// --- candidate kinds tagged ---
check(det.includes('kind: SHAPE_KIND_LINE'), 'line detector tagged');
check(det.includes('kind: SHAPE_KIND_ELLIPSE'), 'ellipse detector tagged');
check((det.match(/kind: SHAPE_KIND_POLYGON/g) || []).length === 2,
  'polygon open+closed results both tagged POLYGON (b16.b variants)');

console.log(`D02_ORIGINAL_SHAPE_OVERRIDE_OK TOTAL=${n} FAILED=0`);
