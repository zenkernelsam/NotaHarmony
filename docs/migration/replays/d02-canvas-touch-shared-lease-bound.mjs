import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const start = canvas.indexOf('  private onCanvasTouch(event: TouchEvent): void {');
const end = canvas.indexOf('\n  }\n', start);
assert.ok(start >= 0 && end > start);
const body = canvas.slice(start, end);

const guardStart = body.indexOf('if (!this.loaded');
const guardEnd = body.indexOf('{\n      return;', guardStart);
assert.ok(guardStart >= 0 && guardEnd > guardStart);
const guard = body.slice(guardStart, guardEnd);

for (const [name, token] of [
  ['page health gate', '!this.loaded'],
  ['data loading gate', 'this.dataLoading'],
  ['data failure gate', 'this.dataLoadFailed'],
  ['shared photo ingress lease', 'this.photoImportBusy'],
  ['history serialization lease', 'this.historyBusy'],
  ['image crop gate', 'this.imageCropVisible'],
  ['math editor gate', 'this.mathEditorVisible'],
]) {
  assert.ok(guard.includes(token), `canvas touch checks ${name}`);
}
assert.ok(
  guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'),
  'shared photo ingress lease is rejected before the internal history guard',
);

for (const name of [
  'toggleCheckboxMarkerAt',
  'beginTextEditingAt',
  'applySelectionTransform',
  'applyEraser',
]) {
  assert.ok(canvas.includes(`private ${name}(`), `${name} implementation exists`);
}

console.log('D02_CANVAS_TOUCH_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=11 FAILED=0');
