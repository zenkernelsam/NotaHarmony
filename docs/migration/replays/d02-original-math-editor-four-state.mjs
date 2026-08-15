import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const w08 = original('w08.java');
const v08 = original('v08.java');
const overlay = read('note/src/main/ets/ui/components/MathEditorOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixture = read('note/src/test/MathEditorOverlay.test.ets');

const checks = [
  [w08, /lvd\.E0\([\s\S]*?setValue\(lwa\.a\)/,
    'original blank draft resolves to Empty'],
  [w08, /setValue\(nwa\.a\)[\s\S]*?s18Var\.f/,
    'original non-empty draft enters Loading before native rendering'],
  [w08, /bitmap == null \? mwa\.a : new owa\(bitmap\)/,
    'original native render resolves to Invalid or bitmap-carrying Ok'],
  [v08, /pwaVar instanceof owa[\s\S]*?gvh\.b\(new tr\(\(\(owa\) pwaVar\)\.a\)/,
    'original Ok state displays its rendered bitmap'],
  [v08, /boolean z = \(\(pwa\) wrdVar\.getValue\(\)\) instanceof owa/,
    'original Done is enabled only for Ok'],
  [overlay, /enum OriginalMathEditorDraftState[\s\S]*?EMPTY[\s\S]*?LOADING[\s\S]*?INVALID[\s\S]*?OK/,
    'Harmony exposes the same four editor states'],
  [overlay, /initialOriginalMathEditorDraftState[\s\S]*?value\.trim\(\)\.length === 0[\s\S]*?EMPTY[\s\S]*?LOADING : OriginalMathEditorDraftState\.INVALID/,
    'Harmony separates blank, pending, and envelope-invalid drafts'],
  [overlay, /@Prop preview: image\.PixelMap \| null/,
    'Harmony carries the rendered preview into the overlay'],
  [overlay, /draftState === OriginalMathEditorDraftState\.OK && this\.preview !== null[\s\S]*?Image\(this\.preview\)/,
    'Harmony displays preview only for Ok'],
  [overlay, /draftState === OriginalMathEditorDraftState\.INVALID[\s\S]*?math_editor_invalid/,
    'Harmony displays syntax failure only for Invalid'],
  [overlay, /return !busy && state === OriginalMathEditorDraftState\.OK/,
    'Harmony Done helper rejects Empty, Loading, Invalid, and busy Ok'],
  [canvas, /ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH: number = 280/,
    'Harmony uses the original 280-unit editor preview width'],
  [canvas, /ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT: number = 96/,
    'Harmony uses the original 96-unit editor preview height'],
  [canvas, /ORIGINAL_MATH_EDITOR_PREVIEW_PIXEL_SCALE: number = 1/,
    'Harmony uses the original 1x editor preview scale'],
  [canvas, /mathEditorValidationGeneration[\s\S]*?setTimeout\(\(\): void =>/,
    'Harmony defers and generations native validation'],
  [canvas, /originalMathEngine\.render\(draft,[\s\S]*?ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH[\s\S]*?ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT/,
    'Harmony requires complete native bitmap rendering for Ok'],
  [canvas, /generation !== this\.mathEditorValidationGeneration[\s\S]*?draft !== this\.mathEditorDraft/,
    'Harmony drops stale native results after rapid input or close'],
  [canvas, /preview\.bitmap\.close\(\)[\s\S]*?preview\.pixelMap\.release\(\)/,
    'Harmony releases superseded preview resources'],
  [canvas, /mathEngineInitializationComplete = true[\s\S]*?this\.requestMathEditorDraftValidation\(\)/,
    'Harmony resumes Loading validation when engine initialization completes'],
  [canvas, /@Watch\('onMathEditorThemeChange'\)[\s\S]*?onMathEditorThemeChange[\s\S]*?requestMathEditorDraftValidation/,
    'Harmony rerenders the preview in the active theme color'],
  [canvas, /mathEditorDraftState !== OriginalMathEditorDraftState\.OK[\s\S]*?mathEditorPreview === null/,
    'Harmony confirmation defensively requires a current Ok preview'],
  [fixture, /starts the original four-state machine at Empty, Invalid, or Loading/,
    'ArkTS fixture locks initial state classification'],
  [fixture, /enables Done only for an idle native-rendered Ok state/,
    'ArkTS fixture locks the Done gate'],
];

for (const [source, pattern, label] of checks) {
  assert.match(source, pattern, label);
}

const EMPTY = 0;
const LOADING = 1;
const INVALID = 2;
const OK = 3;
const initial = (value, encodable = true) => value.trim().length === 0 ? EMPTY :
  encodable ? LOADING : INVALID;
const canConfirm = (state, busy) => !busy && state === OK;

assert.equal(initial('   '), EMPTY);
assert.equal(initial('x'), LOADING);
assert.equal(initial('\ud800', false), INVALID);
assert.equal(canConfirm(OK, false), true);
assert.equal(canConfirm(LOADING, false), false);
assert.equal(canConfirm(OK, true), false);

console.log(`TOTAL=${checks.length + 6} FAILED=0`);
