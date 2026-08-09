import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const MAX_OPS = 262144;

class Table {
  constructor(bytes, table) {
    this.bytes = bytes;
    this.table = table;
    const distance = i32(bytes, table);
    assert(distance > 0 && distance <= table);
    this.vtable = table - distance;
    this.vtableSize = u16(bytes, this.vtable);
    this.objectSize = u16(bytes, this.vtable + 2);
    assert(this.vtableSize >= 4 && (this.vtableSize & 1) === 0 && this.objectSize >= 4);
    range(bytes, this.vtable, this.vtableSize);
    range(bytes, table, this.objectSize);
  }
  offset(field) {
    const entry = this.vtable + 4 + field * 2;
    return entry + 2 <= this.vtable + this.vtableSize ? u16(this.bytes, entry) : 0;
  }
  inline(field, size) {
    const offset = this.offset(field);
    if (offset === 0) return null;
    assert(offset >= 4 && offset + size <= this.objectSize);
    return this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  scalar(field, size, fallback = 0) {
    const value = this.inline(field, size);
    return value === null ? fallback : size === 1 ? value[0] : u16(value, 0);
  }
  decimal(field, fallback = null) {
    const value = this.inline(field, 8);
    if (value === null) return fallback;
    let result = 0n;
    for (let index = 7; index >= 0; index--) result = result * 256n + BigInt(value[index]);
    return result.toString();
  }
  pointer(field) {
    const offset = this.offset(field);
    if (offset === 0) return null;
    const pointer = this.table + offset;
    const relative = u32(this.bytes, pointer);
    assert(relative >= 4 && pointer + relative <= this.bytes.length - 4);
    return pointer + relative;
  }
  tableField(field) {
    const pointer = this.pointer(field);
    return pointer === null ? null : new Table(this.bytes, pointer);
  }
  tables(field, maximum) {
    const vector = this.pointer(field);
    if (vector === null) return [];
    const count = u32(this.bytes, vector);
    assert(count <= maximum);
    range(this.bytes, vector + 4, count * 4);
    return Array.from({ length: count }, (_, index) => {
      const slot = vector + 4 + index * 4;
      return new Table(this.bytes, slot + u32(this.bytes, slot));
    });
  }
}

function decodeBundle(bytes) {
  const root = new Table(bytes, u32(bytes, 0));
  const uuid = root.inline(0, 16);
  assert(uuid !== null && root.offset(3) !== 0 && root.offset(5) !== 0 && root.offset(6) !== 0);
  const operations = root.tables(6, MAX_OPS).map(table => {
    const id = table.inline(0, 8);
    const payload = table.tableField(5);
    assert(id !== null && payload !== null);
    return {
      timestamp: u32(id, 4), site: u16(id, 0), type: table.scalar(4, 1),
      client: table.decimal(1, '0'), server: table.decimal(2), payload,
    };
  });
  const high = leHex(uuid, 8, 8), low = leHex(uuid, 0, 8), value = high + low;
  return {
    noteId: `${value.slice(0, 8)}-${value.slice(8, 12)}-${value.slice(12, 16)}-` +
      `${value.slice(16, 20)}-${value.slice(20)}`,
    editorSite: root.scalar(2, 2), schema: root.scalar(7, 2), operations,
  };
}

function createPayload(operation) {
  const location = operation.payload.inline(0, 12);
  return {
    location: location === null ? null : seq(u32(location, 4), u16(location, 0), u32(location, 8)),
    count: operation.payload.offset(2) === 0 ? 1 : u32(operation.payload.bytes,
      operation.payload.table + operation.payload.offset(2)),
  };
}

function materialize(bundle) {
  if (bundle.operations.some(operation => operation.type === 4)) return { reason: 'modify-page' };
  const groups = bundle.operations.filter(operation => operation.type === 3).map(operation => {
    const payload = createPayload(operation);
    assert(payload.count > 0 && payload.count <= 10000);
    return { operation, location: payload.location,
      pages: Array.from({ length: payload.count }, (_, index) => seq(operation.timestamp, operation.site, index)),
      modified: operation.server ?? operation.client };
  });
  const all = new Set(groups.flatMap(group => group.pages.map(key)));
  const children = new Map();
  for (const group of groups) {
    assert(group.location === null || all.has(key(group.location)));
    const parent = group.location === null ? 'ROOT' : key(group.location);
    children.set(parent, [...(children.get(parent) ?? []), group]);
  }
  for (const siblings of children.values()) {
    siblings.sort((left, right) => -compare(left.pages.at(-1), right.pages.at(-1)));
  }
  const order = [], visited = new Set();
  const append = parent => {
    for (const group of children.get(parent) ?? []) {
      const op = `${group.operation.timestamp}:${group.operation.site}`;
      assert(!visited.has(op));
      visited.add(op);
      for (const page of group.pages) {
        order.push(page);
        append(key(page));
      }
    }
  };
  append('ROOT');
  assert.equal(visited.size, groups.length);
  return { reason: null, groups, order };
}

function applyIdentity(db, bundle, failAfterGroup = false) {
  const tree = materialize(bundle);
  if (tree.reason !== null) return { applied: false, reason: tree.reason };
  const pages = db.prepare(`SELECT page_id FROM page_info WHERE note_id=? ORDER BY page_index`).all(bundle.noteId);
  if (pages.length !== tree.order.length) return { applied: false, reason: 'page-count' };
  const divergent = db.prepare(`SELECT COUNT(*) count FROM operation_log WHERE note_id=?
    AND op_type IN (1,2,3)`).get(bundle.noteId).count;
  if (divergent !== 0) return { applied: false, reason: 'local-diverged' };
  const existing = db.prepare(`SELECT COUNT(*) count FROM original_page_insert_group WHERE note_id=?`).get(bundle.noteId).count;
  if (existing !== 0) return { applied: false, reason: null };
  db.exec('BEGIN IMMEDIATE');
  try {
    const insertGroup = db.prepare(`INSERT INTO original_page_insert_group VALUES(?,?,?,?,?,?,?,?)`);
    const insertIdentity = db.prepare(`INSERT INTO original_page_identity VALUES(?,?,?,?,?,1)`);
    for (const group of tree.groups) {
      insertGroup.run(bundle.noteId, group.operation.timestamp, group.operation.site,
        group.location?.timestamp ?? null, group.location?.site ?? null,
        group.location?.index ?? null, group.pages.length, group.modified);
      if (failAfterGroup) throw new Error('injected');
    }
    const pageBySequence = new Map(tree.order.map((identity, index) => [key(identity), pages[index].page_id]));
    for (const group of tree.groups) for (const page of group.pages) {
      insertIdentity.run(bundle.noteId, page.timestamp, page.site, page.index, pageBySequence.get(key(page)));
    }
    db.exec('COMMIT');
    return { applied: true, reason: null };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function database(noteId) {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE page_info(page_id TEXT PRIMARY KEY,note_id TEXT,page_index INTEGER,UNIQUE(note_id,page_index));
    CREATE TABLE operation_log(note_id TEXT,op_type INTEGER);
    CREATE TABLE deferred_bundle(id INTEGER PRIMARY KEY,note_id TEXT,payload BLOB);
    CREATE TABLE original_page_insert_group(note_id TEXT,op_timestamp INTEGER,op_site_id INTEGER,
      parent_timestamp INTEGER,parent_site_id INTEGER,parent_index INTEGER,page_count INTEGER,modified_time TEXT,
      PRIMARY KEY(note_id,op_timestamp,op_site_id));
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,seq_index INTEGER,
      page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    INSERT INTO note_meta VALUES('${noteId}');
    INSERT INTO page_info VALUES('page-a','${noteId}',0),('page-b','${noteId}',1);`);
  return db;
}

function buildBundle() {
  const bytes = new Uint8Array(260);
  w32(bytes, 0, 24); w16(bytes, 4, 20); w16(bytes, 6, 40);
  [4, 0, 20, 24, 0, 28, 32, 36].forEach((value, index) => w16(bytes, 8 + index * 2, value));
  w32(bytes, 24, 20);
  bytes.set([0xff,0xee,0xdd,0xcc,0xbb,0xaa,0x99,0x88,0x77,0x66,0x55,0x44,0x33,0x22,0x11,0], 28);
  w16(bytes, 44, 9); w32(bytes, 48, 20); w32(bytes, 52, 24); w32(bytes, 56, 28); w16(bytes, 60, 7);
  w32(bytes, 68, 1); bytes[72] = 0x65; w32(bytes, 76, 1); bytes[80] = 0x63;
  w32(bytes, 84, 2); w32(bytes, 88, 28); w32(bytes, 92, 80);
  writeOperation(bytes, 96, 116, 1, 10, 11n, 12n, 220);
  writeOperation(bytes, 152, 172, 2, 20, 21n, 22n, 240);
  w16(bytes, 208, 10); w16(bytes, 210, 8); w16(bytes, 216, 4); w32(bytes, 220, 12); w32(bytes, 224, 1);
  w16(bytes, 228, 10); w16(bytes, 230, 20); w16(bytes, 232, 4); w16(bytes, 236, 16); w32(bytes, 240, 12);
  w16(bytes, 244, 1); w32(bytes, 248, 10); w32(bytes, 252, 0); w32(bytes, 256, 1);
  return bytes;
}

function writeOperation(bytes, vtable, table, site, timestamp, client, server, payload) {
  w16(bytes, vtable, 18); w16(bytes, vtable + 2, 36);
  [4,12,20,0,28,32,0].forEach((value, index) => w16(bytes, vtable + 4 + index * 2, value));
  w32(bytes, table, table - vtable); w16(bytes, table + 4, site); w32(bytes, table + 8, timestamp);
  w64(bytes, table + 12, client); w64(bytes, table + 20, server); bytes[table + 28] = 3;
  w32(bytes, table + 32, payload - table - 32);
}

const bytes = buildBundle();
const bundle = decodeBundle(bytes);
assert.equal(bundle.noteId, '00112233-4455-6677-8899-aabbccddeeff');
assert.deepEqual([bundle.editorSite, bundle.schema], [9, 7]);
assert.deepEqual(bundle.operations.map(op => [op.timestamp, op.site, op.client, op.server]),
  [[10,1,'11','12'],[20,2,'21','22']]);
assert.deepEqual(materialize(bundle).order.map(key), ['10:1:0','20:2:0']);

const db = database(bundle.noteId);
db.prepare(`INSERT INTO deferred_bundle VALUES(1,?,?)`).run(bundle.noteId, bytes);
assert.deepEqual(applyIdentity(db, bundle), { applied: true, reason: null });
assert.deepEqual(db.prepare(`SELECT seq_timestamp,page_id FROM original_page_identity ORDER BY seq_timestamp`).all()
  .map(row => [row.seq_timestamp, row.page_id]), [[10, 'page-a'], [20, 'page-b']]);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM deferred_bundle`).get().count, 1);
assert.deepEqual(applyIdentity(db, bundle), { applied: false, reason: null });

const divergent = database(bundle.noteId);
divergent.prepare(`INSERT INTO operation_log VALUES(?,3)`).run(bundle.noteId);
assert.deepEqual(applyIdentity(divergent, bundle), { applied: false, reason: 'local-diverged' });
assert.equal(divergent.prepare(`SELECT COUNT(*) count FROM original_page_identity`).get().count, 0);

const rollback = database(bundle.noteId);
assert.throws(() => applyIdentity(rollback, bundle, true), /injected/);
assert.equal(rollback.prepare(`SELECT COUNT(*) count FROM original_page_insert_group`).get().count, 0);

const modifiedBytes = bytes.slice(); modifiedBytes[200] = 4;
assert.deepEqual(materialize(decodeBundle(modifiedBytes)), { reason: 'modify-page' });
console.log('success|note-bundle=r29|uuid=1|nested-ops=2|identity-map=2|idempotent=1|raw-preserved=1|local-diverged=1|modify-deferred=1|rollback=1');

function seq(timestamp, site, index) { return { timestamp, site, index }; }
function key(value) { return `${value.timestamp}:${value.site}:${value.index}`; }
function javaInt(value) { return value >= 0x80000000 ? value - 0x100000000 : value; }
function compare(left, right) {
  const timestamp = (javaInt(left.timestamp) - javaInt(right.timestamp)) | 0;
  if (timestamp !== 0) return Math.sign(timestamp);
  if (left.site !== right.site) return left.site < right.site ? -1 : 1;
  return Math.sign((javaInt(right.index) - javaInt(left.index)) | 0);
}
function leHex(bytes, start, count) { return [...bytes.slice(start, start + count)].reverse().map(v => v.toString(16).padStart(2,'0')).join(''); }
function range(bytes, offset, size) { assert(offset >= 0 && size >= 0 && offset + size <= bytes.length); }
function u16(bytes, offset) { range(bytes, offset, 2); return bytes[offset] + bytes[offset + 1] * 0x100; }
function u32(bytes, offset) { range(bytes, offset, 4); return bytes[offset] + bytes[offset+1]*0x100 + bytes[offset+2]*0x10000 + bytes[offset+3]*0x1000000; }
function i32(bytes, offset) { const value = u32(bytes, offset); return value >= 0x80000000 ? value - 0x100000000 : value; }
function w16(bytes, offset, value) { bytes[offset] = value & 255; bytes[offset+1] = value >>> 8; }
function w32(bytes, offset, value) { for (let i=0;i<4;i++) bytes[offset+i] = Math.floor(value / 2 ** (i*8)) & 255; }
function w64(bytes, offset, value) { for (let i=0;i<8;i++) { bytes[offset+i] = Number(value & 255n); value >>= 8n; } }
