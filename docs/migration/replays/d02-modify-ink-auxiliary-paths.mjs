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
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) {
  bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24;
}

class Builder {
  constructor() { this.bytes = new Uint8Array(8192); this.cursor = 4; }
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
  byteVector(value) {
    this.align(4); const vector = this.cursor; this.cursor += 5 + value.length;
    w32(this.bytes, vector, value.length); this.bytes.set(value, vector + 4);
    this.bytes[vector + 4 + value.length] = 0;
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
  vector(field) {
    const offset = this.offset(field); if (!offset) return null;
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    return this.bytes.slice(vector + 4, vector + 4 + u32(this.bytes, vector));
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

function fixture(targets, update) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 5);
  builder.bytes[root + 28] = 17;
  const fields = new Array(19).fill(0);
  fields[0] = 4;
  if (update.custom !== undefined) fields[9] = 8;
  if (update.fill !== undefined) fields[10] = 12;
  if (update.fillColor !== undefined) fields[11] = 16;
  const modify = builder.table(fields, 20); builder.pointer(root + 32, modify);
  builder.pointer(modify + 4, builder.identities(targets));
  if (update.custom !== undefined) builder.pointer(modify + 8, builder.byteVector(update.custom));
  if (update.fill !== undefined) builder.pointer(modify + 12, builder.byteVector(update.fill));
  if (update.fillColor !== undefined) {
    const setterFields = [update.fillColor === null ? 0 : 4];
    const setter = builder.table(setterFields, 8); builder.pointer(modify + 16, setter);
    if (update.fillColor !== null) builder.bytes.set(update.fillColor, setter + 4);
  }
  return builder.finish(root);
}

function hex(bytes) { return bytes === null ? null : Buffer.from(bytes).toString('hex'); }
function decode(raw) {
  const root = new Table(raw, u32(raw, 0));
  assert.equal(raw[root.table + root.offset(4)], 17);
  const table = root.nested(5), setter = table.nested(11);
  const custom = table.vector(9), fill = table.vector(10);
  const colorOffset = setter === null ? 0 : setter.offset(0);
  return {
    targets: table.identities(0),
    customPresent: table.offset(9) !== 0,
    custom: custom !== null && custom.length >= 3 && custom[1] === 0 && custom[2] === 0 ? null : hex(custom),
    fillPresent: table.offset(10) !== 0,
    fill: fill !== null && fill.length >= 3 && fill[1] === 0 && fill[2] === 0 ? null : hex(fill),
    fillColorPresent: setter !== null,
    fillColor: colorOffset === 0 ? null :
      ((setter.bytes[setter.table + colorOffset + 3] << 24) |
       (setter.bytes[setter.table + colorOffset] << 16) |
       (setter.bytes[setter.table + colorOffset + 1] << 8) |
       setter.bytes[setter.table + colorOffset + 2]),
  };
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=32;
    CREATE TABLE page(page_id TEXT PRIMARY KEY,revision INTEGER NOT NULL);
    CREATE TABLE element(ink_timestamp INTEGER,ink_site INTEGER,page_id TEXT,payload TEXT,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE ink_state(ink_timestamp INTEGER,ink_site INTEGER,
      PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE create_state(ink_timestamp INTEGER,ink_site INTEGER,custom_path TEXT,fill_path TEXT,
      fill_color INTEGER,PRIMARY KEY(ink_timestamp,ink_site));
    CREATE TABLE invalidation(page_id TEXT); CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO page VALUES('p1',1);
    INSERT INTO ink_state VALUES(20,2),(21,3);
    INSERT INTO create_state VALUES(20,2,'000001aa','000001bb',-65536),
      (21,3,NULL,NULL,NULL);
    INSERT INTO element VALUES(20,2,'p1',
      '{"custom":"000001aa","fill":"000001bb","fillColor":-65536}'),
      (21,3,'p1','{"custom":null,"fill":null,"fillColor":null}');`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    for (const prefix of ['custom_path', 'fill_path', 'fill_color']) {
      db.exec(`ALTER TABLE ink_state ADD COLUMN create_${prefix} ${prefix === 'fill_color' ? 'INTEGER' : 'TEXT'};
        ALTER TABLE ink_state ADD COLUMN ${prefix}_value ${prefix === 'fill_color' ? 'INTEGER' : 'TEXT'};
        ALTER TABLE ink_state ADD COLUMN ${prefix}_winner_timestamp INTEGER NOT NULL DEFAULT 0;
        ALTER TABLE ink_state ADD COLUMN ${prefix}_winner_site INTEGER NOT NULL DEFAULT 0;
        ALTER TABLE ink_state ADD COLUMN ${prefix}_winner_present INTEGER NOT NULL DEFAULT 0;`);
    }
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=33; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function newer(timestamp, site, state, prefix) {
  return !state[`${prefix}_winner_present`] || timestamp > state[`${prefix}_winner_timestamp`] ||
    (timestamp === state[`${prefix}_winner_timestamp`] && site > state[`${prefix}_winner_site`]);
}

function apply(db, timestamp, site, raw, inject = false) {
  const update = decode(raw); db.exec('BEGIN IMMEDIATE');
  try {
    const plans = [];
    for (const target of update.targets) {
      const state = db.prepare('SELECT * FROM ink_state WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      const create = db.prepare('SELECT * FROM create_state WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      const row = db.prepare('SELECT * FROM element WHERE ink_timestamp=? AND ink_site=?')
        .get(target.timestamp, target.site);
      if (!state || !create || !row) { db.exec('ROLLBACK'); return 'MISSING'; }
      const current = JSON.parse(row.payload), next = { ...current }, accepted = [];
      for (const [prefix, present, value, property] of [
        ['custom_path', update.customPresent, update.custom, 'custom'],
        ['fill_path', update.fillPresent, update.fill, 'fill'],
        ['fill_color', update.fillColorPresent, update.fillColor, 'fillColor'],
      ]) {
        if (!present || !newer(timestamp, site, state, prefix)) continue;
        const fallback = state[`create_${prefix}`] ?? create[prefix];
        const expected = state[`${prefix}_winner_present`] ? state[`${prefix}_value`] : fallback;
        if (current[property] !== expected) { db.exec('ROLLBACK'); return 'DIVERGED'; }
        next[property] = value; accepted.push({ prefix, value, fallback });
      }
      if (accepted.length) plans.push({ target, row, next, accepted });
    }
    for (const plan of plans) {
      db.prepare('UPDATE element SET payload=? WHERE ink_timestamp=? AND ink_site=?')
        .run(JSON.stringify(plan.next), plan.target.timestamp, plan.target.site);
      for (const accepted of plan.accepted) {
        db.prepare(`UPDATE ink_state SET create_${accepted.prefix}=?,${accepted.prefix}_value=?,
          ${accepted.prefix}_winner_timestamp=?,${accepted.prefix}_winner_site=?,
          ${accepted.prefix}_winner_present=1 WHERE ink_timestamp=? AND ink_site=?`)
          .run(accepted.fallback, accepted.value, timestamp, site,
            plan.target.timestamp, plan.target.site);
      }
    }
    if (inject) throw new Error('injected apply');
    if (plans.length) {
      db.exec("UPDATE page SET revision=revision+1 WHERE page_id='p1'; INSERT INTO invalidation VALUES('p1')");
    }
    db.exec('COMMIT'); return plans.length ? 'APPLIED' : 'STALE';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const a = { timestamp: 20, site: 2 }, b = { timestamp: 21, site: 3 };
const pathA = Uint8Array.from([0, 0, 1, 170]), pathB = Uint8Array.from([0, 0, 1, 187]);
const clearPath = Uint8Array.from([0, 0, 0]);
const decoded = decode(fixture([a], { custom: pathA, fill: pathB, fillColor: [1, 2, 3, 128] }));
assert.equal(decoded.custom, '000001aa'); assert.equal(decoded.fill, '000001bb');
assert.equal(decoded.fillColor, -2147417597);
const cleared = decode(fixture([a], { custom: clearPath, fillColor: null }));
assert.equal(cleared.customPresent, true); assert.equal(cleared.custom, null);
assert.equal(cleared.fillColorPresent, true); assert.equal(cleared.fillColor, null);

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 33);
assert.equal(apply(db, 5, 1, fixture([a], { custom: Uint8Array.from([0,0,1,204]) })), 'APPLIED');
assert.equal(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload).custom,
  '000001cc');
assert.equal(db.prepare('SELECT create_custom_path FROM ink_state WHERE ink_timestamp=20').get()
  .create_custom_path, '000001aa');
assert.equal(apply(db, 4, 9, fixture([a], { fill: Uint8Array.from([0,0,1,221]) })), 'APPLIED');
assert.equal(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload).fill,
  '000001dd');
assert.equal(apply(db, 3, 1, fixture([a], { custom: pathA })), 'STALE');
assert.equal(apply(db, 6, 1, fixture([a], { custom: clearPath, fillColor: null })), 'APPLIED');
assert.deepEqual(JSON.parse(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload),
  { custom: null, fill: '000001dd', fillColor: null });

const before = db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload;
db.exec("UPDATE element SET payload='{" + '"custom":null,"fill":null,"fillColor":123}' + "' WHERE ink_timestamp=21");
assert.equal(apply(db, 7, 1, fixture([a, b], { fillColor: [9, 8, 7, 255] })), 'DIVERGED');
assert.equal(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload, before);
db.exec("UPDATE element SET payload='{" + '"custom":null,"fill":null,"fillColor":null}' + "' WHERE ink_timestamp=21");
assert.throws(() => apply(db, 8, 1, fixture([a, b], { fillColor: [9, 8, 7, 255] }), true),
  /injected apply/);
assert.equal(db.prepare('SELECT payload FROM element WHERE ink_timestamp=20').get().payload, before);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 0);
const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 32);

const renderer = fs.readFileSync(new URL('../../../note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets',
  import.meta.url), 'utf8');
const createSource = fs.readFileSync(new URL('../../../note/src/main/ets/data/OriginalCreateInkOperation.ets',
  import.meta.url), 'utf8');
const modifySource = fs.readFileSync(new URL('../../../note/src/main/ets/data/OriginalModifyInkOperation.ets',
  import.meta.url), 'utf8');
assert.match(renderer, /renderInkFill/); assert.match(renderer, /c\.clip\('evenodd'\)/);
assert.match(renderer, /renderCustomPath/); assert.match(createSource, /customPath: payload\.customPath/);
assert.match(modifySource, /MODIFY_INK_AUXILIARY_STATE_DIVERGED/);
assert.match(modifySource, /field !== 11 && field !== 12 && field !== 13/);

console.log('success|flatbuffer-fields-9-11=3|nullable-clear=2|v32-v33=1|' +
  'legacy-create-fallback=1|independent-registers=2|stale-rejected=1|' +
  'multi-ink-atomic=2|rollback=1|render-paths=3|no-local-log=1');
