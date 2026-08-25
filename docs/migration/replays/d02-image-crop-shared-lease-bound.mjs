import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function methodBody(name) {
  const start = canvas.indexOf(`  private ${name}(`);
  assert.ok(start >= 0, `${name} exists`);
  return canvas.slice(start, canvas.indexOf('\n  }\n', start));
}

for (const [name, publishToken] of [
  ['startImageCrop', 'this.imageCropVisible = true;'],
  ['confirmImageCrop', 'this.replaceImagesById([after]);'],
]) {
  const body = methodBody(name);
  const photoIndex = body.indexOf('this.photoImportBusy');
  const historyIndex = body.indexOf('this.historyBusy');
  const publishIndex = body.indexOf(publishToken);
  assert.ok(photoIndex >= 0 && historyIndex >= 0 && publishIndex > historyIndex,
    `${name} guard order`);
  assert.ok(photoIndex < historyIndex,
    `${name} checks shared ingress lease before history`);
}

const touchStart = canvas.indexOf('  private onCanvasTouch(event: TouchEvent): void {');
const touchGuard = canvas.slice(touchStart, canvas.indexOf('{\n      return;', touchStart));
assert.match(touchGuard, /photoImportBusy[\s\S]*historyBusy/);

console.log('D02_IMAGE_CROP_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
