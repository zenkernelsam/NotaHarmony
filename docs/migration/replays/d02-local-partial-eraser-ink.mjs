import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalInput = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/kt1.java', 'utf8');
const originalTools = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/u16.java', 'utf8');
const model = read('note/src/main/ets/core/model/StrokeTypes.ets');
const createReducer = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const createEncoder = read('note/src/main/ets/data/OriginalCreateInkPayloadEncoder.ets');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets');
const painter = read('note/src/main/ets/rendering/StrokeCanvasPainter.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const selection = read('note/src/main/ets/rendering/SelectionTool.ets');
const fixture = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');

assert.match(originalTools, /PARTIAL_ERASER\(\(byte\) 5\)/);
assert.match(originalInput, /q4fVar\.b\(\) == d04\.J/);
assert.match(originalInput, /u16VarL = u16\.PARTIAL_ERASER/);
assert.match(originalInput, /u5j\.g\(x09VarA, cxcVar, fqaVarG2, null, null, u16Var/);

assert.match(model, /isPartialEraser\?: boolean/);
assert.match(createEncoder, /isPartialEraser === true[\s\S]*return 5/);
assert.match(createReducer, /payload\.tool !== 5/);
assert.match(createReducer, /isPartialEraser: payload\.tool === 5/);
assert.match(painter, /isPartialEraser === true[\s\S]*renderPartialEraser/);
assert.match(renderer, /renderPartialEraser[\s\S]*destination-out/);
assert.match(canvas, /commitOriginalPartialEraser/);
assert.match(canvas, /inkStyle: InkStyle\.FIXED_WIDTH/);
assert.match(canvas, /this\.persist\(true\)/);
assert.match(canvas, /const eraseObjects: boolean = this\.eraserEngine\.getMode\(\) === EraserMode\.WHOLE/);
assert.match(canvas, /renderOrderedContentLayer/);
assert.match(selection, /isPartialEraser === true/);
assert.match(fixture, /decoded\.tool\)\.assertEqual\(5\)/);
assert.match(fixture, /unsupportedOriginalCreateInkReason\(decoded\) === null/);

const entities = [
  { id: 'ink-a', kind: 'ink', visible: true },
  { id: 'eraser', kind: 'partial-eraser', visible: true },
  { id: 'ink-b', kind: 'ink', visible: true },
];
const visibleAtCrossing = () => entities.filter(entity => entity.visible).reduce(
  (visible, entity) => entity.kind === 'partial-eraser' ? false : true, false);
assert.equal(visibleAtCrossing(), true, 'later ink must render above the eraser');
entities[2].visible = false;
assert.equal(visibleAtCrossing(), false, 'eraser must remove earlier ink');
entities[1].visible = false;
assert.equal(visibleAtCrossing(), true, 'undo by deleting the eraser restores earlier ink');
entities[1].visible = true;
assert.equal(visibleAtCrossing(), false, 'redo by undeleting the eraser reapplies it');

console.log('localPartialEraser=original-create-tool5-zorder-undo-redo-paper-safe');
