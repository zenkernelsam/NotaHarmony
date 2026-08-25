import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const start = canvas.indexOf('  async onTextCommit(text: string): Promise<boolean> {');
const end = canvas.indexOf('\n  onTextCancel(): void {', start);
assert.ok(start >= 0 && end > start);
const body = canvas.slice(start, end);

const guardStart = body.indexOf('if (this.');
const guardEnd = body.indexOf('{\n      return false;', guardStart);
assert.ok(guardStart >= 0 && guardEnd > guardStart);
const guard = body.slice(guardStart, guardEnd);
assert.match(guard, /this\.photoImportBusy \|\| this\.historyBusy/);
assert.ok(
  guard.indexOf('this.photoImportBusy') < guard.indexOf('this.historyBusy'),
  'shared photo ingress lease is rejected before the internal history guard',
);

for (const token of [
  'this.undoRedo.push(',
  'this.replaceTextBlock(updated)',
  'this.persist(rearmOriginalCreate)',
]) {
  assert.ok(body.includes(token), `commit path reaches ${token}`);
}

console.log('D02_TEXT_COMMIT_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=7 FAILED=0');
