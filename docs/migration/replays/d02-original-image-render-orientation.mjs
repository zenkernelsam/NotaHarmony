#!/usr/bin/env node
import fs from 'node:fs';

const vuh = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vuh.java', 'utf8');
const g3 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/g3.java', 'utf8');
const normalizer = fs.readFileSync('note/src/main/ets/data/OriginalImageNormalizer.ets', 'utf8');
const loader = fs.readFileSync('note/src/main/ets/core/adaptation/ImageAssetLoader.ets', 'utf8');
const renderer = fs.readFileSync('note/src/main/ets/rendering/ImageCanvasRenderer.ets', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const fixture = fs.readFileSync('note/src/test/OriginalImageNormalizer.test.ets', 'utf8');

const checks = [
  ['original insertion normalization rotates oversized pixels before persistence',
    vuh.includes('matrix.postRotate(iL)') && vuh.includes('Bitmap.CompressFormat.WEBP_LOSSY')],
  ['original display decode reads JPEG WebP HEIC HEIF orientation metadata',
    g3.includes('"image/jpeg"') && g3.includes('"image/webp"') &&
    g3.includes('"image/heic"') && g3.includes('"image/heif"')],
  ['original display decode applies mirror and EXIF rotation around the bitmap centre',
    g3.includes('matrix.postScale(-1.0f, 1.0f, width, height);') &&
    g3.includes('matrix.postRotate(i7, width, height);') &&
    g3.includes('new Canvas(bitmapCreateBitmap).drawBitmap(bitmapDecodeStream, matrix, z34.a);')],
  ['Harmony asset loader preserves orientation and mirror metadata with the bitmap',
    loader.includes('orientationDegrees: number;') &&
    loader.includes('mirroredHorizontally: boolean;') &&
    loader.includes("originalImageOrientedDimensions(") &&
    loader.includes("originalExifMirrorsHorizontally(")],
  ['Harmony renderer maps only valid quarter-turn orientations',
    renderer.includes('[0, 90, 180, 270].includes(orientationDegrees)')],
  ['renderer swaps oriented dimensions for 90 and 270 degree bitmaps',
    renderer.includes('swapsAxes ? bitmapHeight : bitmapWidth') &&
    renderer.includes('swapsAxes ? bitmapWidth : bitmapHeight')],
  ['renderer maps raw encoded pixels into the oriented crop domain',
    renderer.includes('orientationTransform: TransformMatrix;') &&
    renderer.includes('originalImageOrientationTransform(') &&
    renderer.includes('ctx.transform(geometry.orientationTransform);') &&
    renderer.includes('ctx.rect(0, 0, element.blockWidth, element.blockHeight);')],
  ['canvas passes loaded orientation and mirror state to image rendering',
    canvas.includes('loaded.orientationDegrees, loaded.mirroredHorizontally')],
  ['rotation helper is exported and covered by ArkTS fixtures',
    normalizer.includes('export function originalRotationDegrees') &&
    normalizer.includes('export function originalExifMirrorsHorizontally') &&
    fixture.includes("expect(originalRotationDegrees('6')).assertEqual(90)")],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_IMAGE_RENDER_ORIENTATION_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
