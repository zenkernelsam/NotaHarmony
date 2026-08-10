import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');
const addSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalAddPathElementsOperation.ets', rootPath), 'utf8');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    INSERT INTO page_info VALUES('note','page',0);
    CREATE TABLE original_element_z_index(note_id TEXT,ts INTEGER,site INTEGER,page_id TEXT,
      PRIMARY KEY(note_id,ts,site));
    INSERT INTO original_element_z_index VALUES('note',20,2,'page');
    CREATE TABLE original_ink_state(note_id TEXT,ts INTEGER,site INTEGER,base_path TEXT,
      estimated_path TEXT NOT NULL,estimated_ts INTEGER,estimated_site INTEGER,
      estimated_present INTEGER NOT NULL,PRIMARY KEY(note_id,ts,site));
    INSERT INTO original_ink_state VALUES('note',20,2,'base','',0,0,0);
    CREATE TABLE original_ink_path_append(note_id TEXT,ink_ts INTEGER,ink_site INTEGER,
      append_ts INTEGER,append_site INTEGER,path TEXT,
      PRIMARY KEY(note_id,ink_ts,ink_site,append_ts,append_site));
    CREATE TABLE snapshot(note_id TEXT,page_id TEXT,element_id TEXT,path TEXT,revision INTEGER,
      PRIMARY KEY(note_id,page_id,element_id));
    INSERT INTO snapshot VALUES('note','page','20:2','["base"]',0);`);
  return db;
}

function compare(leftTs, leftSite, rightTs, rightSite) {
  return leftTs === rightTs ? Math.sign(leftSite - rightSite) : Math.sign(leftTs - rightTs);
}

function applyAdd(db, operation, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    if (operation.actual === null && operation.estimated === null) {
      throw new Error('MALFORMED_ADD_PATH_ELEMENTS_PAYLOAD');
    }
    const state = db.prepare(`SELECT * FROM original_ink_state
      WHERE note_id='note' AND ts=? AND site=?`).get(operation.inkTs, operation.inkSite);
    if (!state) throw new Error('ADD_PATH_ELEMENTS_INK_MISSING_OR_UNBOUND');
    const existing = db.prepare(`SELECT path FROM original_ink_path_append
      WHERE note_id='note' AND ink_ts=? AND ink_site=? AND append_ts=? AND append_site=?`)
      .get(operation.inkTs, operation.inkSite, operation.timestamp, operation.site);
    if (existing && operation.actual === null) {
      throw new Error('identity conflicts with persisted actual path');
    }
    if (existing && existing.path !== operation.actual) {
      throw new Error('identity conflicts with persisted actual path');
    }
    const sameEstimatedWinner = state.estimated_present === 1 &&
      compare(state.estimated_ts, state.estimated_site, operation.timestamp, operation.site) === 0;
    const incomingEstimated = operation.estimated ?? '';
    if (sameEstimatedWinner && state.estimated_path !== incomingEstimated) {
      throw new Error('identity conflicts with persisted estimated path');
    }
    const estimatedComparison = state.estimated_present === 0 ? null :
      compare(state.estimated_ts, state.estimated_site, operation.timestamp, operation.site);
    if (existing) {
      if (estimatedComparison === null || estimatedComparison < 0) {
        throw new Error('partial persisted state');
      }
      db.exec('COMMIT');
      return false;
    }
    if (operation.actual !== null && estimatedComparison === 0) {
      throw new Error('partial persisted state');
    }
    if (operation.actual === null && estimatedComparison !== null && estimatedComparison >= 0) {
      db.exec('COMMIT');
      return false;
    }
    const replaceEstimated = state.estimated_present === 0 ||
      compare(operation.timestamp, operation.site, state.estimated_ts, state.estimated_site) > 0;
    if (operation.actual === null && !replaceEstimated) {
      db.exec('COMMIT');
      return false;
    }
    if (!existing && operation.actual !== null) {
      db.prepare(`INSERT INTO original_ink_path_append VALUES('note',?,?,?,?,?)`).run(
        operation.inkTs, operation.inkSite, operation.timestamp, operation.site, operation.actual);
    }
    if (replaceEstimated) {
      db.prepare(`UPDATE original_ink_state SET estimated_path=?,estimated_ts=?,estimated_site=?,
        estimated_present=1 WHERE note_id='note' AND ts=? AND site=?`).run(
        incomingEstimated, operation.timestamp, operation.site, operation.inkTs, operation.inkSite);
    }
    const current = db.prepare(`SELECT base_path,estimated_path FROM original_ink_state
      WHERE note_id='note' AND ts=? AND site=?`).get(operation.inkTs, operation.inkSite);
    const appends = db.prepare(`SELECT path FROM original_ink_path_append WHERE note_id='note'
      AND ink_ts=? AND ink_site=? ORDER BY append_ts,append_site`)
      .all(operation.inkTs, operation.inkSite).map(row => row.path);
    const path = [current.base_path, ...appends];
    if (current.estimated_path !== '') path.push(`estimated:${current.estimated_path}`);
    db.prepare(`UPDATE snapshot SET path=?,revision=revision+1
      WHERE note_id='note' AND element_id='20:2'`).run(JSON.stringify(path));
    db.prepare(`UPDATE page_info SET content_revision=content_revision+1
      WHERE note_id='note' AND page_id='page'`).run();
    if (fail) throw new Error('injected bundle add failure');
    db.exec('COMMIT');
    return true;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const db = database();
const first = { inkTs: 20, inkSite: 2, timestamp: 30, site: 3,
  actual: 'actual-a', estimated: 'estimate-a' };
assert.equal(applyAdd(db, first), true);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 1);
assert.equal(db.prepare('SELECT estimated_path FROM original_ink_state').get().estimated_path,
  'estimate-a');
const afterFirst = db.prepare('SELECT path FROM snapshot').get().path;
assert.equal(applyAdd(db, first), false);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 1);
assert.equal(db.prepare('SELECT path FROM snapshot').get().path, afterFirst);
assert.throws(() => applyAdd(db, { ...first, actual: 'conflicting' }),
  /conflicts with persisted actual/);

assert.equal(applyAdd(db, { inkTs: 20, inkSite: 2, timestamp: 40, site: 1,
  actual: 'actual-b', estimated: null }), true);
assert.equal(db.prepare('SELECT estimated_path FROM original_ink_state').get().estimated_path, '');
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);
assert.equal(applyAdd(db, { inkTs: 20, inkSite: 2, timestamp: 35, site: 9,
  actual: null, estimated: 'stale' }), false);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);
const estimated = { inkTs: 20, inkSite: 2, timestamp: 50, site: 1,
  actual: null, estimated: 'estimate-new' };
assert.equal(applyAdd(db, estimated), true);
assert.equal(applyAdd(db, estimated), false);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 3);
assert.throws(() => applyAdd(db, { ...estimated, estimated: 'conflicting-estimate' }),
  /conflicts with persisted estimated/);

const partial = database();
partial.exec(`UPDATE original_ink_state SET estimated_path='estimate-a',estimated_ts=30,
  estimated_site=3,estimated_present=1`);
assert.throws(() => applyAdd(partial, first), /partial persisted state/);
assert.equal(partial.prepare('SELECT count(*) count FROM original_ink_path_append').get().count, 0);

const failed = database();
assert.throws(() => applyAdd(failed, first, true), /injected bundle add failure/);
assert.equal(failed.prepare('SELECT count(*) count FROM original_ink_path_append').get().count, 0);
assert.equal(failed.prepare('SELECT content_revision FROM page_info').get().content_revision, 0);
assert.equal(failed.prepare('SELECT path FROM snapshot').get().path, '["base"]');

assert.match(addSource, /preflightTable\(table: OriginalFlatBufferTableReader\)/);
assert.match(addSource, /async applyTable[\s\S]*decodeOriginalAddPathElementsTable/);
assert.match(addSource, /existingAppend !== undefined[\s\S]*sameBytes/);
assert.match(addSource, /persisted estimated path/);
assert.match(addSource, /original add-path-elements has partial persisted state/);
assert.match(addSource,
  /operationAlreadyApplied[\s\S]*originalInkGeometryMatches[\s\S]*operationAlreadyApplied/);
assert.match(bundleSource, /ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE/);
assert.match(bundleSource, /await addPath\.applyTable/);
assert.match(bundleSource, /revisionAfter > revisionBefore/);

console.log('success|bundle-add-actual=2|estimated-lww=3|actual-only-clear=1|' +
  'stale-estimated-noop=1|actual-retry-idempotent=1|estimated-retry-idempotent=1|' +
  'actual-conflict=1|estimated-conflict=1|partial-state=1|failure-rollback=1|' +
  'retry-geometry-check=1|revision-marker=1');
