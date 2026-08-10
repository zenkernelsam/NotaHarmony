import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

function u16(bytes, offset) { return bytes[offset] | (bytes[offset + 1] << 8); }
function u32(bytes, offset) {
  return (bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)) >>> 0;
}
function i32(bytes, offset) {
  return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getInt32(0, true);
}
function f32(bytes, offset) {
  return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true);
}
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) {
  bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24;
}
function wf32(bytes, offset, value) {
  new DataView(bytes.buffer, bytes.byteOffset + offset, 4).setFloat32(0, value, true);
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
    w32(this.bytes, table, table - vtable);
    return table;
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
  styleMap(entries) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + entries.length * 20;
    w32(this.bytes, vector, entries.length);
    entries.forEach((entry, index) => {
      const item = vector + 4 + index * 20;
      w32(this.bytes, item, entry.seed); wf32(this.bytes, item + 4, entry.x);
      wf32(this.bytes, item + 8, entry.y); wf32(this.bytes, item + 12, entry.phase);
      wf32(this.bytes, item + 16, entry.period);
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
    const pointer = this.table + offset;
    return new Table(this.bytes, pointer + u32(this.bytes, pointer));
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
  styleMap(field) {
    const offset = this.offset(field); if (!offset) return null;
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    const result = [], count = u32(this.bytes, vector);
    for (let index = 0; index < count; index++) {
      const item = vector + 4 + index * 20;
      result.push({ seed: i32(this.bytes, item), x: f32(this.bytes, item + 4),
        y: f32(this.bytes, item + 8), phase: f32(this.bytes, item + 12),
        period: f32(this.bytes, item + 16) });
    }
    return result;
  }
}

function fixture(targets, styleMap) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 5);
  builder.bytes[root + 28] = 17;
  const fields = new Array(19).fill(0); fields[0] = 4;
  if (styleMap !== undefined) fields[12] = 8;
  const modify = builder.table(fields, 12); builder.pointer(root + 32, modify);
  builder.pointer(modify + 4, builder.identities(targets));
  if (styleMap !== undefined) builder.pointer(modify + 8, builder.styleMap(styleMap));
  return builder.finish(root);
}

function encode(entries) {
  const bytes = new Uint8Array(entries.length * 20);
  entries.forEach((entry, index) => {
    const item = index * 20;
    w32(bytes, item, entry.seed); wf32(bytes, item + 4, entry.x); wf32(bytes, item + 8, entry.y);
    wf32(bytes, item + 12, entry.phase); wf32(bytes, item + 16, entry.period);
  });
  return Buffer.from(bytes).toString('hex');
}

function decode(raw) {
  const root = new Table(raw, u32(raw, 0));
  assert.equal(raw[root.table + root.offset(4)], 17);
  const table = root.nested(5);
  return { targets: table.identities(0), present: table.offset(12) !== 0,
    entries: table.styleMap(12) };
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=33;
    CREATE TABLE page(page_id TEXT PRIMARY KEY,revision INTEGER NOT NULL);
    CREATE TABLE element(ink_timestamp INTEGER,ink_site INTEGER,page_id TEXT,payload TEXT,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE ink_state(ink_timestamp INTEGER,ink_site INTEGER,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE create_state(ink_timestamp INTEGER,ink_site INTEGER,style_map TEXT,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE invalidation(page_id TEXT); CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO page VALUES('p1',1);
    INSERT INTO ink_state VALUES(20,2),(21,3);
    INSERT INTO create_state VALUES(20,2,NULL),(21,3,NULL);
    INSERT INTO element VALUES(20,2,'p1','{"styleMap":null}'),
      (21,3,'p1','{"styleMap":null}');`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE ink_state ADD COLUMN create_style_map TEXT;
      ALTER TABLE ink_state ADD COLUMN style_map_value TEXT;
      ALTER TABLE ink_state ADD COLUMN style_map_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN style_map_winner_site INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE ink_state ADD COLUMN style_map_winner_present INTEGER NOT NULL DEFAULT 0;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=34; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function newer(timestamp, site, state) {
  return !state.style_map_winner_present || timestamp > state.style_map_winner_timestamp ||
    (timestamp === state.style_map_winner_timestamp && site > state.style_map_winner_site);
}

function apply(db, timestamp, site, raw, inject = false) {
  const update = decode(raw); db.exec('BEGIN IMMEDIATE');
  try {
    if (!update.present) { db.exec('COMMIT'); return 'NOOP'; }
    if (update.entries.length > 1) { db.exec('ROLLBACK'); return 'MALFORMED'; }
    const value = encode(update.entries), plans = [];
    for (const target of update.targets) {
      const state = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      const create = db.prepare('SELECT * FROM create_state WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      const row = db.prepare('SELECT * FROM element WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      if (!state || !create || !row) { db.exec('ROLLBACK'); return 'MISSING'; }
      if (!newer(timestamp, site, state)) continue;
      const fallback = state.create_style_map ?? create.style_map;
      const expected = state.style_map_winner_present ? state.style_map_value : fallback;
      const current = JSON.parse(row.payload).styleMap;
      if (current !== expected) { db.exec('ROLLBACK'); return 'DIVERGED'; }
      plans.push({ target, fallback, value });
    }
    for (const plan of plans) {
      db.prepare('UPDATE element SET payload=? WHERE ink_timestamp=? AND ink_site=?')
        .run(JSON.stringify({ styleMap: plan.value }), plan.target.timestamp, plan.target.site);
      db.prepare(`UPDATE ink_state SET create_style_map=?,style_map_value=?,
        style_map_winner_timestamp=?,style_map_winner_site=?,style_map_winner_present=1
        WHERE ink_timestamp=? AND ink_site=?`)
        .run(plan.fallback, plan.value, timestamp, site, plan.target.timestamp, plan.target.site);
    }
    if (inject) throw new Error('injected apply');
    if (plans.length) {
      db.exec("UPDATE page SET revision=revision+1 WHERE page_id='p1'; INSERT INTO invalidation VALUES('p1')");
    }
    db.exec('COMMIT'); return plans.length ? 'APPLIED' : 'STALE';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const a = { timestamp: 20, site: 2 }, b = { timestamp: 21, site: 3 };
const first = [{ seed: -123, x: 1.5, y: -2.25, phase: 7.5, period: 30 }];
const second = [{ seed: 2147483647, x: 4, y: 5, phase: -2, period: 24 }];
const decoded = decode(fixture([a], first));
assert.equal(decoded.present, true); assert.deepEqual(decoded.targets, [a]);
assert.deepEqual(decoded.entries, first);
const cleared = decode(fixture([a], []));
assert.equal(cleared.present, true); assert.deepEqual(cleared.entries, []);
assert.equal(decode(fixture([a], undefined)).present, false);

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 34);
assert.equal(apply(db, 5, 1, fixture([a], first)), 'APPLIED');
assert.equal(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload)
  .styleMap, encode(first));
assert.equal(apply(db, 4, 9, fixture([a], second)), 'STALE');
assert.equal(apply(db, 6, 1, fixture([a], [])), 'APPLIED');
assert.equal(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload)
  .styleMap, '');

const before = db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload;
db.exec("UPDATE element SET payload='{\"styleMap\":\"bad\"}' WHERE ink_timestamp=21");
assert.equal(apply(db, 7, 1, fixture([a, b], second)), 'DIVERGED');
assert.equal(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload, before);
db.exec("UPDATE element SET payload='{\"styleMap\":null}' WHERE ink_timestamp=21");
assert.throws(() => apply(db, 8, 1, fixture([a, b], second), true), /injected apply/);
assert.equal(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload, before);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 0);
const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 33);

const renderer = fs.readFileSync(new URL(
  '../../../note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets', import.meta.url), 'utf8');
const createSource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalCreateInkOperation.ets', import.meta.url), 'utf8');
const modifySource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalModifyInkOperation.ets', import.meta.url), 'utf8');
const schema = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/DatabaseHelper.ets', import.meta.url), 'utf8');
assert.match(renderer, /setLineDashOffset/); assert.match(renderer, /backingDashPhase/);
assert.match(createSource, /create_style_map/); assert.match(createSource, /styleMap: payload\.styleMap/);
assert.match(modifySource, /field !== 11 && field !== 12 && field !== 13 && field !== 14 && field !== 15/);
assert.match(modifySource, /MODIFY_INK_STYLE_MAP_STATE_DIVERGED/);
assert.match(schema, /DB_VERSION: number = 47/); assert.match(schema, /style_map_winner_present/);

console.log('success|flatbuffer-field-12=1|signed-seed-floats=5|nullable-clear=1|' +
  'v33-v34=1|legacy-create-fallback=1|lww-stale=1|multi-ink-atomic=2|' +
  'rollback=2|dash-render-consumer=1|no-local-log=1');
