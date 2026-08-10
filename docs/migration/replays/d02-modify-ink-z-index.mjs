import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

function u16(bytes, offset) { return bytes[offset] | (bytes[offset + 1] << 8); }
function u32(bytes, offset) {
  return (bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)) >>> 0;
}
function i32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getInt32(0, true); }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) {
  bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24;
}
function w64(bytes, offset, value) {
  let remaining = BigInt(value);
  for (let index = 0; index < 8; index++) {
    bytes[offset + index] = Number(remaining & 255n); remaining >>= 8n;
  }
}

class Builder {
  constructor() { this.bytes = new Uint8Array(4096); this.cursor = 4; }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    this.align(4);
    const vtable = this.cursor; this.cursor += 4 + fields.length * 2;
    this.align(4);
    const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2); w16(this.bytes, vtable + 2, size);
    fields.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable); return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  identities(values) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + values.length * 8;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => {
      const item = vector + 4 + index * 8;
      w16(this.bytes, item, value.site); w32(this.bytes, item + 4, value.timestamp);
    });
    return vector;
  }
  finish(root) { w32(this.bytes, 0, root); return this.bytes.slice(0, this.cursor); }
}

class Table {
  constructor(bytes, table) {
    this.bytes = bytes; this.table = table; this.vtable = table - i32(bytes, table);
    this.vtableSize = u16(bytes, this.vtable);
  }
  offset(field) {
    const entry = this.vtable + 4 + field * 2;
    return entry + 2 <= this.vtable + this.vtableSize ? u16(this.bytes, entry) : 0;
  }
  nested(field) {
    const offset = this.offset(field); if (!offset) return null;
    const pointer = this.table + offset; return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  identities(field) {
    const pointer = this.table + this.offset(field), vector = pointer + u32(this.bytes, pointer);
    const result = [], count = u32(this.bytes, vector);
    for (let index = 0; index < count; index++) {
      const item = vector + 4 + index * 8;
      result.push({ timestamp: u32(this.bytes, item + 4), site: u16(this.bytes, item) });
    }
    return result;
  }
}

function fixture(targets, zIndex) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 5);
  w64(builder.bytes, root + 12, 1n); w64(builder.bytes, root + 20, 2n);
  builder.bytes[root + 28] = 17;
  const fields = [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0];
  const modify = builder.table(fields, 20); builder.pointer(root + 32, modify);
  builder.pointer(modify + 4, builder.identities(targets)); w64(builder.bytes, modify + 12, zIndex);
  return builder.finish(root);
}

function decode(bytes) {
  const root = new Table(bytes, u32(bytes, 0)); assert.equal(bytes[root.table + root.offset(4)], 17);
  const table = root.nested(5), offset = table.offset(13);
  assert.notEqual(offset, 0);
  let value = 0n;
  for (let index = 7; index >= 0; index--) value = (value << 8n) | BigInt(bytes[table.table + offset + index]);
  return { targets: table.identities(0), zIndex: value.toString() };
}

const inks = [{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }];

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=31;
    CREATE TABLE page(page_id TEXT PRIMARY KEY, archived INTEGER, revision INTEGER);
    CREATE TABLE element(page_id TEXT, element_id TEXT, kind INTEGER, payload TEXT, element_order INTEGER,
      PRIMARY KEY(page_id,element_id,kind));
    CREATE TABLE z_state(element_timestamp INTEGER,element_site INTEGER,page_id TEXT,kind INTEGER,z_index TEXT,
      PRIMARY KEY(element_timestamp,element_site));
    CREATE TABLE ink_state(ink_timestamp INTEGER,ink_site INTEGER,PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE create_state(ink_timestamp INTEGER,ink_site INTEGER,z_index TEXT,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE invalidation(page_id TEXT); CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO page VALUES('p1',0,1),('p2',0,5),('p3',1,8);
    INSERT INTO z_state VALUES(20,2,'p1',1,'10'),(30,1,'p1',1,'30'),
      (31,1,'p2',1,'5'),(32,1,'p2',1,'50'),(21,3,'p3',1,'12'),(33,1,'p3',1,'60');
    INSERT INTO ink_state VALUES(20,2),(21,3);
    INSERT INTO create_state VALUES(20,2,'10'),(21,3,'12');
    INSERT INTO element VALUES('p1','20:2',1,'ink-20',0),('p1','30:1',1,'fixed-30',1),
      ('p2','31:1',1,'fixed-31',0),('p2','32:1',1,'fixed-32',1),
      ('p3','21:3',1,'ink-21',0),('p3','33:1',1,'fixed-33',1);`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE ink_state ADD COLUMN create_z_index TEXT;
      ALTER TABLE ink_state ADD COLUMN z_index_value TEXT;
      ALTER TABLE ink_state ADD COLUMN z_index_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN z_index_winner_site INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN z_index_winner_present INTEGER NOT NULL DEFAULT 0;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=32; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function newer(timestamp, site, row) {
  return !row.z_index_winner_present || timestamp > row.z_index_winner_timestamp ||
    (timestamp === row.z_index_winner_timestamp && site > row.z_index_winner_site);
}
function compareRows(left, right) {
  const a = BigInt(left.z_index), b = BigInt(right.z_index);
  return a < b ? -1 : a > b ? 1 : left.element_timestamp - right.element_timestamp ||
    left.element_site - right.element_site;
}
function loadPageRows(db, pageId, cache) {
  if (cache.has(pageId)) return cache.get(pageId);
  const stored = db.prepare('SELECT element_id,kind FROM element WHERE page_id=?').all(pageId);
  const tracked = db.prepare('SELECT * FROM z_state WHERE page_id=?').all(pageId);
  if (stored.length !== tracked.length || stored.some(row => !tracked.some(item =>
    row.element_id === `${item.element_timestamp}:${item.element_site}` && row.kind === item.kind))) return null;
  tracked.sort(compareRows); cache.set(pageId, tracked); return tracked;
}

function apply(db, timestamp, site, raw, destinations = new Map(), inject = false) {
  const payload = decode(raw); db.exec('BEGIN IMMEDIATE');
  try {
    const plans = [], pageRows = new Map();
    for (const ink of payload.targets) {
      const state = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=? AND ink_site=?')
        .get(ink.timestamp, ink.site);
      const tracked = db.prepare('SELECT * FROM z_state WHERE element_timestamp=? AND element_site=?')
        .get(ink.timestamp, ink.site);
      const create = db.prepare('SELECT z_index FROM create_state WHERE ink_timestamp=? AND ink_site=?')
        .get(ink.timestamp, ink.site);
      if (!state || !tracked || !create) { db.exec('ROLLBACK'); return 'MISSING'; }
      if (!newer(timestamp, site, state)) continue;
      const base = state.create_z_index ?? create.z_index;
      const expected = state.z_index_winner_present ? state.z_index_value : base;
      if (tracked.z_index !== expected) { db.exec('ROLLBACK'); return 'DIVERGED'; }
      const destination = destinations.get(`${ink.timestamp}:${ink.site}`) ?? tracked.page_id;
      if (!db.prepare('SELECT 1 FROM page WHERE page_id=?').get(destination)) {
        db.exec('ROLLBACK'); return 'PAGE_MISSING';
      }
      const row = db.prepare('SELECT * FROM element WHERE page_id=? AND element_id=? AND kind=1')
        .get(tracked.page_id, `${ink.timestamp}:${ink.site}`);
      if (!row) { db.exec('ROLLBACK'); return 'DIVERGED'; }
      plans.push({ ink, state, tracked, row, destination, base });
    }
    for (const plan of plans) {
      const sourceRows = loadPageRows(db, plan.tracked.page_id, pageRows);
      const destinationRows = loadPageRows(db, plan.destination, pageRows);
      if (!sourceRows || !destinationRows) { db.exec('ROLLBACK'); return 'ORDER_DIVERGED'; }
      const index = sourceRows.findIndex(row => row.element_timestamp === plan.ink.timestamp &&
        row.element_site === plan.ink.site);
      if (index < 0) { db.exec('ROLLBACK'); return 'ORDER_DIVERGED'; }
      const moved = { ...sourceRows[index], page_id: plan.destination, z_index: payload.zIndex };
      if (plan.destination === plan.tracked.page_id) sourceRows[index] = moved;
      else { sourceRows.splice(index, 1); destinationRows.push(moved); }
      sourceRows.sort(compareRows); destinationRows.sort(compareRows);
    }
    const affected = new Set();
    for (const plan of plans) {
      const id = `${plan.ink.timestamp}:${plan.ink.site}`;
      if (plan.destination !== plan.tracked.page_id) {
        db.prepare('DELETE FROM element WHERE page_id=? AND element_id=? AND kind=1')
          .run(plan.tracked.page_id, id);
        db.prepare('INSERT INTO element VALUES(?,?,1,?,0)').run(plan.destination, id, plan.row.payload);
      }
      db.prepare(`UPDATE z_state SET page_id=?,z_index=? WHERE element_timestamp=? AND element_site=?
        AND page_id=? AND z_index=?`).run(plan.destination,payload.zIndex,plan.ink.timestamp,plan.ink.site,
          plan.tracked.page_id,plan.tracked.z_index);
      db.prepare(`UPDATE ink_state SET create_z_index=?,z_index_value=?,z_index_winner_timestamp=?,
        z_index_winner_site=?,z_index_winner_present=1 WHERE ink_timestamp=? AND ink_site=?`)
        .run(plan.base,payload.zIndex,timestamp,site,plan.ink.timestamp,plan.ink.site);
      affected.add(plan.tracked.page_id); affected.add(plan.destination);
    }
    for (const [pageId, rows] of pageRows) rows.forEach((row, index) =>
      db.prepare('UPDATE element SET element_order=? WHERE page_id=? AND element_id=? AND kind=?')
        .run(index,pageId,`${row.element_timestamp}:${row.element_site}`,row.kind));
    if (inject) throw new Error('injected apply');
    for (const pageId of affected) {
      db.prepare('UPDATE page SET revision=revision+1 WHERE page_id=?').run(pageId);
      db.prepare('INSERT INTO invalidation VALUES(?)').run(pageId);
    }
    db.exec('COMMIT'); return plans.length ? 'APPLIED' : 'STALE';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

assert.equal(decode(fixture(inks, 18446744073709551615n)).zIndex, '18446744073709551615');
const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 32);
assert.equal(apply(db, 5, 1, fixture([inks[0]], 40n)), 'APPLIED');
assert.deepEqual(db.prepare("SELECT element_id FROM element WHERE page_id='p1' ORDER BY element_order")
  .all().map(row => row.element_id), ['30:1', '20:2']);
assert.equal(db.prepare('SELECT create_z_index,z_index_value FROM ink_state WHERE ink_timestamp=20')
  .get().create_z_index, '10');
assert.equal(apply(db, 4, 9, fixture([inks[0]], 1n)), 'STALE');
assert.equal(db.prepare('SELECT z_index FROM z_state WHERE element_timestamp=20').get().z_index, '40');
const destinations = new Map([['20:2', 'p2']]);
assert.equal(apply(db, 6, 1, fixture([inks[0]], 3n), destinations), 'APPLIED');
assert.deepEqual(db.prepare("SELECT element_id FROM element WHERE page_id='p2' ORDER BY element_order")
  .all().map(row => row.element_id), ['20:2', '31:1', '32:1']);
assert.equal(db.prepare('SELECT z_index FROM z_state WHERE element_timestamp=20').get().z_index, '3');
assert.equal(apply(db, 7, 1, fixture([inks[1]], 18446744073709551615n)), 'APPLIED');
assert.deepEqual(db.prepare("SELECT element_id FROM element WHERE page_id='p3' ORDER BY element_order")
  .all().map(row => row.element_id), ['33:1', '21:3']);
const before = db.prepare('SELECT z_index_winner_timestamp value FROM ink_state WHERE ink_timestamp=20').get().value;
db.exec("UPDATE z_state SET z_index='999' WHERE element_timestamp=21");
assert.equal(apply(db, 8, 1, fixture(inks, 25n)), 'DIVERGED');
assert.equal(db.prepare('SELECT z_index_winner_timestamp value FROM ink_state WHERE ink_timestamp=20').get().value,before);
db.exec("UPDATE z_state SET z_index='18446744073709551615' WHERE element_timestamp=21");
assert.throws(() => apply(db, 9, 1, fixture(inks, 25n), new Map(), true), /injected apply/);
assert.equal(db.prepare('SELECT z_index_winner_timestamp value FROM ink_state WHERE ink_timestamp=20').get().value,before);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 0);
const orderBad = database(); migrate(orderBad);
orderBad.exec("INSERT INTO element VALUES('p1','local',1,'local',2)");
assert.equal(apply(orderBad, 5, 1, fixture([inks[0]], 40n)), 'ORDER_DIVERGED');
const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 31);

console.log('success|flatbuffer-u64-max=1|v31-v32=1|lower-first-wins=1|stale-rejected=1|' +
  'same-page-order=1|page-and-z-combined=1|archived-order=1|u64-order=2|' +
  'multi-ink-atomic=2|order-divergence=1|rollback=1|no-local-log=1');
