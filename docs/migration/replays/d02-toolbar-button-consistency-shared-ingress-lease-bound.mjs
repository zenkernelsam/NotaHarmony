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

const undoButton = section("glyph: 'topnavundo'", "glyph: 'topnavredo'");
const redoButton = toolbar.slice(toolbar.indexOf("glyph: 'topnavredo'"), toolbar.indexOf('\n        }\n        .height(48)', toolbar.indexOf("glyph: 'topnavredo'")));

// Inline insert buttons render via InsertButton(icon+label); the shared
// enabled + photoImportLeaseActive guard lives inside the InsertButton builder.
assert.match(toolbar,
  /this\.InsertButton\(\$r\('app\.string\.insert_photo'\)[\s\S]*?this\.InsertButton\(\$r\('app\.string\.insert_math'\)/,
  'insert_photo and insert_math InsertButtons present');
assert.match(toolbar,
  /private InsertButton[\s\S]*?\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/,
  'InsertButton enabled guard');
assert.match(undoButton,
  /\.enabled\(this\.canUndo &&\s+!this\.photoImportLeaseActive\)/);
assert.match(redoButton,
  /\.enabled\(this\.canRedo &&\s+!this\.photoImportLeaseActive\)/);

console.log(
  'D02_TOOLBAR_BUTTON_CONSISTENCY_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
