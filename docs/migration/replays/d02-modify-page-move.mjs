import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY,structure_revision INTEGER NOT NULL DEFAULT 0);
  CREATE TABLE page_info(page_id TEXT PRIMARY KEY,note_id TEXT NOT NULL,page_index INTEGER NOT NULL,
    UNIQUE(note_id,page_index));
  CREATE TABLE original_page_insert_group(note_id TEXT,op_timestamp INTEGER,op_site_id INTEGER,
    parent_timestamp INTEGER,parent_site_id INTEGER,parent_index INTEGER,page_count INTEGER,modified_time TEXT,
    PRIMARY KEY(note_id,op_timestamp,op_site_id));
  CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,seq_index INTEGER,
    page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index),UNIQUE(note_id,page_id));
  INSERT INTO note_meta VALUES('note',0);
  INSERT INTO original_page_insert_group VALUES('note',10,1,NULL,NULL,NULL,4,'10');
  INSERT INTO original_page_identity VALUES
    ('note',10,1,0,'A',1),('note',10,1,1,'B',1),
    ('note',10,1,2,'C',1),('note',10,1,3,'D',1);
  INSERT INTO page_info VALUES('A','note',0),('B','note',1),('C','note',2),('D','note',3);
  PRAGMA user_version=22;

  CREATE TABLE original_page_position_group(
    note_id TEXT NOT NULL,op_timestamp INTEGER NOT NULL,op_site_id INTEGER NOT NULL,
    parent_timestamp INTEGER,parent_site_id INTEGER,parent_index INTEGER,
    position_count INTEGER NOT NULL,modified_time TEXT NOT NULL,
    PRIMARY KEY(note_id,op_timestamp,op_site_id));
  CREATE TABLE original_page_position(
    note_id TEXT NOT NULL,pos_timestamp INTEGER NOT NULL,pos_site_id INTEGER NOT NULL,pos_index INTEGER NOT NULL,
    page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,page_index INTEGER NOT NULL,
    PRIMARY KEY(note_id,pos_timestamp,pos_site_id,pos_index));
  CREATE TABLE original_page_position_winner(
    note_id TEXT NOT NULL,page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,page_index INTEGER NOT NULL,
    winner_timestamp INTEGER NOT NULL,winner_site_id INTEGER NOT NULL,position_index INTEGER NOT NULL,
    PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index),
    UNIQUE(note_id,winner_timestamp,winner_site_id,position_index));
  INSERT INTO original_page_position_group
    SELECT note_id,op_timestamp,op_site_id,parent_timestamp,parent_site_id,parent_index,page_count,modified_time
      FROM original_page_insert_group;
  INSERT INTO original_page_position
    SELECT note_id,seq_timestamp,seq_site_id,seq_index,seq_timestamp,seq_site_id,seq_index
      FROM original_page_identity;
  INSERT INTO original_page_position_winner
    SELECT note_id,seq_timestamp,seq_site_id,seq_index,seq_timestamp,seq_site_id,seq_index
      FROM original_page_identity;
  PRAGMA user_version=23;`);

const seq = (timestamp, site, index) => ({ timestamp, site, index });
const key = value => `${value.timestamp}:${value.site}:${value.index}`;
const opKey = value => `${value.timestamp}:${value.site}`;
const javaInt = value => value >= 0x80000000 ? value - 0x100000000 : value;

function compareSeq(left, right) {
  const timestamp = (javaInt(left.timestamp) - javaInt(right.timestamp)) | 0;
  if (timestamp !== 0) return Math.sign(timestamp);
  if (left.site !== right.site) return left.site < right.site ? -1 : 1;
  return Math.sign((javaInt(right.index) - javaInt(left.index)) | 0);
}

function compareOp(left, right) {
  if (left.timestamp !== right.timestamp) return left.timestamp < right.timestamp ? -1 : 1;
  return left.site === right.site ? 0 : left.site < right.site ? -1 : 1;
}

function order() {
  const rows = db.prepare(`SELECT g.*,p.pos_index,i.page_id,i.visible,
      w.winner_timestamp,w.winner_site_id,w.position_index
    FROM original_page_position_group g
    JOIN original_page_position p ON p.note_id=g.note_id
      AND p.pos_timestamp=g.op_timestamp AND p.pos_site_id=g.op_site_id
    JOIN original_page_identity i ON i.note_id=p.note_id
      AND i.seq_timestamp=p.page_timestamp AND i.seq_site_id=p.page_site_id AND i.seq_index=p.page_index
    JOIN original_page_position_winner w ON w.note_id=p.note_id
      AND w.page_timestamp=p.page_timestamp AND w.page_site_id=p.page_site_id AND w.page_index=p.page_index
    WHERE g.note_id='note' ORDER BY g.op_timestamp,g.op_site_id,p.pos_index`).all();
  const groups = new Map();
  for (const row of rows) {
    const groupKey = `${row.op_timestamp}:${row.op_site_id}`;
    if (!groups.has(groupKey)) groups.set(groupKey, {
      op: seq(row.op_timestamp,row.op_site_id,0),
      parent: row.parent_timestamp === null ? null :
        seq(row.parent_timestamp,row.parent_site_id,row.parent_index),
      count: row.position_count, positions: [],
    });
    const position = seq(row.op_timestamp,row.op_site_id,row.pos_index);
    groups.get(groupKey).positions.push({ position, pageId: row.page_id, visible: row.visible === 1,
      active: row.winner_timestamp === position.timestamp && row.winner_site_id === position.site &&
        row.position_index === position.index });
  }
  const children = new Map();
  for (const group of groups.values()) {
    assert.equal(group.positions.length, group.count);
    const parent = group.parent === null ? 'ROOT' : key(group.parent);
    children.set(parent, [...(children.get(parent) ?? []), group]);
  }
  for (const siblings of children.values())
    siblings.sort((left,right) => -compareSeq(left.positions.at(-1).position,right.positions.at(-1).position));
  const result = [], visited = new Set();
  const append = parent => {
    for (const group of children.get(parent) ?? []) {
      assert(!visited.has(opKey(group.op)));
      visited.add(opKey(group.op));
      for (const position of group.positions) {
        if (position.active && position.visible) result.push(position.pageId);
        append(key(position.position));
      }
    }
  };
  append('ROOT');
  assert.equal(visited.size,groups.size);
  return result;
}

function storedOrder() {
  return db.prepare(`SELECT page_id FROM page_info WHERE note_id='note' ORDER BY page_index`)
    .all().map(row => row.page_id);
}

function snapshot() {
  return JSON.stringify({
    groups: db.prepare('SELECT * FROM original_page_position_group ORDER BY op_timestamp,op_site_id').all(),
    positions: db.prepare('SELECT * FROM original_page_position ORDER BY pos_timestamp,pos_site_id,pos_index').all(),
    winners: db.prepare('SELECT * FROM original_page_position_winner ORDER BY page_index').all(),
    pages: db.prepare('SELECT * FROM page_info ORDER BY page_index').all(),
  });
}

function exists(table, columns, value) {
  const where = columns.map(column => `${column}=?`).join(' AND ');
  return db.prepare(`SELECT 1 FROM ${table} WHERE note_id='note' AND ${where}`).get(
    value.timestamp,value.site,value.index) !== undefined;
}

function applyMove(op, pages, target, failAt = '') {
  if (new Set(pages.map(key)).size !== pages.length) return false;
  if (pages.some(page => !exists('original_page_identity',
    ['seq_timestamp','seq_site_id','seq_index'],page))) return false;
  if (target !== null && !exists('original_page_position',
    ['pos_timestamp','pos_site_id','pos_index'],target)) return false;
  if (JSON.stringify(order()) !== JSON.stringify(storedOrder())) return false;
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare(`INSERT INTO original_page_position_group VALUES(?,?,?,?,?,?,?,?)`).run(
      'note',op.timestamp,op.site,target?.timestamp ?? null,target?.site ?? null,target?.index ?? null,
      pages.length,String(op.timestamp));
    if (failAt === 'group') throw new Error('injected');
    const insertPosition = db.prepare(`INSERT INTO original_page_position VALUES('note',?,?,?,?,?,?)`);
    const readWinner = db.prepare(`SELECT * FROM original_page_position_winner WHERE note_id='note'
      AND page_timestamp=? AND page_site_id=? AND page_index=?`);
    const updateWinner = db.prepare(`UPDATE original_page_position_winner SET
      winner_timestamp=?,winner_site_id=?,position_index=? WHERE note_id='note'
      AND page_timestamp=? AND page_site_id=? AND page_index=?
      AND winner_timestamp=? AND winner_site_id=? AND position_index=?`);
    pages.forEach((page,index) => {
      insertPosition.run(op.timestamp,op.site,index,page.timestamp,page.site,page.index);
      const winner = readWinner.get(page.timestamp,page.site,page.index);
      if (compareOp(op,{ timestamp:winner.winner_timestamp,site:winner.winner_site_id }) >= 0)
        assert.equal(updateWinner.run(op.timestamp,op.site,index,page.timestamp,page.site,page.index,
          winner.winner_timestamp,winner.winner_site_id,winner.position_index).changes,1);
    });
    if (failAt === 'winner') throw new Error('injected');
    const before = storedOrder();
    const updateIndex = db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
    before.forEach((pageId,index) => assert.equal(updateIndex.run(-(index+1),pageId).changes,1));
    order().forEach((pageId,index) => assert.equal(updateIndex.run(index,pageId).changes,1));
    db.prepare(`UPDATE note_meta SET structure_revision=structure_revision+1 WHERE id='note'`).run();
    db.exec('COMMIT');
    return true;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

assert.equal(db.prepare('PRAGMA user_version').get().user_version,23);
assert.deepEqual(order(),['A','B','C','D']);

assert.equal(applyMove(seq(20,2,0),[seq(10,1,2)],null),true);
assert.deepEqual(order(),['C','A','B','D']);
assert.equal(applyMove(seq(30,2,0),[seq(10,1,2)],seq(10,1,1)),true);
assert.deepEqual(order(),['A','B','C','D']);
assert.equal(applyMove(seq(40,2,0),[seq(10,1,1),seq(10,1,2)],seq(10,1,3)),true);
assert.deepEqual(order(),['A','D','B','C']);

// The target is B's current position in the moved set. Its old position remains as a hidden anchor.
assert.equal(applyMove(seq(50,2,0),[seq(10,1,1),seq(10,1,2)],seq(40,2,0)),true);
assert.deepEqual(order(),['A','D','B','C']);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_page_position WHERE note_id='note'`)
  .get().count,10);

// A later-delivered operation with a smaller op ID creates anchors but cannot replace either winner.
assert.equal(applyMove(seq(25,9,0),[seq(10,1,1),seq(10,1,2)],null),true);
assert.deepEqual(order(),['A','D','B','C']);
assert.deepEqual(db.prepare(`SELECT winner_timestamp,winner_site_id FROM original_page_position_winner
  WHERE page_index IN (1,2) ORDER BY page_index`).all()
  .map(row => [row.winner_timestamp,row.winner_site_id]),[[50,2],[50,2]]);

const beforeRejected = snapshot();
assert.equal(applyMove(seq(60,1,0),[seq(999,1,0)],null),false);
assert.equal(applyMove(seq(61,1,0),[seq(10,1,0)],seq(999,1,0)),false);
assert.equal(applyMove(seq(62,1,0),[seq(10,1,0),seq(10,1,0)],null),false);
assert.equal(snapshot(),beforeRejected);

const current = storedOrder();
const updateIndex = db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
current.forEach((pageId,index) => updateIndex.run(-(index+1),pageId));
[...current].reverse().forEach((pageId,index) => updateIndex.run(index,pageId));
assert.equal(applyMove(seq(63,1,0),[seq(10,1,0)],null),false);
current.forEach((pageId,index) => updateIndex.run(-(index+1),pageId));
current.forEach((pageId,index) => updateIndex.run(index,pageId));

const beforeFailure = snapshot();
assert.throws(() => applyMove(seq(70,1,0),[seq(10,1,0)],null,'winner'),/injected/);
assert.equal(snapshot(),beforeFailure);
assert.equal(db.prepare('PRAGMA foreign_key_check').all().length,0);
assert.equal(db.prepare(`SELECT structure_revision FROM note_meta WHERE id='note'`).get()
  .structure_revision,5);

console.log('success|v22-v23=1|modify-page=4|seqmove=1|batch-order=1|root=1|inside-anchor=1|lww-opid=1|missing-deferred=1|diverged-deferred=1|rollback=1');
