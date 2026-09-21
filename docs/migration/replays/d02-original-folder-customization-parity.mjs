import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const ddl = read('note/src/main/ets/data/DatabaseHelper.ets');
const repo = read('note/src/main/ets/data/FolderRepositoryImpl.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const dbFixture = read('note/src/test/DatabaseHelper.test.ets');
const folderFixture = read('note/src/test/FolderRepository.test.ets');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors -----------------------------------------------------
const e47 = readOriginal('decompiled_1.0.3/sources/defpackage/e47.java');
const vdb = readOriginal('decompiled_1.0.3/sources/defpackage/vdb.java');
const pdb = readOriginal('decompiled_1.0.3/sources/defpackage/pdb.java');
const xo1 = readOriginal('decompiled_1.0.3/sources/defpackage/xo1.java');
const id7 = readOriginal('decompiled_1.0.3/sources/defpackage/id7.java');
const xdb = readOriginal('decompiled_1.0.3/sources/defpackage/xdb.java');
const w09 = readOriginal('decompiled_1.0.3/sources/defpackage/w09.java');
const ac4 = readOriginal('decompiled_1.0.3/sources/defpackage/ac4.java');
const rdb = readOriginal('decompiled_1.0.3/sources/defpackage/rdb.java');
const msb = readOriginal('decompiled_1.0.3/sources/defpackage/msb.java');

// e47.java:353 — SyncedFolderMetadata carries color INTEGER NOT NULL, emoji TEXT,
// updatedAt INTEGER NOT NULL. Folder customization is schema-backed, not cosmetic.
ok(e47.includes('`SyncedFolderMetadata` (`id` BLOB NOT NULL, `parentId` BLOB NOT NULL, `updatedAt` INTEGER NOT NULL, `title` TEXT NOT NULL, `color` INTEGER NOT NULL, `siblingOrder` REAL NOT NULL, `emoji` TEXT'),
  'original SyncedFolderMetadata color/emoji/updatedAt columns missing');
// e47.java:354 — ClientFolderEdit is the partial-edit queue: every payload column
// nullable (unset = keep current), updatedAt NOT NULL (always stamped).
ok(e47.includes('`ClientFolderEdit` (`id` BLOB NOT NULL, `parentId` BLOB, `title` TEXT, `color` INTEGER, `siblingOrder` REAL, `createdAt` INTEGER, `updatedAt` INTEGER NOT NULL'),
  'original ClientFolderEdit partial-edit columns missing');
ok(e47.includes('`emoji` TEXT, PRIMARY KEY(`id`))'), 'original ClientFolderEdit emoji column missing');

// xo1.java — ClientFolderEdit field order: b=parentId, c=title, d=color(Integer),
// e=siblingOrder(Double), g=updatedAt(long), j=emoji(String).
ok(xo1.includes('public xo1(utf utfVar, utf utfVar2, String str, Integer num, Double d, xgb xgbVar, long j, boolean z, utf utfVar3, String str2)'),
  'original ClientFolderEdit constructor signature missing');

// vdb.java — the beb.e() edit path: null parameter falls back to the current value
// (lq4Var getters), while updatedAt (this.T) is written unconditionally.
ok(vdb.includes('iF = lq4Var.f();') && vdb.includes('strD = lq4Var.d();') &&
   vdb.includes('title2 = lq4Var.getTitle();') && vdb.includes('dH = lq4Var.h();'),
  'original partial-edit keep-current fallback missing');
ok(vdb.includes('this.T, str3') && vdb.includes('this.T, false, strD'),
  'original unconditional updatedAt stamp missing');

// id7.java — l(): rename/customize submits title+color+emoji in one beb.e() call;
// b(): creation requires a concrete int color; n(): move goes through xdb.
ok(id7.includes('id7Var.c.e(utfVar, System.currentTimeMillis(), null, str,') &&
   id7.includes('(i & 64) != 0 ? null : str2'),
  'original combined title/color/emoji edit path missing');
ok(id7.includes('new sdb(id7Var.c, utfVar, utfVar2, str, new Integer(i),'),
  'original create path with required color missing');
ok(id7.includes('new xdb(id7Var.c, utfVar, utfVar2, i, System.currentTimeMillis(), null)'),
  'original move path missing');
// rdb.java — creation writes createdAt and updatedAt with the same timestamp j.
ok(rdb.includes('new xo1(this.K, this.L, this.M, this.N, d, new xgb(j), j, this.Q)'),
  'original create-time updatedAt=createdAt stamp missing');
// xdb.java — a move passes only siblingOrder (d); title/color/emoji stay null (keep).
ok(xdb.includes('bebVar.e(this.L, this.O, this.M, null, null, d, null, this)'),
  'original move writes only siblingOrder');

// pdb.java — display model resolves each field edit-over-synced; empty emoji -> null.
ok(pdb.includes('(str = xo1VarC.j) == null') && pdb.includes('str.length() <= 0'),
  'original emoji edit-override + empty-to-null display missing');
ok(pdb.includes('(num = xo1VarC.d) != null') && pdb.includes('return jaeVar.e'),
  'original color edit-override display missing');

// w09.java — folderColor is part of the library Note row model (user-visible).
ok(w09.includes('folderColor=') && w09.includes('Integer'), 'original note-row folderColor missing');
// ac4/msb — the emoji picker is a real feature flag (LIBRARY_FOLDER_EMOJI_PICKER).
ok(ac4.includes('LIBRARY_FOLDER_EMOJI_PICKER') && msb.includes('androidFolderEmojiPicker'),
  'original folder emoji picker flag missing');

// --- Harmony schema anchors --------------------------------------------------------
ok(ddl.includes('export const FOLDER_DEFAULT_COLOR: number'), 'FOLDER_DEFAULT_COLOR missing');
ok(ddl.includes('color INTEGER NOT NULL DEFAULT ${FOLDER_DEFAULT_COLOR}'),
  'folder.color NOT NULL column missing');
ok(/emoji TEXT,\s*\n\s*updated_at INTEGER NOT NULL DEFAULT 0/.test(ddl),
  'folder.emoji/updated_at columns missing');
ok(ddl.includes('ALTER TABLE folder ADD COLUMN color INTEGER NOT NULL DEFAULT') &&
   ddl.includes('ALTER TABLE folder ADD COLUMN emoji TEXT') &&
   ddl.includes('ALTER TABLE folder ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0') &&
   ddl.includes('UPDATE folder SET updated_at = created_at'),
  'v68 folder migration statements missing');
ok(ddl.includes('DB_VERSION: number = 69'), 'DB_VERSION must be 69');

// --- Harmony repository anchors ----------------------------------------------------
ok(/export interface NoteFolder \{[\s\S]*?color: number;[\s\S]*?emoji: string \| null;[\s\S]*?updatedAt: number;[\s\S]*?\}/.test(repo),
  'NoteFolder color/emoji/updatedAt fields missing');
ok(repo.includes('export interface FolderEdits {') &&
   /FolderEdits \{[\s\S]*?name\?: string;[\s\S]*?color\?: number;[\s\S]*?emoji\?: string \| null;/.test(repo),
  'FolderEdits partial-edit contract missing');
ok(repo.includes('async editFolder(folderId: string, edits: FolderEdits)'),
  'editFolder missing');
ok(repo.includes("const bucket: relationalStore.ValuesBucket = { 'updated_at': Date.now() };"),
  'editFolder must stamp updated_at unconditionally');
ok(repo.includes("bucket['emoji'] = normalizeFolderEmoji(edits.emoji)"),
  'editFolder emoji normalization missing');
ok(repo.includes('return this.editFolder(folderId, { name: name })'),
  'renameFolder must delegate to editFolder');
ok(/moveFolder[\s\S]*?'updated_at': Date\.now\(\),/.test(repo),
  'moveFolder must stamp updated_at on the moved folder');
ok(repo.includes('color: number = FOLDER_DEFAULT_COLOR') &&
   repo.includes('emoji: string | null = null'),
  'createFolder color/emoji parameters missing');
ok(repo.includes("'color': folder.color") && repo.includes("'emoji': folder.emoji") &&
   repo.includes("'updated_at': folder.updatedAt"),
  'folderBucket must write color/emoji/updated_at');
ok(repo.includes("resultSet.getLong(resultSet.getColumnIndex('color'))") &&
   repo.includes("resultSet.getColumnIndex('emoji')") &&
   repo.includes("resultSet.getLong(resultSet.getColumnIndex('updated_at'))"),
  'queryFolders must read color/emoji/updated_at');
ok(/function normalizeFolderEmoji[\s\S]*?emoji\.length === 0[\s\S]*?return null/.test(repo),
  'normalizeFolderEmoji blank-to-null semantics missing');

// --- Harmony UI anchors ------------------------------------------------------------
ok(page.includes('const FOLDER_COLOR_PALETTE: number[]') &&
   page.includes('FOLDER_DEFAULT_COLOR,'), 'folder color palette missing');
ok(page.includes('const FOLDER_EMOJI_PRESETS: string[]'), 'folder emoji presets missing');
ok(page.includes('folderDialogColor') && page.includes('folderDialogEmoji'),
  'folder dialog customization state missing');
ok(page.includes('.fill(item.folder.color)'), 'folder row color dot missing');
ok(page.includes('item.folder.emoji !== null'), 'folder row emoji display missing');
ok(page.includes('this.folderDialogColor = folder.color') &&
   page.includes("folder.emoji === null ? '' : folder.emoji"),
  'rename dialog must initialize color/emoji from the folder');
ok(page.includes('repo.editFolder(this.folderDialogTargetId') &&
   page.includes('color: color, emoji: emoji'),
  'rename dialog must submit name/color/emoji in one edit');
ok(/createFolder\(trimmed,[\s\S]*?color, emoji\)/.test(page),
  'create dialog must pass color/emoji');
ok(page.includes('initialColor: this.folderDialogColor') &&
   page.includes('initialEmoji: this.folderDialogEmoji'),
  'NameDialog must receive customization props');
ok(/ForEach\(FOLDER_COLOR_PALETTE/.test(page) && /ForEach\(FOLDER_EMOJI_PRESETS/.test(page),
  'dialog color/emoji picker rows missing');
ok(page.includes('this.onConfirm(this.inputText, this.selectedColor, this.selectedEmoji)'),
  'dialog confirm must return color/emoji');

// --- Fixture anchors ---------------------------------------------------------------
ok(dbFixture.includes('expect(DB_VERSION).assertEqual(69)'),
  'database fixture must pin DB_VERSION 69');
ok(/emoji: null/.test(folderFixture) && /updatedAt: order/.test(folderFixture),
  'folder test factory must carry color/emoji/updatedAt');

// --- Executable model: beb.e()/vdb partial-edit semantics ---------------------------
// Model the original: a folder edit row carries only the fields the caller set;
// display resolution falls back per field and stamps updatedAt every edit.
function originalEdit(current, edits, now) {
  return {
    parentId: edits.parentId !== undefined ? edits.parentId : current.parentId,
    title: edits.title !== undefined ? edits.title : current.title,
    color: edits.color !== undefined ? edits.color : current.color,
    siblingOrder: edits.siblingOrder !== undefined ? edits.siblingOrder : current.siblingOrder,
    updatedAt: now,
    emoji: edits.emoji !== undefined ? edits.emoji : current.emoji,
  };
}
const base = { parentId: null, title: 'Work', color: -7431250, siblingOrder: 2.5, updatedAt: 100, emoji: null };
const renamed = originalEdit(base, { title: 'Personal' }, 200);
assert.equal(renamed.title, 'Personal'); checks++;
assert.equal(renamed.color, base.color); checks++;
assert.equal(renamed.emoji, null); checks++;
assert.equal(renamed.siblingOrder, base.siblingOrder); checks++;
assert.equal(renamed.updatedAt, 200); checks++;
const colored = originalEdit(base, { color: -2394804 }, 300);
assert.equal(colored.color, -2394804); checks++;
assert.equal(colored.title, base.title); checks++;
const moved = originalEdit(base, { parentId: 'p', siblingOrder: 0.0 }, 400);
assert.equal(moved.parentId, 'p'); checks++;
assert.equal(moved.color, base.color); checks++;
assert.equal(moved.updatedAt, 400); checks++;
// pdb.d(): empty-string emoji resolves to no emoji.
const emojied = originalEdit(base, { emoji: '⭐' }, 500);
assert.equal(emojied.emoji === '' || emojied.emoji === null ? null : emojied.emoji, '⭐'); checks++;
const cleared = originalEdit(emojied, { emoji: '' }, 600);
assert.equal(cleared.emoji === '' || cleared.emoji === null ? null : cleared.emoji, null); checks++;

console.log(`D02_ORIGINAL_FOLDER_CUSTOMIZATION_OK TOTAL=${checks} FAILED=0`);
