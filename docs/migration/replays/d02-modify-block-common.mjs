import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const source = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalModifyBlockOperation.ets', rootPath), 'utf8');
const schema = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');
const dispatcher = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalPageOperationApplier.ets', rootPath), 'utf8');
const geometry = fs.readFileSync(new URL(
  'note/src/main/ets/core/model/TextBlockGeometry.ets', rootPath), 'utf8');
const selection = fs.readFileSync(new URL(
  'note/src/main/ets/rendering/SelectionTool.ets', rootPath), 'utf8');
const packageSpec = fs.readFileSync(new URL(
  'note/src/main/ets/data/NotePackageSpec.ets', rootPath), 'utf8');

class Builder {
  constructor() { this.bytes = new Uint8Array(768); this.cursor = 4; }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    const vtable = this.cursor; this.cursor += 4 + fields.length * 2; this.align(4);
    const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2); w16(this.bytes, vtable + 2, size);
    fields.forEach((field, index) => w16(this.bytes, vtable + 4 + index * 2, field));
    w32(this.bytes, table, table - vtable); return table;
  }
  operationIds(values) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + values.length * 8;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => {
      w16(this.bytes, vector + 4 + index * 8, value.site);
      w32(this.bytes, vector + 8 + index * 8, value.timestamp);
    });
    return vector;
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
    const offset = this.offset(field);
    return offset === 0 ? null : this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  nested(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    return offset === 0 ? null : new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  identities(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    const vector = pointer + u32(this.bytes, pointer), count = u32(this.bytes, vector);
    return Array.from({ length: count }, (_, index) => ({
      site: u16(this.bytes, vector + 4 + index * 8),
      timestamp: u32(this.bytes, vector + 8 + index * 8),
    }));
  }
}

function fixture() {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, 7); w32(b.bytes, root + 8, 91);
  w64(b.bytes, root + 12, 125n); w64(b.bytes, root + 20, 126n); b.bytes[root + 28] = 23;
  const modify = b.table([4, 8, 12, 24, 32, 36, 40, 48, 49, 56,
    0, 0, 0, 0, 0, 0, 0, 64], 68);
  b.pointer(root + 32, modify); b.bytes[modify + 8] = 1;
  w16(b.bytes, modify + 12, 2); w32(b.bytes, modify + 16, 10); w32(b.bytes, modify + 20, 3);
  wf32(b.bytes, modify + 24, 12); wf32(b.bytes, modify + 28, 34);
  wf32(b.bytes, modify + 40, 300); wf32(b.bytes, modify + 44, 60);
  b.bytes[modify + 48] = 1; b.bytes[modify + 49] = 1;
  w64(b.bytes, modify + 56, 18446744073709551615n); b.bytes[modify + 64] = 1;
  const rotation = b.table([4], 8); wf32(b.bytes, rotation + 4, 0.5);
  b.pointer(modify + 32, rotation);
  const scale = b.table([4], 12); wf32(b.bytes, scale + 4, 2); wf32(b.bytes, scale + 8, 3);
  b.pointer(modify + 36, scale);
  b.pointer(modify + 4, b.operationIds([{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }]));
  return b.finish(root);
}

const envelope = new Table(fixture(), u32(fixture(), 0));
assert.equal(envelope.inline(4, 1)[0], 23);
const block = envelope.nested(5), ids = block.identities(0);
assert.deepEqual(ids, [{ timestamp: 20, site: 2 }, { timestamp: 21, site: 3 }]);
assert.equal(block.inline(1, 1)[0], 1);
assert.deepEqual([u32(block.inline(2, 12), 4), u16(block.inline(2, 12), 0),
  u32(block.inline(2, 12), 8)], [10, 2, 3]);
assert.deepEqual([f32(block.inline(3, 8), 0), f32(block.inline(3, 8), 4)], [12, 34]);
assert.deepEqual([f32(block.inline(6, 8), 0), f32(block.inline(6, 8), 4)], [300, 60]);
assert.equal(f32(block.nested(4).inline(0, 4), 0), 0.5);
assert.deepEqual([f32(block.nested(5).inline(0, 8), 0),
  f32(block.nested(5).inline(0, 8), 4)], [2, 3]);
assert.equal(u64(block.inline(9, 8), 0).toString(), '18446744073709551615');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=35;
    CREATE TABLE original_block_state(
      note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,block_type INTEGER,
      create_page_timestamp INTEGER,create_page_site_id INTEGER,create_page_index INTEGER,
      create_origin_x REAL,create_origin_y REAL,create_rotation REAL,create_scale_x REAL,create_scale_y REAL,
      create_width REAL,create_height REAL,create_corner INTEGER,create_text_wrap INTEGER,
      create_enable_caption INTEGER,create_position_locked INTEGER,create_resizes_width INTEGER,
      create_margin_top REAL,create_margin_bottom REAL,create_margin_left REAL,create_margin_right REAL,
      create_z_index TEXT,PRIMARY KEY(note_id,block_timestamp,block_site_id));
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
      page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload BLOB,
      revision INTEGER,element_order INTEGER,PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE search_page_state(note_id TEXT,page_id TEXT,indexed_revision INTEGER);
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,type INTEGER,sub_id TEXT);
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      page_id TEXT,content_revision INTEGER,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      type INTEGER,sub_id TEXT);`);
  return db;
}

function migrate(db, inject = false, includeV35 = false) {
  const body = schema.match(/36:\s*\[([\s\S]*?)\n\s*\],\n\s*37:/);
  assert(body); const statements = Array.from(body[1].matchAll(/`([\s\S]*?)`/g), match => match[1]);
  assert.equal(statements.length, 42);
  db.exec('BEGIN IMMEDIATE');
  try {
    if (includeV35) {
      const frozen = schema.match(/const DDL_ORIGINAL_BLOCK_STATE_V35: string = `([\s\S]*?)`;/);
      assert(frozen); db.exec(frozen[1]);
    }
    statements.forEach(statement => db.exec(statement));
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=36; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function seed(db) {
  const payload = value => Buffer.from(JSON.stringify({ kind: 'text', data: {
    id: value.id, richText: '', textOrigin: { x: 0, y: 0 }, transform: value.transform,
    blockWidth: value.width, blockHeight: value.height,
  } }));
  db.exec(`INSERT INTO original_page_identity VALUES('n',10,2,1,'p1',1);
    INSERT INTO original_page_identity VALUES('n',11,2,1,'p2',1);
    INSERT INTO page_info VALUES('n','p1',0); INSERT INTO page_info VALUES('n','p2',0);
    INSERT INTO search_page_state VALUES('n','p1',0); INSERT INTO search_page_state VALUES('n','p2',0);
    INSERT INTO search_item VALUES('n','p1',2,'old'); INSERT INTO search_item VALUES('n','p2',2,'old');
    INSERT INTO original_element_z_index VALUES('n',20,2,10,2,1,2,'5');
    INSERT INTO original_element_z_index VALUES('n',30,1,11,2,1,2,'9');
    INSERT INTO original_block_state(note_id,block_timestamp,block_site_id,block_type,
      create_page_timestamp,create_page_site_id,create_page_index,create_origin_x,create_origin_y,
      create_rotation,create_scale_x,create_scale_y,create_width,create_height,create_corner,create_text_wrap,
      create_enable_caption,create_position_locked,create_resizes_width,create_margin_top,create_margin_bottom,
      create_margin_left,create_margin_right,create_z_index)
      VALUES('n',20,2,0,10,2,1,1,2,NULL,NULL,NULL,200,40,0,0,0,0,0,3,10,5,5,'5');`);
  db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p1','op:14:2',2,?,0,0)`)
    .run(payload({ id: 'op:14:2', transform: [1,0,1,0,1,2,0,0,1], width: 200, height: 40 }));
  db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p2','op:1e:1',2,?,0,0)`)
    .run(payload({ id: 'op:1e:1', transform: [1,0,0,0,1,0,0,0,1], width: 10, height: 10 }));
}

function apply(db, operation, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare(`SELECT * FROM original_block_state
      WHERE note_id='n' AND block_timestamp=20 AND block_site_id=2`).get();
    const accepts = prefix => state[`${prefix}_winner_present`] === 0 ||
      operation.timestamp > state[`${prefix}_winner_timestamp`] ||
      operation.timestamp === state[`${prefix}_winner_timestamp`] && operation.site > state[`${prefix}_winner_site_id`];
    const fields = operation.fields;
    const winning = Object.keys(fields).filter(accepts);
    if (winning.length === 0) { db.exec('COMMIT'); return false; }
    const setWinner = (prefix, valueColumns) => {
      const assignments = [...Object.keys(valueColumns).map(key => `${key}=?`),
        `${prefix}_winner_timestamp=?`, `${prefix}_winner_site_id=?`, `${prefix}_winner_present=1`];
      db.prepare(`UPDATE original_block_state SET ${assignments.join(',')} WHERE note_id='n'
        AND block_timestamp=20 AND block_site_id=2 AND ${prefix}_winner_present=?`)
        .run(...Object.values(valueColumns), operation.timestamp, operation.site,
          state[`${prefix}_winner_present`]);
    };
    if (winning.includes('page_origin')) setWinner('page_origin', fields.page_origin);
    if (winning.includes('rotation')) setWinner('rotation', { rotation_value: fields.rotation });
    if (winning.includes('scale')) setWinner('scale', fields.scale);
    if (winning.includes('size')) setWinner('size', fields.size);
    if (winning.includes('corner')) setWinner('corner', { corner_value: fields.corner });
    if (winning.includes('text_wrap')) setWinner('text_wrap', { text_wrap_value: fields.text_wrap });
    if (winning.includes('enable_caption')) setWinner('enable_caption',
      { enable_caption_value: fields.enable_caption ? 1 : 0 });
    if (winning.includes('position_locked')) setWinner('position_locked',
      { position_locked_value: fields.position_locked ? 1 : 0 });
    if (winning.includes('z_index')) setWinner('z_index', { z_index_value: fields.z_index });
    const destination = winning.includes('page_origin') ? fields.page_origin.page_origin_page_timestamp :
      (state.page_origin_winner_present ? state.page_origin_page_timestamp : state.create_page_timestamp);
    const pageId = destination === 10 ? 'p1' : 'p2';
    const oldPageId = db.prepare(`SELECT page_id FROM page_element_snapshot WHERE element_id='op:14:2'`).get().page_id;
    const z = winning.includes('z_index') ? fields.z_index :
      (state.z_index_winner_present ? state.z_index_value : state.create_z_index);
    if (oldPageId !== pageId) {
      const row = db.prepare(`SELECT * FROM page_element_snapshot WHERE note_id='n' AND page_id=?
        AND element_id='op:14:2'`).get(oldPageId);
      db.prepare(`DELETE FROM page_element_snapshot WHERE note_id='n' AND page_id=? AND element_id='op:14:2'`).run(oldPageId);
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n',?,'op:14:2',2,?,1,0)`).run(pageId, row.payload);
    }
    if (winning.includes('position_locked')) {
      const row = db.prepare(`SELECT payload FROM page_element_snapshot
        WHERE note_id='n' AND page_id=? AND element_id='op:14:2'`).get(pageId);
      const payload = JSON.parse(Buffer.from(row.payload).toString());
      payload.data.positionLocked = fields.position_locked;
      db.prepare(`UPDATE page_element_snapshot SET payload=?
        WHERE note_id='n' AND page_id=? AND element_id='op:14:2'`)
        .run(Buffer.from(JSON.stringify(payload)), pageId);
    }
    db.prepare(`UPDATE original_element_z_index SET page_timestamp=?,page_site_id=2,page_index=1,z_index=?
      WHERE note_id='n' AND element_timestamp=20 AND element_site_id=2`).run(destination, z);
    for (const currentPage of new Set([oldPageId, pageId])) {
      const tracked = db.prepare(`SELECT element_timestamp,element_site_id,z_index
        FROM original_element_z_index WHERE note_id='n' AND page_timestamp=?`).all(currentPage === 'p1' ? 10 : 11);
      const zById = new Map(tracked.map(row =>
        [`op:${row.element_timestamp.toString(16)}:${row.element_site_id.toString(16)}`, row.z_index]));
      const rows = db.prepare(`SELECT element_id FROM page_element_snapshot
        WHERE note_id='n' AND page_id=?`).all(currentPage)
        .map(row => ({ element_id: row.element_id, z_index: zById.get(row.element_id) }));
      assert(rows.every(row => row.z_index !== undefined));
      rows.sort((a,b) => a.z_index.length-b.z_index.length || a.z_index.localeCompare(b.z_index));
      rows.forEach((row,index) => db.prepare(`UPDATE page_element_snapshot SET element_order=?
        WHERE note_id='n' AND page_id=? AND element_id=?`).run(index,currentPage,row.element_id));
      db.prepare(`UPDATE page_info SET content_revision=content_revision+1 WHERE note_id='n' AND page_id=?`).run(currentPage);
      db.prepare(`DELETE FROM search_page_state WHERE note_id='n' AND page_id=?`).run(currentPage);
      db.prepare(`DELETE FROM search_item WHERE note_id='n' AND page_id=? AND type=2`).run(currentPage);
    }
    if (inject) throw new Error('injected apply');
    db.exec('COMMIT'); return true;
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const db = database(); migrate(db); seed(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 36);
assert.equal(db.prepare(`SELECT page_origin_winner_present FROM original_block_state`).get().page_origin_winner_present, 0);
apply(db, { timestamp: 100, site: 2, fields: {
  page_origin: { page_origin_page_timestamp: 11, page_origin_page_site_id: 2,
    page_origin_page_index: 1, page_origin_x: 12, page_origin_y: 34 },
  rotation: 0.5, scale: { scale_x_value: 2, scale_y_value: 3 }, z_index: '10',
} });
assert.equal(db.prepare(`SELECT page_id FROM page_element_snapshot WHERE element_id='op:14:2'`).get().page_id, 'p2');
assert.equal(db.prepare(`SELECT z_index FROM original_element_z_index WHERE element_timestamp=20`).get().z_index, '10');
assert.deepEqual(db.prepare(`SELECT element_id FROM page_element_snapshot WHERE page_id='p2'
  ORDER BY element_order`).all().map(row => row.element_id), ['op:1e:1','op:14:2']);
assert.equal(db.prepare(`SELECT count(*) count FROM search_item`).get().count, 0);
apply(db, { timestamp: 90, site: 1, fields: {
  size: { size_width_value: 300, size_height_value: 60 },
} });
const sizeWinner = db.prepare(`SELECT size_width_value,size_height_value,size_winner_timestamp
  FROM original_block_state`).get();
assert.equal(sizeWinner.size_width_value, 300);
assert.equal(sizeWinner.size_height_value, 60);
assert.equal(sizeWinner.size_winner_timestamp, 90);
assert.equal(apply(db, { timestamp: 70, site: 1, fields: { position_locked: true } }), true);
assert.equal(db.prepare(`SELECT position_locked_value FROM original_block_state`).get()
  .position_locked_value, 1);
const lockedPayload = JSON.parse(Buffer.from(db.prepare(`SELECT payload FROM page_element_snapshot
  WHERE element_id='op:14:2'`).get().payload).toString());
assert.equal(lockedPayload.data.positionLocked, true);
assert.equal(apply(db, { timestamp: 60, site: 1, fields: { position_locked: false } }), false);
assert.equal(apply(db, { timestamp: 80, site: 1, fields: { rotation: null } }), false);
const before = JSON.stringify(db.prepare(`SELECT * FROM original_block_state`).get());
assert.throws(() => apply(db, { timestamp: 110, site: 1, fields: { rotation: null } }, true), /injected apply/);
assert.equal(JSON.stringify(db.prepare(`SELECT * FROM original_block_state`).get()), before);

const failed = database();
assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name='page_origin_winner_present'`).get().count, 0);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 35);

const chain = database();
chain.exec('DROP TABLE original_block_state; PRAGMA user_version=34');
migrate(chain, false, true);
assert.equal(chain.prepare('PRAGMA user_version').get().user_version, 36);
assert.equal(chain.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name IN ('create_z_index','page_origin_winner_present','z_index_winner_present')`).get().count, 3);

assert.match(source, /ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE: number = 23/);
assert.match(source, /must pair page and origin/);
assert.match(source, /MODIFY_BLOCK_MATH_FIELDS_ON_NON_MATH/);
assert.match(source, /MODIFY_BLOCK_IMAGE_FIELDS_ON_NON_IMAGE/);
assert.match(source, /MODIFY_BLOCK_TEXT_FIELDS_ON_NON_TEXT/);
assert.doesNotMatch(source, /MODIFY_BLOCK_COMMON_BEHAVIOR_UNSUPPORTED/);
assert.match(source, /updatedElement\.positionLocked/);
assert.match(source, /registerAccepts/);
assert.match(source, /readOptionalWinner/);
assert.match(source, /isFiniteNullableScale/);
assert.match(source, /advanceRevisionAndInvalidateSearch/);
assert.match(schema, /DB_VERSION: number = 49/);
assert.match(dispatcher, /ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE/);
assert.match(geometry, /isTextBlockPositionLocked/);
assert.match(geometry, /eraserPath\.length === 0 \|\| isTextBlockPositionLocked/);
assert.match(selection, /!isTextBlockPositionLocked\(textBlock\)/);
assert.match(packageSpec, /text\.positionLocked === undefined/);

console.log('success|flatbuffer-td8=1|materialized-registers=6|reserved-registers=3|nullable-clear=1|state-finite=1|v34-v36=1|' +
  'lower-first-wins=1|stale-noop=1|cross-page=1|z-order=1|search-invalidated=2|' +
  'position-lock=1|text-common-consumer=1|rollback=2|type-specific-deferred=1');

function w16(bytes, offset, value) { new DataView(bytes.buffer).setUint16(offset, value, true); }
function w32(bytes, offset, value) { new DataView(bytes.buffer).setUint32(offset, value, true); }
function i32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getInt32(0, true); }
function u16(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 2).getUint16(0, true); }
function u32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getUint32(0, true); }
function f32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
function wf32(bytes, offset, value) { new DataView(bytes.buffer).setFloat32(offset, value, true); }
function w64(bytes, offset, value) { new DataView(bytes.buffer).setBigUint64(offset, value, true); }
function u64(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 8).getBigUint64(0, true); }
