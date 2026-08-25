import assert from 'node:assert/strict';
import fs from 'node:fs';

const page = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');

for (const [label, propertyName] of [
  ['style', 'onSelectionStyle'],
  ['color', 'onSelectionColor'],
  ['width', 'onSelectionWidth'],
]) {
  const start = page.indexOf(`          ${propertyName}: `);
  const end = page.indexOf('\n          },\n', start) + '\n          },\n'.length;
  assert.ok(start >= 0 && end > start, `${label} callback`);
  const body = page.slice(start, end);
  const guardStart = body.indexOf('if (this.');
  const guardEnd = body.indexOf('return;', guardStart);
  assert.ok(guardStart >= 0 && guardEnd > guardStart, `${label} guard`);
  const guard = body.slice(guardStart, guardEnd);
  for (const [name, token] of [
    ['photo ingress lease', 'this.photoImportLeaseActive'],
    ['page operation lease', 'this.pageOperationBusy'],
    ['history pending lease', 'this.historyPending'],
    ['page structure lease', 'this.pageStructureLeaseActive'],
  ]) {
    assert.ok(guard.includes(token), `${label} checks ${name}`);
  }
}

for (const [label, methodName] of [
  ['style', 'modifySelectedInkStyle'],
  ['color', 'modifySelectedInkColor'],
  ['width', 'modifySelectedInkWidth'],
]) {
  const start = canvas.indexOf(`  onSelection${'Style|Color|Width'}SignalChange`.replace('Style|Color|Width', label[0].toUpperCase() + label.slice(1)));
  assert.ok(start >= 0, `${label} watcher`);
  const body = canvas.slice(start, start + 500);
  const guardStart = body.indexOf('if (!this.photoImportBusy');
  const publishIndex = body.indexOf(methodName);
  assert.ok(guardStart >= 0 && publishIndex > guardStart, `${label} watcher order`);
  for (const token of [
    '!this.photoImportBusy',
    '!this.historyBusy',
    '!this.dataLoading',
    '!this.dataLoadFailed',
    'this.loaded',
    'this.loadedPageId === this.currentPage.pageId',
  ]) {
    assert.ok(body.includes(token), `${label} watcher checks ${token}`);
  }
}

const modifyStart = canvas.indexOf('  private modifySelectedInkRegisters(');
const modifyBody = canvas.slice(modifyStart, canvas.indexOf('\n  }\n', modifyStart));
assert.match(modifyBody,
  /if \(this\.historyBusy \|\| !this\.loaded \|\| !this\.viewModel\.isSelectionActive\(\)\) \{\s+return;\s+\}/);

console.log('D02_SELECTION_STYLE_SHARED_LEASE_BOUND_REPLAY_OK TOTAL=15 FAILED=0');
