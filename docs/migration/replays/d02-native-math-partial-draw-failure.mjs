import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const originalNative = original('com/gingerlabs/notability/core/glmath/GLMathNative.java');
const originalDraw = original('defpackage/p18.java');
const originalTarget = original('com/gingerlabs/notability/core/glmath/MathDrawTarget.java');
const native = read('note/src/main/cpp/nota_math.cpp');
const graphicsStart = native.indexOf('class HarmonyGraphics');
const readStringStart = native.indexOf('\nbool ReadString(', graphicsStart);
const graphics = native.slice(graphicsStart, readStringStart);
const renderStart = native.indexOf('napi_value Render(');
const cleanupStart = native.indexOf('\nvoid Cleanup(', renderStart);
const render = native.slice(renderStart, cleanupStart);

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original nativeDraw exposes one boolean for the complete drawing operation',
  /native boolean nativeDraw\(String latex, float width, float height, float fontSize, int argbColor,/.test(originalNative));
check('original caller discards the complete bitmap when native drawing returns false',
  /if \(GLMathNative\.a\.nativeDraw[\s\S]*?return bitmapCreateBitmap;[\s\S]*?bitmapCreateBitmap\.recycle\(\)/
    .test(originalDraw));
check('original draw target leaves callback failures to the nativeDraw boundary',
  /this\.canvas\.drawText\(text, x, y, this\.textPaint\)/.test(originalTarget) &&
  /this\.canvas\.drawRoundRect/.test(originalTarget) &&
  !/try \{|catch \(/.test(originalTarget));

check('Harmony graphics records sticky drawing failure state',
  /bool failed\(\) const \{ return failed_; \}/.test(graphics) &&
  /bool failed_ = false;/.test(graphics));
check('empty text remains an intentional no-op rather than a false allocation failure',
  /void drawText[\s\S]*?if \(text\.empty\(\)\) return;/.test(graphics));
check('missing text drawing resources mark the complete render as failed',
  /font == nullptr \|\| font->native\(\) == nullptr\) \{[\s\S]*?failed_ = true;[\s\S]*?return;/.test(graphics));
check('TextBlob allocation failure is sticky instead of silently dropping glyphs',
  /OH_Drawing_TextBlobCreateFromText[\s\S]*?if \(blob == nullptr\) \{[\s\S]*?failed_ = true;[\s\S]*?return;/.test(graphics));
check('line drawing resource loss marks the complete render as failed',
  /void drawLine[\s\S]*?if \(canvas_ == nullptr \|\| pen_ == nullptr\) \{[\s\S]*?failed_ = true;/.test(graphics));
check('both rectangle allocation paths mark sticky failure',
  (graphics.match(/if \(rect == nullptr\) \{[\s\S]*?failed_ = true;[\s\S]*?return;/g) ?? []).length >= 2);
check('round-rectangle allocation failure marks sticky failure and releases its Rect',
  /if \(round == nullptr\) \{[\s\S]*?failed_ = true;[\s\S]*?OH_Drawing_RectDestroy\(rect\);[\s\S]*?return;/.test(graphics));

check('render checks sticky graphics failure immediately after the complete formula draw',
  /render->draw\(graphics, drawX, drawY\);[\s\S]*?if \(graphics\.failed\(\)\) return ErrorResult\(env, "formula drawing failed"\);/.test(render));
check('partial pixels are rejected before ArrayBuffer allocation or pixel export',
  render.indexOf('if (graphics.failed())') < render.indexOf('napi_create_arraybuffer') &&
  render.indexOf('if (graphics.failed())') < render.indexOf('OH_Drawing_BitmapReadPixels'));
check('partial drawing failure still exits through scoped graphics canvas and bitmap owners',
  render.indexOf('BitmapHandle bitmap(') < render.indexOf('CanvasHandle canvas(') &&
  render.indexOf('CanvasHandle canvas(') < render.indexOf('HarmonyGraphics graphics(') &&
  render.indexOf('HarmonyGraphics graphics(') < render.indexOf('if (graphics.failed())'));

function drawFormula(operations) {
  let failed = false;
  const draw = operation => {
    if (!operation()) failed = true;
  };
  for (const operation of operations) draw(operation);
  return failed ? null : 'complete-bitmap';
}

check('runtime model rejects a bitmap when any middle drawing primitive fails',
  drawFormula([() => true, () => false, () => true]) === null);
check('runtime model returns a bitmap only when every primitive succeeds',
  drawFormula([() => true, () => true, () => true]) === 'complete-bitmap');

console.log(`TOTAL=${checks.length} FAILED=0`);
