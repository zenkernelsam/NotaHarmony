import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor() { this.bytes = new Uint8Array(512); this.cursor = 4; }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    const vtable = this.cursor; this.cursor += 4 + fields.length * 2; this.align(4);
    const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2); w16(this.bytes, vtable + 2, size);
    fields.forEach((field, index) => w16(this.bytes, vtable + 4 + index * 2, field));
    w32(this.bytes, table, table - vtable); return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
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
  inline(field, size) {
    const offset = this.offset(field); return offset === 0 ? null :
      this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  nested(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
}

function createBlockFixture(type = 0, includeMargins = true) {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, 7); w32(b.bytes, root + 8, 90);
  w64(b.bytes, root + 12, 123n); w64(b.bytes, root + 20, 124n); b.bytes[root + 28] = 22;
  const fields = [4, 5, 8, 20, 28, 32, 40, 48, 49, 56,
    0, 0, 0, 0, 0, 84, 0, 0, 81, includeMargins ? 64 : 0, 80];
  const block = b.table(fields, 88); b.pointer(root + 32, block);
  b.bytes[block + 4] = type; b.bytes[block + 5] = 1;
  w16(b.bytes, block + 8, 2); w32(b.bytes, block + 12, 10); w32(b.bytes, block + 16, 3);
  wf32(b.bytes, block + 20, 12); wf32(b.bytes, block + 24, 34);
  wf32(b.bytes, block + 28, Math.PI / 2); wf32(b.bytes, block + 32, 2);
  wf32(b.bytes, block + 36, 3); wf32(b.bytes, block + 40, 200);
  wf32(b.bytes, block + 44, 40); b.bytes[block + 48] = 1;
  w64(b.bytes, block + 56, 18446744073709551615n);
  wf32(b.bytes, block + 64, 3); wf32(b.bytes, block + 68, 10);
  wf32(b.bytes, block + 72, 5); wf32(b.bytes, block + 76, 5);
  b.bytes[block + 80] = 1; b.bytes[block + 81] = 1;
  const paper = b.table([4, 8, 12, 13, 16, 20], 24);
  b.bytes[paper + 4] = 2; wf32(b.bytes, paper + 8, 18);
  b.bytes[paper + 12] = 1; b.bytes[paper + 13] = 1;
  b.bytes.set([250, 251, 252, 255], paper + 16); b.bytes[paper + 20] = 7;
  b.pointer(block + 84, paper);
  return b.finish(root);
}

function decodeFixture(raw) {
  const root = new Table(raw, u32(raw, 0)); assert.equal(root.inline(4, 1)[0], 22);
  const block = root.nested(5), page = block.inline(2, 12), origin = block.inline(3, 8);
  const scale = block.inline(5, 8), size = block.inline(6, 8), marginBytes = block.inline(19, 16);
  const margins = marginBytes === null ? [3, 10, 5, 5] :
    [f32(marginBytes, 0), f32(marginBytes, 4), f32(marginBytes, 8), f32(marginBytes, 12)];
  const paper = block.nested(15);
  return {
    type: block.inline(0, 1)[0], corner: block.inline(1, 1)[0],
    page: { site: u16(page, 0), timestamp: u32(page, 4), index: u32(page, 8) },
    origin: [f32(origin, 0), f32(origin, 4)], rotation: f32(block.inline(4, 4), 0),
    scale: [f32(scale, 0), f32(scale, 4)], size: [f32(size, 0), f32(size, 4)],
    textWrap: block.inline(7, 1)[0], zIndex: u64(block.inline(9, 8), 0).toString(),
    paper: { flair: paper.inline(0, 1)[0], spacing: f32(paper.inline(1, 4), 0),
      bleeds: paper.inline(2, 1)[0] !== 0, centered: paper.inline(3, 1)[0] !== 0,
      color: Array.from(paper.inline(4, 4)), legacy: paper.inline(5, 1)[0] },
    resize: block.inline(18, 1)[0] !== 0,
    margins, positionLocked: block.inline(20, 1)[0] !== 0,
  };
}

const decoded = decodeFixture(createBlockFixture());
assert.deepEqual(decoded.page, { site: 2, timestamp: 10, index: 3 });
assert.deepEqual(decoded.origin, [12, 34]); assert.deepEqual(decoded.scale, [2, 3]);
assert.deepEqual(decoded.size, [200, 40]); assert.deepEqual(decoded.margins, [3, 10, 5, 5]);
assert.equal(decoded.type, 0); assert.equal(decoded.corner, 1); assert.equal(decoded.textWrap, 1);
assert.equal(decoded.zIndex, '18446744073709551615');
assert.equal(decoded.positionLocked, true);
assert.deepEqual(decoded.paper, { flair: 2, spacing: 18, bleeds: true, centered: true,
  color: [250, 251, 252, 255], legacy: 7 });
assert.equal(decoded.resize, true);
assert(Math.abs(decoded.rotation - Math.PI / 2) < 1e-7);
assert.deepEqual(decodeFixture(createBlockFixture(0, false)).margins, [3, 10, 5, 5]);

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=34;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
      page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,
      payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE search_page_state(note_id TEXT,page_id TEXT,indexed_revision INTEGER);
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,type INTEGER,sub_id TEXT);
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,page_id TEXT,content_revision INTEGER,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,type INTEGER,sub_id TEXT);
    INSERT INTO note_meta VALUES('n');
    INSERT INTO original_page_identity VALUES('n',10,2,3,'p',1);`);
  return db;
}

const blockDdl = `CREATE TABLE original_block_state(
  note_id TEXT NOT NULL,block_timestamp INTEGER NOT NULL,block_site_id INTEGER NOT NULL,
  block_type INTEGER NOT NULL CHECK(block_type BETWEEN 0 AND 2),
  create_page_timestamp INTEGER NOT NULL,create_page_site_id INTEGER NOT NULL,create_page_index INTEGER NOT NULL,
  create_origin_x REAL NOT NULL,create_origin_y REAL NOT NULL,create_rotation REAL,
  create_scale_x REAL,create_scale_y REAL,create_width REAL NOT NULL,create_height REAL NOT NULL,
  create_corner INTEGER NOT NULL,create_text_wrap INTEGER NOT NULL,create_enable_caption INTEGER NOT NULL,
  create_position_locked INTEGER NOT NULL,create_resizes_width INTEGER NOT NULL,
  create_margin_top REAL NOT NULL,create_margin_bottom REAL NOT NULL,
  create_margin_left REAL NOT NULL,create_margin_right REAL NOT NULL,create_z_index TEXT NOT NULL,
  PRIMARY KEY(note_id,block_timestamp,block_site_id),
  FOREIGN KEY(note_id,block_timestamp,block_site_id) REFERENCES
    original_element_z_index(note_id,element_timestamp,element_site_id) ON DELETE CASCADE)`;

function migrate(db, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(blockDdl); if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=35; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function apply(db, { timestamp, site, zIndex, archived = false, fail = false,
  positionLocked = true }) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const table = archived ? 'original_deleted_page_element' : 'page_element_snapshot';
    const where = archived ? "note_id='n' AND page_timestamp=10 AND page_site_id=2 AND page_index=3" :
      "note_id='n' AND page_id='p'";
    const existing = db.prepare(`SELECT element_id,kind FROM ${table} WHERE ${where}`).all();
    const tracked = db.prepare(`SELECT element_timestamp,element_site_id,kind,z_index
      FROM original_element_z_index WHERE note_id='n' AND page_timestamp=10
      AND page_site_id=2 AND page_index=3`).all();
    const keys = new Set(tracked.map(row => `${row.kind}:op:${row.element_timestamp.toString(16)}:${row.element_site_id.toString(16)}`));
    if (!existing.every(row => keys.has(`${row.kind}:${row.element_id}`)) || existing.length !== tracked.length) {
      throw new Error('diverged');
    }
    db.prepare(`INSERT INTO original_element_z_index VALUES('n',?,?,10,2,3,2,?)`)
      .run(timestamp, site, zIndex);
    db.prepare(`INSERT INTO original_block_state VALUES(
      'n',?,?,0,10,2,3,12,34,1.5707963267948966,2,3,200,40,1,1,0,?,0,3,10,5,5,?)`)
      .run(timestamp, site, positionLocked ? 1 : 0, zIndex);
    tracked.push({ element_timestamp: timestamp, element_site_id: site, kind: 2, z_index: zIndex });
    tracked.sort(compareRows);
    const id = `op:${timestamp.toString(16)}:${site.toString(16)}`;
    const order = tracked.findIndex(row => row.element_timestamp === timestamp && row.element_site_id === site);
    const payload = Buffer.from(JSON.stringify({ kind: 'text', data: { id, richText: '',
      blockWidth: 200, blockHeight: 40, contentLeftInset: 5, contentTopInset: 3,
      positionLocked } }));
    if (archived) {
      db.prepare(`INSERT INTO original_deleted_page_element VALUES('n',10,2,3,?,2,?,1,?)`)
        .run(id, payload, order);
    } else {
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p',?,2,?,1,?)`).run(id, payload, order);
    }
    for (let index = 0; index < tracked.length; index++) {
      const row = tracked[index], elementId = `op:${row.element_timestamp.toString(16)}:${row.element_site_id.toString(16)}`;
      db.prepare(`UPDATE ${table} SET element_order=? WHERE ${where} AND element_id=? AND kind=?`)
        .run(index, elementId, row.kind);
    }
    if (fail) throw new Error('injected apply');
    if (archived) {
      db.exec(`UPDATE original_deleted_page SET content_revision=content_revision+1,indexed_revision=NULL
        WHERE note_id='n' AND page_timestamp=10 AND page_site_id=2 AND page_index=3;
        DELETE FROM original_deleted_page_search WHERE note_id='n' AND page_timestamp=10
          AND page_site_id=2 AND page_index=3 AND type=2;`);
    } else {
      db.exec(`UPDATE page_info SET content_revision=content_revision+1 WHERE note_id='n' AND page_id='p';
        DELETE FROM search_page_state WHERE note_id='n' AND page_id='p';
        DELETE FROM search_item WHERE note_id='n' AND page_id='p' AND type=2;`);
    }
    db.exec('COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function compareRows(left, right) {
  if (left.z_index.length !== right.z_index.length) return left.z_index.length - right.z_index.length;
  if (left.z_index !== right.z_index) return left.z_index < right.z_index ? -1 : 1;
  return left.element_timestamp - right.element_timestamp || left.element_site_id - right.element_site_id;
}

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 35);
db.exec(`INSERT INTO page_info VALUES('n','p',0); INSERT INTO search_page_state VALUES('n','p',0);
  INSERT INTO search_item VALUES('n','p',2,'old');`);
apply(db, { timestamp: 20, site: 2, zIndex: '18446744073709551615' });
apply(db, { timestamp: 21, site: 1, zIndex: '9' });
assert.deepEqual(db.prepare('SELECT element_id FROM page_element_snapshot ORDER BY element_order').all()
  .map(row => row.element_id), ['op:15:1', 'op:14:2']);
assert.equal(db.prepare('SELECT count(*) count FROM search_item').get().count, 0);
const text = JSON.parse(Buffer.from(db.prepare(
  "SELECT payload FROM page_element_snapshot WHERE element_id='op:14:2'").get().payload).toString());
assert.equal(text.kind, 'text'); assert.equal(text.data.richText, '');
assert.equal(text.data.contentLeftInset, 5); assert.equal(text.data.contentTopInset, 3);
assert.equal(text.data.positionLocked, true);

db.exec(`INSERT INTO original_deleted_page VALUES('n',10,2,3,'p',2,2);
  INSERT INTO original_deleted_page_element SELECT note_id,10,2,3,element_id,kind,payload,revision,
    element_order FROM page_element_snapshot; DELETE FROM page_element_snapshot; DELETE FROM page_info;
  INSERT INTO original_deleted_page_search VALUES('n',10,2,3,2,'old');`);
apply(db, { timestamp: 22, site: 1, zIndex: '10', archived: true });
assert.equal(db.prepare('SELECT indexed_revision FROM original_deleted_page').get().indexed_revision, null);
const before = db.prepare('SELECT count(*) count FROM original_block_state').get().count;
assert.throws(() => apply(db, { timestamp: 23, site: 1, zIndex: '11', archived: true, fail: true }),
  /injected apply/);
assert.equal(db.prepare('SELECT count(*) count FROM original_block_state').get().count, before);

const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 34);
assert.equal(failed.prepare("SELECT count(*) count FROM sqlite_master WHERE name='original_block_state'")
  .get().count, 0);

const v40 = database(); migrate(v40); v40.exec('PRAGMA user_version=39');
v40.exec('BEGIN IMMEDIATE; ALTER TABLE original_block_state ADD COLUMN create_text_paper TEXT;' +
  'PRAGMA user_version=40; COMMIT');
assert.equal(v40.prepare('PRAGMA user_version').get().user_version, 40);
assert.equal(v40.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name='create_text_paper'`).get().count, 1);

const source = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalCreateBlockOperation.ets', import.meta.url), 'utf8');
const dispatcher = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalPageOperationApplier.ets', import.meta.url), 'utf8');
const schema = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/DatabaseHelper.ets', import.meta.url), 'utf8');
assert.match(source, /ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE: number = 22/);
assert.match(source, /marginBytes === null \? \{[\s\S]*top: 3, bottom: 10, left: 5, right: 5/);
assert.doesNotMatch(source, /CREATE_BLOCK_IMAGE_UNSUPPORTED/);
assert.match(source, /CREATE_BLOCK_MATH_FIELDS_MISSING/);
assert.doesNotMatch(source, /CREATE_BLOCK_POSITION_LOCK_UNSUPPORTED/);
assert.match(source, /positionLocked: payload\.positionLocked/);
assert.match(source, /paper: cloneOriginalPaper\(payload\.paper\)/);
assert.match(source, /resizesWidthToFitText: payload\.resizesWidthToFitText/);
assert.doesNotMatch(source, /CREATE_BLOCK_TEXT_PAPER_UNSUPPORTED/);
assert.doesNotMatch(source, /CREATE_BLOCK_RESIZE_TO_FIT_UNSUPPORTED/);
assert.match(source, /PageElementKind\.IMAGE[\s\S]*PageElementKind\.TEXT/);
assert.match(dispatcher, /OriginalCreateBlockOperationApplier/);
assert.match(schema, /DB_VERSION: number = 48/);
assert.match(schema, /DDL_ORIGINAL_BLOCK_STATE/);
assert.match(schema, /40: \['ALTER TABLE original_block_state ADD COLUMN create_text_paper TEXT'\]/);

console.log('success|flatbuffer-rl2=1|text-create=1|empty-richtext=1|transform=1|' +
  'margins=3,10,5,5|uint64-z=1|v34-v35=1|live-order=1|archive-apply=1|' +
  'search-invalidated=1|position-lock=1|text-paper=1|resize-to-fit=1|v39-v40=1|' +
  'rollback=2|image-create-dispatched=1|math-type-gate-upgraded=1');

function u16(bytes, offset) { return bytes[offset] | bytes[offset + 1] << 8; }
function u32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}
function i32(bytes, offset) { const value = u32(bytes, offset); return value >= 2 ** 31 ? value - 2 ** 32 : value; }
function u64(bytes, offset) { let value = 0n; for (let i = 7; i >= 0; i--) value = value * 256n + BigInt(bytes[offset + i]); return value; }
function f32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) {
  bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24;
}
function w64(bytes, offset, value) { for (let i = 0; i < 8; i++) { bytes[offset + i] = Number(value & 255n); value >>= 8n; } }
function wf32(bytes, offset, value) { new DataView(bytes.buffer, offset, 4).setFloat32(0, value, true); }
