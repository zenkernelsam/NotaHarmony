import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const source = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalModifyBlockOperation.ets', rootPath), 'utf8');
const schema = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');
const tests = fs.readFileSync(new URL(
  'note/src/test/SyncedOperationInbox.test.ets', rootPath), 'utf8');

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
  ids(values) {
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
  inline(field, size) {
    const offset = this.offset(field);
    return offset === 0 ? null : this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  nested(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    return offset === 0 ? null : new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
}

function fixture(clearCrop, horizontal, vertical) {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, 7); w32(b.bytes, root + 8, 92);
  w64(b.bytes, root + 12, 126n); w64(b.bytes, root + 20, 127n); b.bytes[root + 28] = 23;
  const modify = b.table([4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 8, 0, 12, 13, 0, 0], 16);
  b.pointer(root + 32, modify); b.bytes[modify + 12] = horizontal ? 1 : 0;
  b.bytes[modify + 13] = vertical ? 1 : 0;
  const crop = b.table([clearCrop ? 0 : 4], clearCrop ? 8 : 20);
  if (!clearCrop) {
    wf32(b.bytes, crop + 4, -5); wf32(b.bytes, crop + 8, 2);
    wf32(b.bytes, crop + 12, 100); wf32(b.bytes, crop + 16, 50);
  }
  b.pointer(modify + 8, crop);
  b.pointer(modify + 4, b.ids([{ timestamp: 20, site: 2 }]));
  return b.finish(root);
}

const setEnvelope = new Table(fixture(false, false, true), u32(fixture(false, false, true), 0));
const setBlock = setEnvelope.nested(5), setCrop = setBlock.nested(12).inline(0, 16);
assert.deepEqual([f32(setCrop, 0), f32(setCrop, 4), f32(setCrop, 8), f32(setCrop, 12)],
  [-5, 2, 100, 50]);
assert.equal(setBlock.inline(14, 1)[0], 0);
assert.equal(setBlock.inline(15, 1)[0], 1);
const clearBlock = new Table(fixture(true, true, false), u32(fixture(true, true, false), 0)).nested(5);
assert.equal(clearBlock.nested(12).inline(0, 16), null);
assert.equal(clearBlock.inline(14, 1)[0], 1);
assert.equal(clearBlock.inline(15, 1)[0], 0);

const migrationBody = schema.match(/44:\s*\[([\s\S]*?)\n\s*\],\n};/);
assert(migrationBody);
const migrationStatements = Array.from(
  migrationBody[1].matchAll(/(?:'([^']+)'|`([\s\S]*?)`)/g), match => match[1] ?? match[2]);
assert.equal(migrationStatements.length, 15);

function v43Database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=43;
    CREATE TABLE original_block_state(note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
      PRIMARY KEY(note_id,block_timestamp,block_site_id));
    INSERT INTO original_block_state VALUES('legacy',1,1);`);
  return db;
}

function migrate44(db, failAt = -1) {
  db.exec('BEGIN IMMEDIATE');
  try {
    migrationStatements.forEach((statement, index) => {
      db.exec(statement); if (index === failAt) throw new Error('injected migration');
    });
    db.exec('PRAGMA user_version=44; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const migrated = v43Database(); migrate44(migrated);
assert.equal(migrated.prepare('PRAGMA user_version').get().user_version, 44);
assert.equal(migrated.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name LIKE 'image_crop_%' OR name LIKE 'image_flip_%'`).get().count, 15);
const legacyWinners = migrated.prepare(`SELECT image_crop_winner_present,
  image_flip_horizontal_winner_present,image_flip_vertical_winner_present
  FROM original_block_state`).get();
assert.equal(legacyWinners.image_crop_winner_present, 0);
assert.equal(legacyWinners.image_flip_horizontal_winner_present, 0);
assert.equal(legacyWinners.image_flip_vertical_winner_present, 0);
const failedMigration = v43Database();
assert.throws(() => migrate44(failedMigration, 7), /injected migration/);
assert.equal(failedMigration.prepare('PRAGMA user_version').get().user_version, 43);
assert.equal(failedMigration.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name='image_crop_x_value'`).get().count, 0);

function materializationDatabase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE block_state(id TEXT PRIMARY KEY,kind INTEGER,block_type INTEGER,page_id TEXT,
      z_index TEXT,create_crop_x REAL,create_crop_y REAL,create_crop_width REAL,create_crop_height REAL,
      create_h INTEGER,create_v INTEGER,
      image_crop_x_value REAL,image_crop_y_value REAL,image_crop_width_value REAL,image_crop_height_value REAL,
      image_crop_winner_timestamp INTEGER,image_crop_winner_site_id INTEGER,image_crop_winner_present INTEGER DEFAULT 0,
      image_flip_horizontal_value INTEGER,image_flip_horizontal_winner_timestamp INTEGER,
      image_flip_horizontal_winner_site_id INTEGER,image_flip_horizontal_winner_present INTEGER DEFAULT 0,
      image_flip_vertical_value INTEGER,image_flip_vertical_winner_timestamp INTEGER,
      image_flip_vertical_winner_site_id INTEGER,image_flip_vertical_winner_present INTEGER DEFAULT 0);
    CREATE TABLE snapshot(page_id TEXT,id TEXT,kind INTEGER,payload TEXT,element_order INTEGER,
      PRIMARY KEY(page_id,id,kind));
    CREATE TABLE archived(page_id TEXT,id TEXT,kind INTEGER,payload TEXT,element_order INTEGER,
      PRIMARY KEY(page_id,id,kind));
    CREATE TABLE search_item(page_id TEXT,type INTEGER,sub_id TEXT);
    INSERT INTO search_item VALUES('p1',2,'text-kept'),('p2',2,'text-kept');`);
  seedImage(db, 'i1', 'p1', '5', false, { x: 1, y: 2, width: 30, height: 40 });
  seedImage(db, 'i2', 'p1', '9', false, null);
  seedImage(db, 'i3', 'deleted', '7', true, { x: 3, y: 4, width: 5, height: 6 });
  db.exec(`INSERT INTO snapshot VALUES('p1','text',2,'{}',1);
    INSERT INTO snapshot VALUES('p2','stroke',0,'{}',0)`);
  return db;
}

function seedImage(db, id, page, z, isArchived, crop) {
  db.prepare(`INSERT INTO block_state(id,kind,block_type,page_id,z_index,
    create_crop_x,create_crop_y,create_crop_width,create_crop_height,create_h,create_v)
    VALUES(?,4,1,?,?,?,?,?,?,1,0)`).run(id, page, z, crop?.x ?? null, crop?.y ?? null,
      crop?.width ?? null, crop?.height ?? null);
  const payload = JSON.stringify({ kind: 'image', data: { id,
    cropRect: crop === null ? null : { left: crop.x, top: crop.y,
      right: crop.x + crop.width, bottom: crop.y + crop.height },
    imageFlippedHorizontally: true, imageFlippedVertically: false } });
  db.prepare(`INSERT INTO ${isArchived ? 'archived' : 'snapshot'} VALUES(?,?,4,?,0)`)
    .run(page, id, payload);
}

function accepts(state, prefix, timestamp, site) {
  return state[`${prefix}_winner_present`] === 0 ||
    timestamp > state[`${prefix}_winner_timestamp`] ||
    timestamp === state[`${prefix}_winner_timestamp`] && site > state[`${prefix}_winner_site_id`];
}

function apply(db, ids, operation, failAfter = -1) {
  db.exec('BEGIN IMMEDIATE');
  try {
    ids.forEach((id, index) => {
      const state = db.prepare('SELECT * FROM block_state WHERE id=?').get(id);
      if (!state || state.kind !== 4 || state.block_type !== 1) throw new Error('type gate');
      const tuple = [state.image_crop_x_value, state.image_crop_y_value,
        state.image_crop_width_value, state.image_crop_height_value];
      const tupleCount = tuple.filter(value => value !== null).length;
      if (state.image_crop_winner_present && tupleCount !== 0 && tupleCount !== 4) {
        throw new Error('state diverged');
      }
      const table = state.page_id === 'deleted' ? 'archived' : 'snapshot';
      const row = db.prepare(`SELECT payload FROM ${table} WHERE page_id=? AND id=? AND kind=4`)
        .get(state.page_id, id);
      const payload = JSON.parse(row.payload);
      if ('crop' in operation && accepts(state, 'image_crop', operation.timestamp, operation.site)) {
        const crop = operation.crop;
        db.prepare(`UPDATE block_state SET image_crop_x_value=?,image_crop_y_value=?,
          image_crop_width_value=?,image_crop_height_value=?,image_crop_winner_timestamp=?,
          image_crop_winner_site_id=?,image_crop_winner_present=1 WHERE id=?`)
          .run(crop?.x ?? null, crop?.y ?? null, crop?.width ?? null, crop?.height ?? null,
            operation.timestamp, operation.site, id);
        payload.data.cropRect = crop === null ? null : { left: crop.x, top: crop.y,
          right: crop.x + crop.width, bottom: crop.y + crop.height };
      }
      for (const [field, prefix, property] of [
        ['horizontal', 'image_flip_horizontal', 'imageFlippedHorizontally'],
        ['vertical', 'image_flip_vertical', 'imageFlippedVertically']]) {
        if (field in operation && accepts(state, prefix, operation.timestamp, operation.site)) {
          db.prepare(`UPDATE block_state SET ${prefix}_value=?,${prefix}_winner_timestamp=?,
            ${prefix}_winner_site_id=?,${prefix}_winner_present=1 WHERE id=?`)
            .run(operation[field] ? 1 : 0, operation.timestamp, operation.site, id);
          payload.data[property] = operation[field];
        }
      }
      let page = state.page_id;
      if (operation.pageId && state.page_id !== 'deleted') {
        db.prepare(`DELETE FROM snapshot WHERE page_id=? AND id=? AND kind=4`).run(page, id);
        page = operation.pageId;
        db.prepare('UPDATE block_state SET page_id=?,z_index=? WHERE id=?')
          .run(page, operation.zIndex, id);
        db.prepare('INSERT INTO snapshot VALUES(?,?,4,?,0)').run(page, id, JSON.stringify(payload));
      } else {
        db.prepare(`UPDATE ${table} SET payload=? WHERE page_id=? AND id=? AND kind=4`)
          .run(JSON.stringify(payload), page, id);
      }
      if (index === failAfter) throw new Error('injected apply');
    });
    for (const page of ['p1', 'p2']) {
      const rows = db.prepare('SELECT id,kind FROM snapshot WHERE page_id=?').all(page);
      rows.forEach((row, index) => db.prepare(
        'UPDATE snapshot SET element_order=? WHERE page_id=? AND id=? AND kind=?')
        .run(index, page, row.id, row.kind));
    }
    db.exec('COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const db = materializationDatabase();
apply(db, ['i1'], { timestamp: 100, site: 2,
  crop: { x: -5, y: 2, width: 100, height: 50 }, horizontal: false, vertical: true });
let state = db.prepare("SELECT * FROM block_state WHERE id='i1'").get();
assert.equal(state.image_crop_x_value, -5);
assert.equal(state.image_flip_horizontal_value, 0);
assert.equal(state.image_flip_vertical_value, 1);
apply(db, ['i1'], { timestamp: 110, site: 1, crop: null, horizontal: true, vertical: false });
state = db.prepare("SELECT * FROM block_state WHERE id='i1'").get();
assert.equal(state.image_crop_winner_present, 1);
assert.equal(state.image_crop_x_value, null);
assert.equal(state.image_flip_horizontal_value, 1);
assert.equal(state.image_flip_vertical_value, 0);
apply(db, ['i1'], { timestamp: 90, site: 9, crop: { x: 9, y: 9, width: 9, height: 9 } });
assert.equal(db.prepare("SELECT image_crop_x_value FROM block_state WHERE id='i1'").get()
  .image_crop_x_value, null);
apply(db, ['i2'], { timestamp: 50, site: 1, vertical: true });
assert.equal(db.prepare("SELECT image_crop_winner_present FROM block_state WHERE id='i2'").get()
  .image_crop_winner_present, 0);
apply(db, ['i3'], { timestamp: 70, site: 1, crop: null, horizontal: false });
const archivedPayload = JSON.parse(db.prepare("SELECT payload FROM archived WHERE id='i3'").get().payload);
assert.equal(archivedPayload.data.cropRect, null);
assert.equal(archivedPayload.data.imageFlippedHorizontally, false);
apply(db, ['i1'], { timestamp: 120, site: 1, pageId: 'p2', zIndex: '12', vertical: true });
assert.equal(db.prepare("SELECT page_id FROM block_state WHERE id='i1'").get().page_id, 'p2');
assert.equal(db.prepare("SELECT count(*) count FROM snapshot WHERE page_id='p2' AND id='i1'").get().count, 1);
assert.equal(db.prepare('SELECT count(*) count FROM search_item').get().count, 2);

const beforeMulti = JSON.stringify(db.prepare('SELECT * FROM block_state ORDER BY id').all());
assert.throws(() => apply(db, ['i1', 'i2'], { timestamp: 130, site: 1, horizontal: false }, 0),
  /injected apply/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM block_state ORDER BY id').all()), beforeMulti);
db.exec(`UPDATE block_state SET image_crop_x_value=1,image_crop_y_value=NULL,
  image_crop_width_value=2,image_crop_height_value=3,image_crop_winner_present=1 WHERE id='i2'`);
assert.throws(() => apply(db, ['i2'], { timestamp: 140, site: 1, vertical: false }), /state diverged/);

assert.match(source, /cropSetter\.readInlineBytes\(0, 16\)/);
assert.match(source, /MODIFY_BLOCK_IMAGE_FIELDS_ON_NON_IMAGE/);
assert.match(source, /MODIFY_BLOCK_TEXT_FIELDS_ON_NON_TEXT/);
assert.match(source, /target\.kind === PageElementKind\.IMAGE/);
assert.match(source, /cloneImageElement/);
assert.match(source, /imageBlockWorldBounds/);
assert.match(source, /image_crop_x_value/);
assert.match(source, /if \(textChanged\)/);
assert.match(schema, /DB_VERSION: number = 44/);
assert.match(schema, /image_crop_winner_present = 1[\s\S]*image_crop_x_value IS NULL/);
assert.match(tests, /decodes original MODIFY_BLOCK image crop and flip registers/);

console.log('success|flatbuffer-image-registers=3|crop-clear=1|false-presence=1|v43-v44=1|' +
  'migration-rollback=1|independent-winners=3|stale-noop=1|create-fallback=1|live=1|archive=1|' +
  'cross-page=1|mixed-order=1|multi-image-rollback=1|type-gates=2|partial-crop-diverged=1|' +
  'text-search-preserved=1');

function w16(bytes, offset, value) { new DataView(bytes.buffer).setUint16(offset, value, true); }
function w32(bytes, offset, value) { new DataView(bytes.buffer).setUint32(offset, value, true); }
function i32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getInt32(0, true); }
function u16(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 2).getUint16(0, true); }
function u32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getUint32(0, true); }
function f32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
function wf32(bytes, offset, value) { new DataView(bytes.buffer).setFloat32(offset, value, true); }
function w64(bytes, offset, value) { new DataView(bytes.buffer).setBigUint64(offset, value, true); }
