import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor() { this.bytes = new Uint8Array(2048); this.cursor = 4; }
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
  nested(field) {
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset; return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  identities(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    const vector = pointer + u32(this.bytes, pointer), count = u32(this.bytes, vector), result = [];
    for (let index = 0; index < count; index++) {
      const item = vector + 4 + index * 8;
      result.push({ timestamp: u32(this.bytes, item + 4), site: u16(this.bytes, item) });
    }
    return result;
  }
}

function fixture(targets, values = {}) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 8);
  w64(builder.bytes, root + 12, 1n); w64(builder.bytes, root + 20, 2n);
  builder.bytes[root + 28] = 17;
  const fields = [4, 0, 0, values.rotation === undefined ? 0 : 8,
    values.scale === undefined ? 0 : 12, values.style === undefined ? 0 : 16,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const modify = builder.table(fields, 20); builder.pointer(root + 32, modify);
  if (values.rotation !== undefined) {
    const setter = builder.table([values.rotation === null ? 0 : 4], 8);
    if (values.rotation !== null) wf32(builder.bytes, setter + 4, values.rotation);
    builder.pointer(modify + 8, setter);
  }
  if (values.scale !== undefined) {
    const setter = builder.table([values.scale === null ? 0 : 4], 12);
    if (values.scale !== null) {
      wf32(builder.bytes, setter + 4, values.scale.x);
      wf32(builder.bytes, setter + 8, values.scale.y);
    }
    builder.pointer(modify + 12, setter);
  }
  if (values.style !== undefined) builder.bytes[modify + 16] = values.style;
  builder.pointer(modify + 4, builder.identities(targets));
  return builder.finish(root);
}

function decode(bytes) {
  const root = new Table(bytes, u32(bytes, 0));
  assert.equal(bytes[root.table + root.offset(4)], 17);
  const table = root.nested(5), rotation = table.nested(3), scale = table.nested(4);
  const rotationOffset = rotation?.offset(0) ?? 0, scaleOffset = scale?.offset(0) ?? 0;
  return {
    targets: table.identities(0),
    rotation: { present: rotation !== null,
      value: rotationOffset === 0 ? null : f32(bytes, rotation.table + rotationOffset) },
    scale: { present: scale !== null, value: scaleOffset === 0 ? null : {
      x: f32(bytes, scale.table + scaleOffset), y: f32(bytes, scale.table + scaleOffset + 4),
    } },
    style: table.has(5) ? bytes[table.table + table.offset(5)] : null,
  };
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=29;
    CREATE TABLE original_ink_state(note_id TEXT,ink_timestamp INTEGER,ink_site_id INTEGER,
      base_center_path BLOB,center_path_winner_timestamp INTEGER,center_path_winner_site_id INTEGER,
      style_value INTEGER,style_winner_timestamp INTEGER,style_winner_site_id INTEGER,
      color_value INTEGER,color_winner_timestamp INTEGER,color_winner_site_id INTEGER,
      width_value REAL,width_winner_timestamp INTEGER,width_winner_site_id INTEGER,
      PRIMARY KEY(note_id,ink_timestamp,ink_site_id));
    CREATE TABLE create_transform(ink_timestamp INTEGER,ink_site_id INTEGER,origin_x REAL,origin_y REAL,
      rotation REAL,scale_x REAL,scale_y REAL,PRIMARY KEY(ink_timestamp,ink_site_id));
    CREATE TABLE stroke(ink_timestamp INTEGER,ink_site_id INTEGER,transform TEXT,revision INTEGER,
      PRIMARY KEY(ink_timestamp,ink_site_id));
    CREATE TABLE page_info(id INTEGER PRIMARY KEY,content_revision INTEGER);
    CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO original_ink_state VALUES('n',20,2,x'010002',20,2,1,20,2,-1,20,2,2,20,2);
    INSERT INTO original_ink_state VALUES('n',21,3,x'010002',21,3,1,99,4,-1,21,3,2,21,3);
    INSERT INTO create_transform VALUES(20,2,10,20,0.25,1.5,0.5);
    INSERT INTO create_transform VALUES(21,3,-4,6,-0.5,2,3);
    INSERT INTO stroke VALUES(20,2,'${JSON.stringify(matrix(10, 20, 0.25, 1.5, 0.5))}',1);
    INSERT INTO stroke VALUES(21,3,'${JSON.stringify(matrix(-4, 6, -0.5, 2, 3))}',1);
    INSERT INTO page_info VALUES(1,1);`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE original_ink_state ADD COLUMN center_path_winner_present INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN style_winner_present INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN color_winner_present INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN width_winner_present INTEGER NOT NULL DEFAULT 0;
      UPDATE original_ink_state SET
        center_path_winner_present=(center_path_winner_timestamp<>ink_timestamp OR center_path_winner_site_id<>ink_site_id),
        style_winner_present=(style_winner_timestamp<>ink_timestamp OR style_winner_site_id<>ink_site_id),
        color_winner_present=(color_winner_timestamp<>ink_timestamp OR color_winner_site_id<>ink_site_id),
        width_winner_present=(width_winner_timestamp<>ink_timestamp OR width_winner_site_id<>ink_site_id);
      ALTER TABLE original_ink_state ADD COLUMN create_origin_x REAL;
      ALTER TABLE original_ink_state ADD COLUMN create_origin_y REAL;
      ALTER TABLE original_ink_state ADD COLUMN create_rotation REAL;
      ALTER TABLE original_ink_state ADD COLUMN create_scale_x REAL;
      ALTER TABLE original_ink_state ADD COLUMN create_scale_y REAL;
      ALTER TABLE original_ink_state ADD COLUMN rotation_value REAL;
      ALTER TABLE original_ink_state ADD COLUMN rotation_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN rotation_winner_site_id INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN rotation_winner_present INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN scale_x_value REAL;
      ALTER TABLE original_ink_state ADD COLUMN scale_y_value REAL;
      ALTER TABLE original_ink_state ADD COLUMN scale_winner_timestamp INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN scale_winner_site_id INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE original_ink_state ADD COLUMN scale_winner_present INTEGER NOT NULL DEFAULT 0;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=30; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function apply(db, timestamp, site, raw, inject = false) {
  const payload = decode(raw); db.exec('BEGIN IMMEDIATE');
  try {
    const plans = [];
    for (const target of payload.targets) {
      const state = db.prepare(`SELECT * FROM original_ink_state WHERE note_id='n'
        AND ink_timestamp=? AND ink_site_id=?`).get(target.timestamp, target.site);
      const create = db.prepare(`SELECT * FROM create_transform WHERE ink_timestamp=? AND ink_site_id=?`)
        .get(target.timestamp, target.site);
      const stroke = db.prepare(`SELECT * FROM stroke WHERE ink_timestamp=? AND ink_site_id=?`)
        .get(target.timestamp, target.site);
      if (!state || !create || !stroke) { db.exec('ROLLBACK'); return 'MISSING'; }
      const replaceRotation = payload.rotation.present && accepts(timestamp, site,
        state.rotation_winner_present, state.rotation_winner_timestamp, state.rotation_winner_site_id);
      const replaceScale = payload.scale.present && accepts(timestamp, site,
        state.scale_winner_present, state.scale_winner_timestamp, state.scale_winner_site_id);
      const replaceStyle = payload.style !== null && accepts(timestamp, site,
        state.style_winner_present, state.style_winner_timestamp, state.style_winner_site_id);
      if (!replaceRotation && !replaceScale && !replaceStyle) continue;
      const oldRotation = state.rotation_winner_present && state.rotation_value !== null ?
        state.rotation_value : create.rotation;
      const oldScale = state.scale_winner_present && state.scale_x_value !== null ?
        { x: state.scale_x_value, y: state.scale_y_value } : { x: create.scale_x, y: create.scale_y };
      if (stroke.transform !== JSON.stringify(matrix(create.origin_x, create.origin_y,
        oldRotation, oldScale.x, oldScale.y))) { db.exec('ROLLBACK'); return 'DIVERGED'; }
      const nextRotation = replaceRotation ? payload.rotation.value ?? create.rotation : oldRotation;
      const nextScale = replaceScale ? payload.scale.value ?? { x: create.scale_x, y: create.scale_y } : oldScale;
      plans.push({ target, replaceRotation, replaceScale, replaceStyle, nextRotation, nextScale,
        rotationValue: payload.rotation.value, scaleValue: payload.scale.value, create });
    }
    for (const plan of plans) {
      const sets = [`create_origin_x=?`,`create_origin_y=?`,`create_rotation=?`,
        `create_scale_x=?`,`create_scale_y=?`];
      const args = [plan.create.origin_x, plan.create.origin_y, plan.create.rotation,
        plan.create.scale_x, plan.create.scale_y];
      if (plan.replaceRotation) {
        sets.push('rotation_value=?','rotation_winner_timestamp=?','rotation_winner_site_id=?',
          'rotation_winner_present=1'); args.push(plan.rotationValue, timestamp, site);
      }
      if (plan.replaceScale) {
        sets.push('scale_x_value=?','scale_y_value=?','scale_winner_timestamp=?',
          'scale_winner_site_id=?','scale_winner_present=1');
        args.push(plan.scaleValue?.x ?? null, plan.scaleValue?.y ?? null, timestamp, site);
      }
      if (plan.replaceStyle) {
        sets.push('style_value=?','style_winner_timestamp=?','style_winner_site_id=?',
          'style_winner_present=1'); args.push(payload.style, timestamp, site);
      }
      args.push(plan.target.timestamp, plan.target.site);
      db.prepare(`UPDATE original_ink_state SET ${sets.join(',')} WHERE note_id='n'
        AND ink_timestamp=? AND ink_site_id=?`).run(...args);
      db.prepare(`UPDATE stroke SET transform=?,revision=revision+1 WHERE ink_timestamp=? AND ink_site_id=?`)
        .run(JSON.stringify(matrix(plan.create.origin_x, plan.create.origin_y, plan.nextRotation,
          plan.nextScale.x, plan.nextScale.y)), plan.target.timestamp, plan.target.site);
    }
    if (inject) throw new Error('injected apply');
    if (plans.length) db.exec('UPDATE page_info SET content_revision=content_revision+1 WHERE id=1');
    db.exec('COMMIT'); return plans.length ? 'APPLIED' : 'STALE';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const targets = [{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }];
assert.deepEqual(decode(fixture(targets, { rotation: null, scale: { x: 2, y: 3 } })), {
  targets, rotation: { present: true, value: null },
  scale: { present: true, value: { x: 2, y: 3 } }, style: null,
});
const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 30);
assert.deepEqual({ ...db.prepare(`SELECT center_path_winner_present center,style_winner_present style
  FROM original_ink_state WHERE ink_timestamp=20`).get() }, { center: 0, style: 0 });
assert.equal(db.prepare(`SELECT style_winner_present value FROM original_ink_state
  WHERE ink_timestamp=21`).get().value, 1);
assert.equal(apply(db, 10, 1, fixture(targets, { rotation: 0.75, scale: { x: 4, y: 5 } })), 'APPLIED');
assert.equal(apply(db, 9, 9, fixture(targets, { rotation: 1 })), 'STALE');
assert.equal(apply(db, 11, 1, fixture(targets, { rotation: 1.25 })), 'APPLIED');
assert.equal(apply(db, 10, 2, fixture(targets, { scale: { x: -2, y: 0 } })), 'APPLIED');
assert.equal(apply(db, 12, 1, fixture(targets, { rotation: null })), 'APPLIED');
assert.equal(apply(db, 13, 1, fixture(targets, { scale: null })), 'APPLIED');
const cleared = db.prepare(`SELECT rotation_value,scale_x_value,rotation_winner_timestamp rotation_ts,
  scale_winner_timestamp scale_ts,create_origin_x origin FROM original_ink_state
  WHERE ink_timestamp=20`).get();
assert.deepEqual({ ...cleared }, { rotation_value: null, scale_x_value: null,
  rotation_ts: 12, scale_ts: 13, origin: 10 });
assert.equal(apply(db, 5, 1, fixture(targets, { style: 3 })), 'APPLIED');
db.exec(`UPDATE stroke SET transform='[]' WHERE ink_timestamp=21`);
const before = db.prepare(`SELECT rotation_winner_timestamp value FROM original_ink_state
  WHERE ink_timestamp=20`).get().value;
assert.equal(apply(db, 14, 1, fixture(targets, { rotation: 2 })), 'DIVERGED');
assert.equal(db.prepare(`SELECT rotation_winner_timestamp value FROM original_ink_state
  WHERE ink_timestamp=20`).get().value, before);
db.exec(`UPDATE stroke SET transform='${JSON.stringify(matrix(-4, 6, -0.5, 2, 3))}' WHERE ink_timestamp=21`);
assert.throws(() => apply(db, 15, 1, fixture(targets, { rotation: 2 }), true), /injected apply/);
assert.equal(db.prepare(`SELECT rotation_winner_timestamp value FROM original_ink_state
  WHERE ink_timestamp=20`).get().value, before);
assert.equal(db.prepare('SELECT count(*) count FROM operation_log').get().count, 0);
const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 29);

console.log('success|flatbuffer-nullable=2|v29-v30=1|absent-winner-recovered=4|' +
  'lower-first-wins=3|independent-lww=2|explicit-clear=2|create-fallback=2|' +
  'multi-ink-atomic=2|rollback=1|no-local-log=1');

function accepts(timestamp, site, present, oldTimestamp, oldSite) {
  return !present || timestamp > oldTimestamp || (timestamp === oldTimestamp && site > oldSite);
}
function matrix(x, y, rotation, scaleX, scaleY) {
  const cos = Math.cos(rotation), sin = Math.sin(rotation);
  return [cos * scaleX, -sin * scaleY, x, sin * scaleX, cos * scaleY, y, 0, 0, 1];
}
function f32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
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
