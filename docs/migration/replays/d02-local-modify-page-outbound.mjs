import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const q0 = fs.readFileSync(`${originalRoot}q0.java`, 'utf8');
const be2 = fs.readFileSync(`${originalRoot}be2.java`, 'utf8');
const u5j = fs.readFileSync(`${originalRoot}u5j.java`, 'utf8');
const r0j = fs.readFileSync(`${originalRoot}r0j.java`, 'utf8');
const egh = fs.readFileSync(`${originalRoot}egh.java`, 'utf8');
const encoder = read('note/src/main/ets/data/OriginalModifyPagePayloadEncoder.ets');
const planner = read('note/src/main/ets/data/OriginalPageReorderPlanner.ets');
const persistence = read('note/src/main/ets/data/OriginalPagePersistence.ets');
const repository = read('note/src/main/ets/data/PageRepositoryImpl.ets');
const editor = read('note/src/main/ets/ui/editor/NotePage.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const fixtures = read('note/src/test/OriginalModifyPagePayloadEncoder.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

assert.match(q0, /cxcVar2 = .*get\(i11\)[\s\S]*new be2\(de2Var, cxcVar2, i12/);
assert.match(be2, /u5j\.s\([^;]*m18\.l0\(new tz9\(\(cxc\) obj2\)\)[^;]*new Integer\(this\.K\)[^;]*12\)/);
assert.match(u5j, /bfj\.b\(f1aVar\.b, num\.intValue\(\), f1aVar\.h\)/);
assert.match(u5j, /lxcVarA = egh\.a\(cxcVarB != null \? cxcVarB : null\)/);
assert.match(r0j, /aVarA\.h\(0, numValueOf\.intValue\(\)\)/);
assert.match(r0j, /aVarA\.h\(1, numValueOf3\.intValue\(\)\)/);
assert.match(egh, /aVarA\.C\(1\)/);
assert.match(egh, /if \(cxcVar != null\)[\s\S]*aVarA\.j\(0, nti\.X\(cxcVar, aVarA\)\)/);

assert.match(encoder, /writeVtable\(bytes, rootVtable, 12, \[4, 8, 0, 0\]\)/);
assert.match(encoder, /moveTo === null \? 4 : 16/);
assert.match(encoder, /moveTo === null \? 0 : 4/);
assert.match(planner, /requestedWithoutMoved/);
assert.match(planner, /predecessorPageId: targetIndex === 0 \? null : requestedOrder\[targetIndex - 1\]/);
assert.match(persistence, /readWinningPosition/);
assert.match(persistence, /OriginalModifyPageOperationApplier\(\)\.apply/);
assert.match(persistence, /samePageIds\(materializedOrder, requestedOrder\)/);
assert.match(persistence, /opType: OpType\.ORIGINAL_MODIFY_PAGE/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(repository, /noteHasOriginalPages\(store, noteId\)/);
assert.match(repository, /persistOriginalPageReorder\(store, noteId, pageIds, movedPageId\)/);
assert.match(repository, /appendStructureHistoryMutation/);
assert.match(editor, /reorderPages\(this\.noteId, orderAfter, selectedPageId, history\)/);
assert.match(editor, /reorderPages\(this\.noteId, order, action\.pageId, history\)/);
assert.match(opTypes, /ORIGINAL_MODIFY_PAGE = 77/);
for (const companion of [
  'ORIGINAL_MODIFY_TEXT_STYLE', 'ORIGINAL_MODIFY_PARAGRAPH_STYLE', 'ORIGINAL_MODIFY_PAGE',
]) assert.match(history, new RegExp(`OpType\\.${companion}`));
assert.match(fixtures, /keeps SeqMove present while moving a page to the root/);
assert.match(fixtures, /plans relocation from the explicit dragged page identity/);
assert.match(fixtureList, /originalModifyPagePayloadEncoderTest\(\)/);

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

function u16(bytes, offset) {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function u32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}

function write16(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
}

function write32(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
  bytes[offset + 2] = value >>> 16 & 255;
  bytes[offset + 3] = value >>> 24 & 255;
}

function writeVtable(bytes, offset, objectSize, fields) {
  write16(bytes, offset, 4 + fields.length * 2);
  write16(bytes, offset + 2, objectSize);
  fields.forEach((field, index) => write16(bytes, offset + 4 + index * 2, field));
}

function writeSeq(bytes, offset, value) {
  write16(bytes, offset, value.site);
  write32(bytes, offset + 4, value.timestamp);
  write32(bytes, offset + 8, value.index);
}

function encodeMove(pages, target) {
  const rootTable = 16, vector = 28;
  const moveVtable = vector + 4 + pages.length * 12;
  const moveTable = (moveVtable + 9) & ~3;
  const objectSize = target === null ? 4 : 16;
  const bytes = new Uint8Array(moveTable + objectSize);
  write32(bytes, 0, rootTable);
  writeVtable(bytes, 4, 12, [4, 8, 0, 0]);
  write32(bytes, rootTable, 12);
  write32(bytes, rootTable + 4, vector - rootTable - 4);
  write32(bytes, rootTable + 8, moveTable - rootTable - 8);
  write32(bytes, vector, pages.length);
  pages.forEach((page, index) => writeSeq(bytes, vector + 4 + index * 12, page));
  writeVtable(bytes, moveVtable, objectSize, [target === null ? 0 : 4]);
  write32(bytes, moveTable, moveTable - moveVtable);
  if (target !== null) writeSeq(bytes, moveTable + 4, target);
  return bytes;
}

function field(bytes, table, index) {
  const vtable = table - u32(bytes, table);
  const size = u16(bytes, vtable);
  return 4 + index * 2 < size ? u16(bytes, vtable + 4 + index * 2) : 0;
}

function decodeMove(bytes) {
  const table = u32(bytes, 0);
  const pagesField = table + field(bytes, table, 0);
  const vector = pagesField + u32(bytes, pagesField);
  const pages = [];
  for (let index = 0; index < u32(bytes, vector); index++) {
    const offset = vector + 4 + index * 12;
    pages.push(seq(u32(bytes, offset + 4), u16(bytes, offset), u32(bytes, offset + 8)));
  }
  const moveFieldOffset = field(bytes, table, 1);
  const move = moveFieldOffset === 0 ? null : table + moveFieldOffset + u32(bytes, table + moveFieldOffset);
  const targetOffset = move === null ? 0 : field(bytes, move, 0);
  return {
    pages,
    hasMove: move !== null,
    target: targetOffset === 0 ? null : seq(
      u32(bytes, move + targetOffset + 4), u16(bytes, move + targetOffset),
      u32(bytes, move + targetOffset + 8)),
  };
}

assert.deepEqual(decodeMove(encodeMove([seq(17, 3, 2)], seq(41, 7, 5))), {
  pages: [seq(17, 3, 2)], hasMove: true, target: seq(41, 7, 5),
});
assert.deepEqual(decodeMove(encodeMove([seq(19, 4, 0)], null)), {
  pages: [seq(19, 4, 0)], hasMove: true, target: null,
});

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page_info(page_id TEXT PRIMARY KEY,page_index INTEGER UNIQUE);
  CREATE TABLE identity(page_id TEXT PRIMARY KEY,ts INTEGER,site INTEGER,idx INTEGER);
  CREATE TABLE position_group(op_ts INTEGER,op_site INTEGER,parent_ts INTEGER,parent_site INTEGER,
    parent_idx INTEGER,count INTEGER,PRIMARY KEY(op_ts,op_site));
  CREATE TABLE position(op_ts INTEGER,op_site INTEGER,pos_idx INTEGER,page_id TEXT,
    PRIMARY KEY(op_ts,op_site,pos_idx));
  CREATE TABLE winner(page_id TEXT PRIMARY KEY,op_ts INTEGER,op_site INTEGER,pos_idx INTEGER);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,target TEXT,history TEXT);
  CREATE TABLE note_meta(revision INTEGER);
  INSERT INTO note_meta VALUES(0);
  INSERT INTO page_info VALUES('A',0),('B',1),('C',2),('D',3);
  INSERT INTO identity VALUES('A',10,1,0),('B',10,1,1),('C',10,1,2),('D',10,1,3);
  INSERT INTO position_group VALUES(10,1,NULL,NULL,NULL,4);
  INSERT INTO position VALUES(10,1,0,'A'),(10,1,1,'B'),(10,1,2,'C'),(10,1,3,'D');
  INSERT INTO winner VALUES('A',10,1,0),('B',10,1,1),('C',10,1,2),('D',10,1,3);`);

function same(left, right) {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}

function without(order, pageId) {
  return order.filter(candidate => candidate !== pageId);
}

function plan(current, requested, movedPageId) {
  assert.equal(new Set(current).size, current.length);
  assert.equal(new Set(requested).size, requested.length);
  assert.equal(current.length, requested.length);
  assert(current.includes(movedPageId) && requested.includes(movedPageId));
  assert(same(without(current, movedPageId), without(requested, movedPageId)),
    'not one relocation of named page');
  assert(!same(current, requested), 'no-op move');
  const index = requested.indexOf(movedPageId);
  return { movedPageId, predecessorPageId: index === 0 ? null : requested[index - 1] };
}

function crdtOrder() {
  const groups = new Map();
  for (const row of db.prepare(`SELECT g.*,p.pos_idx,p.page_id,w.op_ts winner_ts,
      w.op_site winner_site,w.pos_idx winner_idx FROM position_group g
      JOIN position p ON p.op_ts=g.op_ts AND p.op_site=g.op_site
      JOIN winner w ON w.page_id=p.page_id ORDER BY g.op_ts,g.op_site,p.pos_idx`).all()) {
    const groupKey = `${row.op_ts}:${row.op_site}`;
    if (!groups.has(groupKey)) groups.set(groupKey, {
      op: seq(row.op_ts, row.op_site, 0),
      parent: row.parent_ts === null ? null : seq(row.parent_ts, row.parent_site, row.parent_idx),
      count: row.count, positions: [],
    });
    const positionId = seq(row.op_ts, row.op_site, row.pos_idx);
    groups.get(groupKey).positions.push({ id: positionId, pageId: row.page_id,
      active: row.winner_ts === positionId.timestamp && row.winner_site === positionId.site &&
        row.winner_idx === positionId.index });
  }
  const children = new Map();
  for (const group of groups.values()) {
    assert.equal(group.positions.length, group.count);
    const parent = group.parent === null ? 'ROOT' : key(group.parent);
    children.set(parent, [...(children.get(parent) ?? []), group]);
  }
  for (const siblings of children.values())
    siblings.sort((left, right) => -compareSeq(left.positions.at(-1).id, right.positions.at(-1).id));
  const result = [], visited = new Set();
  const append = parent => {
    for (const group of children.get(parent) ?? []) {
      assert(!visited.has(opKey(group.op)));
      visited.add(opKey(group.op));
      for (const position of group.positions) {
        if (position.active) result.push(position.pageId);
        append(key(position.id));
      }
    }
  };
  append('ROOT');
  assert.equal(visited.size, groups.size);
  return result;
}

function storedOrder() {
  return db.prepare('SELECT page_id FROM page_info ORDER BY page_index').all().map(row => row.page_id);
}

function snapshot() {
  return JSON.stringify({
    pages: db.prepare('SELECT * FROM page_info ORDER BY page_index').all(),
    groups: db.prepare('SELECT * FROM position_group ORDER BY op_ts,op_site').all(),
    positions: db.prepare('SELECT * FROM position ORDER BY op_ts,op_site,pos_idx').all(),
    winners: db.prepare('SELECT * FROM winner ORDER BY page_id').all(),
    operations: db.prepare('SELECT kind,target,history FROM operation_log ORDER BY sequence').all(),
    revision: db.prepare('SELECT revision FROM note_meta').get().revision,
  });
}

function persist(requested, movedPageId, opTs, historyId, fail = false) {
  const current = storedOrder();
  assert.deepEqual(crdtOrder(), current, 'original and materialized orders must start aligned');
  const move = plan(current, requested, movedPageId);
  const moved = db.prepare('SELECT * FROM identity WHERE page_id=?').get(move.movedPageId);
  const targetRow = move.predecessorPageId === null ? null :
    db.prepare('SELECT op_ts timestamp,op_site site,pos_idx `index` FROM winner WHERE page_id=?')
      .get(move.predecessorPageId);
  const target = targetRow === null ? null :
    seq(targetRow.timestamp, targetRow.site, targetRow.index);
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO position_group VALUES(?,?,?,?,?,1)').run(opTs, 2,
      target?.timestamp ?? null, target?.site ?? null, target?.index ?? null);
    db.prepare('INSERT INTO position VALUES(?,?,0,?)').run(opTs, 2, moved.page_id);
    db.prepare('UPDATE winner SET op_ts=?,op_site=2,pos_idx=0 WHERE page_id=?').run(opTs, moved.page_id);
    const materialized = crdtOrder();
    const update = db.prepare('UPDATE page_info SET page_index=? WHERE page_id=?');
    current.forEach((pageId, index) => assert.equal(update.run(-(index + 1), pageId).changes, 1));
    materialized.forEach((pageId, index) => assert.equal(update.run(index, pageId).changes, 1));
    db.prepare('UPDATE note_meta SET revision=revision+1').run();
    assert.deepEqual(storedOrder(), requested, 'reducer output must equal requested order');
    assert.deepEqual(crdtOrder(), requested, 'CRDT output must equal requested order');
    if (fail) throw new Error('injected after reducer');
    db.prepare('INSERT INTO operation_log(kind,target,history) VALUES(?,?,NULL)').run(
      'ORIGINAL_MODIFY_PAGE', JSON.stringify(target));
    db.prepare('INSERT INTO operation_log(kind,target,history) VALUES(?,?,?)').run(
      'REORDER_PAGES', movedPageId, historyId);
    db.exec('COMMIT');
    return target;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

assert.deepEqual(plan(['A','B','C','D'], ['A','C','B','D'], 'B'),
  { movedPageId: 'B', predecessorPageId: 'C' });
assert.deepEqual(plan(['A','B','C','D'], ['A','C','B','D'], 'C'),
  { movedPageId: 'C', predecessorPageId: 'A' });
assert.throws(() => plan(['A','B','C','D'], ['B','A','D','C'], 'A'),
  /not one relocation/);

assert.deepEqual(persist(['A','C','B','D'], 'B', 20, 'push-B'), seq(10,1,2));
const movedWinnerTarget = persist(['C','B','A','D'], 'A', 30, 'push-A');
assert.deepEqual(movedWinnerTarget, seq(20,2,0), 'predecessor must use its current winning position');
assert.equal(persist(['A','C','B','D'], 'A', 40, 'undo-A'), null);
assert.deepEqual(persist(['A','B','C','D'], 'B', 50, 'undo-B'), seq(40,2,0));
assert.deepEqual(storedOrder(), ['A','B','C','D']);

const beforeFailure = snapshot();
assert.throws(() => persist(['B','A','C','D'], 'B', 60, 'failed', true), /injected/);
assert.equal(snapshot(), beforeFailure);

const log = db.prepare('SELECT kind,history FROM operation_log ORDER BY sequence').all();
const visibleHistory = log.filter(row => row.kind !== 'ORIGINAL_MODIFY_PAGE').map(row => row.history);
assert.deepEqual(visibleHistory, ['push-B','push-A','undo-A','undo-B']);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM operation_log WHERE kind='ORIGINAL_MODIFY_PAGE'`)
  .get().count, 4);
assert.equal(db.prepare('SELECT revision FROM note_meta').get().revision, 4);
db.close();

console.log('localModifyPage=type4-single-drag-identity-winning-predecessor-root-undo-redo-history-transparent-rollback');
