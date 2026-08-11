import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const helperSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');
const deleteSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalDeleteEntitiesOperation.ets', rootPath), 'utf8');
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');

function ddl(name) {
  const match = helperSource.match(new RegExp(
    '(?:export )?const ' + name + ': string = `([\\s\\S]*?)`;'));
  assert.ok(match, `${name} DDL is missing`);
  return match[1];
}

function migrateV45() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    INSERT INTO note_meta VALUES('note');
    CREATE TABLE original_page_identity(
      note_id TEXT NOT NULL,seq_timestamp INTEGER NOT NULL,seq_site_id INTEGER NOT NULL,
      seq_index INTEGER NOT NULL,page_id TEXT,visible INTEGER NOT NULL,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO original_page_identity VALUES('note',10,1,0,'live',1);
    INSERT INTO original_page_identity VALUES('note',11,1,0,'archived',1);
    CREATE TABLE original_element_z_index(
      note_id TEXT NOT NULL,element_timestamp INTEGER NOT NULL,element_site_id INTEGER NOT NULL,
      page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,page_index INTEGER NOT NULL,
      kind INTEGER NOT NULL CHECK(kind BETWEEN 1 AND 3),z_index TEXT NOT NULL,
      PRIMARY KEY(note_id,element_timestamp,element_site_id),
      FOREIGN KEY(note_id,page_timestamp,page_site_id,page_index)
        REFERENCES original_page_identity(note_id,seq_timestamp,seq_site_id,seq_index)
        ON DELETE CASCADE,
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE original_ink_state(
      note_id TEXT NOT NULL,ink_timestamp INTEGER NOT NULL,ink_site_id INTEGER NOT NULL,
      value TEXT NOT NULL,PRIMARY KEY(note_id,ink_timestamp,ink_site_id),
      FOREIGN KEY(note_id,ink_timestamp,ink_site_id)
        REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id)
        ON DELETE CASCADE);
    CREATE TABLE original_block_state(
      note_id TEXT NOT NULL,block_timestamp INTEGER NOT NULL,block_site_id INTEGER NOT NULL,
      value TEXT NOT NULL,PRIMARY KEY(note_id,block_timestamp,block_site_id),
      FOREIGN KEY(note_id,block_timestamp,block_site_id)
        REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id)
        ON DELETE CASCADE);
    INSERT INTO original_element_z_index VALUES('note',20,2,10,1,0,1,'10');
    INSERT INTO original_ink_state VALUES('note',20,2,'ink-state');`);
  assert.throws(() => db.exec(
    `INSERT INTO original_element_z_index VALUES('note',21,2,10,1,0,4,'11')`),
  /CHECK constraint failed/);

  db.exec('PRAGMA foreign_keys=OFF');
  db.exec(ddl('DDL_ORIGINAL_ELEMENT_Z_INDEX_V46'));
  db.exec(`INSERT INTO original_element_z_index_v46
      (note_id,element_timestamp,element_site_id,page_timestamp,page_site_id,page_index,
       kind,visible,z_index)
    SELECT note_id,element_timestamp,element_site_id,page_timestamp,page_site_id,page_index,
      kind,1,z_index FROM original_element_z_index`);
  db.exec('DROP TABLE original_element_z_index');
  db.exec('ALTER TABLE original_element_z_index_v46 RENAME TO original_element_z_index');
  db.exec(ddl('DDL_ORIGINAL_ENTITY_VISIBILITY_WINNER'));
  db.exec(ddl('DDL_ORIGINAL_DELETED_ENTITY'));
  db.exec('PRAGMA foreign_keys=ON');

  assert.deepEqual(db.prepare('PRAGMA foreign_key_check').all(), []);
  assert.equal(db.prepare(`SELECT "table" AS parent FROM pragma_foreign_key_list(
    'original_ink_state') WHERE "from"='ink_timestamp'`).get().parent,
  'original_element_z_index');
  assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
    WHERE element_timestamp=20`).get().visible, 1);
  assert.equal(db.prepare('SELECT value FROM original_ink_state').get().value, 'ink-state');
  db.exec(`INSERT INTO original_element_z_index VALUES('note',21,2,10,1,0,4,1,'11');
    INSERT INTO original_element_z_index VALUES('note',22,2,10,1,0,5,1,'12')`);
  return db;
}

function database() {
  const db = migrateV45();
  db.exec(`CREATE TABLE page_info(
      note_id TEXT,page_id TEXT,content_revision INTEGER NOT NULL,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE original_deleted_page(
      note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      page_id TEXT,content_revision INTEGER NOT NULL,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE page_element_snapshot(
      note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload BLOB,
      revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE original_deleted_page_element(
      note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE search_page_state(
      note_id TEXT,page_id TEXT,indexed_revision INTEGER,PRIMARY KEY(note_id,page_id));
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,value TEXT);
    CREATE TABLE original_deleted_page_search(
      note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,value TEXT);
    INSERT INTO page_info VALUES('note','live',0);
    INSERT INTO original_deleted_page VALUES('note',11,1,0,'archived',5,5);
    INSERT INTO search_page_state VALUES('note','live',0);
    INSERT INTO search_item VALUES('note','live','live-search');
    INSERT INTO original_deleted_page_search VALUES('note',11,1,0,'archived-search');
    INSERT INTO original_element_z_index VALUES('note',30,3,10,1,0,1,1,'20');
    INSERT INTO original_element_z_index VALUES('note',31,3,11,1,0,2,1,'30');
    INSERT INTO original_ink_state VALUES('note',30,3,'second-ink');
    INSERT INTO original_block_state VALUES('note',31,3,'archived-block');
    INSERT INTO page_element_snapshot VALUES('note','live','20:2',1,X'01',0,0);
    INSERT INTO page_element_snapshot VALUES('note','live','21:2',4,X'02',0,1);
    INSERT INTO page_element_snapshot VALUES('note','live','22:2',5,X'03',0,2);
    INSERT INTO page_element_snapshot VALUES('note','live','30:3',1,X'04',0,3);
    INSERT INTO original_deleted_page_element VALUES('note',11,1,0,'31:3',2,X'05',5,0);`);
  return db;
}

function compare(left, right) {
  return left.timestamp === right.timestamp ? Math.sign(left.site - right.site) :
    Math.sign(left.timestamp - right.timestamp);
}

function applyVisibility(db, operation, deletes, undeletes, options = {}) {
  db.exec('BEGIN IMMEDIATE');
  try {
    if (options.pagePreflightFails) throw new Error('DELETE_ENTITIES_PAGE_MISSING');
    const desired = new Map();
    deletes.forEach(entity => desired.set(`${entity.timestamp}:${entity.site}`,
      { ...entity, deleted: true }));
    undeletes.forEach(entity => desired.set(`${entity.timestamp}:${entity.site}`,
      { ...entity, deleted: false }));
    const planned = [];
    for (const mutation of desired.values()) {
      const target = db.prepare(`SELECT z.*,
        CASE WHEN z.page_timestamp=11 THEN 1 ELSE 0 END AS archived
        FROM original_element_z_index z WHERE note_id='note'
        AND element_timestamp=? AND element_site_id=?`).get(mutation.timestamp, mutation.site);
      if (!target) throw new Error('DELETE_ENTITIES_ENTITY_MISSING_OR_UNBOUND');
      const winner = db.prepare(`SELECT winner_timestamp AS timestamp,winner_site_id AS site,deleted
        FROM original_entity_visibility_winner WHERE note_id='note'
        AND entity_timestamp=? AND entity_site_id=?`).get(mutation.timestamp, mutation.site);
      if (winner && compare(operation, winner) === 0 &&
        Boolean(winner.deleted) !== mutation.deleted) {
        throw new Error('identity conflicts with persisted value');
      }
      if (winner && compare(operation, winner) <= 0) continue;
      planned.push({ mutation, target, winner });
    }

    const affectedPages = new Map();
    let mutationCount = 0;
    for (const item of planned) {
      const { mutation, target, winner } = item;
      const changes = Boolean(target.visible) === mutation.deleted;
      const elementId = `${mutation.timestamp}:${mutation.site}`;
      if (changes && mutation.deleted) {
        const source = target.archived ? 'original_deleted_page_element' : 'page_element_snapshot';
        const row = target.archived ? db.prepare(`SELECT * FROM ${source} WHERE note_id='note'
          AND page_timestamp=? AND page_site_id=? AND page_index=? AND element_id=? AND kind=?`)
          .get(target.page_timestamp, target.page_site_id, target.page_index, elementId, target.kind) :
          db.prepare(`SELECT * FROM ${source} WHERE note_id='note' AND page_id='live'
            AND element_id=? AND kind=?`).get(elementId, target.kind);
        if (!row) throw new Error('entity snapshot missing');
        db.prepare(`INSERT INTO original_deleted_entity VALUES(
          'note',?,?,?,?,?,?,?,?,?,?)`).run(mutation.timestamp, mutation.site,
          target.page_timestamp, target.page_site_id, target.page_index, elementId,
          target.kind, row.payload, row.revision, row.element_order);
        if (target.archived) db.prepare(`DELETE FROM ${source} WHERE note_id='note'
          AND page_timestamp=? AND page_site_id=? AND page_index=? AND element_id=? AND kind=?`)
          .run(target.page_timestamp, target.page_site_id, target.page_index, elementId, target.kind);
        else db.prepare(`DELETE FROM ${source} WHERE note_id='note' AND page_id='live'
          AND element_id=? AND kind=?`).run(elementId, target.kind);
        db.prepare(`UPDATE original_element_z_index SET visible=0 WHERE note_id='note'
          AND element_timestamp=? AND element_site_id=?`).run(mutation.timestamp, mutation.site);
      } else if (changes) {
        const row = db.prepare(`SELECT * FROM original_deleted_entity WHERE note_id='note'
          AND entity_timestamp=? AND entity_site_id=?`).get(mutation.timestamp, mutation.site);
        if (!row) throw new Error('entity archive missing');
        if (target.archived) db.prepare(`INSERT INTO original_deleted_page_element VALUES(
          'note',?,?,?,?,?,?,?,?)`).run(target.page_timestamp, target.page_site_id,
          target.page_index, elementId, target.kind, row.payload, row.revision, row.element_order);
        else db.prepare(`INSERT INTO page_element_snapshot VALUES(
          'note','live',?,?,?,?,?)`).run(elementId, target.kind, row.payload,
          row.revision, row.element_order);
        db.prepare(`DELETE FROM original_deleted_entity WHERE note_id='note'
          AND entity_timestamp=? AND entity_site_id=?`).run(mutation.timestamp, mutation.site);
        db.prepare(`UPDATE original_element_z_index SET visible=1 WHERE note_id='note'
          AND element_timestamp=? AND element_site_id=?`).run(mutation.timestamp, mutation.site);
      }
      db.prepare(`INSERT INTO original_entity_visibility_winner VALUES('note',?,?,?,?,?)
        ON CONFLICT(note_id,entity_timestamp,entity_site_id) DO UPDATE SET
        winner_timestamp=excluded.winner_timestamp,winner_site_id=excluded.winner_site_id,
        deleted=excluded.deleted`).run(mutation.timestamp, mutation.site,
        operation.timestamp, operation.site, mutation.deleted ? 1 : 0);
      if (changes) affectedPages.set(`${target.page_timestamp}:${target.page_site_id}:${target.page_index}`,
        target);
      if (++mutationCount === options.failAfter) throw new Error('injected entity failure');
    }

    for (const target of affectedPages.values()) {
      const table = target.archived ? 'original_deleted_page_element' : 'page_element_snapshot';
      const rows = db.prepare(`SELECT z.element_timestamp,z.element_site_id,z.kind,z.z_index
        FROM original_element_z_index z WHERE z.note_id='note' AND z.page_timestamp=?
        AND z.page_site_id=? AND z.page_index=? AND z.visible=1
        ORDER BY length(z.z_index),z.z_index,z.element_timestamp,z.element_site_id,z.kind`)
        .all(target.page_timestamp, target.page_site_id, target.page_index);
      rows.forEach((row, index) => {
        const elementId = `${row.element_timestamp}:${row.element_site_id}`;
        const result = target.archived ? db.prepare(`UPDATE ${table} SET element_order=?
          WHERE note_id='note' AND page_timestamp=? AND page_site_id=? AND page_index=?
          AND element_id=? AND kind=?`).run(index, target.page_timestamp, target.page_site_id,
          target.page_index, elementId, row.kind) : db.prepare(`UPDATE ${table} SET element_order=?
          WHERE note_id='note' AND page_id='live' AND element_id=? AND kind=?`)
          .run(index, elementId, row.kind);
        if (result.changes !== 1) throw new Error('entity order diverged');
      });
      if (target.archived) {
        db.prepare(`UPDATE original_deleted_page SET content_revision=content_revision+1,
          indexed_revision=NULL WHERE note_id='note' AND page_timestamp=? AND page_site_id=?
          AND page_index=?`).run(target.page_timestamp, target.page_site_id, target.page_index);
        db.prepare(`DELETE FROM original_deleted_page_search WHERE note_id='note'
          AND page_timestamp=? AND page_site_id=? AND page_index=?`)
          .run(target.page_timestamp, target.page_site_id, target.page_index);
      } else {
        db.exec(`UPDATE page_info SET content_revision=content_revision+1
          WHERE note_id='note' AND page_id='live';
          DELETE FROM search_page_state WHERE note_id='note' AND page_id='live';
          DELETE FROM search_item WHERE note_id='note' AND page_id='live';`);
      }
    }
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const migrated = migrateV45();
assert.equal(migrated.prepare('SELECT count(*) AS count FROM original_element_z_index').get().count, 3);

const db = database();
applyVisibility(db, { timestamp: 40, site: 4 }, [{ timestamp: 20, site: 2 }], []);
assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=20`).get().visible, 0);
assert.equal(db.prepare(`SELECT count(*) AS count FROM original_deleted_entity
  WHERE entity_timestamp=20`).get().count, 1);
assert.equal(db.prepare('SELECT count(*) AS count FROM original_ink_state').get().count, 2);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 1);
assert.equal(db.prepare('SELECT count(*) AS count FROM search_item').get().count, 0);
applyVisibility(db, { timestamp: 41, site: 4 }, [], [{ timestamp: 20, site: 2 }]);
assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=20`).get().visible, 1);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);

applyVisibility(db, { timestamp: 42, site: 4 }, [{ timestamp: 31, site: 3 }], []);
assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=31`).get().visible, 0);
assert.equal(db.prepare(`SELECT content_revision,indexed_revision FROM original_deleted_page`).get()
  .content_revision, 6);
assert.equal(db.prepare('SELECT count(*) AS count FROM original_deleted_page_search').get().count, 0);
applyVisibility(db, { timestamp: 43, site: 4 }, [], [{ timestamp: 31, site: 3 }]);
assert.equal(db.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=31`).get().visible, 1);

const samePayload = database();
applyVisibility(samePayload, { timestamp: 50, site: 5 },
  [{ timestamp: 20, site: 2 }], [{ timestamp: 20, site: 2 }]);
assert.equal(samePayload.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=20`).get().visible, 1);
assert.equal(samePayload.prepare(`SELECT deleted FROM original_entity_visibility_winner
  WHERE entity_timestamp=20`).get().deleted, 0);
assert.equal(samePayload.prepare('SELECT content_revision FROM page_info').get().content_revision, 0);
assert.throws(() => applyVisibility(samePayload, { timestamp: 50, site: 5 },
  [{ timestamp: 20, site: 2 }], []), /identity conflicts/);
applyVisibility(samePayload, { timestamp: 49, site: 9 },
  [{ timestamp: 20, site: 2 }], []);
assert.equal(samePayload.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=20`).get().visible, 1);

const batched = database();
applyVisibility(batched, { timestamp: 60, site: 6 }, [
  { timestamp: 20, site: 2 }, { timestamp: 30, site: 3 },
], []);
assert.equal(batched.prepare('SELECT content_revision FROM page_info').get().content_revision, 1);
assert.equal(batched.prepare('SELECT count(*) AS count FROM original_ink_state').get().count, 2);

const failed = database();
const before = JSON.stringify(failed.prepare(`SELECT * FROM original_element_z_index
  ORDER BY element_timestamp`).all());
assert.throws(() => applyVisibility(failed, { timestamp: 70, site: 7 }, [
  { timestamp: 20, site: 2 }, { timestamp: 30, site: 3 },
], [], { failAfter: 2 }), /injected entity failure/);
assert.equal(JSON.stringify(failed.prepare(`SELECT * FROM original_element_z_index
  ORDER BY element_timestamp`).all()), before);
assert.equal(failed.prepare('SELECT count(*) AS count FROM original_deleted_entity').get().count, 0);
assert.throws(() => applyVisibility(failed, { timestamp: 71, site: 7 },
  [{ timestamp: 20, site: 2 }], [], { pagePreflightFails: true }), /PAGE_MISSING/);
assert.equal(failed.prepare(`SELECT visible FROM original_element_z_index
  WHERE element_timestamp=20`).get().visible, 1);

  assert.match(helperSource, /export const DB_VERSION: number = 58/);
assert.match(helperSource, /kind INTEGER NOT NULL CHECK \(kind BETWEEN 1 AND 5\)/);
assert.ok(deleteSource.indexOf('const appliesPageVisibility: boolean') <
  deleteSource.indexOf('const entityReason: string | null = await this.applyEntityVisibility'));
assert.match(deleteSource, /throw new Error\('original entity order diverged after visibility mutation'\)/);
assert.match(deleteSource, /for \(const entity of payload\.entityDeletes\)[\s\S]*for \(const entity of payload\.entityUndeletes\)/);
assert.match(bundleSource, /await deleteEntities\.applyEntityTable/);

console.log('success|v45-v46-fk=1|image-math-kind=1|live-delete-undelete=1|' +
  'archived-delete-undelete=1|same-payload-undelete-wins=1|stale-noop=1|' +
  'identity-conflict=1|one-page-one-revision=1|search-invalidated=1|' +
  'hidden-z-state-preserved=1|failure-rollback=1|deferred-zero-write=1');
