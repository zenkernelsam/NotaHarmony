import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const xai = original('sources/defpackage/xai.java');
const q16 = original('sources/defpackage/q16.java');
const o1 = original('sources/defpackage/o1.java');
const n8j = original('sources/defpackage/n8j.java');
const o8j = original('sources/defpackage/o8j.java');
const l96 = original('sources/defpackage/l96.java');
const d1j = original('sources/defpackage/d1j.java');
const shapeEraser = read('note/src/main/ets/rendering/OriginalShapePartialEraser.ets');
const encoder = read('note/src/main/ets/data/OriginalCreateInkPayloadEncoder.ets');
const decoder = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const fixture = read('note/src/test/OriginalShapePartialEraser.test.ets');
const fixtureList = read('note/src/test/List.test.ets');
const evidence = read(
  'docs/migration/evidence/original-shape-partial-erase-jadx-2026-08-15.md');

// q16/xai restore native Shape paths instead of the renderer's sampled hit-test geometry.
assert.match(q16, /Path path = \(Path\)[\s\S]{0,120}\.c\(m4dVar\)/);
assert.match(q16, /Path pathD = xai\.d\(\(\(n5d\) m4dVar\)\.S\(\)\)/);
assert.match(xai, /path\.cubicTo\(/);
assert.match(xai, /path\.quadTo\(/);
assert.match(xai, /path\.lineTo\(/);
assert.match(xai, /path2\.addOval\(0\.0f, 0\.0f/);
assert.match(xai, /path3\.close\(\)/);

// shapeErasePaths keeps the complete center path. l96.W contributes only the arrowhead path.
assert.match(o1, /wx0 wx0VarX = sh8\.x\(pathE, 0, 0, null\)/);
assert.match(o1, /l96\.W\(n5dVar\.S\(\), pathE, n5dVar\.Q\(\)\)/);
assert.match(o1, /new k1a\(wx0VarX,[\s\S]{0,100}ca0VarW\.b/);
assert.match(l96, /pathMeasure\.getSegment\(0\.0f, f4, path3, true\)/);
assert.match(d1j, /return c\(f\) \* 20\.0f/);
assert.match(d1j, /return c\(f\) \* 46\.0f/);

// n8j assigns center/custom/fill in that order and does not inflate center clipping by border width.
assert.match(n8j, /wx0 wx0Var6 = dz3Var\.c/);
assert.match(n8j, /wx0 wx0Var7 = dz3Var\.f \? dz3Var\.e : null/);
assert.match(n8j, /wx0 wx0Var8 = dz3Var\.d/);
assert.match(n8j, /pxh\.d\(wx0Var6, dz3Var\.h\)/);
assert.match(n8j, /new zz3\(wx0VarE3, wx0VarE, wx0VarE2\)/);
assert.match(o8j, /wx0 wx0Var4 = zz3Var\.a/);
assert.match(o8j, /wx0 wx0Var5 = zz3Var\.c/);
assert.match(o8j, /wx0 wx0Var6 = zz3Var\.b/);

// Harmony now mirrors xai.d with native Path verbs and keeps arrow geometry separate.
assert.match(shapeEraser, /path\.addOval\([\s\S]{0,220}\}, 1, drawing\.PathDirection\.CLOCKWISE\)/);
assert.match(shapeEraser, /rotation\.setRotation\(ellipse\.rotationRadians \* 180 \/ Math\.PI/);
assert.doesNotMatch(shapeEraser, /rotation\.rotate\(/);
assert.match(shapeEraser, /path\.cubicTo\(line\.controlPoint1\.x/);
assert.match(shapeEraser, /path\.quadTo\(line\.controlPoint1\.x/);
assert.match(shapeEraser, /path\.lineTo\(line\.end\.x/);
assert.match(shapeEraser, /Android xai\.d\(\) closes every u4d polygon/);
assert.doesNotMatch(shapeEraser, /if \(polygon\.isClosed\)/);
assert.match(shapeEraser, /shapeArrowPath\(shape, centerPath\)/);
assert.match(shapeEraser, /centerPath\.getLength\(false\)/);
assert.match(shapeEraser, /centerPath\.getSegment\(false, run\.start, run\.end, true/);
assert.match(shapeEraser, /return eraserPath\.contains\(position\.x, position\.y\)/);
assert.doesNotMatch(shapeEraser, /shapeLocalSubpaths/);
assert.doesNotMatch(shapeEraser, /new EraserEngine/);
assert.match(shapeEraser, /pen\.setStrokeWidth\(shape\.strokeWidth\)/);
assert.match(shapeEraser, /customPath: customPath/);
assert.match(shapeEraser, /fillPath: fillCommands\.length === 0 \? null/);
assert.match(shapeEraser, /fillColor: fillCommands\.length === 0 \? null : shape\.fillColor/);
assert.match(shapeEraser, /if \(this\.pathContainsConic\(path\)\)/);
assert.match(shapeEraser, /return this\.approximatePathContours\(path\)/);
assert.doesNotMatch(shapeEraser,
  /verb === drawing\.PathIteratorVerb\.QUAD \|\| verb === drawing\.PathIteratorVerb\.CONIC/);

// CREATE_INK and its production decoder agree that fields 9/10/11 are center/custom/fill.
assert.match(encoder, /writeU32\(bytes, table \+ 52, customVector - \(table \+ 52\)\)/);
assert.match(encoder, /writeU32\(bytes, table \+ 56, fillVector - \(table \+ 56\)\)/);
assert.match(decoder, /readByteVector\(\s*9, false/);
assert.match(decoder, /readByteVector\(\s*10, false/);
assert.match(decoder, /readByteVector\(\s*11, false/);

assert.match(fixture, /preserves native quadratic center segments/);
assert.match(fixture, /native oval instead of a sampled polygon/);
assert.match(fixture, /applies the original Ellipse rotation/);
assert.match(fixture, /closes a Polygon like original xai/);
assert.match(fixture, /full Line center path when only the native arrowhead is clipped/);
assert.match(fixture, /does not expand center clipping by half the Shape border width/);
assert.match(fixtureList, /originalShapePartialEraserTest\(\)/);
assert.match(evidence, /center\/custom\/fill component 归属/);
assert.match(evidence, /2E1750C94B811A22F61E0DB5CC2F57A7BC9C5B132B2B22F734902DE3105A6FFC/);

// Geometry sentinels: an arrow-only hit must not shorten center, and a border-only hit must not
// erase center merely because the Shape border is wide.
function arrowScale(width) {
  let adjusted = width;
  if (adjusted < 2) adjusted = ((adjusted - 2) / 2) + 2;
  else if (adjusted > 4) adjusted = ((adjusted - 4) / 4) + 4;
  return Math.max(0, adjusted) / 7;
}

const width = 2;
const baseX = 100 - arrowScale(width) * 46;
const halfWidth = arrowScale(width) * 20;
assert.ok(baseX > 86 && baseX < 87);
assert.ok(halfWidth > 5 && halfWidth < 6);
assert.ok(Math.hypot(90 - 90, 4.4 - 0) > 0.5, 'arrow-only probe is outside center eraser');

const eraserRadius = 1;
const borderHalfWidth = 5;
const borderProbeDistance = 5.5;
assert.ok(borderProbeDistance > eraserRadius, 'original center remains outside eraser');
assert.ok(borderProbeDistance < eraserRadius + borderHalfWidth,
  'the removed expanded-radius implementation would erase the center');

console.log(
  'originalShapePartialEraser=native-path-center-custom-fill-arrow-radius-conic-polygon');
