import assert from 'node:assert/strict';
import fs from 'node:fs';

const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const overlay = fs.readFileSync(
  'note/src/main/ets/ui/components/TextBlockOverlay.ets', 'utf8').replaceAll('\r\n', '\n');

assert.match(overlay, /@Prop photoImportLeaseActive: boolean = false;/);
assert.equal(overlay.match(/\.enabled\(!this\.photoImportLeaseActive\)/g)?.length, 5);

assert.match(overlay,
  /\.onChange\(\(value: string\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.draftText = value;/);
assert.match(overlay,
  /\.onClick\(async \(\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+if \(await this\.onCommit\(this\.draftText, this\.computeParagraphRuns\(\)\)\) \{/);
assert.match(overlay,
  /\.onClick\(\(\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.draftText = '';/);

const callStart = canvas.indexOf('      TextBlockOverlay({');
const callEnd = canvas.indexOf('\n      })', callStart);
assert.ok(callStart >= 0 && callEnd > callStart);
const call = canvas.slice(callStart, callEnd);
assert.match(call, /photoImportLeaseActive: this\.photoImportBusy/);

const beginTextEdit = canvas.slice(
  canvas.indexOf('  private beginTextEditingAt('),
  canvas.indexOf('\n  }\n', canvas.indexOf('  private beginTextEditingAt(')));
assert.match(beginTextEdit,
  /if \(this\.photoImportBusy \|\| this\.historyBusy\) \{\s+return;\s+\}/);

for (const name of ['onDraftChange', 'onCancel']) {
  const callbackStart = call.indexOf(`${name}:`);
  assert.ok(callbackStart >= 0, `${name} exists`);
  const guardStart = call.indexOf('{', callbackStart);
  const guardEnd = call.indexOf('return;', guardStart);
  const guard = call.slice(guardStart, guardEnd);
  assert.match(guard, /this\.photoImportBusy/, `${name} rejects shared lease first`);
  assert.match(guard, /this\.historyBusy/, `${name} rejects history lease second`);
}

console.log('D02_OPEN_TEXT_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=13 FAILED=0');
