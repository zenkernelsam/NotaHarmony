import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  onSelectionMenuAction(action: SelectionMenuAction): void {');
const end = canvas.indexOf('  private onMathEditorThemeChange(): void {', start);
const body = canvas.slice(start, end);
const guardStart = body.indexOf('if (this.');
const guardEnd = body.indexOf('{\n      return;', guardStart);
assert.ok(start >= 0 && end > start && guardStart >= 0 && guardEnd > guardStart);
const guard = body.slice(guardStart, guardEnd);

for (const [name, token] of [
  ['photo ingress lease', 'this.photoImportBusy'],
  ['history serialization lease', 'this.historyBusy'],
  ['page health gate', 'this.loaded'],
  ['page identity gate', 'this.loadedPageId !== this.currentPage.pageId'],
]) {
  assert.ok(guard.includes(token), `selection menu checks ${name}`);
}

assert.ok(guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'),
  'shared photo ingress lease is rejected before the internal history guard');

console.log('D02_SELECTION_MENU_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
