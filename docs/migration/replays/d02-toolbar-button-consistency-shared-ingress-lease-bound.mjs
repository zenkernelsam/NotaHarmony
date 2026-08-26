import assert from 'node:assert/strict';
import fs from 'node:fs';

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function section(startMarker, endMarker) {
  const start = toolbar.indexOf(startMarker);
  assert.ok(start >= 0, startMarker);
  const end = toolbar.indexOf(endMarker, start);
  assert.ok(end > start, `${startMarker} bounds`);
  return toolbar.slice(start, end);
}

const photoButton = section("Button($r('app.string.insert_photo'))", "Button($r('app.string.insert_math'))");
const mathButton = section("Button($r('app.string.insert_math'))", '\n          Divider().vertical(true)');
const undoButton = section("Button('↶')", "Button('↷')");
const redoButton = toolbar.slice(toolbar.indexOf("Button('↷')"), toolbar.indexOf('\n        }\n        .height(48)', toolbar.indexOf("Button('↷')")));

for (const [name, button] of [['photo', photoButton], ['math', mathButton]]) {
  assert.match(button,
    /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/,
    name);
}
assert.match(undoButton,
  /\.enabled\(this\.canUndo &&\s+!this\.photoImportLeaseActive\)/);
assert.match(redoButton,
  /\.enabled\(this\.canRedo &&\s+!this\.photoImportLeaseActive\)/);

console.log(
  'D02_TOOLBAR_BUTTON_CONSISTENCY_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
