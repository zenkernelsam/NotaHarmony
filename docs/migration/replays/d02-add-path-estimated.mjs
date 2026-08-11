import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=41;
    CREATE TABLE ink_state(note_id TEXT,ink_timestamp INTEGER,ink_site_id INTEGER,
      base_path BLOB NOT NULL,PRIMARY KEY(note_id,ink_timestamp,ink_site_id));
    CREATE TABLE actual_append(note_id TEXT,ink_timestamp INTEGER,ink_site_id INTEGER,
      timestamp INTEGER,site_id INTEGER,path TEXT NOT NULL,PRIMARY KEY(note_id,timestamp,site_id));
    CREATE TABLE snapshot(ink_timestamp INTEGER,ink_site_id INTEGER,path TEXT NOT NULL,revision INTEGER,
      PRIMARY KEY(ink_timestamp,ink_site_id));
    CREATE TABLE page(revision INTEGER NOT NULL);
    INSERT INTO ink_state VALUES('n',20,2,x'5b302c31305d');
    INSERT INTO snapshot VALUES(20,2,'[0,10]',1);
    INSERT INTO page VALUES(1);`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE ink_state ADD COLUMN estimated_center_path BLOB NOT NULL DEFAULT X''
        CHECK(length(estimated_center_path)=0 OR length(estimated_center_path) BETWEEN 3 AND 16777216);
      ALTER TABLE ink_state ADD COLUMN estimated_path_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN estimated_path_winner_site_id INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN estimated_path_winner_present INTEGER NOT NULL DEFAULT 0;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=42; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function newer(timestamp, site, state) {
  return state.estimated_path_winner_present === 0 ||
    timestamp > state.estimated_path_winner_timestamp ||
    (timestamp === state.estimated_path_winner_timestamp &&
      site > state.estimated_path_winner_site_id);
}

function materialize(db, state, estimated) {
  const points = JSON.parse(Buffer.from(state.base_path).toString());
  const appends = db.prepare(`SELECT path FROM actual_append WHERE note_id='n'
    AND ink_timestamp=20 AND ink_site_id=2 ORDER BY timestamp,site_id`).all();
  for (const row of appends) points.push(...JSON.parse(row.path));
  if (estimated.length > 0) points.push(...JSON.parse(Buffer.from(estimated).toString()));
  return points;
}

function apply(db, { timestamp, site, actual = null, estimated = null, inject = false }) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare(`SELECT * FROM ink_state WHERE note_id='n'
      AND ink_timestamp=20 AND ink_site_id=2`).get();
    const snapshot = db.prepare('SELECT * FROM snapshot WHERE ink_timestamp=20 AND ink_site_id=2').get();
    const current = materialize(db, state, state.estimated_center_path);
    if (snapshot.path !== JSON.stringify(current)) { db.exec('ROLLBACK'); return 'DIVERGED'; }
    const replaceEstimated = newer(timestamp, site, state);
    if (actual === null && !replaceEstimated) { db.exec('COMMIT'); return 'STALE'; }
    if (actual !== null) db.prepare(`INSERT INTO actual_append VALUES('n',20,2,?,?,?)`)
      .run(timestamp, site, JSON.stringify(actual));
    const nextEstimated = replaceEstimated ? (estimated === null ? Buffer.alloc(0) :
      Buffer.from(JSON.stringify(estimated))) :
      state.estimated_center_path;
    const next = materialize(db, state, nextEstimated);
    if (replaceEstimated) db.prepare(`UPDATE ink_state SET estimated_center_path=?,
      estimated_path_winner_timestamp=?,estimated_path_winner_site_id=?,
      estimated_path_winner_present=1 WHERE note_id='n' AND ink_timestamp=20 AND ink_site_id=2`)
      .run(nextEstimated, timestamp, site);
    db.prepare('UPDATE snapshot SET path=?,revision=revision+1 WHERE ink_timestamp=20 AND ink_site_id=2')
      .run(JSON.stringify(next));
    db.exec('UPDATE page SET revision=revision+1');
    if (inject) throw new Error('injected apply');
    db.exec('COMMIT'); return 'APPLIED';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 42);
assert.equal(apply(db, { timestamp: 40, site: 2, estimated: [15] }), 'APPLIED');
assert.equal(db.prepare('SELECT path FROM snapshot').get().path, '[0,10,15]');
assert.equal(db.prepare('SELECT count(*) count FROM actual_append').get().count, 0);

assert.equal(apply(db, { timestamp: 30, site: 3, actual: [20], estimated: [25] }), 'APPLIED');
assert.equal(db.prepare('SELECT path FROM snapshot').get().path, '[0,10,20,15]');
assert.equal(db.prepare('SELECT estimated_path_winner_timestamp timestamp FROM ink_state').get().timestamp, 40);

assert.equal(apply(db, { timestamp: 50, site: 1, actual: [30] }), 'APPLIED');
assert.equal(db.prepare('SELECT path FROM snapshot').get().path, '[0,10,20,30]');
assert.equal(db.prepare('SELECT length(estimated_center_path) value FROM ink_state').get().value, 0);
const revision = db.prepare('SELECT revision FROM page').get().revision;
assert.equal(apply(db, { timestamp: 45, site: 9, estimated: [99] }), 'STALE');
assert.equal(db.prepare('SELECT revision FROM page').get().revision, revision);

const before = db.prepare('SELECT path FROM snapshot').get().path;
assert.throws(() => apply(db, { timestamp: 60, site: 1, estimated: [40], inject: true }),
  /injected apply/);
assert.equal(db.prepare('SELECT path FROM snapshot').get().path, before);
assert.equal(db.prepare('SELECT estimated_path_winner_timestamp timestamp FROM ink_state').get().timestamp, 50);

db.exec("UPDATE snapshot SET path='[999]'");
assert.equal(apply(db, { timestamp: 61, site: 1, estimated: [40] }), 'DIVERGED');
assert.equal(db.prepare('SELECT estimated_path_winner_timestamp timestamp FROM ink_state').get().timestamp, 50);

const failed = database();
assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 41);
assert.equal(failed.prepare(`SELECT count(*) count FROM pragma_table_info('ink_state')
  WHERE name='estimated_center_path'`).get().count, 0);

const addSource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalAddPathElementsOperation.ets', import.meta.url), 'utf8');
const modifySource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalModifyInkOperation.ets', import.meta.url), 'utf8');
const schema = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/DatabaseHelper.ets', import.meta.url), 'utf8');
assert.doesNotMatch(addSource, /ADD_PATH_ELEMENTS_ESTIMATED_PATH_UNSUPPORTED/);
assert.match(addSource, /estimatedState\.winner === null/);
assert.match(addSource, /payload\.centerPathEstimatedElements === null \? new Uint8Array\(0\)/);
assert.match(addSource, /rebuildOriginalInkGeometry\(basePath, allAppends, stroke, estimatedBytes\)/);
assert.match(modifySource, /state\.estimatedPath\.value/);
assert.match(schema, /DB_VERSION: number = 50/);
assert.match(schema, /42: \[/);

console.log('success|v41-v42=1|estimated-only=1|actual-order=1|lww-stale=1|' +
  'actual-clears-estimated=1|divergence=1|rollback=2|modify-consumer=1');
