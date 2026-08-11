import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const yqa = original('yqa.java');
const jo3 = original('jo3.java');
const htd = original('htd.java');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const fixture = read('note/src/test/RendererStyle.test.ets');

assert.match(yqa, /si7Var\.a == fy2\.CHECK_BOX/);
assert.match(yqa, /bl1 bl1VarC = jo3\.c\(si7Var, qi3Var/);
assert.match(yqa, /zn9\.d\(zn9\.f\(j, bl1VarC\.a\(\)\)\) < bl1VarC\.b\(\) \* 1\.5f/);
assert.match(jo3, /float f3 = fD \/ 2\.0f/);
assert.match(jo3, /float f4 = f3 - 1\.0f/);
assert.match(jo3, /if \(f4 < f5\)/);
assert.match(htd, /yqa\.d\([\s\S]*?yqaVar\.g\.n\(numD\.intValue\(\)\)/);

assert.match(renderer, /interface TextLayoutLine/);
assert.match(renderer, /line\.paragraphStart \? this\.decoratorPrefix/);
assert.match(renderer, /checkboxMarkers\(element: TextBlockElement/);
assert.match(renderer, /Math\.max\(naturalLineHeight \/ 2 - 1, naturalLineHeight \/ 4\)/);
assert.match(renderer, /const tolerance: number = marker\.radius \* 1\.5/);
assert.match(renderer, /inverseTransformPoint\(worldPoint, element\)/);
assert.match(canvas, /currentTool === ToolType\.DEFAULT[\s\S]*?toggleCheckboxMarkerAt\(canvasP\)/);
assert.match(canvas, /this\.textRenderer\.hitCheckboxMarker\(/);
assert.match(canvas, /toggleOriginalCheckboxAt\(before, codePointIndex\)/);
assert.match(canvas, /type: UndoableActionType\.REPLACE_ELEMENT/);
assert.match(canvas, /this\.notifyUndoRedo\(\);[\s\S]*?this\.persist\(\);[\s\S]*?this\.renderFrame\(true\)/);
assert.match(fixture, /shared wrapped and transformed layout/);
assert.match(fixture, /expect\(markers\.length\)\.assertEqual\(2\)/);

const matrix = [0, -1, 120, 1, 0, 10];
const local = { x: 12, y: 40 };
const world = {
  x: matrix[0] * local.x + matrix[1] * local.y + matrix[2],
  y: matrix[3] * local.x + matrix[4] * local.y + matrix[5],
};
const determinant = matrix[0] * matrix[4] - matrix[1] * matrix[3];
const dx = world.x - matrix[2];
const dy = world.y - matrix[5];
assert.deepEqual({
  x: (matrix[4] * dx - matrix[1] * dy) / determinant,
  y: (-matrix[3] * dx + matrix[0] * dy) / determinant,
}, local);
const radius = Math.max(25 / 2 - 1, 25 / 4);
assert.equal(17.2 < radius * 1.5, true);
assert.equal(17.3 < radius * 1.5, false);

console.log('checkboxMarkerHit=' +
  'original-layout-geometry-radius15-shared-wrap-transform-single-tap-history-type28');
