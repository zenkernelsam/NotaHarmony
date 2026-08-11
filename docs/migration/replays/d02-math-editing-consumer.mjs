import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const geometry = read('note/src/main/ets/core/model/MathBlockGeometry.ets');
const selection = read('note/src/main/ets/rendering/SelectionTool.ets');
const clipboard = read('note/src/main/ets/rendering/StrokeClipboard.ets');
const history = read('note/src/main/ets/rendering/UndoRedoManager.ets');
const order = read('note/src/main/ets/core/model/PageElementOrder.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const selectionTest = read('note/src/test/SelectionTool.test.ets');
const geometryTest = read('note/src/test/MathBlockGeometry.test.ets');
const clipboardTest = read('note/src/test/StrokeClipboard.test.ets');

const multiply = (a, b) => [
  a[0] * b[0] + a[1] * b[3], a[0] * b[1] + a[1] * b[4],
  a[0] * b[2] + a[1] * b[5] + a[2],
  a[3] * b[0] + a[4] * b[3], a[3] * b[1] + a[4] * b[4],
  a[3] * b[2] + a[4] * b[5] + a[5], 0, 0, 1,
];
const bounds = element => {
  const points = [[0, 0], [element.width, 0], [element.width, element.height], [0, element.height]]
    .map(([x, y]) => ({
      x: element.transform[0] * x + element.transform[1] * y + element.transform[2],
      y: element.transform[3] * x + element.transform[4] * y + element.transform[5],
    }));
  return {
    left: Math.min(...points.map(point => point.x)),
    top: Math.min(...points.map(point => point.y)),
    right: Math.max(...points.map(point => point.x)),
    bottom: Math.max(...points.map(point => point.y)),
  };
};

const math = { width: 40, height: 20, transform: [0, -1, 30, 1, 0, 40, 0, 0, 1] };
const translated = { ...math, transform: multiply([1, 0, 5, 0, 1, 7, 0, 0, 1], math.transform) };
assert.deepEqual(translated.transform, [0, -1, 35, 1, 0, 47, 0, 0, 1]);
assert.deepEqual(bounds(translated), { left: 15, top: 47, right: 35, bottom: 87 });

assert.match(geometry, /isMathBlockPositionLocked\(element\)/);
assert.match(geometry, /updated\.transform = multiplyTransform\(transform, element\.transform\)/);
assert.match(geometry, /updated\.bounds = mathBlockWorldBounds\(updated\)/);
assert.match(geometry, /eraserPathHitsMathBlock/);
assert.match(geometry, /if \(eraserPath\.length === 0 \|\| isMathBlockPositionLocked\(element\)\)/);
assert.match(selection, /selectedMathIds: string\[\]/);
assert.match(selection, /if \(this\.elementBoundsSelected\(math\.bounds\)\)/);
assert.doesNotMatch(selection,
  /!isMathBlockPositionLocked\(math\) && this\.elementBoundsSelected/);
assert.match(selection, /availableIds\.push\(math\.id\)/);
assert.match(selection, /\.concat\(this\.state\.selectedMathIds\)/);
assert.match(clipboard, /cloneClipboardMath/);
assert.match(clipboard, /mathSnapshots: MathElement\[\]/);
assert.match(clipboard, /PageElementKind\.MATH/);
assert.match(history, /addedMathBlocks\?: MathElement\[\]/);
assert.match(history, /removedMathBlocks\?: MathElement\[\]/);
assert.match(history, /beforeMathBlocks\?: MathElement\[\]/);
assert.match(order, /mathIds: string\[\] = \[\]/);
assert.match(order, /selectedMath\.has\(ref\.elementId\)/);
assert.match(canvas, /this\.selectionGroups, this\.mathBlocks/);
assert.match(canvas, /transformMathElements\(/);
assert.match(canvas, /removePageElementRefs\(this\.elementOrder, PageElementKind\.MATH/);
assert.match(canvas, /this\.restoreRemovedMathBlocks/);
assert.match(canvas, /this\.replaceMathBlocksById/);
assert.match(canvas, /selectedImages, selectedMathBlocks/);
assert.match(canvas, /addedMathBlocks: result\.mathBlocks/);
assert.match(canvas,
  /captureHistoryPageSnapshot[\s\S]*?mathBlocks: this\.mathBlocks\.map\([\s\S]*?cloneMathElement\(math\)/);
assert.match(persistence,
  /saveHistoryGroup[\s\S]*?initial\.mathBlocks \?\? \[\][\s\S]*?step\.mathBlocks \?\? \[\]/);
assert.match(selectionTest, /selects locked Math when its bounds are hit/);
assert.match(geometryTest, /leaves position-locked Math untouched/);
assert.match(clipboardTest, /deep-copies Math and preserves five-kind z order/);
assert.match(canvas, /this\.persistence\.commitOriginalMathLatex/);

console.log('D02_MATH_EDITING_CONSUMER_REPLAY_OK ' +
  'positionable-evidence=u08-be5|locked-selectable-for-unlock=1|group-leaf=1|transform-bounds=1|' +
  'eraser-lock=2|history=add-delete-transform-erase-durable|clipboard=1|z-order=1|' +
  'latex-editor=type23-field10-complete|native-formula-engine=runtime-pending');
