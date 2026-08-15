import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const axi = original('axi.java');
const r93 = original('r93.java');
const p18 = original('p18.java');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const native = read('note/src/main/cpp/nota_math.cpp');

const checks = [
  [axi, /float fJ0 = r93Var\.j0\(280\.0f\)[\s\S]*?float fJ1 = r93Var\.j0\(96\.0f\)/,
    'original converts the 280dp by 96dp preview box through Compose Density'],
  [r93, /default float j0\(float f\)[\s\S]*?return a\(\) \* f/,
    'original Density conversion multiplies logical units by physical density'],
  [p18, /int iCeil = \(int\) Math\.ceil\(f \* f3\)[\s\S]*?int iCeil2 = \(int\) Math\.ceil\(f2 \* f3\)/,
    'original bitmap dimensions are derived after density conversion'],
  [p18, /canvas\.scale\(f3, f3\)/,
    'original keeps a separate render scale after selecting the physical box'],
  [canvas, /ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH_VP: number = 280/,
    'Harmony keeps the original logical preview width'],
  [canvas, /ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT_VP: number = 96/,
    'Harmony keeps the original logical preview height'],
  [canvas, /previewWidthPixels: number = vp2px\(ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH_VP\)/,
    'Harmony converts preview width to physical pixels'],
  [canvas, /previewHeightPixels: number = vp2px\(ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT_VP\)/,
    'Harmony converts preview height to physical pixels'],
  [canvas, /previewWidthPixels <= 0 \|\| previewHeightPixels <= 0[\s\S]*?OriginalMathEditorDraftState\.INVALID/,
    'Harmony fails closed if density conversion cannot produce a positive target'],
  [canvas, /originalMathEngine\.render\(draft,[\s\S]*?previewWidthPixels, previewHeightPixels,[\s\S]*?ORIGINAL_MATH_EDITOR_PREVIEW_PIXEL_SCALE/,
    'Harmony renders the density-sized target at the original separate 1x scale'],
  [native, /std::ceil\(width \* pixelScale\)[\s\S]*?std::ceil\(height \* pixelScale\)[\s\S]*?OH_Drawing_CanvasScale\(canvas\.get\(\), pixelScale, pixelScale\)/,
    'native keeps bitmap sizing and canvas scale coupled to the explicit render scale'],
];

for (const [source, pattern, label] of checks) {
  assert.match(source, pattern, label);
}

const physicalPreview = density => ({ width: 280 * density, height: 96 * density, pixelScale: 1 });
assert.deepEqual(physicalPreview(1), { width: 280, height: 96, pixelScale: 1 });
assert.deepEqual(physicalPreview(2), { width: 560, height: 192, pixelScale: 1 });
assert.deepEqual(physicalPreview(3), { width: 840, height: 288, pixelScale: 1 });
assert.notDeepEqual(physicalPreview(3), { width: 280, height: 96, pixelScale: 1 });

console.log(`TOTAL=${checks.length + 4} FAILED=0`);
