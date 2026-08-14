import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalDraw = original('defpackage/p18.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const harmonyEngine = read('note/src/main/ets/rendering/OriginalMathEngine.ets');
const renderStart = native.indexOf('napi_value Render(');
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const render = native.slice(renderStart, cleanupStart);
const pixelMapStart = harmonyEngine.indexOf('image.createPixelMapSync(result.pixels');
const pixelMapEnd = harmonyEngine.indexOf('\n    });', pixelMapStart);
const pixelMapOptions = harmonyEngine.slice(pixelMapStart, pixelMapEnd);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original renders through an Android ARGB_8888 Bitmap-backed Canvas',
  /Bitmap\.createBitmap\(iCeil, iCeil2, Bitmap\.Config\.ARGB_8888\)/.test(originalDraw) &&
  /new Canvas\(bitmapCreateBitmap\)/.test(originalDraw));
check('Harmony Native Drawing bitmap is explicitly premultiplied',
  /OH_Drawing_BitmapFormat format = \{COLOR_FORMAT_RGBA_8888, ALPHA_FORMAT_PREMUL\}/.test(render));
check('Harmony validates the actual native alpha type before exporting',
  /OH_Drawing_BitmapGetAlphaFormat\(bitmap\.get\(\)\) != ALPHA_FORMAT_PREMUL/.test(render));
check('Harmony ReadPixels destination preserves premultiplied RGBA',
  /pixelWidth, pixelHeight, COLOR_FORMAT_RGBA_8888, ALPHA_FORMAT_PREMUL/.test(render));
check('PixelMap source and destination formats both remain RGBA_8888',
  /srcPixelFormat: image\.PixelMapFormat\.RGBA_8888/.test(pixelMapOptions) &&
  /pixelFormat: image\.PixelMapFormat\.RGBA_8888/.test(pixelMapOptions));
check('PixelMap explicitly interprets the exported bytes as premultiplied alpha',
  /alphaType: image\.AlphaType\.PREMUL/.test(pixelMapOptions));
check('PixelMap never relabels native premultiplied bytes as unpremultiplied',
  !/alphaType: image\.AlphaType\.UNPREMUL/.test(pixelMapOptions));
check('PixelMap dimensions are taken from the same native render result',
  /size: \{ width: result\.width, height: result\.height \}/.test(pixelMapOptions));

function compositePremulOverWhite(redPremul, alpha) {
  return Math.round(redPremul + 255 * (1 - alpha));
}

check('runtime model preserves a half-transparent red edge when alpha is declared premultiplied',
  compositePremulOverWhite(128, 128 / 255) === 255);
check('runtime model shows double premultiplication would darken the same edge', (() => {
  const alpha = 128 / 255;
  const incorrectlyPremultipliedAgain = Math.round(128 * alpha);
  return compositePremulOverWhite(incorrectlyPremultipliedAgain, alpha) < 255;
})());

console.log(`TOTAL=${checks.length} FAILED=0`);
