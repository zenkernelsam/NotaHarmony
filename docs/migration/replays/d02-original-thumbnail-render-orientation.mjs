#!/usr/bin/env node
import fs from 'node:fs';

const g3 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/g3.java', 'utf8');
const nx0 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/nx0.java', 'utf8');
const loader = fs.readFileSync('note/src/main/ets/core/adaptation/ImageAssetLoader.ets', 'utf8');
const renderer = fs.readFileSync('note/src/main/ets/rendering/ImageCanvasRenderer.ets', 'utf8');
const thumbnail = fs.readFileSync('note/src/main/ets/rendering/ThumbnailRenderer.ets', 'utf8');
const fixture = fs.readFileSync('note/src/test/ImageBlockRendering.test.ets', 'utf8');

const checks = [
  ['original shared display decode reads orientation for JPEG WebP HEIC and HEIF',
    g3.includes('"image/jpeg"') && g3.includes('"image/webp"') &&
    g3.includes('"image/heic"') && g3.includes('"image/heif"')],
  ['original loader factory invokes the shared decode callback',
    nx0.includes('new g3(this, 6)')],
  ['Harmony loader preserves quarter-turn rotation and horizontal mirror',
    loader.includes('orientationDegrees: number;') &&
    loader.includes('mirroredHorizontally: boolean;')],
  ['Harmony image renderer accepts only the original four EXIF rotations',
    renderer.includes('[0, 90, 180, 270].includes(orientationDegrees)')],
  ['Harmony thumbnail passes loaded orientation and mirror metadata to the same renderer',
    thumbnail.includes('this.imageRenderer.renderImage(element.data, asset.bitmap, renderContext,') &&
    thumbnail.includes('asset.orientationDegrees, asset.mirroredHorizontally);')],
  ['fixture covers oriented dimensions and rejects non-quarter-turn input',
    fixture.includes('resolved.orientationDegrees).assertEqual(90)') &&
    fixture.includes('resolved.mirroredHorizontally).assertTrue()') &&
    fixture.includes('imageRenderGeometry(block, 200, 100, 45, true) === null')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_THUMBNAIL_RENDER_ORIENTATION_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;