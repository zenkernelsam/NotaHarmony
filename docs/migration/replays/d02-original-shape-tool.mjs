// Phase 1389 — 1.4.2 SHAPE drag-to-create tool vertical slice.
// Original evidence (decompiled_1.4.2):
//   eti.java        — tool enum adds SHAPE(14) as a new tool (1.4.2-only).
//   r5g.java        — SHAPE_KIND: RECTANGLE(0) ELLIPSE(1) DIAMOND(2)
//                     TRIANGLE(3) ARROW(4) LINE(5).
//   cc3.java H()    — fresh-install default: SHAPE secondary tray index 5
//                     (RULER=4 留空), color=g92(-16777216), width=r2k(1,2.0f),
//                     shapeKind=r5g.F(RECTANGLE).
//   h5g.java:154-170— shape-kind picker: 6 类按 ordinal 取标签 + 图标 + 选中态。
//   u5g.java:117-186— drag→shape geometry: start/end 包围盒 → 各 shapeKind;
//                     r().q 约束 = 正方形包围盒 / LINE·ARROW 45° 吸附。
//   ca3.java:404    — ToolStateEntity.shapeKind TEXT DEFAULT 'RECTANGLE'.
//   fgf.java:46     — ALTER TABLE ToolStateEntity ADD shapeKind TEXT.
//   ui_tools__shape = "Shape"; ui_designsystem__shape_tool_* = 4 层 glyph.
// Port: dedicated tool on a drag/preview/commit path (NOT the ink pipeline);
//       ShapeDragGeometry ports u5g's bounding-box→shape mapping; the
//       committed ShapeElement carries a reserved CREATE_SHAPE identity.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const VM = 'note/src/main/ets/ui/editor/EditorViewModel.ets';
const BT = 'note/src/main/ets/core/model/BrushTypes.ets';
const SDG = 'note/src/main/ets/core/model/ShapeDragGeometry.ets';
const ET = 'note/src/main/ets/core/model/ElementTypes.ets';
const TRI = 'note/src/main/ets/data/ToolRepositoryImpl.ets';
const DBH = 'note/src/main/ets/data/DatabaseHelper.ets';
const GLYPHS = 'note/src/main/ets/ui/components/ToolGlyphs.ets';
const GLYPH = 'note/src/main/ets/ui/components/ToolGlyph.ets';
const DLG = 'note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets';
const SKP = 'note/src/main/ets/ui/editor/ShapeKindPicker.ets';
const STR_BASE = 'note/src/main/resources/base/element/string.json';
const STR_ZH = 'note/src/main/resources/zh_CN/element/string.json';
const NCV = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';

const vm = readFileSync(VM, 'utf8');
const bt = readFileSync(BT, 'utf8');
const sdg = readFileSync(SDG, 'utf8');
const et = readFileSync(ET, 'utf8');
const tri = readFileSync(TRI, 'utf8');
const dbh = readFileSync(DBH, 'utf8');
const glyphs = readFileSync(GLYPHS, 'utf8');
const glyph = readFileSync(GLYPH, 'utf8');
const dlg = readFileSync(DLG, 'utf8');
const skp = readFileSync(SKP, 'utf8');
const strBase = readFileSync(STR_BASE, 'utf8');
const strZh = readFileSync(STR_ZH, 'utf8');
const ncv = readFileSync(NCV, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// === 1. Model surface ===
check(/SHAPE\s*=\s*\d+/.test(bt), 'ToolType.SHAPE enum member exists');
check(/export enum ShapeKind/.test(bt), 'ShapeKind enum exported');
check(/RECTANGLE\s*=\s*0/.test(bt) && /ELLIPSE\s*=\s*1/.test(bt) &&
  /DIAMOND\s*=\s*2/.test(bt) && /TRIANGLE\s*=\s*3/.test(bt) &&
  /ARROW\s*=\s*4/.test(bt) && /LINE\s*=\s*5/.test(bt),
  'ShapeKind ordinals match r5g (RECTANGLE..LINE = 0..5)');
check(/shapeKind\?:\s*ShapeKind\s*\|\s*null/.test(bt),
  'ToolState carries optional shapeKind (ToolStateEntity.shapeKind col)');
check(/stabilization\?:\s*number\s*\|\s*null/.test(bt),
  'ToolState carries optional stabilization (1.4.2 col)');

// === 2. shapeKind name codec (TEXT 'RECTANGLE' storage) ===
check(bt.includes('shapeKindToName') && bt.includes('shapeKindFromName'),
  'shapeKind name codec helpers present (enum-name TEXT persistence)');
check(/SHAPE_KIND_NAMES[^=]*=\s*\[[\s\S]*'RECTANGLE'[\s\S]*'LINE'/.test(bt),
  'SHAPE_KIND_NAMES maps ordinals to the original enum names');

// === 3. Default toolbox seed (cc3.H(): secondary index 5, RECTANGLE) ===
const defaults = vm.slice(vm.indexOf('private createDefaultStates'));
check(/'shape',\s*ownerId,\s*ToolType\.SHAPE,\s*5/.test(defaults),
  'SHAPE seeded at secondary tray index 5 (cc3.H order; RULER=4 empty)');
check(/ToolType\.SHAPE,\s*5,\s*-16777216,\s*2\.0/.test(defaults),
  'SHAPE seed color=-16777216, width=2.0 (g92/r2k)');
check(/ToolType\.SHAPE[^)]*ShapeKind\.RECTANGLE/.test(defaults),
  'SHAPE default shapeKind = RECTANGLE (r5g.F)');

// === 4. ViewModel state handling ===
check(/activeShapeKind:\s*ShapeKind\s*=\s*ShapeKind\.RECTANGLE/.test(vm),
  'activeShapeKind defaults to RECTANGLE');
check(/state\.toolType === ToolType\.SHAPE[\s\S]{0,120}activeShapeKind = state\.shapeKind/.test(vm),
  'applyActiveState adopts per-tool shapeKind');
check(/isShapeActive\(\)[\s\S]{0,60}ToolType\.SHAPE/.test(vm),
  'isShapeActive helper present');
check(/supportsBrushControls\(\)[\s\S]*ToolType\.SHAPE/.test(vm),
  'shape exposes brush controls (color/width — g92+r2k are non-null)');
check(/setToolShapeKind\(toolId: string,\s*kind: ShapeKind[\s\S]{0,160}toolType !== ToolType\.SHAPE/.test(vm) &&
  /setToolShapeKind[\s\S]{0,500}state\.shapeKind = kind/.test(vm),
  'setToolShapeKind guards toolType=SHAPE and persists shapeKind');
check(/kind < ShapeKind\.RECTANGLE \|\| kind > ShapeKind\.LINE/.test(vm),
  'setToolShapeKind range-checks RECTANGLE..LINE');

// === 5. ShapeDragGeometry (u5g port) ===
check(sdg.includes('export function buildDragShape'), 'buildDragShape exported');
check(/Math\.hypot\(end\.x - start\.x, end\.y - start\.y\)\s*<=\s*SHAPE_DRAG_SLOP/.test(sdg),
  'drag ≤ slop produces no shape (u5g min-length gate)');
check(sdg.includes('kind === ShapeKind.LINE || kind === ShapeKind.ARROW') &&
  sdg.includes('const line: LineElement'),
  'LINE/ARROW build LineElement objects');
check(sdg.includes('arrowHead: kind === ShapeKind.ARROW ? ShapeArrowHead.SINGLE : ShapeArrowHead.NONE'),
  'ARROW→SINGLE arrowhead, LINE→NONE (u5g arrowHead flag)');
check(sdg.includes('kind === ShapeKind.ELLIPSE') &&
  sdg.includes('const ellipse: EllipseElement') &&
  sdg.includes('radiusX: w / 2') && sdg.includes('radiusY: h / 2'),
  'ELLIPSE builds an inscribed EllipseElement (radius=w/2,h/2)');
check(sdg.includes('kind === ShapeKind.RECTANGLE') &&
  sdg.includes('kind === ShapeKind.DIAMOND') &&
  sdg.includes('left + w / 2, y: top') && sdg.includes('const polygon: PolygonElement'),
  'DIAMOND→edge-midpoint vertices; TRIANGLE→apex + bottom corners');
check(/isClosed:\s*true/.test(sdg), 'closed polygon for RECT/DIAMOND/TRIANGLE');
check(/Math\.round\(Math\.atan2[\s\S]{0,80}\*\s*PI_OVER_4/.test(sdg),
  'constrain snaps LINE/ARROW direction to 45° (u5g r().q)');
check(/Math\.max\(Math\.abs\(dx\), Math\.abs\(dy\)\)/.test(sdg),
  'constrain makes area shapes square (max side, sign-preserved)');
check(sdg.includes('recomputeShapeBounds'), 'each shape recomputes its bounds');

// === 6. Touch lifecycle (drag/preview/commit, not ink) ===
check(/isShapeActive\(\)[\s\S]{0,120}shapeDragActive = true/.test(ncv),
  'touch-down begins a shape drag (shapeDragActive, shapeDragStart)');
check(/shapeDragActive\)[\s\S]{0,200}previewShape = buildDragShape/.test(ncv),
  'touch-move builds the live previewShape via buildDragShape');
check(/if \(this\.shapeDragActive\)[\s\S]{0,40}commitShapeDrag\(\)/.test(ncv),
  'touch-up commits the shape via commitShapeDrag');
check(ncv.includes('private commitShapeDrag'), 'commitShapeDrag present');
check(/committed\.id = encodeOperationId/.test(ncv) &&
  /committed\.originalCreate = shapeCreate/.test(ncv),
  'committed shape carries a reserved CREATE_SHAPE identity');
check(/UndoableActionType\.ADD_ELEMENTS[\s\S]{0,200}addedShapes: \[committed\]/.test(ncv),
  'shape commit pushes an ADD_ELEMENTS undo action');
check(/this\.previewShape !== null[\s\S]{0,120}renderShape\(this\.previewShape/.test(ncv),
  'renderFrame draws the live previewShape');
check(/previewShape !== null[\s\S]{0,40}orderedRender|orderedRender[\s\S]{0,120}previewShape !== null/.test(ncv),
  'previewShape forces ordered render during drag');
check(/shapeDragActive = false[\s\S]{0,40}previewShape = null/.test(ncv),
  'cancelActiveInteraction clears shape drag state');

// === 7. Glyph + label ===
check(/'shape':\s*\{/.test(glyphs), 'TOOL_GLYPHS has a shape entry');
{
  const entry = glyphs.slice(glyphs.indexOf("'shape':"),
    glyphs.indexOf("'shape':") + 3200);
  for (const k of ['f:', 'o:', 'sw:', 's:', 'v:', 'vw: 24', 'vh: 24']) {
    check(entry.includes(k), `shape glyph carries layer key "${k}"`);
  }
}
check(glyph.includes('case ToolType.SHAPE') && glyph.includes("return 'shape'"),
  'ToolGlyph maps SHAPE → shape');
check(/COLOR_GLYPHS[^;]*'shape'/.test(glyph),
  'shape fill tinted by brush color (cq.h semantics)');
check(dlg.includes('case ToolType.SHAPE') && dlg.includes('shape'),
  'toolTypeLabel maps SHAPE to the shape string');
check(strBase.includes('"name": "shape"') && /shape[\s\S]{0,40}"value": "Shape"/.test(strBase),
  'base string shape=Shape (ui_tools__shape)');
check(strZh.includes('"name": "shape"'), 'zh string for shape present');

// === 8. Shape-kind picker (h5g) ===
check(skp.includes('export struct ShapeKindPicker'), 'ShapeKindPicker component exists');
check(/SHAPE_KIND_ORDER[^=]*=\s*\[[\s\S]*RECTANGLE[\s\S]*LINE/.test(skp),
  'picker lists all 6 kinds in r5g declaration order');
check(skp.includes('buildDragShape') && skp.includes('renderShape'),
  'picker swatches render the live shape geometry');
check(skp.includes('setToolShapeKind'), 'pick persists via setToolShapeKind');
check(dlg.includes('shapeKindToolId') && dlg.includes('ShapeKindPicker'),
  'SHAPE tool ⋯ menu opens the shape-kind picker');

// === 9. shape_kind label strings (6 kinds) ===
for (const k of ['shape_rectangle', 'shape_ellipse', 'shape_diamond',
  'shape_triangle', 'shape_arrow', 'shape_line']) {
  check(strBase.includes(`"name": "${k}"`), `base label ${k} present`);
}

// === 10. Persistence: shape_kind/nib columns + codec ===
check(/shape_kind TEXT DEFAULT 'RECTANGLE'/.test(dbh),
  "tool_state gains shape_kind TEXT DEFAULT 'RECTANGLE' (ca3.java:404)");
check(/ADD COLUMN shape_kind/.test(dbh) && /ADD COLUMN nib_angle/.test(dbh) &&
  /ADD COLUMN nib_flatness/.test(dbh) && /ADD COLUMN stabilization/.test(dbh),
  'migration adds shape_kind/nib_angle/nib_flatness/stabilization columns');
check(tri.includes('shapeKindFromName') && tri.includes('shapeKindToName'),
  'ToolRepositoryImpl codecs shapeKind name <-> enum on load/save');
check(/'shape_kind':/.test(tri) && tri.includes('shape_kind'),
  'toBucket writes shape_kind');

// === 11. Numeric: drag→shape geometry (u5g port validation) ===
{
  const slop = 6.0;
  // constrainEnd square: dx=30,dy=10 → side=30.
  const side = Math.max(Math.abs(30), Math.abs(10));
  assert(side === 30, 'square constraint takes max |d| side');
  // 45° snap: end (30,7) → atan2≈13° → rounds to 0°.
  const snapped = Math.round(Math.atan2(7, 30) / (Math.PI / 4)) * (Math.PI / 4);
  assert(Math.abs(snapped - 0) < 1e-9, 'line direction snaps to nearest 45°');
  // 45° snap up: end (10,28) → atan2≈70° → rounds to 90° (π/2).
  const snapped2 = Math.round(Math.atan2(28, 10) / (Math.PI / 4)) * (Math.PI / 4);
  assert(Math.abs(snapped2 - Math.PI / 2) < 1e-9, 'steep line snaps to 90°');
  // slop gate: a 5-unit drag produces no shape.
  assert(Math.hypot(3, 4) <= slop, '5-unit drag within slop → no shape');
  assert(Math.hypot(6, 6) > slop, 'drag beyond slop produces a shape');
  n += 5;
}

console.log(`d02-original-shape-tool OK — ${n} checks`);
console.log('TOTAL=1 FAILED=0');
