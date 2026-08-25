#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const readWindows = (path) => fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
const androidNormalizer = readWindows(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vuh.java');
const androidExif = readWindows(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/w34.java');
const harmonyNormalizer = readWindows('note/src/main/ets/data/OriginalImageNormalizer.ets');
const evidence = readWindows(
  'docs/migration/evidence/original-normalization-mirror-parity-harmony-2026-08-26.md');
const adr = readWindows('docs/migration/adr/ADR-0418-original-normalization-mirror-parity.md');

assert.match(androidNormalizer, /int iL = w34Var != null \? w34Var\.l\(\) : 0;/);
assert.match(androidNormalizer, /matrix\.postRotate\(iL\);/);
assert.doesNotMatch(androidNormalizer, /postScale\(-1/);
assert.match(androidExif, /public final int l\(\)/);

const rotateIndex = harmonyNormalizer.indexOf('await pixelMap.rotate(rotationDegrees);');
const mirrorIndex = harmonyNormalizer.indexOf('await pixelMap.flip');
const scaleIndex = harmonyNormalizer.indexOf('await pixelMap.scale(scaleX, scaleY);');
assert.ok(rotateIndex >= 0);
assert.equal(mirrorIndex, -1);
assert.ok(scaleIndex > rotateIndex);
assert.match(harmonyNormalizer,
  /export function originalRotationDegrees\(orientation: string\): number \{/);
assert.match(harmonyNormalizer,
  /export function originalExifMirrorsHorizontally\(orientation: string\): boolean \{/);

for (const source of [evidence, adr]) {
  assert.ok(source.includes('vuh.b()'));
  assert.ok(source.includes('postRotate'));
  assert.ok(source.includes('2/4/5/7'));
  assert.ok(source.includes('原版同源限制'));
}

console.log('D02_ORIGINAL_NORMALIZATION_MIRROR_PARITY_REPLAY_OK TOTAL=11 FAILED=0');
