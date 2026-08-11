import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');

const shapeRenderer = read('note/src/main/ets/rendering/ShapeCanvasRenderer.ets');
const textRenderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const thumbnail = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const shapeReducer = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const textReducer = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');

// Android 1.0.3 stores RichText on Shape, but its visible consumers submit only Shape geometry.
assert.match(shapeRenderer, /renderShape\(shape: ShapeElement, context: RenderContext\)/);
assert.doesNotMatch(shapeRenderer, /Canvas2DTextRenderer|richText|fillText/);
assert.match(canvas, /this\.shapeRenderer\.renderShape\(element\.data, this\.renderCtx\)/);
assert.match(thumbnail, /this\.shapeRenderer\.renderShape\(element\.data, renderContext\)/);

// The visible text renderer remains a Text Block consumer, not a Shape label renderer.
assert.match(textRenderer, /renderText\(element: TextBlockElement, context: RenderContext\)/);
assert.doesNotMatch(textRenderer, /ShapeElement/);

// The non-visual Shape RichText CRDT remains materialized and is not discarded by this boundary.
assert.match(shapeReducer, /richText: ''/);
assert.match(shapeReducer, /copyShapeRichText/);
assert.match(textReducer, /PageElementKind\.SHAPE/);

console.log('shapeRichText=state-only-original-1.0.3');
