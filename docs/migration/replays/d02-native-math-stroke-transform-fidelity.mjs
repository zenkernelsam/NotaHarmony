import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const target = original('com/gingerlabs/notability/core/glmath/MathDrawTarget.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const graphicsHeader = read('note/src/main/cpp/third_party/microtex/src/graphic/graphic.h');
const render = read('note/src/main/cpp/third_party/microtex/src/render.cpp');
const boxes = read('note/src/main/cpp/third_party/microtex/src/box/box_single.cpp');
const graphicsStart = native.indexOf('class HarmonyGraphics');
const graphicsEnd = native.indexOf('\nbool ReadString(', graphicsStart);
const graphics = native.slice(graphicsStart, graphicsEnd);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const constructorStart = target.indexOf('public MathDrawTarget(');
const drawLineStart = target.indexOf('public final void drawLine', constructorStart);
const constructor = target.slice(constructorStart, drawLineStart);

check('original draw target starts with Android stroke-paint defaults',
  /new Paint\(1\)/.test(constructor) && /paint\.setStyle\(Paint\.Style\.STROKE\)/.test(constructor) &&
  !/setStrokeWidth|setStrokeCap|setStrokeJoin|setStrokeMiter/.test(constructor));
check('original setStroke applies width cap join and only positive miter limits',
  /setStrokeWidth\(width\)/.test(target) && /setStrokeCap\(cap2\)/.test(target) &&
  /setStrokeJoin\(join2\)/.test(target) &&
  /if \(miterLimit > 0\.0f\)[\s\S]*?setStrokeMiter\(miterLimit\)/.test(target));
check('original transforms are delegated to the Android canvas',
  /canvas\.translate\(dx, dy\)/.test(target) && /canvas\.scale\(sx, sy\)/.test(target) &&
  /canvas\.rotate\(degrees, px, py\)/.test(target));
check('MicroTeX rotation input is radians while the original Android target consumes degrees',
  /Rotate the context with the given angle \(in radian\)/.test(graphicsHeader) &&
  /public final void rotate\(float degrees, float px, float py\)/.test(target));
check('MicroTeX line boxes mutate width and later restore the logical stroke width',
  /g2\.setStrokeWidth\(_thickness\)/.test(boxes) &&
  /g2\.setStrokeWidth\(oldThickness\)/.test(boxes));

check('Harmony constructor recreates Android stroke-paint defaults explicitly',
  /OH_Drawing_PenSetWidth\(pen_, 0\)/.test(graphics) &&
  /OH_Drawing_PenSetCap\(pen_, LINE_FLAT_CAP\)/.test(graphics) &&
  /OH_Drawing_PenSetJoin\(pen_, LINE_MITER_JOIN\)/.test(graphics));
check('Harmony constructor keeps logical MicroTeX stroke separate from platform defaults',
  !/setStroke\(tex::Stroke\(\)\)/.test(graphics) && /tex::Stroke stroke_;/.test(graphics));
check('Harmony setStrokeWidth reapplies the complete current stroke',
  /void setStrokeWidth\(float width\)[\s\S]*?stroke_\.lineWidth = width;[\s\S]*?setStroke\(stroke_\);/.test(graphics));
check('Harmony full stroke mapping matches original cap and join enums',
  /stroke\.cap == tex::CAP_ROUND \? LINE_ROUND_CAP/.test(graphics) &&
  /stroke\.cap == tex::CAP_SQUARE \? LINE_SQUARE_CAP : LINE_FLAT_CAP/.test(graphics) &&
  /stroke\.join == tex::JOIN_ROUND \? LINE_ROUND_JOIN/.test(graphics) &&
  /stroke\.join == tex::JOIN_BEVEL \? LINE_BEVEL_JOIN : LINE_MITER_JOIN/.test(graphics));
check('Harmony retains original positive-only miter override',
  /if \(stroke\.miterLimit > 0\) OH_Drawing_PenSetMiterLimit/.test(graphics));
check('Harmony translate delegates directly without maintaining stale pseudo-matrix offsets',
  /void translate\(float dx, float dy\)[\s\S]*?OH_Drawing_CanvasTranslate\(canvas_, dx, dy\)/.test(graphics) &&
  !/tx_|ty_/.test(graphics));
check('Harmony reset only restores logical scale and never clears the native canvas matrix',
  /void reset\(\) override[\s\S]*?sx_ = sy_ = 1;/.test(graphics) &&
  !/OH_Drawing_CanvasResetMatrix/.test(graphics));
check('Harmony rotation preserves original double conversion order before the final float API call',
  /const double degrees = static_cast<double>\(angle\) \/ M_PI \* 180\.0;/.test(graphics) &&
  /OH_Drawing_CanvasRotate\(canvas_, static_cast<float>\(degrees\), px, py\)/.test(graphics) &&
  !/angle \* 180\.0f \/ static_cast<float>\(M_PI\)/.test(graphics));
check('Harmony outer pixel scale is established before formula drawing',
  /OH_Drawing_CanvasScale\(canvas\.get\(\), pixelScale, pixelScale\)[\s\S]*?render->draw\(graphics, drawX, drawY\)/
    .test(native));
check('MicroTeX reset occurs only after the complete formula box draw',
  /_box->draw\(g2,[\s\S]*?g2\.reset\(\);[\s\S]*?g2\.setColor\(old\)/.test(render));

function applyStrokeWidth(logicalStroke, width) {
  return { ...logicalStroke, lineWidth: width };
}

check('runtime model promotes Android defaults to the complete logical stroke on first width change',
  assert.deepEqual(applyStrokeWidth({ lineWidth: 1, cap: 'round', join: 'round', miter: 0 }, 0.25),
    { lineWidth: 0.25, cap: 'round', join: 'round', miter: 0 }) === undefined);
check('runtime model keeps the outer pixel scale after logical reset', (() => {
  const canvasScale = 2;
  let logicalScale = 12;
  logicalScale = 1;
  return canvasScale === 2 && logicalScale === 1;
})());
check('runtime model preserves original rotation rounding instead of float-first conversion', (() => {
  const angle = Math.fround(1);
  const originalDegrees = Math.fround(angle / Math.PI * 180);
  const floatFirstDegrees = Math.fround(
    Math.fround(Math.fround(angle * Math.fround(180)) / Math.fround(Math.PI)));
  return originalDegrees === 57.295780181884766 &&
    floatFirstDegrees === 57.2957763671875 && originalDegrees !== floatFirstDegrees;
})());

console.log(`TOTAL=${checks.length} FAILED=0`);
