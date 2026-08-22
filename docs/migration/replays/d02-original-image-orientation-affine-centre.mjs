#!/usr/bin/env node
import fs from 'node:fs';

const g3 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/g3.java', 'utf8');
const renderer = fs.readFileSync('note/src/main/ets/rendering/ImageCanvasRenderer.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const thumbnail = fs.readFileSync('note/src/main/ets/rendering/ThumbnailRenderer.ets', 'utf8');

function tail(source, anchor) {
  const index = source.indexOf(anchor);
  return index < 0 ? '' : source.slice(index);
}

const renderTail = tail(renderer, 'ctx.rect(crop.left');
const encodedCenter = [
  'const centerX = bitmap.width / 2;',
  '        const centerY = bitmap.height / 2;',
].join('\n');
const flipIndex = renderTail.indexOf('ctx.translate(geometry.flipTranslateX');

const checks = [
  ['original bakes EXIF mirror then rotation around encoded bitmap centre',
    g3.includes('float width = bitmapDecodeStream.getWidth() / 2.0f;') &&
    g3.includes('float height = bitmapDecodeStream.getHeight() / 2.0f;') &&
    g3.includes('matrix.postScale(-1.0f, 1.0f, width, height);') &&
    g3.includes('matrix.postRotate(i7, width, height);')],
  ['Harmony uses encoded dimensions as the orientation transform centre',
    renderTail.includes(encodedCenter) &&
    !renderTail.includes('const centerX = geometry.orientedWidth / 2;')],
  ['orientation remains applied after encoded crop clipping and before user flip',
    renderTail.indexOf(encodedCenter) > renderTail.indexOf('ctx.clip();') &&
    renderTail.indexOf(encodedCenter) < flipIndex],
  ['editor and thumbnail continue sharing the corrected renderer contract',
    canvas.includes('loaded.orientationDegrees, loaded.mirroredHorizontally') &&
    thumbnail.includes('asset.orientationDegrees, asset.mirroredHorizontally);')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_IMAGE_ORIENTATION_AFFINE_CENTRE_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;