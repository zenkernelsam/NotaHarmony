import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const replayDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(replayDir, '..', '..', '..');

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function section(source, start, end) {
  const startIndex = source.indexOf(start);
  assert.notEqual(startIndex, -1, `missing section start: ${start}`);
  const endIndex = source.indexOf(end, startIndex + start.length);
  assert.notEqual(endIndex, -1, `missing section end: ${end}`);
  return source.slice(startIndex, endIndex);
}

const imageGeometry = read('note/src/main/ets/core/model/ImageBlockGeometry.ets');
const selection = read('note/src/main/ets/rendering/SelectionTool.ets');
const clipboard = read('note/src/main/ets/rendering/StrokeClipboard.ets');
const order = read('note/src/main/ets/core/model/PageElementOrder.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

assert.match(imageGeometry, /isImageBlockPositionLocked/);
assert.match(imageGeometry, /updated\.transform = multiplyTransform\(transform, element\.transform\)/);
assert.match(imageGeometry, /updated\.bounds = imageBlockWorldBounds\(updated\)/);
assert.match(imageGeometry, /eraserPathHitsImageBlock/);
assert.match(imageGeometry, /pointOnSegment/);

assert.match(selection, /selectedImageIds: string\[\]/);
assert.match(selection, /this\.elementBoundsSelected\(image\.bounds\)/);
assert.doesNotMatch(selection,
  /!isImageBlockPositionLocked\(image\) && this\.elementBoundsSelected\(image\.bounds\)/);
assert.match(selection, /concat\(this\.state\.selectedImageIds\)/);

assert.match(clipboard, /cloneClipboardImage/);
assert.match(clipboard, /cloneImageElement\(image\)/);
assert.match(imageGeometry, /assetHashBits: element\.assetHashBits\.slice\(\)/);
assert.match(imageGeometry, /cropRect: element\.cropRect === null/);
assert.match(clipboard, /PageElementKind\.IMAGE/);
assert.match(order, /IMAGE = 4/);
assert.match(order, /selectedImages\.has\(ref\.elementId\)/);

for (const [field, type] of [
  ['removedImages', 'ImageElement'], ['removedImageIndices', 'number'],
  ['addedImages', 'ImageElement'], ['beforeImages', 'ImageElement'], ['afterImages', 'ImageElement'],
]) {
  assert.match(undo, new RegExp(`${field}: ${type}\\[\\]`));
}
assert.match(undo, /estimateImages\(action\.removedImages\)/);
assert.match(undo, /estimateImages\(action\.addedImages\)/);
assert.match(undo, /estimateImages\(action\.beforeImages\)/);

assert.match(canvas, /eraserPathHitsImageBlock\(this\.eraserPath, image/);
assert.match(canvas, /transformImageElements\(/);
assert.match(canvas, /restoreRemovedImages/);
assert.match(canvas, /replaceImagesById/);
assert.match(canvas, /const nextImages: ImageElement\[\] = this\.imageBlocks\.filter\(/);
assert.match(canvas, /this\.persistence\.queueSaveElements\(this\.noteId, this\.loadedPageId,[\s\S]*?nextImages/);
assert.match(canvas, /this\.imageBlocks = nextImages/);
assert.match(canvas, /this\.refreshImageAssets\(this\.pageLoadGeneration, this\.loadedPageId\)/);

const assetRefresh = section(canvas,
  'private actionTouchesImages(action: UndoableAction): boolean {',
  'private synchronizeElementArraysByOrder(): void {');
assert.match(assetRefresh, /ERASE_ELEMENTS/);
assert.match(assetRefresh, /DELETE_ELEMENTS/);
assert.match(assetRefresh, /ADD_ELEMENTS/);
assert.doesNotMatch(assetRefresh, /TRANSFORM_ELEMENTS/);

console.log('d02-image-editing: PASS');
