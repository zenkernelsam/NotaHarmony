import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const source = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalInsertTextOperation.ets', rootPath), 'utf8');
const schema = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');
const dispatcher = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalPageOperationApplier.ets', rootPath), 'utf8');

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
  string(value) {
    return this.bytesVector(Array.from(new TextEncoder().encode(value)));
  }
  bytesVector(values) {
    this.align(4); const vector = this.cursor; this.cursor += 5 + values.length;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => { this.bytes[vector + 4 + index] = value; });
    this.bytes[vector + 4 + values.length] = 0; return vector;
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
    return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  string(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    const vector = pointer + u32(this.bytes, pointer), count = u32(this.bytes, vector);
    assert.equal(this.bytes[vector + 4 + count], 0);
    return this.bytes.slice(vector + 4, vector + 4 + count);
  }
}

function fixture({ type, timestamp, site, location = null, textField = null,
  scalar = null, text = null, rawString = null }) {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, site); w32(b.bytes, root + 8, timestamp);
  w64(b.bytes, root + 12, BigInt(timestamp)); w64(b.bytes, root + 20, BigInt(timestamp));
  b.bytes[root + 28] = type;
  const payload = b.table([location === null ? 0 : 4, 16, textField === null ? 0 : 20], 28);
  b.pointer(root + 32, payload);
  if (location !== null) writeSequence(b.bytes, payload + 4, location);
  if (textField !== null) writeOperation(b.bytes, payload + 20, textField);
  if (type === 7) {
    w32(b.bytes, payload + 16, scalar);
  } else {
    const vector = rawString === null ? b.string(text) : b.bytesVector(rawString);
    b.pointer(payload + 16, vector);
  }
  return b.finish(root);
}

function decodeFixture(bytes, expectedType) {
  const root = new Table(bytes, u32(bytes, 0));
  assert.equal(root.inline(4, 1)[0], expectedType);
  const payload = root.nested(5), locationBytes = payload.inline(0, 12);
  const fieldBytes = payload.inline(2, 8);
  const location = locationBytes === null ? null : readSequence(locationBytes);
  const textField = fieldBytes === null ? null : readOperation(fieldBytes);
  if (expectedType === 7) {
    return { location, textField, scalars: [u32(payload.inline(1, 4), 0)] };
  }
  const decoded = new TextDecoder('utf-8').decode(payload.string(1));
  return { location, textField, scalars: Array.from(decoded, value => value.codePointAt(0)) };
}

const block = { timestamp: 20, site: 2 };
const stringRaw = fixture({ type: 8, timestamp: 100, site: 7,
  location: { timestamp: 0, site: 0xFFFF, index: 0 }, textField: block, text: 'A中😀' });
assert.deepEqual(decodeFixture(stringRaw, 8), {
  location: { timestamp: 0, site: 0xFFFF, index: 0 }, textField: block,
  scalars: [0x41, 0x4E2D, 0x1F600],
});
const charRaw = fixture({ type: 7, timestamp: 101, site: 7,
  location: { timestamp: 100, site: 7, index: 0 }, textField: block, scalar: 0x1F642 });
assert.deepEqual(decodeFixture(charRaw, 7).scalars, [0x1F642]);
assert.deepEqual(decodeFixture(fixture({ type: 8, timestamp: 102, site: 7,
  textField: block, rawString: [0xF0, 0x28, 0x8C, 0x28] }), 8).scalars,
  [0xFFFD, 0x28, 0xFFFD, 0x28]);

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=36;
    CREATE TABLE original_element_z_index(
      note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,page_timestamp INTEGER,
      page_site_id INTEGER,page_index INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE original_block_state(
      note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,block_type INTEGER,
      PRIMARY KEY(note_id,block_timestamp,block_site_id),
      FOREIGN KEY(note_id,block_timestamp,block_site_id) REFERENCES
        original_element_z_index(note_id,element_timestamp,element_site_id) ON DELETE CASCADE);
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,
      payload BLOB,revision INTEGER,PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE search_page_state(note_id TEXT,page_id TEXT,indexed_revision INTEGER);
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,type INTEGER,sub_id TEXT);
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,page_id TEXT,content_revision INTEGER,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,type INTEGER,sub_id TEXT);`);
  return db;
}

function migrate(db, inject = false) {
  const ddl = schema.match(/const DDL_ORIGINAL_TEXT_CHARACTER_V37: string = `([\s\S]*?)`;/);
  assert(ddl); db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(ddl[1]); if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=37; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function seedBlock(db, identity, page, richText = '', archived = false) {
  const id = `op:${identity.timestamp.toString(16)}:${identity.site.toString(16)}`;
  db.prepare(`INSERT INTO original_element_z_index VALUES('n',?,?,10,2,3,2,'1')`)
    .run(identity.timestamp, identity.site);
  db.prepare(`INSERT INTO original_block_state VALUES('n',?,?,0)`)
    .run(identity.timestamp, identity.site);
  const payload = Buffer.from(JSON.stringify({ kind: 'text', data: { id, richText,
    transform: [1,0,0,0,1,0,0,0,1], bounds: { left: 0, top: 0, right: 100, bottom: 40 },
    textOrigin: { x: 0, y: 0 }, blockWidth: 100, blockHeight: 40,
    contentLeftInset: 5, contentTopInset: 3, fontSize: 16, fontColor: '#000000' } }));
  if (archived) {
    db.prepare(`INSERT INTO original_deleted_page_element VALUES('n',10,2,3,?,2,?,0)`)
      .run(id, payload);
  } else {
    db.prepare(`INSERT INTO page_element_snapshot VALUES('n',?, ?,2,?,0)`)
      .run(page, id, payload);
  }
}

function compareId(left, right) {
  return right.timestamp - left.timestamp || right.site - left.site || left.index - right.index;
}

function materialize(db, identity) {
  const rows = db.prepare(`SELECT char_timestamp timestamp,char_site_id site,char_index [index],
    parent_timestamp,parent_site_id,parent_index,unicode_scalar scalar,visible
    FROM original_text_character WHERE note_id='n' AND block_timestamp=? AND block_site_id=?`)
    .all(identity.timestamp, identity.site);
  const ids = new Map(rows.map(row => [`${row.timestamp}:${row.site}:${row.index}`, row]));
  const children = new Map();
  for (const row of rows) {
    const parent = row.parent_timestamp === null ? 'root' :
      `${row.parent_timestamp}:${row.parent_site_id}:${row.parent_index}`;
    if (parent !== 'root' && !ids.has(parent)) return null;
    if (!children.has(parent)) children.set(parent, []);
    children.get(parent).push(row);
  }
  for (const values of children.values()) values.sort(compareId);
  const seen = new Set(), scalars = [];
  function walk(parent) {
    for (const row of children.get(parent) ?? []) {
      const key = `${row.timestamp}:${row.site}:${row.index}`;
      if (seen.has(key)) return false;
      seen.add(key); if (row.visible) scalars.push(row.scalar);
      if (!walk(key)) return false;
    }
    return true;
  }
  if (!walk('root') || seen.size !== rows.length) return null;
  return String.fromCodePoint(...scalars);
}

function readSnapshot(db, identity, archived) {
  const id = `op:${identity.timestamp.toString(16)}:${identity.site.toString(16)}`;
  const row = archived ? db.prepare(`SELECT payload,revision FROM original_deleted_page_element
    WHERE note_id='n' AND page_timestamp=10 AND page_site_id=2 AND page_index=3
      AND element_id=? AND kind=2`).get(id) :
    db.prepare(`SELECT payload,revision FROM page_element_snapshot
      WHERE note_id='n' AND page_id='p' AND element_id=? AND kind=2`).get(id);
  return row === undefined ? null : { row, value: JSON.parse(Buffer.from(row.payload).toString()) };
}

function apply(db, operation, { archived = false, fail = false } = {}) {
  db.exec('BEGIN IMMEDIATE');
  try {
    let target = operation.textField;
    if (operation.location !== null) {
      const anchor = db.prepare(`SELECT block_timestamp timestamp,block_site_id site
        FROM original_text_character WHERE note_id='n' AND char_timestamp=?
          AND char_site_id=? AND char_index=?`).get(
        operation.location.timestamp, operation.location.site, operation.location.index);
      if (anchor === undefined || target !== null &&
        (anchor.timestamp !== target.timestamp || anchor.site !== target.site)) {
        db.exec('ROLLBACK'); return false;
      }
      target = anchor;
    }
    if (target === null) { db.exec('ROLLBACK'); return false; }
    const snapshot = readSnapshot(db, target, archived);
    if (snapshot === null || materialize(db, target) !== snapshot.value.data.richText) {
      db.exec('ROLLBACK'); return false;
    }
    let parent = operation.location;
    for (let index = 0; index < operation.scalars.length; index++) {
      db.prepare(`INSERT INTO original_text_character VALUES(
        'n',?,?,?,?,?,?,?,?,?,1)`).run(target.timestamp, target.site,
        operation.timestamp, operation.site, index,
        parent?.timestamp ?? null, parent?.site ?? null, parent?.index ?? null,
        operation.scalars[index]);
      parent = { timestamp: operation.timestamp, site: operation.site, index };
    }
    snapshot.value.data.richText = materialize(db, target);
    const payload = Buffer.from(JSON.stringify(snapshot.value));
    if (archived) {
      db.prepare(`UPDATE original_deleted_page_element SET payload=?,revision=revision+1
        WHERE note_id='n' AND page_timestamp=10 AND page_site_id=2 AND page_index=3
          AND element_id=?`).run(payload, snapshot.value.data.id);
      db.exec(`UPDATE original_deleted_page SET content_revision=content_revision+1,indexed_revision=NULL;
        DELETE FROM original_deleted_page_search WHERE type=2;`);
    } else {
      db.prepare(`UPDATE page_element_snapshot SET payload=?,revision=revision+1
        WHERE note_id='n' AND page_id='p' AND element_id=?`).run(payload, snapshot.value.data.id);
      db.exec(`UPDATE page_info SET content_revision=content_revision+1 WHERE note_id='n' AND page_id='p';
        DELETE FROM search_page_state WHERE note_id='n' AND page_id='p';
        DELETE FROM search_item WHERE note_id='n' AND page_id='p' AND type=2;`);
    }
    if (fail) throw new Error('injected apply');
    db.exec('COMMIT'); return true;
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 37);
db.exec(`INSERT INTO page_info VALUES('n','p',0);
  INSERT INTO search_page_state VALUES('n','p',0);
  INSERT INTO search_item VALUES('n','p',2,'old');`);
seedBlock(db, block, 'p');
assert.equal(apply(db, { timestamp: 100, site: 7, location: null, textField: block,
  scalars: [0x41, 0x4E2D, 0x1F600] }), true);
assert.equal(readSnapshot(db, block, false).value.data.richText, 'A中😀');
assert.equal(db.prepare(`SELECT count(*) count FROM original_text_character`).get().count, 3);
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, 1);
assert.equal(db.prepare(`SELECT count(*) count FROM search_item`).get().count, 0);

assert.equal(apply(db, { timestamp: 110, site: 1,
  location: { timestamp: 100, site: 7, index: 0 }, textField: block, scalars: [0x58] }), true);
assert.equal(readSnapshot(db, block, false).value.data.richText, 'AX中😀');
assert.equal(apply(db, { timestamp: 109, site: 9,
  location: { timestamp: 100, site: 7, index: 0 }, textField: null, scalars: [0x59] }), true);
assert.equal(readSnapshot(db, block, false).value.data.richText, 'AXY中😀');

const other = { timestamp: 21, site: 2 }; seedBlock(db, other, 'p');
const beforeRejected = db.prepare(`SELECT count(*) count FROM original_text_character`).get().count;
assert.equal(apply(db, { timestamp: 120, site: 1,
  location: { timestamp: 100, site: 7, index: 0 }, textField: other, scalars: [0x5A] }), false);
assert.equal(apply(db, { timestamp: 121, site: 1,
  location: { timestamp: 999, site: 1, index: 0 }, textField: block, scalars: [0x5A] }), false);
assert.equal(apply(db, { timestamp: 122, site: 1,
  location: null, textField: null, scalars: [0x5A] }), false);
assert.equal(db.prepare(`SELECT count(*) count FROM original_text_character`).get().count, beforeRejected);

const legacy = { timestamp: 22, site: 2 }; seedBlock(db, legacy, 'p', 'legacy');
assert.equal(apply(db, { timestamp: 123, site: 1,
  location: null, textField: legacy, scalars: [0x5A] }), false);

const archived = { timestamp: 23, site: 2 };
db.exec(`INSERT INTO original_deleted_page VALUES('n',10,2,3,'deleted',0,0);
  INSERT INTO original_deleted_page_search VALUES('n',10,2,3,2,'old');`);
seedBlock(db, archived, 'deleted', '', true);
assert.equal(apply(db, { timestamp: 130, site: 1,
  location: null, textField: archived, scalars: [0x1F642] }, { archived: true }), true);
assert.equal(readSnapshot(db, archived, true).value.data.richText, '🙂');
assert.equal(db.prepare(`SELECT indexed_revision FROM original_deleted_page`).get().indexed_revision, null);
assert.equal(db.prepare(`SELECT count(*) count FROM original_deleted_page_search`).get().count, 0);

const rowsBeforeRollback = db.prepare(`SELECT count(*) count FROM original_text_character`).get().count;
assert.throws(() => apply(db, { timestamp: 140, site: 1,
  location: { timestamp: 130, site: 1, index: 0 }, textField: archived,
  scalars: [0x21] }, { archived: true, fail: true }), /injected apply/);
assert.equal(db.prepare(`SELECT count(*) count FROM original_text_character`).get().count, rowsBeforeRollback);
assert.equal(readSnapshot(db, archived, true).value.data.richText, '🙂');

db.prepare(`DELETE FROM original_block_state WHERE note_id='n' AND block_timestamp=? AND block_site_id=?`)
  .run(block.timestamp, block.site);
assert.equal(db.prepare(`SELECT count(*) count FROM original_text_character
  WHERE block_timestamp=? AND block_site_id=?`).get(block.timestamp, block.site).count, 0);

const failed = database();
assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 36);
assert.equal(failed.prepare(`SELECT count(*) count FROM sqlite_master
  WHERE name='original_text_character'`).get().count, 0);

assert.match(source, /ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE: number = 7/);
assert.match(source, /ORIGINAL_INSERT_STRING_PAYLOAD_TYPE: number = 8/);
assert.match(source, /util\.TextDecoder\.create\('utf-8'\)/);
assert.match(source, /compareOriginalSequenceIdentity/);
assert.match(source, /INSERT_TEXT_STATE_DIVERGED/);
assert.match(source, /advanceRevisionAndInvalidateSearch/);
assert.match(dispatcher, /OriginalInsertTextOperationApplier/);
assert.match(schema, /DB_VERSION: number = 52/);
assert.match(schema, /DDL_ORIGINAL_TEXT_CHARACTER/);

console.log('success|flatbuffer-e46-f46=1|unicode-codepoints=1|utf8-replacement=1|' +
  'v36-v37=1|root-and-anchor=1|concurrent-order=1|missing-cross-unbound=3|' +
  'snapshot-divergence=1|live-archive=1|search-invalidated=2|rollback=2|cascade=1');

function writeSequence(bytes, offset, value) {
  w16(bytes, offset, value.site); w32(bytes, offset + 4, value.timestamp);
  w32(bytes, offset + 8, value.index);
}
function writeOperation(bytes, offset, value) {
  w16(bytes, offset, value.site); w32(bytes, offset + 4, value.timestamp);
}
function readSequence(bytes) {
  return { timestamp: u32(bytes, 4), site: u16(bytes, 0), index: u32(bytes, 8) };
}
function readOperation(bytes) { return { timestamp: u32(bytes, 4), site: u16(bytes, 0) }; }
function w16(bytes, offset, value) { new DataView(bytes.buffer).setUint16(offset, value, true); }
function w32(bytes, offset, value) { new DataView(bytes.buffer).setUint32(offset, value, true); }
function w64(bytes, offset, value) { new DataView(bytes.buffer).setBigUint64(offset, value, true); }
function i32(bytes, offset) { return new DataView(bytes.buffer, offset, 4).getInt32(0, true); }
function u16(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 2).getUint16(0, true); }
function u32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getUint32(0, true); }
