import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const panel = fs.readFileSync(
  'note/src/main/ets/ui/editor/RecordingPanel.ets', 'utf8').replaceAll('\r\n', '\n');

assert.match(panel, /@Prop photoImportLeaseActive: boolean = false;/);
assert.match(panel,
  /private get controlsEnabled\(\): boolean \{\s+return !this\.photoImportLeaseActive && !this\.loading;\s+\}/,
  'recording controls reject an in-flight recording list load');
assert.equal(panel.match(/this\.controlsEnabled/g)?.length >= 10, true);
for (const token of [
  '.enabled(this.controlsEnabled)',
  '.enabled(this.controlsEnabled && this.canSeek())',
  '.enabled(this.controlsEnabled &&',
]) {
  assert.ok(panel.includes(token), `panel binds ${token}`);
}

const guardedCallbacks = [
  'onClose', 'onSeek', 'onPauseCapture', 'onResumeCapture', 'onStopCapture',
  'onRecord', 'onSpeedChange', 'onToggle', 'onDelete', 'onUndoDelete',
];
for (const name of guardedCallbacks) {
  const callbackStart = panel.indexOf(`this.${name}(`);
  assert.ok(callbackStart >= 0, `${name} invocation exists`);
  const guardStart = panel.lastIndexOf('.onClick(() => {', callbackStart);
  const guardEnd = panel.indexOf('this.on' + name.slice(2), callbackStart);
  assert.ok(guardStart >= 0 && guardEnd > guardStart, `${name} guard bounds`);
  const guard = panel.slice(guardStart, guardEnd);
  assert.match(guard,
    name === 'onClose' ?
      /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}/ :
      /if \(this\.photoImportLeaseActive \|\| this\.loading\) \{\s+return;\s+\}/,
    `${name} rejects the active panel boundary before forwarding`);
}

assert.equal(
  panel.match(/if \(this\.photoImportLeaseActive \|\| this\.loading\) \{\s+return;\s+\}/g)?.length,
  9,
  'nine recording actions reject list loading');
assert.equal(
  panel.match(/if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}/g)?.length,
  1,
  'close remains available while list loading');

const controlsEnabled = (photoImportLeaseActive, loading) =>
  !photoImportLeaseActive && !loading;
assert.equal(controlsEnabled(false, true), false,
  'loading blocks recording actions');
assert.equal(controlsEnabled(false, false), true,
  'idle panel keeps recording actions enabled');

const callStart = page.indexOf('        RecordingPanel({');
const callEnd = page.indexOf('\n      }\n\n      // 画布', callStart);
assert.ok(callStart >= 0 && callEnd > callStart);
const call = page.slice(callStart, callEnd);
assert.match(call, /photoImportLeaseActive: this\.photoImportLeaseActive/);
const topBarEnd = page.indexOf('      // 工具栏');
assert.ok(topBarEnd > 0);
assert.match(page.slice(0, topBarEnd),
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+if \(this\.showRecordings\) \{\s+this\.closeRecordings\(\);\s+\} else \{\s+this\.showRecordings = true;/,
  'recordings toggle rejects shared lease before changing visibility');

const callbackNames = [
  'onRecord', 'onPauseCapture', 'onResumeCapture', 'onStopCapture',
  'onToggle', 'onSeek', 'onSpeedChange', 'onDelete', 'onUndoDelete', 'onClose',
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
  'D02_RECORDING_PANEL_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=29 FAILED=0');
