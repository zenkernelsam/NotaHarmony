import assert from 'node:assert/strict';
import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8').replaceAll('\r\n', '\n');
}

const colorPicker = read('note/src/main/ets/ui/components/ColorPicker.ets');
const widthSlider = read('note/src/main/ets/ui/components/WidthSlider.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');

assert.match(colorPicker,
  /@Prop photoImportLeaseActive: boolean = false;/);
assert.ok(
  (colorPicker.match(/\.enabled\(!this\.photoImportLeaseActive\)/g)?.length ?? 0) >= 1,
  'colorPicker interactive controls must disable under the shared lease');
assert.match(widthSlider,
  /@Prop photoImportLeaseActive: boolean = false;/);
assert.ok(
  (widthSlider.match(/\.enabled\(!this\.photoImportLeaseActive\)/g)?.length ?? 0) >= 1,
  'widthSlider interactive controls must disable under the shared lease');

for (const name of ['ColorPickerView', 'WidthSlider']) {
  const callStart = toolbar.indexOf(`${name}({`);
  assert.ok(callStart >= 0, name);
  const callEnd = toolbar.indexOf('\n          })', callStart);
  assert.ok(callEnd > callStart, `${name} call bounds`);
  const call = toolbar.slice(callStart, callEnd);
  assert.match(call, /photoImportLeaseActive: this\.photoImportLeaseActive/,
    `${name} receives the shared lease`);
}

// Every tap path in the picker rejects the shared lease first: the well-color and
// free-color handlers both open with the lease guard.
for (const handler of ['onWellColor', 'onFreeColor']) {
  const handlerStart = colorPicker.indexOf(`private ${handler}(`);
  assert.ok(handlerStart >= 0, `${handler} missing`);
  const guardEnd = colorPicker.indexOf('return;', handlerStart);
  assert.ok(guardEnd > handlerStart, `${handler} guard missing`);
  assert.match(colorPicker.slice(handlerStart, guardEnd),
    /if \(this\.photoImportLeaseActive\) \{/,
    `${handler} rejects shared lease first`);
}
assert.match(colorPicker,
  /if \(this\.selectionMode\) \{\s+this\.onSelectionColor\(color\);\s+\} else \{\s+this\.viewModel\.setBrushColor\(color\);/,
  'free-color path keeps selectionMode dispatch');
assert.match(widthSlider,
  /\.enabled\(!this\.photoImportLeaseActive\)\s+\.onChange\(\(value: number\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+if \(this\.selectionMode\) \{/);

const toolbarCallStart = notePage.indexOf('        EditorToolbar({');
assert.ok(toolbarCallStart >= 0);
const toolbarCallEnd = notePage.indexOf('\n        })', toolbarCallStart);
assert.ok(toolbarCallEnd > toolbarCallStart);
const toolbarCall = notePage.slice(toolbarCallStart, toolbarCallEnd);
assert.match(toolbarCall,
  /photoImportLeaseActive: this\.photoImportLeaseActive/);

for (const name of ['onSelectionColor', 'onSelectionWidth']) {
  const callbackStart = toolbarCall.indexOf(`${name}:`);
  assert.ok(callbackStart >= 0, name);
  const guardStart = toolbarCall.indexOf('{', callbackStart);
  const guardEnd = toolbarCall.indexOf('return;', guardStart);
  const guard = toolbarCall.slice(guardStart, guardEnd);
  assert.match(guard, /this\.photoImportLeaseActive/,
    `${name} rejects shared lease first`);
  assert.match(guard, /this\.pageOperationBusy/, `${name} keeps page lease`);
}

console.log('D02_TOOL_CONTROLS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=11 FAILED=0');
