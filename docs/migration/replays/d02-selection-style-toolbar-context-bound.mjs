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
