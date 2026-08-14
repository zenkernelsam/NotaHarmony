import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const metrics = original('n18.java');
const engine = original('s18.java');
const draw = original('p18.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const types = read('note/src/main/cpp/types/libnota_math/Index.d.ts');
const harmonyEngine = read('note/src/main/ets/rendering/OriginalMathEngine.ets');
const measureStart = native.indexOf('napi_value Measure(');
const renderStart = native.indexOf('napi_value Render(');
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const measureNative = native.slice(measureStart, renderStart);
const renderNative = native.slice(renderStart, cleanupStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original MathMetrics preserves four independent native fields',
  /public n18\(float f, float f2, float f3, float f4\)/.test(metrics) &&
  /widthPx=[\s\S]*?heightPx=[\s\S]*?baselineFraction=[\s\S]*?depthPx=/.test(metrics));
check('original detailed measurement consumes width height baseline and depth in native order',
  /fArrNativeMeasure\.length < 4/.test(engine) &&
  /new n18\(f2, f3, fArrNativeMeasure\[2\], fArrNativeMeasure\[3\]\)/.test(engine));
check('original block fitting consumes native width and height without folding depth into height',
  /float f3 = fArrNativeMeasure\[0\];[\s\S]*?float f4 = fArrNativeMeasure\[1\]/.test(engine) &&
  /Math\.min\(fFloor \/ f3, fFloor2 \/ f4\)/.test(engine));
check('original creates a ceil-sized bitmap but passes logical block dimensions to nativeDraw',
  /Math\.ceil\(f \* f3\)/.test(draw) && /Math\.ceil\(f2 \* f3\)/.test(draw) &&
  /nativeDraw\(str, f, f2, q18VarD\.a/.test(draw));

check('Harmony parses formulas with the original zero line spacing',
  /constexpr float ORIGINAL_LINE_SPACE = 0\.0f/.test(native) &&
  /fontSize, ORIGINAL_LINE_SPACE, color/.test(native));
check('Harmony measure truncates logical width before parsing',
  /Parse\(latex, static_cast<int>\(width\), static_cast<float>\(fontSize\), tex::black\)/.test(measureNative) &&
  !/Parse\(latex, static_cast<int>\(std::ceil\(width\)\)/.test(measureNative));
check('Harmony render truncates parse width while retaining ceil bitmap allocation',
  /Parse\(latex, static_cast<int>\(width\), static_cast<float>\(fontSize\)/.test(renderNative) &&
  /static_cast<int>\(std::ceil\(width \* pixelScale\)\)/.test(renderNative));
check('Harmony measure exposes the original four independent values',
  /SetNumber\(env, result, "width", render->getWidth\(\)\)/.test(measureNative) &&
  /SetNumber\(env, result, "height", render->getHeight\(\)\)/.test(measureNative) &&
  /SetNumber\(env, result, "baseline", render->getBaseline\(\)\)/.test(measureNative) &&
  /SetNumber\(env, result, "depth", render->getDepth\(\)\)/.test(measureNative) &&
  !/getHeight\(\) \+ render->getDepth\(\)/.test(measureNative));
check('Harmony native type surface preserves the independent depth field',
  /baseline\?: number;[\s\S]*?depth\?: number;/.test(types));
check('Harmony block fit continues to use only original width and height fields',
  /fitOriginalMathMeasuredSizeToBox\(width, height, measured\.width, measured\.height\)/.test(harmonyEngine));
check('Harmony computes original integer horizontal and vertical center offsets',
  /const int drawX = renderWidth < width \? static_cast<int>\(width - renderWidth\) \/ 2 : 0;/.test(renderNative) &&
  /const int drawY = renderHeight < height \? static_cast<int>\(height - renderHeight\) \/ 2 : 0;/.test(renderNative));
check('Harmony never supplies negative centering offsets and draws with both offsets',
  /renderWidth < width \?[\s\S]*?: 0;/.test(renderNative) &&
  /renderHeight < height \?[\s\S]*?: 0;/.test(renderNative) &&
  /render->draw\(graphics, drawX, drawY\)/.test(renderNative));
check('Harmony validates drawing resources before calculating and using the offsets',
  renderNative.indexOf('if (!graphics.valid())') < renderNative.indexOf('const int drawX') &&
  renderNative.indexOf('const int drawX') < renderNative.indexOf('render->draw(graphics, drawX, drawY)'));

function originalCenter(blockWidth, blockHeight, renderWidth, renderHeight) {
  return {
    x: renderWidth < blockWidth ? Math.trunc(Math.trunc(blockWidth - renderWidth) / 2) : 0,
    y: renderHeight < blockHeight ? Math.trunc(Math.trunc(blockHeight - renderHeight) / 2) : 0,
  };
}

check('runtime model centers fractional blocks with original truncation semantics',
  assert.deepEqual(originalCenter(240.9, 120.9, 100, 20), { x: 70, y: 50 }) === undefined);
check('runtime model floors odd half-gaps and clamps oversized formulas to the origin',
  assert.deepEqual(originalCenter(241, 121, 100, 20), { x: 70, y: 50 }) === undefined &&
  assert.deepEqual(originalCenter(100, 20, 120, 30), { x: 0, y: 0 }) === undefined);

console.log(`TOTAL=${checks.length} FAILED=0`);
