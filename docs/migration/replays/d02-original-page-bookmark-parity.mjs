import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const db = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const createOp = read('note/src/main/ets/data/OriginalCreatePageOperation.ets');
const modifyOp = read('note/src/main/ets/data/OriginalModifyPageOperation.ets');
const modifyEncoder = read('note/src/main/ets/data/OriginalModifyPagePayloadEncoder.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const pagePersistence = read('note/src/main/ets/data/OriginalPagePersistence.ets');
const pageRepo = read('note/src/main/ets/data/PageRepositoryImpl.ets');
const deleteOp = read('note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets');
const noteTypes = read('note/src/main/ets/core/model/NoteTypes.ets');
const bgModel = read('note/src/main/ets/core/model/PageBackgroundModel.ets');
const packageSpec = read('note/src/main/ets/data/NotePackageSpec.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const pageBar = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const dbFixture = read('note/src/test/DatabaseHelper.test.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ------------------------------------------------------
const oz9 = readOriginal('decompiled_1.0.3/sources/defpackage/oz9.java');
const wz9 = readOriginal('decompiled_1.0.3/sources/defpackage/wz9.java');
const ln2 = readOriginal('decompiled_1.0.3/sources/defpackage/ln2.java');
const ge8 = readOriginal('decompiled_1.0.3/sources/defpackage/ge8.java');
const haj = readOriginal('decompiled_1.0.3/sources/defpackage/haj.java');
const u5j = readOriginal('decompiled_1.0.3/sources/defpackage/u5j.java');
const ae2 = readOriginal('decompiled_1.0.3/sources/defpackage/ae2.java');
const de2 = readOriginal('decompiled_1.0.3/sources/defpackage/de2.java');
const md = readOriginal('decompiled_1.0.3/sources/defpackage/md.java');
const nd2 = readOriginal('decompiled_1.0.3/sources/defpackage/nd2.java');
const n9j = readOriginal('decompiled_1.0.3/sources/defpackage/n9j.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// oz9.java — the register value enum is a byte: UNBOOKMARKED(0) / BOOKMARKED(1).
ok(oz9.includes('UNBOOKMARKED((byte) 0)') && oz9.includes('BOOKMARKED((byte) 1)'),
  'original oz9 UNBOOKMARKED/BOOKMARKED bytes missing');
// wz9.java:42 + 132 — PageImpl holds a bookmarkedRegister whose LWW winner is the
// oz9 value; the materialized flag reads winner == BOOKMARKED.
ok(wz9.includes('this.l = yc6Var2.K == oz9.BOOKMARKED') &&
   wz9.includes('bookmarkedRegister='),
  'original wz9 bookmarkedRegister missing');
// ln2/ge8 — both CreatePage and ModifyPage payloads carry the bookmark field.
ok(ln2.includes('bookmarked=" + k()') && ge8.includes('bookmarked=" + k()'),
  'original CreatePage/ModifyPage bookmark field missing');
// haj.java:40 + 175 — the FlatBuffer writers store the oz9 byte at field 3.
ok((haj.match(/\.c\(3, oz9\w*\.I, 0\)/g) || []).length >= 2,
  'original field-3 oz9 byte writes missing');
// u5j.s — the ModifyPage builder takes an oz9 bookmark argument (mask selects it).
ok(u5j.includes('oz9 oz9Var, int i') && u5j.includes('r0j.a(list, lxcVarA, m2dVar, oz9Var)'),
  'original ModifyPage bookmark builder missing');
// ae2.java — the content-manager toggle: any selected unbookmarked page flips the
// whole selection to BOOKMARKED, otherwise UNBOOKMARKED; one ModifyPage op.
ok(ae2.includes('oz9Var = oz9.BOOKMARKED') && ae2.includes('oz9Var = oz9.UNBOOKMARKED') &&
   ae2.includes('u5j.s(x09Var, list3, null, null, oz9Var, 6)') &&
   ae2.includes('!fw4Var.a.l()'),
  'original bookmark toggle semantics missing');
// de2.java:177 — an empty selection logs and returns without dispatching.
ok(de2.includes('Bookmark toggle with empty page selection'),
  'original empty-selection guard missing');
// md.java — the thumbnail overlay icon is bookmark_tall_fill / _outline.
ok(md.includes('ui_designsystem__bookmark_tall_fill') &&
   md.includes('ui_designsystem__bookmark_tall_outline'),
  'original bookmark thumbnail icons missing');
// nd2 — the content-manager filter has ALL / BOOKMARKS / NOTES chips.
ok(nd2.includes('new nd2("ALL", 0)') && nd2.includes('new nd2("BOOKMARKS", 1)') &&
   nd2.includes('new nd2("NOTES", 2)'),
  'original content-manager filter enum missing');
ok(n9j.includes('R.string.feature_note__content_manager_filter_bookmarks'),
  'original filter-bookmarks chip missing');
ok(origStrings.includes('feature_note__content_manager_bookmark') &&
   origStrings.includes('feature_note__content_manager_filter_bookmarks'),
  'original bookmark strings missing');

// --- Harmony schema anchors ----------------------------------------------------------
ok(db.includes('DB_VERSION: number = 70'), 'DB_VERSION must be 70');
ok(dbFixture.includes('expect(DB_VERSION).assertEqual(70)'),
  'database fixture must pin DB_VERSION 70');
// wz9.bookmarkedRegister parity — the LWW winner table keyed by page identity.
ok(db.includes('export const DDL_ORIGINAL_PAGE_BOOKMARK_WINNER') &&
   db.includes('original_page_bookmark_winner') &&
   db.includes("REFERENCES original_page_identity(note_id, seq_timestamp, seq_site_id, seq_index)") &&
   db.includes('bookmarked INTEGER NOT NULL CHECK (bookmarked IN (0, 1))'),
  'original_page_bookmark_winner DDL missing');
// bookmarked materializes on live pages, archived pages, and delete checkpoints.
ok(/CREATE TABLE IF NOT EXISTS page_info \([\s\S]*?bookmarked INTEGER NOT NULL DEFAULT 0/.test(db),
  'page_info.bookmarked missing');
ok(/CREATE TABLE IF NOT EXISTS original_deleted_page \([\s\S]*?bookmarked INTEGER NOT NULL DEFAULT 0/.test(db),
  'original_deleted_page.bookmarked missing');
ok(/CREATE TABLE IF NOT EXISTS page_delete_checkpoint \([\s\S]*?bookmarked INTEGER NOT NULL DEFAULT 0/.test(db),
  'page_delete_checkpoint.bookmarked missing');
// v70 migration: three ALTERs + winner DDL + register seed from page identity.
ok(/70: \[[\s\S]*?ALTER TABLE page_info ADD COLUMN bookmarked[\s\S]*?ALTER TABLE original_deleted_page ADD COLUMN bookmarked[\s\S]*?ALTER TABLE page_delete_checkpoint ADD COLUMN bookmarked[\s\S]*?DDL_ORIGINAL_PAGE_BOOKMARK_WINNER[\s\S]*?FROM original_page_identity/.test(db),
  'v70 bookmark migration missing');
ok(manager.includes('DDL_ORIGINAL_PAGE_BOOKMARK_WINNER'),
  'DatabaseManager must create the bookmark winner table');

// --- Harmony codec/applier anchors ----------------------------------------------------
// ge8.k() decode: field 3 presence + oz9 byte (absent = no write; any non-1 byte =
// UNBOOKMARKED per ln2.k()/oz9 ordinal mapping).
ok(modifyOp.includes('hasBookmarked: table.hasField(3)') &&
   modifyOp.includes('bookmarked: table.readUint8(3, 0) === 1'),
  'ModifyPage field-3 decode missing');
// LWW register: applyBookmark -> read/write winner -> materialize live or archived.
ok(modifyOp.includes('applyBookmark') && modifyOp.includes('readBookmarkWinner') &&
   modifyOp.includes('writeBookmarkWinner') && modifyOp.includes('updateMaterializedBookmark') &&
   modifyOp.includes('original_page_bookmark_winner') &&
   modifyOp.includes('compareOperationIdentity(operation, winner) <= 0'),
  'ModifyPage bookmark LWW path missing');
// Local write encoder: field 3 byte, moveTo/background omitted (vtable 0s).
ok(modifyEncoder.includes('export function encodeOriginalModifyPageBookmark') &&
   modifyEncoder.includes('[4, 0, 0, 12]') && modifyEncoder.includes('bookmarked ? 1 : 0'),
  'encodeOriginalModifyPageBookmark missing');
// CreatePage seeds the register and materializes bookmarked on the new page_info row.
ok(createOp.includes('bookmarked: table.readUint8(3, 0) === 1') &&
   createOp.includes("store.insert('original_page_bookmark_winner'") &&
   createOp.includes("'bookmarked': bookmarked ? 1 : 0"),
  'CreatePage bookmark seed missing');
ok(!createOp.includes('BOOKMARK_UNSUPPORTED') &&
   !modifyOp.includes('BOOKMARK_UNSUPPORTED') &&
   !bundle.includes('BOOKMARK_UNSUPPORTED'),
  'bookmark defer reasons must be removed');

// --- Harmony bundle/bootstrap anchors ---------------------------------------------------
ok(bundle.includes('bookmarked: boolean;') && bundle.includes('bookmarkWinner: OperationIdentity | null;'),
  'BootstrapPageState bookmark fields missing');
ok(bundle.includes('state.bookmarked = payload.bookmarked') &&
   bundle.includes('state.bookmarkWinner = { timestamp: operation.timestamp, siteId: operation.siteId }'),
  'bundle replay bookmark LWW missing');
ok(bundle.includes("store.insert('original_page_bookmark_winner'") &&
   bundle.includes('applyBootstrapBookmarks') &&
   bundle.includes("exactCount(store, 'original_page_bookmark_winner'") &&
   bundle.includes("'original_page_bookmark_winner',"),
  'bundle winner insert/reconcile/match missing');
ok(bundle.includes("'bookmarked': page.bookmarked ? 1 : 0"),
  'bundle archived-page bookmarked insert missing');

// --- Harmony runtime anchors ------------------------------------------------------------
ok(noteTypes.includes('bookmarked?: boolean;'), 'PageInfo.bookmarked missing');
ok(bgModel.includes('bookmarked: page.bookmarked'), 'clonePageInfo bookmarked missing');
ok(iface.includes('setPageBookmarked(noteId: string, pageId: string, bookmarked: boolean)'),
  'PageRepository.setPageBookmarked missing');
ok(pagePersistence.includes('export async function persistOriginalPageBookmark') &&
   pagePersistence.includes('encodeOriginalModifyPageBookmark([page], bookmarked)') &&
   pagePersistence.includes('ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE'),
  'persistOriginalPageBookmark missing');
ok(pageRepo.includes('async setPageBookmarked(noteId: string, pageId: string, bookmarked: boolean)') &&
   pageRepo.includes('persistOriginalPageBookmark(store, noteId, pageId, bookmarked)') &&
   pageRepo.includes("'bookmarked': bookmarked ? 1 : 0"),
  'PageRepositoryImpl.setPageBookmarked missing');
ok(pageRepo.includes('bookmarked: resultSet.getLong(resultSet.getColumnIndex(\'bookmarked\')) === 1'),
  'rowToPage/checkpoint bookmarked read missing');
// Delete/archive/restore carry bookmarked through original_deleted_page.
ok(deleteOp.includes('original_page_in_asset, bookmarked, content_revision') &&
   deleteOp.includes("'bookmarked': rows.getLong(rows.getColumnIndex('bookmarked'))"),
  'delete archive/restore bookmarked missing');
// Export/import round-trip keeps the flag.
ok(packageSpec.includes('bookmarked?: boolean;') &&
   packageSpec.includes("typeof parsed.bookmarked !== 'boolean'"),
  'PageData.bookmarked validation missing');
ok(exporter.includes('bookmarked: p.bookmarked') &&
   importer.includes('bookmarked: page.bookmarked'),
  'export/import bookmarked missing');

// --- Harmony UI anchors ------------------------------------------------------------------
ok(pageBar.includes('@Prop currentPageBookmarked: boolean = false;') &&
   pageBar.includes('onToggleBookmark: () => void'),
  'PageManagerBar bookmark prop/callback missing');
// md.java fill icon parity — the indicator marks the current page when bookmarked.
ok(/currentPageBookmarked[\s\S]*?Text\('🔖'\)/.test(pageBar),
  'bookmark indicator missing');
ok(pageBar.includes("value: $r('app.string.bookmark_page')"),
  'compact bookmark menu entry missing');
ok(notePage.includes('currentPageBookmarked: this.pages[this.currentPageIndex].bookmarked === true') &&
   notePage.includes('toggleCurrentPageBookmark') &&
   notePage.includes('setPageBookmarked('),
  'NotePage bookmark wiring missing');
ok(stringsBase.includes('"name": "bookmark_page"') && stringsZh.includes('"name": "bookmark_page"'),
  'bookmark_page strings missing');

// --- Executable model: ae2 toggle + wz9 LWW register --------------------------------------
// ae2: toggle = BOOKMARKED when any selected page is unbookmarked, else UNBOOKMARKED.
function toggleSelection(pages, selectedIds) {
  const selected = pages.filter(p => selectedIds.includes(p.id));
  // de2.m guard: empty selection never dispatches.
  if (selected.length === 0) return pages;
  const target = selected.some(p => !p.bookmarked) ? 1 : 0;
  return pages.map(p => selectedIds.includes(p.id) ? { ...p, bookmarked: target === 1 } : p);
}
const seq = (ts, site) => ({ timestamp: ts, siteId: site });
const cmp = (a, b) => a.timestamp !== b.timestamp ? a.timestamp - b.timestamp : a.siteId - b.siteId;
// wz9: the register is LWW — a strictly newer op wins; equal/older ops are dropped.
function applyBookmarkOp(state, op) {
  if (state.winner !== null && cmp(op.identity, state.winner) <= 0) return state;
  return { winner: op.identity, bookmarked: op.bookmarked };
}

const p = id => ({ id, bookmarked: false });
// Single selected unbookmarked page -> BOOKMARKED (the Harmony single-page toggle).
assert.deepEqual(toggleSelection([p('a'), p('b')], ['a']).map(x => x.bookmarked),
  [true, false]); checks++;
// Mixed selection -> all BOOKMARKED.
assert.deepEqual(
  toggleSelection([{ id: 'a', bookmarked: true }, p('b'), p('c')], ['a', 'b', 'c'])
    .map(x => x.bookmarked),
  [true, true, true]); checks++;
// All selected already bookmarked -> UNBOOKMARKED.
assert.deepEqual(
  toggleSelection([{ id: 'a', bookmarked: true }, { id: 'b', bookmarked: true }], ['a', 'b'])
    .map(x => x.bookmarked),
  [false, false]); checks++;
// Empty selection is a no-op (de2.m logs and returns).
assert.deepEqual(toggleSelection([p('a')], []).map(x => x.bookmarked), [false]); checks++;
// LWW: newer op wins regardless of value; equal/older op is dropped.
let reg = { winner: seq(10, 1), bookmarked: true };
reg = applyBookmarkOp(reg, { identity: seq(9, 9), bookmarked: false });
assert.equal(reg.bookmarked, true); checks++;            // older unbookmark dropped
reg = applyBookmarkOp(reg, { identity: seq(11, 0), bookmarked: false });
assert.equal(reg.bookmarked, false); checks++;           // newer unbookmark wins
reg = applyBookmarkOp(reg, { identity: seq(11, 0), bookmarked: true });
assert.equal(reg.bookmarked, false); checks++;           // identical identity dropped
reg = applyBookmarkOp(reg, { identity: seq(11, 1), bookmarked: true });
assert.equal(reg.bookmarked, true); checks++;            // same ts, higher siteId wins

console.log(`D02_ORIGINAL_PAGE_BOOKMARK_PARITY_OK TOTAL=${checks} FAILED=0`);
