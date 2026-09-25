import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const types = read('note/src/main/ets/core/model/NoteTypes.ets');
const noteRepo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const folderRepo = read('note/src/main/ets/data/FolderRepositoryImpl.ets');
const db = read('note/src/main/ets/data/DatabaseHelper.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const vmFixture = read('note/src/test/LibraryViewModel.test.ets');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors --------------------------------------------------------
const w09 = readOriginal('decompiled_1.0.3/sources/defpackage/w09.java');
const cti = readOriginal('decompiled_1.0.3/sources/defpackage/cti.java');
const e5j = readOriginal('decompiled_1.0.3/sources/defpackage/e5j.java');
const i2j = readOriginal('decompiled_1.0.3/sources/defpackage/i2j.java');
const kkf = readOriginal('decompiled_1.0.3/sources/defpackage/kkf.java');
const w3j = readOriginal('decompiled_1.0.3/sources/defpackage/w3j.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// w09.java — the merged library note projection carries folderName (g) and
// folderColor (h, nullable Integer) alongside folderId (f).
ok(w09.includes(', folderName=') && w09.includes(', folderColor=') &&
   w09.includes('public final String g;') && w09.includes('public final Integer h;'),
  'original w09 folderName/folderColor fields missing');
// cti.c — the card renders the chip only when BOTH name and color are non-null;
// recordings show a mic icon (w09.l -> record_mic_outline), shared notes a
// shared outline (w09.k).
ok(cti.includes('Integer num = w09Var.h') && cti.includes('String str = w09Var.g') &&
   cti.includes('if (str == null || num == null)') && cti.includes('e5j.b(str, num, uz4Var, 0)'),
  'original cti.c chip condition missing');
ok(cti.includes('ui_designsystem__record_mic_outline') &&
   cti.includes('R.string.feature_library__recordings'),
  'original recordings mic icon missing');
// e5j.b delegates to i2j.b; i2j.b = 0.5dp folder-color border + solid
// folder-color background (w3j.c alpha=1.0) + name text.
ok(e5j.includes('i2j.b(num.intValue(), i2 & 126, uz4Var, str)'),
  'original e5j.b -> i2j.b delegate missing');
ok(i2j.includes('iu1.b(0.5f, kkf.d(i))') && i2j.includes('w3j.c(') &&
   i2j.includes('1.0f, kkf.d(i)') && i2j.includes('tpe.b(str,'),
  'original i2j.b chip pill missing');
ok(kkf.includes('((long) i2) << 32'), 'original int->Color packing missing');
ok(w3j.includes('new d01(f, kldVar, n4dVar)'),
  'original solid color background element missing');
ok(origStrings.includes('feature_library__recordings'),
  'original recordings label missing');

// --- Harmony model anchors -------------------------------------------------------------
ok(types.includes('folderName: string | null;') && types.includes('folderColor: number | null;'),
  'NoteMeta w09.g/h projection fields missing');
// Repository: one batched folder lookup attaches the projection to every list.
ok(noteRepo.includes('private async attachFolderProjection') &&
   noteRepo.includes('SELECT id, name, color FROM folder WHERE id IN'),
  'attachFolderProjection missing');
eq((noteRepo.match(/await this\.attachFolderProjection\(store, notes\)/g) || []).length, 8,
  'all eight note list queries must attach the folder projection');
eq((noteRepo.match(/await this\.attachFolderProjection\(store, \[note\]\)/g) || []).length, 3,
  'createNote/createNoteWithMeta/getNote must attach the projection');
// Folder color is NOT NULL on Harmony (Phase 533 decision) so a filed note
// always has both chip inputs — matching the original's non-null condition.
ok(/CREATE TABLE IF NOT EXISTS folder \([\s\S]*?color INTEGER NOT NULL/.test(db),
  'folder.color NOT NULL missing');
// note_meta.folder_id is ON DELETE SET NULL — a deleted folder leaves no chip.
ok(/FOREIGN KEY\(folder_id\) REFERENCES folder\(id\) ON DELETE SET NULL/.test(db),
  'folder_id SET NULL missing');
// Folder-delete committed list re-attaches the projection for surviving folders.
ok(folderRepo.includes('SELECT id, name, color FROM folder WHERE id IN'),
  'folder-delete committed projection missing');

// --- Harmony view-model anchors ----------------------------------------------------------
ok(vm.includes('publishCommittedNoteMove(noteId: string, folderId: string | null,') &&
   vm.includes('folderName: string | null, folderColor: number | null'),
  'publishCommittedNoteMove projection params missing');
ok(vm.includes('this.noteWithFolder(note, folderId, folderName, folderColor)') &&
   /moved\.has\(note\.id\)\) \{[\s\S]{0,160}continue;/.test(vm),
  'move projection + folder-delete cascade card drop missing');
ok(vm.includes('folderName: note.folderName') && vm.includes('folderColor: note.folderColor'),
  'favorite-toggle projection must preserve the folder chip fields');
ok(vmFixture.includes('folderName: null') && vmFixture.includes('folderColor: null') &&
   vmFixture.includes('folder projection'),
  'ArkTS fixtures for the folder projection missing');

// --- Harmony UI anchors --------------------------------------------------------------------
ok(page.includes('note.folderName !== null && note.folderColor !== null') &&
   page.includes('Text(note.folderName)') &&
   page.includes('this.folderChipTextColor(note.folderColor)') &&
   page.includes('this.folderChipColor(note.folderColor)'),
  'note-card folder chip missing');
ok(page.includes('note.hasRecordings') && page.includes("$r('app.string.recordings')"),
  'recordings mic indicator missing');
ok(page.includes('private folderChipColor(color: number): string') &&
   page.includes('(color >>> 0).toString(16)') &&
   page.includes('private folderChipTextColor(color: number): string'),
  'chip color/contrast helpers missing');
ok(page.includes('targetFolder === undefined ? null : targetFolder.name') &&
   page.includes('targetFolder === undefined ? null : targetFolder.color'),
  'move call-site projection resolution missing');

// --- Executable model ---------------------------------------------------------------------
// cti.c: chip renders iff folderName AND folderColor are both non-null.
const chipVisible = note => note.folderName !== null && note.folderColor !== null;
// i2j.b + kkf.d: the stored int packs ARGB; normalize to #AARRGGBB.
const chipColor = c => `#${(c >>> 0).toString(16).padStart(8, '0').toUpperCase()}`;
const chipText = c => {
  const a = c >>> 0;
  const l = 0.299 * ((a >> 16) & 0xFF) + 0.587 * ((a >> 8) & 0xFF) + 0.114 * (a & 0xFF);
  return l >= 150 ? '#DE000000' : '#FFFFFFFF';
};
const note = (folderId, folderName, folderColor) => ({ folderId, folderName, folderColor });

assert.equal(chipVisible(note('f1', 'Work', -7431250)), true); checks++;
assert.equal(chipVisible(note(null, null, null)), false); checks++;
assert.equal(chipVisible(note('f1', 'Work', null)), false); checks++;
// Signed (SQLite int32) and unsigned literals normalize identically.
assert.equal(chipColor(-7431250), '#FF8E9BAE'); checks++;
assert.equal(chipColor(0xFF4FA8DE), '#FF4FA8DE'); checks++;
// Contrast: light palette colors get dark text, dark colors get white.
assert.equal(chipText(0xFFF5C445), '#DE000000'); checks++;
assert.equal(chipText(0xFF4FA8DE), '#FFFFFFFF'); checks++;
assert.equal(chipText(-7431250), '#DE000000'); checks++; // 0xFF8E9BAE slate is mid-tone
// Move projection: committed move carries the destination name/color; unfiled clears.
function move(note, folderId, name, color) {
  return { ...note, folderId, folderName: name, folderColor: color };
}
let n = note(null, null, null);
n = move(n, 'f9', 'Work', 0xFF4FA8DE);
assert.deepEqual([n.folderName, n.folderColor], ['Work', 0xFF4FA8DE]); checks++;
n = move(n, null, null, null);
assert.equal(chipVisible(n), false); checks++;

console.log(`D02_ORIGINAL_NOTE_FOLDER_CHIP_OK TOTAL=${checks} FAILED=0`);

function eq(actual, expected, label) {
  assert.equal(actual, expected, label);
  checks++;
}
