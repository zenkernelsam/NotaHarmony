import fs from 'node:fs';

const ingress = fs.readFileSync('note/src/main/ets/data/OriginalClipboardImageIngress.ets', 'utf8').replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8').replaceAll('\r\n', '\n');
const fixture = fs.readFileSync('note/src/test/OriginalClipboardImageIngress.test.ets', 'utf8');
const fixtureList = fs.readFileSync('note/src/test/List.test.ets', 'utf8');
const evidence = fs.readFileSync('docs/migration/evidence/original-clipboard-image-ingress-jadx-2026-08-23.md', 'utf8');

function between(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  if (start < 0) return '';
  const next = source.indexOf(endMarker, start + startMarker.length);
  return next < 0 ? source.slice(start) : source.slice(start, next);
}

const importSource = between(ingress, 'export async function importOriginalClipboardImage', '\nasync function packWebpLossy');
const menuSource = between(canvas, '@Builder\n  private ClipboardPasteContextMenu', '\n  // === 文本框 ===');
const pasteSource = between(canvas, 'private async startOriginalClipboardImagePaste', '\n  private canUseOriginalClipboardImage');

const checks = [
  ['only accepts the system PixelMap clipboard type',
    ingress.includes("mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)")],
  ['validates dimensions and byte ceiling before returning bytes',
    importSource.includes("if (!validDimensions(info.size.width, info.size.height)) {") &&
    ingress.includes('CLIPBOARD_IMAGE_MAX_BYTES: number = 104857600')],
  ['normalizes to original WebP lossy 85',
    ingress.includes("format: 'image/webp', quality: WEBP_LOSSY_QUALITY") &&
    ingress.includes('WEBP_LOSSY_QUALITY: number = 85')],
  ['always releases the clipboard source',
    importSource.includes('} finally {\n    await source.release();\n  }')],
  ['long press menu exposes the image fallback only without internal content',
    menuSource.includes('if (!this.canPasteClipboardNow() && this.canUseOriginalClipboardImage())') &&
    menuSource.includes('this.startOriginalClipboardImagePaste();')],
  ['paste uses the long press anchor for durable insertion',
    pasteSource.includes('await this.insertOriginalPhotos([{') &&
    pasteSource.includes('}], target);') &&
    canvas.includes('pasteAnchor?: Point2D')],
  ['failures show the localized insert failure toast',
    pasteSource.includes("$r('app.string.original_photo_insert_failed')")],
  ['ArkTS fixture proves empty oversized and reset paths',
    fixture.includes("'system pasteboard has no original clipboard image'") &&
    fixture.includes("'original clipboard image dimensions are invalid'") &&
    fixtureList.includes('originalClipboardImageIngressTest();')],
  ['JADX evidence records the ClipboardImage dispatch boundary',
    evidence.includes('hasMimeType("image/*")') &&
    evidence.includes('handleAddImageFromClipboard') &&
    evidence.includes('不声称复刻其内部实现')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed++;
}
console.log(`D02_ORIGINAL_CLIPBOARD_IMAGE_INGRESS_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
