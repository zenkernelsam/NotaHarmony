import assert from 'node:assert/strict';
import fs from 'node:fs';

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function builderSection(name) {
  const start = toolbar.indexOf(`  ${name}(`);
  assert.ok(start >= 0, name);
  return toolbar.slice(start, toolbar.indexOf('\n  }\n', start));
}

const toolButton = builderSection('ToolButton');
const styleButton = builderSection('StyleButton');

for (const [name, section] of [['tool', toolButton], ['style', styleButton]]) {
  assert.match(section,
    /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/,
    name);
}
assert.match(toolButton,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.selectTool\(tool\);/);
assert.match(styleButton,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.setBrushStyle\(style\);/);

console.log(
  'D02_TOOLBAR_BUILDERS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=4 FAILED=0');
