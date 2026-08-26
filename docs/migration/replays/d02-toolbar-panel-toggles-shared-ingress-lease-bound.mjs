import assert from 'node:assert/strict';
import fs from 'node:fs';

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function buttonSection(startMarker, endMarker) {
  const start = toolbar.indexOf(startMarker);
  assert.ok(start >= 0, startMarker);
  const end = toolbar.indexOf(endMarker, start);
  assert.ok(end > start, `${startMarker} bounds`);
  return toolbar.slice(start, end);
}

const colorToggle = buttonSection('        // 颜色按钮', '\n\n        // 粗细按钮');
const widthToggle = buttonSection('        // 粗细按钮', '\n\n        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })\n\n        if (!this.compact)');

for (const [name, section] of [['color toggle', colorToggle], ['width toggle', widthToggle]]) {
  assert.match(section,
    /\.enabled\(\(this\.viewModel\.supportsBrushControls\(\) \|\| this\.viewModel\.isSelectionActive\(\)\) &&\s+!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/,
    name);
  assert.match(section,
    /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}/,
    name);
}

assert.match(colorToggle,
  /this\.viewModel\.showColorPicker = !this\.viewModel\.showColorPicker;\s+this\.viewModel\.showWidthSlider = false;/);
assert.match(widthToggle,
  /this\.viewModel\.showWidthSlider = !this\.viewModel\.showWidthSlider;\s+this\.viewModel\.showColorPicker = false;/);

console.log('D02_TOOLBAR_PANEL_TOGGLES_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
