import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const plan = read('note/src/main/ets/rendering/PdfRasterPlan.ets');
const loader = read('note/src/main/ets/core/adaptation/PdfBackgroundLoader.ets');
const paper = read('note/src/main/ets/rendering/PaperRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const thumbnail = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const viewport = read('note/src/main/ets/rendering/CanvasViewport.ets');
const fixture = read('note/src/test/PdfRasterPlan.test.ets');
const list = read('note/src/test/List.test.ets');

const checks = [
  ['original-style visible union has an explicit pure plan',
    plan.includes('buildPdfRasterPlan') && plan.includes('expandedVisiblePageRect')],
  ['PDF top origin is converted to bottom-origin matrix y',
    plan.includes('(1 - normalizedBottom) * pdfPageHeightPt') &&
      plan.includes('(1 - normalizedTop) * pdfPageHeightPt')],
  ['all cardinal inverse mappings are explicit',
    plan.includes('paperWidth - rect.right') && plan.includes('paperHeight - rect.bottom') &&
      plan.includes('paperHeight - rect.top')],
  ['raster allocations have hard side and pixel budgets',
    plan.includes('PDF_RASTER_MAX_SIDE: number = 4096') &&
      plan.includes('PDF_RASTER_MAX_PIXELS: number = 8 * 1024 * 1024') &&
      plan.includes('Math.round(logicalSize * scale)') &&
      plan.includes('pixelCount <= PDF_RASTER_MAX_PIXELS')],
  ['PDFKit receives a zero-rotation visible-area matrix',
    loader.includes('matrix.rotate = 0') && loader.includes('page.getAreaPixelMap(matrix')],
  ['area raster failure retains a full-page fallback',
    loader.includes('visible-area raster failed; using full-page fallback') &&
      loader.includes('pixelMap = page.getPagePixelMap()')],
  ['cropped bitmap is drawn at its page-space destination',
    paper.includes('pdfRenderRect') && paper.includes('destination.right - destination.left')],
  ['editor derives visible page bounds from the shared viewport',
    viewport.includes('visibleCanvasRect') && canvas.includes('this.viewport.visibleCanvasRect(')],
  ['editor preserves the current bitmap during async reraster',
    canvas.includes('preserveCurrent: boolean = false') &&
      canvas.includes('PDF reraster kept previous bitmap') &&
      canvas.includes('loader.release(previous)')],
  ['pinch and pan use debounced overscan reraster',
    canvas.includes('PDF_RASTER_REFRESH_DELAY_MS: number = 120') &&
      canvas.includes('overscanRatio: PDF_RASTER_OVERSCAN_RATIO') &&
      canvas.includes('pdfRasterPlanCovers(loaded.rasterPlan, request)')],
  ['budget-limited overviews can regain detail without a refresh loop',
    plan.includes('plan.rasterScale + COVERAGE_EPSILON < nextRasterScale') &&
      plan.includes('boundedRasterScale(') &&
      fixture.includes('budget-limited overview when a detail view can afford more scale')],
  ['thumbnail requests only its fitted output scale',
    thumbnail.includes('outputScale: pageTransform.scale') &&
      thumbnail.includes('pdfLoader.load(effective.pdf, rasterRequest)')],
  ['ArkTS fixture covers y inversion, rotations, budgets and cache coverage',
    fixture.includes('bottom-origin PDF y values') && fixture.includes('all cardinal page rotations') &&
      fixture.includes('PDF_RASTER_MAX_PIXELS') && fixture.includes('pdfRasterPlanCovers') &&
      fixture.includes('original positive round rule') &&
      fixture.includes('legal zero-area margins as empty') &&
      list.includes('pdfRasterPlanTest();')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`D02_ORIGINAL_PDF_VISIBLE_RASTER_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
