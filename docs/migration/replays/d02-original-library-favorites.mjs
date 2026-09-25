import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const noteRepo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');
const vmFixture = read('note/src/test/LibraryViewModel.test.ets');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors --------------------------------------------------------
const dk9 = readOriginal('decompiled_1.0.3/sources/defpackage/dk9.java');
const ua5 = readOriginal('decompiled_1.0.3/sources/defpackage/ua5.java');
const pk9 = readOriginal('decompiled_1.0.3/sources/defpackage/pk9.java');
const mk9 = readOriginal('decompiled_1.0.3/sources/defpackage/mk9.java');
const fh7 = readOriginal('decompiled_1.0.3/sources/defpackage/fh7.java');
const apb = readOriginal('decompiled_1.0.3/sources/defpackage/apb.java');
const x17 = readOriginal('decompiled_1.0.3/sources/defpackage/x17.java');
const yp1 = readOriginal('decompiled_1.0.3/sources/defpackage/yp1.java');
const d5j = readOriginal('decompiled_1.0.3/sources/defpackage/d5j.java');
const gj9 = readOriginal('decompiled_1.0.3/sources/defpackage/gj9.java');
const pf9 = readOriginal('decompiled_1.0.3/sources/defpackage/pf9.java');
const dj5 = readOriginal('decompiled_1.0.3/sources/defpackage/dj5.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// dk9.java — the library section enum is ALL_NOTES/RECENT/FAVORITES/UNFILED.
ok(dk9.includes('ALL_NOTES(R.string.feature_library__all_notes)') &&
   dk9.includes('RECENT(R.string.feature_library__recent_notes)') &&
   dk9.includes('FAVORITES(R.string.feature_library__favorite_notes)') &&
   dk9.includes('UNFILED(R.string.feature_library__unfiled)'),
  'original dk9 section enum missing');
// ua5.java:227 — the section row iterates all four values as selectable chips.
ok(ua5.includes('for (dk9 dk9Var : dk9.M)') && ua5.includes('fk9Var.d == dk9Var'),
  'original dk9 chip row missing');
// pk9.java:67 — ALL_NOTES is the default selected section.
ok(pk9.includes('bsd.a(dk9.ALL_NOTES)'), 'original ALL_NOTES default missing');
// mk9.java — RECENT sorts by the recency key descending and takes the top 10;
// other sections go through the shared s() sort; RECENT cards show gb6.b0
// (lastOpened) while the rest show gb6.c0 (updatedAt).
ok(mk9.includes('au1.N1(au1.K1(list, new fh7(13)), 10)') &&
   mk9.includes('dk9Var == dk9Var2 ? gb6.b0 : gb6.c0'),
  'original RECENT top-10 ordering missing');
// fh7 case 13 — swapped-argument comparison = descending by apb.F (lastOpened).
ok(/case 13:[\s\S]*?apb\.F\(\(j89\) obj2\)[\s\S]*?apb\.F\(\(j89\) obj\)/.test(fh7),
  'original RECENT descending comparator missing');
// apb.F — lastOpened override wins; otherwise the note's own timestamp is used.
ok(apb.includes('public static final long F(j89 j89Var)') &&
   apb.includes('xgbVarC != null ? xgbVarC.I : j89Var.m()'),
  'original apb.F recency fallback missing');
// x17 merged query — favorite/lastOpened are first-class merged metadata and
// partial setFavorite/setLastOpened EDIT rows must not resurrect a note.
ok(x17.includes('COALESCE(cp.editFavorite, snm.favorite, 0) as favorite') &&
   x17.includes('COALESCE(cp.editLastOpened, snm.lastOpened) as lastOpened') &&
   x17.includes('setLastOpened') && x17.includes('setFavorite'),
  'original merged favorite/lastOpened model missing');
// yp1 — the modifyNote mutation writes isFavorited/lastOpened as optional fields.
ok(yp1.includes('jSONObject2.put("isFavorited", bool.booleanValue())') &&
   yp1.includes('jSONObject2.put("lastOpened", xgbVar.I)'),
  'original modifyNote isFavorited write missing');
// d5j/gj9 — the context-menu row flips Favorite/Unfavorite by current state.
ok(d5j.includes('R.string.feature_library__unfavorite : R.string.feature_library__favorite') &&
   gj9.includes('ui_designsystem__unfavorite_outline') &&
   gj9.includes('ui_designsystem__favorite_outline'),
  'original favorite toggle menu missing');
// pf9 — favorited notes render the favorite_fill badge.
ok(pf9.includes('ui_designsystem__favorite_fill'), 'original favorite_fill badge missing');
// dj5 — the home-recents model carries isFavorited for display.
ok(dj5.includes('", isFavorited="'), 'original HomeRecentNoteModel.isFavorited missing');
ok(origStrings.includes('feature_library__empty_favorite_notes_title') &&
   origStrings.includes('feature_library__empty_favorite_notes_body'),
  'original favorites empty-state strings missing');

// --- Harmony repository anchors ---------------------------------------------------------
// LibrarySection keeps the dk9 ordinals.
ok(iface.includes('ALL_NOTES = 0') && iface.includes('RECENT = 1') &&
   iface.includes('FAVORITES = 2') && iface.includes('UNFILED = 3'),
  'LibrarySection dk9 ordinals missing');
ok(iface.includes('getFavoriteNotes(): Promise<NoteMeta[]>') &&
   iface.includes('getRecentNotes(): Promise<NoteMeta[]>') &&
   iface.includes('getUnfiledNotes(): Promise<NoteMeta[]>') &&
   iface.includes('setNoteFavorite(noteId: string, favorite: boolean): Promise<NoteMeta>') &&
   iface.includes('touchNoteLastOpened(noteId: string, lastOpened: number): Promise<void>'),
  'NoteRepository favorite/section surface missing');
// FAVORITES = favorite=1 + not deleted, updatedAt desc (gb6.c0).
ok(noteRepo.includes("predicates.equalTo('favorite', 1)") &&
   noteRepo.includes("async getFavoriteNotes(): Promise<NoteMeta[]>"),
  'getFavoriteNotes query missing');
// RECENT = lastOpened desc, LIMIT 10 (mk9 N1(...,10)).
ok(/ORDER BY last_opened DESC, updated_at DESC LIMIT 10/.test(noteRepo),
  'getRecentNotes top-10 ordering missing');
// UNFILED = folder_id IS NULL + not deleted.
ok(noteRepo.includes("async getUnfiledNotes(): Promise<NoteMeta[]>") &&
   /getUnfiledNotes[\s\S]*?isNull\('folder_id'\)/.test(noteRepo),
  'getUnfiledNotes query missing');
// setFavorite is a partial update — the bucket writes ONLY the favorite column.
ok(/setNoteFavorite[\s\S]*?ValuesBucket = \{ 'favorite': favorite \? 1 : 0 \}/.test(noteRepo) &&
   !/setNoteFavorite[\s\S]*?'updated_at'/.test(noteRepo.slice(
     noteRepo.indexOf('async setNoteFavorite'), noteRepo.indexOf('async touchNoteLastOpened'))),
  'setNoteFavorite must not touch updatedAt');
// setLastOpened partial update — writes only last_opened.
ok(/touchNoteLastOpened[\s\S]*?ValuesBucket = \{ 'last_opened': lastOpened \}/.test(noteRepo),
  'touchNoteLastOpened partial update missing');
// Section-scoped search keeps the EXISTS search_item predicate per section.
ok(noteRepo.includes('searchNotesInSection(query: string, section: LibrarySection)') &&
   (noteRepo.match(/note\.favorite = 1[\s\S]*?EXISTS \(SELECT 1 FROM search_item/) !== null) &&
   (noteRepo.match(/note\.folder_id IS NULL[\s\S]*?EXISTS \(SELECT 1 FROM search_item/) !== null),
  'section-scoped search missing');

// --- Harmony view-model anchors -----------------------------------------------------------
ok(vm.includes('currentSection: LibrarySection = LibrarySection.ALL_NOTES'),
  'ALL_NOTES default section missing');
ok(vm.includes('async setSection(section: LibrarySection, query: string)') &&
   vm.includes('this.currentFolderId = null;'),
  'setSection clears the folder view missing');
ok(vm.includes('this.currentSection = LibrarySection.ALL_NOTES'),
  'folder selection must reset the section');
ok(vm.includes('async toggleFavorite(noteId: string)') &&
   vm.includes('this.repo.setNoteFavorite(noteId, !note.favorite)') &&
   vm.includes('this.currentSection === LibrarySection.FAVORITES'),
  'toggleFavorite mutation missing');
// RECENT bypasses applySort (mk9 ordering is fixed).
ok(/applySort\(\): void \{\s+\/\/ Original dk9\.RECENT[\s\S]*?currentSection === LibrarySection\.RECENT[\s\S]*?return;/.test(vm),
  'RECENT must bypass the sort modes');
ok(vmFixture.includes('setSection(LibrarySection.FAVORITES') &&
   vmFixture.includes('caps at ten') &&
   vmFixture.includes('toggleFavorite'),
  'ArkTS fixtures for sections/favorites missing');

// --- Harmony UI anchors --------------------------------------------------------------------
// Four dk9 rows + the Home pseudo-section (Phase 746, LIBRARY_HOME
// default-on per ADR-0691) in both the sidebar and the compact drawer.
ok((page.match(/this\.SectionNavRow\(/g) || []).length === 10,
  'ten SectionNavRow calls (5 sections × 2 surfaces) missing');
ok(page.includes('LibrarySection.RECENT') && page.includes('LibrarySection.FAVORITES') &&
   page.includes('LibrarySection.UNFILED') && page.includes('LibrarySection.ALL_NOTES') &&
   page.includes('LibrarySection.HOME'),
  'dk9 + Home section rows missing');
ok(page.includes('private async selectSection(section: LibrarySection)') &&
   page.includes('vm.setSection(section, query)'),
  'selectSection handler missing');
// d5j/gj9 menu parity: Favorite/Unfavorite label flips on the current flag.
ok(page.includes("note.favorite ? $r('app.string.unfavorite_note') :") &&
   page.includes("$r('app.string.favorite_note')") &&
   page.includes('this.toggleNoteFavorite(note)'),
  'favorite context-menu toggle missing');
// pf9 parity: the card renders a badge overlay when favorited.
ok(/Stack\(\{ alignContent: Alignment\.TopEnd \}\)[\s\S]*?if \(note\.favorite\)[\s\S]*?Text\('♥'\)/.test(page),
  'note-card favorite badge missing');
// gb6.b0 parity: RECENT cards show lastOpened.
ok(page.includes('this.currentSection === LibrarySection.RECENT ? note.lastOpened : note.updatedAt'),
  'RECENT lastOpened card date missing');
// FAVORITES empty state (feature_library__empty_favorite_notes_*).
ok(page.includes("empty_favorite_notes_title") && page.includes("empty_favorite_notes_body"),
  'favorites empty state missing');
// Editor open stamps lastOpened (original setLastOpened partial update).
ok(notePage.includes('touchNoteLastOpened(this.noteId, Date.now())'),
  'editor lastOpened touch missing');
for (const name of ['recent_notes', 'favorite_notes', 'unfiled', 'favorite_note',
  'unfavorite_note', 'empty_favorite_notes_title', 'empty_favorite_notes_body']) {
  ok(stringsBase.includes(`"name": "${name}"`) && stringsZh.includes(`"name": "${name}"`),
    `string ${name} missing in a locale`);
}

// --- Executable model: mk9 section projection + setFavorite mutation -----------------------
function sectionList(notes, section) {
  const live = notes.filter(n => n.deletedAt === null);
  if (section === 'RECENT') {
    // fh7(13): descending by lastOpened (apb.F fallback = the note timestamp);
    // au1.N1 takes the top 10.
    return live.slice().sort((a, b) =>
      (b.lastOpened ?? b.updatedAt) - (a.lastOpened ?? a.updatedAt)).slice(0, 10);
  }
  if (section === 'FAVORITES') {
    return live.filter(n => n.favorite)
      .sort((a, b) => b.updatedAt - a.updatedAt);
  }
  if (section === 'UNFILED') {
    return live.filter(n => n.folderId === null)
      .sort((a, b) => b.updatedAt - a.updatedAt);
  }
  return live.slice().sort((a, b) => b.updatedAt - a.updatedAt);
}
// setFavorite/setLastOpened: partial writes — favorite/lastOpened flip without
// touching createdAt/updatedAt (x17 ClientPivot keeps snm.updatedAt).
function setFavorite(note, favorite) {
  return { ...note, favorite };
}
const note = (id, extra = {}) => ({
  id, title: id, createdAt: 1, updatedAt: 1, favorite: false,
  lastOpened: 1, folderId: null, deletedAt: null, ...extra,
});

const pool = [
  note('fav-new', { favorite: true, updatedAt: 5 }),
  note('fav-old', { favorite: true, updatedAt: 3 }),
  note('plain', { updatedAt: 9 }),
  note('filed', { folderId: 'f1', updatedAt: 7 }),
  note('gone', { favorite: true, deletedAt: 100 }),
];
assert.deepEqual(sectionList(pool, 'FAVORITES').map(n => n.id), ['fav-new', 'fav-old']);
checks++;
assert.deepEqual(sectionList(pool, 'UNFILED').map(n => n.id), ['plain', 'fav-new', 'fav-old']);
checks++;
const recentPool = Array.from({ length: 12 }, (_, i) =>
  note(`r${i}`, { lastOpened: i + 1 }));
assert.deepEqual(sectionList(recentPool, 'RECENT').map(n => n.id),
  ['r11', 'r10', 'r9', 'r8', 'r7', 'r6', 'r5', 'r4', 'r3', 'r2']);
checks++;
// Deleted notes never appear in any section (ClientPivot excludes them).
assert.equal(sectionList(pool, 'FAVORITES').some(n => n.id === 'gone'), false);
checks++;
// setFavorite: partial write preserves updatedAt (the original EDIT row has no
// createdAt/updatedAt, so the merged projection keeps the synced values).
const flipped = setFavorite(note('n', { updatedAt: 42 }), true);
assert.equal(flipped.favorite, true);
assert.equal(flipped.updatedAt, 42);
checks++;
// Unfavoriting inside FAVORITES drops the row from the projection.
const favView = sectionList(pool, 'FAVORITES').map(n => n.id === 'fav-new' ?
  setFavorite(n, false) : n);
assert.deepEqual(sectionList(favView, 'FAVORITES').map(n => n.id), ['fav-old']);
checks++;

console.log(`D02_ORIGINAL_LIBRARY_FAVORITES_OK TOTAL=${checks} FAILED=0`);
