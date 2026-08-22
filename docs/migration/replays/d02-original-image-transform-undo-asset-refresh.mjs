#!/usr/bin/env node
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8');
const undo = fs.readFileSync('note/src/main/ets/rendering/UndoRedoManager.ets', 'utf8');
const geometry = fs.readFileSync('note/src/main/ets/core/model/OriginalImageCropGeometry.ets', 'utf8');
const editingReplay = fs.readFileSync('docs/migration/replays/d02-image-editing.mjs', 'utf8');
const fixture = fs.readFileSync('note/src/test/ImageBlockRendering.test.ets', 'utf8');

function section(source, start, end) {
  const startIndex = source.indexOf(start);
  if (startIndex < 0) return '';
  const endIndex = source.indexOf(end, startIndex + start.length);
  return endIndex < 0 ? '' : source.slice(startIndex, endIndex);
}

const assetRefresh = section(canvas,
  'private actionTouchesImages(action: UndoableAction): boolean {',
  'private synchronizeElementArraysByOrder(): void {');

const checks = [
  ['Harmony crop confirmation creates an image transform history action',
    canvas.includes('beforeImages: [before], afterImages: [after]') &&
    canvas.includes('UndoableActionType.TRANSFORM_ELEMENTS')],
  ['transform actions estimate both image snapshots for memory pressure',
    undo.includes('estimateImages(action.beforeImages)') &&
    undo.includes('estimateImages(action.afterImages)')],
  ['image transform history is classified as touching image assets',
    assetRefresh.includes('if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {') &&
    assetRefresh.includes('action.beforeImages.length > 0 || action.afterImages.length > 0')],
  ['single-image crop remains the durable original mutation boundary',
    canvas.includes('applyOriginalImageCropDraft(session, this.imageCropDraft)') &&
    canvas.includes('this.persist(true)')],
  ['existing image-editing replay no longer excludes transform asset refreshes',
    editingReplay.includes("assert.match(assetRefresh, /TRANSFORM_ELEMENTS/);") &&
    !editingReplay.includes('assert.doesNotMatch(assetRefresh, /TRANSFORM_ELEMENTS/);')],
  ['crop and rendering fixtures remain registered in the suite',
    fixture.includes('applies a rotated and scaled intrinsic crop with the original origin shift') &&
    fixture.includes('applies user flips in encoded bitmap coordinates after EXIF orientation')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_IMAGE_TRANSFORM_UNDO_ASSET_REFRESH_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;