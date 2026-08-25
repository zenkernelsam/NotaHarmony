import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function section(marker, endMarker) {
  const start = canvas.indexOf(marker);
  assert.ok(start >= 0, marker);
  return canvas.slice(start, canvas.indexOf(endMarker, start));
}

const schedule = section(
  '  private schedulePdfRasterRefresh(', '\n  private cancelPdfRasterRefresh');
const guardStart = schedule.indexOf('if (');
const guardEnd = schedule.indexOf('{\n      return;', guardStart);
const guard = schedule.slice(guardStart, guardEnd);
assert.match(guard, /!this\.lifecycleActive \|\| this\.photoImportBusy \|\| this\.historyBusy/);
assert.ok(guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'));

const save = section(
  '  private async saveViewportState(', '\n  // 缩放控制条操作');
assert.match(save,
  /!allowDisposedFinalSave && \(this\.photoImportBusy \|\| this\.historyBusy\) \|\|\s+requestedGeneration !== this\.pageLoadGeneration\)/);
assert.match(save, /allowDisposedFinalSave: boolean = false/);

for (const [name, token] of [
  ['pinch end', 'this.gestureTracker.resetScale();'],
  ['pan end', 'this.gestureTracker.resetPan();'],
]) {
  let cursor = 0;
  let guarded = 0;
  while ((cursor = canvas.indexOf(token, cursor)) >= 0) {
    const callback = canvas.slice(cursor, cursor + 260);
    if (!callback.includes('schedulePdfRasterRefresh(0)')) break;
    assert.match(callback, /if \(this\.photoImportBusy\) \{\s+return;\s+\}/, name);
    guarded++;
    cursor += token.length;
  }
  assert.equal(guarded, 2, `${name} guards both end and cancel`);
}

console.log('D02_VIEWPORT_CONTINUATION_SHARED_INGRESS_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
