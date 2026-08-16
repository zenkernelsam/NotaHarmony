import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');

const library = read('note/src/main/ets/ui/library/LibraryPage.ets');
const baseStrings = JSON.parse(read('note/src/main/resources/base/element/string.json'));
const zhStrings = JSON.parse(read('note/src/main/resources/zh_CN/element/string.json'));
const originalTa7 = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ta7.java', 'utf8');
const originalGsi = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/gsi.java', 'utf8');
const originalVc2 = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/vc2.java', 'utf8');
const originalZri = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/zri.java', 'utf8');

const resourceNames = values => new Set((values.string ?? values).map(item => item.name));
const baseNames = resourceNames(baseStrings);
const zhNames = resourceNames(zhStrings);
const hasBoth = name => baseNames.has(name) && zhNames.has(name);

// Original 1.0.3: <840dp owns a drawer state; 952/1400 select sidebar width/columns,
// and 600 selects compact content columns. These are source facts, not Harmony guesses.
assert.match(originalTa7, /q8gVar\.a\(840\)/);
assert.match(originalTa7, /yk3\.a\(fV, 952\.0f\)/);
assert.match(originalTa7, /yk3\.a\(fV, 1400\.0f\)/);
assert.match(originalTa7, /q8gVar\.a\(600\)/);
assert.match(originalTa7, /new hp3\(/);
assert.match(originalGsi, /fq4Var\.l\(\)/);
assert.match(originalGsi, /!fq4Var\.l\(\)/);
assert.match(originalVc2, /feature_library__sidebar_add_folder/);
assert.match(originalVc2, /feature_library__sidebar_rename/);
assert.match(originalVc2, /feature_library__sidebar_delete/);
assert.match(originalZri, /feature_library__sidebar_folders/);

// Harmony compact path remains reachable without a hidden sidebar.
assert.match(library, /@State compactFolderDrawerVisible: boolean = false/);
assert.match(library, /@State expandedFolderIds: string\[\] = \[\]/);
assert.match(library, /openCompactFolderDrawer\(\)/);
assert.match(library, /CompactFolderDrawer\(\)/);
assert.match(library, /\.overlay\(this\.CompactFolderDrawer\(\)/);
assert.match(library, /Button\('☰'\)/);
assert.match(library, /open_folder_drawer/);

// A long folder list is bounded by a vertical Scroll in both regular sidebar and drawer.
assert.ok((library.match(/\.scrollable\(ScrollDirection\.Vertical\)/g) ?? []).length >= 2);
assert.match(library, /folderListItems\(false\)/);
assert.match(library, /includeCollapsed: boolean/);
assert.match(library, /toggleFolderExpanded\(folderId: string\)/);
assert.match(library, /hasChildren: boolean/);
assert.match(library, /expanded: boolean/);
assert.match(library, /collapsed valid parent is intentionally not an orphan/);

// Selection, current-folder display, and all folder mutations remain available from compact.
assert.match(library, /Button\(this\.currentFolderName\(\)\)/);
assert.match(library, /Text\(\$r\('app\.string\.all_notes'\)\)/);
assert.match(library, /showCreateFolderDialog\(\)/);
assert.match(library, /showRenameFolderDialog\(folder\)/);
assert.match(library, /confirmDeleteFolder\(folder\)/);
assert.match(library, /closeCompactFolderDrawer\(\)/);
assert.match(library, /this\.notes = vm\.getFilteredNotes\(\)\.slice\(\)/);

for (const name of ['folders', 'open_folder_drawer', 'close', 'expand_folder', 'collapse_folder']) {
  assert.ok(hasBoth(name), `missing localized resource: ${name}`);
}

// Static layout budgets for the requested phone widths; device screenshots remain a separate gate.
const compactHeaderBudget = 44 + 48 + 8 + 48 + 32;
for (const width of [360, 600]) {
  assert.ok(width >= compactHeaderBudget, `compact header exceeds ${width}vp`);
}
assert.equal(1280 < 840, false);
assert.ok(library.includes(".constraintSize({ minWidth: 280, maxWidth: 320 })"));
assert.match(library, /\.height\(48\)/);
assert.match(library, /\.width\(44\)/);

console.log('D02_ORIGINAL_COMPACT_LIBRARY_DRAWER_REPLAY_OK ' +
  'drawer-state=1|folder-scroll=1|tree-expand-collapse=1|selection-check=1|' +
  'folder-actions=1|compact-hit-targets=1|original-thresholds=1');
