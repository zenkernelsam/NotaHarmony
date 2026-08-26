import assert from 'node:assert/strict';
import fs from 'node:fs';

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

const moreButtonStart = toolbar.indexOf("            Button('...')");
const moreButtonEnd = toolbar.indexOf('\n          } else {', moreButtonStart);
const moreButton = toolbar.slice(moreButtonStart, moreButtonEnd);
assert.match(moreButton, /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/);

function builderSection(name) {
  const start = toolbar.indexOf(`  ${name}(`);
  assert.ok(start >= 0, name);
  return toolbar.slice(start, toolbar.indexOf('\n  }\n', start));
}

const toolButton = builderSection('ToolButton');
assert.match(toolButton,
  /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/);
assert.match(toolButton, /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.selectTool\(tool\);/);

const styleButton = builderSection('StyleButton');
assert.match(styleButton,
  /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/);
assert.match(styleButton, /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.setBrushStyle\(style\);/);

const selectionStyleButton = builderSection('SelectionStyleButton');
assert.match(selectionStyleButton,
  /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive &&/);

const freehandStart = toolbar.indexOf('            Button(this.viewModel.selectionIsFreehand');
const freehandEnd = toolbar.indexOf('\n          }', freehandStart);
const freehandButton = toolbar.slice(freehandStart, freehandEnd);
assert.match(freehandButton,
  /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/);

for (const tool of ['WHOLE_ERASER', 'PARTIAL_ERASER', 'SELECTION', 'DEFAULT']) {
  const actionStart = toolbar.indexOf(`this.viewModel.selectTool(ToolType.${tool});`, 0);
  assert.ok(actionStart >= 0, tool);
  const guardStart = toolbar.lastIndexOf('{ value:', actionStart);
  const action = toolbar.slice(guardStart, actionStart);
  assert.match(action, /action: \(\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}/, tool);
}

console.log('D02_TOOLBAR_DIRECT_MUTATIONS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=11 FAILED=0');
