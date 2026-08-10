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
  sequences(values) {
    this.align(4); const vector = this.cursor; this.cursor += 4 + values.length * 12;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => writeSequence(this.bytes, vector + 4 + index * 12, value));
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
    return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  sequenceVector(field) {
    const offset = this.offset(field), pointer = this.table + offset;
    const vector = pointer + u32(this.bytes, pointer), count = u32(this.bytes, vector);
    return Array.from({ length: count }, (_, index) =>
      readSequence(this.bytes.slice(vector + 4 + index * 12, vector + 16 + index * 12)));
  }
}

function fixture(type, locations, textField = { timestamp: 20, site: 2 }) {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, 7); w32(b.bytes, root + 8, 200 + type);
  w64(b.bytes, root + 12, BigInt(200 + type)); w64(b.bytes, root + 20, BigInt(200 + type));
  b.bytes[root + 28] = type;
  if (type === 9) {
    const payload = b.table([4, textField === null ? 0 : 16], 24);
    b.pointer(root + 32, payload); writeSequence(b.bytes, payload + 4, locations[0]);
    if (textField !== null) writeOperation(b.bytes, payload + 16, textField);
  } else {
    const payload = b.table([4, textField === null ? 0 : 8], 16);
    b.pointer(root + 32, payload);
    if (textField !== null) writeOperation(b.bytes, payload + 8, textField);
    b.pointer(payload + 4, b.sequences(locations));
  }
  return b.finish(root);
}

function decodeFixture(bytes, type) {
  const root = new Table(bytes, u32(bytes, 0)); assert.equal(root.inline(4, 1)[0], type);
  const payload = root.nested(5);
  const locations = type === 9 ? [readSequence(payload.inline(0, 12))] : payload.sequenceVector(0);
  const field = payload.inline(1, 8);
  return { locations, textField: field === null ? null : readOperation(field), visible: type === 11 };
}

const ids = [0, 1, 2].map(index => ({ timestamp: 100, site: 7, index }));
assert.deepEqual(decodeFixture(fixture(9, [ids[1]]), 9).locations, [ids[1]]);
assert.deepEqual(decodeFixture(fixture(10, ids), 10).locations, ids);
assert.equal(decodeFixture(fixture(11, ids, null), 11).visible, true);
assert.equal(decodeFixture(fixture(11, ids, null), 11).textField, null);

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=36;
    CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,
      element_site_id INTEGER,PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE original_block_state(note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
      block_type INTEGER,PRIMARY KEY(note_id,block_timestamp,block_site_id),
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
  const v37 = schema.match(/const DDL_ORIGINAL_TEXT_CHARACTER_V37: string = `([\s\S]*?)`;/);
  assert(v37); db.exec(v37[1]); db.exec('PRAGMA user_version=37'); return db;
}

function migrate(db, inject = false) {
  const body = schema.match(/38:\s*\[([\s\S]*?)\n\s*\],\n\s*};/);
  assert(body); const statements = Array.from(body[1].matchAll(/`([\s\S]*?)`/g), match => match[1]);
  assert.equal(statements.length, 3); db.exec('BEGIN IMMEDIATE');
  try {
    statements.forEach(statement => db.exec(statement));
    if (inject) throw new Error('injected migration');
    db.exec('PRAGMA user_version=38; COMMIT');
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function seedBlock(db, block, pageId, text, archived = false) {
  const elementId = `op:${block.timestamp.toString(16)}:${block.site.toString(16)}`;
  db.prepare(`INSERT INTO original_element_z_index VALUES('n',?,?)`).run(block.timestamp, block.site);
  db.prepare(`INSERT INTO original_block_state VALUES('n',?,?,0)`).run(block.timestamp, block.site);
  const payload = Buffer.from(JSON.stringify({ kind: 'text', data: { id: elementId, richText: text } }));
  if (archived) {
    db.prepare(`INSERT INTO original_deleted_page_element VALUES('n',10,2,3,?,2,?,0)`)
      .run(elementId, payload);
  } else {
    db.prepare(`INSERT INTO page_element_snapshot VALUES('n',?, ?,2,?,0)`)
      .run(pageId, elementId, payload);
  }
  let parent = null;
  Array.from(text).forEach((value, index) => {
    db.prepare(`INSERT INTO original_text_character VALUES(
      'n',?,?,?,?,?,?,?,?,?,1,NULL,NULL,0)`).run(block.timestamp, block.site,
      100 + block.timestamp, block.site, index,
      parent?.timestamp ?? null, parent?.site ?? null, parent?.index ?? null, value.codePointAt(0));
    parent = { timestamp: 100 + block.timestamp, site: block.site, index };
  });
  return Array.from(text).map((_, index) => ({ timestamp: 100 + block.timestamp,
    site: block.site, index }));
}

function rows(db, block) {
  return db.prepare(`SELECT char_timestamp timestamp,char_site_id site,char_index [index],
    parent_timestamp,parent_site_id,parent_index,unicode_scalar scalar,visible,
    visibility_winner_timestamp winner_timestamp,visibility_winner_site_id winner_site
    FROM original_text_character WHERE note_id='n' AND block_timestamp=? AND block_site_id=?`)
    .all(block.timestamp, block.site);
}

function materialize(db, block) {
  const values = rows(db, block), byId = new Map(values.map(value => [key(value), value])), children = new Map();
  for (const value of values) {
    const parent = value.parent_timestamp === null ? 'root' :
      `${value.parent_timestamp}:${value.parent_site_id}:${value.parent_index}`;
    if (parent !== 'root' && !byId.has(parent)) return null;
    if (!children.has(parent)) children.set(parent, []);
    children.get(parent).push(value);
  }
  for (const siblings of children.values()) siblings.sort((a, b) => b.timestamp-a.timestamp || b.site-a.site || a.index-b.index);
  const pending = [...(children.get('root') ?? [])].reverse(), seen = new Set(), output = [];
  while (pending.length) {
    const value = pending.pop(), identity = key(value); if (seen.has(identity)) return null;
    seen.add(identity); if (value.visible) output.push(String.fromCodePoint(value.scalar));
    const descendants = children.get(identity) ?? [];
    for (let index = descendants.length - 1; index >= 0; index--) pending.push(descendants[index]);
  }
  return seen.size === values.length ? output.join('') : null;
}

function snapshot(db, block, archived) {
  const id = `op:${block.timestamp.toString(16)}:${block.site.toString(16)}`;
  const row = archived ? db.prepare(`SELECT payload,revision FROM original_deleted_page_element
    WHERE note_id='n' AND element_id=?`).get(id) : db.prepare(`SELECT payload,revision
    FROM page_element_snapshot WHERE note_id='n' AND element_id=?`).get(id);
  return { row, value: JSON.parse(Buffer.from(row.payload).toString()) };
}

function apply(db, operation, { archived = false, fail = false } = {}) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const unique = new Map(operation.locations.map(location => [key(location), location]));
    let block = operation.textField;
    for (const location of unique.values()) {
      if (location.timestamp === 0 && location.site === 0xFFFF && location.index === 0) {
        db.exec('ROLLBACK'); return false;
      }
      const owner = db.prepare(`SELECT block_timestamp timestamp,block_site_id site
        FROM original_text_character WHERE note_id='n' AND char_timestamp=? AND char_site_id=?
          AND char_index=?`).get(location.timestamp, location.site, location.index);
      if (owner === undefined || block !== null &&
        (owner.timestamp !== block.timestamp || owner.site !== block.site)) {
        db.exec('ROLLBACK'); return false;
      }
      block = owner;
    }
    const current = snapshot(db, block, archived);
    if (materialize(db, block) !== current.value.data.richText) { db.exec('ROLLBACK'); return false; }
    let winners = 0;
    for (const location of unique.values()) {
      const state = db.prepare(`SELECT visibility_winner_timestamp timestamp,
        visibility_winner_site_id site,visibility_winner_present present
        FROM original_text_character WHERE note_id='n' AND char_timestamp=? AND char_site_id=?
          AND char_index=?`).get(location.timestamp, location.site, location.index);
      const accepts = state.present === 0 || operation.timestamp > state.timestamp ||
        operation.timestamp === state.timestamp && operation.site >= state.site;
      if (!accepts) continue;
      db.prepare(`UPDATE original_text_character SET visible=?,visibility_winner_timestamp=?,
        visibility_winner_site_id=?,visibility_winner_present=1 WHERE note_id='n'
        AND char_timestamp=? AND char_site_id=? AND char_index=?`).run(
        operation.visible ? 1 : 0, operation.timestamp, operation.site,
        location.timestamp, location.site, location.index);
      winners++;
    }
    const after = materialize(db, block);
    if (winners > 0 && after !== current.value.data.richText) {
      current.value.data.richText = after; const payload = Buffer.from(JSON.stringify(current.value));
      if (archived) {
        db.prepare(`UPDATE original_deleted_page_element SET payload=?,revision=revision+1
          WHERE note_id='n' AND element_id=?`).run(payload, current.value.data.id);
        db.exec(`UPDATE original_deleted_page SET content_revision=content_revision+1,indexed_revision=NULL;
          DELETE FROM original_deleted_page_search WHERE type=2;`);
      } else {
        db.prepare(`UPDATE page_element_snapshot SET payload=?,revision=revision+1
          WHERE note_id='n' AND element_id=?`).run(payload, current.value.data.id);
        db.exec(`UPDATE page_info SET content_revision=content_revision+1;
          DELETE FROM search_page_state; DELETE FROM search_item WHERE type=2;`);
      }
    }
    if (fail) throw new Error('injected apply'); db.exec('COMMIT'); return true;
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

const block = { timestamp: 20, site: 2 }, db = database(); migrate(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 38);
db.exec(`INSERT INTO page_info VALUES('n','p',0); INSERT INTO search_page_state VALUES('n','p',0);
  INSERT INTO search_item VALUES('n','p',2,'old');`);
const chars = seedBlock(db, block, 'p', 'ABCD');
assert.equal(apply(db, { timestamp: 200, site: 1, locations: [chars[1]], textField: block, visible: false }), true);
assert.equal(snapshot(db, block, false).value.data.richText, 'ACD');
assert.equal(materialize(db, block), 'ACD');
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, 1);
assert.equal(db.prepare(`SELECT count(*) count FROM search_item`).get().count, 0);
assert.equal(apply(db, { timestamp: 199, site: 9, locations: [chars[1]], textField: null, visible: true }), true);
assert.equal(snapshot(db, block, false).value.data.richText, 'ACD');
assert.equal(apply(db, { timestamp: 201, site: 1, locations: [chars[1]], textField: null, visible: true }), true);
assert.equal(snapshot(db, block, false).value.data.richText, 'ABCD');
assert.equal(apply(db, { timestamp: 202, site: 1, locations: [chars[0], chars[2]], textField: block, visible: false }), true);
assert.equal(snapshot(db, block, false).value.data.richText, 'BD');
const revisionBeforeSame = db.prepare(`SELECT content_revision FROM page_info`).get().content_revision;
assert.equal(apply(db, { timestamp: 203, site: 1, locations: [chars[0]], textField: block, visible: false }), true);
assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, revisionBeforeSame);
assert.equal(rows(db, block).find(value => value.index === 0).winner_timestamp, 203);

const beforeReject = JSON.stringify(rows(db, block));
assert.equal(apply(db, { timestamp: 204, site: 1,
  locations: [{ timestamp: 999, site: 1, index: 0 }], textField: block, visible: false }), false);
assert.equal(apply(db, { timestamp: 204, site: 1,
  locations: [{ timestamp: 0, site: 0xFFFF, index: 0 }], textField: block, visible: false }), false);
assert.equal(JSON.stringify(rows(db, block)), beforeReject);

const archived = { timestamp: 30, site: 3 };
db.exec(`INSERT INTO original_deleted_page VALUES('n',10,2,3,'deleted',0,0);
  INSERT INTO original_deleted_page_search VALUES('n',10,2,3,2,'old');`);
const archivedChars = seedBlock(db, archived, 'deleted', 'XYZ', true);
assert.equal(apply(db, { timestamp: 210, site: 1, locations: [archivedChars[0], archivedChars[2]],
  textField: archived, visible: false }, { archived: true }), true);
assert.equal(snapshot(db, archived, true).value.data.richText, 'Y');
assert.equal(db.prepare(`SELECT indexed_revision FROM original_deleted_page`).get().indexed_revision, null);

const beforeRollback = JSON.stringify(rows(db, archived));
assert.throws(() => apply(db, { timestamp: 211, site: 1, locations: [archivedChars[0]],
  textField: archived, visible: true }, { archived: true, fail: true }), /injected apply/);
assert.equal(JSON.stringify(rows(db, archived)), beforeRollback);
assert.equal(snapshot(db, archived, true).value.data.richText, 'Y');

db.prepare(`DELETE FROM original_block_state WHERE note_id='n' AND block_timestamp=? AND block_site_id=?`)
  .run(block.timestamp, block.site);
assert.equal(db.prepare(`SELECT count(*) count FROM original_text_character WHERE block_timestamp=?`)
  .get(block.timestamp).count, 0);

const failed = database(); assert.throws(() => migrate(failed, true), /injected migration/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 37);
assert.equal(failed.prepare(`SELECT count(*) count FROM pragma_table_info('original_text_character')
  WHERE name='visibility_winner_present'`).get().count, 0);

assert.match(source, /ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE: number = 9/);
assert.match(source, /ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE: number = 10/);
assert.match(source, /ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE: number = 11/);
assert.match(source, /compareOperationIdentity\(operation, character\.visibilityWinner\) >= 0/);
assert.match(source, /if \(after === before\)/);
assert.match(dispatcher, /OriginalTextVisibilityOperationApplier/);
assert.match(schema, /DB_VERSION: number = 38/);
assert.match(schema, /visibility_winner_present/);

console.log('success|flatbuffer-pub-qub-f2c=1|v37-v38=1|remove-parent-keeps-descendants=1|' +
  'batch-remove=1|revive=2|strict-lww=1|same-value-winner-no-revision=1|' +
  'missing-root-atomic=2|live-archive=1|search-invalidated=2|rollback=2|cascade=1');

function key(value) { return `${value.timestamp}:${value.site}:${value.index}`; }
function writeSequence(bytes, offset, value) {
  w16(bytes, offset, value.site); w32(bytes, offset + 4, value.timestamp); w32(bytes, offset + 8, value.index);
}
function writeOperation(bytes, offset, value) { w16(bytes, offset, value.site); w32(bytes, offset + 4, value.timestamp); }
function readSequence(bytes) { return { timestamp: u32(bytes, 4), site: u16(bytes, 0), index: u32(bytes, 8) }; }
function readOperation(bytes) { return { timestamp: u32(bytes, 4), site: u16(bytes, 0) }; }
function w16(bytes, offset, value) { new DataView(bytes.buffer).setUint16(offset, value, true); }
function w32(bytes, offset, value) { new DataView(bytes.buffer).setUint32(offset, value, true); }
function w64(bytes, offset, value) { new DataView(bytes.buffer).setBigUint64(offset, value, true); }
function i32(bytes, offset) { return new DataView(bytes.buffer, offset, 4).getInt32(0, true); }
function u16(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 2).getUint16(0, true); }
function u32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getUint32(0, true); }
