import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const t0g = original('t0g.java');
const r93 = original('r93.java');
const evidence = read('docs/migration/evidence/original-math-raster-scale-jadx-2026-08-15.md');
const renderer = read('note/src/main/ets/rendering/MathCanvasRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const thumbnail = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const fixture = read('note/src/test/MathCanvasRenderer.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original ViewportState names t0g.a as zoom and t0g.f as density',
  /public final float a;/.test(t0g) && /public final r93 f;/.test(t0g) &&
  /ViewportState\(zoom=", this\.a/.test(t0g) && /sbQ\.append\(this\.f\)/.test(t0g));
check('original Density converts logical units by multiplying r93.a()',
  /default float j0\(float f\)[\s\S]*?return a\(\) \* f/.test(r93));
check('JADX fallback proves aeg passes viewport zoom and Density into ue4.v',
  /float r3 = r13\.a[\s\S]*?r93 r4 = r13\.f[\s\S]*?float r4 = r4\.a\(\)[\s\S]*?r0\.v\(r1, r2, r3, r4, r5, r6\)/
    .test(evidence));
check('JADX simple output proves original clamp, half-step quantization, and G handoff',
  /m18\.y0\(rh8\.u\(r20 \* r21, 1\.0f, 4\.0f\) \* 2\.0f\) \/ 2\.0f/.test(evidence) &&
  /r17\.P = r25[\s\S]*?r3\.G\(r111, r210, r211, r29, r212\)/.test(evidence));

check('Harmony narrows zoom and density to the original Float32 boundary before multiplying',
  /Math\.fround\(viewportZoom\)/.test(renderer) && /Math\.fround\(density\)/.test(renderer) &&
  /Math\.fround\(zoom \* pixelsPerVp\)/.test(renderer));
check('Harmony clamps to 1 through 4 and rounds to half steps',
  /physicalScale < MIN_RASTER_SCALE/.test(renderer) &&
  /physicalScale > MAX_RASTER_SCALE/.test(renderer) &&
  /Math\.round\(Math\.fround\(clampedScale \* RASTER_SCALE_STEPS_PER_UNIT\)\)/.test(renderer));
check('Math bitmap cache identity and native render both use the quantized dynamic scale',
  /renderMath\(element: MathElement, ctx: Canvas2DDrawingContext, rasterScale: number\)/.test(renderer) &&
  renderer.includes('`${element.color}\\u0000${pixelScale}`') &&
  /element\.blockHeight, element\.color, pixelScale/.test(renderer));
check('main canvas supplies current viewport zoom times current ArkUI Density',
  /originalMathRasterScale\(this\.viewport\.zoom, vp2px\(1\)\)/.test(canvas) &&
  /renderMath\(element\.data, renderContext, mathRasterScale\)/.test(canvas));
check('thumbnail supplies its real page-to-output transform without reapplying screen Density',
  /originalMathRasterScale\(pageTransform\.scale, 1\)/.test(thumbnail) &&
  /renderMath\(element\.data, renderContext, mathRasterScale\)/.test(thumbnail));
check('ArkTS fixture covers density, half-step thresholds, clamps, and invalid platform input',
  /originalMathRasterScale\(0\.5, 3\)/.test(fixture) &&
  /originalMathRasterScale\(1\.2499999, 1\)/.test(fixture) &&
  /Number\.POSITIVE_INFINITY/.test(fixture) &&
  /import mathCanvasRendererTest/.test(fixtureList) && /mathCanvasRendererTest\(\)/.test(fixtureList));

function rasterScale(viewportZoom, density) {
  const zoom = Math.fround(viewportZoom);
  const pixelsPerVp = Math.fround(density);
  if (!Number.isFinite(zoom) || !Number.isFinite(pixelsPerVp) || zoom <= 0 || pixelsPerVp <= 0) return 1;
  const physical = Math.fround(zoom * pixelsPerVp);
  const clamped = physical < 1 ? 1 : (physical > 4 ? 4 : physical);
  return Math.round(Math.fround(clamped * 2)) / 2;
}

check('runtime model keeps a 1x baseline', rasterScale(1, 1) === 1);
check('runtime model includes physical display density', rasterScale(0.5, 3) === 1.5 && rasterScale(1, 3) === 3);
check('runtime model preserves the original positive half-step boundary',
  rasterScale(1.2499999, 1) === 1 && rasterScale(1.25, 1) === 1.5 &&
  rasterScale(1, 2.74) === 2.5 && rasterScale(1, 2.75) === 3);
check('runtime model clamps high and low output scales', rasterScale(0.25, 1) === 1 && rasterScale(2, 3) === 4);
check('runtime model safely falls back for invalid Harmony platform input',
  rasterScale(Number.NaN, 3) === 1 && rasterScale(1, Number.POSITIVE_INFINITY) === 1);

console.log(`TOTAL=${checks.length} FAILED=0`);
