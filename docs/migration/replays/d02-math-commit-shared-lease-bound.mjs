import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function methodBody(startMarker, endMarker) {
  const start = canvas.indexOf(startMarker);
  assert.ok(start >= 0, startMarker);
  return canvas.slice(start, canvas.indexOf(endMarker, start));
}

for (const [name, marker, end] of [
  ['startMathEditing', '  private startMathEditing(): void {', '\n  }\n'],
  ['confirmMathEditing', '  private async confirmMathEditing(): Promise<void> {', '\n  private async confirmMathInsert'],
]) {
  const body = methodBody(marker, end);
  const photoIndex = body.indexOf('this.photoImportBusy');
  const historyIndex = body.indexOf('this.historyBusy');
  assert.ok(photoIndex >= 0 && historyIndex > photoIndex, `${name} guard order`);
}

const insertStart = canvas.indexOf('  private async confirmMathInsert(): Promise<void> {');
assert.ok(insertStart >= 0);
const insertEnd = canvas.indexOf('\n  private groupSelectedElements', insertStart);
assert.ok(insertEnd > insertStart);
const insertBody = canvas.slice(insertStart, insertEnd);

const guardStart = insertBody.indexOf('if (this.');
const guardEnd = insertBody.indexOf('{\n      return;\n    }', guardStart);
assert.ok(guardStart >= 0 && guardEnd > guardStart);
const guard = insertBody.slice(guardStart, guardEnd);
assert.match(guard, /this\.photoImportBusy \|\| this\.historyBusy/);

for (const effect of [
  'await this.persistence.commitOriginalMathInsert(',
  'this.undoRedo.push(mathAction, prepared);',
]) {
  assert.ok(insertBody.includes(effect), `insert reaches ${effect}`);
}

console.log('D02_MATH_COMMIT_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=9 FAILED=0');
