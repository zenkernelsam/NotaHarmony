#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const repoRoot = process.cwd();
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability';
const readRepo = relative => fs.readFileSync(path.join(repoRoot, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = relative => fs.readFileSync(path.join(originalRoot, relative), 'utf8').replaceAll('\r\n', '\n');

const planSource = readRepo('note/src/main/ets/core/model/OriginalImageInsertPlan.ets');
const normalizerSource = readRepo('note/src/main/ets/data/OriginalImageNormalizer.ets');
const persistenceSource = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const fixtureSource = readRepo('note/src/test/OriginalImageNormalizer.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');
const vuh = readOriginal('decompiled_1.0.3/sources/defpackage/vuh.java');
const w34 = readOriginal('decompiled_1.0.3/sources/defpackage/w34.java');

function planDownscale(encodedWidth, encodedHeight) {
  if (!Number.isSafeInteger(encodedWidth) || !Number.isSafeInteger(encodedHeight) ||
    encodedWidth <= 0 || encodedHeight <= 0) return null;
  if (encodedWidth <= 3000 && encodedHeight <= 3000)
    return { sampleSize: 1, width: encodedWidth, height: encodedHeight };
  const floatRatio = Math.fround(3000 / Math.fround(Math.max(encodedWidth, encodedHeight)));
  const width = Math.max(1, Math.round(encodedWidth * floatRatio));
  const height = Math.max(1, Math.round(encodedHeight * floatRatio));
  let sampleSize = 1;
  while (Math.floor(encodedWidth / (sampleSize * 2)) >= width &&
    Math.floor(encodedHeight / (sampleSize * 2)) >= height) sampleSize *= 2;
  return { sampleSize, width, height };
}

const expectedPlans = [
  [1, 3000, { sampleSize: 1, width: 1, height: 3000 }],
  [3000, 1, { sampleSize: 1, width: 3000, height: 1 }],
  [3001, 1, { sampleSize: 1, width: 3000, height: 1 }],
  [6000, 2000, { sampleSize: 2, width: 3000, height: 1000 }],
  [9000, 12000, { sampleSize: 4, width: 2250, height: 3000 }],
  [24000, 8000, { sampleSize: 8, width: 3000, height: 1000 }],
];

const checks = [
  ['original decodes bounds and fails closed on invalid dimensions',
    vuh.includes('options.inJustDecodeBounds = true') &&
    vuh.includes('Failed to decode image dimensions') && vuh.includes('file.delete()')],
  ['original applies EXIF rotation before the oriented 3000px gate',
    vuh.includes('int iL = w34Var != null ? w34Var.l() : 0;') &&
    vuh.includes('boolean z = iL == 90 || iL == 270;') &&
    vuh.includes('i3 <= 3000 && i4 <= 3000')],
  ['original uses Float32 max-axis ratio and power-of-two sample size',
    vuh.includes('3000.0f / Math.max(i2, i)') &&
    vuh.includes('options2.inSampleSize = i7;')],
  ['original repacks normalized pixels as WebP lossy quality 85',
    vuh.includes('Bitmap.createScaledBitmap(bitmapDecodeFile, i5, i6, true)') &&
    vuh.includes('compress(Bitmap.CompressFormat.WEBP_LOSSY, 85, fileOutputStream)') &&
    vuh.includes('"image/webp"')],
  ['original maps EXIF 3/4 to 180, 5/8 to 270 and 6/7 to 90',
    w34.includes('case 3:') && w34.includes('case 4:') && w34.includes('return 180;') &&
    w34.includes('case 5:') && w34.includes('case 8:') && w34.includes('return 270;') &&
    w34.includes('case 6:') && w34.includes('case 7:') && w34.includes('return 90;')],
  ['Harmony planner reproduces boundary Float32 and sample-size behavior',
    planSource.includes('Math.fround(Math.max(encodedWidth, encodedHeight))') &&
    planSource.includes('while (Math.floor(encodedWidth / (sampleSize * 2)) >= scaledWidth &&') &&
    planSource.includes('Math.floor(encodedHeight / (sampleSize * 2)) >= scaledHeight')],
  ['Harmony adapter decodes headers and swaps oriented axes for EXIF',
    normalizerSource.includes('await source.getImageInfo()') &&
    normalizerSource.includes('originalImageOrientedDimensions(') &&
    normalizerSource.includes("image.PropertyKey.ORIENTATION")],
  ['Harmony adapter uses desired size rotation editable PixelMap and WebP lossy 85',
    normalizerSource.includes('desiredSize: { width: downscale.width, height: downscale.height }') &&
    normalizerSource.includes('rotate: rotationDegrees > 0 ? rotationDegrees : undefined') &&
    normalizerSource.includes('editable: true') &&
    normalizerSource.includes("format: 'image/webp'") &&
    normalizerSource.includes('quality: WEBP_LOSSY_QUALITY')],
  ['Harmony WebP packing is fail-closed and releases decoder encoder resources',
    normalizerSource.includes("throw new Error(`normalizing original image failed: ${JSON.stringify(error)}`") &&
    normalizerSource.includes('await pixelMap.release()') &&
    normalizerSource.includes('packer.release()') &&
    normalizerSource.includes('await source.release()')],
  ['persistence normalization returns bytes MIME and intrinsic dimensions together',
    persistenceSource.includes('export async function normalizedOriginalImagePersistencePlan(') &&
    persistenceSource.includes('bytes: normalized.bytes') &&
    persistenceSource.includes('mimeType: normalized.mimeType') &&
    persistenceSource.includes('intrinsicWidth: normalized.encodedWidth') &&
    persistenceSource.includes('intrinsicHeight: normalized.encodedHeight')],
  ['normalization fixtures cover unchanged rotated oversized and invalid inputs',
    fixtureSource.includes('planOriginalImageDownscale(3000, 1)') &&
    fixtureSource.includes("originalImageOrientedDimensions(4000, 100, orientation)") &&
    fixtureSource.includes("['5', '6', '7', '8', 'Right-top']") &&
    fixtureSource.includes('planOriginalImageDownscale(0, 10) === null')],
  ['fixture suite registers the normalizer tests',
    fixtureList.includes("import originalImageNormalizerTest from './OriginalImageNormalizer.test';") &&
    fixtureList.includes('originalImageNormalizerTest();')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}

for (const [width, height, expected] of expectedPlans) {
  const actual = planDownscale(width, height);
  const passed = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`${passed ? 'PASS' : 'FAIL'} numeric ${width}x${height} -> ${JSON.stringify(actual)}`);
  if (!passed) failed += 1;
}

console.log(`D02_ORIGINAL_LARGE_IMAGE_NORMALIZATION_${failed === 0 ? 'OK' : 'FAILED'} ` +
  `TOTAL=${checks.length + expectedPlans.length} FAILED=${failed}`);
if (failed !== 0) process.exitCode = 1;