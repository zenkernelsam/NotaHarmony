import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalNative = original('com/gingerlabs/notability/core/glmath/GLMathNative.java');
const originalFitSource = original('defpackage/s18.java');
const originalDraw = original('defpackage/p18.java');
const layout = read('note/src/main/ets/core/model/OriginalMathInsertPlan.ets');
const fixture = read('note/src/test/OriginalMathInsertPlan.test.ets');
const native = read('note/src/main/cpp/nota_math.cpp');
const measureStart = native.indexOf('napi_value Measure(');
const renderStart = native.indexOf('napi_value Render(');
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const measure = native.slice(measureStart, renderStart);
const render = native.slice(renderStart, cleanupStart);
const readFloatStart = native.indexOf('bool ReadPositiveFloat(');
const readArgbStart = native.indexOf('bool ReadArgb(', readFloatStart);
const readPositiveFloat = native.slice(readFloatStart, readArgbStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original GLMath public geometry and font arguments are Java floats',
  /nativeMeasure\(String latex, float width, float fontSize\)/.test(originalNative) &&
  /nativeDraw\(String latex, float width, float height, float fontSize, int argbColor,/.test(originalNative));
check('original fit stores box limits measured dimensions ratio and result in floats',
  /float fFloor = \(float\) Math\.floor\(f\)/.test(originalFitSource) &&
  /float fFloor2 = \(float\) Math\.floor\(f2\)/.test(originalFitSource) &&
  /float fMin = Math\.min\(fFloor \/ f3, fFloor2 \/ f4\)/.test(originalFitSource) &&
  /new q18\(\(float\) Math\.floor\(fMax \* fMin\), \(float\) Math\.ceil\(f3 \* fMin\), \(float\) Math\.ceil\(f4 \* fMin\)\)/
    .test(originalFitSource));
check('original bitmap sizing multiplies float block geometry by a float scale',
  /public final \/\* synthetic \*\/ float K;/.test(originalDraw) &&
  /public final \/\* synthetic \*\/ float L;/.test(originalDraw) &&
  /public final \/\* synthetic \*\/ float M;/.test(originalDraw) &&
  /Math\.ceil\(f \* f3\)/.test(originalDraw) && /Math\.ceil\(f2 \* f3\)/.test(originalDraw));

check('Harmony fit narrows box and measured values to Float32',
  /const originalWidth: number = Math\.fround\(boxWidth\)/.test(layout) &&
  /const originalHeight: number = Math\.fround\(boxHeight\)/.test(layout) &&
  /const originalMeasuredWidth: number = Math\.fround\(measuredWidth\)/.test(layout) &&
  /const originalMeasuredHeight: number = Math\.fround\(measuredHeight\)/.test(layout));
check('Harmony fit rounds both divisions and all result multiplications as Float32',
  /Math\.fround\(widthLimit \/ originalMeasuredWidth\)/.test(layout) &&
  /Math\.fround\(heightLimit \/ originalMeasuredHeight\)/.test(layout) &&
  /Math\.floor\(Math\.fround\(measurementFontSize \* scale\)\)/.test(layout) &&
  /Math\.ceil\(Math\.fround\(originalMeasuredWidth \* scale\)\)/.test(layout) &&
  /Math\.ceil\(Math\.fround\(originalMeasuredHeight \* scale\)\)/.test(layout));
check('Harmony permits only the original one-pixel ceil rounding overshoot',
  /const ORIGINAL_MATH_FLOAT32_ROUNDING_OVERSHOOT: number = 1/.test(layout) &&
  /width <= widthLimit \+ ORIGINAL_MATH_FLOAT32_ROUNDING_OVERSHOOT/.test(layout) &&
  /height <= heightLimit \+ ORIGINAL_MATH_FLOAT32_ROUNDING_OVERSHOOT/.test(layout) &&
  /measuredWidth > ORIGINAL_MATH_INSERT_MAX_WIDTH \+ ORIGINAL_MATH_FLOAT32_ROUNDING_OVERSHOOT/.test(layout));
check('ArkTS fixture locks exact-axis and one-pixel overshoot regressions',
  /fitOriginalMathMeasuredSizeToBox\(27, 55, 126, 319\)/.test(fixture) &&
  /fitOriginalMathMeasuredSizeToBox\(240, 81, 852, 133\)/.test(fixture) &&
  /roundedOvershoot\?\.width\)\.assertEqual\(241\)/.test(fixture));

check('native Float reader validates the double before and after narrowing',
  /ReadDouble\(env, value, number\)/.test(readPositiveFloat) &&
  /number <= 0 \|\| number > maximum/.test(readPositiveFloat) &&
  /const float narrowed = static_cast<float>\(number\)/.test(readPositiveFloat) &&
  /!std::isfinite\(narrowed\) \|\| narrowed <= 0/.test(readPositiveFloat));
check('native measure stores width and font size as floats before parsing',
  /float width = 0;[\s\S]*?float fontSize = 0;/.test(measure) &&
  /ReadPositiveFloat\(env, arguments\[1\], MAX_LOGICAL_EDGE, width\)/.test(measure) &&
  /Parse\(latex, static_cast<int>\(width\), fontSize, tex::black\)/.test(measure));
check('native render stores every original floating argument as float',
  /float width = 0, height = 0, fontSize = 0, pixelScale = 0;/.test(render) &&
  /ReadPositiveFloat\(env, arguments\[5\], 4\.0, pixelScale\)/.test(render));
check('native render uses Float32 values for bitmap sizing parsing centering and canvas scale',
  /std::ceil\(width \* pixelScale\)/.test(render) &&
  /std::ceil\(height \* pixelScale\)/.test(render) &&
  /Parse\(latex, static_cast<int>\(width\), fontSize, color\)/.test(render) &&
  /static_cast<int>\(width - renderWidth\) \/ 2/.test(render) &&
  /OH_Drawing_CanvasScale\(canvas\.get\(\), pixelScale, pixelScale\)/.test(render));

function originalFit(boxWidth, boxHeight, measuredWidth, measuredHeight) {
  const widthLimit = Math.fround(Math.floor(Math.fround(boxWidth)));
  const heightLimit = Math.fround(Math.floor(Math.fround(boxHeight)));
  const measuredW = Math.fround(measuredWidth);
  const measuredH = Math.fround(measuredHeight);
  const measurementFontSize = Math.fround(Math.max(widthLimit, heightLimit));
  const scale = Math.fround(Math.min(
    Math.fround(widthLimit / measuredW), Math.fround(heightLimit / measuredH)));
  return {
    fontSize: Math.floor(Math.fround(measurementFontSize * scale)),
    width: Math.ceil(Math.fround(measuredW * scale)),
    height: Math.ceil(Math.fround(measuredH * scale)),
  };
}

check('runtime model shows Float32 narrowing can cross an integer floor boundary',
  Math.floor(10.9999999) === 10 && Math.floor(Math.fround(10.9999999)) === 11);
check('runtime model avoids the former false-null exact-axis double result',
  Math.ceil(319 * (55 / 319)) === 56 &&
  assert.deepEqual(originalFit(27, 55, 126, 319), { fontSize: 9, width: 22, height: 55 }) === undefined);
check('runtime model preserves original one-pixel Float32 overshoot instead of rejecting it',
  assert.deepEqual(originalFit(240, 81, 852, 133), { fontSize: 67, width: 241, height: 38 }) === undefined);

console.log(`TOTAL=${checks.length} FAILED=0`);
