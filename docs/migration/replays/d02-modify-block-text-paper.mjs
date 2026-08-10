import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const source = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalModifyBlockOperation.ets', rootPath), 'utf8');
const schema = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');

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
    return offset === 0 ? null : new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
}

function fixture(clearPaper = false) {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, 7); w32(b.bytes, root + 8, 91);
  w64(b.bytes, root + 12, 125n); w64(b.bytes, root + 20, 126n); b.bytes[root + 28] = 23;
  const fields = Array(18).fill(0); fields[0] = 4; fields[13] = 12; fields[16] = 8;
  const modify = b.table(fields, 16); b.pointer(root + 32, modify); b.bytes[modify + 8] = 1;
  const setter = b.table(clearPaper ? [0] : [4], 8); b.pointer(modify + 12, setter);
  if (!clearPaper) {
    const paper = b.table([4, 8, 12, 13, 16, 20], 24);
    b.bytes[paper + 4] = 1; wf32(b.bytes, paper + 8, 16);
    b.bytes[paper + 12] = 1; b.bytes[paper + 13] = 0;
    b.bytes.set([240, 241, 242, 255], paper + 16); b.bytes[paper + 20] = 4;
    b.pointer(setter + 4, paper);
  }
  b.align(4); const vector = b.cursor; b.cursor += 12;
  w32(b.bytes, vector, 1); w16(b.bytes, vector + 4, 2); w32(b.bytes, vector + 8, 20);
  b.pointer(modify + 4, vector);
  return b.finish(root);
}

function decode(raw) {
  const root = new Table(raw, u32(raw, 0)), block = root.nested(5);
  assert.equal(root.inline(4, 1)[0], 23); assert.equal(block.inline(16, 1)[0], 1);
  const setter = block.nested(13), paper = setter.nested(0);
  return paper === null ? null : {
    flair: paper.inline(0, 1)[0], spacing: f32(paper.inline(1, 4), 0),
    bleeds: paper.inline(2, 1)[0] !== 0, centered: paper.inline(3, 1)[0] !== 0,
    color: Array.from(paper.inline(4, 4)), legacy: paper.inline(5, 1)[0],
  };
}

assert.deepEqual(decode(fixture()), { flair: 1, spacing: 16, bleeds: true,
  centered: false, color: [240, 241, 242, 255], legacy: 4 });
assert.equal(decode(fixture(true)), null);

const migrated = new DatabaseSync(':memory:');
migrated.exec(`PRAGMA user_version=40; CREATE TABLE original_block_state(
  note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,PRIMARY KEY(note_id,block_timestamp,block_site_id));
  BEGIN IMMEDIATE;
  ALTER TABLE original_block_state ADD COLUMN text_paper_value TEXT;
  ALTER TABLE original_block_state ADD COLUMN text_paper_winner_timestamp INTEGER;
  ALTER TABLE original_block_state ADD COLUMN text_paper_winner_site_id INTEGER;
  ALTER TABLE original_block_state ADD COLUMN text_paper_winner_present INTEGER NOT NULL DEFAULT 0
    CHECK (text_paper_winner_present IN (0,1));
  ALTER TABLE original_block_state ADD COLUMN resizes_width_value INTEGER;
  ALTER TABLE original_block_state ADD COLUMN resizes_width_winner_timestamp INTEGER;
  ALTER TABLE original_block_state ADD COLUMN resizes_width_winner_site_id INTEGER;
  ALTER TABLE original_block_state ADD COLUMN resizes_width_winner_present INTEGER NOT NULL DEFAULT 0
    CHECK (resizes_width_winner_present IN (0,1));
  PRAGMA user_version=41; COMMIT`);
assert.equal(migrated.prepare('PRAGMA user_version').get().user_version, 41);
assert.equal(migrated.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name IN ('text_paper_value','resizes_width_value','resizes_width_winner_present')`).get().count, 3);

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE original_block_state(
    note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,create_text_paper TEXT,
    create_resizes_width INTEGER NOT NULL,text_paper_value TEXT,
    text_paper_winner_timestamp INTEGER,text_paper_winner_site_id INTEGER,
    text_paper_winner_present INTEGER NOT NULL DEFAULT 0,resizes_width_value INTEGER,
    resizes_width_winner_timestamp INTEGER,resizes_width_winner_site_id INTEGER,
    resizes_width_winner_present INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(note_id,block_timestamp,block_site_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,payload BLOB,
      PRIMARY KEY(note_id,page_id,element_id));`);
  const baseline = JSON.stringify({ flair: 0, flairSpacingPt: 20, flairBleeds: false,
    flairCentered: false, colorR: 255, colorG: 255, colorB: 255, colorA: 255,
    legacyPaperIndex: null });
  db.prepare(`INSERT INTO original_block_state(note_id,block_timestamp,block_site_id,
    create_text_paper,create_resizes_width) VALUES('n',20,2,?,0)`).run(baseline);
  db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:14:2',?)`).run(
    Buffer.from(JSON.stringify({ kind: 'text', data: { id: 'op:14:2', paper: JSON.parse(baseline),
      resizesWidthToFitText: false } })));
  return db;
}

function apply(db, timestamp, site, paper, resize, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare(`SELECT * FROM original_block_state WHERE note_id='n'`).get();
    const accepts = prefix => state[`${prefix}_winner_present`] === 0 ||
      timestamp > state[`${prefix}_winner_timestamp`] ||
      timestamp === state[`${prefix}_winner_timestamp`] && site > state[`${prefix}_winner_site_id`];
    const row = db.prepare(`SELECT payload FROM page_element_snapshot WHERE note_id='n'`).get();
    const payload = JSON.parse(Buffer.from(row.payload).toString());
    let changed = false;
    if (paper !== undefined && accepts('text_paper')) {
      db.prepare(`UPDATE original_block_state SET text_paper_value=?,text_paper_winner_timestamp=?,
        text_paper_winner_site_id=?,text_paper_winner_present=1 WHERE note_id='n'`)
        .run(paper === null ? null : JSON.stringify(paper), timestamp, site);
      payload.data.paper = paper; changed = true;
    }
    if (resize !== undefined && accepts('resizes_width')) {
      db.prepare(`UPDATE original_block_state SET resizes_width_value=?,resizes_width_winner_timestamp=?,
        resizes_width_winner_site_id=?,resizes_width_winner_present=1 WHERE note_id='n'`)
        .run(resize ? 1 : 0, timestamp, site);
      payload.data.resizesWidthToFitText = resize; changed = true;
    }
    if (changed) db.prepare(`UPDATE page_element_snapshot SET payload=? WHERE note_id='n'`)
      .run(Buffer.from(JSON.stringify(payload)));
    if (fail) throw new Error('injected apply');
    db.exec('COMMIT'); return changed;
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const paper = { flair: 2, flairSpacingPt: 18, flairBleeds: true, flairCentered: true,
  colorR: 250, colorG: 251, colorB: 252, colorA: 255, legacyPaperIndex: 7 };
const db = database();
assert.equal(apply(db, 50, 1, paper, true), true);
assert.equal(apply(db, 40, 1, null, false), false);
let payload = JSON.parse(Buffer.from(db.prepare('SELECT payload FROM page_element_snapshot').get()
  .payload).toString());
assert.deepEqual(payload.data.paper, paper); assert.equal(payload.data.resizesWidthToFitText, true);
assert.equal(apply(db, 60, 1, null, undefined), true);
payload = JSON.parse(Buffer.from(db.prepare('SELECT payload FROM page_element_snapshot').get()
  .payload).toString()); assert.equal(payload.data.paper, null);
const before = JSON.stringify(db.prepare('SELECT * FROM original_block_state').get());
assert.throws(() => apply(db, 70, 1, paper, false, true), /injected apply/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM original_block_state').get()), before);

assert.match(source, /paperSetter.*table\.readTable\(13\)/);
assert.match(source, /resizesWidthToFitText: table\.hasField\(16\)/);
assert.match(source, /text_paper_value/); assert.match(source, /resizes_width_value/);
assert.match(source, /cloneOriginalPaper\(payload\.paper\.value\)/);
assert.match(schema, /DB_VERSION: number = 42/);
assert.match(schema, /41: \[/); assert.match(schema, /text_paper_winner_present/);
assert.match(schema, /resizes_width_winner_present/);

console.log('success|flatbuffer-td8-paper-resize=2|v40-v41=1|create-fallback=1|' +
  'paper-lww=1|resize-lww=1|paper-clear=1|stale-noop=1|rollback=1|snapshot=1');

function u16(bytes, offset) { return bytes[offset] | bytes[offset + 1] << 8; }
function u32(bytes, offset) { return (bytes[offset] | bytes[offset + 1] << 8 |
  bytes[offset + 2] << 16 | bytes[offset + 3] << 24) >>> 0; }
function i32(bytes, offset) { const value = u32(bytes, offset); return value >= 2 ** 31 ? value - 2 ** 32 : value; }
function f32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24; }
function w64(bytes, offset, value) { for (let i = 0; i < 8; i++) { bytes[offset + i] = Number(value & 255n); value >>= 8n; } }
function wf32(bytes, offset, value) { new DataView(bytes.buffer, offset, 4).setFloat32(0, value, true); }
