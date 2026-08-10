import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor() { this.bytes = new Uint8Array(512); this.cursor = 4; }
  align(value) { while ((this.cursor & (value - 1)) !== 0) this.cursor++; }
  table(offsets, size) {
    const vtable = this.cursor, vtableSize = 4 + offsets.length * 2;
    this.cursor += vtableSize; this.align(4); const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, vtableSize); w16(this.bytes, vtable + 2, size);
    offsets.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable); return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  vector(values) {
    this.align(4); const vector = this.cursor; this.cursor += 5 + values.length;
    w32(this.bytes, vector, values.length); this.bytes.set(values, vector + 4); return vector;
  }
  finish(root) { w32(this.bytes, 0, root); return this.bytes.slice(0, this.cursor); }
}

class Table {
  constructor(bytes, table) {
    this.bytes = bytes; this.table = table; this.vtable = table - i32(bytes, table);
    this.vtableSize = u16(bytes, this.vtable); this.objectSize = u16(bytes, this.vtable + 2);
  }
  offset(field) {
    const entry = this.vtable + 4 + field * 2;
    return entry + 2 <= this.vtable + this.vtableSize ? u16(this.bytes, entry) : 0;
  }
  inline(field, size) {
    const offset = this.offset(field); if (offset === 0) return null;
    assert(offset + size <= this.objectSize); return this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  tableField(field) {
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset; return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  vector(field) {
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    const count = u32(this.bytes, vector); return this.bytes.slice(vector + 4, vector + 4 + count);
  }
}

function addPathFixture(targetTimestamp, targetSite, path, estimated = null) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 90);
  w64(builder.bytes, root + 12, 123n); w64(builder.bytes, root + 20, 124n);
  builder.bytes[root + 28] = 16;
  const fields = [4, path === null ? 0 : 12, estimated === null ? 0 : 16];
  const add = builder.table(fields, 20); builder.pointer(root + 32, add);
  w16(builder.bytes, add + 4, targetSite); w32(builder.bytes, add + 8, targetTimestamp);
  if (path !== null) builder.pointer(add + 12, builder.vector(path));
  if (estimated !== null) builder.pointer(add + 16, builder.vector(estimated));
  return builder.finish(root);
}

function decodeAddPathFixture(bytes) {
  const root = new Table(bytes, u32(bytes, 0)); assert.equal(root.inline(4, 1)[0], 16);
  const add = root.tableField(5), ink = add.inline(0, 8);
  assert(ink !== null);
  const actual = add.vector(1), estimated = add.vector(2);
  assert(actual !== null || estimated !== null);
  return { ink: { timestamp: u32(ink, 4), site: u16(ink, 0) }, actual, estimated };
}

function path(elements) {
  const result = [1, elements.length >>> 8, elements.length & 255];
  for (const element of elements) {
    result.push(element.type);
    for (const point of element.points) f32(result, point.x, point.y);
    if (element.type <= 3) result.push(0x3c, 0, 0x38, 0, 255, 0);
  }
  return Uint8Array.from(result);
}

function decodePath(bytes, start = null) {
  assert(bytes.length >= 3 && bytes[0] >>> 3 === 0 && (bytes[0] & 7) === 1);
  const count = bytes[1] * 256 + bytes[2]; assert(count > 0);
  let offset = 3, current = start, attributed = true; const points = [], segments = [], hull = [];
  for (let index = 0; index < count; index++) {
    const type = bytes[offset++], pointCount = [0, 4].includes(type) ? 3 : [1, 5].includes(type) ? 2 : 1;
    assert(type >= 0 && type <= 7);
    const raw = [];
    for (let pointIndex = 0; pointIndex < pointCount; pointIndex++) {
      const view = new DataView(bytes.buffer, bytes.byteOffset + offset, 8);
      raw.push({ x: view.getFloat32(0, true), y: view.getFloat32(4, true) }); offset += 8;
    }
    const hasAttributes = type <= 3; attributed &&= hasAttributes;
    if (hasAttributes) offset += 6;
    if ([3, 7].includes(type)) {
      if (start !== null || index !== 0) throw new Error('move');
      current = raw[0]; points.push(current); hull.push(current); continue;
    }
    assert(current !== null); const end = raw.at(-1); let p1, p2;
    if ([0, 4].includes(type)) [p1, p2] = raw;
    else if ([1, 5].includes(type)) {
      const control = raw[0];
      p1 = { x: current.x + (control.x - current.x) * 2 / 3,
        y: current.y + (control.y - current.y) * 2 / 3 };
      p2 = { x: end.x + (control.x - end.x) * 2 / 3,
        y: end.y + (control.y - end.y) * 2 / 3 };
    } else {
      p1 = { x: current.x + (end.x - current.x) / 3, y: current.y + (end.y - current.y) / 3 };
      p2 = { x: current.x + (end.x - current.x) * 2 / 3,
        y: current.y + (end.y - current.y) * 2 / 3 };
    }
    segments.push({ p0: current, p1, p2, p3: end }); points.push(end); hull.push(...raw); current = end;
  }
  assert.equal(offset, bytes.length);
  const all = start === null ? hull : [start, ...hull];
  return { points, segments, end: current, attributed,
    bounds: { left: Math.min(...all.map(value => value.x)), top: Math.min(...all.map(value => value.y)),
      right: Math.max(...all.map(value => value.x)), bottom: Math.max(...all.map(value => value.y)) } };
}

function rebuild(baseBytes, appendRows, width = 2) {
  const base = decodePath(baseBytes), points = [...base.points], segments = [...base.segments];
  let bounds = base.bounds, current = base.end;
  appendRows.sort(compareAppend);
  for (const row of appendRows) {
    const append = decodePath(row.bytes, current); points.push(...append.points); segments.push(...append.segments);
    bounds = union(bounds, append.bounds); current = append.end;
  }
  const padding = width * 2;
  return { points, segments, bounds: { left: bounds.left - padding, top: bounds.top - padding,
    right: bounds.right + padding, bottom: bounds.bottom + padding } };
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=26;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
      page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id),
      FOREIGN KEY(note_id,page_timestamp,page_site_id,page_index) REFERENCES
        original_page_identity(note_id,seq_timestamp,seq_site_id,seq_index) ON DELETE CASCADE);
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,
      payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,page_id TEXT,content_revision INTEGER,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE search_page_state(note_id TEXT,page_id TEXT);
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,type INTEGER);
    CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,type INTEGER);
    CREATE TABLE operation_log(id INTEGER PRIMARY KEY);
    INSERT INTO note_meta VALUES('n');
    INSERT INTO original_page_identity VALUES('n',10,1,2,'p',1);
    INSERT INTO page_info VALUES('n','p',1);
    INSERT INTO original_element_z_index VALUES('n',20,2,10,1,2,1,'5');`);
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`CREATE TABLE original_ink_state(
      note_id TEXT NOT NULL,ink_timestamp INTEGER NOT NULL,ink_site_id INTEGER NOT NULL,
      base_center_path BLOB NOT NULL CHECK(length(base_center_path) BETWEEN 3 AND 16777216),
      PRIMARY KEY(note_id,ink_timestamp,ink_site_id),FOREIGN KEY(note_id,ink_timestamp,ink_site_id)
      REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id) ON DELETE CASCADE);
      CREATE TABLE original_ink_path_append(
      note_id TEXT NOT NULL,ink_timestamp INTEGER NOT NULL,ink_site_id INTEGER NOT NULL,
      append_timestamp INTEGER NOT NULL,append_site_id INTEGER NOT NULL,
      center_path_elements BLOB NOT NULL CHECK(length(center_path_elements) BETWEEN 3 AND 16777216),
      PRIMARY KEY(note_id,append_timestamp,append_site_id),FOREIGN KEY(note_id,ink_timestamp,ink_site_id)
      REFERENCES original_ink_state(note_id,ink_timestamp,ink_site_id) ON DELETE CASCADE);
      CREATE INDEX idx_original_ink_append_target ON original_ink_path_append(
        note_id,ink_timestamp,ink_site_id,append_timestamp,append_site_id);`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=27; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function apply(db, { timestamp, site, raw, archived = false, inject = false }) {
  const decoded = decodeAddPathFixture(raw);
  try { decodePath(decoded.actual, { x: 0, y: 0 }); } catch (error) {
    return error.message === 'move' ? 'MULTI_COMPONENT' : 'MALFORMED';
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare(`SELECT base_center_path FROM original_ink_state
      WHERE note_id='n' AND ink_timestamp=? AND ink_site_id=?`).get(decoded.ink.timestamp, decoded.ink.site);
    if (state === undefined) { db.exec('ROLLBACK'); return 'MISSING_STATE'; }
    const table = archived ? 'original_deleted_page_element' : 'page_element_snapshot';
    const where = archived ? "note_id='n' AND page_timestamp=10 AND page_site_id=1 AND page_index=2" :
      "note_id='n' AND page_id='p'";
    const row = db.prepare(`SELECT payload FROM ${table} WHERE ${where} AND element_id='op:14:2'`).get();
    if (row === undefined) { db.exec('ROLLBACK'); return 'MISSING_STROKE'; }
    const existing = db.prepare(`SELECT append_timestamp timestamp,append_site_id site,
      center_path_elements bytes FROM original_ink_path_append WHERE note_id='n'
      AND ink_timestamp=20 AND ink_site_id=2`).all();
    const current = JSON.parse(Buffer.from(row.payload).toString());
    if (JSON.stringify(current) !== JSON.stringify(rebuild(state.base_center_path, existing))) {
      db.exec('ROLLBACK'); return 'DIVERGED';
    }
    const all = [...existing, { timestamp, site, bytes: decoded.actual }];
    const next = rebuild(state.base_center_path, all);
    db.prepare(`INSERT INTO original_ink_path_append VALUES('n',20,2,?,?,?)`)
      .run(timestamp, site, decoded.actual);
    db.prepare(`UPDATE ${table} SET payload=?,revision=revision+1 WHERE ${where}
      AND element_id='op:14:2'`).run(Buffer.from(JSON.stringify(next)));
    if (inject) throw new Error('injected apply');
    if (archived) db.exec(`UPDATE original_deleted_page SET content_revision=content_revision+1,
      indexed_revision=NULL WHERE note_id='n' AND page_timestamp=10 AND page_site_id=1 AND page_index=2;
      DELETE FROM original_deleted_page_search WHERE note_id='n' AND page_timestamp=10
        AND page_site_id=1 AND page_index=2 AND type=3;`);
    else db.exec(`UPDATE page_info SET content_revision=content_revision+1 WHERE note_id='n' AND page_id='p';
      DELETE FROM search_page_state WHERE note_id='n' AND page_id='p';
      DELETE FROM search_item WHERE note_id='n' AND page_id='p' AND type=3;`);
    db.exec('COMMIT'); return 'APPLIED';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const base = path([{ type: 3, points: [{ x: 0, y: 0 }] },
  { type: 2, points: [{ x: 10, y: 0 }] }]);
const later = path([{ type: 2, points: [{ x: 30, y: 0 }] }]);
const earlier = path([{ type: 1, points: [{ x: 100, y: 100 }, { x: 20, y: 0 }] }]);
const decoded = decodeAddPathFixture(addPathFixture(20, 2, earlier));
assert.deepEqual(decoded.ink, { timestamp: 20, site: 2 });
assert.equal(decodePath(decoded.actual, { x: 10, y: 0 }).bounds.right, 100);

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 27);
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_state`).get().count, 0);
const initial = rebuild(base, []);
db.prepare(`INSERT INTO original_ink_state VALUES('n',20,2,?)`).run(base);
db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:14:2',1,?,1,0)`)
  .run(Buffer.from(JSON.stringify(initial)));
db.exec(`INSERT INTO search_page_state VALUES('n','p'); INSERT INTO search_item VALUES('n','p',3);`);

assert.equal(apply(db, { timestamp: 40, site: 2, raw: addPathFixture(20, 2, later) }), 'APPLIED');
assert.equal(apply(db, { timestamp: 30, site: 3, raw: addPathFixture(20, 2, earlier) }), 'APPLIED');
const ordered = db.prepare(`SELECT append_timestamp FROM original_ink_path_append
  ORDER BY append_timestamp,append_site_id`).all().map(row => row.append_timestamp);
assert.deepEqual(ordered, [30, 40]);
const live = JSON.parse(Buffer.from(db.prepare(`SELECT payload FROM page_element_snapshot`).get().payload));
assert.deepEqual(live.points.map(point => point.x), [0, 10, 20, 30]);
assert.equal(live.segments[2].p0.x, 20);
assert.deepEqual(live.bounds, { left: -4, top: -4, right: 104, bottom: 104 });
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, 3);
assert.equal(db.prepare(`SELECT count(*) count FROM search_item`).get().count, 0);
assert.equal(db.prepare(`SELECT count(*) count FROM operation_log`).get().count, 0);

db.exec(`INSERT INTO original_deleted_page VALUES('n',10,1,2,'p',3,3);
  INSERT INTO original_deleted_page_element SELECT note_id,10,1,2,element_id,kind,payload,revision,
    element_order FROM page_element_snapshot; DELETE FROM page_element_snapshot; DELETE FROM page_info;
  INSERT INTO original_deleted_page_search VALUES('n',10,1,2,3);`);
const tail = path([{ type: 2, points: [{ x: 40, y: 0 }] }]);
assert.equal(apply(db, { timestamp: 50, site: 1, raw: addPathFixture(20, 2, tail), archived: true }), 'APPLIED');
assert.equal(db.prepare(`SELECT indexed_revision FROM original_deleted_page`).get().indexed_revision, null);
assert.equal(db.prepare(`SELECT count(*) count FROM original_deleted_page_search`).get().count, 0);

const before = db.prepare(`SELECT count(*) count FROM original_ink_path_append`).get().count;
const estimatedFixture = decodeAddPathFixture(addPathFixture(20, 2, null, tail));
assert.equal(estimatedFixture.actual, null);
assert.deepEqual(estimatedFixture.estimated, tail);
const move = path([{ type: 3, points: [{ x: 1, y: 1 }] }]);
assert.equal(apply(db, { timestamp: 61, site: 1,
  raw: addPathFixture(20, 2, move), archived: true }), 'MULTI_COMPONENT');
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_path_append`).get().count, before);

db.exec(`UPDATE original_deleted_page_element SET payload=x'7b7d'`);
assert.equal(apply(db, { timestamp: 62, site: 1,
  raw: addPathFixture(20, 2, tail), archived: true }), 'DIVERGED');
db.prepare(`UPDATE original_deleted_page_element SET payload=?`).run(Buffer.from(JSON.stringify(
  rebuild(base, db.prepare(`SELECT append_timestamp timestamp,append_site_id site,
    center_path_elements bytes FROM original_ink_path_append`).all()))));
assert.throws(() => apply(db, { timestamp: 63, site: 1,
  raw: addPathFixture(20, 2, tail), archived: true, inject: true }), /injected apply/);
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_path_append`).get().count, before);
assert.equal(apply(db, { timestamp: 64, site: 1,
  raw: addPathFixture(99, 1, tail), archived: true }), 'MISSING_STATE');

const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 26);
assert.equal(failed.prepare(`SELECT count(*) count FROM sqlite_master
  WHERE name IN ('original_ink_state','original_ink_path_append')`).get().count, 0);

db.exec(`DELETE FROM original_element_z_index WHERE note_id='n' AND element_timestamp=20 AND element_site_id=2`);
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_state`).get().count, 0);
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_path_append`).get().count, 0);

console.log('success|flatbuffer-gd=1|raw-quadratic-hull=1|v26-v27=1|base-state=1|ordered-rebuild=1|out-of-order-reconnect=1|live-search=1|archive-apply=1|estimated-fixture=1|multi-component-deferred=1|divergence-gate=1|rollback=1|missing-state=1|no-local-log=1|cascade=1');

function compareAppend(left, right) { return left.timestamp - right.timestamp || left.site - right.site; }
function union(left, right) { return { left: Math.min(left.left, right.left), top: Math.min(left.top, right.top),
  right: Math.max(left.right, right.right), bottom: Math.max(left.bottom, right.bottom) }; }
function f32(target, x, y) {
  const bytes = new Uint8Array(new Float32Array([x, y]).buffer); target.push(...bytes);
}
function u16(bytes, offset) { return bytes[offset] + bytes[offset + 1] * 256; }
function u32(bytes, offset) { return bytes[offset] + bytes[offset + 1] * 256 +
  bytes[offset + 2] * 65536 + bytes[offset + 3] * 16777216; }
function i32(bytes, offset) { const value = u32(bytes, offset); return value >= 2147483648 ? value - 4294967296 : value; }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24; }
function w64(bytes, offset, value) { for (let index = 0; index < 8; index++) {
  bytes[offset + index] = Number(value & 255n); value >>= 8n; } }
