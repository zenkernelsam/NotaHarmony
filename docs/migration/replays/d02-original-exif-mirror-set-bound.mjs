#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const g3 = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/g3.java',
  'utf8').replaceAll('\r\n', '\n');
const normalizer = fs.readFileSync(
  'note/src/main/ets/data/OriginalImageNormalizer.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const loader = fs.readFileSync(
  'note/src/main/ets/core/adaptation/ImageAssetLoader.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const renderer = fs.readFileSync(
  'note/src/main/ets/rendering/ImageCanvasRenderer.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const fixture = fs.readFileSync(
  'note/src/test/OriginalImageNormalizer.test.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(g3, /case 6:\s*\n\s*nx0 nx0Var = \(nx0\) this\.J;/);
assert.match(g3, /iC == 2 \|\| iC == 7 \|\| iC == 4 \|\| iC == 5/);
assert.match(g3, /z3 != 0 \|\| i7 > 0/);
const mirrorIndex = g3.indexOf('matrix.postScale(-1.0f, 1.0f, width, height);');
const rotateIndex = g3.indexOf('matrix.postRotate(i7, width, height);');
assert.ok(mirrorIndex >= 0 && mirrorIndex < rotateIndex);

assert.match(normalizer,
  /export function originalExifMirrorsHorizontally\(orientation: string\): boolean \{/);
assert.match(normalizer,
  /return value === '2' \|\| value === '4' \|\| value === '5' \|\| value === '7';/);
assert.doesNotMatch(loader, /orientation\.trim\(\)\.toLowerCase\(\) === '2'/);
assert.match(loader, /originalExifMirrorsHorizontally\(orientation\)/);
for (const orientation of ['2', '4', '5', '7']) {
  const assertion = `expect(originalExifMirrorsHorizontally('${orientation}')).assertTrue();`;
  assert.ok(fixture.includes(assertion));
}
for (const orientation of ['1', '3', '6', '8']) {
  const assertion = `expect(originalExifMirrorsHorizontally('${orientation}')).assertFalse();`;
  assert.ok(fixture.includes(assertion));
}

assert.match(renderer, /geometry\.orientationDegrees !== 0 \|\| geometry\.mirroredHorizontally/);
assert.match(renderer, /ctx\.rotate\(geometry\.orientationDegrees \* Math\.PI \/ 180\);/);
assert.match(renderer, /if \(geometry\.mirroredHorizontally\) \{\s*\n\s+ctx\.scale\(-1, 1\);\s*\n\s+\}/);
const mirrorRender = renderer.indexOf('ctx.scale(-1, 1);');
const rotationRender = renderer.indexOf('ctx.rotate(geometry.orientationDegrees * Math.PI / 180);');
assert.ok(mirrorRender > rotationRender);

console.log('D02_ORIGINAL_EXIF_MIRROR_SET_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
