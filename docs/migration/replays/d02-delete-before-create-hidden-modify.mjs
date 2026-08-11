import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const helper = read('note/src/main/ets/data/DatabaseHelper.ets');
const deletion = read('note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets');
const createInk = read('note/src/main/ets/data/OriginalCreateInkOperation.ets');
const createBlock = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const modifyInk = read('note/src/main/ets/data/OriginalModifyInkOperation.ets');
const modifyBlock = read('note/src/main/ets/data/OriginalModifyBlockOperation.ets');
const text = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');

function read(path) {
  return fs.readFileSync(new URL(path, root), 'utf8');
}

function ddl(name) {
  const match = helper.match(new RegExp(
    '(?:export )?const ' + name + ': string = `([\\s\\S]*?)`;'));
  assert.ok(match, `${name} DDL is missing`);
  return match[1];
}

function schema() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    INSERT INTO note_meta VALUES('note');
    CREATE TABLE original_page_identity(
      note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,page_id TEXT,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO original_page_identity VALUES('note',10,1,0,'p1');
    INSERT INTO original_page_identity VALUES('note',11,1,0,'p2');
    CREATE TABLE original_element_z_index(
      note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,page_timestamp INTEGER,
      page_site_id INTEGER,page_index INTEGER,kind INTEGER,visible INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE original_entity_visibility_winner(
      note_id TEXT,entity_timestamp INTEGER,entity_site_id INTEGER,winner_timestamp INTEGER,
      winner_site_id INTEGER,deleted INTEGER,
      PRIMARY KEY(note_id,entity_timestamp,entity_site_id),
      FOREIGN KEY(note_id,entity_timestamp,entity_site_id)
        REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id)
        ON DELETE CASCADE,
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO original_element_z_index VALUES('note',1,1,10,1,0,1,0,'5');
    INSERT INTO original_entity_visibility_winner VALUES('note',1,1,9,2,1);`);
  return db;
}

function migrateV47() {
  const db = schema();
  db.exec('PRAGMA foreign_keys=OFF');
  db.exec(ddl('DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER_V47'));
  db.exec(`INSERT INTO original_entity_visibility_winner_v47
    SELECT * FROM original_entity_visibility_winner`);
  db.exec('DROP TABLE original_entity_visibility_winner');
  db.exec(`ALTER TABLE original_entity_visibility_winner_v47
    RENAME TO original_entity_visibility_winner`);
  db.exec('PRAGMA foreign_keys=ON');
  assert.deepEqual(db.prepare('PRAGMA foreign_key_check').all(), []);
  const preserved = db.prepare(`SELECT winner_timestamp,deleted
    FROM original_entity_visibility_winner`).get();
  assert.equal(preserved.winner_timestamp, 9);
  assert.equal(preserved.deleted, 1);
  const parents = db.prepare(`SELECT "table" AS parent FROM pragma_foreign_key_list(
    'original_entity_visibility_winner') ORDER BY parent`).all().map(row => row.parent);
  assert.deepEqual(parents, ['note_meta']);
  db.prepare(`INSERT INTO original_entity_visibility_winner VALUES('note',99,7,10,3,1)`).run();
  db.prepare(`DELETE FROM note_meta WHERE id='note'`).run();
  assert.equal(db.prepare(`SELECT COUNT(*) AS count
    FROM original_entity_visibility_winner`).get().count, 0);
  db.close();
}

function stateDatabase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    INSERT INTO note_meta VALUES('note');
    CREATE TABLE original_page_identity(
      note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,seq_index INTEGER,page_id TEXT,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    INSERT INTO original_page_identity VALUES('note',10,1,0,'p1');
    INSERT INTO original_page_identity VALUES('note',11,1,0,'p2');
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    INSERT INTO page_info VALUES('note','p1',4),('note','p2',8);
    CREATE TABLE original_element_z_index(
      note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,page_timestamp INTEGER,
      page_site_id INTEGER,page_index INTEGER,kind INTEGER,visible INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE original_entity_visibility_winner(
      note_id TEXT,entity_timestamp INTEGER,entity_site_id INTEGER,winner_timestamp INTEGER,
      winner_site_id INTEGER,deleted INTEGER,
      PRIMARY KEY(note_id,entity_timestamp,entity_site_id));
    CREATE TABLE original_deleted_entity(
      note_id TEXT,entity_timestamp INTEGER,entity_site_id INTEGER,page_timestamp INTEGER,
      page_site_id INTEGER,page_index INTEGER,element_id TEXT,kind INTEGER,payload TEXT,
      revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,entity_timestamp,entity_site_id));
    CREATE TABLE page_element_snapshot(
      note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload TEXT,revision INTEGER,
      element_order INTEGER,PRIMARY KEY(note_id,page_id,element_id,kind));`);
  return db;
}

function compare(left, right) {
  return left.timestamp === right.timestamp ? Math.sign(left.site - right.site) :
    Math.sign(left.timestamp - right.timestamp);
}

function visibility(db, entity, operation, deleted) {
  const winner = db.prepare(`SELECT winner_timestamp AS timestamp,winner_site_id AS site,deleted
    FROM original_entity_visibility_winner WHERE note_id='note'
    AND entity_timestamp=? AND entity_site_id=?`).get(entity.timestamp, entity.site);
  if (winner && compare(operation, winner) === 0 && Boolean(winner.deleted) !== deleted) {
    throw new Error('visibility identity conflict');
  }
  if (winner && compare(operation, winner) <= 0) return;
  db.prepare(`INSERT INTO original_entity_visibility_winner VALUES('note',?,?,?,?,?)
    ON CONFLICT(note_id,entity_timestamp,entity_site_id) DO UPDATE SET
    winner_timestamp=excluded.winner_timestamp,winner_site_id=excluded.winner_site_id,
    deleted=excluded.deleted`).run(entity.timestamp, entity.site,
    operation.timestamp, operation.site, deleted ? 1 : 0);
  const tracked = db.prepare(`SELECT * FROM original_element_z_index WHERE note_id='note'
    AND element_timestamp=? AND element_site_id=?`).get(entity.timestamp, entity.site);
  if (!tracked || Boolean(tracked.visible) !== deleted) return;
  const id = `${entity.timestamp}:${entity.site}`;
  if (deleted) {
    const row = db.prepare(`SELECT * FROM page_element_snapshot WHERE note_id='note'
      AND element_id=? AND kind=?`).get(id, tracked.kind);
    assert.ok(row);
    db.prepare(`INSERT INTO original_deleted_entity VALUES('note',?,?,?,?,?,?,?,?,?,?)`).run(
      entity.timestamp, entity.site, tracked.page_timestamp, tracked.page_site_id,
      tracked.page_index, id, tracked.kind, row.payload, row.revision, row.element_order);
    db.prepare(`DELETE FROM page_element_snapshot WHERE note_id='note'
      AND element_id=? AND kind=?`).run(id, tracked.kind);
    db.prepare(`UPDATE original_element_z_index SET visible=0 WHERE note_id='note'
      AND element_timestamp=? AND element_site_id=?`).run(entity.timestamp, entity.site);
  } else {
    const row = db.prepare(`SELECT * FROM original_deleted_entity WHERE note_id='note'
      AND entity_timestamp=? AND entity_site_id=?`).get(entity.timestamp, entity.site);
    assert.ok(row);
    const pageId = db.prepare(`SELECT page_id FROM original_page_identity WHERE note_id='note'
      AND seq_timestamp=? AND seq_site_id=? AND seq_index=?`).get(
      row.page_timestamp, row.page_site_id, row.page_index).page_id;
    db.prepare(`INSERT INTO page_element_snapshot VALUES('note',?,?,?,?,?,?)`).run(
      pageId, id, row.kind, row.payload, row.revision, row.element_order);
    db.prepare(`DELETE FROM original_deleted_entity WHERE note_id='note'
      AND entity_timestamp=? AND entity_site_id=?`).run(entity.timestamp, entity.site);
    db.prepare(`UPDATE original_element_z_index SET visible=1 WHERE note_id='note'
      AND element_timestamp=? AND element_site_id=?`).run(entity.timestamp, entity.site);
  }
}

function create(db, entity, page, kind, zIndex, payload) {
  const winner = db.prepare(`SELECT deleted FROM original_entity_visibility_winner
    WHERE note_id='note' AND entity_timestamp=? AND entity_site_id=?`).get(
    entity.timestamp, entity.site);
  const hidden = winner && Boolean(winner.deleted);
  const existing = db.prepare(`SELECT * FROM original_element_z_index WHERE note_id='note'
    AND element_timestamp=? AND element_site_id=?`).get(entity.timestamp, entity.site);
  if (existing) {
    const active = db.prepare(`SELECT payload FROM page_element_snapshot WHERE note_id='note'
      AND element_id=? AND kind=?`).all(`${entity.timestamp}:${entity.site}`, kind);
    const archived = db.prepare(`SELECT payload FROM original_deleted_entity WHERE note_id='note'
      AND entity_timestamp=? AND entity_site_id=? AND kind=?`).all(
      entity.timestamp, entity.site, kind);
    const stored = hidden ? archived : active;
    if (existing.page_timestamp === page.timestamp && existing.page_site_id === page.site &&
      existing.page_index === page.index && existing.kind === kind &&
      existing.z_index === zIndex && Boolean(existing.visible) === !hidden &&
      stored.length === 1 && stored[0].payload === payload &&
      active.length + archived.length === 1) return;
    throw new Error('create identity conflict');
  }
  db.prepare(`INSERT INTO original_element_z_index VALUES('note',?,?,?,?,?,?,?,?)`).run(
    entity.timestamp, entity.site, page.timestamp, page.site, page.index,
    kind, hidden ? 0 : 1, zIndex);
  const pageId = page.timestamp === 10 ? 'p1' : 'p2';
  if (hidden) {
    const revision = db.prepare(`SELECT content_revision FROM page_info
      WHERE note_id='note' AND page_id=?`).get(pageId).content_revision;
    db.prepare(`INSERT INTO original_deleted_entity VALUES('note',?,?,?,?,?,?,?,?,?,?)`).run(
      entity.timestamp, entity.site, page.timestamp, page.site, page.index,
      `${entity.timestamp}:${entity.site}`, kind, payload, revision, 0);
  } else {
    db.prepare(`INSERT INTO page_element_snapshot VALUES('note',?,?,?,?,?,0)`).run(
      pageId, `${entity.timestamp}:${entity.site}`, kind, payload,
      db.prepare(`SELECT content_revision FROM page_info WHERE note_id='note'
        AND page_id=?`).get(pageId).content_revision + 1);
    db.prepare(`UPDATE page_info SET content_revision=content_revision+1
      WHERE note_id='note' AND page_id=?`).run(pageId);
  }
}

function hiddenModify(db, entity, destination, zIndex, payload) {
  const row = db.prepare(`SELECT * FROM original_deleted_entity WHERE note_id='note'
    AND entity_timestamp=? AND entity_site_id=?`).get(entity.timestamp, entity.site);
  assert.ok(row);
  db.prepare(`UPDATE original_deleted_entity SET page_timestamp=?,page_site_id=?,page_index=?,
    payload=? WHERE note_id='note' AND entity_timestamp=? AND entity_site_id=?`).run(
    destination.timestamp, destination.site, destination.index, payload,
    entity.timestamp, entity.site);
  db.prepare(`UPDATE original_element_z_index SET page_timestamp=?,page_site_id=?,page_index=?,
    z_index=? WHERE note_id='note' AND element_timestamp=? AND element_site_id=? AND visible=0`).run(
    destination.timestamp, destination.site, destination.index, zIndex,
    entity.timestamp, entity.site);
}

function stateReplay() {
  const db = stateDatabase();
  const p1 = { timestamp: 10, site: 1, index: 0 };
  const p2 = { timestamp: 11, site: 1, index: 0 };
  const ink = { timestamp: 20, site: 2 };
  const text = { timestamp: 21, site: 2 };
  visibility(db, ink, { timestamp: 30, site: 3 }, true);
  visibility(db, text, { timestamp: 31, site: 3 }, true);
  create(db, ink, p1, 1, '10', 'ink-v1');
  create(db, text, p1, 2, '20', 'text-v1');
  create(db, ink, p1, 1, '10', 'ink-v1');
  assert.throws(() => create(db, ink, p1, 1, '10', 'ink-conflict'),
    /create identity conflict/);
  assert.equal(db.prepare(`SELECT COUNT(*) AS count FROM page_element_snapshot`).get().count, 0);
  assert.deepEqual(db.prepare(`SELECT page_id,content_revision FROM page_info ORDER BY page_id`).all()
    .map(row => ({ ...row })),
    [{ page_id: 'p1', content_revision: 4 }, { page_id: 'p2', content_revision: 8 }]);
  const activeBeforeCreate = { timestamp: 22, site: 2 };
  visibility(db, activeBeforeCreate, { timestamp: 32, site: 3 }, false);
  create(db, activeBeforeCreate, p1, 2, '25', 'undelete-before-create');
  assert.equal(db.prepare(`SELECT payload FROM page_element_snapshot
    WHERE element_id='22:2'`).get().payload, 'undelete-before-create');
  assert.equal(db.prepare(`SELECT content_revision FROM page_info
    WHERE page_id='p1'`).get().content_revision, 5);
  hiddenModify(db, ink, p2, '40', 'ink-v2');
  hiddenModify(db, text, p2, '30', 'text-with-characters-and-style');
  visibility(db, ink, { timestamp: 40, site: 4 }, false);
  visibility(db, text, { timestamp: 41, site: 4 }, false);
  assert.deepEqual(db.prepare(`SELECT page_id,element_id,payload FROM page_element_snapshot
    WHERE element_id IN ('20:2','21:2') ORDER BY element_id`).all().map(row => ({ ...row })), [
    { page_id: 'p2', element_id: '20:2', payload: 'ink-v2' },
    { page_id: 'p2', element_id: '21:2', payload: 'text-with-characters-and-style' },
  ]);
  visibility(db, ink, { timestamp: 39, site: 9 }, true);
  assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
    WHERE element_timestamp=20`).get().visible, 1);
  assert.throws(() => visibility(db, ink, { timestamp: 40, site: 4 }, true),
    /identity conflict/);

  db.exec('BEGIN IMMEDIATE');
  try {
    visibility(db, ink, { timestamp: 50, site: 5 }, true);
    throw new Error('injected failure');
  } catch (_error) {
    db.exec('ROLLBACK');
  }
  assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
    WHERE element_timestamp=20`).get().visible, 1);
  assert.equal(db.prepare(`SELECT winner_timestamp FROM original_entity_visibility_winner
    WHERE entity_timestamp=20`).get().winner_timestamp, 40);
  db.close();
}

function staticGuards() {
  assert.match(helper, /export const DB_VERSION: number = 57/);
  assert.doesNotMatch(ddl('DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER'),
    /REFERENCES original_element_z_index/);
  assert.match(deletion, /target: null/);
  assert.match(deletion, /originalEntityExists/);
  assert.match(createInk, /'visible': hidden \? 0 : 1/);
  assert.match(createInk, /active_count/);
  assert.match(createBlock, /original_deleted_entity/);
  assert.match(createBlock, /hidden_count/);
  assert.match(modifyInk, /updateHiddenStroke/);
  assert.match(modifyBlock, /updateHiddenBlockElement/);
  assert.match(text, /writeTextPayload/);
  assert.match(text, /target\.hidden \?/);
}

migrateV47();
stateReplay();
staticGuards();
console.log('d02 delete-before-create/hidden-modify replay passed');
