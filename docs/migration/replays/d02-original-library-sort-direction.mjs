import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');
const testFile = read('note/src/test/LibraryViewModel.test.ets');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const inh = readOriginal('decompiled_1.0.3/sources/defpackage/inh.java');
const vc2 = readOriginal('decompiled_1.0.3/sources/defpackage/vc2.java');
const pk9 = readOriginal('decompiled_1.0.3/sources/defpackage/pk9.java');
const z97 = readOriginal('decompiled_1.0.3/sources/defpackage/z97.java');
const he7 = readOriginal('decompiled_1.0.3/sources/defpackage/he7.java');
const je7 = readOriginal('decompiled_1.0.3/sources/defpackage/je7.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// he7 field enum: NAME / CREATED_DATE / MODIFIED_DATE.
ok(he7.includes('"NAME", 0') && he7.includes('"CREATED_DATE", 1') &&
   he7.includes('"MODIFIED_DATE", 2'),
  'original he7 field enum missing');
// je7 direction enum: ASCENDING / DESCENDING.
ok(je7.includes('"ASCENDING", 0') && je7.includes('"DESCENDING", 1'),
  'original je7 direction enum missing');
// z97 defaults: MODIFIED_DATE + DESCENDING persisted prefs.
ok(z97.includes('"MODIFIED_DATE"') && z97.includes('"DESCENDING"') &&
   z97.includes('sortDirection'),
  'original sort pref defaults missing');
// pk9.s: field comparators produce ascending lists (fh7(10)/fh7(11)/bg1
// collator) and DESCENDING reverses via au1.E1.
ok(pk9.includes('je7Var.ordinal()') &&
   pk9.includes('au1.E1(listK1)') &&
   pk9.includes('new fh7(10)') && pk9.includes('new fh7(11)'),
  'original pk9.s asc+reverse missing');
// inh.b: field chip (name/created/modified tld list) + a rotating
// direction arrow that dispatches the opposite je7.
ok(inh.includes('feature_library__name') &&
   inh.includes('feature_library__created_date') &&
   inh.includes('feature_library__modified_date') &&
   inh.includes('SortDirectionArrow') &&
   inh.includes('je7Var == je7Var2 ? je7.J : je7Var2'),
  'original sort chip + arrow missing');
// vc2 dropdown: field rows with check icon + divider + two direction rows
// whose labels are field-aware (A to Z vs Oldest to Newest).
ok(vc2.includes('general_check_med_reg') &&
   vc2.includes('feature_library__A_to_Z') &&
   vc2.includes('feature_library__Z_to_A') &&
   vc2.includes('feature_library__oldest_to_newest') &&
   vc2.includes('feature_library__newest_to_oldest'),
  'original sort dropdown rows missing');
ok(origStrings.includes('feature_library__sort') &&
   origStrings.includes('feature_library__cd_sort'),
  'original sort strings missing');

// --- Harmony anchors ----------------------------------------------------------------------
// VM: direction state defaulting to the z97 DESCENDING default.
ok(/sortDescending: boolean = true;/.test(vm),
  'sortDescending default missing');
// applySort: ascending comparators + reverse on descending (pk9.s parity).
ok(/a\.updatedAt - b\.updatedAt/.test(vm) &&
   /a\.createdAt - b\.createdAt/.test(vm) &&
   /a\.title\.localeCompare\(b\.title\)/.test(vm) &&
   /if \(this\.sortDescending\) \{\s*sorted\.reverse\(\);/.test(vm),
  'pk9.s asc+reverse parity missing');
// RECENT bypass retained (mk9 fixed ordering).
ok(/applySort\(\): void \{[\s\S]*?LibrarySection\.RECENT[\s\S]*?return;/.test(vm),
  'RECENT bypass missing');
// VM direction setter.
ok(vm.includes('setSortDescending(descending: boolean): void'),
  'setSortDescending missing');
// Page: direction pref key, load, and dual-key persistence.
ok(page.includes("PREF_SORT_DIR_KEY: string = 'library_sort_dir'") &&
   page.includes('vm.sortDescending = savedDir !== 0;') &&
   page.includes('pref.putSync(this.PREF_SORT_DIR_KEY, descending ? 1 : 0)'),
  'sort direction persistence missing');
// Page: guarded direction setter + arrow toggle delegating to it.
ok(/private setSortDescending\(descending: boolean\): void \{\s*if \(!this\.pageActive \|\| this\.viewModel === null\) \{\s*return;/.test(page) &&
   page.includes('this.setSortDescending(!this.viewModel.sortDescending);'),
  'direction toggle guard missing');
// UI: field-label chip + direction arrow button.
ok(page.includes('Button(this.sortFieldLabel())') &&
   page.includes("this.viewModel.sortDescending ? '↓' : '↑'") &&
   page.includes('this.toggleSortDirection();'),
  'sort chip + arrow button missing');
// Menu: 3 fields + 2 field-aware direction rows (vc2 parity).
ok(/buildSortMenuItems\(\): MenuElement\[\] \{[\s\S]*?sort_name[\s\S]*?sort_created_date[\s\S]*?sort_modified_date[\s\S]*?directions\[0\][\s\S]*?directions\[1\]/.test(page) &&
   page.includes("sort_a_to_z')") && page.includes("sort_z_to_a')") &&
   page.includes("sort_oldest_to_newest')") && page.includes("sort_newest_to_oldest')"),
  'sort menu items missing');
for (const name of ['sort_name', 'sort_created_date', 'sort_modified_date',
                    'sort_a_to_z', 'sort_z_to_a',
                    'sort_oldest_to_newest', 'sort_newest_to_oldest']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}
// Compact library-actions menu shares the same items.
ok(page.includes('const items: MenuElement[] = this.buildSortMenuItems();'),
  'compact menu sort items missing');
// Test fake coverage: direction exercised in the sort test.
ok(testFile.includes('setSortDescending(false)') &&
   testFile.includes('setSortDescending(true)'),
  'sort direction test missing');

// --- Executable model: pk9.s field asc + je7 reverse --------------------------------------
function applySort(notes, field, descending) {
  const sorted = notes.slice();
  if (field === 'MODIFIED_DATE') {
    sorted.sort((a, b) => a.updatedAt - b.updatedAt);
  } else if (field === 'CREATED_DATE') {
    sorted.sort((a, b) => a.createdAt - b.createdAt);
  } else {
    sorted.sort((a, b) => a.title.localeCompare(b.title));
  }
  if (descending) { sorted.reverse(); }
  return sorted.map(n => n.id);
}
const alpha = { id: 'alpha', title: 'Alpha', createdAt: 30, updatedAt: 10 };
const beta = { id: 'beta', title: 'Beta', createdAt: 10, updatedAt: 30 };
const gamma = { id: 'gamma', title: 'Gamma', createdAt: 20, updatedAt: 20 };
const notes = [gamma, beta, alpha];
// Default z97 state: MODIFIED_DATE + DESCENDING.
assert.deepEqual(applySort(notes, 'MODIFIED_DATE', true), ['beta', 'gamma', 'alpha']); checks++;
assert.deepEqual(applySort(notes, 'MODIFIED_DATE', false), ['alpha', 'gamma', 'beta']); checks++;
assert.deepEqual(applySort(notes, 'CREATED_DATE', true), ['alpha', 'gamma', 'beta']); checks++;
assert.deepEqual(applySort(notes, 'CREATED_DATE', false), ['beta', 'gamma', 'alpha']); checks++;
assert.deepEqual(applySort(notes, 'NAME', true), ['gamma', 'beta', 'alpha']); checks++;
assert.deepEqual(applySort(notes, 'NAME', false), ['alpha', 'beta', 'gamma']); checks++;

console.log(`D02_ORIGINAL_LIBRARY_SORT_DIRECTION_OK TOTAL=${checks} FAILED=0`);
