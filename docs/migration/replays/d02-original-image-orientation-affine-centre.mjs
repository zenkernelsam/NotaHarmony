#!/usr/bin/env node
import fs from 'node:fs';

const g3 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/g3.java', 'utf8');
const renderer = fs.readFileSync('note/src/main/ets/rendering/ImageCanvasRenderer.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const thumbnail = fs.readFileSync('note/src/main/ets/rendering/ThumbnailRenderer.ets', 'utf8');

const renderTail = renderer.slice(renderer.indexOf('export function originalImageOrientationTransform'));
const renderBody = renderer.slice(renderer.indexOf('ctx.transform(element.transform);'));

const checks = [
  ['original bakes EXIF mirror then rotation around encoded bitmap centre',
    g3.includes('float width = bitmapDecodeStream.getWidth() / 2.0f;') &&
    g3.includes('float height = bitmapDecodeStream.getHeight() / 2.0f;') &&
    g3.includes('matrix.postScale(-1.0f, 1.0f, width, height);') &&
    g3.includes('matrix.postRotate(i7, width, height);')],
  ['Harmony orientation matrix uses encoded bitmap dimensions and positive bounds',
    renderTail.includes('bitmapWidth') && renderTail.includes('bitmapHeight') &&
    renderTail.includes('rotation = [0, -1, bitmapHeight') &&
    renderTail.includes('rotation = [0, 1, 0, -1, 0, bitmapWidth') &&
    renderTail.includes('multiplyTransform(rotation, mirror)')],
  ['renderer clips the block, translates the oriented crop, then composes flip and EXIF source mapping',
    renderBody.indexOf('ctx.rect(0, 0, element.blockWidth, element.blockHeight);') >= 0 &&
    renderBody.indexOf('ctx.translate(-crop.left, -crop.top);') >
      renderBody.indexOf('ctx.clip();') &&
    renderBody.indexOf('ctx.translate(geometry.flipTranslateX') >
      renderBody.indexOf('ctx.translate(-crop.left, -crop.top);') &&
    renderBody.indexOf('ctx.transform(geometry.orientationTransform);') >
      renderBody.indexOf('ctx.scale(geometry.flipScaleX')],
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
