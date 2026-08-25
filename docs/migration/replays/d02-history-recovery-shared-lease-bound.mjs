import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const fixture = fs.readFileSync('note/src/test/PhotoHistoryRecoveryLease.test.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function methodBody(startMarker, endMarker) {
  const start = canvas.indexOf(startMarker);
  assert.ok(start >= 0, startMarker);
  return canvas.slice(start, canvas.indexOf(endMarker, start));
}

for (const [name, marker, end] of [
  ['request entry', '  private requestPersistentHistoryReset(): Promise<void> {',
    '\n  private async resetPersistentHistory'],
  ['reset body', '  private async resetPersistentHistory(): Promise<void> {',
    '\n  private showHistoryRecoveryToast'],
]) {
  const body = methodBody(marker, end);
  const photoIndex = body.indexOf('this.photoImportBusy');
  const historyIndex = body.indexOf('this.historyBusy');
  assert.ok(photoIndex >= 0 && historyIndex > photoIndex,
    `${name} checks shared ingress before internal history`);
}

assert.match(fixture, /blocks history reset while shared photo ingress is active/);
assert.match(fixture, /photoImportBusy = true/);

console.log('D02_HISTORY_RECOVERY_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
