import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalNative = original('com/gingerlabs/notability/core/glmath/GLMathNative.java');
const originalDraw = original('defpackage/p18.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const insertPlan = read('note/src/main/ets/core/model/OriginalMathInsertPlan.ets');
const readArgbStart = native.indexOf('bool ReadArgb(');
const setNumberStart = native.indexOf('\nvoid SetNumber(', readArgbStart);
const readArgb = native.slice(readArgbStart, setNumberStart);
const measureStart = native.indexOf('napi_value Measure(');
const renderStart = native.indexOf('napi_value Render(');
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const measure = native.slice(measureStart, renderStart);
const render = native.slice(renderStart, cleanupStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original nativeDraw exposes color as a signed Java int',
  /nativeDraw\(String latex, float width, float height, float fontSize, int argbColor,/.test(originalNative) &&
  /nativeDraw[\s\S]*?FFFILcom\/gingerlabs\/notability\/core\/glmath\/MathDrawTarget/.test(originalNative));
check('original draw path preserves the int color argument through the JNI call',
  /public final \/\* synthetic \*\/ int N;/.test(originalDraw) &&
  /nativeDraw\(str, f, f2, q18VarD\.a, this\.N,/.test(originalDraw));
check('Harmony math insertion retains original signed black ARGB',
  /latex: latex, color: -16777216,/.test(insertPlan));

check('native ARGB reader produces an unsigned 32-bit bit pattern',
  /bool ReadArgb\(napi_env env, napi_value value, uint32_t &result\)/.test(readArgb));
check('native ARGB reader requires a finite integral JavaScript number',
  /ReadDouble\(env, value, number\)/.test(readArgb) &&
  /std::trunc\(number\) != number/.test(readArgb));
check('native ARGB reader accepts only signed-int32 through unsigned-int32 representations',
  /number < std::numeric_limits<int32_t>::min\(\)/.test(readArgb) &&
  /number > std::numeric_limits<uint32_t>::max\(\)/.test(readArgb));
check('negative ARGB values are converted through int32 to preserve their bit pattern',
  /number < 0[\s\S]*?static_cast<uint32_t>\(static_cast<int32_t>\(number\)\)/.test(readArgb));
check('non-negative uint32 ARGB values remain accepted for Harmony callers',
  /: static_cast<uint32_t>\(number\)/.test(readArgb));

check('render stores color as uint32 and validates it with the dedicated reader',
  /uint32_t color = 0;/.test(render) &&
  /ReadArgb\(env, arguments\[4\], color\)/.test(render));
check('render forwards the validated ARGB bits without another numeric reinterpretation',
  /Parse\(latex, static_cast<int>\(width\), static_cast<float>\(fontSize\), color\)/.test(render) &&
  !/static_cast<uint32_t>\(color\)/.test(render));
check('measure and render share explicit logical and font-size narrowing limits',
  /constexpr double MAX_LOGICAL_EDGE = 100000\.0/.test(native) &&
  /constexpr double MAX_FONT_SIZE = 512\.0/.test(native) &&
  /width > MAX_LOGICAL_EDGE/.test(measure) && /fontSize > MAX_FONT_SIZE/.test(measure) &&
  /width > MAX_LOGICAL_EDGE/.test(render) && /height > MAX_LOGICAL_EDGE/.test(render) &&
  /fontSize > MAX_FONT_SIZE/.test(render));
check('render rejects logical overflow before ceil and integer narrowing',
  render.indexOf('width > MAX_LOGICAL_EDGE') < render.indexOf('const int pixelWidth') &&
  render.indexOf('height > MAX_LOGICAL_EDGE') < render.indexOf('const int pixelHeight') &&
  render.indexOf('fontSize > MAX_FONT_SIZE') < render.indexOf('static_cast<float>(fontSize)'));

function readArgbModel(number) {
  if (!Number.isFinite(number) || !Number.isInteger(number) ||
    number < -2147483648 || number > 4294967295) {
    return null;
  }
  return number < 0 ? number >>> 0 : number;
}

check('runtime model preserves common signed and unsigned ARGB encodings',
  readArgbModel(-16777216) === 0xFF000000 &&
  readArgbModel(-1) === 0xFFFFFFFF &&
  readArgbModel(0xFF000000) === 0xFF000000 &&
  readArgbModel(0xFFFFFFFF) === 0xFFFFFFFF);
check('runtime model preserves both accepted numeric endpoints',
  readArgbModel(-2147483648) === 0x80000000 &&
  readArgbModel(4294967295) === 0xFFFFFFFF);
check('runtime model rejects fractional non-finite and out-of-range colors',
  readArgbModel(1.5) === null && readArgbModel(Number.NaN) === null &&
  readArgbModel(Number.POSITIVE_INFINITY) === null &&
  readArgbModel(-2147483649) === null && readArgbModel(4294967296) === null);

console.log(`TOTAL=${checks.length} FAILED=0`);
