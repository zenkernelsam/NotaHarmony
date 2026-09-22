// Phase 586 — original tap-to-reveal tapes (dl1 case2 → xtc.b → ej9 case20 → xo5).
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java:80-95 — every canvas pointer-down calls xtcVar.b(jE) BEFORE the
//     tool state machine; a non-null action consumes the gesture.
//   xtc.java:39-73 — b(long j): hit-test the page element under the point, must
//     be a Tape (otcVar.a().I.k()); fu1.f collects ALL elements covering the
//     point, filter to tapes, collect element ids; falls back to the first hit
//     id when the broader query is empty; returns ej9(20, set).
//   ej9.java:256-263 — case 20 dispatches fvbVar2.a.c(new xo5(2, set)).
//   xo5.java:32-50 — case 2 toggle: if every incoming id is already in the
//     revealed set, subtract the set; otherwise union it.
// Harmony:
//   NoteCanvasView.onTouchDown probes tapRevealTapeAt(canvasP) before eraser /
//     selection / laser / ink dispatch and at the head of the DEFAULT text
//     branch; a hit consumes the gesture (early return, isDrawing stays false).
//   tapeIdsAtPoint collects every tape element covering the point: strokes with
//     renderSpec.tapePattern != null (band hit via EraserEngine.hitStrokeAtPoint)
//     and shapes with originalTool === 3 (tapeHitTestShape — same coverage
//     geometry as the eraser but ignoring positionLocked, reveal is not an edit).
//   tapRevealTapeAt applies the xo5 toggle on the covered id set, then emits the
//     session reveal state and repaints.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const ERASER = 'note/src/main/ets/rendering/EraserEngine.ets';
const GEO = 'note/src/main/ets/core/model/ShapeGeometry.ets';

const view = readFileSync(VIEW, 'utf8');
const eraser = readFileSync(ERASER, 'utf8');
const geo = readFileSync(GEO, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Stroke band hit test (xtc.a / fu1 coverage over the rendered band) ---
check(eraser.includes('hitStrokeAtPoint'), 'EraserEngine exposes the point hit test');
const hit = eraser.slice(eraser.indexOf('hitStrokeAtPoint'));
check(hit.includes('this.sampleStroke(stroke)'),
  'stroke sampling reuses transform/cubic-aware pipeline');
check(hit.includes('stroke.renderSpec.brushWidth * widthFactor * scale / 2'),
  'hit radius = rendered half-band (widthFactor × transform scale)');
check(hit.includes('this.maximumLinearScale(stroke.transform)'),
  'stroke transform scales the hit band');

// --- Shape coverage (tape shapes: originalTool === 3) ---
check(geo.includes('export function tapeHitTestShape'),
  'tape shape point hit test exported');
const shapeHit = geo.slice(geo.indexOf('export function tapeHitTestShape'),
  geo.indexOf('export function tapeHitTestShape') + 400);
check(shapeHit.includes('shapeCoveredByPath([point], shape, 0)'),
  'shape test shares the eraser coverage geometry at zero width');
check(geo.includes('function shapeCoveredByPath'),
  'eraser/tape coverage share one geometry core');
// tapeHitTestShape must NOT inherit the eraser's positionLocked bail-out:
const eraserFn = geo.slice(geo.indexOf('export function eraserPathHitsShape'),
  geo.indexOf('export function eraserPathHitsShape') + 400);
check(eraserFn.includes('shape.positionLocked === true'),
  'positionLocked still guards the eraser only');

// --- All-tapes-under-point collection (fu1.f + I.k() filter) ---
const collect = view.slice(view.indexOf('private tapeIdsAtPoint'),
  view.indexOf('private tapeIdsAtPoint') + 1400);
check(collect.includes('this.completedStrokes'),
  'iterates completed strokes');
check(collect.includes('stroke.renderSpec.tapePattern === undefined') &&
  collect.includes('stroke.renderSpec.tapePattern === null'),
  'stroke tape filter = renderSpec.tapePattern non-null');
check(collect.includes('this.eraserEngine.hitStrokeAtPoint(point, stroke)'),
  'stroke coverage via the band hit test');
check(collect.includes('shape.originalTool === 3') &&
  collect.includes('tapeHitTestShape(point, shape)'),
  'shape tape filter = originalTool TAPE(3) + shape coverage');
check(collect.indexOf('ids.push(stroke.id)') > -1 &&
  collect.indexOf('ids.push(shape.id)') > -1,
  'collects every covering tape id, not just the first');

// --- xo5 case2 toggle semantics on the covered set ---
const toggle = view.slice(view.indexOf('private tapRevealTapeAt'),
  view.indexOf('private tapRevealTapeAt') + 1400);
check(toggle.includes('tapeIds.every'), 'all-revealed check over the covered set');
check(toggle.includes('this.revealedTapeIds.delete(id)') &&
  toggle.includes('this.revealedTapeIds.add(id)'),
  'subtract-if-all-present else union (xo5 parity)');
check(toggle.includes('this.emitTapeRevealState()') &&
  toggle.includes('this.renderFrame(true)'),
  'toggle emits session state and repaints');
check(toggle.includes('return true') && toggle.includes('return false'),
  'hit consumes the gesture, miss falls through');

// --- Pointer ordering: before tool dispatch (dl1 case2 parity) ---
const down = view.slice(view.indexOf('private onTouchDown'),
  view.indexOf('private onTouchMove'));
const tapeCall = down.indexOf('if (this.tapRevealTapeAt(canvasP))');
check(tapeCall > -1, 'onTouchDown probes the tape hit');
check(tapeCall < down.indexOf('this.viewModel.isEraserActive()') &&
  tapeCall < down.indexOf('this.viewModel.isSelectionActive()') &&
  tapeCall < down.indexOf('this.viewModel.isLaserActive()') &&
  tapeCall < down.indexOf('new StrokeSession(spec)'),
  'tape probe precedes eraser/selection/laser/ink dispatch');
check(down.indexOf('tapRevealTapeAt(canvasP)') < down.indexOf('this.isDrawing = true'),
  'a tape hit consumes the gesture before isDrawing');
// DEFAULT text-input branch: tape probe precedes checkbox/double-tap handling.
const def = down.slice(down.indexOf('currentTool === ToolType.DEFAULT'),
  down.indexOf('currentTool === ToolType.DEFAULT') + 1200);
check(def.indexOf('tapRevealTapeAt(canvasP)') < def.indexOf('toggleCheckboxMarkerAt'),
  'DEFAULT branch probes tape before text gestures');
check(def.includes('this.lastTapTime = 0'),
  'consumed tap resets the double-tap clock');

// --- Global toggle set also covers tape shapes (fu1/vnd element parity) ---
const pageIds = view.slice(view.indexOf('private pageTapeIds'),
  view.indexOf('private pageTapeIds') + 700);
check(pageIds.includes('this.shapes') && pageIds.includes('shape.originalTool === 3'),
  'pageTapeIds includes tape shapes');

console.log(`D02_ORIGINAL_TAPE_TAP_REVEAL_OK TOTAL=${n} FAILED=0`);
