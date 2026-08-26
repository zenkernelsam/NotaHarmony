import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/ImageCropOverlay.ets', 'utf8').replaceAll('\r\n', '\n');

assert.match(overlay, /@Prop photoImportLeaseActive: boolean = false;/);
assert.match(overlay, /private get controlsEnabled\(\): boolean \{\n    return !this\.photoImportLeaseActive;\n  \}/);
assert.equal(overlay.match(/\.enabled\(this\.controlsEnabled\)/g)?.length, 3);
assert.match(overlay,
  /\.onActionUpdate\(\(event: GestureEvent\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+const offsetX: number = event\.offsetX === undefined \? this\.dragOffsetX : event\.offsetX;/);

for (const action of ['onClose()', 'onReset()', 'onConfirm()']) {
  const forwardStart = overlay.indexOf(`this.${action}`);
  assert.ok(forwardStart >= 0, action);
  const clickStart = overlay.lastIndexOf('.onClick(() => {', forwardStart);
  assert.ok(clickStart >= 0, `${action} click bounds`);
  const body = overlay.slice(clickStart, forwardStart + action.length + 1);
  assert.match(body,
    /if \(!this\.controlsEnabled\) \{\s+return;\s+\}\s+/,
    `${action} rejects disabled controls`);
}

const callStart = canvas.indexOf('      ImageCropOverlay({');
const callEnd = canvas.indexOf('\n      })', callStart);
assert.ok(callStart >= 0 && callEnd > callStart);
const call = canvas.slice(callStart, callEnd);
assert.match(call, /photoImportLeaseActive: this\.photoImportBusy/);

for (const name of ['onMove', 'onClose', 'onReset', 'onConfirm']) {
  const callbackStart = call.indexOf(`${name}:`);
  assert.ok(callbackStart >= 0, `${name} exists`);
  const guardStart = call.indexOf('{', callbackStart);
  const guardEnd = call.indexOf('return;', guardStart);
  const guard = call.slice(guardStart, guardEnd);
  assert.match(guard, /this\.photoImportBusy/, `${name} rejects shared lease first`);
  assert.match(guard, /this\.historyBusy/, `${name} rejects history lease second`);
}

console.log('D02_OPEN_CROP_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=14 FAILED=0');
