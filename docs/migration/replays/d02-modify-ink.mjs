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
  vector(values) {
    this.align(4); const vector = this.cursor; this.cursor += 5 + values.length;
    w32(this.bytes, vector, values.length); this.bytes.set(values, vector + 4); return vector;
  }
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
    this.vtableSize = u16(bytes, this.vtable); this.objectSize = u16(bytes, this.vtable + 2);
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
  vectorStart(field, size) {
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    const count = u32(this.bytes, vector); assert(vector + 4 + count * size <= this.bytes.length);
    return { vector, count };
  }
  bytesVector(field) {
    const value = this.vectorStart(field, 1); return value === null ? null :
      this.bytes.slice(value.vector + 4, value.vector + 4 + value.count);
  }
}

function modifyFixture(targets, centerPath, includeUnsupportedRotation = false) {
  const builder = new Builder(), root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 90);
  w64(builder.bytes, root + 12, 123n); w64(builder.bytes, root + 20, 124n);
  builder.bytes[root + 28] = 17;
  const fields = [4, 0, 0, includeUnsupportedRotation ? 8 : 0, 0, 0, 0, 0,
    centerPath === null ? 0 : 12,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  const modify = builder.table(fields, 16); builder.pointer(root + 32, modify);
  if (includeUnsupportedRotation) wf32(builder.bytes, modify + 8, 0.5);
  builder.pointer(modify + 4, builder.identities(targets));
  if (centerPath !== null) builder.pointer(modify + 12, builder.vector(centerPath));
  return builder.finish(root);
}

function decodeModifyFixture(bytes) {
  const root = new Table(bytes, u32(bytes, 0)); assert.equal(bytes[root.table + root.offset(4)], 17);
  const modify = root.tableField(5), identityVector = modify.vectorStart(0, 8);
  assert(identityVector !== null && identityVector.count > 0);
  const targets = [];
  for (let index = 0; index < identityVector.count; index++) {
    const offset = identityVector.vector + 4 + index * 8;
    targets.push({ timestamp: u32(bytes, offset + 4), site: u16(bytes, offset) });
  }
  let unsupported = false;
  for (let field = 1; field <= 18; field++) if (field !== 8 && modify.has(field)) unsupported = true;
  return { targets, centerPath: modify.bytesVector(8), unsupported };
}

function encodedPath(start, end) {
  const result = [1, 0, 2, 3]; f32(result, start, 0); result.push(0x3c, 0, 0x38, 0, 255, 0);
  result.push(2); f32(result, end, 0); result.push(0x3c, 0, 0x38, 0, 255, 0);
  return Uint8Array.from(result);
}

function encodedAppend(end) {
  const result = [1, 0, 1, 2]; f32(result, end, 0); result.push(0x3c, 0, 0x38, 0, 255, 0);
  return Uint8Array.from(result);
}

function decodePath(bytes, start = null) {
  assert.equal(bytes[0], 1); const count = bytes[1] * 256 + bytes[2]; let offset = 3, current = start;
  const points = [], segments = [];
  for (let index = 0; index < count; index++) {
    const type = bytes[offset++]; assert([2, 3].includes(type));
    const view = new DataView(bytes.buffer, bytes.byteOffset + offset, 8);
    const point = { x: view.getFloat32(0, true), y: view.getFloat32(4, true) }; offset += 14;
    if (type === 3) { assert(current === null && index === 0); current = point; points.push(point); }
    else { assert(current !== null); segments.push({ p0: current, p3: point }); points.push(point); current = point; }
  }
  assert.equal(offset, bytes.length); return { points, segments, end: current };
}

function rebuild(base, appends) {
  const decoded = decodePath(base), points = [...decoded.points], segments = [...decoded.segments];
  let current = decoded.end;
  appends.sort(compareIdentity);
  for (const appendRow of appends) {
    const append = decodePath(appendRow.bytes, current);
    points.push(...append.points); segments.push(...append.segments); current = append.end;
  }
  return { points, segments };
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=27;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
      page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE original_ink_state(note_id TEXT,ink_timestamp INTEGER,ink_site_id INTEGER,
      base_center_path BLOB NOT NULL,PRIMARY KEY(note_id,ink_timestamp,ink_site_id));
    CREATE TABLE original_ink_path_append(note_id TEXT,ink_timestamp INTEGER,ink_site_id INTEGER,
      append_timestamp INTEGER,append_site_id INTEGER,center_path_elements BLOB,
      PRIMARY KEY(note_id,append_timestamp,append_site_id));
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
    INSERT INTO original_element_z_index VALUES('n',20,2,10,1,2,1,'5');
    INSERT INTO original_element_z_index VALUES('n',21,3,10,1,2,1,'6');`);
  const first = encodedPath(0, 10), second = encodedPath(1, 11);
  db.prepare(`INSERT INTO original_ink_state VALUES('n',20,2,?)`).run(first);
  db.prepare(`INSERT INTO original_ink_state VALUES('n',21,3,?)`).run(second);
  db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:14:2',1,?,1,0)`)
    .run(Buffer.from(JSON.stringify(rebuild(first, []))));
  db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:15:3',1,?,1,1)`)
    .run(Buffer.from(JSON.stringify(rebuild(second, []))));
  return db;
}

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE original_ink_state ADD COLUMN center_path_winner_timestamp INTEGER NOT NULL
      DEFAULT 0 CHECK(center_path_winner_timestamp BETWEEN 0 AND 4294967295);
      ALTER TABLE original_ink_state ADD COLUMN center_path_winner_site_id INTEGER NOT NULL
      DEFAULT 0 CHECK(center_path_winner_site_id BETWEEN 0 AND 65535);
      UPDATE original_ink_state SET center_path_winner_timestamp=ink_timestamp,
        center_path_winner_site_id=ink_site_id;`);
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=28; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function apply(db, { timestamp, site, raw, archived = false, inject = false }) {
  const payload = decodeModifyFixture(raw);
  if (payload.unsupported) return 'UNSUPPORTED_FIELDS';
  if (payload.centerPath === null) return 'APPLIED';
  decodePath(payload.centerPath);
  db.exec('BEGIN IMMEDIATE');
  try {
    const table = archived ? 'original_deleted_page_element' : 'page_element_snapshot';
    const where = archived ? "note_id='n' AND page_timestamp=10 AND page_site_id=1 AND page_index=2" :
      "note_id='n' AND page_id='p'";
    const plans = [];
    for (const target of payload.targets) {
      const state = db.prepare(`SELECT base_center_path,center_path_winner_timestamp timestamp,
        center_path_winner_site_id site FROM original_ink_state WHERE note_id='n'
        AND ink_timestamp=? AND ink_site_id=?`).get(target.timestamp, target.site);
      if (state === undefined) { db.exec('ROLLBACK'); return 'MISSING_STATE'; }
      if (compareIdentity({ timestamp, site }, state) <= 0) continue;
      const id = `op:${target.timestamp.toString(16)}:${target.site.toString(16)}`;
      const row = db.prepare(`SELECT payload FROM ${table} WHERE ${where} AND element_id=?`).get(id);
      if (row === undefined) { db.exec('ROLLBACK'); return 'MISSING_STROKE'; }
      const appends = db.prepare(`SELECT append_timestamp timestamp,append_site_id site,
        center_path_elements bytes FROM original_ink_path_append WHERE note_id='n'
        AND ink_timestamp=? AND ink_site_id=?`).all(target.timestamp, target.site);
      const current = JSON.parse(Buffer.from(row.payload).toString());
      if (JSON.stringify(current) !== JSON.stringify(rebuild(state.base_center_path, appends))) {
        db.exec('ROLLBACK'); return 'DIVERGED';
      }
      plans.push({ target, state, id, next: rebuild(payload.centerPath, appends) });
    }
    for (const plan of plans) {
      db.prepare(`UPDATE original_ink_state SET base_center_path=?,center_path_winner_timestamp=?,
        center_path_winner_site_id=? WHERE note_id='n' AND ink_timestamp=? AND ink_site_id=?
        AND center_path_winner_timestamp=? AND center_path_winner_site_id=?`).run(
        payload.centerPath, timestamp, site, plan.target.timestamp, plan.target.site,
        plan.state.timestamp, plan.state.site);
      db.prepare(`UPDATE ${table} SET payload=?,revision=revision+1 WHERE ${where} AND element_id=?`)
        .run(Buffer.from(JSON.stringify(plan.next)), plan.id);
    }
    if (inject) throw new Error('injected apply');
    if (plans.length > 0 && archived) db.exec(`UPDATE original_deleted_page SET
      content_revision=content_revision+1,indexed_revision=NULL WHERE note_id='n' AND page_timestamp=10
      AND page_site_id=1 AND page_index=2; DELETE FROM original_deleted_page_search
      WHERE note_id='n' AND page_timestamp=10 AND page_site_id=1 AND page_index=2 AND type=3;`);
    else if (plans.length > 0) db.exec(`UPDATE page_info SET content_revision=content_revision+1
      WHERE note_id='n' AND page_id='p'; DELETE FROM search_page_state WHERE note_id='n' AND page_id='p';
      DELETE FROM search_item WHERE note_id='n' AND page_id='p' AND type=3;`);
    db.exec('COMMIT'); return plans.length === 0 ? 'STALE' : 'APPLIED';
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const replacement = encodedPath(5, 50), targets = [{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }];
const fixture = decodeModifyFixture(modifyFixture(targets, replacement));
assert.deepEqual(fixture.targets, targets); assert.equal(fixture.centerPath.length, replacement.length);
assert.equal(fixture.unsupported, false);
assert.equal(decodeModifyFixture(modifyFixture(targets, replacement, true)).unsupported, true);

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 28);
assert.deepEqual(db.prepare(`SELECT ink_timestamp,center_path_winner_timestamp winner
  FROM original_ink_state ORDER BY ink_timestamp`).all().map(row => ({ ...row })),
  [{ ink_timestamp: 20, winner: 20 }, { ink_timestamp: 21, winner: 21 }]);
const append = encodedAppend(30);
db.prepare(`INSERT INTO original_ink_path_append VALUES('n',20,2,40,1,?)`).run(append);
db.prepare(`UPDATE page_element_snapshot SET payload=? WHERE element_id='op:14:2'`)
  .run(Buffer.from(JSON.stringify(rebuild(encodedPath(0, 10), [{ timestamp: 40, site: 1, bytes: append }]))));
db.exec(`INSERT INTO search_page_state VALUES('n','p'); INSERT INTO search_item VALUES('n','p',3);`);

assert.equal(apply(db, { timestamp: 100, site: 1, raw: modifyFixture(targets, replacement) }), 'APPLIED');
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, 2);
assert.equal(db.prepare(`SELECT count(*) count FROM search_item`).get().count, 0);
assert.equal(db.prepare(`SELECT count(*) count FROM original_ink_path_append`).get().count, 1);
const first = JSON.parse(Buffer.from(db.prepare(`SELECT payload FROM page_element_snapshot
  WHERE element_id='op:14:2'`).get().payload));
assert.deepEqual(first.points.map(point => point.x), [5, 50, 30]);
assert.equal(first.segments[1].p0.x, 50);
assert.equal(apply(db, { timestamp: 99, site: 9, raw: modifyFixture(targets, encodedPath(9, 19)) }), 'STALE');
assert.equal(apply(db, { timestamp: 100, site: 1, raw: modifyFixture(targets, encodedPath(9, 19)) }), 'STALE');
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, 2);
assert.equal(apply(db, { timestamp: 101, site: 1,
  raw: modifyFixture(targets, replacement, true) }), 'UNSUPPORTED_FIELDS');

db.exec(`INSERT INTO original_deleted_page VALUES('n',10,1,2,'p',2,2);
  INSERT INTO original_deleted_page_element SELECT note_id,10,1,2,element_id,kind,payload,revision,
    element_order FROM page_element_snapshot; DELETE FROM page_element_snapshot; DELETE FROM page_info;
  INSERT INTO original_deleted_page_search VALUES('n',10,1,2,3);`);
assert.equal(apply(db, { timestamp: 100, site: 2,
  raw: modifyFixture([{ timestamp: 20, site: 2 }], encodedPath(7, 70)), archived: true }), 'APPLIED');
assert.equal(db.prepare(`SELECT indexed_revision FROM original_deleted_page`).get().indexed_revision, null);
assert.equal(db.prepare(`SELECT count(*) count FROM original_deleted_page_search`).get().count, 0);

const beforeWinner = db.prepare(`SELECT center_path_winner_timestamp timestamp,
  center_path_winner_site_id site FROM original_ink_state WHERE ink_timestamp=20`).get();
db.exec(`UPDATE original_deleted_page_element SET payload=x'7b7d' WHERE element_id='op:15:3'`);
assert.equal(apply(db, { timestamp: 102, site: 1,
  raw: modifyFixture(targets, encodedPath(8, 80)), archived: true }), 'DIVERGED');
assert.deepEqual(db.prepare(`SELECT center_path_winner_timestamp timestamp,
  center_path_winner_site_id site FROM original_ink_state WHERE ink_timestamp=20`).get(), beforeWinner);
db.prepare(`UPDATE original_deleted_page_element SET payload=? WHERE element_id='op:15:3'`).run(
  Buffer.from(JSON.stringify(rebuild(replacement, []))));
assert.throws(() => apply(db, { timestamp: 103, site: 1,
  raw: modifyFixture(targets, encodedPath(9, 90)), archived: true, inject: true }), /injected apply/);
assert.deepEqual(db.prepare(`SELECT center_path_winner_timestamp timestamp,
  center_path_winner_site_id site FROM original_ink_state WHERE ink_timestamp=20`).get(), beforeWinner);
assert.equal(apply(db, { timestamp: 104, site: 1,
  raw: modifyFixture([{ timestamp: 99, site: 1 }], replacement), archived: true }), 'MISSING_STATE');
assert.equal(db.prepare(`SELECT count(*) count FROM operation_log`).get().count, 0);

const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 27);
assert.equal(failed.prepare(`SELECT count(*) count FROM pragma_table_info('original_ink_state')
  WHERE name LIKE 'center_path_winner_%'`).get().count, 0);

console.log('success|flatbuffer-wd8=1|field8-center-path=1|v27-v28=1|create-winner-backfill=2|strict-lww=1|multi-ink=2|single-page-revision=1|append-preserved=1|append-reconnected=1|live-search=1|archive-apply=1|unsupported-fields-deferred=1|divergence-atomic=1|rollback=1|missing-state=1|no-local-log=1');

function compareIdentity(left, right) { return left.timestamp - right.timestamp || left.site - right.site; }
function f32(target, x, y) { target.push(...new Uint8Array(new Float32Array([x, y]).buffer)); }
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
