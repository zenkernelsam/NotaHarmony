import assert from 'node:assert/strict';
import fs from 'node:fs';

const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');

function builderSection(name) {
  const start = toolbar.indexOf(`  ${name}(`);
  assert.ok(start >= 0, name);
  return toolbar.slice(start, toolbar.indexOf('\n  }\n', start));
}

const toolButton = builderSection('StateToolButton');
const eraserButtons = builderSection('EraserToolButtons');
const styleButton = builderSection('StyleButton');
const compactMenu = toolbar.slice(
  toolbar.indexOf('  private buildCompactToolMenu()'),
  toolbar.indexOf('\n  }\n', toolbar.indexOf('  private buildCompactToolMenu()')));

for (const action of ['insert_photo', 'insert_math']) {
  assert.match(compactMenu,
    new RegExp(`\\{ value: \\$r\\('app\\.string\\.${action}'\\), icon: [^,]+, action: \\(\\) => \\{\\s+if \\(this\\.photoImportLeaseActive\\) \\{\\s+return;\\s+\\}\\s+this\\.on`),
    action);
}

for (const [name, section] of [['tool', toolButton], ['eraser', eraserButtons],
                               ['style', styleButton]]) {
  assert.match(section,
    /\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)/,
    name);
}
assert.match(toolButton,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.selectToolById\(tool\.toolId\);/);
assert.match(eraserButtons,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.selectToolById\(tool\.toolId\)/);
assert.match(styleButton,
  /if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.viewModel\.setBrushStyle\(style\);/);

// Inline insert buttons now render via InsertButton(icon+label); the
// photoImportLeaseActive guard lives inside InsertButton, callback forwarded.
assert.match(toolbar,
  /private InsertButton[\s\S]*?\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)[\s\S]*?if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+onTap\(\)/,
  'InsertButton keeps enabled + lease guard');
for (const [action, forward] of [
  ['insert_photo', 'onInsertPhotos()'],
  ['insert_math', 'onInsertMath()'],
]) {
  assert.match(toolbar,
    new RegExp(`InsertButton\\(\\$r\\('app\\.string\\.${action}'\\), \\$r\\('app\\.media\\.[a-z_]+'\\),\\s*\\(\\) => this\\.${forward.replace('(', '\\(').replace(')', '\\)')}`),
    `${action} InsertButton forwards ${forward}`);
}

console.log(
  'D02_TOOLBAR_BUILDERS_SHARED_INGRESS_LEASE_BOUND_REPLAY_OK TOTAL=8 FAILED=0');
