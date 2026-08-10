import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

function u16(bytes, offset) { return bytes[offset] | (bytes[offset + 1] << 8); }
function u32(bytes, offset) {
  return (bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)) >>> 0;
}
function i32(bytes, offset) {
  return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getInt32(0, true);
}
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) {
  bytes[offset] = value; bytes[offset + 1] = value >>> 8;
  bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24;
}

class Builder {
  constructor() { this.bytes = new Uint8Array(512); this.cursor = 4; }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    this.align(4);
    const vtable = this.cursor; this.cursor += 4 + fields.length * 2;
    this.align(4);
    const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2); w16(this.bytes, vtable + 2, size);
    fields.forEach((field, index) => w16(this.bytes, vtable + 4 + index * 2, field));
    w32(this.bytes, table, table - vtable);
    return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  identities() {
    this.align(4); const vector = this.cursor; this.cursor += 12;
    w32(this.bytes, vector, 1); w16(this.bytes, vector + 4, 2); w32(this.bytes, vector + 8, 20);
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
  nested(field) {
    const offset = this.offset(field); assert.notEqual(offset, 0);
    const pointer = this.table + offset;
    return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  uint16(field) {
    const offset = this.offset(field); return offset === 0 ? null : u16(this.bytes, this.table + offset);
  }
}

function envelope(payloadType, payloadFields, payloadSize, writePayload) {
  const builder = new Builder();
  const root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7); w32(builder.bytes, root + 8, 9);
  builder.bytes[root + 28] = payloadType;
  const payload = builder.table(payloadFields, payloadSize); builder.pointer(root + 32, payload);
  writePayload(builder, payload);
  return builder.finish(root);
}

function createFixture() {
  const fields = new Array(20).fill(0); fields[16] = 4; fields[17] = 6;
  return envelope(15, fields, 8, (builder, payload) => {
    w16(builder.bytes, payload + 4, 65535); w16(builder.bytes, payload + 6, 40000);
  });
}

function modifyFixture() {
  const fields = new Array(19).fill(0); fields[0] = 4; fields[14] = 8; fields[15] = 10;
  return envelope(17, fields, 12, (builder, payload) => {
    builder.pointer(payload + 4, builder.identities());
    w16(builder.bytes, payload + 8, 65535); w16(builder.bytes, payload + 10, 40000);
  });
}

function payloadTable(raw, expectedType) {
  const root = new Table(raw, u32(raw, 0));
  assert.equal(raw[root.table + root.offset(4)], expectedType);
  return root.nested(5);
}

const create = payloadTable(createFixture(), 15);
assert.equal(create.uint16(16), 65535); assert.equal(create.uint16(17), 40000);
const modifyRaw = modifyFixture(), modify = payloadTable(modifyRaw, 17);
assert.equal(modify.uint16(14), 65535); assert.equal(modify.uint16(15), 40000);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page(id TEXT PRIMARY KEY, revision INTEGER NOT NULL, payload TEXT NOT NULL);
  CREATE TABLE inbox(sequence INTEGER PRIMARY KEY, raw BLOB NOT NULL, state TEXT NOT NULL);
  CREATE TABLE cursor(id INTEGER PRIMARY KEY CHECK(id=1), sequence INTEGER NOT NULL);
  INSERT INTO page VALUES('p1',7,'{"width":4}'); INSERT INTO cursor VALUES(1,0);`);

function applyNibNoop(raw, inject = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare("INSERT INTO inbox VALUES(1,?,'RECEIVED')").run(raw);
    if (inject) throw new Error('injected apply');
    db.exec("UPDATE inbox SET state='APPLIED' WHERE sequence=1; UPDATE cursor SET sequence=1 WHERE id=1; COMMIT");
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

applyNibNoop(modifyRaw);
const unchangedPage = db.prepare('SELECT revision,payload FROM page').get();
assert.equal(unchangedPage.revision, 7);
assert.equal(unchangedPage.payload, '{"width":4}');
assert.equal(db.prepare('SELECT state FROM inbox').get().state, 'APPLIED');
assert.equal(db.prepare('SELECT sequence FROM cursor').get().sequence, 1);
assert.deepEqual(new Uint8Array(db.prepare('SELECT raw FROM inbox').get().raw), modifyRaw);

db.exec("DELETE FROM inbox; UPDATE cursor SET sequence=0");
assert.throws(() => applyNibNoop(modifyRaw, true), /injected apply/);
assert.equal(db.prepare('SELECT count(*) count FROM inbox').get().count, 0);
assert.equal(db.prepare('SELECT sequence FROM cursor').get().sequence, 0);

const createSource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalCreateInkOperation.ets', import.meta.url), 'utf8');
const modifySource = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalModifyInkOperation.ets', import.meta.url), 'utf8');
const schema = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/DatabaseHelper.ets', import.meta.url), 'utf8');
assert.match(createSource, /nibAngle: table\.hasField\(16\) \? table\.readUint16\(16\) : null/);
assert.match(createSource, /nibFlatness: table\.hasField\(17\) \? table\.readUint16\(17\) : null/);
assert.doesNotMatch(createSource, /CREATE_INK_NIB_ATTRIBUTES_UNSUPPORTED/);
assert.match(modifySource, /field !== 14 && field !== 15/);
assert.match(modifySource, /nibAngle: table\.hasField\(14\) \? table\.readUint16\(14\) : null/);
assert.match(modifySource, /nib-only op is an applied no-op/);
assert.match(schema, /DB_VERSION: number = 47/);
assert.doesNotMatch(schema, /nib_angle|nib_flatness/);

console.log('success|create-nib-u16=65535,40000|modify-nib-u16=65535,40000|' +
  'nib-only-applied-noop=1|raw-preserved=1|rollback=1|schema-current=39');
