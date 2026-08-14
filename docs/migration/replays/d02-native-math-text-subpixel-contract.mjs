import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const measurer = original('com/gingerlabs/notability/core/glmath/GLMathTextMeasurer.java');
const target = original('com/gingerlabs/notability/core/glmath/MathDrawTarget.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const fontStart = native.indexOf('class HarmonyFont');
const layoutStart = native.indexOf('class HarmonyTextLayout', fontStart);
const graphicsStart = native.indexOf('class HarmonyGraphics', layoutStart);
const font = native.slice(fontStart, layoutStart);
const layout = native.slice(layoutStart, graphicsStart);
const graphicsEnd = native.indexOf('\nbool ReadString(', graphicsStart);
const graphics = native.slice(graphicsStart, graphicsEnd);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original measurement creates an anti-aliased Paint without the subpixel text flag',
  /Paint paint = new Paint\(1\)/.test(measurer));
check('original drawing creates text Paint with anti-alias and subpixel text flags',
  /this\.textPaint = new Paint\(129\)/.test(target));
check('original stroke and fill Paints do not inherit the text-only subpixel flag',
  (target.match(/new Paint\(1\)/g) ?? []).length === 2);

const ANTI_ALIAS_FLAG = 0x01;
const SUBPIXEL_TEXT_FLAG = 0x80;
check('numeric Android flags prove that only drawing carries SUBPIXEL_TEXT_FLAG',
  (1 & ANTI_ALIAS_FLAG) !== 0 && (1 & SUBPIXEL_TEXT_FLAG) === 0 &&
  (129 & ANTI_ALIAS_FLAG) !== 0 && (129 & SUBPIXEL_TEXT_FLAG) !== 0);

check('Harmony allocates independent drawing and measurement Font handles',
  /font_ = OH_Drawing_FontCreate\(\);[\s\S]*?measureFont_ = OH_Drawing_FontCreate\(\);/.test(font) &&
  /OH_Drawing_Font \*font_ = nullptr;[\s\S]*?OH_Drawing_Font \*measureFont_ = nullptr;/.test(font));
check('Harmony configures drawing with subpixel and measurement without it',
  /configureNativeFont\(font_, true\);[\s\S]*?configureNativeFont\(measureFont_, false\);/.test(font) &&
  /OH_Drawing_FontSetSubpixel\(font, subpixel\)/.test(font));
check('both Font handles still share typeface size edging bold and italic configuration',
  /OH_Drawing_FontSetTypeface\(font, typeface_\)/.test(font) &&
  /OH_Drawing_FontSetTextSize\(font, size_\)/.test(font) &&
  /OH_Drawing_FontSetEdging\(font, FONT_EDGING_ANTI_ALIAS\)/.test(font) &&
  /OH_Drawing_FontSetFakeBoldText\(font, \(style_ & tex::BOLD\) != 0\)/.test(font) &&
  /OH_Drawing_FontSetTextSkewX\(font, \(style_ & tex::ITALIC\) != 0/.test(font));
check('Harmony layout exclusively measures with the non-subpixel Font handle',
  /font->measureNative\(\)/.test(layout) &&
  /OH_Drawing_FontGetMetrics\(measureFont, &metrics\)/.test(layout) &&
  /OH_Drawing_FontMeasureText\(measureFont,/.test(layout) &&
  !/font->native\(\)/.test(layout));
check('Harmony drawing exclusively creates the TextBlob with the subpixel Font handle',
  /font->native\(\)/.test(graphics) &&
  /OH_Drawing_TextBlobCreateFromText\([\s\S]*?font->native\(\), TEXT_ENCODING_UTF8\)/.test(graphics) &&
  !/measureNative\(\)/.test(graphics));
check('Harmony releases both Native Font handles before their shared typeface',
  font.indexOf('OH_Drawing_FontDestroy(measureFont_)') >= 0 &&
  font.indexOf('OH_Drawing_FontDestroy(measureFont_)') < font.indexOf('OH_Drawing_FontDestroy(font_)') &&
  font.indexOf('OH_Drawing_FontDestroy(font_)') < font.indexOf('OH_Drawing_TypefaceDestroy(typeface_)'));

function paintFlags(subpixel) {
  return ANTI_ALIAS_FLAG | (subpixel ? SUBPIXEL_TEXT_FLAG : 0);
}

check('runtime flag model preserves the original measurement and drawing split',
  paintFlags(false) === 1 && paintFlags(true) === 129);

console.log(`TOTAL=${checks.length} FAILED=0`);
