import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');
const inkSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalCreateInkOperation.ets', rootPath), 'utf8');
const blockSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalCreateBlockOperation.ets', rootPath), 'utf8');

const NOTE = '00112233-4455-6677-8899-aabbccddeeff';
const livePage = { timestamp: 10, site: 1, index: 0 };
const archivedContentPage = { timestamp: 10, site: 1, index: 1 };
const archivedMovePage = { timestamp: 10, site: 1, index: 2 };
const emptyTombstone = { timestamp: 10, site: 1, index: 3 };
const key = page => `${page.timestamp}:${page.site}:${page.index}`;
const storageId = page => `original-page:${NOTE.length}:${NOTE}:` +
  `seq:${page.timestamp.toString(16)}:${page.site.toString(16)}:${page.index.toString(16)}`;

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY,background TEXT NOT NULL);
    INSERT INTO note_meta VALUES('${NOTE}','paper-old');
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,page_index INTEGER,content_revision INTEGER,
      background TEXT,PRIMARY KEY(note_id,page_id),UNIQUE(note_id,page_index));
    INSERT INTO page_info VALUES('${NOTE}','local-live',0,0,'paper-old');
    CREATE TABLE original_page_identity(note_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,
      page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,ts,site,idx),UNIQUE(note_id,page_id));
    CREATE TABLE original_deleted_page(note_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,
      page_id TEXT,content_revision INTEGER,background TEXT,
      PRIMARY KEY(note_id,ts,site,idx),UNIQUE(note_id,page_id));
    CREATE TABLE archived_snapshot(note_id TEXT,page_ts INTEGER,page_site INTEGER,page_idx INTEGER,
      element_id TEXT,kind INTEGER,payload TEXT,element_order INTEGER,revision INTEGER,
      PRIMARY KEY(note_id,page_ts,page_site,page_idx,element_id));
    CREATE TABLE original_element_z_index(note_id TEXT,ts INTEGER,site INTEGER,page_ts INTEGER,
      page_site INTEGER,page_idx INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,ts,site));
    CREATE TABLE original_ink_state(note_id TEXT,ts INTEGER,site INTEGER,baseline TEXT,
      PRIMARY KEY(note_id,ts,site));
    CREATE TABLE original_block_state(note_id TEXT,ts INTEGER,site INTEGER,baseline TEXT,
      PRIMARY KEY(note_id,ts,site));`);
  return db;
}

const operations = [
  { type: 15, timestamp: 20, site: 2, page: archivedContentPage, zIndex: '20',
    payload: 'ink' },
  { type: 22, timestamp: 30, site: 3, page: archivedContentPage, zIndex: '5',
    payload: 'text' },
  { type: 17, timestamp: 40, site: 4, inkTimestamp: 20, inkSite: 2,
    pageOrigin: archivedMovePage },
];

function bootstrap(db, failAfter = -1) {
  if (mappingMatches(db) && contentMatches(db)) return null;
  const existing = ['original_page_identity', 'original_deleted_page',
    'original_element_z_index', 'original_ink_state', 'original_block_state',
    'archived_snapshot'].reduce((total, table) => total +
      db.prepare(`SELECT COUNT(*) count FROM ${table}`).get().count, 0);
  if (existing !== 0) return 'archived-content identity conflict';
  db.exec('BEGIN IMMEDIATE');
  try {
    const pages = [livePage, archivedContentPage, archivedMovePage, emptyTombstone];
    const contentPages = new Set(operations.map(operation =>
      key(operation.type === 17 ? operation.pageOrigin : operation.page)));
    const pageIds = new Map([[key(livePage), 'local-live']]);
    for (const page of pages) {
      if (contentPages.has(key(page)) && key(page) !== key(livePage)) {
        pageIds.set(key(page), storageId(page));
      }
    }
    const insertIdentity = db.prepare(
      `INSERT INTO original_page_identity VALUES(?,?,?,?,?,?)`);
    for (const page of pages) {
      const pageId = pageIds.get(key(page)) ?? null;
      insertIdentity.run(NOTE, page.timestamp, page.site, page.index,
        pageId, pageId === null ? 0 : 1);
    }
    for (const page of [archivedContentPage, archivedMovePage]) {
      db.prepare(`INSERT INTO original_deleted_page VALUES(?,?,?,?,?,0,'paper-old')`).run(
        NOTE, page.timestamp, page.site, page.index, storageId(page));
    }

    let applied = 0;
    for (const operation of operations.filter(value => value.type === 15 || value.type === 22)) {
      const stateTable = operation.type === 15 ? 'original_ink_state' : 'original_block_state';
      const kind = operation.type === 15 ? 1 : 2;
      db.prepare(`INSERT INTO original_element_z_index VALUES(?,?,?,?,?,?,?,?)`).run(
        NOTE, operation.timestamp, operation.site, operation.page.timestamp,
        operation.page.site, operation.page.index, kind, operation.zIndex);
      db.prepare(`INSERT INTO ${stateTable} VALUES(?,?,?,?)`).run(
        NOTE, operation.timestamp, operation.site, operation.payload);
      db.prepare(`INSERT INTO archived_snapshot VALUES(?,?,?,?,?,?,?,?,?)`).run(
        NOTE, operation.page.timestamp, operation.page.site, operation.page.index,
        `${operation.timestamp}:${operation.site}`, kind, operation.payload, 0, applied + 1);
      const order = db.prepare(`SELECT ts,site FROM original_element_z_index
        WHERE note_id=? AND page_ts=? AND page_site=? AND page_idx=?
        ORDER BY length(z_index),z_index,ts,site`).all(
        NOTE, operation.page.timestamp, operation.page.site, operation.page.index);
      order.forEach((row, index) => db.prepare(`UPDATE archived_snapshot SET element_order=?
        WHERE note_id=? AND element_id=?`).run(index, NOTE, `${row.ts}:${row.site}`));
      db.prepare(`UPDATE original_deleted_page SET content_revision=content_revision+1
        WHERE note_id=? AND ts=? AND site=? AND idx=?`).run(
        NOTE, operation.page.timestamp, operation.page.site, operation.page.index);
      applied++;
      if (applied === failAfter) throw new Error('injected archived-content failure');
    }

    const move = operations.find(value => value.type === 17);
    const moved = db.prepare(`SELECT element_id,kind,payload FROM archived_snapshot
      WHERE note_id=? AND page_ts=? AND page_site=? AND page_idx=? AND element_id='20:2'`).get(
      NOTE, archivedContentPage.timestamp, archivedContentPage.site, archivedContentPage.index);
    assert(moved !== undefined && move !== undefined);
    db.prepare(`DELETE FROM archived_snapshot WHERE note_id=? AND page_ts=? AND page_site=?
      AND page_idx=? AND element_id='20:2'`).run(
      NOTE, archivedContentPage.timestamp, archivedContentPage.site, archivedContentPage.index);
    db.prepare(`UPDATE archived_snapshot SET element_order=0 WHERE note_id=? AND page_ts=?
      AND page_site=? AND page_idx=?`).run(
      NOTE, archivedContentPage.timestamp, archivedContentPage.site, archivedContentPage.index);
    db.prepare(`UPDATE original_element_z_index SET page_ts=?,page_site=?,page_idx=?
      WHERE note_id=? AND ts=? AND site=?`).run(move.pageOrigin.timestamp,
      move.pageOrigin.site, move.pageOrigin.index, NOTE, move.inkTimestamp, move.inkSite);
    db.prepare(`INSERT INTO archived_snapshot VALUES(?,?,?,?,?,?,?,?,1)`).run(
      NOTE, move.pageOrigin.timestamp, move.pageOrigin.site, move.pageOrigin.index,
      moved.element_id, moved.kind, moved.payload, 0);
    db.prepare(`UPDATE original_deleted_page SET content_revision=content_revision+1
      WHERE note_id=? AND ts=? AND site=? AND idx=?`).run(
      NOTE, archivedContentPage.timestamp, archivedContentPage.site, archivedContentPage.index);
    db.prepare(`UPDATE original_deleted_page SET content_revision=content_revision+1
      WHERE note_id=? AND ts=? AND site=? AND idx=?`).run(
      NOTE, move.pageOrigin.timestamp, move.pageOrigin.site, move.pageOrigin.index);

    // SET_METADATA is applied before final page-background materialization.
    db.prepare(`UPDATE note_meta SET background='paper-new' WHERE id=?`).run(NOTE);
    db.prepare(`UPDATE original_deleted_page SET background=(
      SELECT background FROM note_meta WHERE id=?) WHERE note_id=?`).run(NOTE, NOTE);
    db.exec('COMMIT');
    return null;
  } catch (error) {
    db.exec('ROLLBACK');
    return error.message;
  }
}

function mappingMatches(db) {
  const archived = db.prepare(`SELECT page_id,content_revision,background
    FROM original_deleted_page WHERE note_id=? AND ts=10 AND site=1 AND idx=1`).get(NOTE);
  const moved = db.prepare(`SELECT page_id,content_revision,background
    FROM original_deleted_page WHERE note_id=? AND ts=10 AND site=1 AND idx=2`).get(NOTE);
  const empty = db.prepare(`SELECT page_id,visible FROM original_page_identity
    WHERE note_id=? AND ts=10 AND site=1 AND idx=3`).get(NOTE);
  return archived?.page_id === storageId(archivedContentPage) &&
    archived.content_revision === 3 && archived.background === 'paper-new' &&
    moved?.page_id === storageId(archivedMovePage) && moved.content_revision === 1 &&
    moved.background === 'paper-new' &&
    empty?.page_id === null && empty.visible === 0 &&
    db.prepare('SELECT COUNT(*) count FROM original_deleted_page').get().count === 2;
}

function contentMatches(db) {
  const ink = db.prepare(`SELECT baseline FROM original_ink_state
    WHERE note_id=? AND ts=20 AND site=2`).get(NOTE);
  const block = db.prepare(`SELECT baseline FROM original_block_state
    WHERE note_id=? AND ts=30 AND site=3`).get(NOTE);
  const snapshots = db.prepare(`SELECT page_idx,element_id,kind,payload,element_order
    FROM archived_snapshot WHERE note_id=? ORDER BY page_idx,element_order`).all(NOTE);
  return ink?.baseline === 'ink' && block?.baseline === 'text' &&
    JSON.stringify(snapshots) === JSON.stringify([
      { page_idx: 1, element_id: '30:3', kind: 2, payload: 'text', element_order: 0 },
      { page_idx: 2, element_id: '20:2', kind: 1, payload: 'ink', element_order: 0 },
    ]);
}

const db = database();
assert.equal(bootstrap(db), null);
assert.equal(mappingMatches(db), true);
assert.deepEqual(db.prepare(`SELECT element_id FROM archived_snapshot
  ORDER BY page_idx,element_order`).all().map(row => row.element_id), ['30:3', '20:2']);
assert.equal(db.prepare(`SELECT visible FROM original_page_identity
  WHERE note_id=? AND ts=10 AND site=1 AND idx=1`).get(NOTE).visible, 1);
const retrySnapshot = JSON.stringify(db.prepare(`SELECT * FROM archived_snapshot
  ORDER BY element_order`).all());
assert.equal(bootstrap(db), null);
assert.equal(JSON.stringify(db.prepare(`SELECT * FROM archived_snapshot
  ORDER BY element_order`).all()), retrySnapshot);
assert.equal(db.prepare(`SELECT content_revision FROM original_deleted_page`).get()
  .content_revision, 3);

const conflict = database();
conflict.prepare(`INSERT INTO original_page_identity VALUES(?,?,?,?,?,1)`).run(
  NOTE, archivedContentPage.timestamp, archivedContentPage.site, archivedContentPage.index,
  'wrong-archive-id');
assert.equal(bootstrap(conflict), 'archived-content identity conflict');
assert.equal(conflict.prepare('SELECT COUNT(*) count FROM original_deleted_page').get().count, 0);

// A future page undelete can restore the same stable page ID and both elements.
db.exec('BEGIN IMMEDIATE');
db.prepare(`INSERT INTO page_info SELECT note_id,page_id,1,content_revision,background
  FROM original_deleted_page WHERE note_id=? AND ts=10 AND site=1 AND idx=1`).run(NOTE);
const restored = db.prepare(`SELECT element_id,payload FROM archived_snapshot
  WHERE note_id=? AND page_idx=1 ORDER BY element_order`).all(NOTE);
db.prepare(`DELETE FROM original_deleted_page WHERE note_id=? AND ts=10 AND site=1 AND idx=1`).run(NOTE);
db.exec('COMMIT');
assert.deepEqual(restored.map(row => row.element_id), ['30:3']);
assert.equal(db.prepare(`SELECT page_id FROM page_info WHERE note_id=? AND page_index=1`).get(NOTE).page_id,
  storageId(archivedContentPage));
assert.equal(db.prepare(`SELECT element_id FROM archived_snapshot WHERE note_id=? AND page_idx=2`).get(NOTE)
  .element_id, '20:2');

const failed = database();
assert.equal(bootstrap(failed, 1), 'injected archived-content failure');
assert.equal(failed.prepare('SELECT COUNT(*) count FROM original_page_identity').get().count, 0);
assert.equal(failed.prepare('SELECT COUNT(*) count FROM original_deleted_page').get().count, 0);
assert.equal(failed.prepare('SELECT COUNT(*) count FROM original_ink_state').get().count, 0);
assert.equal(failed.prepare('SELECT COUNT(*) count FROM archived_snapshot').get().count, 0);
assert.equal(failed.prepare('SELECT background FROM note_meta').get().background, 'paper-old');

assert.doesNotMatch(bundleSource, /NOTE_BUNDLE_CREATE_INK_ARCHIVED_PAGE_UNSUPPORTED/);
assert.match(bundleSource, /bindArchivedContentPages\(history, bundle, expectedNoteId/);
assert.match(bundleSource, /encodeOriginalPageStorageId\(noteId, page\.identity\)/);
assert.match(bundleSource, /await store\.insert\('original_deleted_page'/);
assert.match(bundleSource, /countBoundArchivedPages\(history, pageIdBySequence\)/);
assert.match(bundleSource, /const table: string = archived \? 'original_deleted_page' : 'page_info'/);
assert.match(bundleSource, /NOTE_BUNDLE_MODIFY_INK_DESTINATION_PAGE_MISSING/);
assert.match(bundleSource, /NOTE_BUNDLE_MODIFY_BLOCK_DESTINATION_PAGE_MISSING/);
assert.match(inkSource, /table: 'original_deleted_page_element'/);
assert.match(blockSource, /table: 'original_deleted_page_element'/);

console.log('success|note-bundle-archived-content=1|ink=1|block=1|stable-page-id=1|' +
  'empty-tombstone-unbound=1|revisions=3+1|background-final=1|restore=1|' +
  'cross-page-move=1|z-order=1|exact-retry=1|mapping-conflict=1|' +
  'failure-full-rollback=1');
