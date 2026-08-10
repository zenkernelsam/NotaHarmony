import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');
const createInkSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalCreateInkOperation.ets', rootPath), 'utf8');
const deferredSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/DeferredSyncedOperationBundle.ets', rootPath), 'utf8');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,page_index INTEGER,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    INSERT INTO page_info VALUES('note','page-1',0,0);
    CREATE TABLE original_page_identity(note_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,
      page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,ts,site,idx));
    CREATE TABLE original_element_z_index(note_id TEXT,ts INTEGER,site INTEGER,page_ts INTEGER,
      page_site INTEGER,page_idx INTEGER,z_index TEXT,PRIMARY KEY(note_id,ts,site));
    CREATE TABLE original_ink_state(note_id TEXT,ts INTEGER,site INTEGER,path TEXT,
      PRIMARY KEY(note_id,ts,site));
    CREATE TABLE snapshot(note_id TEXT,page_id TEXT,element_id TEXT,payload TEXT,
      element_order INTEGER,revision INTEGER,PRIMARY KEY(note_id,page_id,element_id));`);
  return db;
}

const page = { type: 3, timestamp: 10, site: 1, count: 1 };
function ink(timestamp, site, zIndex, overrides = {}) {
  return { type: 15, timestamp, site, pageTimestamp: 10, pageSite: 1, pageIndex: 0,
    tool: 0, path: `path-${timestamp}`, zIndex, ...overrides };
}

function replay(db, operations, failAt = -1) {
  db.exec('BEGIN IMMEDIATE');
  try {
    for (const operation of operations) {
      if (operation.type !== 3 && operation.type !== 4 && operation.type !== 25 &&
        operation.type !== 15) throw new Error(`NOTE_BUNDLE_PAYLOAD_${operation.type}_UNSUPPORTED`);
      if (operation.type === 25 && (operation.entityDeleteCount || operation.entityUndeleteCount)) {
        throw new Error('NOTE_BUNDLE_ENTITY_VISIBILITY_UNSUPPORTED');
      }
      if (operation.type === 15 && operation.tool === 3) {
        throw new Error('NOTE_BUNDLE_CREATE_INK_TAPE_UNSUPPORTED');
      }
      if (operation.type === 15 && (operation.tool < 0 || operation.tool > 2)) {
        throw new Error('NOTE_BUNDLE_CREATE_INK_TOOL_UNSUPPORTED');
      }
      if (operation.type === 15 && !operation.path) {
        throw new Error('NOTE_BUNDLE_CREATE_INK_CENTER_PATH_MISSING');
      }
      if (operation.type === 15 && (operation.pageTimestamp !== 10 ||
        operation.pageSite !== 1 || operation.pageIndex !== 0)) {
        throw new Error('NOTE_BUNDLE_CREATE_INK_PAGE_MISSING');
      }
    }
    if (operations.some(operation => operation.type === 3)) {
      db.prepare(`INSERT OR IGNORE INTO original_page_identity VALUES('note',10,1,0,'page-1',1)`)
        .run();
    }
    let appliedInk = 0;
    for (const operation of operations.filter(value => value.type === 15)) {
      const element = db.prepare(`SELECT 1 FROM original_element_z_index
        WHERE note_id='note' AND ts=? AND site=?`).get(operation.timestamp, operation.site);
      const state = db.prepare(`SELECT 1 FROM original_ink_state
        WHERE note_id='note' AND ts=? AND site=?`).get(operation.timestamp, operation.site);
      if (element || state) {
        if (element && state) {
          const persisted = db.prepare(`SELECT z.z_index,s.path FROM original_element_z_index z
            JOIN original_ink_state s USING(note_id,ts,site)
            WHERE z.note_id='note' AND z.ts=? AND z.site=?`)
            .get(operation.timestamp, operation.site);
          if (persisted.path === operation.path && persisted.z_index === operation.zIndex) continue;
          throw new Error('identity conflicts with persisted create state');
        }
        throw new Error('partial persisted state');
      }
      const identity = db.prepare(`SELECT page_id FROM original_page_identity
        WHERE note_id='note' AND ts=? AND site=? AND idx=? AND visible=1`)
        .get(operation.pageTimestamp, operation.pageSite, operation.pageIndex);
      if (!identity) throw new Error('CREATE_INK_PAGE_MISSING_OR_UNBOUND');
      db.prepare(`INSERT INTO original_element_z_index VALUES('note',?,?,?,?,?,?)`).run(
        operation.timestamp, operation.site, operation.pageTimestamp, operation.pageSite,
        operation.pageIndex, operation.zIndex);
      db.prepare(`INSERT INTO original_ink_state VALUES('note',?,?,?)`).run(
        operation.timestamp, operation.site, operation.path);
      db.prepare(`INSERT INTO snapshot VALUES('note',?,?,?,0,0)`).run(identity.page_id,
        `${operation.timestamp}:${operation.site}`, JSON.stringify(operation));
      const ordered = db.prepare(`SELECT ts,site FROM original_element_z_index WHERE note_id='note'
        ORDER BY length(z_index),z_index,ts,site`).all();
      ordered.forEach((row, index) => db.prepare(`UPDATE snapshot SET element_order=?
        WHERE note_id='note' AND element_id=?`).run(index, `${row.ts}:${row.site}`));
      db.prepare(`UPDATE page_info SET content_revision=content_revision+1
        WHERE note_id='note' AND page_id=?`).run(identity.page_id);
      if (appliedInk++ === failAt) throw new Error('injected bundle content failure');
    }
    db.exec('COMMIT');
    return null;
  } catch (error) {
    db.exec('ROLLBACK');
    return error.message;
  }
}

const db = database();
const complete = [page, ink(20, 2, '20'), ink(30, 3, '5')];
assert.equal(replay(db, complete), null);
assert.equal(db.prepare('SELECT count(*) count FROM original_page_identity').get().count, 1);
assert.equal(db.prepare('SELECT count(*) count FROM original_ink_state').get().count, 2);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);
assert.equal(replay(db, [page, ink(20, 2, '20', { path: 'conflicting' })]),
  'identity conflicts with persisted create state');
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);
assert.deepEqual(db.prepare('SELECT element_id FROM snapshot ORDER BY element_order').all()
  .map(row => row.element_id), ['30:3', '20:2']);
const snapshot = JSON.stringify(db.prepare('SELECT * FROM snapshot ORDER BY element_id').all());
assert.equal(replay(db, complete), null);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM snapshot ORDER BY element_id').all()), snapshot);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);

for (const operations of [[page, { type: 22 }], [page, ink(20, 2, '1', { tool: 3 })],
  [page, ink(20, 2, '1', { pageTimestamp: 99 })],
  [page, ink(20, 2, '1'), { type: 25, entityDeleteCount: 1 }]]) {
  const rejected = database();
  assert.match(replay(rejected, operations), /UNSUPPORTED|PAGE_MISSING/);
  assert.equal(rejected.prepare('SELECT count(*) count FROM original_page_identity').get().count, 0);
  assert.equal(rejected.prepare('SELECT count(*) count FROM original_ink_state').get().count, 0);
}

const failed = database();
assert.equal(replay(failed, complete, 0), 'injected bundle content failure');
assert.equal(failed.prepare('SELECT count(*) count FROM original_page_identity').get().count, 0);
assert.equal(failed.prepare('SELECT count(*) count FROM original_element_z_index').get().count, 0);
assert.equal(failed.prepare('SELECT count(*) count FROM original_ink_state').get().count, 0);
assert.equal(failed.prepare('SELECT count(*) count FROM snapshot').get().count, 0);
assert.equal(failed.prepare('SELECT content_revision FROM page_info').get().content_revision, 0);

assert.ok(bundleSource.indexOf('preflightBundleContent(bundle, history)') <
  bundleSource.indexOf('insertBootstrapHistory(store'));
assert.match(bundleSource, /NOTE_BUNDLE_PAYLOAD_\$\{operation\.payloadType\}_UNSUPPORTED/);
assert.match(bundleSource, /NOTE_BUNDLE_ENTITY_VISIBILITY_UNSUPPORTED/);
assert.match(bundleSource, /await createInk\.applyTable/);
assert.match(createInkSource, /elementExists && inkStateExists[\s\S]*originalCreateMatches/);
assert.match(createInkSource, /original create-ink has partial persisted state/);
assert.match(createInkSource, /identity conflicts with persisted create state/);
assert.match(deferredSource,
  /if \(result\.deferredReason !== null\) \{\s*await this\.store\.rollBack\(\)/);

console.log('success|bundle-create-ink=2|z-order=1|revision=2|retry-idempotent=1|' +
  'conflicting-identity-rejected=1|' +
  'unknown-zero-write=1|tape-zero-write=1|missing-page-zero-write=1|' +
  'entity-visibility-zero-write=1|' +
  'content-failure-full-rollback=1|preflight-before-page-write=1');
