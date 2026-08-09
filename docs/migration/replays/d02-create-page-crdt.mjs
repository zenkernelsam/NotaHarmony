import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const db = new DatabaseSync(':memory:');
db.exec(`
  PRAGMA foreign_keys=ON;
  PRAGMA user_version=21;
  CREATE TABLE note_meta(
    id TEXT PRIMARY KEY, structure_revision INTEGER NOT NULL DEFAULT 0);
  CREATE TABLE page_info(
    page_id TEXT PRIMARY KEY, note_id TEXT NOT NULL, page_index INTEGER NOT NULL,
    size INTEGER NOT NULL DEFAULT 1, template INTEGER NOT NULL DEFAULT 0,
    orientation INTEGER NOT NULL DEFAULT 0, width_mm REAL NOT NULL DEFAULT 210,
    height_mm REAL NOT NULL DEFAULT 297, content_revision INTEGER NOT NULL DEFAULT 0,
    UNIQUE(note_id,page_index), UNIQUE(note_id,page_id),
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE original_page_insert_group(
    note_id TEXT NOT NULL,
    op_timestamp INTEGER NOT NULL CHECK(op_timestamp BETWEEN 0 AND 4294967295),
    op_site_id INTEGER NOT NULL CHECK(op_site_id BETWEEN 0 AND 65535),
    parent_timestamp INTEGER CHECK(parent_timestamp BETWEEN 0 AND 4294967295),
    parent_site_id INTEGER CHECK(parent_site_id BETWEEN 0 AND 65535),
    parent_index INTEGER CHECK(parent_index BETWEEN 0 AND 4294967295),
    page_count INTEGER NOT NULL CHECK(page_count BETWEEN 1 AND 10000),
    modified_time TEXT NOT NULL,
    CHECK((parent_timestamp IS NULL AND parent_site_id IS NULL AND parent_index IS NULL)
      OR (parent_timestamp IS NOT NULL AND parent_site_id IS NOT NULL AND parent_index IS NOT NULL)),
    PRIMARY KEY(note_id,op_timestamp,op_site_id),
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE original_page_identity(
    note_id TEXT NOT NULL, seq_timestamp INTEGER NOT NULL, seq_site_id INTEGER NOT NULL,
    seq_index INTEGER NOT NULL, page_id TEXT, visible INTEGER NOT NULL DEFAULT 1,
    CHECK((visible=1 AND page_id IS NOT NULL AND length(page_id)>0)
      OR (visible=0 AND page_id IS NULL)),
    PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index), UNIQUE(note_id,page_id),
    FOREIGN KEY(note_id,seq_timestamp,seq_site_id)
      REFERENCES original_page_insert_group(note_id,op_timestamp,op_site_id) ON DELETE CASCADE,
    FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  INSERT INTO note_meta VALUES('note',0);
  PRAGMA user_version=22;
`);

const seq = (timestamp, site, index) => ({ timestamp, site, index });
const seqKey = value => `${value.timestamp}:${value.site}:${value.index}`;
const opKey = value => `${value.timestamp}:${value.site}`;
const pageId = value => `page:${seqKey(value)}`;
const javaInt = value => value >= 0x80000000 ? value - 0x100000000 : value;

function compareSeq(left, right) {
  const timestamp = (javaInt(left.timestamp) - javaInt(right.timestamp)) | 0;
  if (timestamp !== 0) return Math.sign(timestamp);
  if (left.site !== right.site) return left.site < right.site ? -1 : 1;
  return Math.sign((javaInt(right.index) - javaInt(left.index)) | 0);
}

function readOrder() {
  const records = db.prepare(`SELECT g.*,p.seq_index,p.page_id,p.visible
    FROM original_page_insert_group g JOIN original_page_identity p
      ON p.note_id=g.note_id AND p.seq_timestamp=g.op_timestamp AND p.seq_site_id=g.op_site_id
    WHERE g.note_id='note' ORDER BY g.op_timestamp,g.op_site_id,p.seq_index`).all();
  const groups = new Map();
  for (const row of records) {
    const key = `${row.op_timestamp}:${row.op_site_id}`;
    if (!groups.has(key)) {
      groups.set(key, {
        op: seq(row.op_timestamp, row.op_site_id, 0),
        parent: row.parent_timestamp === null ? null :
          seq(row.parent_timestamp, row.parent_site_id, row.parent_index),
        count: row.page_count, pages: [],
      });
    }
    groups.get(key).pages.push({
      ...seq(row.op_timestamp, row.op_site_id, row.seq_index),
      pageId: row.page_id, visible: row.visible === 1,
    });
  }
  const children = new Map();
  for (const group of groups.values()) {
    assert.equal(group.pages.length, group.count);
    const key = group.parent === null ? 'ROOT' : seqKey(group.parent);
    const siblings = children.get(key) ?? [];
    siblings.push(group);
    children.set(key, siblings);
  }
  for (const siblings of children.values()) {
    siblings.sort((left, right) =>
      -compareSeq(left.pages.at(-1), right.pages.at(-1)));
  }
  const result = [];
  const visited = new Set();
  function append(parent) {
    for (const group of children.get(parent) ?? []) {
      assert(!visited.has(opKey(group.op)));
      visited.add(opKey(group.op));
      for (const page of group.pages) {
        if (page.visible) result.push(page.pageId);
        append(seqKey(page));
      }
    }
  }
  append('ROOT');
  assert.equal(visited.size, groups.size);
  return result;
}

function anchorExists(parent) {
  if (parent === null) return true;
  return db.prepare(`SELECT 1 FROM original_page_identity WHERE note_id='note'
    AND seq_timestamp=? AND seq_site_id=? AND seq_index=?`).get(
      parent.timestamp, parent.site, parent.index) !== undefined;
}

function applyCreate(op, parent, count, failAt = '') {
  if (!anchorExists(parent)) return false;
  const currentOrder = db.prepare(`SELECT page_id FROM page_info WHERE note_id='note'
    ORDER BY page_index`).all().map(row => row.page_id);
  if (JSON.stringify(currentOrder) !== JSON.stringify(readOrder())) return false;
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare(`INSERT INTO original_page_insert_group VALUES(?,?,?,?,?,?,?,?)`).run(
      'note', op.timestamp, op.site, parent?.timestamp ?? null, parent?.site ?? null,
      parent?.index ?? null, count, String(op.timestamp));
    if (failAt === 'after-group') throw new Error('injected');
    const insertIdentity = db.prepare(`INSERT INTO original_page_identity VALUES(?,?,?,?,?,1)`);
    const newPages = [];
    for (let index = 0; index < count; index++) {
      const identity = seq(op.timestamp, op.site, index);
      const id = pageId(identity);
      insertIdentity.run('note', identity.timestamp, identity.site, identity.index, id);
      newPages.push(id);
    }
    if (failAt === 'after-identities') throw new Error('injected');
    const existing = db.prepare(`SELECT page_id FROM page_info WHERE note_id='note'
      ORDER BY page_index`).all().map(row => row.page_id);
    const update = db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
    existing.forEach((id, index) => assert.equal(update.run(-(index + 1), id).changes, 1));
    const insertPage = db.prepare(`INSERT INTO page_info(page_id,note_id,page_index) VALUES(?,'note',?)`);
    newPages.forEach((id, index) => insertPage.run(id, -(existing.length + index + 1)));
    const order = readOrder();
    order.forEach((id, index) => assert.equal(update.run(index, id).changes, 1));
    db.prepare(`UPDATE note_meta SET structure_revision=structure_revision+1 WHERE id='note'`).run();
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
  return true;
}

assert.equal(applyCreate(seq(10, 2, 0), null, 2), true);
assert.deepEqual(readOrder(), ['page:10:2:0', 'page:10:2:1']);
assert.equal(applyCreate(seq(5, 9, 0), null, 1), true);
assert.equal(applyCreate(seq(20, 1, 0), null, 1), true);
assert.deepEqual(readOrder(),
  ['page:20:1:0', 'page:10:2:0', 'page:10:2:1', 'page:5:9:0']);
assert.equal(applyCreate(seq(30, 4, 0), seq(10, 2, 0), 1), true);
assert.deepEqual(readOrder(),
  ['page:20:1:0', 'page:10:2:0', 'page:30:4:0', 'page:10:2:1', 'page:5:9:0']);

const canonicalOrder = readOrder();
const changeIndex = db.prepare(`UPDATE page_info SET page_index=? WHERE note_id='note' AND page_id=?`);
canonicalOrder.forEach((id, index) => changeIndex.run(-(index + 1), id));
[...canonicalOrder].reverse().forEach((id, index) => changeIndex.run(index, id));
assert.equal(applyCreate(seq(35, 1, 0), null, 1), false);
canonicalOrder.forEach((id, index) => changeIndex.run(-(index + 1), id));
canonicalOrder.forEach((id, index) => changeIndex.run(index, id));

const beforeMissing = JSON.stringify({
  groups: db.prepare(`SELECT * FROM original_page_insert_group ORDER BY op_timestamp`).all(),
  pages: db.prepare(`SELECT * FROM page_info ORDER BY page_index`).all(),
});
assert.equal(applyCreate(seq(40, 1, 0), seq(999, 1, 0), 1), false);
assert.equal(JSON.stringify({
  groups: db.prepare(`SELECT * FROM original_page_insert_group ORDER BY op_timestamp`).all(),
  pages: db.prepare(`SELECT * FROM page_info ORDER BY page_index`).all(),
}), beforeMissing);
assert.throws(() => applyCreate(seq(50, 1, 0), null, 1, 'after-identities'), /injected/);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_page_insert_group
  WHERE op_timestamp=50`).get().count, 0);
assert.equal(db.prepare(`PRAGMA foreign_key_check`).all().length, 0);
assert.equal(db.prepare(`SELECT structure_revision FROM note_meta`).get().structure_revision, 4);

assert.equal(db.prepare(`PRAGMA user_version`).get().user_version, 22);
console.log('success|v21-v22=1|create-page=3|seqid=12-byte|root-order=1|child-anchor=1|missing-deferred=1|diverged-deferred=1|rollback=1');
