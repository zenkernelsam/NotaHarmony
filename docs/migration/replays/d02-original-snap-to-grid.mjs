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

console.log(`D02_ORIGINAL_SNAP_TO_GRID_REPLAY_OK TOTAL=${n} FAILED=0`);
