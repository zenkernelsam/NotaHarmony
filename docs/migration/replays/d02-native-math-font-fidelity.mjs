import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const measurer = original('com/gingerlabs/notability/core/glmath/GLMathTextMeasurer.java');
const target = original('com/gingerlabs/notability/core/glmath/MathDrawTarget.java');
const fontCache = original('defpackage/lz4.java');
const native = read('note/src/main/cpp/nota_math.cpp');

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original text measurement returns advance ascent and descent rather than tight glyph bounds',
  /new float\[\]\{paint\.measureText\(text\), fontMetrics\.ascent, fontMetrics\.descent\}/.test(measurer));
check('original font resolver preserves requested default and file-backed styles',
  /Typeface\.defaultFromStyle\(i\)/.test(fontCache) &&
  /if \(i != 0\)[\s\S]*?Typeface\.create\(typefaceCreateFromFile, i\)/.test(fontCache));
check('original draw target applies the derived style to text rendering',
  /textPaint\.setTypeface\(lz4\.a\.a\(fontStyle, fontFile\)\)/.test(target));
check('original leaves the platform miter default intact for zero limits',
  /if \(miterLimit > 0\.0f\)[\s\S]*?setStrokeMiter\(miterLimit\)/.test(target));

check('Harmony font stores style and deriveFont propagates the requested style',
  /HarmonyFont\(std::string file, int style, float size\)/.test(native) &&
  /style_\(style\)/.test(native) &&
  /deriveFont\(int style\)[\s\S]*?make_shared<HarmonyFont>\(file_, style, size_\)/.test(native));
check('Harmony font identity includes style as in the original native port',
  /font->file_ == file_ && font->style_ == style_ && font->size_ == size_/.test(native));
check('Harmony synthesizes bold and italic when the platform typeface lacks a styled clone',
  /OH_Drawing_FontSetFakeBoldText\(font, \(style_ & tex::BOLD\) != 0\)/.test(native) &&
  /OH_Drawing_FontSetTextSkewX\(font, \(style_ & tex::ITALIC\) != 0 \? ITALIC_SKEW_X : 0\.0f\)/.test(native) &&
  /configureNativeFont\(font_, true\);[\s\S]*?configureNativeFont\(measureFont_, false\);/.test(native));
check('Harmony measures advance separately from baseline font metrics',
  /OH_Drawing_Font \*measureFont = font == nullptr \? nullptr : font->measureNative\(\)/.test(native) &&
  /OH_Drawing_FontGetMetrics\(measureFont, &metrics\)/.test(native) &&
  /OH_Drawing_FontMeasureText\(measureFont,[\s\S]*?TEXT_ENCODING_UTF8, nullptr, &width\)/.test(native));
check('Harmony recreates the original zero-x ascent descent layout box',
  /bounds\.x = 0;[\s\S]*?bounds\.y = metrics\.ascent;[\s\S]*?bounds\.w = width;[\s\S]*?bounds\.h = metrics\.descent - metrics\.ascent/.test(native));
check('Harmony validates finite ordered metrics before exposing a layout',
  /!std::isfinite\(width\)/.test(native) &&
  /!std::isfinite\(metrics\.ascent\)/.test(native) &&
  /!std::isfinite\(metrics\.descent\)/.test(native) &&
  /metrics\.descent <= metrics\.ascent/.test(native));
check('Harmony only overrides miter limit when the original would',
  /if \(stroke\.miterLimit > 0\) OH_Drawing_PenSetMiterLimit/.test(native));

function textBox(width, ascent, descent, size) {
  const height = -ascent * size / 10;
  return {
    width: (width + 0.4) * size / 10,
    height,
    depth: (descent - ascent) * size / 10 - height,
  };
}

check('runtime model preserves independent ascent height and descent depth',
  assert.deepEqual(textBox(20, -8, 2, 10), { width: 20.4, height: 8, depth: 2 }) === undefined);

console.log(`TOTAL=${checks.length} FAILED=0`);
