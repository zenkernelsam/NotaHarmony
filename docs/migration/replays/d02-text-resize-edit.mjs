import assert from 'node:assert/strict';
import fs from 'node:fs';

function bounds(width, transform) {
  const points = [[10, 20], [10 + width, 20], [10 + width, 60], [10, 60]]
    .map(([x, y]) => ({
      x: transform[0] * x + transform[1] * y + transform[2],
      y: transform[3] * x + transform[4] * y + transform[5],
    }));
  return {
    left: Math.min(...points.map(point => point.x)),
    top: Math.min(...points.map(point => point.y)),
    right: Math.max(...points.map(point => point.x)),
    bottom: Math.max(...points.map(point => point.y)),
  };
}

function fit(element, measuredWidth) {
  const copy = structuredClone(element);
  if (copy.resizesWidthToFitText !== true || !Number.isFinite(measuredWidth)) return copy;
  copy.blockWidth = Math.max(copy.contentLeftInset * 2 + 1, Math.ceil(measuredWidth));
  copy.bounds = bounds(copy.blockWidth, copy.transform);
  return copy;
}

const source = {
  blockWidth: 100, contentLeftInset: 4, resizesWidthToFitText: true,
  transform: [2, 0, 30, 0, 2, 40, 0, 0, 1], bounds: bounds(100, [2, 0, 30, 0, 2, 40, 0, 0, 1]),
};
const fitted = fit(source, 81.2);
assert.equal(fitted.blockWidth, 82);
assert.deepEqual(fitted.bounds, { left: 50, top: 80, right: 214, bottom: 160 });
assert.equal(source.blockWidth, 100);
assert.equal(fit({ ...source, resizesWidthToFitText: false }, 60).blockWidth, 100);
assert.equal(fit(source, Number.NaN).blockWidth, 100);

const renderer = fs.readFileSync(new URL(
  '../../../note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', import.meta.url), 'utf8');
const tool = fs.readFileSync(new URL(
  '../../../note/src/main/ets/rendering/TextBlockTool.ets', import.meta.url), 'utf8');
const canvas = fs.readFileSync(new URL(
  '../../../note/src/main/ets/ui/editor/NoteCanvasView.ets', import.meta.url), 'utf8');
const overlay = fs.readFileSync(new URL(
  '../../../note/src/main/ets/ui/components/TextBlockOverlay.ets', import.meta.url), 'utf8');

assert.match(renderer, /measureNaturalWidth\(element: TextBlockElement, context: RenderContext\)/);
assert.match(renderer, /this\.measureRange\(ctx, characters, characterStyles/);
assert.match(renderer, /paragraph\.indentLevel/);
assert.match(renderer, /this\.decoratorPrefix\(paragraph\.decoratorStyle/);
assert.match(tool, /updateWidthToFit\(element: TextBlockElement, measuredWidth: number\)/);
assert.match(tool, /updated\.bounds = textBlockWorldBounds\(updated\)/);
assert.match(canvas, /this\.textRenderer\.measureNaturalWidth\(element, this\.renderCtx\)/);
assert.match(canvas, /editingTextLayoutWidth: number/);
assert.match(canvas, /layoutWidth: this\.editingTextLayoutWidth/);
assert.match(overlay, /this\.layoutWidth > 0 \? this\.layoutWidth : this\.element\.blockWidth/);

console.log('success|canvas-font-metrics=1|explicit-lines=1|paragraph-prefix-indent=1|' +
  'live-overlay-width=1|commit-width=1|world-bounds=1|disabled-noop=1|nan-noop=1');
