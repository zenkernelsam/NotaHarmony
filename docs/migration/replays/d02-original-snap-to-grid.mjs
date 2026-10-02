// Phase 568 — original snap-to-grid / alignment guides on selection move.
// Original evidence:
//  - ac4.S = SNAP_TO_GRID remote flag; stb.c provider key androidSnapToGrid
//    defaults to true in res/xml/core_remoteconfig__remote_config_defaults.xml.
//  - q7j.a builds candidates per visible bounds: GRID paper → GRID_LINE
//    horizontal/vertical line candidates (threshold 12pt); DOTS paper →
//    GRID_INTERSECTION points (6pt); LINES/others → none (q3a empty).
//    Each non-selected element contributes 4 OBJECT_CORNER points (6pt),
//    2 OBJECT_CENTER lines (6pt, guide segment spanning the element) and
//    4 OBJECT_EDGE lines (8pt, guide on the edge).
//  - fjd.I priorities: GRID_LINE=1, OBJECT_EDGE=1, GRID_INTERSECTION=2,
//    OBJECT_CORNER=2, OBJECT_CENTER=3.
//  - m91.j: jjd point tests both axes; ijd horizontal line tests y only;
//    kjd vertical line tests x only; |delta| <= thresholdPt/zoom (m91 divides
//    the pt threshold by zoom at construction).
//  - xe8.R per-axis winner: higher fjd.I wins; equal priority keeps the
//    smallest |delta|.
//  - fi3.c/b: dragged bounds contribute 4 corner anchors + the center,
//    each translated by the proposed delta (zn9.g).
//  - m91.i: rendered guides = winning candidates' non-null b() segments.
// Harmony landing: OriginalSnapGuides.ets ports candidates + winner selection;
// NoteCanvasView applies the snapped delta inside selectionDrag move and
// renders winning segments in theme.accent at constant screen width.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const policy = readFileSync('note/src/main/ets/core/model/OriginalSnapGuides.ets', 'utf8');
const view = readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Policy: kinds/priorities (fjd.I) ---
check(policy.includes('GRID_LINE = 1'), 'grid line priority 1');
check(policy.includes('OBJECT_EDGE = 1'), 'object edge priority 1');
check(policy.includes('GRID_INTERSECTION = 2'), 'grid intersection priority 2');
check(policy.includes('OBJECT_CORNER = 2'), 'object corner priority 2');
check(policy.includes('OBJECT_CENTER = 3'), 'object center priority 3');

// --- Policy: thresholds (jjd 6 / center 6 / edge 8 / grid line 12) ---
check(policy.includes('POINT_THRESHOLD_PT: number = 6.0'), 'point threshold 6pt');
check(policy.includes('CENTER_THRESHOLD_PT: number = 6.0'), 'center threshold 6pt');
check(policy.includes('EDGE_THRESHOLD_PT: number = 8.0'), 'edge threshold 8pt');
check(policy.includes('GRID_LINE_THRESHOLD_PT: number = 12.0'), 'grid line threshold 12pt');

// --- Policy: zoom-scaled threshold (m91 a()/f) ---
check(policy.includes('candidate.thresholdPt * POINTS_TO_PAGE_UNITS / zoom'),
  'threshold scaled by 1/zoom into page units');

// --- Policy: element candidates (4 corners + 2 centers + 4 edges) ---
const elementFn = policy.slice(policy.indexOf('originalSnapCandidatesForElementBounds'),
  policy.indexOf('interface OriginalGridPositions'));
check((elementFn.match(/OBJECT_CORNER/g) || []).length === 2, 'corner candidates block');
check((elementFn.match(/OBJECT_CENTER/g) || []).length === 4, 'center line candidates');
check((elementFn.match(/OBJECT_EDGE/g) || []).length === 8, 'edge line candidates');
check((elementFn.match(/axis: 'x'/g) || []).length === 3, 'x-axis line candidates (v-center + 2 v-edges)');
check((elementFn.match(/axis: 'y'/g) || []).length === 3, 'y-axis line candidates (h-center + 2 h-edges)');
check((elementFn.match(/axis: 'xy'/g) || []).length === 1, 'corner points test both axes');

// --- Policy: grid candidates only for GRID/DOTS (q3a empty otherwise) ---
check(policy.includes('template !== PaperTemplate.GRID && template !== PaperTemplate.DOTS'),
  'grid branch gated to GRID/DOTS');
check(policy.includes('GRID_INTERSECTION'), 'dots intersections');
check(policy.indexOf('y >= visible.top && y <= visible.bottom') >= 0,
  'horizontal grid lines filtered to visible y');
check(policy.indexOf('x >= visible.left && x <= visible.right') >= 0,
  'vertical grid lines filtered to visible x');

// --- Policy: move anchors = 4 corners + center (fi3.c + fi3.b) ---
const anchorsFn = policy.slice(policy.indexOf('originalSnapMoveAnchors'),
  policy.indexOf('interface AxisSnap'));
check((anchorsFn.match(/\{ x: bounds\./g) || []).length === 4, 'four corner anchors');
check(anchorsFn.includes('(bounds.left + bounds.right) / 2'), 'center anchor x');
check(anchorsFn.includes('(bounds.top + bounds.bottom) / 2'), 'center anchor y');

// --- Policy: winner selection = priority desc, then |delta| asc (xe8.R) ---
check(policy.includes('priority > best.priority'), 'higher priority wins');
check(policy.includes('priority === best.priority && Math.abs(delta) < Math.abs(best.delta)'),
  'equal priority prefers smaller |delta|');
check(policy.includes('anchor.x + dx') && policy.includes('anchor.y + dy'),
  'anchors translated by proposed delta');
// --- m91.i: guides = winning candidates' non-null segments only ---
check(policy.includes('bestX.has && bestX.guide !== null'), 'x guide from winner segment');
check(policy.includes('bestY.has && bestY.guide !== null'), 'y guide from winner segment');

// --- View wiring ---
check(view.includes("from '../../core/model/OriginalSnapGuides'"), 'view imports policy');
check(view.includes('private snapGuides: OriginalSnapGuideSegment[] = []'),
  'guide state field');
check((view.match(/planSelectionSnap\(dx, dy\)/g) || []).length === 2,
  'snap planned in move + touch-up call sites');
check((view.match(/moveSelected\(dx \+ snap\.dx, dy \+ snap\.dy\)/g) || []).length === 2,
  'snapped delta applied in move and final move');
check(view.includes('planOriginalSnapMove('), 'winner selection invoked');
check(view.includes('originalSnapMoveAnchors(bounds)'), 'anchors from selection bounds');
check(view.includes('originalSnapGridCandidates('), 'grid candidates collected');
check(view.includes('originalSnapCandidatesForElementBounds('), 'element candidates collected');
check(view.includes('collectSnapCandidates(this.visibleCanvasRect())'),
  'candidates filtered to visible canvas rect');
check(view.includes('this.snapGuides = [];'), 'guides cleared');
check(view.includes('this.canvasCtx.strokeStyle = theme.accent'), 'guides drawn in accent');
check(view.includes('this.canvasCtx.lineWidth = 1.5 / this.viewport.zoom'),
  'guide width constant on screen');
check(view.indexOf('this.snapGuides.length > 0') > view.indexOf('private renderFrame'),
  'guide pass inside renderFrame');
// selected elements excluded from candidates
check(view.includes('selectedStrokeIds.has(s.id)') && view.includes('selectedShapeIds.has(shape.id)') &&
  view.includes('selectedTextBlockIds.has(textBlock.id)') &&
  view.includes('selectedImageIds.has(image.id)') && view.includes('selectedMathIds.has(math.id)'),
  'all five element kinds excluded when selected');

// --- Phase 1456 — guf.b 吸附旋转门：twm.e(fJ) 非零旋转禁用吸附 ---
const gateIdx = view.indexOf('private selectionSnapRotation(');
check(gateIdx > 0, 'selectionSnapRotation resolver present');
const gate = view.slice(gateIdx, gateIdx + 2400);
check(gate.includes('Math.atan2(t[3], t[0])'),
  'ksf branch: selection-transform rotation (ksf.g() equivalent)');
check(gate.includes('this.shapeVertexRotation(shape)') &&
  gate.includes('stroke.transform[3]') &&
  gate.includes('tb.rotationRadians') &&
  gate.includes('img.rotationRadians') &&
  gate.includes('mb.rotationRadians'),
  'lsf branch: member intrinsic rotation (hv6.j() equivalent)');
const plan = view.slice(view.indexOf('private planSelectionSnap('),
  view.indexOf('private planSelectionSnap(') + 800);
check(plan.includes('Math.abs(this.selectionSnapRotation()) > 0.0001'),
  'snap skipped entirely when rotated (guf.b !twm.e(fJ) gate)');
check(plan.indexOf('selectionSnapRotation') < plan.indexOf('planOriginalSnapMove'),
  'rotation gate runs before candidate planning');

// --- Phase 1465 — guf.b lsf 支：单形状拖拽锚点 = og0.e 轮廓点 + og0.h/i 中心 ---
const anc = view.slice(view.indexOf('private singleShapeSnapAnchors('),
  view.indexOf('private singleShapeSnapAnchors(') + 3000);
check(anc.includes('total !== 1 || state.selectedShapeIds.length !== 1'),
  'shape anchors gated to lsf single-shape selection');
check(anc.includes('transformMemberPoint(shape.start, shape.transform)') &&
  anc.includes('transformMemberPoint(shape.end, shape.transform)') &&
  !anc.includes('controlPoint'),
  'j4g LINE: anchors = first/last endpoints only (og0.e p3/y3)');
check(anc.includes('first.x === last.x') && anc.includes('verts.slice(0, verts.length - 1)'),
  'l4g POLYGON: closed duplicate tail vertex dropped (zx7.r + m3(1))');
check(anc.includes('sx / (3 * twice)') && anc.includes('sy / (3 * twice)') &&
  anc.includes('p.x * q.y - p.y * q.x'),
  'l4g center = shoelace centroid over world anchors (og0.h)');
check(anc.indexOf('!centroid') > anc.indexOf('twice !== 0') ||
  anc.includes('if (twice !== 0)'),
  'degenerate polygon falls back to mean (og0.i)');
check(anc.includes('this.shapeVertexDots(shape)'),
  'k4g branch: cardinal mid-edge points (oag.y2 four mids)');
check(anc.includes('anchors.push({ x: cx, y: cy })'),
  'center appended to anchor set (ne1.w pa9VarE2.add)');
check(plan.includes('this.singleShapeSnapAnchors() ??') &&
  plan.includes('originalSnapMoveAnchors(bounds)'),
  'shape branch replaces bounds anchors; others keep u64.c(sbe) corners');
// 可执行模型：三角形 (0,0)-(6,0)-(0,6) 质心=(2,2)；退化共线回退均值。
{
  const tri = [{ x: 0, y: 0 }, { x: 6, y: 0 }, { x: 0, y: 6 }];
  let twice = 0, sx = 0, sy = 0;
  for (let i = 0; i < tri.length; i++) {
    const p = tri[i], q = tri[(i + 1) % tri.length];
    const cr = p.x * q.y - p.y * q.x;
    twice += cr; sx += (q.x + p.x) * cr; sy += (q.y + p.y) * cr;
  }
  const cx = sx / (3 * twice), cy = sy / (3 * twice);
  assert(Math.abs(cx - 2) < 1e-9 && Math.abs(cy - 2) < 1e-9,
    'shoelace centroid of triangle = (2,2)');
  // 退化三角形 (0,0)-(1,1)-(2,2)：twice=0 → og0.i 均值=(1,1)。
  const line = [{ x: 0, y: 0 }, { x: 1, y: 1 }, { x: 2, y: 2 }];
  let t2 = 0;
  for (let i = 0; i < line.length; i++) {
    const p = line[i], q = line[(i + 1) % line.length];
    t2 += p.x * q.y - p.y * q.x;
  }
  assert(t2 === 0, 'collinear polygon → shoelace d==0 → mean fallback');
  n += 2;
}

console.log(`D02_ORIGINAL_SNAP_TO_GRID_REPLAY_OK TOTAL=${n} FAILED=0`);
