import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

function createDatabase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    PRAGMA foreign_keys = ON;
    CREATE TABLE note_meta (id TEXT PRIMARY KEY, structure_revision INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE page_info (
      page_id TEXT PRIMARY KEY, note_id TEXT NOT NULL, page_index INTEGER NOT NULL,
      size INTEGER NOT NULL, template INTEGER NOT NULL, orientation INTEGER NOT NULL,
      width_mm REAL NOT NULL, height_mm REAL NOT NULL, content_revision INTEGER NOT NULL,
      UNIQUE(note_id, page_index), UNIQUE(note_id, page_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE page_element_snapshot (
      note_id TEXT NOT NULL, page_id TEXT NOT NULL, element_id TEXT NOT NULL, kind INTEGER NOT NULL,
      payload BLOB NOT NULL, revision INTEGER NOT NULL, element_order INTEGER NOT NULL,
      PRIMARY KEY(note_id, page_id, element_id, kind),
      FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE);
    CREATE TABLE search_item (
      id INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL, type INTEGER NOT NULL,
      sub_id TEXT NOT NULL, page_id TEXT NOT NULL, folded_text TEXT NOT NULL, rects BLOB,
      UNIQUE(note_id, type, sub_id),
      FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE);
    CREATE TABLE search_page_state (
      note_id TEXT NOT NULL, page_id TEXT NOT NULL, indexed_revision INTEGER NOT NULL,
      PRIMARY KEY(note_id, page_id),
      FOREIGN KEY(note_id, page_id) REFERENCES page_info(note_id, page_id) ON DELETE CASCADE);
    CREATE TABLE operation_log (
      sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL, op_id TEXT NOT NULL,
      op_type INTEGER NOT NULL, payload BLOB NOT NULL, client_time INTEGER NOT NULL,
      action_id TEXT, history_effect INTEGER, coalesce_track INTEGER, action_time INTEGER,
      UNIQUE(note_id, op_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE page_delete_checkpoint (
      note_id TEXT NOT NULL, action_id TEXT NOT NULL, page_id TEXT NOT NULL, page_index INTEGER NOT NULL,
      size INTEGER NOT NULL, template INTEGER NOT NULL, orientation INTEGER NOT NULL,
      width_mm REAL NOT NULL, height_mm REAL NOT NULL, content_revision INTEGER NOT NULL,
      indexed_revision INTEGER, created_time INTEGER NOT NULL, PRIMARY KEY(note_id, action_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE page_delete_checkpoint_element (
      note_id TEXT NOT NULL, action_id TEXT NOT NULL, element_id TEXT NOT NULL, kind INTEGER NOT NULL,
      payload BLOB NOT NULL, revision INTEGER NOT NULL, element_order INTEGER NOT NULL,
      PRIMARY KEY(note_id, action_id, element_id, kind),
      FOREIGN KEY(note_id, action_id) REFERENCES page_delete_checkpoint(note_id, action_id) ON DELETE CASCADE);
    CREATE TABLE page_delete_checkpoint_search (
      note_id TEXT NOT NULL, action_id TEXT NOT NULL, type INTEGER NOT NULL, sub_id TEXT NOT NULL,
      folded_text TEXT NOT NULL, rects BLOB, PRIMARY KEY(note_id, action_id, type, sub_id),
      FOREIGN KEY(note_id, action_id) REFERENCES page_delete_checkpoint(note_id, action_id) ON DELETE CASCADE);
    INSERT INTO note_meta(id) VALUES ('note');
  `);
  return db;
}

function tx(db, body) {
  db.exec('BEGIN IMMEDIATE');
  try {
    body();
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function seed(db, count = 4) {
  const page = db.prepare(`INSERT INTO page_info VALUES (?, 'note', ?, 1, ?, 0, 210, 297, ?)`);
  for (let index = 0; index < count; index++) {
    page.run(`p${index}`, index, index, index + 7);
  }
  db.prepare(`INSERT INTO page_element_snapshot VALUES ('note', ?, ?, 0, ?, ?, 0)`)
    .run('p1', 'stroke-1', Buffer.from('stroke-payload'), 8);
  db.prepare(`INSERT INTO search_item(note_id,type,sub_id,page_id,folded_text,rects)
    VALUES ('note',2,'text-1','p1','hello',?)`).run(Buffer.from([1, 2, 3]));
  db.exec(`INSERT INTO search_page_state VALUES ('note','p1',8)`);
}

function rows(db, sql, ...params) {
  return db.prepare(sql).all(...params);
}

function state(db) {
  return JSON.stringify({
    pages: rows(db, 'SELECT page_id,page_index,content_revision FROM page_info ORDER BY page_index'),
    elements: rows(db, 'SELECT page_id,element_id,hex(payload) payload,revision,element_order FROM page_element_snapshot'),
    search: rows(db, 'SELECT page_id,type,sub_id,folded_text,hex(rects) rects FROM search_item'),
    searchState: rows(db, 'SELECT * FROM search_page_state'),
    checkpoints: rows(db, 'SELECT note_id,action_id,page_id,page_index FROM page_delete_checkpoint'),
    checkpointElements: rows(db, 'SELECT action_id,element_id,hex(payload) payload FROM page_delete_checkpoint_element'),
    checkpointSearch: rows(db, 'SELECT action_id,type,sub_id,hex(rects) rects FROM page_delete_checkpoint_search'),
    ops: rows(db, 'SELECT op_id,op_type,action_id,history_effect FROM operation_log ORDER BY sequence'),
  });
}

function deleteWithCheckpoint(db, pageId, actionId = 'delete-action', effect = 0) {
  tx(db, () => {
    if (effect === 0) {
      db.prepare(`INSERT INTO page_delete_checkpoint
        SELECT note_id,?,page_id,page_index,size,template,orientation,width_mm,height_mm,content_revision,
          (SELECT indexed_revision FROM search_page_state s WHERE s.note_id=p.note_id AND s.page_id=p.page_id),100
        FROM page_info p WHERE note_id='note' AND page_id=?`).run(actionId, pageId);
      db.prepare(`INSERT INTO page_delete_checkpoint_element
        SELECT note_id,?,element_id,kind,payload,revision,element_order FROM page_element_snapshot
        WHERE note_id='note' AND page_id=?`).run(actionId, pageId);
      db.prepare(`INSERT INTO page_delete_checkpoint_search
        SELECT note_id,?,type,sub_id,folded_text,rects FROM search_item
        WHERE note_id='note' AND page_id=?`).run(actionId, pageId);
    } else {
      verifyRedoSource(db, pageId, actionId);
    }
    const ordered = rows(db, `SELECT page_id FROM page_info WHERE note_id='note' ORDER BY page_index`);
    assert.equal(db.prepare(`DELETE FROM page_info WHERE note_id='note' AND page_id=?`).run(pageId).changes, 1);
    let target = 0;
    for (const page of ordered) {
      if (page.page_id !== pageId) {
        db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`).run(target++, page.page_id);
      }
    }
    db.prepare(`UPDATE note_meta SET structure_revision=structure_revision+1 WHERE id='note'`).run();
    db.prepare(`INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time,action_id,history_effect,
      coalesce_track,action_time) VALUES ('note',?,6,X'01',100,?,?,0,100)`)
      .run(`delete-${effect}-${actionId}`, actionId, effect);
  });
}

function restore(db, actionId = 'delete-action') {
  tx(db, () => {
    const checkpoint = db.prepare(`SELECT * FROM page_delete_checkpoint
      WHERE note_id='note' AND action_id=?`).get(actionId);
    assert.ok(checkpoint);
    const pages = rows(db, `SELECT page_id FROM page_info WHERE note_id='note' ORDER BY page_index`);
    for (let index = 0; index < pages.length; index++) {
      db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`)
        .run(-(index + 1), pages[index].page_id);
    }
    db.prepare(`INSERT INTO page_info VALUES (?, 'note', ?, ?, ?, ?, ?, ?, ?)`)
      .run(checkpoint.page_id, checkpoint.page_index, checkpoint.size, checkpoint.template,
        checkpoint.orientation, checkpoint.width_mm, checkpoint.height_mm, checkpoint.content_revision);
    let source = 0;
    for (let target = 0; target <= pages.length; target++) {
      if (target !== checkpoint.page_index) {
        db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`)
          .run(target, pages[source++].page_id);
      }
    }
    db.prepare(`INSERT INTO page_element_snapshot
      SELECT note_id,page_id,element_id,kind,payload,revision,element_order
      FROM page_delete_checkpoint_element JOIN page_delete_checkpoint USING(note_id,action_id)
      WHERE note_id='note' AND action_id=?`).run(actionId);
    db.prepare(`INSERT INTO search_item(note_id,type,sub_id,page_id,folded_text,rects)
      SELECT s.note_id,s.type,s.sub_id,c.page_id,s.folded_text,s.rects
      FROM page_delete_checkpoint_search s JOIN page_delete_checkpoint c USING(note_id,action_id)
      WHERE s.note_id='note' AND s.action_id=?`).run(actionId);
    if (checkpoint.indexed_revision !== null) {
      db.prepare(`INSERT INTO search_page_state VALUES ('note',?,?)`)
        .run(checkpoint.page_id, checkpoint.indexed_revision);
    }
    db.exec(`UPDATE note_meta SET structure_revision=structure_revision+1 WHERE id='note'`);
    db.prepare(`INSERT INTO operation_log(note_id,op_id,op_type,payload,client_time,action_id,history_effect,
      coalesce_track,action_time) VALUES ('note',?,5,X'01',101,?,1,0,100)`)
      .run(`restore-${actionId}`, actionId);
  });
}

function verifyRedoSource(db, pageId, actionId) {
  const live = db.prepare(`SELECT p.*,s.indexed_revision FROM page_info p LEFT JOIN search_page_state s
    USING(note_id,page_id) WHERE p.note_id='note' AND p.page_id=?`).get(pageId);
  const saved = db.prepare(`SELECT * FROM page_delete_checkpoint WHERE note_id='note' AND action_id=?`).get(actionId);
  assert.ok(live && saved);
  for (const key of ['page_id', 'page_index', 'size', 'template', 'orientation', 'width_mm', 'height_mm',
    'content_revision', 'indexed_revision']) assert.equal(live[key], saved[key]);
  assert.deepEqual(
    rows(db, `SELECT element_id,kind,hex(payload) payload,revision,element_order FROM page_element_snapshot
      WHERE note_id='note' AND page_id=? ORDER BY element_order`, pageId),
    rows(db, `SELECT element_id,kind,hex(payload) payload,revision,element_order FROM page_delete_checkpoint_element
      WHERE note_id='note' AND action_id=? ORDER BY element_order`, actionId));
  assert.deepEqual(
    rows(db, `SELECT type,sub_id,folded_text,hex(rects) rects FROM search_item
      WHERE note_id='note' AND page_id=? ORDER BY type,sub_id`, pageId),
    rows(db, `SELECT type,sub_id,folded_text,hex(rects) rects FROM page_delete_checkpoint_search
      WHERE note_id='note' AND action_id=? ORDER BY type,sub_id`, actionId));
}

function expectRollback(phase, prepare, operation) {
  const db = createDatabase();
  seed(db);
  prepare(db);
  const before = state(db);
  const event = phase === 'delete_page' ? 'DELETE' : 'INSERT';
  const table = phase === 'header' ? 'page_delete_checkpoint' :
    phase === 'checkpoint_element' ? 'page_delete_checkpoint_element' :
      phase === 'checkpoint_search' ? 'page_delete_checkpoint_search' :
      phase === 'delete_page' || phase === 'restore_page' ? 'page_info' :
        phase === 'restore_element' ? 'page_element_snapshot' : 'operation_log';
  const targetTable = phase === 'restore_search' ? 'search_item' :
    phase === 'restore_state' ? 'search_page_state' : table;
  db.exec(`CREATE TRIGGER fail_${phase} BEFORE ${event} ON ${targetTable}
    BEGIN SELECT RAISE(ABORT, 'injected'); END;`);
  assert.throws(() => operation(db), /injected/);
  assert.equal(state(db), before, phase);
  db.close();
}

for (const pageId of ['p0', 'p1', 'p3']) {
  const db = createDatabase();
  seed(db);
  deleteWithCheckpoint(db, pageId, `delete-${pageId}`);
  assert.deepEqual(rows(db, `SELECT page_index FROM page_info ORDER BY page_index`).map(row => row.page_index), [0, 1, 2]);
  db.close();
}

const happy = createDatabase();
seed(happy);
deleteWithCheckpoint(happy, 'p1');
assert.equal(rows(happy, `SELECT * FROM page_delete_checkpoint_element`).length, 1);
assert.equal(rows(happy, `SELECT * FROM page_delete_checkpoint_search`).length, 1);
restore(happy);
assert.deepEqual(rows(happy, `SELECT page_id FROM page_info ORDER BY page_index`).map(row => row.page_id),
  ['p0', 'p1', 'p2', 'p3']);
assert.equal(dbValue(happy, `SELECT hex(payload) value FROM page_element_snapshot WHERE page_id='p1'`),
  Buffer.from('stroke-payload').toString('hex').toUpperCase());
assert.equal(dbValue(happy, `SELECT indexed_revision value FROM search_page_state WHERE page_id='p1'`), 8);
deleteWithCheckpoint(happy, 'p1', 'delete-action', 2);
assert.deepEqual(rows(happy, `SELECT page_id FROM page_info ORDER BY page_index`).map(row => row.page_id),
  ['p0', 'p2', 'p3']);
happy.close();

function dbValue(db, sql) {
  return db.prepare(sql).get().value;
}

let rollbackCount = 0;
const cases = [
  ['header', () => {}, db => deleteWithCheckpoint(db, 'p1')],
  ['checkpoint_element', () => {}, db => deleteWithCheckpoint(db, 'p1')],
  ['checkpoint_search', () => {}, db => deleteWithCheckpoint(db, 'p1')],
  ['delete_page', () => {}, db => deleteWithCheckpoint(db, 'p1')],
  ['delete_log', () => {}, db => deleteWithCheckpoint(db, 'p1')],
  ['restore_page', db => deleteWithCheckpoint(db, 'p1'), db => restore(db)],
  ['restore_element', db => deleteWithCheckpoint(db, 'p1'), db => restore(db)],
  ['restore_search', db => deleteWithCheckpoint(db, 'p1'), db => restore(db)],
  ['restore_state', db => deleteWithCheckpoint(db, 'p1'), db => restore(db)],
  ['restore_log', db => deleteWithCheckpoint(db, 'p1'), db => restore(db)],
];
for (const [phase, prepare, operation] of cases) {
  expectRollback(phase, prepare, operation);
  rollbackCount++;
}

const mismatch = createDatabase();
seed(mismatch);
deleteWithCheckpoint(mismatch, 'p1');
restore(mismatch);
mismatch.exec(`UPDATE page_element_snapshot SET payload=X'FF' WHERE page_id='p1'`);
const mismatchState = state(mismatch);
assert.throws(() => deleteWithCheckpoint(mismatch, 'p1', 'delete-action', 2));
assert.equal(state(mismatch), mismatchState);
mismatch.close();

console.log(`success|delete-orders=first,middle,last|restore=content,search,index|rollback=${rollbackCount}|redo-mismatch=1`);
