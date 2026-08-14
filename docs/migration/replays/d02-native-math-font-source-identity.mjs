import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const resolver = original('defpackage/lz4.java');
const measurer = original('com/gingerlabs/notability/core/glmath/GLMathTextMeasurer.java');
const target = original('com/gingerlabs/notability/core/glmath/MathDrawTarget.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const textBox = read('note/src/main/cpp/third_party/microtex/src/box/box_single.cpp');
const macros = read('note/src/main/cpp/third_party/microtex/src/core/macro_impl.h');

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('MicroTeX externalfont forwards the requested source into text rendering',
  /inline macro\(externalfont\)[\s\S]*?TextRenderingBox::setFont\(x\)/.test(macros) &&
  /TextRenderingBox::setFont\(const string& name\)[\s\S]*?Font::_create\(name, PLAIN, 10\)/.test(textBox));
check('original empty font source resolves directly to the styled default typeface',
  /if \(str\.length\(\) == 0\)[\s\S]*?Typeface\.defaultFromStyle\(i\)/.test(resolver));
check('original nonempty source is treated as a font file and then styled',
  /Typeface\.createFromFile\(str\)/.test(resolver) &&
  /if \(i != 0\)[\s\S]*?Typeface\.create\(typefaceCreateFromFile, i\)/.test(resolver));
check('original invalid font file falls back without losing the requested style',
  /catch \(RuntimeException e\)[\s\S]*?Typeface\.defaultFromStyle\(i\)/.test(resolver));
check('original resolver identity and cache key include source and style',
  /new k1a\(str, Integer\.valueOf\(i\)\)/.test(resolver) &&
  /linkedHashMap\.put\(k1aVar, obj\)/.test(resolver));
check('original measurement and drawing resolve the same font source style and size tuple',
  /measure\(String text, String fontFile, int fontStyle, float fontSize\)/.test(measurer) &&
  /lz4\.a\.a\(fontStyle, fontFile\)/.test(measurer) &&
  /drawText\(String text, float x, float y, String fontFile, int fontStyle, float fontSize\)/.test(target) &&
  /lz4\.a\.a\(fontStyle, fontFile\)/.test(target));

check('Harmony font stores the source style and size as independent identity fields',
  /HarmonyFont\(std::string file, int style, float size\)/.test(native) &&
  /file_\(std::move\(file\)\), style_\(style\), size_\(size\)/.test(native));
check('Harmony attempts every nonempty source as a font file',
  /file_\.empty\(\) \? OH_Drawing_TypefaceCreateDefault\(\) :[\s\S]*?OH_Drawing_TypefaceCreateFromFile\(file_\.c_str\(\), 0\)/.test(native));
check('Harmony invalid font files fall back to the platform default typeface',
  /if \(typeface_ == nullptr\) \{[\s\S]*?typeface_ = OH_Drawing_TypefaceCreateDefault\(\)/.test(native));
check('Harmony applies requested style to both loaded and fallback typefaces',
  /OH_Drawing_FontSetFakeBoldText\(font, \(style_ & tex::BOLD\) != 0\)/.test(native) &&
  /OH_Drawing_FontSetTextSkewX\(font, \(style_ & tex::ITALIC\) != 0/.test(native) &&
  /configureNativeFont\(font_, true\);[\s\S]*?configureNativeFont\(measureFont_, false\);/.test(native));
check('Harmony file-font creation preserves the original source with plain style',
  /Font \*Font::create\(const std::string &file, float size\)[\s\S]*?new HarmonyFont\(file, PLAIN, size\)/.test(native));
check('Harmony named-font creation no longer discards the requested source',
  /Font::_create\(const std::string &name, int style, float size\)[\s\S]*?make_shared<HarmonyFont>\(name, style, size\)/.test(native));
check('Harmony deriveFont retains source and size while replacing style',
  /deriveFont\(int style\)[\s\S]*?make_shared<HarmonyFont>\(file_, style, size_\)/.test(native));
check('Harmony font equality keeps distinct source style and size identities',
  /font->file_ == file_ && font->style_ == style_ && font->size_ == size_/.test(native));

function resolveSource(source, style, fileLoads) {
  return source.length === 0 || !fileLoads
    ? { typeface: 'default', source, style }
    : { typeface: 'file', source, style };
}

check('runtime model preserves source identity across file success and fallback',
  assert.deepEqual(resolveSource('/data/font.ttf', 1, true),
    { typeface: 'file', source: '/data/font.ttf', style: 1 }) === undefined &&
  assert.deepEqual(resolveSource('Serif', 2, false),
    { typeface: 'default', source: 'Serif', style: 2 }) === undefined);
check('runtime model keeps Serif and SansSerif identities distinct after equal visual fallback',
  resolveSource('Serif', 0, false).source !== resolveSource('SansSerif', 0, false).source);

console.log(`TOTAL=${checks.length} FAILED=0`);
