import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = value => fs.readFileSync(new URL('../../../' + value, import.meta.url), 'utf8');
const originalToolbar = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/dhb.java', 'utf8');
const originalInk = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/y31.java', 'utf8');
const brush = read('note/src/main/ets/core/model/BrushTypes.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');

assert.match(originalInk, /new y31\("Mono", 0\)/);
assert.match(originalInk, /new y31\("Taper", 1\)/);
assert.match(originalInk, /new y31\("Dash", 2\)/);
assert.match(originalInk, /new y31\("Dot", 3\)/);
assert.match(originalToolbar, /iOrdinal = t16VarW\.ordinal\(\)/);
assert.match(originalToolbar, /y31Var = y31\.J/);
assert.match(originalToolbar, /y31Var = y31\.I/);
assert.match(originalToolbar, /y31Var = y31\.K/);
assert.match(originalToolbar, /y31Var = y31\.L/);

assert.match(brush, /export function inkStyleToBrushStyle\(style: InkStyle\): BrushStyle/);
assert.match(brush, /case InkStyle\.VARIABLE_WIDTH: return BrushStyle\.TAPER;/);
assert.match(brush, /case InkStyle\.DASH: return BrushStyle\.DASH;/);
assert.match(brush, /case InkStyle\.DOTS: return BrushStyle\.DOT;/);

assert.match(canvas, /onSelectionInkControlsChanged[\s\S]{0,260}style: InkStyle \| null\)/);
assert.match(canvas, /this\.selectionTool\.deselect\(\);[\s\S]{0,80}onSelectionInkControlsChanged\(null, null, 0\.5, 30, true, null\);/);
assert.match(canvas,
  /private clearSelectionWithRegisterReset\(\): void \{[\s\S]{0,220}onSelectionInkControlsChanged\(null, null, 0\.5, 30, true, null\);/);
assert.match(canvas, /selectedMathIds\.length === 0 && state\.selectedGroupIds\.length === 0\) \{[\s\S]{0,100}selectionVisible = false/);
assert.match(canvas, /private startMathEditing\(\): void \{[\s\S]{0,900}selectionVisible = false;/);
assert.match(canvas, /private startImageCrop\(\): void \{[\s\S]{0,1000}selectionVisible = false;/);
for (const restoreContext of [
  'detachMathEditorForNavigation',
  'cancelMathEditing',
]) {
  const index = canvas.indexOf(restoreContext);
  assert.ok(index >= 0, `missing temporary editor context ${restoreContext}`);
  const body = canvas.slice(index);
  const refreshIndex = body.indexOf('this.updateSelectionOverlay();');
  assert.ok(refreshIndex >= 0, `missing overlay refresh after ${restoreContext}`);
  assert.ok(body.slice(refreshIndex).includes('this.selectionVisible = true;'),
    `missing visibility rebind after ${restoreContext}`);
}
const confirmMathIndex = canvas.indexOf('this.mathBlocks = proposedMath;');
assert.ok(confirmMathIndex >= 0, 'missing Math edit projection');
const confirmMathBody = canvas.slice(confirmMathIndex);
assert.ok(confirmMathBody.includes('this.updateSelectionOverlay();'),
  'missing overlay refresh after Math edit');
assert.ok(confirmMathBody.indexOf('this.selectionVisible = true;') <
  confirmMathBody.indexOf('this.renderFrame();'),
  'Math edit must rebind visibility before render');

function restoreOverlayAfterTemporaryEditor(state) {
  state.selectionVisible = false;
  state.selectionRect = { left: 1, top: 1, right: 2, bottom: 2 };
  if (state.selectedIds.length > 0) {
    state.overlayRefreshes += 1;
    state.selectionVisible = true;
  }
}
{
  const restored = { selectedIds: ['math-1'], selectionVisible: false,
    selectionRect: { left: 0, top: 0, right: 0, bottom: 0 }, overlayRefreshes: 0 };
  restoreOverlayAfterTemporaryEditor(restored);
  assert.equal(restored.overlayRefreshes, 1);
  assert.equal(restored.selectionVisible, true);
  assert.deepEqual(restored.selectionRect, { left: 1, top: 1, right: 2, bottom: 2 });
}
{
  const authoritativeExit = { selectedIds: [], selectionVisible: true,
    selectionRect: { left: 3, top: 3, right: 4, bottom: 4 }, overlayRefreshes: 0 };
  restoreOverlayAfterTemporaryEditor(authoritativeExit);
  assert.equal(authoritativeExit.overlayRefreshes, 0);
  assert.equal(authoritativeExit.selectionVisible, false);
}
assert.equal([...canvas.matchAll(/this\.onSelectionInkControlsChanged\(null, null, 0\.5, 30, true, null\);/g)].length >= 11, true);
for (const context of [
  'finalImages.map',
  'result.math.id',
  'created.id',
  'cancelImageCrop',
  'confirmImageCrop',
  'pasteClipboard',
]) {
  const index = canvas.indexOf(context);
  assert.ok(index >= 0, `missing selection-replacement context ${context}`);
  assert.ok(canvas.slice(index).includes('onSelectionInkControlsChanged(null, null, 0.5, 30, true, null)'),
    `missing reset after ${context}`);
}
for (const context of [
  'enterLoadFailureState',
  'cancelActiveInteraction',
  'commitOriginalPartialErase',
  'applyOriginalGroupHistoryMove',
  'applyOriginalClipboardPasteHistoryMove',
  'applyOriginalPartialEraseHistoryMove',
  'applyOriginalHandwritingConversionHistoryMove',
  'applyAction',
  'SelectionMenuAction.DESELECT',
  'startMathInsert',
]) {
  const index = canvas.indexOf(context);
  assert.ok(index >= 0, `missing exit context ${context}`);
  assert.ok(canvas.slice(index).includes('clearSelectionWithRegisterReset()'),
    `missing reset after ${context}`);
}
for (const cropRestoreContext of [
  'cancelImageCrop',
  'confirmImageCrop',
]) {
  const index = canvas.indexOf(cropRestoreContext);
  assert.ok(index >= 0, `missing crop restore context ${cropRestoreContext}`);
  const body = canvas.slice(index);
  assert.equal((body.match(/this\.updateSelectionOverlay\(\);/g) || []).length >= 2, true,
    `crop ${cropRestoreContext} lacks empty and non-empty paths`);
  assert.equal((body.match(/this\.selectionVisible = true;/g) || []).length >= 2, true,
    `crop ${cropRestoreContext} lacks visibility rebinds`);
}
assert.match(canvas, /let selectedStyle: InkStyle \| null = null;/);
assert.match(canvas, /selectedStrokeIds\.has\(stroke\.id\) \|\|[\s\S]{0,80}isPartialEraser === true/);
assert.match(canvas, /selectedStyle = stroke\.renderSpec\.inkStyle;[\s\S]{0,30}break;/);
assert.match(canvas, /variableStyleEnabled, selectedStyle\);/);

assert.match(page, /selectionStyle: inkStyleToBrushStyle\(this\.selectionInkStyle\)/);
assert.match(page, /onSelectionInkControlsChanged:[\s\S]{0,220}style: InkStyle \| null\)/);
assert.match(page, /if \(color !== null\) {[\s\S]{0,60}this\.selectionInkColor = color;[\s\S]{0,180}if \(style !== null\) {[\s\S]{0,50}this\.selectionInkStyle = style;/);

assert.match(toolbar, /@Prop selectionStyle: BrushStyle = BrushStyle\.MONO;/);
assert.match(toolbar, /\.backgroundColor\(this\.selectionStyle === style \? this\.resolveTokens\(\)\.accent :/);
assert.match(toolbar, /\.fontColor\(this\.selectionStyle === style \? this\.resolveTokens\(\)\.onAccent :/);
assert.match(toolbar, /\(style !== BrushStyle\.TAPER \|\| this\.selectionVariableStyleEnabled\)/);

function selectionContext(strokes) {
  let selectedColor = null;
  let selectedWidth = null;
  let variableStyleEnabled = true;
  let selectedStyle = null;
  for (const stroke of strokes) {
    if (!stroke.selected || stroke.isPartialEraser) continue;
    if (selectedColor === null) selectedColor = stroke.color;
    if (selectedWidth === null) selectedWidth = stroke.width;
    if (variableStyleEnabled && stroke.isPencil) variableStyleEnabled = false;
  }
  for (const stroke of strokes) {
    if (!stroke.selected || stroke.isPartialEraser) continue;
    selectedStyle = stroke.style;
    break;
  }
  return { color: selectedColor, width: selectedWidth,
    variableStyleEnabled, style: selectedStyle };
}

const mixed = selectionContext([
  { id: 'fixed', selected: true, isPartialEraser: false, isPencil: false, style: 'FIXED', color: 1, width: 3 },
  { id: 'pencil', selected: true, isPartialEraser: false, isPencil: true, style: 'FIXED', color: 4, width: 2 },
  { id: 'taper', selected: true, isPartialEraser: false, isPencil: false, style: 'TAPER', color: 2, width: 5 },
]);
assert.equal(mixed.color, 1);
assert.equal(mixed.width, 3);
assert.equal(mixed.variableStyleEnabled, false);
assert.equal(mixed.style, 'FIXED');

const partialOnly = selectionContext([
  { id: 'partial', selected: true, isPartialEraser: true, isPencil: false, style: 'DASH', color: 9, width: 9 },
]);
assert.deepEqual(partialOnly, { color: null, width: null, variableStyleEnabled: true, style: null });

let published = null;
const pageState = {
  selectionInkStyle: 'FIXED', selectionInkColor: 9, selectionInkWidth: 11,
};
function onSelectionInkControlsChanged(_color, _width, _minimum, _maximum,
  variableStyleEnabled, style, reset = false) {
  pageState.selectionInkStyle = style;
  if (reset) {
    pageState.selectionInkColor = -16777216;
    pageState.selectionInkWidth = 5;
    pageState.selectionVariableStyleEnabled = true;
  }
}
published = selectionContext([{ id: 'dash', selected: true, isPartialEraser: false,
  isPencil: false, style: 'DASH', color: 4, width: 2 }]);
onSelectionInkControlsChanged(published.color ?? -16777216, published.width ?? 5,
  0.5, 30, published.variableStyleEnabled, published.style ?? pageState.selectionInkStyle);
assert.equal(pageState.selectionInkStyle, 'DASH');

function clearSelectionWithRegisterReset() {
  onSelectionInkControlsChanged(null, null, 0.5, 30, true, null, true);
}
clearSelectionWithRegisterReset();
assert.equal(pageState.selectionInkColor, -16777216);
assert.equal(pageState.selectionInkWidth, 5);
assert.equal(pageState.selectionInkStyle, null);
assert.equal(pageState.selectionVariableStyleEnabled, true);

console.log('selectionStyleToolbarContext=original-inverse-map-pencil-gate-first-eligible-sync');
