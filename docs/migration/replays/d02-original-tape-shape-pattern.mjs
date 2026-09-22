// Phase 587 — tape pattern overlay for tape ShapeElements (originalTool === 3).
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   Tape elements are ShapeImpl entities carrying tapePatternRegister —
//   dm2 validates tapePattern only when the tool is TAPE; OriginalShapeGroup
//   ops decode the register (OriginalShapeGroupOperation field 8/9).
//   The render path (e16/d5g bake) draws the band body plus the ife pattern
//   fill over the stroke outline — the same qfe tile pipeline as tape Ink.
// Harmony gap fixed here: imported tape elements materialize as ShapeElement
// (originalTool === 3, originalTapePattern) and previously rendered only the
// plain stroked band — no pattern overlay. The partial-eraser remnant path
// (OriginalShapePartialEraser:631) already synthesizes tape strokes from
// these shapes; renderTapePatternOverlay now does the same for whole shapes.
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const RENDERER = 'note/src/main/ets/rendering/ShapeCanvasRenderer.ets';
const VIEW = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const ERASER = 'note/src/main/ets/rendering/OriginalShapePartialEraser.ets';

const renderer = readFileSync(RENDERER, 'utf8');
const view = readFileSync(VIEW, 'utf8');
const eraser = readFileSync(ERASER, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- Session reveal set shared with the painter (yd9.j parity) ---
check(renderer.includes('revealedTapeIds: Set<string> = new Set()'),
  'renderer owns a session reveal set');
check(view.includes('this.shapeRenderer.revealedTapeIds = this.revealedTapeIds'),
  'canvas shares the same set instance with the shape renderer');

// --- Overlay gate (ife=null when revealed; PLAIN draws no pattern) ---
const overlay = renderer.slice(renderer.indexOf('private renderTapePatternOverlay'),
  renderer.indexOf('private renderTapePatternOverlay') + 1800);
check(overlay.includes('this.revealedTapeIds.has(shape.id)'),
  'revealed tape shape suppresses the pattern overlay');
check(overlay.includes('shape.originalTapePattern ?? TapePattern.STRIPES'),
  'missing pattern falls back to original STRIPES default');
check(overlay.includes('TapePattern.PLAIN'),
  'PLAIN renders as a solid band (no pattern layer)');
check(overlay.includes('component.pathPoints') && overlay.includes('component.cubicSegments'),
  'per-component geometry feeds the pattern outline');
check(overlay.includes('brushWidth: shape.strokeWidth') &&
  overlay.includes('color: shape.color'),
  'synthesized stroke keeps the shape band width/color');
check(overlay.includes('tapePattern: pattern'),
  'synthesized renderSpec carries the decoded pattern');
check(overlay.includes('this.renderer.renderTapePattern'),
  'pattern rendered through the shared qfe tile pipeline');

// --- Call site: after the band body, only for tape shapes ---
const renderBody = renderer.slice(renderer.indexOf('renderShape(shape: ShapeElement'));
check(renderBody.indexOf('this.strokeShape(shape, geometry, ctx') <
  renderBody.indexOf('renderTapePatternOverlay'),
  'pattern overlays the stroked band body');
check(renderBody.includes("shape.originalTool === 3"),
  'overlay restricted to tape shapes (dm2 TAPE parity)');
check(renderer.includes('renderShape(shape: ShapeElement, context: RenderContext, viewportZoom: number = 1)'),
  'renderShape accepts viewport zoom for the tile scale bucket');

// --- Canvas plumbing: zoom plumbed at both call sites ---
check(view.includes('this.shapeRenderer.renderShape(element.data, renderContext, this.viewport.zoom)'),
  'ordered-element path passes viewport zoom');
check(view.includes('this.shapeRenderer.renderShape(heldShape, this.renderCtx, this.viewport.zoom)'),
  'held-shape preview path passes viewport zoom');

// --- Consistency with the existing shape→tape-stroke conversion ---
check(eraser.includes("tool === 3 ? shape.originalTapePattern ?? TapePattern.STRIPES : undefined"),
  'partial-eraser remnant path shares the same tape marker');

console.log(`D02_ORIGINAL_TAPE_SHAPE_PATTERN_OK TOTAL=${n} FAILED=0`);
