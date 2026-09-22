import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const repo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
// d5j.java — the note-card context menu, in original order.
const d5j = readOriginal('decompiled_1.0.3/sources/defpackage/d5j.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');
const lineOf = (s, needle) => s.indexOf(needle);
// Positional order check: rename < favorite < duplicate < export <
// show_in_folder < sort_to_folder < copy_note_id < report < delete.
const order = [
  'feature_library__sidebar_rename',
  'feature_library__favorite',
  'feature_library__duplicate',
  'feature_library__export',
  'feature_library__show_in_folder',
  'feature_library__sort_to_folder',
  'feature_library__copy_note_id',
  'feature_library__report_note',
  'feature_library__sidebar_delete',
];
let last = -1;
for (const key of order) {
  const at = lineOf(d5j, `R.string.${key}`);
  assert.ok(at > last, `original menu order broken at ${key} (at=${at}, last=${last})`);
  last = at;
  checks++;
}
ok(d5j.includes('R.string.feature_library__unfavorite'),
  'original unfavorite label missing');
ok(d5j.includes('feature_library__export_options') &&
   d5j.includes('feature_library__open_in_new_window'),
  'original export-options/new-window items missing');
for (const key of ['feature_library__duplicate', 'feature_library__export',
  'feature_library__show_in_folder', 'feature_library__copy_note_id']) {
  ok(origStrings.includes(`name="${key}"`), `original string ${key} missing`);
}

// --- Harmony anchors ---------------------------------------------------------------------
// Menu order in NoteContextMenu mirrors d5j (non-portable items registered).
const menu = page.slice(page.indexOf('NoteContextMenu(note: NoteMeta)'),
  page.indexOf('MoveNoteSubMenu(note: NoteMeta)'));
const harmonyOrder = [
  "$r('app.string.rename')",
  'favorite_note',
  "$r('app.string.duplicate_note')",
  "$r('app.string.export_note')",
  "$r('app.string.show_in_folder')",
  'move_to_folder',
  "$r('app.string.copy_note_id')",
  "$r('app.string.delete')",
];
last = -1;
for (const key of harmonyOrder) {
  const at = menu.indexOf(key);
  assert.ok(at > last, `harmony menu order broken at ${key} (at=${at}, last=${last})`);
  last = at;
  checks++;
}
ok(menu.includes('.enabled(note.folderId !== null)'),
  'show-in-folder must be disabled for unfiled notes');
// Rename path: page dialog -> vm.renameNote -> repo.renameNote -> updateNoteTitle
// (original SET_TITLE op path).
ok(page.includes('this.showRenameNoteDialog(note)') &&
   page.includes('vm.renameNote(this.noteDialogNoteId, name.trim())'),
  'rename wiring missing');
ok(vm.includes('async renameNote(noteId: string, title: string)') &&
   vm.includes('this.repo.renameNote(noteId, title)'),
  'renameNote VM path missing');
ok(iface.includes('renameNote(noteId: string, title: string): Promise<void>') &&
   repo.includes('async renameNote(noteId: string, title: string)') &&
   repo.includes('this.updateNoteTitle(noteId, title.length === 0 ? null : title)'),
  'renameNote repository path missing');
// Duplicate: lossless package round-trip.
ok(page.includes('exporter.exportNote(note.id)') &&
   page.includes('importer.importFromData(data)') &&
   page.includes('new NoteExporter(this.db, this.persistence)') &&
   page.includes('new NoteImporter(this.db, this.persistence)'),
  'duplicate export->import path missing');
// Export: single-note package via the existing exporter.
ok(page.includes('exporter.exportToFile(context, note.id, note.title)'),
  'export wiring missing');
// Show in folder: navigates via setFolder (resets dk9 section like the
// original subject pick).
ok(vm.includes('async showNoteInFolder(note: NoteMeta, query: string)') &&
   vm.includes('this.setFolder(note.folderId, query)'),
  'show-in-folder VM path missing');
ok(page.includes('this.currentFolderId = vm.currentFolderId'),
  'show-in-folder must sync page folder state');
// Copy note ID: pasteboard write.
ok(page.includes("import { BusinessError, pasteboard } from '@kit.BasicServicesKit'") &&
   page.includes('pasteboard.createPlainTextData(note.id)') &&
   page.includes('pasteboard.getSystemPasteboard().setData(data)'),
  'copy-note-id pasteboard path missing');
// NameDialog decoration gate: folder dialog passes showDecoration, note
// rename dialog does not.
ok(page.includes('showDecoration: boolean = false') &&
   page.includes('showDecoration: true') &&
   /if \(this\.showDecoration\)\s*\{\s*Row\(\)/.test(page),
  'NameDialog decoration gate missing');
// Strings in both locales.
for (const name of ['duplicate_note', 'export_note', 'export_done',
  'show_in_folder', 'copy_note_id', 'note_id_copied', 'note_duplicated',
  'duplicate_failed', 'rename_failed']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}

// --- Executable model: menu order ------------------------------------------------------------
const originalMenu = ['rename', 'favorite', 'duplicate', 'export',
  'export_options', 'open_in_new_window', 'show_in_folder', 'sort_to_folder',
  'copy_note_id', 'report_note', 'delete'];
const portable = new Set(['rename', 'favorite', 'duplicate', 'export',
  'show_in_folder', 'sort_to_folder', 'copy_note_id', 'delete']);
const expected = originalMenu.filter((item) => portable.has(item));
assert.deepEqual(expected, ['rename', 'favorite', 'duplicate', 'export',
  'show_in_folder', 'sort_to_folder', 'copy_note_id', 'delete']); checks++;

console.log(`D02_ORIGINAL_NOTE_CONTEXT_MENU_OK TOTAL=${checks} FAILED=0`);
