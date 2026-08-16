import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const repairSource = read('note/src/main/ets/data/FolderHierarchyRepair.ets');
const managerSource = read('note/src/main/ets/data/DatabaseManager.ets');
const fixtureSource = read('note/src/test/FolderRepository.test.ets');

const normalizedOrder = value => Number.isFinite(value) ? value : 0;
const compare = (left, right) => normalizedOrder(left.siblingOrder) - normalizedOrder(right.siblingOrder) ||
  left.createdAt - right.createdAt || left.id.localeCompare(right.id);
const depth = (id, parents) => {
  let value = 1;
  let current = id;
  const visited = new Set();
  while (true) {
    if (visited.has(current)) return Number.MAX_SAFE_INTEGER;
    visited.add(current);
    const parent = parents.get(current);
    if (parent === undefined || parent === null) return value;
    value++;
    current = parent;
  }
};

function planRepairs(records) {
  const stable = [...records].sort(compare);
  const byId = new Map(stable.map(record => [record.id, record]));
  const rank = new Map(stable.map((record, index) => [record.id, index]));
  const parents = new Map(stable.map(record => [record.id,
    record.parentId === record.id || (record.parentId !== null && !byId.has(record.parentId))
      ? null : record.parentId]));
  for (const record of stable) {
    const path = [];
    const indexes = new Map();
    let current = record.id;
    while (current !== null) {
      if (indexes.has(current)) {
        const cycle = path.slice(indexes.get(current));
        const breakId = cycle.reduce((best, candidate) => rank.get(candidate) < rank.get(best) ? candidate : best);
        parents.set(breakId, null);
        break;
      }
      indexes.set(current, path.length);
      path.push(current);
      current = parents.get(current) ?? null;
    }
  }
  const shallowFirst = [...stable].sort((left, right) =>
    depth(left.id, parents) - depth(right.id, parents) || compare(left, right));
  for (const record of shallowFirst) {
    if (depth(record.id, parents) > 6) parents.set(record.id, null);
  }
  const orders = new Map();
  const parentKeys = [];
  for (const record of stable) {
    const parentId = parents.get(record.id) ?? null;
    if (!parentKeys.includes(parentId)) parentKeys.push(parentId);
  }
  for (const parentId of parentKeys) {
    stable.filter(record => (parents.get(record.id) ?? null) === parentId)
      .sort(compare).forEach((record, index) => orders.set(record.id, index));
  }
  return stable.map(record => ({ id: record.id, parentId: parents.get(record.id) ?? null,
    siblingOrder: orders.get(record.id) ?? 0 }))
    .filter(update => byId.get(update.id).parentId !== update.parentId ||
      byId.get(update.id).siblingOrder !== update.siblingOrder);
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec('PRAGMA foreign_keys=OFF');
  db.exec(`CREATE TABLE folder(
    id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL,
    parent_id TEXT, sibling_order REAL NOT NULL,
    FOREIGN KEY(parent_id) REFERENCES folder(id) ON DELETE CASCADE)`);
  const rows = [
    ['root', 'Root', 0, null, 10], ['orphan', 'Orphan', 1, 'missing', 5],
    ['cycle-a', 'Cycle A', 2, 'cycle-b', 1], ['cycle-b', 'Cycle B', 3, 'cycle-a', 2],
    ['self', 'Self', 10, 'self', 4],
    ['d2', 'D2', 4, 'root', 9], ['d3', 'D3', 5, 'd2', 9],
    ['d4', 'D4', 6, 'd3', 9], ['d5', 'D5', 7, 'd4', 9],
    ['d6', 'D6', 8, 'd5', 9], ['d7', 'D7', 9, 'd6', 9],
    ['gap', 'Gap', 10, null, 100],
  ];
  const insert = db.prepare('INSERT INTO folder VALUES(?,?,?,?,?)');
  for (const row of rows) insert.run(...row);
  return db;
}

function readRows(db) {
  return db.prepare(`SELECT id,name,created_at createdAt,parent_id parentId,
    sibling_order siblingOrder FROM folder`).all();
}

function applyStartupRepair(db, failAfter = -1) {
  const updates = planRepairs(readRows(db));
  db.exec('BEGIN IMMEDIATE');
  try {
    const update = db.prepare('UPDATE folder SET parent_id=?,sibling_order=? WHERE id=?');
    updates.forEach((value, index) => {
      assert.equal(update.run(value.parentId, value.siblingOrder, value.id).changes, 1);
      if (index === failAfter) throw new Error('injected startup repair failure');
    });
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const rollbackDb = database();
assert.throws(() => applyStartupRepair(rollbackDb, 0), /injected startup repair failure/);
assert.equal(rollbackDb.prepare("SELECT parent_id FROM folder WHERE id='orphan'").get().parent_id, 'missing');
rollbackDb.close();

const db = database();
const namesBefore = new Map(readRows(db).map(row => [row.id, row.name]));
applyStartupRepair(db);
db.exec('PRAGMA foreign_keys=ON');
assert.equal(db.prepare('PRAGMA foreign_key_check').all().length, 0);
const repaired = readRows(db);
assert.equal(repaired.length, namesBefore.size);
for (const row of repaired) assert.equal(row.name, namesBefore.get(row.id));
const parents = new Map(repaired.map(row => [row.id, row.parentId]));
for (const row of repaired) assert.ok(depth(row.id, parents) <= 6);
assert.equal(parents.get('orphan'), null);
assert.equal(parents.get('cycle-a'), null);
assert.equal(parents.get('cycle-b'), 'cycle-a');
assert.equal(parents.get('self'), null);
assert.equal(parents.get('d7'), null);
for (const parentId of new Set(repaired.map(row => row.parentId))) {
  const siblings = repaired.filter(row => row.parentId === parentId)
    .sort((left, right) => left.siblingOrder - right.siblingOrder);
  siblings.forEach((row, index) => assert.equal(row.siblingOrder, index));
}
assert.deepEqual(planRepairs(repaired), []);
applyStartupRepair(db);
assert.deepEqual(readRows(db), repaired);
db.close();

assert.match(repairSource, /ORIGINAL_MAX_FOLDER_DEPTH: number = 6/);
assert.match(repairSource, /parentId === record\.id/);
assert.match(repairSource, /!byId\.has\(parentId\)/);
assert.match(repairSource, /parents\.set\(breakId, null\)/);
assert.match(repairSource, /parentDepth\(record\.id, parents\) > ORIGINAL_MAX_FOLDER_DEPTH/);
assert.match(repairSource, /normalizedOrders\.set\(siblings\[index\]\.id, index\)/);
const transaction = managerSource.slice(managerSource.indexOf('await store.beginTransaction()',
  managerSource.indexOf('for (const ddl of ddlList)')), managerSource.indexOf('await this.verifyForeignKeys'));
assert.match(transaction, /await this\.repairFolderHierarchy\(store\)/);
assert.ok(transaction.indexOf('await this.repairFolderHierarchy(store)') < transaction.indexOf('await store.commit()'));
assert.match(transaction, /await store\.rollBack\(\)/);
assert.match(managerSource, /Database startup repair failed/);
assert.match(fixtureSource, /repairs old-library orphans, cycles, over-depth paths and sibling gaps deterministically/);

console.log('D02_FOLDER_STARTUP_INTEGRITY_REPAIR_REPLAY_OK ' +
  'preserve-all=1|preserve-names=1|orphan=1|self-parent=1|cycle-min-break=1|max-depth-6=1|' +
  'contiguous-orders=1|idempotent=1|foreign-key-check=0|transaction-rollback=1|' +
  'same-version-startup=1');
