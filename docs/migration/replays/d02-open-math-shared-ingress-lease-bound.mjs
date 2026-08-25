import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/MathEditorOverlay.ets', 'utf8').replaceAll('\r\n', '\n');

assert.match(overlay, /@Prop photoImportLeaseActive: boolean = false;/);
assert.match(overlay,
  /export function isOriginalMathEditorDoneEnabled\(state: OriginalMathEditorDraftState,\s+busy: boolean, photoImportLeaseActive: boolean\): boolean \{\s+return !busy && !photoImportLeaseActive &&\s+state === OriginalMathEditorDraftState\.OK;\s+\}/);
assert.equal(overlay.match(/!this\.photoImportLeaseActive/g)?.length >= 2, true);

const callStart = canvas.indexOf('      MathEditorOverlay({');
const callEnd = canvas.indexOf('\n      })', callStart);
assert.ok(callStart >= 0 && callEnd > callStart);
const call = canvas.slice(callStart, callEnd);
assert.match(call, /photoImportLeaseActive: this\.photoImportBusy/);

for (const name of ['onDraftChange', 'onCancel', 'onConfirm']) {
  const callbackStart = call.indexOf(`${name}:`);
  assert.ok(callbackStart >= 0, `${name} exists`);
  const guardStart = call.indexOf('{', callbackStart);
  const guardEnd = call.indexOf('return;', guardStart);
  const guard = call.slice(guardStart, guardEnd);
  assert.match(guard, /this\.photoImportBusy/, `${name} rejects shared lease first`);
  assert.match(guard, /this\.historyBusy/, `${name} rejects history lease second`);
}

console.log('D02_OPEN_MATH_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=10 FAILED=0');
