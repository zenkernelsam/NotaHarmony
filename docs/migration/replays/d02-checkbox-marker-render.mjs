import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const jo3 = original('jo3.java');
const no3 = original('no3.java');
const zoe = original('zoe.java');
const iu1 = original('iu1.java');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const fixture = read('note/src/test/RendererStyle.test.ets');

assert.match(no3, /no3Var\.p\(j, f3, j3, f2/);
assert.match(jo3, /iu1\.b\(0\.75f, j4\)/);
assert.match(jo3, /no3\.c0\(no3Var, j4, f \+ 0\.5f/);
assert.match(jo3, /float f3 = f2 \/ 15\.0f/);
assert.match(jo3, /jtVar\.g\(f7, f8\)/);
assert.match(jo3, /jtVar\.f\(f9, \(5\.04f \* f3\) \+ f5\)/);
assert.match(jo3, /jtVar\.f\(\(7\.92f \* f3\) \+ f4, f5 \+ 0\.0f\)/);
assert.match(jo3, /jtVar\.f\(\(9\.0f \* f3\) \+ f4, f6 \+ f5\)/);
assert.match(jo3, /jtVar\.f\(f9, \(7\.2f \* f3\) \+ f5\)/);
assert.match(jo3, /jtVar\.f\(f4 \+ 0\.0f, \(f3 \* 4\.32f\) \+ f5\)/);
assert.match(jo3, /> 0\.7f \? iu1\.b : iu1\.e/);
assert.match(iu1, /public static final long b = kkf\.f\(4278190080L\)/);
assert.match(iu1, /e = kkf\.f\(4294967295L\)/);
assert.match(zoe, /f2 = i != 2 \? 1\.0f : 1\.6f/);
assert.match(zoe, /return \(f \/ 14\.0f\) \* 36\.0f/);

assert.doesNotMatch(renderer, /\\u2610|\\u2611/);
assert.match(renderer, /private checkboxColumnWidth/);
assert.match(renderer, /return element\.fontSize \* 1\.6/);
assert.match(renderer, /element\.fontSize \* 36 \/ 14/);
assert.match(renderer, /ctx\.arc\(center\.x, center\.y, isChecked \? radius \+ 0\.5 : radius/);
assert.match(renderer, /this\.colorToRgba\(color, 0\.75\)/);
assert.match(renderer, /const unit: number = radius \* 2 \/ 15/);
assert.match(renderer, /unit \* 7\.92/);
assert.match(renderer, /unit \* 4\.32/);
assert.match(renderer, /luminance > 0\.7 \? 'rgba\(0,0,0,1\)' : 'rgba\(255,255,255,1\)'/);
assert.match(fixture, /draws original circular checkbox markers without platform glyphs/);

const radius = Math.max((20 + 8) / 2 - 1, (20 + 8) / 4);
assert.equal(radius, 13);
assert.equal(20 * 1.6, 32);
assert.equal(14 * 36 / 14, 36);
assert.equal((255 * 0.299 + 255 * 0.587 + 255 * 0.114) / 255 > 0.7, true);
assert.equal((0 * 0.299 + 0 * 0.587 + 0 * 0.114) / 255 > 0.7, false);

console.log('checkboxMarkerRender=' +
  'original-circle-alpha-fill-checkpath-contrast-fixed-column-indent-no-platform-glyph');
