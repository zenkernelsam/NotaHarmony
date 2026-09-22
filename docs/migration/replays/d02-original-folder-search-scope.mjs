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

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const bk9 = readOriginal('decompiled_1.0.3/sources/defpackage/bk9.java');
const mhh = readOriginal('decompiled_1.0.3/sources/defpackage/mhh.java');
const yj9 = readOriginal('decompiled_1.0.3/sources/defpackage/yj9.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// bk9 = FolderFilter(name, isShowingAllNotes).
ok(bk9.includes('FolderFilter(name=') && bk9.includes('isShowingAllNotes='),
  'original FolderFilter missing');
// mhh: "Show results for all notes" label + switch (e9e.a) bound to bk9.b.
ok(mhh.includes('feature_library__search_show_all_notes') &&
   mhh.includes('bk9Var.b'),
  'original search-all toggle missing');
// yj9:852 placeholder is "Search in {folder}" when a folder is selected;
// folder-filter-toggle chip renders in the list controls when search active.
ok(yj9.includes('feature_library__search_in_folder') &&
   yj9.includes('folder-filter-toggle'),
  'original folder search surface missing');
ok(origStrings.includes('Search in \\"%s\\"') &&
   origStrings.includes('Show results for all notes'),
  'original search scope strings missing');

// --- Harmony anchors ----------------------------------------------------------------------
// VM: searchAllNotes flag, reset on folder/section change, and the
// queryNotes widening branch (folder search -> all notes).
ok(vm.includes('searchAllNotes: boolean = false;') &&
   /this\.searchAllNotes = false;[\s\S]*?await this\.loadNotes\(query\)/.test(vm) &&
   /if \(this\.searchAllNotes && folderId !== null\) \{\s*return this\.repo\.searchNotes\(query, null\);/.test(vm) &&
   vm.includes('async setSearchAllNotes(searchAll: boolean, query: string)'),
  'VM search-all scope missing');
// Page: folder-aware placeholder helper.
ok(/searchPlaceholder\(\): Resource \{[\s\S]*?search_in_folder', folder\.name[\s\S]*?search_notes'\)/.test(page) &&
   page.includes('placeholder: this.searchPlaceholder()'),
  'folder-aware search placeholder missing');
// Page: toggle row rendered only during an active folder search.
ok(/if \(this\.currentFolderId !== null && this\.searchText\.trim\(\)\.length > 0\) \{[\s\S]*?search_show_all_notes[\s\S]*?Toggle\(\{ type: ToggleType\.Switch[\s\S]*?this\.setSearchAllNotes\(on\)/.test(page),
  'search-all toggle row missing');
// Page: guarded scope setter riding the notes-request generation.
ok(/private setSearchAllNotes\(on: boolean\): void \{\s*const vm[\s\S]*?!this\.pageActive \|\| vm === null[\s\S]*?beginNotesRequest\(\)[\s\S]*?vm\.setSearchAllNotes\(on, query\)/.test(page),
  'search-all setter guards missing');
for (const name of ['search_in_folder', 'search_show_all_notes']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}

// --- Executable model: folder scope vs widened scope --------------------------------------
const notes = [
  { id: 'in-folder-hit', folder: 'f1', text: 'recipe cake' },
  { id: 'in-folder-miss', folder: 'f1', text: 'other' },
  { id: 'all-hit', folder: 'f2', text: 'recipe soup' },
];
function query(list, query, folderId, searchAll) {
  if (query.trim().length === 0) {
    return folderId === null ? list : list.filter(n => n.folder === folderId);
  }
  const scope = searchAll && folderId !== null ? null : folderId;
  return list.filter(n => (scope === null || n.folder === scope) &&
    n.text.includes(query));
}
assert.deepEqual(query(notes, 'recipe', 'f1', false).map(n => n.id), ['in-folder-hit']); checks++;
assert.deepEqual(query(notes, 'recipe', 'f1', true).map(n => n.id),
  ['in-folder-hit', 'all-hit']); checks++;
assert.deepEqual(query(notes, 'recipe', null, false).map(n => n.id),
  ['in-folder-hit', 'all-hit']); checks++;
// Empty query keeps folder scoping regardless of the toggle.
assert.deepEqual(query(notes, '', 'f1', true).map(n => n.id),
  ['in-folder-hit', 'in-folder-miss']); checks++;

console.log(`D02_ORIGINAL_FOLDER_SEARCH_SCOPE_OK TOTAL=${checks} FAILED=0`);
