import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const loader = fs.readFileSync(
  path.join(root, 'note/src/main/ets/core/adaptation/PdfBackgroundLoader.ets'), 'utf8');
const fixture = fs.readFileSync(
  path.join(root, 'note/src/test/PdfResourceLifecycle.test.ets'), 'utf8');

const pageAcquire = loader.indexOf('page = document.getPage(pdf.pageInAsset)');
const pageRaster = loader.indexOf('pixelMap = page.getAreaPixelMap(matrix');
const pageRelease = loader.indexOf('pageToRelease.release()');
const documentRelease = loader.indexOf('document.releaseDocument()');
const checks = [
  ['PDF page is retained as an explicit native handle',
    loader.includes('let page: pdfService.PdfPage | null = null') && pageAcquire >= 0],
  ['page acquisition precedes rasterization', pageAcquire >= 0 && pageAcquire < pageRaster],
  ['page is released before its document', pageRelease >= 0 && pageRelease < documentRelease],
  ['page and document releases have independent failure capture',
    loader.includes('pageError = JSON.stringify(error)') &&
      loader.includes('documentError = JSON.stringify(error)')],
  ['finally always invokes the shared native release boundary',
    loader.includes('finally {') && loader.includes('releasePdfNativeResources(\n        releasePage')],
  ['the old chained page handle loss is absent',
    !loader.includes('document.getPage(pdf.pageInAsset).getPagePixelMap()')],
  ['ArkTS fixture locks release order and no-page behavior',
    fixture.includes("assertEqual('page,document')") &&
      fixture.includes("assertEqual('document')")],
  ['ArkTS fixture locks both cleanup failure paths',
    fixture.includes('still releases the document after a page release failure') &&
      fixture.includes('captures document release failure without throwing')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`D02_PDF_PAGE_NATIVE_LIFECYCLE_REPLAY_OK TOTAL=${checks.length} FAILED=0`);
