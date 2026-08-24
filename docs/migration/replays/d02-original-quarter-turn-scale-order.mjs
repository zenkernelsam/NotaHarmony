#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const repoRoot = process.cwd();
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability';
const readRepo = relative => fs.readFileSync(path.join(repoRoot, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = relative => fs.readFileSync(path.join(originalRoot, relative), 'utf8').replaceAll('\r\n', '\n');

const normalizerSource = readRepo('note/src/main/ets/data/OriginalImageNormalizer.ets');
const plannerSource = readRepo('note/src/main/ets/core/model/OriginalImageInsertPlan.ets');
const fixtureSource = readRepo('note/src/test/OriginalImageNormalizer.test.ets');
const vuh = readOriginal('decompiled_1.0.3/sources/defpackage/vuh.java');

function planDownscale(width, height) {
  if (!Number.isSafeInteger(width) || !Number.isSafeInteger(height) ||
    width <= 0 || height <= 0) return null;
  if (width <= 3000 && height <= 3000)
    return { sampleSize: 1, width, height };
  const ratio = Math.fround(3000 / Math.fround(Math.max(width, height)));
  const scaledWidth = Math.max(1, Math.round(width * ratio));
  const scaledHeight = Math.max(1, Math.round(height * ratio));
  let sampleSize = 1;
  while (Math.floor(width / (sampleSize * 2)) >= scaledWidth &&
    Math.floor(height / (sampleSize * 2)) >= scaledHeight) sampleSize *= 2;
  return {
    sampleSize,
    width: scaledWidth,
    height: scaledHeight,
  };
}

const checks = [
  ['original scales encoded axes before EXIF rotation',
    vuh.includes('int i3 = z ? i : i2;') && vuh.includes('3000.0f / Math.max(i2, i)')],
  ['Harmony keeps the oriented gate and encoded-axis downscale plan',
    normalizerSource.includes('planOriginalImageDownscale(oriented.width, oriented.height)') &&
    plannerSource.includes('Math.fround(Math.max(encodedWidth, encodedHeight))')],
  ['Harmony no longer combines ambiguous decode rotate and desired size',
    !normalizerSource.includes('rotate: rotationDegrees > 0 ? rotationDegrees : undefined') &&
    !normalizerSource.includes('desiredSize:')],
  ['Harmony applies deterministic post-decode rotation then scale',
    normalizerSource.includes('await pixelMap.rotate(rotationDegrees);') &&
    normalizerSource.indexOf('await pixelMap.rotate(rotationDegrees);') <
      normalizerSource.indexOf('await pixelMap.scale(scaleX, scaleY);')],
  ['Harmony validates rotated and scaled output axes',
    normalizerSource.includes("decoded.size.width !== downscale.width || decoded.size.height !== downscale.height") &&
    normalizerSource.includes('original image normalization scale is invalid')],
  ['fixture covers quarter-turn axis swap and renderer degrees',
    fixtureSource.includes("originalRotationDegrees('6')") &&
    fixtureSource.includes("originalRotationDegrees('8')") &&
    fixtureSource.includes('sampleSize: 2, width: 3000, height: 500')],
];

const plans = [
  [6000, 1000, { sampleSize: 2, width: 3000, height: 500 }],
  [1000, 6000, { sampleSize: 2, width: 500, height: 3000 }],
  [9000, 12000, { sampleSize: 4, width: 2250, height: 3000 }],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
for (const [width, height, expected] of plans) {
  const actual = planDownscale(width, height);
  const passed = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`${passed ? 'PASS' : 'FAIL'} numeric ${width}x${height} -> ${JSON.stringify(actual)}`);
  if (!passed) failed += 1;
}

console.log(`D02_ORIGINAL_QUARTER_TURN_SCALE_ORDER_${failed === 0 ? 'OK' : 'FAILED'} ` +
  `TOTAL=${checks.length + plans.length} FAILED=${failed}`);
if (failed !== 0) process.exitCode = 1;
