import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const s18 = original('s18.java');
const p18 = original('p18.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const renderStart = native.indexOf('napi_value Render(');
const renderEnd = native.indexOf('\nvoid Cleanup(', renderStart);
const render = native.slice(renderStart, renderEnd);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original recycles the temporary bitmap when native drawing fails',
  /nativeDraw[\s\S]*?bitmapCreateBitmap\.recycle\(\)/.test(p18));
check('original catches GLMath initialization failures and degrades to unavailable',
  /catch \(Throwable th\)[\s\S]*?new ozb\(th\)/.test(s18) &&
  /GLMath resource extraction failed[\s\S]*?ozbVar = Boolean\.FALSE/.test(s18));

check('native bitmap and canvas ownership uses scoped custom-deleter handles',
  /using BitmapHandle = std::unique_ptr<OH_Drawing_Bitmap, BitmapDeleter>/.test(native) &&
  /OH_Drawing_BitmapDestroy\(bitmap\)/.test(native) &&
  /using CanvasHandle = std::unique_ptr<OH_Drawing_Canvas, CanvasDeleter>/.test(native) &&
  /OH_Drawing_CanvasDestroy\(canvas\)/.test(native));
check('render declares owners in reverse-safe bitmap canvas graphics order',
  render.indexOf('BitmapHandle bitmap(') >= 0 &&
  render.indexOf('BitmapHandle bitmap(') < render.indexOf('CanvasHandle canvas(') &&
  render.indexOf('CanvasHandle canvas(') < render.indexOf('HarmonyGraphics graphics('));
check('render no longer manually destroys scoped bitmap or canvas ownership',
  !render.includes('OH_Drawing_BitmapDestroy(') &&
  !render.includes('OH_Drawing_CanvasDestroy('));

check('bitmap object and backing storage allocations are both validated',
  /BitmapHandle bitmap\(OH_Drawing_BitmapCreate\(\)\);[\s\S]*?if \(!bitmap\)/.test(render) &&
  /void \*source = OH_Drawing_BitmapGetPixels\(bitmap\.get\(\)\)/.test(render) &&
  /source == nullptr/.test(render) &&
  /OH_Drawing_BitmapGetWidth\(bitmap\.get\(\)\) != static_cast<uint32_t>\(pixelWidth\)/.test(render) &&
  /OH_Drawing_BitmapGetHeight\(bitmap\.get\(\)\) != static_cast<uint32_t>\(pixelHeight\)/.test(render) &&
  /OH_Drawing_BitmapGetColorFormat\(bitmap\.get\(\)\) != COLOR_FORMAT_RGBA_8888/.test(render) &&
  /OH_Drawing_BitmapGetAlphaFormat\(bitmap\.get\(\)\) != ALPHA_FORMAT_PREMUL/.test(render));
check('canvas and drawing resources fail closed before any formula draw',
  /CanvasHandle canvas\(OH_Drawing_CanvasCreate\(\)\);[\s\S]*?if \(!canvas\)/.test(render) &&
  /HarmonyGraphics graphics\(canvas\.get\(\)\);[\s\S]*?if \(!graphics\.valid\(\)\)/.test(render) &&
  render.indexOf('if (!graphics.valid())') < render.indexOf('render->draw(graphics, drawX, drawY)'));
check('graphics validity requires canvas pen and brush allocations',
  /if \(canvas_ == nullptr\) return;[\s\S]*?pen_ = OH_Drawing_PenCreate\(\);[\s\S]*?brush_ = OH_Drawing_BrushCreate\(\);[\s\S]*?if \(pen_ == nullptr \|\| brush_ == nullptr\) return;/.test(native) &&
  /bool valid\(\) const \{ return canvas_ != nullptr && pen_ != nullptr && brush_ != nullptr; \}/.test(native));
check('graphics destructor detaches and destroys any partially allocated tools',
  /~HarmonyGraphics\(\)[\s\S]*?CanvasDetachPen[\s\S]*?CanvasDetachBrush[\s\S]*?PenDestroy[\s\S]*?BrushDestroy/.test(native));
check('font and primitive allocations are guarded before native use',
  /if \(typeface_ != nullptr\) OH_Drawing_FontSetTypeface/.test(native) &&
  /OH_Drawing_Font \*native\(\) const \{ return typeface_ == nullptr \? nullptr : font_; \}/.test(native) &&
  (native.match(/if \(rect == nullptr\) \{[\s\S]*?failed_ = true;[\s\S]*?return;[\s\S]*?\}/g) ?? []).length >= 2 &&
  /if \(round == nullptr\) \{[\s\S]*?failed_ = true;[\s\S]*?OH_Drawing_RectDestroy\(rect\);[\s\S]*?return;/.test(native));
check('ArrayBuffer status destination and value are checked before pixel export',
  /napi_value pixels = nullptr/.test(render) &&
  /napi_create_arraybuffer\([\s\S]*?\) != napi_ok \|\|[\s\S]*?destination == nullptr \|\| pixels == nullptr/.test(render) &&
  render.indexOf('destination == nullptr') < render.indexOf('OH_Drawing_BitmapReadPixels'));
check('draw exceptions cross scoped owners and degrade to an error result',
  /render->draw\(graphics, drawX, drawY\)/.test(render) &&
  /catch \(const std::exception &error\)[\s\S]*?return ErrorResult\(env, error\.what\(\)\)/.test(render) &&
  /catch \(\.\.\.\)[\s\S]*?return ErrorResult\(env, "formula renderer failed"\)/.test(render));

console.log(`TOTAL=${checks.length} FAILED=0`);
