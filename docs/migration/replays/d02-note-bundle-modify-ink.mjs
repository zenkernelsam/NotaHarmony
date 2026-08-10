import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');
const modifySource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalModifyInkOperation.ets', rootPath), 'utf8');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    INSERT INTO page_info VALUES('note','page',0);
    CREATE TABLE ink_state(note_id TEXT,ink_ts INTEGER,ink_site INTEGER,
      width REAL NOT NULL,width_ts INTEGER,width_site INTEGER,width_present INTEGER NOT NULL,
      style INTEGER NOT NULL,style_ts INTEGER,style_site INTEGER,style_present INTEGER NOT NULL,
      PRIMARY KEY(note_id,ink_ts,ink_site));
    INSERT INTO ink_state VALUES('note',20,2,4,NULL,NULL,0,0,NULL,NULL,0);
    INSERT INTO ink_state VALUES('note',21,2,4,NULL,NULL,0,0,NULL,NULL,0);
    CREATE TABLE snapshot(note_id TEXT,page_id TEXT,element_id TEXT,width REAL,style INTEGER,
      revision INTEGER,PRIMARY KEY(note_id,page_id,element_id));
    INSERT INTO snapshot VALUES('note','page','20:2',4,0,0);
    INSERT INTO snapshot VALUES('note','page','21:2',4,0,0);`);
  return db;
}

function compare(leftTs, leftSite, rightTs, rightSite) {
  if (leftTs === null) return -1;
  return leftTs === rightTs ? Math.sign(leftSite - rightSite) : Math.sign(leftTs - rightTs);
}

function applyModify(db, operation, failAfter = 0) {
  db.exec('BEGIN IMMEDIATE');
  try {
    let changed = false;
    let mutationCount = 0;
    for (const ink of operation.inks) {
      const state = db.prepare(`SELECT * FROM ink_state WHERE note_id='note'
        AND ink_ts=? AND ink_site=?`).get(ink.timestamp, ink.siteId);
      if (!state) throw new Error('MODIFY_INK_TARGET_MISSING_OR_UNBOUND');
      const widthOrder = operation.width === null ? 1 :
        compare(state.width_ts, state.width_site, operation.timestamp, operation.site);
      const styleOrder = operation.style === null ? 1 :
        compare(state.style_ts, state.style_site, operation.timestamp, operation.site);
      if (widthOrder === 0 && state.width !== operation.width) {
        throw new Error('identity conflicts with persisted width');
      }
      if (styleOrder === 0 && state.style !== operation.style) {
        throw new Error('identity conflicts with persisted style');
      }
      const replaceWidth = operation.width !== null && widthOrder < 0;
      const replaceStyle = operation.style !== null && styleOrder < 0;
      if (!replaceWidth && !replaceStyle) continue;
      db.prepare(`UPDATE ink_state SET
        width=CASE WHEN ? THEN ? ELSE width END,
        width_ts=CASE WHEN ? THEN ? ELSE width_ts END,
        width_site=CASE WHEN ? THEN ? ELSE width_site END,
        width_present=CASE WHEN ? THEN 1 ELSE width_present END,
        style=CASE WHEN ? THEN ? ELSE style END,
        style_ts=CASE WHEN ? THEN ? ELSE style_ts END,
        style_site=CASE WHEN ? THEN ? ELSE style_site END,
        style_present=CASE WHEN ? THEN 1 ELSE style_present END
        WHERE note_id='note' AND ink_ts=? AND ink_site=?`).run(
        replaceWidth ? 1 : 0, operation.width, replaceWidth ? 1 : 0, operation.timestamp,
        replaceWidth ? 1 : 0, operation.site, replaceWidth ? 1 : 0,
        replaceStyle ? 1 : 0, operation.style, replaceStyle ? 1 : 0, operation.timestamp,
        replaceStyle ? 1 : 0, operation.site, replaceStyle ? 1 : 0, ink.timestamp, ink.siteId);
      db.prepare(`UPDATE snapshot SET
        width=CASE WHEN ? THEN ? ELSE width END,
        style=CASE WHEN ? THEN ? ELSE style END,revision=revision+1
        WHERE note_id='note' AND element_id=?`).run(
        replaceWidth ? 1 : 0, operation.width, replaceStyle ? 1 : 0, operation.style,
        `${ink.timestamp}:${ink.siteId}`);
      changed = true;
      mutationCount++;
      if (failAfter > 0 && mutationCount === failAfter) {
        throw new Error('injected bundle modify failure');
      }
    }
    if (changed) {
      db.exec(`UPDATE page_info SET content_revision=content_revision+1
        WHERE note_id='note' AND page_id='page'`);
    }
    db.exec('COMMIT');
    return changed;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const operation = {
  timestamp: 40, site: 4,
  inks: [{ timestamp: 20, siteId: 2 }, { timestamp: 21, siteId: 2 }],
  width: 9, style: 2,
};
const db = database();
assert.equal(applyModify(db, operation), true);
assert.deepEqual(db.prepare('SELECT width,style FROM snapshot ORDER BY element_id').all()
  .map(row => ({ width: row.width, style: row.style })), [
  { width: 9, style: 2 }, { width: 9, style: 2 },
]);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 1);
assert.equal(applyModify(db, operation), false);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 1);
assert.throws(() => applyModify(db, { ...operation, width: 10 }),
  /identity conflicts with persisted width/);

assert.equal(applyModify(db, { ...operation, timestamp: 30, width: 7, style: null }), false);
assert.equal(applyModify(db, { ...operation, timestamp: 50, width: 11, style: null }), true);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);
assert.deepEqual(db.prepare('SELECT width,style FROM snapshot ORDER BY element_id').all()
  .map(row => ({ width: row.width, style: row.style })), [
  { width: 11, style: 2 }, { width: 11, style: 2 },
]);

const failed = database();
assert.throws(() => applyModify(failed, operation, 2), /injected bundle modify failure/);
assert.equal(failed.prepare('SELECT content_revision FROM page_info').get().content_revision, 0);
assert.deepEqual(failed.prepare('SELECT width,style FROM snapshot ORDER BY element_id').all()
  .map(row => ({ width: row.width, style: row.style })), [
  { width: 4, style: 0 }, { width: 4, style: 0 },
]);

assert.match(modifySource, /preflightTable\(table: OriginalFlatBufferTableReader\)/);
assert.match(modifySource, /async applyTable[\s\S]*decodeOriginalModifyInkTable/);
assert.match(modifySource, /assertMatchingModifyInkWinners\(payload, state, operation\)/);
assert.match(modifySource, /persisted center path/);
assert.match(modifySource, /persisted custom path/);
assert.match(modifySource, /persisted fill path/);
assert.match(modifySource, /persisted fill color/);
assert.match(modifySource, /persisted style map/);
assert.match(modifySource, /persisted rotation/);
assert.match(modifySource, /persisted scale/);
assert.match(modifySource, /persisted page\/origin/);
assert.match(modifySource, /persisted z-index/);
assert.match(bundleSource, /ORIGINAL_MODIFY_INK_PAYLOAD_TYPE/);
assert.match(bundleSource, /modifyInk\.preflightTable/);
assert.match(bundleSource, /await modifyInk\.applyTable/);

console.log('success|bundle-modify-two-ink=1|single-page-revision=1|retry-idempotent=1|' +
  'same-identity-conflict=2|stale-noop=1|newer-winner=1|rollback=2|' +
  'all-register-conflict-guards=12|table-preflight=1');
