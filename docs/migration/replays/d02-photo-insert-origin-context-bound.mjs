import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(page, /interface OriginalPhotoInsertOrigin \{\s+generation: number;\s+pageId: string;\s+pageWidth: number;\s+pageHeight: number;\s+zoom: number;\s+center: Point2D;\s+\}/);

const originStart = page.indexOf('  private getOriginalPhotoInsertOrigin(');
const insertStart = page.indexOf('  private async startOriginalPhotoInsert(): Promise<void> {');
const dropStart = page.indexOf('  private onOriginalImageDrop(event: DragEvent): void {');
const pasteStart = page.indexOf('  private async startOriginalClipboardImagePaste(): Promise<void> {');
assert.ok(dropStart !== -1 && dropStart > insertStart && dropStart < pasteStart);
assert.ok(originStart !== -1 && originStart < insertStart && insertStart < pasteStart);

const origin = page.slice(originStart, insertStart);
assert.match(origin, /const center: Point2D = pasteAnchor === undefined \?\s+this\.viewport\.screenToCanvas\(this\.canvasCtx\.width \/ 2, this\.canvasCtx\.height \/ 2\) :\s+\{ x: pasteAnchor\.x, y: pasteAnchor\.y \};/);
assert.match(origin, /if \(!Number\.isFinite\(center\.x\) \|\| !Number\.isFinite\(center\.y\)\) \{\s+throw new Error\('original photo insert origin anchor is invalid'\);\s+\}/);
for (const capture of [
  'generation: this.pageLoadGeneration,',
  'pageId: this.loadedPageId,',
  'pageWidth: this.getPaperWidth(),',
  'pageHeight: this.getPaperHeight(),',
  'zoom: this.viewport.zoom,',
]) {
  assert.ok(origin.includes(capture), capture);
}

const photo = page.slice(insertStart, dropStart);
const busyIndex = photo.indexOf('this.photoImportBusy = true;');
const pickerIndex = photo.indexOf('await pickAndImportOriginalPhotos(');
const originIndex = photo.indexOf('origin = this.getOriginalPhotoInsertOrigin();');
assert.ok(busyIndex !== -1 && originIndex !== -1 && pickerIndex !== -1);
assert.ok(busyIndex < originIndex && originIndex < pickerIndex);
assert.match(photo, /if \(!this\.isPhotoContextCurrent\(origin\.generation, origin\.pageId\)\) \{\s+return;\s+\}\s+const outcome: PhotoInsertOutcome =\s+await this\.commitOriginalPhotoInsert\(imported, origin\);/);
assert.equal([...photo.matchAll(/this\.isPhotoContextCurrent\(origin\.generation, origin\.pageId\)/g)].length, 3);
assert.ok(!photo.includes('photoGeneration'));
assert.ok(!photo.includes('photoPageId'));

const pasteEnd = page.indexOf('  private canUseOriginalClipboardImage(): boolean {', pasteStart);
const paste = page.slice(pasteStart, Math.max(pasteEnd, pasteStart + 4200));
assert.match(paste, /const pasteOrigin: OriginalPhotoInsertOrigin = this\.getOriginalPhotoInsertOrigin\(\s+this\.clipboardPasteTarget === null \? undefined : \{\s+x: this\.clipboardPasteTarget\.x,\s+y: this\.clipboardPasteTarget\.y,\s+\}\);/);
const pasteBusyIndex = paste.indexOf('this.photoImportBusy = true;');
const probeIndex = paste.indexOf('await isOriginalClipboardImageAvailable()');
assert.ok(pasteBusyIndex !== -1 && probeIndex !== -1 && pasteBusyIndex < probeIndex);
assert.ok(!paste.includes('screenToCanvas'));
assert.match(paste, /insertOriginalPhotos\(\[\{[\s\S]*?\}\], pasteOrigin\);/);

assert.match(page, /private async commitOriginalPhotoInsert\(\s+imported: OriginalPhotoIngressItem\[\],\s+origin: OriginalPhotoInsertOrigin\): Promise<PhotoInsertOutcome> \{\s+return this\.insertOriginalPhotos\(imported, origin\);\s+\}/);
assert.doesNotMatch(page, /insertOriginalPhotos\([\s\S]{0,120}pasteAnchor\?: Point2D/);

const commitMarker = 'private async insertOriginalPhotos(';
const commitStart = page.indexOf(commitMarker);
const staleGuardIndex = page.indexOf(
  "if (!this.isPhotoContextCurrent(generation, pageId)) {", commitStart);
assert.ok(commitStart !== -1 && staleGuardIndex !== -1);
const staleSection = page.slice(staleGuardIndex, staleGuardIndex + 260);
assert.match(staleSection, /hilog\.error\(0x0001, 'NoteCanvasView',\s+'original photo insert skipped after stale source page'\);/);
assert.match(staleSection, /return \{ insertedCount: 0, totalCount: plans\.length \};/);

console.log('D02_PHOTO_INSERT_ORIGIN_CONTEXT_BOUND_REPLAY_OK TOTAL=12 FAILED=0');
