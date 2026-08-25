import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const callbackStart = page.indexOf('          onInsertMath: () => {');
const callbackEnd = page.indexOf('          onInsertPhotos:', callbackStart);
assert.ok(callbackStart >= 0 && callbackEnd > callbackStart);
const callback = page.slice(callbackStart, callbackEnd);

const guardStart = callback.indexOf('if (this.');
const guardEnd = callback.indexOf('return;', guardStart);
assert.ok(guardStart >= 0 && guardEnd > guardStart);
const guard = callback.slice(guardStart, guardEnd);

for (const [name, token] of [
  ['photo ingress lease', 'this.photoImportLeaseActive'],
  ['page operation lease', 'this.pageOperationBusy'],
  ['history pending lease', 'this.historyPending'],
  ['page structure lease', 'this.pageStructureLeaseActive'],
]) {
  assert.ok(guard.includes(token), `math toolbar checks ${name}`);
}
assert.match(callback, /this\.mathInsertSignal\+\+/);

const methodStart = canvas.indexOf('  private startMathInsert(): void {');
const methodEnd = canvas.indexOf('\n  }\n', methodStart);
assert.ok(methodStart >= 0 && methodEnd > methodStart);
const method = canvas.slice(methodStart, methodEnd);
const lifecycleGuardStart = method.indexOf('if (!this.lifecycleActive');
const lifecycleGuardEnd = method.indexOf('{\n      return;', lifecycleGuardStart);
assert.ok(lifecycleGuardStart >= 0 && lifecycleGuardEnd > lifecycleGuardStart);
const lifecycleGuard = method.slice(lifecycleGuardStart, lifecycleGuardEnd);

for (const [name, token] of [
  ['photo ingress lease', 'this.photoImportBusy'],
  ['history serialization lease', 'this.historyBusy'],
  ['lifecycle gate', '!this.lifecycleActive'],
  ['editor visibility gate', 'this.mathEditorVisible'],
  ['page health gate', '!this.loaded'],
  ['identity gate', 'this.loadedPageId !== this.currentPage.pageId'],
]) {
  assert.ok(lifecycleGuard.includes(token), `canvas math insert checks ${name}`);
}
assert.ok(
  lifecycleGuard.indexOf('this.photoImportBusy') < lifecycleGuard.indexOf('this.historyBusy'),
  'shared photo ingress lease is rejected before the internal history guard',
);

console.log('D02_MATH_INSERT_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
