import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function body(startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  assert.ok(start !== -1, startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(end !== -1, endMarker);
  return source.slice(start, end);
}

const canStart = body('private canStartOriginalPhotoInsert(): boolean {',
  'private canProbeOriginalClipboardImage(): boolean {');
const canUse = body('private canUseOriginalClipboardImage(): boolean {',
  'private startSystemClipboardImageAvailabilityUpdates(): void {');

for (const [name, text] of [['photo picker', canStart], ['clipboard paste', canUse]]) {
  for (const condition of [
    'this.lifecycleActive &&',
    'this.loaded &&',
    'this.dataLoading',
    'this.dataLoadFailed',
    'this.persistence.isReady()',
    'this.loadedPageId.length > 0',
  ]) {
    assert.ok(text.includes(condition), `${name}: ${condition}`);
  }
  const identityIndex = text.indexOf('this.loadedPageId === this.currentPage.pageId');
  const busyIndex = text.indexOf('!this.photoImportBusy');
  assert.ok(identityIndex > busyIndex, `${name}: page identity gate`);
}

assert.match(canUse, /this\.systemClipboardImageAvailable;/);

console.log('D02_PHOTO_ENTRY_STATE_BOUND_REPLAY_OK TOTAL=15 FAILED=0');
