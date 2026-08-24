import assert from 'node:assert/strict';
import fs from 'node:fs';

const view = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function section(startMarker, endMarker) {
  const start = view.indexOf(startMarker);
  assert.ok(start !== -1, startMarker);
  const end = view.indexOf(endMarker, start);
  assert.ok(end !== -1, endMarker);
  return view.slice(start, end);
}

function assertStaleGuard(text, message, effectIndex) {
  const marker = `if (!this.isHistoryPageContextCurrent(generation, pageId)) {`;
  const guardIndex = text.indexOf(marker);
  const messageIndex = text.indexOf(message);
  assert.ok(guardIndex !== -1 && messageIndex !== -1 && messageIndex < effectIndex);
  assert.ok(text.slice(guardIndex, messageIndex).includes('hilog.error(0x0001'));
}

const erase = section('private commitOriginalPartialErase(',
  'private applyPartialEraseLocally(');
const eraseMessage = "'original partial erase committed after stale page";
const eraseEffect = erase.indexOf('this.partialEraserPreview.complete(previewToken);', erase.indexOf('.then('));
assert.ok(eraseEffect !== -1);
assertStaleGuard(erase, eraseMessage, eraseEffect);
for (const effect of [
  'this.undoRedo.push(action, prepared);',
  'this.notifyUndoRedo();',
]) {
  const effectIndex = erase.indexOf(effect, eraseMessage);
  assert.ok(effectIndex !== -1 && effectIndex > erase.indexOf('return;', eraseMessage));
}
assert.match(erase, /\.finally\(\(\): void => \{\s+const previewCleared: boolean = this\.partialEraserPreview\.complete\(previewToken\);\s+this\.historyBusy = false;/);

const photo = section('private async insertOriginalPhotos(', 'private async confirmMathInsert(): Promise<void> {');
const photoMessage = "'original photo insert committed after stale page";
const photoPush = photo.indexOf('this.undoRedo.push(action, prepared);');
assert.ok(photoPush !== -1);
assertStaleGuard(photo, photoMessage, photoPush);
const photoReturn = photo.indexOf('return { insertedCount: results.length, totalCount: plans.length };', photoMessage);
assert.ok(photoReturn !== -1 && photoReturn < photoPush);
assert.match(photo, /\} finally \{\s+this\.historyBusy = false;\s+\}/);

console.log('D02_PARTIAL_ERASE_PHOTO_STALE_BOUND_REPLAY_OK TOTAL=9 FAILED=0');