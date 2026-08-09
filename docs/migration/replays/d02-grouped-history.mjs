import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE page_info(page_id TEXT PRIMARY KEY, content_revision INTEGER NOT NULL);
    CREATE TABLE page_element_snapshot(page_id TEXT NOT NULL, element_id TEXT NOT NULL,
      revision INTEGER NOT NULL, element_order INTEGER NOT NULL, PRIMARY KEY(page_id,element_id));
    CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, op_id TEXT UNIQUE NOT NULL,
      action_id TEXT NOT NULL, effect INTEGER NOT NULL, from_revision INTEGER NOT NULL,
      to_revision INTEGER NOT NULL, before_ids TEXT NOT NULL, after_ids TEXT NOT NULL);
    INSERT INTO page_info VALUES ('page',3);
    INSERT INTO page_element_snapshot VALUES ('page','a',3,0),('page','b',3,1),('page','c',3,2);
    INSERT INTO operation_log(op_id,action_id,effect,from_revision,to_revision,before_ids,after_ids) VALUES
      ('push-a','a',0,0,1,'','a'),
      ('push-b','b',0,1,2,'a','a,b'),
      ('push-c','c',0,2,3,'a,b','a,b,c');
  `);
  return db;
}

function ids(db) {
  return db.prepare(`SELECT element_id FROM page_element_snapshot
    WHERE page_id='page' ORDER BY element_order`).all().map(row => row.element_id);
}

function groupedMove(db, expected, steps, effect) {
  db.exec('BEGIN IMMEDIATE');
  try {
    assert.deepEqual(ids(db), expected, 'database source must equal the editor snapshot');
    let revision = db.prepare(`SELECT content_revision value FROM page_info WHERE page_id='page'`).get().value;
    let before = expected;
    for (const step of steps) {
      const next = revision + 1;
      db.prepare(`INSERT INTO operation_log(op_id,action_id,effect,from_revision,to_revision,before_ids,after_ids)
        VALUES (?,?,?,?,?,?,?)`).run(`${effect}-${step.action}-${next}`, step.action, effect,
        revision, next, before.join(','), step.ids.join(','));
      revision = next;
      before = step.ids;
    }
    db.prepare(`UPDATE page_info SET content_revision=? WHERE page_id='page'`).run(revision);
    db.exec(`DELETE FROM page_element_snapshot WHERE page_id='page'`);
    const insert = db.prepare(`INSERT INTO page_element_snapshot VALUES ('page',?,?,?)`);
    for (let index = 0; index < before.length; index++) insert.run(before[index], revision, index);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function stacks(db) {
  const undo = [];
  const redo = [];
  for (const row of db.prepare(`SELECT action_id,effect FROM operation_log ORDER BY sequence`).all()) {
    if (row.effect === 0) {
      undo.push(row.action_id);
      redo.length = 0;
    } else if (row.effect === 1) {
      assert.equal(undo.at(-1), row.action_id);
      redo.push(undo.pop());
    } else {
      assert.equal(redo.at(-1), row.action_id);
      undo.push(redo.pop());
    }
  }
  return { undo, redo };
}

const happy = database();
groupedMove(happy, ['a', 'b', 'c'], [
  { action: 'c', ids: ['a', 'b'] },
  { action: 'b', ids: ['a'] },
  { action: 'a', ids: [] },
], 1);
assert.deepEqual(ids(happy), []);
assert.deepEqual(stacks(happy), { undo: [], redo: ['c', 'b', 'a'] });
groupedMove(happy, [], [
  { action: 'a', ids: ['a'] },
  { action: 'b', ids: ['a', 'b'] },
  { action: 'c', ids: ['a', 'b', 'c'] },
], 2);
assert.deepEqual(ids(happy), ['a', 'b', 'c']);
assert.deepEqual(stacks(happy), { undo: ['a', 'b', 'c'], redo: [] });
happy.close();

const failed = database();
const beforeFailure = JSON.stringify({
  revision: failed.prepare(`SELECT content_revision value FROM page_info`).get().value,
  ids: ids(failed),
  ops: failed.prepare(`SELECT action_id,effect FROM operation_log ORDER BY sequence`).all(),
});
failed.exec(`CREATE TRIGGER fail_second_group_op BEFORE INSERT ON operation_log
  WHEN NEW.action_id='b' AND NEW.effect=1 BEGIN SELECT RAISE(ABORT,'injected'); END;`);
assert.throws(() => groupedMove(failed, ['a', 'b', 'c'], [
  { action: 'c', ids: ['a', 'b'] }, { action: 'b', ids: ['a'] }, { action: 'a', ids: [] },
], 1), /injected/);
assert.equal(JSON.stringify({
  revision: failed.prepare(`SELECT content_revision value FROM page_info`).get().value,
  ids: ids(failed),
  ops: failed.prepare(`SELECT action_id,effect FROM operation_log ORDER BY sequence`).all(),
}), beforeFailure);
assert.throws(() => groupedMove(failed, ['wrong'], [], 1), /database source/);
failed.close();

console.log('success|undo-order=c,b,a|redo-order=a,b,c|rollback=second-op|source-mismatch=1');
