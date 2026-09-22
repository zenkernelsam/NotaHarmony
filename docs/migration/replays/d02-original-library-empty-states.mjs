import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const hf0 = readOriginal('decompiled_1.0.3/sources/defpackage/hf0.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');
const origPlurals = readOriginal('decompiled_1.0.3/resources/res/values/plurals.xml');

// hf0: per-descriptor empty states — folders (sw3/uw3) show body only,
// sections show title+body; icons per descriptor family.
ok(hf0.includes('feature_library__empty_folder_body') &&
   hf0.includes('feature_library__empty_folder_with_children_body') &&
   hf0.includes('feature_library__lets_get_started') &&
   hf0.includes('feature_library__empty_recent_notes_title') &&
   hf0.includes('feature_library__empty_favorite_notes_title') &&
   hf0.includes('feature_library__empty_unfiled_notes_title') &&
   hf0.includes('feature_library__empty_shared_notes_title'),
  'original empty-state dispatch missing');
// uw3 renders pluralized counts; folders get no title row (b(null,...)).
ok(hf0.includes('empty_folder_subfolder_count') &&
   hf0.includes('empty_folder_note_count') &&
   hf0.includes('b(null, R.string.feature_library__empty_folder_body'),
  'original folder empty-state shape missing');
ok(origPlurals.includes('empty_folder_subfolder_count') &&
   origPlurals.includes('empty_folder_note_count'),
  'original count plurals missing');
for (const s of ['lets_get_started', 'tap_on_the_create_button_to_create_new_notes',
                 'empty_folder_body', 'empty_recent_notes_title',
                 'empty_unfiled_notes_title']) {
  ok(origStrings.includes(`feature_library__${s}`),
    `original string ${s} missing`);
}

// --- Harmony anchors ----------------------------------------------------------------------
// Per-section title/body/icon helpers.
ok(page.includes('private emptyStateIcon()') &&
   page.includes('private emptyStateHasTitle()') &&
   page.includes('private emptyStateTitle()') &&
   page.includes('private emptyStateBody()'),
  'empty-state helpers missing');
// Folder: no title (emptyStateHasTitle false when a folder is selected).
ok(/emptyStateHasTitle\(\): boolean \{\s*return this\.currentFolderId === null;/.test(page),
  'folder title suppression missing');
// Folder with children -> counted body variant.
ok(/f\.parentId === this\.currentFolderId\)\.length/.test(page) &&
   page.includes("empty_folder_with_children_body',") &&
   page.includes("empty_folder_with_child_body',"),
  'with-children empty body missing');
// Sections map to their dedicated strings.
ok(/emptyStateBody[\s\S]*?empty_favorite_notes_body[\s\S]*?empty_recent_notes_body[\s\S]*?empty_unfiled_notes_body[\s\S]*?tap_to_create_notes/.test(page),
  'section empty-state mapping missing');
// Search-active keeps the generic no-results text.
ok(/if \(this\.searchText\.trim\(\)\.length > 0\) \{\s*Text\(\$r\('app\.string\.no_matching_notes'\)\)/.test(page),
  'search empty-state guard missing');
for (const name of ['lets_get_started', 'tap_to_create_notes',
                    'empty_folder_body', 'empty_folder_with_children_body',
                    'empty_folder_with_child_body',
                    'empty_recent_notes_title', 'empty_recent_notes_body',
                    'empty_unfiled_notes_title', 'empty_unfiled_notes_body']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}
// EN values match the originals.
ok(stringsBase.includes("Let's get started!") &&
   stringsBase.includes('Access your most recently opened notes.') &&
   stringsBase.includes("You've filed all your notes. Time to make some new ones."),
  'EN empty-state values diverge from the original');

console.log(`D02_ORIGINAL_LIBRARY_EMPTY_STATES_OK TOTAL=${checks} FAILED=0`);
