import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const s18 = original('s18.java');
const p18 = original('p18.java');
const g18 = original('g18.java');
const layout = read('note/src/main/ets/core/model/OriginalMathInsertPlan.ets');
const engine = read('note/src/main/ets/rendering/OriginalMathEngine.ets');
const renderer = read('note/src/main/ets/rendering/MathCanvasRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixture = read('note/src/test/OriginalMathInsertPlan.test.ets');

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original measures with max floored box dimension and proportionally fits both axes',
  /Math\.floor\(f\)/.test(s18) && /Math\.floor\(f2\)/.test(s18) &&
  /Math\.max\(fFloor, fFloor2\)/.test(s18) &&
  /nativeMeasure\(str, f, fMax\)/.test(s18) &&
  /Math\.min\(fFloor \/ f3, fFloor2 \/ f4\)/.test(s18));
check('original floors the fitted font and ceils both fitted dimensions',
  /new q18\(\(float\) Math\.floor\(fMax \* fMin\), \(float\) Math\.ceil\(f3 \* fMin\), \(float\) Math\.ceil\(f4 \* fMin\)\)/
    .test(s18));
check('original renders a full block bitmap with the fitted font size',
  /Math\.ceil\(f \* f3\)/.test(p18) && /Math\.ceil\(f2 \* f3\)/.test(p18) &&
  /nativeDraw\(str, f, f2, q18VarD\.a/.test(p18));
check('original insert fits into 240x120 and stores the returned fitted dimensions',
  /new SizeF\(240\.0f, 120\.0f\)/.test(g18) &&
  /new vc\(\(Object\) s18Var, str3, \(Object\) U, 27\)/.test(g18) &&
  /apb\.h\(sizeF\.getWidth\(\), sizeF\.getHeight\(\)\)/.test(g18));

const editStart = g18.indexOf('public static final java.lang.Object i');
const insertStart = g18.indexOf('public static final Object j');
const editMethod = g18.slice(editStart, insertStart);
check('original latex edit writes only the latex register and does not remeasure block geometry',
  /dhh\.a\(r4\)/.test(editMethod) && /u5j\.o\(/.test(editMethod) &&
  !/s18\.d|SizeF|nativeMeasure/.test(editMethod));

check('Harmony pure layout helper mirrors the original Float floor max min floor ceil algorithm',
  /Math\.fround\(boxWidth\)/.test(layout) && /Math\.fround\(boxHeight\)/.test(layout) &&
  /Math\.fround\(Math\.max\(width, height\)\)/.test(layout) &&
  /Math\.fround\(widthLimit \/ originalMeasuredWidth\)/.test(layout) &&
  /Math\.fround\(heightLimit \/ originalMeasuredHeight\)/.test(layout) &&
  /Math\.floor\(Math\.fround\(measurementFontSize \* scale\)\)/.test(layout) &&
  (layout.match(/Math\.ceil\(Math\.fround\(originalMeasured(?:Width|Height) \* scale\)\)/g) ?? []).length === 2);
check('Harmony engine measures first and renders with the fitted font',
  /const measured: MathMeasureResult = this\.measure\(latex, width, measurementFontSize\)/.test(engine) &&
  /fitOriginalMathMeasuredSizeToBox\(width, height, measured\.width, measured\.height\)/.test(engine) &&
  /latex, width, height, fitted\.fontSize, argbColor, pixelScale/.test(engine));
check('Harmony renderer no longer hard-codes a 20px formula font',
  !/DEFAULT_MATH_FONT_SIZE/.test(renderer) &&
  /element\.blockHeight, element\.color, PIXEL_SCALE/.test(renderer));

const editUiStart = canvas.indexOf('private async confirmMathEditing');
const insertUiStart = canvas.indexOf('private async confirmMathInsert');
const editUi = canvas.slice(editUiStart, insertUiStart);
const insertUi = canvas.slice(insertUiStart, canvas.indexOf('private ', insertUiStart + 20));
check('Harmony edit validates layout but preserves the original block geometry',
  /originalMathEngine\.fit\(draft, before\.blockWidth, before\.blockHeight\)/.test(editUi) &&
  /after\.latex = draft/.test(editUi) &&
  !/after\.blockWidth|after\.blockHeight|after\.bounds/.test(editUi));
check('Harmony insert uses the original 240x120 fit before creating the block',
  /originalMathEngine\.fit\(this\.mathEditorDraft,[\s\S]*ORIGINAL_MATH_INSERT_MAX_WIDTH,[\s\S]*ORIGINAL_MATH_INSERT_MAX_HEIGHT\)/
    .test(insertUi) && /fitted\.width, fitted\.height/.test(insertUi));
check('latex-only persistence still rejects any geometry mutation',
  /candidate\.latex = after\.latex/.test(persistence) &&
  /encodePersistedElement\(\{ kind: 'math', data: candidate \}\)/.test(persistence));
check('ArkTS fixture locks down fitted font, downscale, and upscale behavior',
  /fitted\?\.fontSize/.test(fixture) && /enlarged\?\.fontSize/.test(fixture));

function fit(boxWidth, boxHeight, measuredWidth, measuredHeight) {
  const originalWidth = Math.fround(boxWidth);
  const originalHeight = Math.fround(boxHeight);
  const originalMeasuredWidth = Math.fround(measuredWidth);
  const originalMeasuredHeight = Math.fround(measuredHeight);
  const widthLimit = Math.fround(Math.floor(originalWidth));
  const heightLimit = Math.fround(Math.floor(originalHeight));
  const measurementFontSize = Math.fround(Math.max(widthLimit, heightLimit));
  if (![widthLimit, heightLimit, originalMeasuredWidth, originalMeasuredHeight].every(Number.isFinite) ||
      widthLimit <= 0 || heightLimit <= 0 || originalMeasuredWidth <= 0 || originalMeasuredHeight <= 0) return null;
  const scale = Math.fround(Math.min(
    Math.fround(widthLimit / originalMeasuredWidth),
    Math.fround(heightLimit / originalMeasuredHeight)));
  const fontSize = Math.floor(Math.fround(measurementFontSize * scale));
  const width = Math.max(1, Math.ceil(Math.fround(originalMeasuredWidth * scale)));
  const height = Math.max(1, Math.ceil(Math.fround(originalMeasuredHeight * scale)));
  return fontSize > 0 && width <= widthLimit + 1 && height <= heightLimit + 1
    ? { fontSize, width, height } : null;
}

check('runtime model downscales a wide formula exactly like s18.d',
  assert.deepEqual(fit(240, 120, 480, 60), { fontSize: 120, width: 240, height: 30 }) === undefined);
check('runtime model enlarges a small formula to fill its limiting axis',
  assert.deepEqual(fit(240, 120, 40, 80), { fontSize: 360, width: 60, height: 120 }) === undefined);
check('runtime model floors box dimensions before fitting',
  assert.deepEqual(fit(240.9, 120.9, 480, 60), { fontSize: 120, width: 240, height: 30 }) === undefined);
check('runtime model preserves an exact limiting axis after Float32 division and multiplication',
  assert.deepEqual(fit(27, 55, 126, 319), { fontSize: 9, width: 22, height: 55 }) === undefined);
check('runtime model preserves the original one-pixel Float32 ceil overshoot',
  assert.deepEqual(fit(240, 81, 852, 133), { fontSize: 67, width: 241, height: 38 }) === undefined);
check('runtime model rejects unusable measurements', fit(240, 120, 0, 40) === null);

console.log(`TOTAL=${checks.length} FAILED=0`);
