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
const compactMenu = toolbar.slice(
  toolbar.indexOf('  private buildCompactToolMenu()'),
  toolbar.indexOf('\n  }\n', toolbar.indexOf('  private buildCompactToolMenu()')));

for (const action of ['insert_photo', 'insert_math']) {
  assert.match(compactMenu,
    new RegExp(`\\{ value: \\$r\\('app\\.string\\.${action}'\\), action: \\(\\) => \\{\\s+if \\(this\\.photoImportLeaseActive\\) \\{\\s+return;\\s+\\}\\s+this\\.on`),
    action);
}

for (const [name, section] of [['tool', toolButton], ['style', styleButton]]) {
  assert.match(section,
    /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/,
    name);
}
assert.match(toolButton,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.selectTool\(tool\);/);
assert.match(styleButton,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.setBrushStyle\(style\);/);

for (const [action, forward] of [
  ['insert_photo', 'onInsertPhotos()'],
  ['insert_math', 'onInsertMath()'],
]) {
  const buttonStart = toolbar.indexOf(`Button($r('app.string.${action}'))`);
  assert.ok(buttonStart >= 0, action);
  const bodyEnd = toolbar.indexOf('\n          Divider()', buttonStart);
  assert.ok(bodyEnd > buttonStart, `${action} bounds`);
  const body = toolbar.slice(buttonStart, bodyEnd);
  assert.match(body,
    new RegExp(`\\.onClick\\(\\(\\) => \\{\\s+if \\(this\\.photoImportLeaseActive\\) \\{\\s+return;\\s+\\}\\s+this\\.${forward.replace('(', '\\(').replace(')', '\\)')}`),
    `${action} callback guard`);
}

console.log(
  'D02_TOOLBAR_BUILDERS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=6 FAILED=0');
