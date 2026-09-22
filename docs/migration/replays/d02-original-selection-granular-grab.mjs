// Phase 589 — element-granular selection grab (原版 stc / ej9 case18 parity).
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   dl1.java:98-135 — selection state (ftc) pointer-down: xtc.a(jE, set)
//     hit-tests the topmost element; otc hit whose id ∈ ftc.g →
//     stc({id}) (singleton grab); ntc/cqc group hit with any member ∈ set →
//     stc(cqc.b, cqc.a) (group grab); yxi.e(cmb,…) overlay hit → utc no-op;
//     else qtc → z39(17) = gesture falls through to a new selection.
//   ej9.java:215-244 — case 18: stc ids are SUBTRACTED from ftc.g
//     (ys2.H) and UNIONED into ftc.i (ys2.J) — only the grabbed subset
//     joins the moving set; the rest of the selection stays put.
//   nze.java:103 — ftc.i feeds the transform-apply coroutine (aeg), so the
//     drag transform lands on the moving subset only.
// Harmony pre-Phase-589 deviation: any pointer-down inside selectionRect
//   dragged the ENTIRE selection. Now: topmost-hit element is grabbed
//   (element- or group-granular); missing an element starts a new selection.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const TOOL = 'note/src/main/ets/rendering/SelectionTool.ets';
const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const GEO = 'note/src/main/ets/core/model/ShapeGeometry.ets';

const tool = readFileSync(TOOL, 'utf8');
const canvas = readFileSync(CANVAS, 'utf8');
const geo = readFileSync(GEO, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- SelectionState moving set (ftc.i parity) ---
check(tool.includes('movingIds: string[]'), 'SelectionState carries the moving set');
check(tool.includes('grabElements(ids: string[])'), 'grabElements entry point');
check(tool.includes('clearMoving()'), 'clearMoving on drop');
check(tool.includes('movingSubsetOf(ids: string[])'),
  'movingSubsetOf narrows transform targets');
const movingSubset = tool.slice(tool.indexOf('movingSubsetOf(ids: string[])'),
  tool.indexOf('movingSubsetOf(ids: string[])') + 400);
check(movingSubset.includes('this.state.movingIds.length === 0') &&
  movingSubset.includes('moving.has(id)'),
  'movingSubsetOf: empty → full selection, else moving ∩ selected');
const applyT = tool.slice(tool.indexOf('applyTransform(strokes: StrokeElementData[])'),
  tool.indexOf('applyTransform(strokes: StrokeElementData[])') + 400);
check(applyT.includes('movingSubsetOf(this.state.selectedStrokeIds)'),
  'applyTransform targets the moving subset during a grab');

// --- movingIds lifecycle resets ---
const beginSel = tool.slice(tool.indexOf('beginSelection(mode: SelectionMode'),
  tool.indexOf('beginSelection(mode: SelectionMode') + 900);
check(beginSel.includes('this.state.movingIds = []'), 'new selection clears moving');
check(tool.slice(tool.indexOf('deselect()'), tool.indexOf('deselect()') + 500)
  .includes('this.state.movingIds = []'), 'deselect clears moving');
check(tool.slice(tool.indexOf('selectElementIds(strokeIds'),
  tool.indexOf('selectElementIds(strokeIds') + 1100)
  .includes('this.state.movingIds = []'), 're-select clears moving (drop merge-back)');

// --- Canvas: element-granular hit-test (xtc.a(jE, set) parity) ---
check(canvas.includes('hitTestSelectedElementIds(point: Point2D)'),
  'canvas exposes the grab hit-test');
const hitTest = canvas.slice(canvas.indexOf('hitTestSelectedElementIds(point: Point2D)'),
  canvas.indexOf('hitTestSelectedElementIds(point: Point2D)') + 3200);
check(hitTest.includes('materializePageElements(') &&
  hitTest.includes('i >= 0; i--'),
  'topmost-first iteration over the unified z-order');
check(hitTest.includes('hitStrokeAtPoint(point, element.data)'),
  'strokes use exact coverage (eraser core)');
check(hitTest.includes('pointHitsShape(point, element.data)'),
  'shapes use exact coverage');
check(hitTest.includes('pointHitsAffineBlock(') &&
  hitTest.includes('textBlockLocalBounds(element.data)') &&
  hitTest.includes('imageBlockLocalBounds(element.data)') &&
  hitTest.includes('mathBlockLocalBounds(element.data)'),
  'block kinds use inverse-affine local-rect hits');
check(hitTest.includes('selected.has(hitId)') &&
  hitTest.includes('expandGrabToSelectedGroup(hitId, selected)'),
  'selected hit → element/group grab');
check(hitTest.includes('selectedGroupLeavesContaining(hitId, selected)'),
  'unselected hit → selected-group membership fallback');
check(canvas.includes('resolveOriginalSelectedGroupLeaves('),
  'group grab resolves selected group leaves (cqc parity)');

// --- Canvas: pointer-down branch wiring ---
const branch = canvas.slice(canvas.indexOf('isSelectionActive()'),
  canvas.indexOf('isSelectionActive()') + 1600);
check(branch.includes('hitTestSelectedElementIds(canvasP)'),
  'pointer-down probes the element grab first');
check(branch.includes('this.selectionTool.grabElements(grabIds)'),
  'hit → grabElements + drag start');
check(branch.includes('this.selectionTool.beginSelection('),
  'miss → new selection gesture (qtc → z39 parity)');
check(!branch.includes('pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)'),
  'bounding-rect drag-all removed');

// --- Transform + undo narrowed to the moving subset ---
const applySel = canvas.slice(canvas.indexOf('applySelectionTransform(notifyPersist'),
  canvas.indexOf('applySelectionTransform(notifyPersist') + 1400);
check(applySel.includes('movingSubsetOf(') &&
  applySel.includes('selectedStrokeIds') && applySel.includes('selectedShapeIds') &&
  applySel.includes('selectedTextBlockIds') && applySel.includes('selectedImageIds') &&
  applySel.includes('selectedMathIds'),
  'applySelectionTransform narrows all five kinds');
const drop = canvas.slice(canvas.indexOf('movedStrokeIds'),
  canvas.indexOf('movedStrokeIds') + 2200);
check(drop.includes('movedShapeIds') && drop.includes('movedTextBlockIds') &&
  drop.includes('movedImageIds') && drop.includes('movedMathIds'),
  'drop undo record covers only moved elements');

// --- Generic shape point-hit export ---
check(geo.includes('export function pointHitsShape(point: Point2D, shape: ShapeElement)'),
  'pointHitsShape exported for non-tape grab hits');

console.log(`D02_ORIGINAL_SELECTION_GRANULAR_GRAB_OK TOTAL=${n} FAILED=0`);
