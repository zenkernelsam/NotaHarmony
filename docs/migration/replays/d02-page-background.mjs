import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

class Builder {
  constructor(size = 4096) { this.bytes = new Uint8Array(size); this.cursor = 4; }
  align(value) { while ((this.cursor & (value - 1)) !== 0) this.cursor++; }
  table(offsets, objectSize) {
    const vtable = this.cursor, vtableSize = 4 + offsets.length * 2;
    this.cursor += vtableSize; this.align(4);
    const table = this.cursor; this.cursor += objectSize;
    w16(this.bytes, vtable, vtableSize); w16(this.bytes, vtable + 2, objectSize);
    offsets.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable);
    return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  finish(root) { w32(this.bytes, 0, root); return this.bytes.slice(0, this.cursor); }
}

class Table {
  constructor(bytes, table) {
    this.bytes = bytes; this.table = table;
    const distance = i32(bytes, table); assert(distance > 0 && distance <= table);
    this.vtable = table - distance; this.vtableSize = u16(bytes, this.vtable);
    this.objectSize = u16(bytes, this.vtable + 2);
  }
  offset(field) {
    const entry = this.vtable + 4 + field * 2;
    return entry + 2 <= this.vtable + this.vtableSize ? u16(this.bytes, entry) : 0;
  }
  inline(field, size) {
    const offset = this.offset(field); if (offset === 0) return null;
    assert(offset >= 4 && offset + size <= this.objectSize);
    return this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  tableField(field) {
    const offset = this.offset(field); if (offset === 0) return null;
    const slot = this.table + offset; return new Table(this.bytes, slot + u32(this.bytes, slot));
  }
  byte(field, fallback = 0) { return this.inline(field, 1)?.[0] ?? fallback; }
  uint(field, fallback = 0) { const bytes = this.inline(field, 4); return bytes === null ? fallback : u32(bytes, 0); }
  float(field, fallback = 0) { const bytes = this.inline(field, 4); return bytes === null ? fallback : f32(bytes, 0); }
}

function buildCreatePage() {
  const builder = new Builder();
  const root = builder.table([4,12,20,0,28,32], 36);
  w16(builder.bytes, root + 4, 9); w32(builder.bytes, root + 8, 77);
  w64(builder.bytes, root + 12, 100n); w64(builder.bytes, root + 20, 200n);
  builder.bytes[root + 28] = 3;
  const create = builder.table([0,4,8,0], 12); builder.pointer(root + 32, create);
  w32(builder.bytes, create + 8, 2);
  const background = builder.table([4,0,8,12,20], 36); builder.pointer(create + 4, background);
  wF32(builder.bytes, background + 8, Math.PI / 2);
  wF32(builder.bytes, background + 12, 612); wF32(builder.bytes, background + 16, 792);
  [18,20,22,24].forEach((value, index) => wF32(builder.bytes, background + 20 + index * 4, value));
  const paper = builder.table([4,8,12,13,16,20], 24); builder.pointer(background + 4, paper);
  builder.bytes[paper + 4] = 2; wF32(builder.bytes, paper + 8, 18);
  builder.bytes[paper + 12] = 1; builder.bytes[paper + 13] = 1;
  builder.bytes.set([244,245,246,255], paper + 16); builder.bytes[paper + 20] = 7;
  return builder.finish(root);
}

function decodeCreatePage(bytes) {
  const root = new Table(bytes, u32(bytes, 0));
  assert.equal(root.byte(4), 3);
  const create = root.tableField(5); assert(create !== null);
  const value = create.tableField(1); assert(value !== null);
  assert.equal(value.tableField(1), null, 'PDF-backed backgrounds must stay distinguishable');
  const paper = value.tableField(0); assert(paper !== null);
  const color = paper.inline(4, 4); assert(color !== null && color[3] === 255);
  const rotation = cardinal(value.float(2));
  const size = floats(value.inline(3, 8));
  const margins = floats(value.inline(4, 16));
  assert(margins.every(number => Number.isFinite(number) && number >= 0));
  assert(margins[2] + margins[3] <= size[0] && margins[0] + margins[1] <= size[1]);
  const flair = paper.byte(0), spacing = paper.float(1);
  const template = flair === 2 ? 2 : flair === 1 ? 3 : paper.offset(1) === 0 ? 0 : 1;
  const swap = rotation === Math.PI / 2 || rotation === Math.PI * 3 / 2;
  return {
    pageCount: create.uint(2, 1), template,
    widthMm: (swap ? size[1] : size[0]) / 72 * 25.4,
    heightMm: (swap ? size[0] : size[1]) / 72 * 25.4,
    background: {
      schemaVersion: 1,
      paper: { flair, flairSpacingPt: spacing, flairBleeds: paper.byte(2) !== 0,
        flairCentered: paper.byte(3) !== 0, colorR: color[0], colorG: color[1],
        colorB: color[2], colorA: color[3], legacyPaperIndex: paper.byte(5) },
      rotationRadians: rotation, sourceWidthPt: size[0], sourceHeightPt: size[1],
      margins: { topPt:margins[0], bottomPt:margins[1], leftPt:margins[2], rightPt:margins[3] },
    },
  };
}

function cardinal(value) {
  for (const expected of [0,Math.PI/2,Math.PI,Math.PI*3/2])
    if (Math.abs(value - expected) < 1e-4) return expected;
  throw new Error('non-cardinal rotation');
}

function migrate(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec('ALTER TABLE page_info ADD COLUMN background_json TEXT');
    db.exec('ALTER TABLE page_delete_checkpoint ADD COLUMN background_json TEXT');
    db.exec('ALTER TABLE original_deleted_page ADD COLUMN background_json TEXT');
    db.exec(`CREATE TABLE original_page_background_winner (
      note_id TEXT NOT NULL,page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,
      page_index INTEGER NOT NULL,winner_timestamp INTEGER NOT NULL,winner_site_id INTEGER NOT NULL,
      size INTEGER NOT NULL,template INTEGER NOT NULL,orientation INTEGER NOT NULL,
      width_mm REAL NOT NULL CHECK(width_mm>0),height_mm REAL NOT NULL CHECK(height_mm>0),
      background_json TEXT NOT NULL CHECK(length(background_json)>0),
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index),
      FOREIGN KEY(note_id,page_timestamp,page_site_id,page_index) REFERENCES
        original_page_identity(note_id,seq_timestamp,seq_site_id,seq_index) ON DELETE CASCADE)`);
    if (fail) throw new Error('injected');
    db.exec('PRAGMA user_version=25; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=24;
    PRAGMA foreign_keys=ON;
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE page_info(page_id TEXT PRIMARY KEY,note_id TEXT,page_index INTEGER,size INTEGER,
      template INTEGER,orientation INTEGER,width_mm REAL,height_mm REAL,content_revision INTEGER);
    CREATE TABLE page_delete_checkpoint(note_id TEXT,action_id TEXT,page_id TEXT,page_index INTEGER,
      size INTEGER,template INTEGER,orientation INTEGER,width_mm REAL,height_mm REAL,
      content_revision INTEGER,indexed_revision INTEGER,created_time INTEGER);
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,page_id TEXT,size INTEGER,template INTEGER,orientation INTEGER,
      width_mm REAL,height_mm REAL,content_revision INTEGER,indexed_revision INTEGER);`);
  return db;
}

function compareOperation(leftTimestamp, leftSite, rightTimestamp, rightSite) {
  return leftTimestamp === rightTimestamp ? Math.sign(leftSite - rightSite) :
    Math.sign(leftTimestamp - rightTimestamp);
}

function applyBackground(db, timestamp, siteId, backgroundJson) {
  const winner = db.prepare(`SELECT winner_timestamp,winner_site_id
    FROM original_page_background_winner WHERE note_id='n' AND page_timestamp=77
      AND page_site_id=9 AND page_index=0`).get();
  if (winner !== undefined && compareOperation(timestamp, siteId,
    winner.winner_timestamp, winner.winner_site_id) <= 0) return false;
  if (winner === undefined) {
    db.prepare(`INSERT INTO original_page_background_winner VALUES
      ('n',77,9,0,?,?,5,2,1,279.4,215.9,?)`).run(timestamp,siteId,backgroundJson);
  } else {
    db.prepare(`UPDATE original_page_background_winner SET winner_timestamp=?,winner_site_id=?,
      background_json=? WHERE note_id='n' AND page_timestamp=77 AND page_site_id=9 AND page_index=0
      AND winner_timestamp=? AND winner_site_id=?`).run(timestamp,siteId,backgroundJson,
        winner.winner_timestamp,winner.winner_site_id);
  }
  const live = db.prepare(`UPDATE page_info SET background_json=? WHERE note_id='n' AND page_id='paper'`)
    .run(backgroundJson).changes;
  if (live === 0) db.prepare(`UPDATE original_deleted_page SET background_json=? WHERE note_id='n'
    AND page_timestamp=77 AND page_site_id=9 AND page_index=0`).run(backgroundJson);
  return true;
}

const decoded = decodeCreatePage(buildCreatePage());
assert.equal(decoded.pageCount, 2); assert.equal(decoded.template, 2);
assert(Math.abs(decoded.widthMm - 279.4) < 1e-9);
assert(Math.abs(decoded.heightMm - 215.9) < 1e-9);
const encoded = JSON.stringify(decoded.background);

const db = database();
db.exec(`INSERT INTO page_info VALUES('legacy','n',0,1,0,0,210,297,0)`);
migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 25);
assert.equal(db.prepare(`SELECT background_json FROM page_info WHERE page_id='legacy'`).get().background_json, null);
db.prepare(`INSERT INTO page_info VALUES('paper','n',1,5,?,1,?,?,0,?)`).run(
  decoded.template, decoded.widthMm, decoded.heightMm, encoded);
db.exec(`INSERT INTO original_page_identity VALUES('n',77,9,0,'paper',1)`);
const newer = JSON.stringify({ ...decoded.background, rotationRadians: Math.PI });
assert.equal(applyBackground(db, 100, 1, encoded), true);
db.prepare(`INSERT INTO original_deleted_page SELECT note_id,77,9,0,page_id,size,template,orientation,
  width_mm,height_mm,content_revision,NULL,background_json FROM page_info WHERE page_id='paper'`).run();
db.exec(`DELETE FROM page_info WHERE page_id='paper'`);
assert.equal(applyBackground(db, 99, 65535, 'losing-older'), false);
assert.equal(applyBackground(db, 100, 2, newer), true);
assert.equal(applyBackground(db, 100, 2, 'losing-equal'), false);
db.prepare(`INSERT INTO page_info SELECT page_id,note_id,1,size,template,orientation,width_mm,height_mm,
  content_revision,background_json FROM original_deleted_page WHERE page_id='paper'`).run();
assert.equal(db.prepare(`SELECT background_json FROM page_info WHERE page_id='paper'`).get().background_json, newer);
const storedWinner = db.prepare(`SELECT winner_timestamp,winner_site_id
  FROM original_page_background_winner`).get();
assert.equal(storedWinner.winner_timestamp, 100);
assert.equal(storedWinner.winner_site_id, 2);

const failed = database();
assert.throws(() => migrate(failed, true), /injected/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 24);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM pragma_table_info('page_info')
  WHERE name='background_json'`).get().count, 0);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='original_page_background_winner'`).get().count, 0);

console.log('success|flatbuffer-nz9=1|paper-k3a=1|rgba=1|spacing=18|centered=1|bleeds=1|rotation=pi/2|size-swap=1|v24-v25=1|legacy-null=1|strict-lww=1|archive-update=1|delete-undelete=1|rollback=1|pdf-distinct=1');

function floats(bytes) {
  assert(bytes !== null); const result = [];
  for (let offset = 0; offset < bytes.length; offset += 4) result.push(f32(bytes, offset));
  return result;
}
function u16(bytes, offset) { return bytes[offset] + bytes[offset+1] * 0x100; }
function u32(bytes, offset) { return bytes[offset] + bytes[offset+1]*0x100 +
  bytes[offset+2]*0x10000 + bytes[offset+3]*0x1000000; }
function i32(bytes, offset) { const value=u32(bytes,offset); return value>=0x80000000?value-0x100000000:value; }
function f32(bytes, offset) { return new DataView(bytes.buffer,bytes.byteOffset+offset,4).getFloat32(0,true); }
function w16(bytes, offset, value) { bytes[offset]=value; bytes[offset+1]=value>>>8; }
function w32(bytes, offset, value) { bytes[offset]=value; bytes[offset+1]=value>>>8;
  bytes[offset+2]=value>>>16; bytes[offset+3]=value>>>24; }
function w64(bytes, offset, value) { for(let i=0;i<8;i++){bytes[offset+i]=Number(value&255n);value>>=8n;} }
function wF32(bytes, offset, value) { new DataView(bytes.buffer,offset,4).setFloat32(0,value,true); }
