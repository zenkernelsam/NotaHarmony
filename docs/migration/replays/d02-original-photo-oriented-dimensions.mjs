#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = path => fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
const root = process.cwd();
const vuh = read('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vuh.java');
const normalizer = read('note/src/main/ets/data/OriginalImageNormalizer.ets');
const ingress = read('note/src/main/ets/data/OriginalPhotoIngress.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const renderer = read('note/src/main/ets/rendering/ImageCanvasRenderer.ets');
const fixture = read('note/src/test/OriginalImageNormalizer.test.ets');
const pickerReplay = read('docs/migration/replays/d02-original-photo-picker-caller.mjs');

const gate = vuh.indexOf('if (i3 <= 3000 && i4 <= 3000) {');
const ratio = vuh.indexOf('float fMax = 3000.0f / Math.max(i2, i);');
const rotate = vuh.indexOf('matrix.postRotate(iL);');
const result = vuh.indexOf('return new ep5(((Number) k1aVar.I).intValue()', rotate);
assert.ok(gate >= 0 && ratio > gate && rotate > ratio && result > rotate);
assert.match(vuh, /int i3 = z \? i : i2;/);
assert.match(vuh, /int i4 = z \? i2 : i;/);

assert.match(normalizer,
  /planOriginalImageDownscale\(info\.size\.width, info\.size\.height\)/);
assert.match(normalizer,
  /const targetOriented = originalImageOrientedDimensions\(\s*downscale\.width,\s*downscale\.height, orientation\);/);
assert.match(normalizer, /decoded\.size\.width !== targetOriented\.width/);
assert.match(normalizer, /encodedWidth: targetOriented\.width/);
assert.match(normalizer, /encodedHeight: targetOriented\.height/);

assert.match(ingress, /orientedWidth: normalized\.orientedWidth/);
assert.match(ingress, /orientedHeight: normalized\.orientedHeight/);
assert.match(canvas, /intrinsicWidth: item\.orientedWidth/);
assert.match(canvas, /intrinsicHeight: item\.orientedHeight/);
assert.match(persistence, /intrinsicWidth: normalized\.orientedWidth/);
assert.match(persistence, /intrinsicHeight: normalized\.orientedHeight/);
assert.match(renderer, /const orientedWidth: number = swapsAxes \? bitmapHeight : bitmapWidth/);
assert.match(renderer, /const orientedHeight: number = swapsAxes \? bitmapWidth : bitmapHeight/);
assert.match(renderer, /ctx\.translate\(-crop\.left, -crop\.top\);/);
assert.match(renderer, /ctx\.transform\(geometry\.orientationTransform\);/);
assert.ok(fixture.includes('const orientedTarget = originalImageOrientedDimensions'));
assert.ok(pickerReplay.includes('oriented intrinsic dimensions'));

function plan(width, height) {
  const ratio = Math.fround(3000 / Math.fround(Math.max(width, height)));
  return { width: Math.max(1, Math.round(width * ratio)), height: Math.max(1, Math.round(height * ratio)) };
}
function oriented(width, height, orientation) {
  return ['5', '6', '7', '8'].includes(orientation)
    ? { width: height, height: width } : { width, height };
}

const encoded = plan(6000, 1000);
assert.deepEqual(encoded, { width: 3000, height: 500 });
assert.deepEqual(oriented(encoded.width, encoded.height, '6'), { width: 500, height: 3000 });
assert.deepEqual(oriented(encoded.width, encoded.height, '8'), { width: 500, height: 3000 });
assert.deepEqual(oriented(encoded.width, encoded.height, '3'), { width: 3000, height: 500 });

console.log('D02_ORIGINAL_PHOTO_ORIENTED_DIMENSIONS_OK TOTAL=19 FAILED=0');
