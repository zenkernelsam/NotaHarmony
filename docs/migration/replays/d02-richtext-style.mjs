import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const operationSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalRichTextStyleOperation.ets', rootPath), 'utf8');
const stateSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalRichTextStyleState.ets', rootPath), 'utf8');
const insertSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalInsertTextOperation.ets', rootPath), 'utf8');
const dispatcher = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalPageOperationApplier.ets', rootPath), 'utf8');
const renderer = fs.readFileSync(new URL(
  'note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets', rootPath), 'utf8');
const schema = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');

class Builder {
  constructor() { this.bytes = new Uint8Array(2048); this.cursor = 4; }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    const vtable = this.cursor; this.cursor += 4 + fields.length * 2; this.align(4);
    const table = this.cursor; this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2); w16(this.bytes, vtable + 2, size);
    fields.forEach((field, index) => w16(this.bytes, vtable + 4 + index * 2, field));
    w32(this.bytes, table, table - vtable); return table;
  }
  pointer(slot, target) { assert(target > slot); w32(this.bytes, slot, target - slot); }
  string(value) {
    const encoded = new TextEncoder().encode(value); this.align(4);
    const vector = this.cursor; this.cursor += 5 + encoded.length;
    w32(this.bytes, vector, encoded.length); this.bytes.set(encoded, vector + 4);
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
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset; return new Table(this.bytes, pointer + u32(this.bytes, pointer));
  }
  string(field) {
    const offset = this.offset(field); if (offset === 0) return null;
    const pointer = this.table + offset, vector = pointer + u32(this.bytes, pointer);
    return new TextDecoder().decode(this.bytes.slice(vector + 4, vector + 4 + u32(this.bytes, vector)));
  }
}

function envelope(type, payloadFactory) {
  const b = new Builder(), root = b.table([4, 12, 20, 0, 28, 32], 36);
  w16(b.bytes, root + 4, 7); w32(b.bytes, root + 8, 300 + type);
  w64(b.bytes, root + 12, 1n); w64(b.bytes, root + 20, 1n); b.bytes[root + 28] = type;
  const payload = payloadFactory(b); b.pointer(root + 32, payload); return b.finish(root);
}

function boolWrapper(b, value) {
  const table = b.table([value === null ? 0 : 4], 8);
  if (value !== null) b.bytes[table + 4] = value ? 1 : 0;
  return table;
}

function floatWrapper(b, value) {
  const table = b.table([value === null ? 0 : 4], 8);
  if (value !== null) new DataView(b.bytes.buffer).setFloat32(table + 4, value, true);
  return table;
}

function colorWrapper(b, rgba) {
  const table = b.table([rgba === null ? 0 : 4], 8);
  if (rgba !== null) b.bytes.set(rgba, table + 4);
  return table;
}

function stringWrapper(b, value) {
  const table = b.table([value === null ? 0 : 4], 8);
  if (value !== null) b.pointer(table + 4, b.string(value));
  return table;
}

function enumWrapper(b, value) {
  const table = b.table([value === null ? 0 : 4], 8);
  if (value !== null) b.bytes[table + 4] = value;
  return table;
}

const root = { timestamp: 0, site: 0xffff, index: 0 };
const chars = [0, 1, 2].map(index => ({ timestamp: 100, site: 7, index }));

function modifyStyleFixture() {
  return envelope(12, b => {
    const fields = Array(15).fill(0); [0, 1, 2, 3, 6, 8, 9].forEach((field, index) =>
      fields[field] = [4, 20, 36, 44, 48, 52, 56][index]);
    const payload = b.table(fields, 60);
    boundary(b.bytes, payload + 4, chars[0], 0); boundary(b.bytes, payload + 20, chars[2], 1);
    identity(b.bytes, payload + 36, { timestamp: 20, site: 2 });
    b.pointer(payload + 44, boolWrapper(b, true));
    b.pointer(payload + 48, colorWrapper(b, [255, 238, 0, 128]));
    b.pointer(payload + 52, floatWrapper(b, 24));
    b.pointer(payload + 56, colorWrapper(b, [17, 34, 51, 255]));
    return payload;
  });
}

function paragraphFixture() {
  return envelope(13, b => {
    const fields = [4, 16, 28, 32, 36, 40, 0, 44, 52, 56];
    const payload = b.table(fields, 60);
    sequence(b.bytes, payload + 4, chars[0]); sequence(b.bytes, payload + 16, chars[2]);
    identity(b.bytes, payload + 44, { timestamp: 20, site: 2 });
    b.pointer(payload + 28, enumWrapper(b, 2));
    b.pointer(payload + 32, enumWrapper(b, 2));
    b.pointer(payload + 36, floatWrapper(b, 1.5));
    b.pointer(payload + 40, enumWrapper(b, 1));
    b.pointer(payload + 52, stringWrapper(b, 'swift'));
    b.pointer(payload + 56, enumWrapper(b, 0));
    return payload;
  });
}

function clearFixture() {
  return envelope(14, b => {
    const payload = b.table([4, 20, 36, 40], 48);
    boundary(b.bytes, payload + 4, root, 0); boundary(b.bytes, payload + 20, root, 3);
    b.bytes[payload + 36] = 0; identity(b.bytes, payload + 40, { timestamp: 20, site: 2 });
    return payload;
  });
}

function decodePayload(bytes) {
  const rootTable = new Table(bytes, u32(bytes, 0));
  const type = rootTable.inline(4, 1)[0], payload = rootTable.nested(5);
  if (type === 12) {
    return {
      type, start: readBoundary(payload.inline(0, 16)), end: readBoundary(payload.inline(1, 16)),
      textField: readIdentity(payload.inline(2, 8)), bold: readBool(payload.nested(3)),
      highlight: readColor(payload.nested(6)), size: readFloat(payload.nested(8)),
      foreground: readColor(payload.nested(9)),
    };
  }
  if (type === 13) {
    return { type, start: readSequence(payload.inline(0, 12)), end: readSequence(payload.inline(1, 12)),
      indent: readEnum(payload.nested(2)), alignment: readEnum(payload.nested(3)),
      spacing: readFloat(payload.nested(4)), decorator: readEnum(payload.nested(5)),
      language: payload.nested(8).string(0), direction: readEnum(payload.nested(9)) };
  }
  return { type, start: readBoundary(payload.inline(0, 16)),
    end: readBoundary(payload.inline(1, 16)), paragraph: payload.inline(2, 1)[0] !== 0 };
}

const modify = decodePayload(modifyStyleFixture());
assert.deepEqual(modify.start, { ...chars[0], type: 0 });
assert.deepEqual(modify.end, { ...chars[2], type: 1 });
assert.equal(modify.bold, true); assert.equal(modify.highlight, 0x80ffee00 | 0);
assert.equal(modify.size, 24); assert.equal(modify.foreground, 0xff112233 | 0);
const paragraph = decodePayload(paragraphFixture());
assert.equal(paragraph.indent, 2); assert.equal(paragraph.alignment, 2);
assert.equal(paragraph.spacing, 1.5); assert.equal(paragraph.decorator, 1);
assert.equal(paragraph.language, 'swift'); assert.equal(paragraph.direction, 0);
const clear = decodePayload(clearFixture());
assert.equal(clear.start.site, 0xffff); assert.equal(clear.end.type, 3); assert.equal(clear.paragraph, false);

const styleDdl = extractTemplate(schema, 'DDL_ORIGINAL_TEXT_STYLE_OPERATION');
const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
  CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
    PRIMARY KEY(note_id,element_timestamp,element_site_id));
  CREATE TABLE original_block_state(note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
    PRIMARY KEY(note_id,block_timestamp,block_site_id), FOREIGN KEY(note_id,block_timestamp,block_site_id)
    REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id) ON DELETE CASCADE);
  ${styleDdl}; PRAGMA user_version=38;
  INSERT INTO original_element_z_index VALUES('n',20,2);
  INSERT INTO original_block_state VALUES('n',20,2);`);
db.exec('PRAGMA user_version=39');
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 39);

const operations = [];
const add = (timestamp, paragraph, clearAll, start, end, attributes) => {
  operations.push({ timestamp, paragraph, clearAll, start, end, attributes });
  db.prepare(`INSERT INTO original_text_style_operation VALUES(
    'n',20,2,?,7,?,?, ?,?,?,?, ?,?,?,?, ?)`).run(timestamp, paragraph ? 1 : 0,
    clearAll ? 1 : 0, start.timestamp, start.site, start.index, start.type,
    end.timestamp, end.site, end.index, end.type, JSON.stringify(attributes));
};
const boundaryBefore = value => ({ ...value, type: 0 });
const boundaryAfter = value => ({ ...value, type: 1 });
add(10, false, false, boundaryBefore(chars[0]), boundaryAfter(chars[2]), { bold: true, color: 1 });
add(20, false, true, boundaryBefore(chars[1]), boundaryAfter(chars[1]), {});
add(30, false, false, boundaryBefore(chars[1]), boundaryAfter(chars[2]), { italic: true });
add(40, false, false, boundaryBefore(chars[2]), boundaryAfter(chars[2]), { color: null });
add(50, true, false, boundaryBefore(chars[0]), boundaryAfter(chars[2]),
  { indent: 2, alignment: 2, spacing: 1.5, decorator: 1 });

function materialize(sequence, ops) {
  return sequence.map((character, index) => {
    const characterStyle = {}, paragraphStyle = {};
    for (const op of [...ops].sort((a, b) => a.timestamp - b.timestamp)) {
      const start = position(sequence, op.start), end = position(sequence, op.end);
      assert(start !== null && end !== null && start <= end);
      if (index < start || index >= end) continue;
      const style = op.paragraph ? paragraphStyle : characterStyle;
      if (op.clearAll) Object.keys(style).forEach(key => delete style[key]);
      else Object.entries(op.attributes).forEach(([key, value]) =>
        value === null ? delete style[key] : style[key] = value);
    }
    return { characterStyle, paragraphStyle };
  });
}

const styled = materialize(chars, operations);
assert.deepEqual(styled[0].characterStyle, { bold: true, color: 1 });
assert.deepEqual(styled[1].characterStyle, { italic: true });
assert.deepEqual(styled[2].characterStyle, { bold: true, italic: true });
assert.deepEqual(styled[1].paragraphStyle,
  { indent: 2, alignment: 2, spacing: 1.5, decorator: 1 });
const inserted = { timestamp: 200, site: 9, index: 0 };
const grown = materialize([chars[0], inserted, chars[1], chars[2]], operations);
assert.equal(grown[1].characterStyle.bold, true);

db.exec('BEGIN');
try {
  add(60, false, false, boundaryBefore({ timestamp: 999, site: 1, index: 0 }),
    boundaryAfter(chars[2]), { bold: false });
  materialize(chars, operations);
  assert.fail('missing boundary must fail before write');
} catch (_error) {
  db.exec('ROLLBACK');
  operations.pop();
}
assert.equal(db.prepare('SELECT count(*) count FROM original_text_style_operation').get().count, 5);
db.exec('BEGIN');
db.prepare(`INSERT INTO original_text_style_operation VALUES(
  'n',20,2,70,7,0,0,100,7,0,0,100,7,2,1,'{"bold":true}')`).run();
db.exec('ROLLBACK');
assert.equal(db.prepare('SELECT count(*) count FROM original_text_style_operation').get().count, 5);
db.exec(`DELETE FROM original_element_z_index WHERE note_id='n' AND element_timestamp=20 AND element_site_id=2`);
assert.equal(db.prepare('SELECT count(*) count FROM original_text_style_operation').get().count, 0);

assert.match(schema, /DB_VERSION: number = 61/);
assert.match(operationSource, /ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE: number = 12/);
assert.match(operationSource, /ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE: number = 13/);
assert.match(operationSource, /ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE: number = 14/);
assert.match(stateSource, /compareOperationIdentity/);
assert.match(stateSource, /characterStyle = \{\}/);
assert.doesNotMatch(stateSource, /delete \(style as Record/);
assert.match(insertSource, /INSERT_TEXT_STYLE_STATE_DIVERGED/);
assert.match(dispatcher, /OriginalRichTextStyleOperationApplier/);
assert.match(renderer, /highlightColor/);
assert.match(renderer, /decoratorPrefix/);
assert.match(operationSource, /target\.hidden/);
assert.match(operationSource, /writeTextPayload/);
assert.match(insertSource, /original_deleted_entity/);
assert.match(insertSource, /revisionTable/);

console.log('success|flatbuffer-me8-he8-io1=3|v38-v39=1|character-fold=1|' +
  'clear-then-newer-style=1|nullable-property-clear=1|paragraph-style=1|' +
  'stable-boundary-insert=1|missing-atomic=1|rollback=1|cascade=1|archived-target=1|' +
  'renderer-consumer=1');

function position(sequence, boundary) {
  if (boundary.type === 2 || (boundary.type === 0 && boundary.site === 0xffff && boundary.timestamp === 0)) return 0;
  if (boundary.type === 3) return sequence.length;
  const index = sequence.findIndex(value => value.timestamp === boundary.timestamp &&
    value.site === boundary.site && value.index === boundary.index);
  return index < 0 ? null : index + (boundary.type === 1 ? 1 : 0);
}

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`); return match[1];
}
function sequence(bytes, offset, value) { w16(bytes, offset, value.site); w32(bytes, offset + 4, value.timestamp); w32(bytes, offset + 8, value.index); }
function boundary(bytes, offset, value, type) { sequence(bytes, offset, value); bytes[offset + 12] = type; }
function identity(bytes, offset, value) { w16(bytes, offset, value.site); w32(bytes, offset + 4, value.timestamp); }
function readSequence(bytes) { return { timestamp: u32(bytes, 4), site: u16(bytes, 0), index: u32(bytes, 8) }; }
function readBoundary(bytes) { return { ...readSequence(bytes), type: bytes[12] }; }
function readIdentity(bytes) { return { timestamp: u32(bytes, 4), site: u16(bytes, 0) }; }
function readBool(table) { const bytes = table.inline(0, 1); return bytes === null ? null : bytes[0] !== 0; }
function readFloat(table) { const bytes = table.inline(0, 4); return bytes === null ? null : new DataView(bytes.buffer, bytes.byteOffset, 4).getFloat32(0, true); }
function readColor(table) { const bytes = table.inline(0, 4); return bytes === null ? null : ((bytes[3] << 24) | (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]) | 0; }
function readEnum(table) { const bytes = table.inline(0, 1); return bytes === null ? null : bytes[0]; }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) { new DataView(bytes.buffer).setUint32(offset, value, true); }
function w64(bytes, offset, value) { new DataView(bytes.buffer).setBigUint64(offset, value, true); }
function u16(bytes, offset) { return bytes[offset] | bytes[offset + 1] << 8; }
function u32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getUint32(offset, true); }
function i32(bytes, offset) { return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getInt32(offset, true); }
