import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const panel = fs.readFileSync(
  'note/src/main/ets/ui/editor/RecordingPanel.ets', 'utf8').replaceAll('\r\n', '\n');

assert.match(panel, /@Prop photoImportLeaseActive: boolean = false;/);
assert.equal(panel.match(/this\.controlsEnabled/g)?.length >= 10, true);
for (const token of [
  '.enabled(this.controlsEnabled)',
  '.enabled(this.controlsEnabled && this.canSeek())',
  '.enabled(this.controlsEnabled &&',
]) {
  assert.ok(panel.includes(token), `panel binds ${token}`);
}

const callStart = page.indexOf('        RecordingPanel({');
const callEnd = page.indexOf('\n      }\n\n      // 画布', callStart);
assert.ok(callStart >= 0 && callEnd > callStart);
const call = page.slice(callStart, callEnd);
assert.match(call, /photoImportLeaseActive: this\.photoImportLeaseActive/);

const callbackNames = [
  'onRecord', 'onPauseCapture', 'onResumeCapture', 'onStopCapture',
  'onToggle', 'onSeek', 'onSpeedChange', 'onDelete', 'onUndoDelete',
];
let cursor = call.indexOf('onRecord:');
for (const name of callbackNames) {
  const start = call.indexOf(`${name}:`, cursor);
  assert.ok(start >= 0, `${name} callback exists`);
  const bodyStart = call.indexOf('{', start);
  const guardEnd = call.indexOf('return;', bodyStart);
  const guard = call.slice(bodyStart, guardEnd);
  assert.ok(guard.includes('this.photoImportLeaseActive'), `${name} rejects shared lease`);
  assert.ok(guard.includes('this.pageStructureLeaseActive'), `${name} rejects structure lease`);
  cursor = start + name.length;
}

console.log(
  'D02_RECORDING_PANEL_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=12 FAILED=0');
