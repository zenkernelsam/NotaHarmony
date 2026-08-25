import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

for (const gate of ['canStartOriginalPhotoInsert', 'canUseOriginalClipboardImage']) {
  const marker = `private ${gate}(): boolean {`;
  const start = page.indexOf(marker);
  assert.notEqual(start, -1, marker);
  const end = page.indexOf('}', page.indexOf('this.systemClipboardImageAvailable', start));
  const section = page.slice(start, Math.max(end, start + 500));
  assert.ok(section.includes('this.lifecycleActive &&'), `${gate} requires active lifecycle`);
  assert.ok(section.includes('this.loadedPageId === this.currentPage.pageId'),
    `${gate} requires current page identity`);
}

assert.match(page, /private isPhotoContextCurrent\(generation: number, pageId: string\): boolean \{\s+return this\.lifecycleActive && generation === this\.pageLoadGeneration &&\s+pageId === this\.loadedPageId;\s+\}/);
assert.ok(!page.includes('photoGeneration === this.pageLoadGeneration'));
assert.ok(!page.includes('pasteGeneration === this.pageLoadGeneration'));
assert.ok(!page.includes('pasteGeneration !== this.pageLoadGeneration'));

const start = page.indexOf('  private async startOriginalPhotoInsert(): Promise<void> {');
const end = page.indexOf('  private async startOriginalClipboardImagePaste(): Promise<void> {', start);
assert.ok(start !== -1 && end !== -1);
const photo = page.slice(start, end);
assert.equal([...photo.matchAll(/this\.isPhotoContextCurrent\(origin\.generation, origin\.pageId\)/g)].length, 3);
for (const message of ['original_photo_insert_partial_failed', 'original_photo_insert_failed']) {
  const toastIndex = photo.indexOf(message);
  const guardIndex = toastIndex >= 0 ?
    photo.lastIndexOf('this.isPhotoContextCurrent(origin.generation, origin.pageId)', toastIndex) : -1;
  assert.ok(guardIndex !== -1 && guardIndex < toastIndex, message);
}

const pasteStart = end;
const pasteEnd = page.indexOf('  private canUseOriginalClipboardImage(): boolean {', pasteStart);
const paste = page.slice(pasteStart, pasteEnd);
assert.equal([...paste.matchAll(/this\.isPhotoContextCurrent\(pasteGeneration, pastePageId\)/g)].length, 5);
for (const effect of [
  'this.systemClipboardImageAvailable = false;',
  "throw new Error('READ_PASTEBOARD permission was not granted');",
  'await importOriginalClipboardImage();',
  'this.systemClipboardImageAvailable = available && outcome.insertedCount > 0;',
  'original clipboard image paste failed',
]) {
  assert.ok(paste.indexOf(effect) !== -1, effect);
}
assert.match(paste, /\} finally \{\s+this\.photoImportBusy = false;\s+this\.onPhotoIngressFinished\(\);\s+\}/);

console.log('D02_PHOTO_INGRESS_DISPOSAL_BOUND_REPLAY_OK TOTAL=9 FAILED=0');
