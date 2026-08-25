import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const painter = fs.readFileSync('note/src/main/ets/rendering/StrokeCanvasPainter.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = page.indexOf('  renderCustomPath(stroke: StrokeElementData, ctx: RenderContext): boolean {');
const end = page.indexOf('  // === 中心线路径', start);
assert.ok(start !== -1 && end !== -1);
const section = page.slice(start, end);

assert.match(section, /if \(customPath === null \|\| customPath\.length === 0\) \{\s+return false;\s+\}/);
const appendIndex = section.indexOf('this.appendInkPath(c, customPath);');
const clipIndex = section.indexOf('c.clip();');
const centerIndex = section.indexOf('this.renderCenterPath(stroke, ctx);');
assert.ok(appendIndex !== -1 && clipIndex !== -1 && centerIndex !== -1);
assert.ok(appendIndex < clipIndex && clipIndex < centerIndex);
assert.equal(section.split('c.clip();').length - 1, 1);
assert.ok(!section.includes('c.setFillStyle('));
assert.ok(!section.includes('c.fill();'));
assert.match(section, /\} finally \{\s+c\.restore\(\);\s+\}\s+return true;/);

assert.match(page, /renderCenterPath\(stroke: StrokeElementData, ctx: RenderContext\): void \{/);
for (const originalContract of [
  "if (spec.inkStyle === InkStyle.DASH) {\n        c.setLineCap('butt');",
  "c.setLineJoin(spec.inkStyle === InkStyle.DOTS ? 'miter' : 'round');",
  'spec.isHighlighter ? 107 : undefined',
  "c.setLineDash([2 * spec.brushWidth, 1 * spec.brushWidth]);",
  "c.setLineDash([0.001 * spec.brushWidth, 2 * spec.brushWidth]);",
]) {
  assert.ok(page.includes(originalContract), originalContract);
}

const customPencil = painter.indexOf('if (customPath !== null && customPath.length > 0) {');
const nonPencil = painter.indexOf('const customRendered: boolean = this.renderer.renderCustomPath(stroke, rc);');
assert.ok(customPencil !== -1 && nonPencil !== -1 && customPencil < nonPencil);

console.log('D02_INK_CUSTOM_PATH_CENTERLINE_BOUND_REPLAY_OK TOTAL=11 FAILED=0');
