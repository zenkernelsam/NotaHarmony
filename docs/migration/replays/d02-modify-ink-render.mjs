import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor() { this.bytes = new Uint8Array(1024); this.cursor = 4; }
  align(value) { while ((this.cursor & (value - 1)) !== 0) this.cursor++; }
  table(offsets, size) {
    const vtable = this.cursor, vtableSize = 4 + offsets.length * 2;
    this.cursor += vtableSize; this.align(4); const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, vtableSize); w16(this.bytes, vtable + 2, size);
    offsets.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable); return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  identities(values) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + values.length * 8;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => {
      w16(this.bytes, vector + 4 + index * 8, value.site);
      w32(this.bytes, vector + 8 + index * 8, value.timestamp);
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
  has(field) { return this.offset(field) !== 0; }
  tableField(field) {
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset; return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  identities(field) {
    const offset = this.offset(field); assert.notEqual(offset, 0);
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    const count = u32(this.bytes, vector), result = [];
    for (let index = 0; index < count; index++) {
      const item = vector + 4 + index * 8;
      result.push({ timestamp: u32(this.bytes, item + 4), site: u16(this.bytes, item) });
    }
    return result;
  }
}

function fixture(targets, values = {}) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 91);
  w64(builder.bytes, root + 12, 123n); w64(builder.bytes, root + 20, 124n);
  builder.bytes[root + 28] = 17;
  const fields = [4, 0, 0, values.rotation === undefined ? 0 : 8, 0,
    values.style === undefined ? 0 : 12, values.color === undefined ? 0 : 16,
    values.width === undefined ? 0 : 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const modify = builder.table(fields, 24); builder.pointer(root + 32, modify);
  if (values.rotation !== undefined) wf32(builder.bytes, modify + 8, values.rotation);
  if (values.style !== undefined) builder.bytes[modify + 12] = values.style;
  if (values.color !== undefined) {
    builder.bytes[modify + 16] = values.color.r; builder.bytes[modify + 17] = values.color.g;
    builder.bytes[modify + 18] = values.color.b; builder.bytes[modify + 19] = values.color.a;
  }
  if (values.width !== undefined) wf32(builder.bytes, modify + 20, values.width);
  builder.pointer(modify + 4, builder.identities(targets));
  return builder.finish(root);
}

function decode(bytes) {
  const root = new Table(bytes, u32(bytes, 0)); assert.equal(bytes[root.table + root.offset(4)], 17);
  const table = root.tableField(5), targets = table.identities(0);
  let unsupported = false;
  for (let field = 1; field <= 18; field++) {
    if (![5, 6, 7, 8].includes(field) && table.has(field)) unsupported = true;
  }
  const style = table.has(5) ? Math.min(table.bytes[table.table + table.offset(5)], 3) : null;
  const colorOffset = table.offset(6);
  const color = colorOffset === 0 ? null :
    ((table.bytes[table.table + colorOffset + 3] << 24) |
      (table.bytes[table.table + colorOffset] << 16) |
      (table.bytes[table.table + colorOffset + 1] << 8) |
      table.bytes[table.table + colorOffset + 2]);
  const width = table.has(7) ? f32at(table.bytes, table.table + table.offset(7)) : null;
  return { targets, style, color, width, unsupported };
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=28;
    CREATE TABLE original_ink_state(note_id TEXT,ink_timestamp INTEGER,ink_site_id INTEGER,
      base_center_path BLOB,center_path_winner_timestamp INTEGER,center_path_winner_site_id INTEGER,
      PRIMARY KEY(note_id,ink_timestamp,ink_site_id));
    CREATE TABLE create_render(ink_timestamp INTEGER,ink_site_id INTEGER,style INTEGER,color INTEGER,
      width REAL,PRIMARY KEY(ink_timestamp,ink_site_id));
    CREATE TABLE stroke(ink_timestamp INTEGER,ink_site_id INTEGER,style INTEGER,color INTEGER,width REAL,
      attributed INTEGER,bounds_padding REAL,revision INTEGER,
      PRIMARY KEY(ink_timestamp,ink_site_id));
    CREATE TABLE page_info(id INTEGER PRIMARY KEY,content_revision INTEGER);
    CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO original_ink_state VALUES('n',20,2,x'010002',20,2);
    INSERT INTO original_ink_state VALUES('n',21,3,x'010002',21,3);
    INSERT INTO create_render VALUES(20,2,1,-16711165,2.0);
    INSERT INTO create_render VALUES(21,3,1,-16711165,2.0);
    INSERT INTO stroke VALUES(20,2,1,-16711165,2.0,1,4.0,1);
    INSERT INTO stroke VALUES(21,3,1,-16711165,2.0,1,4.0,1);
    INSERT INTO page_info VALUES(1,1);`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE original_ink_state ADD COLUMN style_value INTEGER;
      ALTER TABLE original_ink_state ADD COLUMN style_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN style_winner_site_id INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN color_value INTEGER;
      ALTER TABLE original_ink_state ADD COLUMN color_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN color_winner_site_id INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN width_value REAL;
      ALTER TABLE original_ink_state ADD COLUMN width_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN width_winner_site_id INTEGER NOT NULL DEFAULT 0;
      UPDATE original_ink_state SET
        style_winner_timestamp=ink_timestamp,style_winner_site_id=ink_site_id,
        color_winner_timestamp=ink_timestamp,color_winner_site_id=ink_site_id,
        width_winner_timestamp=ink_timestamp,width_winner_site_id=ink_site_id;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=29; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function apply(db, timestamp, site, raw, inject = false) {
  const payload = decode(raw);
  if (payload.unsupported) return 'UNSUPPORTED_FIELDS';
  if (payload.width !== null && (!Number.isFinite(payload.width) || payload.width < 0)) {
    return 'WIDTH_UNSUPPORTED';
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    const plans = [];
    for (const target of payload.targets) {
      const state = db.prepare(`SELECT * FROM original_ink_state WHERE note_id='n'
        AND ink_timestamp=? AND ink_site_id=?`).get(target.timestamp, target.site);
      if (state === undefined) { db.exec('ROLLBACK'); return 'MISSING_STATE'; }
      const replaceStyle = payload.style !== null && newer(timestamp, site,
        state.style_winner_timestamp, state.style_winner_site_id);
      const replaceColor = payload.color !== null && newer(timestamp, site,
        state.color_winner_timestamp, state.color_winner_site_id);
      const replaceWidth = payload.width !== null && newer(timestamp, site,
        state.width_winner_timestamp, state.width_winner_site_id);
      if (!replaceStyle && !replaceColor && !replaceWidth) continue;
      const stroke = db.prepare(`SELECT * FROM stroke WHERE ink_timestamp=? AND ink_site_id=?`)
        .get(target.timestamp, target.site);
      const initial = db.prepare(`SELECT * FROM create_render WHERE ink_timestamp=? AND ink_site_id=?`)
        .get(target.timestamp, target.site);
      if (stroke === undefined || initial === undefined) { db.exec('ROLLBACK'); return 'MISSING_RENDER'; }
      const oldStyle = state.style_value ?? initial.style;
      const oldColor = state.color_value ?? initial.color;
      const oldWidth = state.width_value ?? initial.width;
      if ((replaceStyle && stroke.style !== oldStyle) || (replaceColor && stroke.color !== oldColor) ||
        (replaceWidth && stroke.width !== oldWidth)) { db.exec('ROLLBACK'); return 'DIVERGED'; }
      const next = { style: replaceStyle ? payload.style : stroke.style,
        color: replaceColor ? payload.color : stroke.color,
        width: replaceWidth ? payload.width : stroke.width };
      if (next.style === 0 && stroke.attributed !== 1) {
        db.exec('ROLLBACK'); return 'VARIABLE_ATTRIBUTES_MISSING';
      }
      plans.push({ target, state, replaceStyle, replaceColor, replaceWidth, next });
    }
    for (const plan of plans) {
      const values = [], assignments = [];
      for (const name of ['style', 'color', 'width']) {
        const replace = plan[`replace${name[0].toUpperCase()}${name.slice(1)}`];
        if (!replace) continue;
        assignments.push(`${name}_value=?,${name}_winner_timestamp=?,${name}_winner_site_id=?`);
        values.push(plan.next[name], timestamp, site);
      }
      values.push(plan.target.timestamp, plan.target.site);
      db.prepare(`UPDATE original_ink_state SET ${assignments.join(',')} WHERE note_id='n'
        AND ink_timestamp=? AND ink_site_id=?`).run(...values);
      db.prepare(`UPDATE stroke SET style=?,color=?,width=?,bounds_padding=?,revision=revision+1
        WHERE ink_timestamp=? AND ink_site_id=?`).run(plan.next.style, plan.next.color,
        plan.next.width, plan.next.width * 2, plan.target.timestamp, plan.target.site);
    }
    if (inject) throw new Error('injected apply');
    if (plans.length > 0) db.exec('UPDATE page_info SET content_revision=content_revision+1 WHERE id=1');
    db.exec('COMMIT'); return plans.length === 0 ? 'STALE' : 'APPLIED';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const targets = [{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }];
const rgba = { r: 1, g: 2, b: 3, a: 128 };
const decoded = decode(fixture(targets, { style: 2, color: rgba, width: 5 }));
assert.deepEqual(decoded.targets, targets); assert.equal(decoded.style, 2);
assert.equal(decoded.color, -2147417597); assert.equal(decoded.width, 5);
assert.equal(decode(fixture(targets, { rotation: 0.5 })).unsupported, true);

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 29);
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_state
  WHERE style_value IS NULL AND color_value IS NULL AND width_value IS NULL`).get().count, 2);
assert.equal(apply(db, 100, 1, fixture(targets, { style: 2, color: rgba, width: 5 })), 'APPLIED');
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 2);
assert.deepEqual({ ...db.prepare(`SELECT style,color,width,bounds_padding FROM stroke
  WHERE ink_timestamp=20`).get() }, { style: 2, color: -2147417597, width: 5, bounds_padding: 10 });
assert.equal(apply(db, 101, 1, fixture(targets, { style: 3 })), 'APPLIED');
assert.equal(apply(db, 100, 2, fixture(targets, { width: 7 })), 'APPLIED');
const winners = db.prepare(`SELECT style_winner_timestamp style_ts,style_winner_site_id style_site,
  width_winner_timestamp width_ts,width_winner_site_id width_site FROM original_ink_state
  WHERE ink_timestamp=20`).get();
assert.deepEqual({ ...winners }, { style_ts: 101, style_site: 1, width_ts: 100, width_site: 2 });
assert.equal(apply(db, 100, 9, fixture(targets, { style: 1 })), 'STALE');
assert.equal(apply(db, 102, 1, fixture(targets, { rotation: 0.2 })), 'UNSUPPORTED_FIELDS');
assert.equal(apply(db, 102, 1, fixture(targets, { width: -1 })), 'WIDTH_UNSUPPORTED');

db.exec(`UPDATE stroke SET attributed=0 WHERE ink_timestamp=20;
  UPDATE stroke SET color=123 WHERE ink_timestamp=21;`);
const before = db.prepare(`SELECT color_winner_timestamp winner FROM original_ink_state
  WHERE ink_timestamp=20`).get();
assert.equal(apply(db, 103, 1, fixture(targets, { color: { r: 9, g: 8, b: 7, a: 255 } })),
  'DIVERGED');
assert.deepEqual({ ...db.prepare(`SELECT color_winner_timestamp winner FROM original_ink_state
  WHERE ink_timestamp=20`).get() }, { ...before });
assert.equal(apply(db, 103, 1, fixture([{ timestamp: 20, site: 2 }], { style: 0 })),
  'VARIABLE_ATTRIBUTES_MISSING');
db.exec(`UPDATE stroke SET attributed=1 WHERE ink_timestamp=20;
  UPDATE stroke SET color=-2147417597 WHERE ink_timestamp=21;`);
assert.throws(() => apply(db, 104, 1, fixture(targets, { width: 8 }), true), /injected apply/);
assert.equal(db.prepare(`SELECT width_winner_timestamp winner FROM original_ink_state
  WHERE ink_timestamp=20`).get().winner, 100);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 0);

const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 28);
assert.equal(failed.prepare(`SELECT count(*) count FROM pragma_table_info('original_ink_state')
  WHERE name='style_value'`).get().count, 0);

console.log('success|flatbuffer-fields=5,6,7|v28-v29=1|legacy-create-recovery=2|' +
  'independent-lww=3|multi-ink=2|single-page-revision=1|width-bounds=10|' +
  'unsupported-gate=1|negative-width-deferred=1|variable-attributes-gate=1|' +
  'divergence-atomic=1|rollback=1|no-local-log=1');

function newer(timestamp, site, oldTimestamp, oldSite) {
  return timestamp > oldTimestamp || (timestamp === oldTimestamp && site > oldSite);
}
function f32at(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
function u16(bytes, offset) { return bytes[offset] + bytes[offset + 1] * 256; }
function u32(bytes, offset) { return bytes[offset] + bytes[offset + 1] * 256 +
  bytes[offset + 2] * 65536 + bytes[offset + 3] * 16777216; }
function i32(bytes, offset) { const value = u32(bytes, offset); return value >= 2147483648 ? value - 4294967296 : value; }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24; }
function w64(bytes, offset, value) { for (let index = 0; index < 8; index++) {
  bytes[offset + index] = Number(value & 255n); value >>= 8n; } }
function wf32(bytes, offset, value) { new DataView(bytes.buffer, offset, 4).setFloat32(0, value, true); }
