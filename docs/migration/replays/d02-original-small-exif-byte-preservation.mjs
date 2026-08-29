#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const readText = path => fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
const original = readText(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vuh.java');
const normalizer = readText('note/src/main/ets/data/OriginalImageNormalizer.ets');
const fixture = readText('note/src/test/OriginalImageNormalizer.test.ets');

const originalGate = original.indexOf('if (i3 <= 3000 && i4 <= 3000) {');
const originalUnchangedReturn = original.indexOf('return ep5Var;', originalGate);
const originalDecode = original.indexOf('bitmapDecodeFile = BitmapFactory.decodeFile', originalGate);
assert.ok(originalGate >= 0);
assert.ok(originalUnchangedReturn > originalGate);
assert.ok(originalDecode > originalUnchangedReturn);

assert.match(normalizer,
  /const needsNormalization: boolean = !isOriginalNormalizedImageDimensions\(\s*oriented\.width, oriented\.height\);/);
assert.doesNotMatch(normalizer, /needsNormalization[\s\S]{0,120}rotationDegrees !== 0/);
const harmonyGate = normalizer.indexOf('if (!needsNormalization) {');
const harmonyStableReturn = normalizer.indexOf('bytes: stable,', harmonyGate);
const harmonyDecode = normalizer.indexOf('pixelMap = await source.createPixelMap({', harmonyGate);
assert.ok(harmonyGate >= 0);
assert.ok(harmonyStableReturn > harmonyGate);
assert.ok(harmonyDecode > harmonyStableReturn);
assert.match(normalizer, /rewroteBytes: false,/);
assert.match(normalizer, /mimeType: sourceMime\(info\.mimeType\),/);

assert.ok(fixture.includes('keeps threshold-sized nonzero EXIF rotations'));
assert.ok(fixture.includes("expect(originalRotationDegrees('6')).assertEqual(90)"));
assert.ok(fixture.includes('isOriginalNormalizedImageDimensions('));

function needsRewrite(encodedWidth, encodedHeight, orientation) {
  const swapsAxes = ['5', '6', '7', '8'].includes(orientation);
  const width = swapsAxes ? encodedHeight : encodedWidth;
  const height = swapsAxes ? encodedWidth : encodedHeight;
  return width > 3000 || height > 3000;
}

for (const orientation of ['3', '4', '5', '6', '7', '8']) {
  assert.equal(needsRewrite(3000, 2000, orientation), false);
}
assert.equal(needsRewrite(3001, 2000, '6'), true);

console.log('D02_ORIGINAL_SMALL_EXIF_BYTE_PRESERVATION_OK TOTAL=12 FAILED=0');
