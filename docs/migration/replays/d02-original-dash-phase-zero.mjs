// Phase 574 — original DASH/DOTS center-path dash phase is always 0.
// Original semantics decoded from decompiled_1.0.3:
//   c5g.java:223/237   DashPathEffect({2f*w,1f*w} / {0.001f*w,2f*w}, 0.0f) —
//                      the live-stroke dash phase is a literal 0.0f constant.
//   e16.java:131/147   p16.centralPathPaint DashPathEffect(intervals, 0.0f) —
//                      the persisted-stroke renderer also uses literal 0.0f.
//   c5g.java:44-59     cap/join table: DASH=BUTT/ROUND, DOTS=ROUND/MITER,
//                      solid=ROUND/ROUND; every paint BlendMode.SRC_OVER.
//   c5g.java:250       isHighlighter → zx1.e(color, 107) alpha *override*.
//   yyd.java:53-60     StyleMap(backingPencilSeed, backingPencilReferencePoint,
//                      backingDashPhase@12, backingDashPeriod@16) wire layout.
//   ft1.java:91        slice advance: ((distance + phase) % period + period)
//                      % period with period = 3w (DASH) / 2.001w (DOTS);
//                      emits uyd("Dash(phase=...)") carriers.
//   s06.java:396-397 / qee.java:82-87 / o0j.java:566 — backingDashPhase feeds
//                      only rz1.H → l06.phaseOffsetPx (RAINBOW/GLITTER
//                      InkEffectSpec, ADR-0046); it never reaches a PathEffect.
// Harmony previously offset the dash pattern by styleMap[0].backingDashPhase,
// which the original never does — sliced/imported strokes rendered shifted.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const RENDERER = 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets';
const PAINTER = 'note/src/main/ets/rendering/StrokeCanvasPainter.ets';
const ERASER = 'note/src/main/ets/rendering/OriginalInkPartialEraser.ets';

const renderer = readFileSync(RENDERER, 'utf8');
const painter = readFileSync(PAINTER, 'utf8');
const eraser = readFileSync(ERASER, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- dash/dot intervals match c5g.java:223/237 and e16.java:131/147 ---
const center = renderer.slice(
  renderer.indexOf('renderCenterPath(stroke: StrokeElementData'),
  renderer.indexOf('renderVariableWidthOutline(stroke: StrokeElementData'));
check(center.includes('setLineDash([2 * spec.brushWidth, 1 * spec.brushWidth])'),
  'DASH intervals [2w,1w]');
check(center.includes('setLineDash([0.001 * spec.brushWidth, 2 * spec.brushWidth])'),
  'DOTS intervals [0.001w,2w]');

// --- phase must NOT be applied to the center-path dash (original = 0.0f) ---
check(!center.includes('setLineDashOffset('),
  'renderCenterPath never offsets the dash pattern');
check(center.indexOf('c.setLineDashOffset') === -1,
  'no backingDashPhase render consumer in center path');
check(center.includes('DashPathEffect(intervals, 0.0f)') ||
  center.includes('0.0f'), 'evidence comment records the 0.0f phase');

// --- cap/join table matches c5g.java:44-59 ---
check(/inkStyle === InkStyle\.DASH\)[\s\S]{0,40}setLineCap\('butt'\)/.test(center),
  'DASH cap = butt');
check(/setLineJoin\(spec\.inkStyle === InkStyle\.DOTS \? 'miter' : 'round'\)/.test(center),
  'DOTS join = miter, others round');

// --- highlighter alpha override 107 (zx1.e), not a blend mode ---
check(center.includes('spec.isHighlighter ? 107 : undefined'),
  'highlighter alpha override = 107');
check(!center.includes('setGlobalCompositeOperation'),
  'center path keeps SRC_OVER (no multiply blend)');

// --- styleMap phase still advances on slice (ft1/uyd bookkeeping) ---
check(eraser.includes('backingDashPhase: phase'),
  'partial-eraser still writes advanced backingDashPhase');
check(/period > 0 \?\s*\(\(basePhase \+ center\.startDistance\) % period \+ period\) % period : 0/
    .test(eraser.replace(/\s+/g, ' ')),
  'slice advance = ((base+start)%period+period)%period');
check(eraser.includes('3 * source.renderSpec.brushWidth') &&
  eraser.includes('2.001 * source.renderSpec.brushWidth'),
  'slice period = 3w / 2.001w');

// --- painter dispatch unchanged: DASH/DOTS clip then center-path ---
check(painter.includes('this.renderer.renderCenterPath(stroke, rc)'),
  'center-path render still dispatched');
check(/renderCustomPath\(stroke: StrokeElementData[\s\S]*?renderCenterPath\(stroke, ctx\)/
    .test(renderer), 'customPath DASH/DOTS still clip → center stroke');

// --- try/finally save/restore convention kept ---
check(/c\.save\(\);\s*try/.test(renderer), 'save/try guard');
check(/finally \{\s*c\.restore\(\);/.test(renderer), 'restore/finally guard');

console.log(`D02_ORIGINAL_DASH_PHASE_ZERO_OK TOTAL=${n} FAILED=0`);
