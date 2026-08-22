#!/usr/bin/env node
import fs from 'node:fs';

const g3 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/g3.java', 'utf8');
const renderer = fs.readFileSync('note/src/main/ets/rendering/ImageCanvasRenderer.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const thumbnail = fs.readFileSync('note/src/main/ets/rendering/ThumbnailRenderer.ets', 'utf8');
const fixture = fs.readFileSync('note/src/test/ImageBlockRendering.test.ets', 'utf8');

const orientationBlock = [
  'if (geometry.orientationDegrees !== 0 || geometry.mirroredHorizontally) {',
  '        const centerX = geometry.orientedWidth / 2;',
].join('\n');
const renderTail = renderer.slice(renderer.indexOf('ctx.rect(crop.left'));
const clipIndex = renderTail.indexOf('ctx.clip();');
const orientationIndex = renderTail.indexOf(orientationBlock);
const flipIndex = renderTail.indexOf('ctx.translate(geometry.flipTranslateX');

const checks = [
  ['original shared decode bakes mirror before EXIF rotation into oriented pixels',
    g3.includes('matrix.postScale(-1.0f, 1.0f, width, height);') &&
    g3.includes('matrix.postRotate(i7, width, height);')],
  ['Harmony clips encoded crop pixels before applying baked display orientation',
    clipIndex >= 0 && orientationIndex > clipIndex && flipIndex > orientationIndex],
  ['Harmony applies user flip after baked display orientation',
    flipIndex < renderTail.indexOf('ctx.scale(geometry.flipScaleX') && flipIndex > orientationIndex],
  ['editor and thumbnail share the same renderer contract',
    canvas.includes('loaded.orientationDegrees, loaded.mirroredHorizontally') &&
    thumbnail.includes('asset.orientationDegrees, asset.mirroredHorizontally);')],
  ['fixture covers user flips in encoded bitmap coordinates',
    fixture.includes("applies user flips in encoded bitmap coordinates after EXIF orientation") &&
    fixture.includes('resolved.flipTranslateX).assertEqual(200)')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_IMAGE_FLIP_ORIENTATION_ORDER_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;