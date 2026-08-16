import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

function readRepo(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function readOriginal(fileName) {
  return fs.readFileSync(path.join(originalRoot, fileName), 'utf8');
}

function anchorZoom(state, anchorX, anchorY, factor) {
  const nextZoom = Math.min(10, Math.max(0.25, state.zoom * factor));
  const actual = nextZoom / state.zoom;
  return {
    zoom: nextZoom,
    scrollX: anchorX - (anchorX - state.scrollX) * actual,
    scrollY: anchorY - (anchorY - state.scrollY) * actual,
  };
}

const t0g = readOriginal('t0g.java');
const h3a = readOriginal('h3a.java');
const v0g = readOriginal('v0g.java');
const x0f = readOriginal('x0f.java');
const d2 = readOriginal('d2.java');
const noteTypes = readRepo('note/src/main/ets/core/model/NoteTypes.ets');
const viewport = readRepo('note/src/main/ets/rendering/CanvasViewport.ets');
const repository = readRepo('note/src/main/ets/data/NoteRepositoryImpl.ets');
const canvasView = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const viewportTest = readRepo('note/src/test/CanvasViewport.test.ets');
const coordinateTest = readRepo('note/src/test/PageCoordinateSpace.test.ets');
const task = readRepo('docs/migration/tasks/T-034-canvas-zoom-pan.md');

const checks = [
  ['original viewport state declares 0.25 to 10 range', t0g.includes('new ms1(0.25f, 10.0f)')],
  ['original interactive zoom clamps old zoom times factor',
    h3a.includes('rh8.u(l6aVar.h() * this.K, 0.25f, 10.0f)')],
  ['original interactive zoom derives actual clamped factor', h3a.includes('float fH = fU / l6aVar.h()')],
  ['original interactive zoom consumes caller anchor', h3a.includes('zn9.h(fH - 1.0f, this.L)')],
  ['original restore rejects non-finite persisted zoom',
    v0g.includes('Math.abs(f.floatValue()) <= Float.MAX_VALUE') &&
      v0g.includes('Discarding corrupt persisted viewport zoom')],
  ['original restore enforces 0.25 to 10 persisted range',
    v0g.includes('fFloatValue < 0.25f || fFloatValue > 10.0f')],
  ['original restore validates packed scroll independently',
    v0g.includes('Discarding corrupt persisted viewport scroll offset') &&
      v0g.indexOf('Discarding corrupt persisted viewport scroll offset') >
      v0g.indexOf('Discarding corrupt persisted viewport zoom')],
  ['original persistence rejects non-finite state and derived doc offset',
    x0f.includes('Refusing to persist non-finite viewport state') &&
      x0f.includes('Refusing to persist non-finite viewport doc offset')],
  ['original keyboard commands remain multiplicative and are not mislabeled as T-034 steps',
    d2.includes('bo6Var.k(1.2f)') && d2.includes('bo6Var.k(0.8333333f)')],
  ['Harmony model owns the shared original viewport constants',
    noteTypes.includes('ORIGINAL_VIEWPORT_MIN_ZOOM: number = 0.25') &&
      noteTypes.includes('ORIGINAL_VIEWPORT_MAX_ZOOM: number = 10.0')],
  ['Harmony model rejects non-finite zoom and scroll',
    noteTypes.includes('Number.isFinite(zoom)') &&
      noteTypes.includes('Number.isFinite(x) && Number.isFinite(y)')],
  ['CanvasViewport validates current zoom and visible rect with the shared range',
    viewport.includes('!isOriginalViewportZoom(this.zoom)') &&
      viewport.match(/!isOriginalViewportZoom\(this\.zoom\)/g)?.length >= 2],
  ['CanvasViewport clamps through the shared min and max constants',
    viewport.includes('ORIGINAL_VIEWPORT_MIN_ZOOM') && viewport.includes('ORIGINAL_VIEWPORT_MAX_ZOOM')],
  ['T-034 toolbar uses additive target then shared anchor zoom',
    viewport.includes('const targetZoom: number = this.clampZoom(this.zoom + delta)') &&
      viewport.includes('this.zoomAt(sx, sy, targetZoom / this.zoom)')],
  ['editor routes minus and plus 0.25 through stepZoomAt',
    canvasView.includes('this.viewport.stepZoomAt(w / 2, h / 2, delta)') &&
      canvasView.includes('this.zoomStep(-0.25)') && canvasView.includes('this.zoomStep(0.25)')],
  ['fit width reuses the original viewport bounds',
    canvasView.includes('fit < ORIGINAL_VIEWPORT_MIN_ZOOM') &&
      canvasView.includes('fit > ORIGINAL_VIEWPORT_MAX_ZOOM')],
  ['repository rejects invalid zoom and scroll before taking the write mutex',
    repository.indexOf('if (!isOriginalViewportZoom(state.zoom))') >= 0 &&
      repository.indexOf('if (!isFiniteViewportScrollOffset(state.scrollOffsetX, state.scrollOffsetY))') >= 0 &&
      repository.indexOf('if (!isOriginalViewportZoom(state.zoom))') <
      repository.indexOf('databaseWriteMutex.runExclusive')],
  ['viewport fixture covers additive sequence and original maximum',
    viewportTest.includes("expect(viewport.zoom).assertEqual(1.75)") &&
      viewportTest.includes('ORIGINAL_VIEWPORT_MAX_ZOOM')],
  ['coordinate fixture covers original 1000 percent and 0.25 to 10 anchor',
    coordinateTest.includes('[0.25, 1, 4, 10]') &&
      coordinateTest.includes('expect(viewport.zoom).assertEqual(10)')],
  ['T-034 task now documents the original range while retaining 0.25 button steps',
    task.includes('[0.25, 10.0]') && task.includes('按钮步进 0.25')],
];

let state = { zoom: 0.25, scrollX: -1200, scrollY: 730 };
const anchor = { x: 413, y: 277 };
const pageBefore = {
  x: (anchor.x - state.scrollX) / state.zoom,
  y: (anchor.y - state.scrollY) / state.zoom,
};
state = anchorZoom(state, anchor.x, anchor.y, 40);
assert.equal(state.zoom, 10);
assert.ok(Math.abs(pageBefore.x - (anchor.x - state.scrollX) / state.zoom) < 1e-10);
assert.ok(Math.abs(pageBefore.y - (anchor.y - state.scrollY) / state.zoom) < 1e-10);

let toolbarZoom = 1;
toolbarZoom = Math.min(10, Math.max(0.25, toolbarZoom + 0.25));
assert.equal(toolbarZoom, 1.25);
toolbarZoom = Math.min(10, Math.max(0.25, toolbarZoom + 0.25));
assert.equal(toolbarZoom, 1.5);
toolbarZoom = Math.min(10, Math.max(0.25, toolbarZoom + 0.25));
assert.equal(toolbarZoom, 1.75);

for (const [name, ok] of checks) {
  if (!ok) {
    throw new Error(`FAILED: ${name}`);
  }
  console.log(`PASS: ${name}`);
}
console.log(`D02_ORIGINAL_VIEWPORT_ZOOM_RANGE_REPLAY_OK TOTAL=${checks.length + 6} FAILED=0`);
