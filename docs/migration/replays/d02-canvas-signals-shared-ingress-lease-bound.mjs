import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function callbackBody(name, endMarker) {
  const start = canvas.indexOf(`  ${name}(`);
  assert.ok(start >= 0, name);
  return canvas.slice(start, canvas.indexOf(endMarker, start));
}

for (const [name, endMarker] of [
  ['onMathInsertSignalChange', '\n  onPhotoInsertSignalChange'],
  ['onPhotoInsertSignalChange', '\n  // === 画布初始化'],
]) {
  const body = callbackBody(name, endMarker);
  assert.match(body,
    /if \(this\.photoImportBusy\) \{\s+return;\s+\}/,
    name);
}

assert.match(canvas,
  /private startMathInsert\(\): void \{[\s\S]*?this\.photoImportBusy \|\|\s+this\.historyBusy/);
assert.match(canvas,
  /private canStartOriginalPhotoInsert\(\): boolean \{[\s\S]*?!this\.historyBusy && !this\.photoImportBusy/);

console.log(
  'D02_CANVAS_SIGNALS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
