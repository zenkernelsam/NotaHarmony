import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function body(marker, endMarker) {
  const start = canvas.indexOf(marker);
  assert.ok(start >= 0, marker);
  return canvas.slice(start, canvas.indexOf(endMarker, start));
}

const canPaste = body(
  '  private canPasteClipboardNow(): boolean {', '\n  private selectionPasteTarget');
assert.match(canPaste,
  /!this\.dataLoading && !this\.dataLoadFailed &&\s+!this\.photoImportBusy && !this\.historyBusy &&/);
assert.ok(
  canPaste.indexOf('this.photoImportBusy') < canPaste.indexOf('this.historyBusy'));

const paste = body('  private pasteClipboard(', '\n  private applyOriginalGroupClipboardPaste');
const guardStart = paste.indexOf('if (');
const guardEnd = paste.indexOf('{', guardStart);
const guard = paste.slice(guardStart, guardEnd);
assert.match(guard, /this\.photoImportBusy \|\| this\.historyBusy/);
assert.ok(guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'));
assert.match(paste, /!this\.canPasteClipboardNow\(\)/);

for (const [name, token] of [
  ['zoom out', 'this.zoomStep(-0.25)'],
  ['zoom in', 'this.zoomStep(0.25)'],
  ['fit width', 'this.zoomFitWidth()'],
]) {
  const callIndex = canvas.indexOf(token);
  const sectionStart = Math.max(0, callIndex - 260);
  const section = canvas.slice(sectionStart, callIndex);
  assert.match(section, /\.enabled\(!this\.photoImportBusy\)/, `${name} is disabled`);
}

console.log('D02_PASTE_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
