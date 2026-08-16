import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets'), 'utf8');
const painter = fs.readFileSync(
  path.join(root, 'note/src/main/ets/rendering/StrokeCanvasPainter.ets'), 'utf8');
const layers = fs.readFileSync(
  path.join(root, 'note/src/main/ets/rendering/StrokeLayerManager.ets'), 'utf8');
const canvasView = fs.readFileSync(
  path.join(root, 'note/src/main/ets/ui/editor/NoteCanvasView.ets'), 'utf8');
const thumbnail = fs.readFileSync(
  path.join(root, 'note/src/main/ets/rendering/ThumbnailRenderer.ets'), 'utf8');
const fixture = fs.readFileSync(
  path.join(root, 'note/src/test/RendererStyle.test.ets'), 'utf8');
const evidence = fs.readFileSync(path.join(root,
  'docs/migration/evidence/original-tape-viewport-zoom-bucket-jadx-2026-08-16.md'), 'utf8');

function scaleBucket(viewportZoom) {
  const zoom = Math.fround(viewportZoom);
  if (!Number.isFinite(zoom) || zoom <= 0) return 2;
  const clamped = Math.fround(Math.max(1, Math.min(8, zoom)));
  return Math.round(Math.fround(clamped * 2));
}

function pixelSize(logicalSize, bucket) {
  const logical = Math.fround(logicalSize);
  if (!Number.isFinite(logical) || logical <= 0) return 1;
  const normalized = Number.isInteger(bucket) ? Math.max(2, Math.min(16, bucket)) : 2;
  return Math.max(1, Math.round(Math.fround(logical * Math.fround(normalized / 2))));
}

const checks = [
  ['original evidence locks qfe zoom clamp, half-step round, and mfe key',
    evidence.includes('round(clamp(viewportZoom, 1, 8) × 2)') &&
      evidence.includes('PatternCellKey') && evidence.includes('c5g.java:275-281')],
  ['Tape renderer does not misuse brush width as zoom',
    !source.includes('0xFFFFFFFF, stroke.renderSpec.brushWidth')],
  ['renderer narrows viewport zoom to Float32 before clamping',
    /Math\.fround\(viewportZoom\)/.test(source) &&
      /Math\.fround\(Math\.max\(1, Math\.min\(8, zoom\)\)\)/.test(source)],
  ['renderer applies the original integer half-step bucket',
    /Math\.round\(Math\.fround\(clamped \* 2\)\)/.test(source)],
  ['invalid platform zoom fails safely to the original minimum bucket',
    /!Number\.isFinite\(zoom\) \|\| zoom <= 0[\s\S]*?return 2/.test(source)],
  ['cache identity includes pattern, both effective colors, and scale bucket',
    source.includes('`${pattern}:${overlayColor}:${colorKey}:${scaleBucket}`')],
  ['FLOWERS remains the only tape-color variant',
    source.includes('pattern === TapePattern.FLOWERS ? tapeColor : 0')],
  ['bitmap pixel dimensions derive from the same bucket',
    /originalTapePatternPixelSize\(size\.width, scaleBucket\)/.test(source) &&
      /originalTapePatternPixelSize\(size\.height, scaleBucket\)/.test(source)],
  ['fixed 8x tile density has been removed', !source.includes('TAPE_TILE_DENSITY')],
  ['painter carries viewport zoom to the renderer',
    /renderTapePattern\(stroke, rc, viewportZoom\)/.test(painter)],
  ['completed, current, and rebuild layer paths carry zoom',
    /renderStroke\(stroke, this\.completedRenderCtx,[\s\S]*?zoom\)/.test(layers) &&
      /renderStroke\(currentStroke, currentRenderCtx,[\s\S]*?zoom\)/.test(layers) &&
      /rebuildFromStrokes\([\s\S]*?zoom: number = 1/.test(layers)],
  ['main canvas direct, full-composite, and rebuild paths use viewport.zoom',
    /renderStroke\(current,[\s\S]*?this\.viewport\.zoom\)/.test(canvasView) &&
      /compositeFull\(this\.canvasCtx, current, this\.renderCtx, this\.viewport\.zoom\)/.test(canvasView) &&
      /rebuildFromStrokes\([\s\S]*?this\.viewport\.zoom\)/.test(canvasView)],
  ['ordered and audio-linked strokes use the same viewport zoom',
    /renderAudioLinkedStroke\([\s\S]*?this\.viewport\.zoom\)/.test(canvasView)],
  ['thumbnail uses page-to-output scale instead of current display density',
    /renderStroke\(element\.data,[\s\S]*?pageTransform\.scale\)/.test(thumbnail)],
  ['ArkTS fixture covers thresholds, clamps, invalid input, and pixel sizes',
    fixture.includes("it('quantizes Tape pattern cells by the original viewport zoom bucket'") &&
      fixture.includes('originalTapePatternPixelSize(11.313708, 16)')],
  ['runtime bucket model covers lower clamp and first half-step threshold',
    scaleBucket(0.25) === 2 && scaleBucket(1.249) === 2 && scaleBucket(1.25) === 3],
  ['runtime bucket model covers upper thresholds and clamp',
    scaleBucket(1.749) === 3 && scaleBucket(1.75) === 4 &&
      scaleBucket(8) === 16 && scaleBucket(20) === 16],
  ['runtime pixel model preserves Float32 qfe dimensions',
    pixelSize(8, 2) === 8 && pixelSize(8, 3) === 12 && pixelSize(11.313708, 16) === 91],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`D02_ORIGINAL_TAPE_SCALE_BUCKET_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
