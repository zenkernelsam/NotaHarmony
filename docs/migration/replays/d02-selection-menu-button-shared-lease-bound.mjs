import assert from 'node:assert/strict';
import fs from 'node:fs';

const overlay = fs.readFileSync('note/src/main/ets/ui/components/SelectionOverlay.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

assert.match(overlay, /@Prop menuEnabled: boolean = true;/);
assert.match(overlay, /@Prop photoImportLeaseActive: boolean = false;/);
assert.match(overlay,
  /\.fontSize\(14\)\s+\.enabled\(this\.menuEnabled\)\s+\.hitTestBehavior\(HitTestMode\.Block\)/);

const start = canvas.indexOf('      SelectionOverlay({');
const end = canvas.indexOf('\n      ImageCropOverlay({', start);
assert.ok(start >= 0 && end > start);
const body = canvas.slice(start, end);

for (const [name, token] of [
  ['shared photo ingress lease', '!this.photoImportBusy'],
  ['history serialization lease', '!this.historyBusy'],
  ['page health gate', 'this.loaded'],
  ['data loading gate', '!this.dataLoading'],
  ['data failure gate', '!this.dataLoadFailed'],
  ['identity gate', 'this.loadedPageId === this.currentPage.pageId'],
]) {
  assert.ok(body.includes(token), `selection menu button checks ${name}`);
}

const entryStart = canvas.indexOf('  onSelectionMenuAction(action: SelectionMenuAction): void {');
const entryBody = canvas.slice(entryStart, canvas.indexOf('\n  }\n', entryStart));
const selectionCall = canvas.slice(
  canvas.indexOf('      SelectionOverlay({'),
  canvas.indexOf('      ImageCropOverlay({'));
assert.match(selectionCall,
  /photoImportLeaseActive: this\.photoImportBusy/);
assert.match(overlay, /if \(this\.photoImportLeaseActive\) \{\s+return items;\s+\}/);
assert.match(entryBody, /this\.photoImportBusy \|\| this\.historyBusy/);
assert.match(entryBody, /SelectionMenuAction\.COPY/);
assert.match(entryBody, /prepareSelectedClipboard\(/);

console.log('D02_SELECTION_MENU_BUTTON_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=13 FAILED=0');
