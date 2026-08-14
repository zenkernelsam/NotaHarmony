import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalDraw = original('defpackage/p18.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const harmonyEngine = read('note/src/main/ets/rendering/OriginalMathEngine.ets');
const buildProfile = read('build-profile.json5');
const renderStart = native.indexOf('napi_value Render(');
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const render = native.slice(renderStart, cleanupStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original draws directly into the Android Bitmap-backed Canvas',
  /Bitmap\.createBitmap\(iCeil, iCeil2, Bitmap\.Config\.ARGB_8888\)/.test(originalDraw) &&
  /Canvas canvas = new Canvas\(bitmapCreateBitmap\)/.test(originalDraw) &&
  /new MathDrawTarget\(canvas\)/.test(originalDraw));
check('Harmony target SDK supports the Native Drawing pixel-read contract',
  /compatibleSdkVersion": "6\.0\.1\(21\)"/.test(buildProfile));
check('Harmony validates actual bitmap dimensions color format and alpha format',
  /OH_Drawing_BitmapGetWidth\(bitmap\.get\(\)\) != static_cast<uint32_t>\(pixelWidth\)/.test(render) &&
  /OH_Drawing_BitmapGetHeight\(bitmap\.get\(\)\) != static_cast<uint32_t>\(pixelHeight\)/.test(render) &&
  /OH_Drawing_BitmapGetColorFormat\(bitmap\.get\(\)\) != COLOR_FORMAT_RGBA_8888/.test(render) &&
  /OH_Drawing_BitmapGetAlphaFormat\(bitmap\.get\(\)\) != ALPHA_FORMAT_PREMUL/.test(render));
check('Harmony defines an explicit tightly packed destination row length',
  /const size_t rowBytes = static_cast<size_t>\(pixelWidth\) \* 4;/.test(render));
check('Harmony derives ArrayBuffer length from packed row bytes and height',
  /const size_t byteLength = rowBytes \* pixelHeight;/.test(render));
check('Harmony describes the destination pixels with matching dimensions and format',
  /const OH_Drawing_Image_Info destinationInfo = \{[\s\S]*?pixelWidth, pixelHeight, COLOR_FORMAT_RGBA_8888, ALPHA_FORMAT_PREMUL\};/.test(render));
check('Harmony uses the platform row-aware pixel export API',
  /OH_Drawing_BitmapReadPixels\(bitmap\.get\(\), &destinationInfo, destination, rowBytes, 0, 0\)/.test(render));
check('pixel export failure rejects the result instead of returning partial bytes',
  /if \(!OH_Drawing_BitmapReadPixels[\s\S]*?return ErrorResult\(env, "formula pixel transfer failed"\);/.test(render));
check('raw internal bitmap storage is no longer copied with a packed-layout assumption',
  !/std::memcpy\(destination, source, byteLength\)/.test(render));
check('ArrayBuffer allocation succeeds before the row-aware export begins',
  render.indexOf('napi_create_arraybuffer') < render.indexOf('OH_Drawing_BitmapReadPixels'));
check('row-aware export completes before the success result is constructed',
  render.indexOf('OH_Drawing_BitmapReadPixels') < render.lastIndexOf('napi_create_object(env, &result)'));
check('ArkTS consumes the exported buffer as the same RGBA_8888 dimensions',
  /srcPixelFormat: image\.PixelMapFormat\.RGBA_8888/.test(harmonyEngine) &&
  /pixelFormat: image\.PixelMapFormat\.RGBA_8888/.test(harmonyEngine) &&
  /size: \{ width: result\.width, height: result\.height \}/.test(harmonyEngine));

function packedRows(source, width, height, sourceRowBytes) {
  const destinationRowBytes = width * 4;
  const destination = new Uint8Array(destinationRowBytes * height);
  for (let y = 0; y < height; y++) {
    destination.set(source.subarray(y * sourceRowBytes, y * sourceRowBytes + destinationRowBytes),
      y * destinationRowBytes);
  }
  return destination;
}

check('runtime model removes internal row padding without shifting later rows', (() => {
  const source = Uint8Array.from([
    1, 2, 3, 4, 5, 6, 7, 8, 90, 91, 92, 93,
    9, 10, 11, 12, 13, 14, 15, 16, 94, 95, 96, 97,
  ]);
  const packed = packedRows(source, 2, 2, 12);
  return assert.deepEqual([...packed],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]) === undefined;
})());
check('runtime model demonstrates why a raw contiguous prefix corrupts padded rows', (() => {
  const source = Uint8Array.from([
    1, 2, 3, 4, 5, 6, 7, 8, 90, 91, 92, 93,
    9, 10, 11, 12, 13, 14, 15, 16, 94, 95, 96, 97,
  ]);
  const naive = source.slice(0, 16);
  return assert.notDeepEqual([...naive], [...packedRows(source, 2, 2, 12)]) === undefined;
})());

console.log(`TOTAL=${checks.length} FAILED=0`);
