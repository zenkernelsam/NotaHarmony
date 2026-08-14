import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const target = original('com/gingerlabs/notability/core/glmath/MathDrawTarget.java');
const graphicsHeader = read('note/src/main/cpp/third_party/microtex/src/graphic/graphic.h');
const native = read('note/src/main/cpp/nota_math.cpp');
const graphicsStart = native.indexOf('class HarmonyGraphics');
const graphicsEnd = native.indexOf('\nbool ReadString(', graphicsStart);
const graphics = native.slice(graphicsStart, graphicsEnd);
const rotateStart = graphics.indexOf('void rotate(float angle, float px, float py)');
const resetStart = graphics.indexOf('\n    void reset()', rotateStart);
const rotate = graphics.slice(rotateStart, resetStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('MicroTeX declares Graphics2D rotation angles in radians',
  (graphicsHeader.match(/angle \(in radian\)/g) ?? []).length >= 2);
check('original MathDrawTarget forwards degrees directly to Android Canvas',
  /public final void rotate\(float degrees, float px, float py\)[\s\S]*?canvas\.rotate\(degrees, px, py\)/
    .test(target));
check('Harmony promotes the Float32 radian input to double before division',
  /const double degrees = static_cast<double>\(angle\) \/ M_PI \* 180\.0;/.test(rotate));
check('Harmony follows the original divide-then-multiply order',
  rotate.indexOf('/ M_PI') < rotate.indexOf('* 180.0'));
check('Harmony narrows exactly once at the Native Drawing degree boundary',
  /OH_Drawing_CanvasRotate\(canvas_, static_cast<float>\(degrees\), px, py\)/.test(rotate) &&
  (rotate.match(/static_cast<float>/g) ?? []).length === 1);
check('Harmony no longer multiplies and divides the angle as Float32',
  !/angle \* 180\.0f/.test(rotate) && !/static_cast<float>\(M_PI\)/.test(rotate));
check('zero-pivot rotation still delegates to the same precise overload',
  /void rotate\(float angle\) override \{ rotate\(angle, 0, 0\); \}/.test(graphics));

function originalDegrees(angle) {
  return Math.fround(Math.fround(angle) / Math.PI * 180);
}

function floatFirstDegrees(angle) {
  const value = Math.fround(angle);
  return Math.fround(Math.fround(value * Math.fround(180)) / Math.fround(Math.PI));
}

check('runtime model reproduces the original one-radian Float32 result',
  originalDegrees(1) === 57.295780181884766);
check('runtime model proves the former float-first path differs by one ULP at one radian',
  floatFirstDegrees(1) === 57.2957763671875 &&
  originalDegrees(1) !== floatFirstDegrees(1));
check('runtime model preserves the original result for positive and negative arbitrary angles',
  originalDegrees(3) === 171.88734436035156 &&
  originalDegrees(-3) === -171.88734436035156);
check('canonical quarter and half turns remain exact after the precision fix',
  originalDegrees(Math.PI / 2) === 90 && originalDegrees(Math.PI) === 180);

console.log(`TOTAL=${checks.length} FAILED=0`);
