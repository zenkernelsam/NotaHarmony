import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const ddl = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const types = read('note/src/main/ets/core/model/NoteTypes.ets');
const repo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const settings = read('note/src/main/ets/ui/settings/SettingsPage.ets');
const trashPage = read('note/src/main/ets/ui/settings/RecentlyDeletedPage.ets');
const pages = read('note/src/main/resources/base/profile/main_pages.json');
const strings = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };
const eq = (a, b, label) => { assert.equal(a, b, label); checks++; };

// --- Original evidence anchors ---------------------------------------------------
const leb = readOriginal('decompiled_1.0.3/sources/defpackage/leb.java');
const x17 = readOriginal('decompiled_1.0.3/sources/defpackage/x17.java');
const e47 = readOriginal('decompiled_1.0.3/sources/defpackage/e47.java');
const tp1 = readOriginal('decompiled_1.0.3/sources/defpackage/tp1.java');
const originalStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// leb.java: move-to-trash clears any queued UNDELETE row, then upserts a
// ClientNoteUpdate DELETE row stamped deletedAt=now.
ok(leb.includes('rp1.K'), 'leb must read the UNDELETE row before deleting');
ok(leb.includes('rp1.J'), 'leb must upsert a DELETE update');
eq((leb.match(/new sp1\(this\.K, rp1\.J/g) || []).length, 3,
  'leb must stamp a fresh DELETE row in all three branches');
ok(leb.includes('new xgb(this.L)'), 'leb DELETE row carries deletedAt=now');

// x17.java ClientPivot: deletedAt resolves client DELETE > client UNDELETE >
// synced deletedAt; PermanentlyDeletedNote + hasPermanentlyDelete hide rows.
ok(x17.includes("type = 'DELETE' THEN deletedAt"), 'ClientPivot DELETE arm missing');
ok(x17.includes("type = 'UNDELETE' THEN 1"), 'ClientPivot UNDELETE arm missing');
ok(x17.includes("type = 'PERMANENTLY_DELETE' THEN 1"), 'ClientPivot P-D arm missing');
ok(x17.includes('PermanentlyDeletedNote'), 'ClientPivot tombstone exclusion missing');
ok(x17.includes('hasPermanentlyDelete IS NULL'), 'ClientPivot P-D filter missing');

// tp1.java: restore = remove every queued update except PERMANENTLY_DELETE.
ok(tp1.includes('DELETE FROM ClientNoteUpdate WHERE id = ? AND type != ?'),
  'restore must delete queued non-permanent updates');

// e47.java: PermanentlyDeletedNote(noteId) tombstone DDL.
ok(e47.includes('PermanentlyDeletedNote'), 'original tombstone DDL missing');

// strings.xml: 30-day retention rule surfaced to the user.
ok(originalStrings.includes('permanently deleted after 30 days'),
  'original 30-day retention copy missing');
ok(originalStrings.includes('recently_deleted'), 'original Recently Deleted strings missing');

// --- Schema parity (v67) ----------------------------------------------------------
ok(ddl.includes('DB_VERSION: number = 71'), 'DB_VERSION must be 71');
ok(/deleted_at INTEGER/.test(ddl), 'note_meta.deleted_at column missing');
ok(ddl.includes('CREATE TABLE IF NOT EXISTS permanently_deleted_note'),
  'permanently_deleted_note DDL missing');
ok(ddl.includes('note_id TEXT PRIMARY KEY'), 'tombstone note_id PK missing');
ok(ddl.includes("'ALTER TABLE note_meta ADD COLUMN deleted_at INTEGER'"),
  'v67 migration must add deleted_at');
ok(ddl.includes('idx_note_meta_deleted_at ON note_meta(deleted_at)'),
  'deleted_at index missing');
ok(manager.includes('DDL_PERMANENTLY_DELETED_NOTE'),
  'DatabaseManager must create the tombstone table');
ok(types.includes('deletedAt: number | null'), 'NoteMeta.deletedAt missing');

// --- Repository behavior anchors ---------------------------------------------------
ok(repo.includes("predicates.isNull('deleted_at')"),
  'library projection must exclude trashed notes');
// Two original search queries + the three Phase 537 section queries (favorite/
// unfiled/recent) + the Phase 551 unindexed-count query all exclude trashed notes.
eq((repo.match(/note\.deleted_at IS NULL/g) || []).length, 6,
  'all search, section, and unindexed queries must exclude trashed notes');
ok(repo.includes("predicates.isNotNull('deleted_at')"),
  'trash list must select deleted_at IS NOT NULL');
ok(repo.includes("predicates.orderByDesc('deleted_at')"),
  'trash list orders by newest deletion first');
ok(repo.includes("30 * 24 * 60 * 60 * 1000"), '30-day retention constant missing');
ok(repo.includes('deleted_at <= ?'), 'purge must bound deleted_at by cutoff');
ok(repo.includes('permanently_deleted_note'),
  'permanent delete must record the tombstone');
ok(repo.includes("new relationalStore.RdbPredicates('search_item')"),
  'permanent delete must remove search index rows');
ok(iface.includes('trashNote(noteId: string, deletedAt: number)'),
  'NoteRepository.trashNote contract missing');
ok(iface.includes('restoreNote(noteId: string)'), 'NoteRepository.restoreNote missing');
ok(iface.includes('getTrashedNotes()'), 'NoteRepository.getTrashedNotes missing');
ok(iface.includes('purgeExpiredTrash(now: number)'),
  'NoteRepository.purgeExpiredTrash missing');

// Import rollback must not tombstone; tombstoned ids must never resurrect.
ok(importer.includes('deleteNote(noteId, false)'),
  'import rollback must skip the tombstone');
ok(importer.includes('permanently_deleted_note WHERE note_id = ?'),
  'import must treat tombstoned ids as occupied');

// --- UI wiring ---------------------------------------------------------------------
ok(vm.includes('this.repo.trashNote(noteId, Date.now())'),
  'library delete must move to trash, not hard-delete');
ok(vm.includes('this.repo.purgeExpiredTrash(Date.now())'),
  'library load must purge expired trash');
ok(settings.includes("ui/settings/RecentlyDeletedPage"),
  'settings must link the Recently Deleted page');
ok(pages.includes('ui/settings/RecentlyDeletedPage'),
  'RecentlyDeletedPage must be registered in main_pages.json');
ok(trashPage.includes('restoreNote'), 'trash page must offer Recover');
ok(trashPage.includes('repo.deleteNote(noteId)'),
  'trash page permanent delete must hit deleteNote');
ok(trashPage.includes('purgeExpiredTrash'), 'trash page must purge on load');
ok(trashPage.includes('TRASH_RETENTION_MS'), 'trash page must show remaining days');

for (const key of ['recently_deleted', 'recently_deleted_empty_state_header',
  'recently_deleted_empty_state_message', 'recently_deleted_meta',
  'recently_deleted_load_failed', 'recover_note', 'recover_note_failed',
  'delete_permanently', 'delete_permanently_message', 'delete_permanently_failed']) {
  ok(strings.includes(`"name": "${key}"`), `base strings missing ${key}`);
  ok(stringsZh.includes(`"name": "${key}"`), `zh_CN strings missing ${key}`);
}
ok(strings.includes('Move \\"%s\\" to Recently Deleted?'),
  'delete dialog must describe the trash destination');

// --- Executable lifecycle model (mirrors NoteRepositoryImpl semantics) -------------
// Faithful local-only equivalent of the original ClientNoteUpdate pivot:
// deleted_at column plays the DELETE-row role, permanently_deleted_note plays
// the PermanentlyDeletedNote tombstone role.
const store = () => ({
  notes: new Map(),      // id -> { id, folderId, deletedAt, title, searchItem }
  tombstones: new Set(), // permanently_deleted_note
});
const create = (s, id, folderId = null, title = '') => {
  assert.ok(!s.notes.has(id) && !s.tombstones.has(id));
  s.notes.set(id, { id, folderId, deletedAt: null, title, searchItem: true });
};
const library = (s, folderId = undefined) => [...s.notes.values()]
  .filter(n => n.deletedAt === null)
  .filter(n => folderId === undefined || n.folderId === folderId);
const trashed = s => [...s.notes.values()].filter(n => n.deletedAt !== null)
  .sort((a, b) => b.deletedAt - a.deletedAt);
const trash = (s, id, at) => { s.notes.get(id).deletedAt = at; };
const restore = (s, id) => { s.notes.get(id).deletedAt = null; };
const permanentlyDelete = (s, id) => { s.tombstones.add(id); s.notes.delete(id); };
const purge = (s, now) => {
  const cutoff = now - 30 * 24 * 60 * 60 * 1000;
  for (const n of [...s.notes.values()]) {
    if (n.deletedAt !== null && n.deletedAt <= cutoff) permanentlyDelete(s, n.id);
  }
};
const noteIdOccupied = (s, id) => s.notes.has(id) || s.tombstones.has(id);

const s = store();
create(s, 'a', 'folder-1', 'Alpha');
create(s, 'b', null, 'Beta');
eq(library(s).length, 2, 'two active notes listed');
eq(library(s, 'folder-1').length, 1, 'folder projection lists its note');

trash(s, 'a', 1000);
eq(library(s).length, 1, 'trashed note leaves the library');
eq(library(s, 'folder-1').length, 0, 'trashed note leaves its folder view');
eq(trashed(s).length, 1, 'trash list gains the note');
ok(s.notes.get('a').searchItem, 'trash keeps the search index (restore keeps ops)');
eq(s.notes.get('a').folderId, 'folder-1', 'trash keeps folder_id for restore');

restore(s, 'a');
eq(library(s, 'folder-1').length, 1, 'restore returns the note to its folder');
eq(trashed(s).length, 0, 'restore clears the trash list');

trash(s, 'a', 2000);
permanentlyDelete(s, 'a');
ok(s.tombstones.has('a'), 'permanent delete writes the tombstone');
eq(library(s).length + trashed(s).length, 1, 'permanently deleted note is gone');
ok(noteIdOccupied(s, 'a'), 'tombstoned id stays occupied for import');

trash(s, 'b', 5000);
const now = 5000 + 30 * 24 * 60 * 60 * 1000 + 1;
purge(s, now);
ok(s.tombstones.has('b'), 'expired trash is tombstoned by the purge');
ok(!s.notes.has('b'), 'expired trash rows are hard-deleted');

// A note trashed inside the retention window survives the purge.
create(s, 'c', null, 'Gamma');
trash(s, 'c', now - 1000);
purge(s, now);
ok(s.notes.has('c') && trashed(s).length === 1,
  'note inside the 30-day window is not purged');

// Trash->restore->retrash cycle behaves like repeated queue updates.
restore(s, 'c');
trash(s, 'c', now);
eq(trashed(s)[0].deletedAt, now, 're-trash restamps deletedAt');
purge(s, now + 30 * 24 * 60 * 60 * 1000 + 1);
ok(s.tombstones.has('c'), 're-trashed note purges on the new timestamp');

console.log(`TOTAL=${checks} FAILED=0`);
