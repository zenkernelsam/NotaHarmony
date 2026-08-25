import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const startMarker = '\n  onTextCancel(): void {';
const start = canvas.indexOf(startMarker);
assert.ok(start >= 0);
const bodyStart = start + startMarker.length - '  '.length;
const endMarker = '\n  // === RenderSpec 构建 ===';
const end = canvas.indexOf(endMarker, start);
assert.ok(end > bodyStart);
const body = canvas.slice(bodyStart, end);

const guardStart = body.indexOf('if (this.');
const guardEnd = body.indexOf('{\n      return;\n    }', guardStart);
assert.ok(guardStart >= 0 && guardEnd > guardStart);
const guard = body.slice(guardStart, guardEnd);
assert.match(guard, /this\.photoImportBusy \|\| this\.historyBusy/);
assert.ok(
  guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'),
  'shared photo ingress lease is rejected before the internal history guard',
);

for (const effect of [
  'this.textBlocks = remaining;',
  'removePageElementRefs(this.elementOrder',
  'this.persist();',
]) {
  assert.ok(body.includes(effect), `cancel path reaches ${effect}`);
}

console.log('D02_TEXT_CANCEL_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
