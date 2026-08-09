import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';

const MAX_OPS = 262144;
const NOTE_ID = '00112233-4455-6677-8899-aabbccddeeff';
const seq = (timestamp, site, index) => ({ timestamp, site, index });
const key = value => `${value.timestamp}:${value.site}:${value.index}`;
const opKey = value => `${value.timestamp}:${value.site}`;

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
    return value === null ? fallback : size === 1 ? value[0] : size === 2 ? u16(value, 0) : u32(value, 0);
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
  sequences(field) {
    const vector = this.pointer(field);
    if (vector === null) return [];
    const count = u32(this.bytes, vector);
    assert(count <= MAX_OPS);
    range(this.bytes, vector + 4, count * 12);
    return Array.from({ length: count }, (_, index) => {
      const position = vector + 4 + index * 12;
      return seq(u32(this.bytes, position + 4), u16(this.bytes, position), u32(this.bytes, position + 8));
    });
  }
}

class FixtureBuilder {
  constructor(size = 16384) {
    this.bytes = new Uint8Array(size);
    this.cursor = 4;
  }
  align(alignment) {
    while ((this.cursor & (alignment - 1)) !== 0) this.cursor++;
  }
  table(fieldOffsets, objectSize) {
    const vtable = this.cursor;
    const vtableSize = 4 + fieldOffsets.length * 2;
    this.cursor += vtableSize;
    this.align(4);
    const table = this.cursor;
    this.cursor += objectSize;
    w16(this.bytes, vtable, vtableSize);
    w16(this.bytes, vtable + 2, objectSize);
    fieldOffsets.forEach((value, index) => w16(this.bytes, vtable + 4 + index * 2, value));
    w32(this.bytes, table, table - vtable);
    return table;
  }
  pointer(pointer, target) {
    assert(target > pointer);
    w32(this.bytes, pointer, target - pointer);
  }
  byteVector(values) {
    this.align(4);
    const vector = this.cursor;
    this.cursor += 4 + values.length + 1;
    w32(this.bytes, vector, values.length);
    this.bytes.set(values, vector + 4);
    return vector;
  }
  sequenceVector(values) {
    this.align(4);
    const vector = this.cursor;
    this.cursor += 4 + values.length * 12;
    w32(this.bytes, vector, values.length);
    values.forEach((value, index) => writeSequence(this.bytes, vector + 4 + index * 12, value));
    return vector;
  }
  tableVector(count) {
    this.align(4);
    const vector = this.cursor;
    this.cursor += 4 + count * 4;
    w32(this.bytes, vector, count);
    return vector;
  }
  finish(root) {
    w32(this.bytes, 0, root);
    return this.bytes.slice(0, this.cursor);
  }
}

function buildBundle(operations) {
  const builder = new FixtureBuilder();
  const root = builder.table([4, 0, 20, 24, 0, 28, 32, 36], 40);
  builder.bytes.set([0xff,0xee,0xdd,0xcc,0xbb,0xaa,0x99,0x88,
    0x77,0x66,0x55,0x44,0x33,0x22,0x11,0], root + 4);
  w16(builder.bytes, root + 20, 9);
  w16(builder.bytes, root + 36, 7);
  builder.pointer(root + 24, builder.byteVector([0x65]));
  builder.pointer(root + 28, builder.byteVector([0x63]));
  const operationVector = builder.tableVector(operations.length);
  builder.pointer(root + 32, operationVector);
  operations.forEach((operation, index) => {
    const operationTable = builder.table([4,12,20,0,28,32,0], 36);
    builder.pointer(operationVector + 4 + index * 4, operationTable);
    w16(builder.bytes, operationTable + 4, operation.site);
    w32(builder.bytes, operationTable + 8, operation.timestamp);
    w64(builder.bytes, operationTable + 12, BigInt(operation.timestamp));
    w64(builder.bytes, operationTable + 20, BigInt(operation.timestamp + 1000));
    builder.bytes[operationTable + 28] = operation.type;
    const payload = buildPayload(builder, operation);
    builder.pointer(operationTable + 32, payload);
  });
  return builder.finish(root);
}

function buildPayload(builder, operation) {
  if (operation.type === 3) {
    const offsets = [operation.location === undefined ? 0 : 4, 0, 16, 0];
    const table = builder.table(offsets, 20);
    if (operation.location !== undefined) writeSequence(builder.bytes, table + 4, operation.location);
    w32(builder.bytes, table + 16, operation.count ?? 1);
    return table;
  }
  if (operation.type === 4) {
    const table = builder.table([4,8,0,0], 12);
    const pages = builder.sequenceVector(operation.pages);
    builder.pointer(table + 4, pages);
    const move = builder.table(operation.target === undefined ? [0] : [4],
      operation.target === undefined ? 4 : 16);
    if (operation.target !== undefined) writeSequence(builder.bytes, move + 4, operation.target);
    builder.pointer(table + 8, move);
    return table;
  }
  assert.equal(operation.type, 25);
  const offsets = [0,0,operation.deletes.length === 0 ? 0 : 4,
    operation.undeletes.length === 0 ? 0 : 8];
  const table = builder.table(offsets, 12);
  if (operation.deletes.length > 0)
    builder.pointer(table + 4, builder.sequenceVector(operation.deletes));
  if (operation.undeletes.length > 0)
    builder.pointer(table + 8, builder.sequenceVector(operation.undeletes));
  return table;
}

function decodeBundle(bytes) {
  const root = new Table(bytes, u32(bytes, 0));
  const uuid = root.inline(0, 16);
  assert(uuid !== null && root.offset(3) !== 0 && root.offset(5) !== 0 && root.offset(6) !== 0);
  const operations = root.tables(6, MAX_OPS).map(payloadTable => {
    const id = payloadTable.inline(0, 8);
    const payload = payloadTable.tableField(5);
    assert(id !== null && payload !== null);
    return {
      timestamp: u32(id, 4), site: u16(id, 0), type: payloadTable.scalar(4, 1),
      client: payloadTable.decimal(1, '0'), server: payloadTable.decimal(2), payload,
    };
  });
  const high = leHex(uuid, 8, 8), low = leHex(uuid, 0, 8), value = high + low;
  return {
    noteId: `${value.slice(0,8)}-${value.slice(8,12)}-${value.slice(12,16)}-` +
      `${value.slice(16,20)}-${value.slice(20)}`,
    editorSite: root.scalar(2, 2), schema: root.scalar(7, 2), operations,
  };
}

function createPayload(operation) {
  const location = operation.payload.inline(0, 12);
  return {
    location: location === null ? null : readSequence(location, 0),
    count: operation.payload.scalar(2, 4, 1),
  };
}

function modifyPayload(operation) {
  const move = operation.payload.tableField(1);
  const target = move?.inline(0, 12) ?? null;
  return { pages: operation.payload.sequences(0), hasMove: move !== null,
    target: target === null ? null : readSequence(target, 0),
    background: operation.payload.offset(2) !== 0, bookmarked: operation.payload.offset(3) !== 0 };
}

function deletePayload(operation) {
  return { deletes: operation.payload.sequences(2), undeletes: operation.payload.sequences(3) };
}

function replay(bundle) {
  const creates = [], groups = [], pages = new Map(), positions = new Set(), winners = new Map();
  for (const operation of bundle.operations.filter(value => value.type === 3)) {
    const payload = createPayload(operation);
    assert(payload.count > 0 && payload.count <= 10000);
    const identities = Array.from({ length: payload.count }, (_, index) =>
      seq(operation.timestamp, operation.site, index));
    for (const identity of identities) {
      assert(!pages.has(key(identity)) && !positions.has(key(identity)));
      pages.set(key(identity), { identity, visibility: null });
      positions.add(key(identity));
      winners.set(key(identity), { timestamp: operation.timestamp, site: operation.site, index: identity.index });
    }
    creates.push({ operation, parent: payload.location, pages: identities });
    groups.push({ operation, parent: payload.location,
      positions: identities.map(identity => ({ position: identity, page: identity })) });
  }
  const pending = [];
  for (const operation of bundle.operations.filter(value => value.type === 4)) {
    const payload = modifyPayload(operation);
    if (!payload.hasMove || payload.background || payload.bookmarked || payload.pages.length === 0)
      return { reason: 'unsupported-modify' };
    if (new Set(payload.pages.map(key)).size !== payload.pages.length) return { reason: 'repeat-page' };
    if (payload.pages.some(page => !pages.has(key(page)))) return { reason: 'missing-page' };
    pending.push({ operation, payload });
  }
  while (pending.length > 0) {
    let progressed = false;
    for (let index = 0; index < pending.length;) {
      const { operation, payload } = pending[index];
      if (payload.target !== null && !positions.has(key(payload.target))) { index++; continue; }
      const entries = payload.pages.map((page, positionIndex) => {
        const position = seq(operation.timestamp, operation.site, positionIndex);
        assert(!positions.has(key(position))); positions.add(key(position));
        const old = winners.get(key(page));
        if (compareOp(operation, old) >= 0)
          winners.set(key(page), { timestamp: operation.timestamp, site: operation.site, index: positionIndex });
        return { position, page };
      });
      groups.push({ operation, parent: payload.target, positions: entries });
      pending.splice(index, 1); progressed = true;
    }
    if (!progressed) return { reason: 'missing-target' };
  }
  for (const operation of bundle.operations.filter(value => value.type === 25)) {
    const payload = deletePayload(operation);
    for (const [values, deleted] of [[payload.deletes,true],[payload.undeletes,false]]) {
      for (const identity of values) {
        const page = pages.get(key(identity));
        if (page === undefined) return { reason: 'visibility-page-missing' };
        if (page.visibility === null || compareOp(operation, page.visibility) >= 0)
          page.visibility = { timestamp: operation.timestamp, site: operation.site, deleted };
      }
    }
  }
  const children = new Map();
  for (const group of groups) {
    assert(group.parent === null || positions.has(key(group.parent)));
    const parent = group.parent === null ? 'ROOT' : key(group.parent);
    children.set(parent, [...(children.get(parent) ?? []), group]);
  }
  for (const siblings of children.values())
    siblings.sort((left,right) => -compareSeq(left.positions.at(-1).position,right.positions.at(-1).position));
  const order = [], visited = new Set();
  const append = parent => {
    for (const group of children.get(parent) ?? []) {
      assert(!visited.has(opKey(group.operation))); visited.add(opKey(group.operation));
      for (const entry of group.positions) {
        const winner = winners.get(key(entry.page)), page = pages.get(key(entry.page));
        if (winner.timestamp === entry.position.timestamp && winner.site === entry.position.site &&
          winner.index === entry.position.index && page.visibility?.deleted !== true) order.push(entry.page);
        append(key(entry.position));
      }
    }
  };
  append('ROOT');
  assert.equal(visited.size, groups.length);
  assert.equal(new Set(order.map(key)).size, order.length);
  assert.equal(order.length, [...pages.values()].filter(page => page.visibility?.deleted !== true).length);
  return { reason: null, creates, groups, pages, winners, order };
}

function database(pageIds) {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE page_info(page_id TEXT PRIMARY KEY,note_id TEXT,page_index INTEGER,UNIQUE(note_id,page_index));
    CREATE TABLE operation_log(note_id TEXT,op_type INTEGER);
    CREATE TABLE original_page_insert_group(note_id TEXT,op_timestamp INTEGER,op_site_id INTEGER,
      parent_timestamp INTEGER,parent_site_id INTEGER,parent_index INTEGER,page_count INTEGER,modified_time TEXT,
      PRIMARY KEY(note_id,op_timestamp,op_site_id));
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,seq_index INTEGER,
      page_id TEXT,visible INTEGER,PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index),UNIQUE(note_id,page_id));
    CREATE TABLE original_page_position_group(note_id TEXT,op_timestamp INTEGER,op_site_id INTEGER,
      parent_timestamp INTEGER,parent_site_id INTEGER,parent_index INTEGER,position_count INTEGER,modified_time TEXT,
      PRIMARY KEY(note_id,op_timestamp,op_site_id));
    CREATE TABLE original_page_position(note_id TEXT,pos_timestamp INTEGER,pos_site_id INTEGER,pos_index INTEGER,
      page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      PRIMARY KEY(note_id,pos_timestamp,pos_site_id,pos_index));
    CREATE TABLE original_page_position_winner(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      winner_timestamp INTEGER,winner_site_id INTEGER,position_index INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_page_visibility_winner(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      winner_timestamp INTEGER,winner_site_id INTEGER,deleted INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,
      page_id TEXT,PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    INSERT INTO note_meta VALUES('${NOTE_ID}');`);
  const insert = db.prepare('INSERT INTO page_info VALUES(?,?,?)');
  pageIds.forEach((pageId, index) => insert.run(pageId, NOTE_ID, index));
  return db;
}

function applyIdentity(db, bundle, failAt = '') {
  const history = replay(bundle);
  if (history.reason !== null) return { applied: false, reason: history.reason };
  const live = db.prepare('SELECT page_id FROM page_info WHERE note_id=? ORDER BY page_index').all(NOTE_ID);
  if (live.length !== history.order.length) return { applied: false, reason: 'page-count' };
  if (db.prepare('SELECT COUNT(*) count FROM operation_log WHERE note_id=? AND op_type IN(1,2,3)')
    .get(NOTE_ID).count !== 0) return { applied: false, reason: 'local-diverged' };
  const pageIds = new Map(history.order.map((identity,index) => [key(identity),live[index].page_id]));
  if (mappingMatches(db, history, pageIds)) return { applied: false, reason: null };
  if (mappingCount(db) !== 0) return { applied: false, reason: 'identity-conflict' };
  db.exec('BEGIN IMMEDIATE');
  try {
    const insertCreate = db.prepare('INSERT INTO original_page_insert_group VALUES(?,?,?,?,?,?,?,?)');
    for (const group of history.creates) insertCreate.run(NOTE_ID,group.operation.timestamp,group.operation.site,
      group.parent?.timestamp??null,group.parent?.site??null,group.parent?.index??null,
      group.pages.length,group.operation.server??group.operation.client);
    const insertIdentity = db.prepare('INSERT INTO original_page_identity VALUES(?,?,?,?,?,?)');
    for (const page of history.pages.values()) insertIdentity.run(NOTE_ID,page.identity.timestamp,page.identity.site,
      page.identity.index,pageIds.get(key(page.identity))??null,pageIds.has(key(page.identity))?1:0);
    const insertGroup = db.prepare('INSERT INTO original_page_position_group VALUES(?,?,?,?,?,?,?,?)');
    const insertPosition = db.prepare('INSERT INTO original_page_position VALUES(?,?,?,?,?,?,?)');
    for (const group of history.groups) {
      insertGroup.run(NOTE_ID,group.operation.timestamp,group.operation.site,
        group.parent?.timestamp??null,group.parent?.site??null,group.parent?.index??null,
        group.positions.length,group.operation.server??group.operation.client);
      for (const entry of group.positions) insertPosition.run(NOTE_ID,entry.position.timestamp,entry.position.site,
        entry.position.index,entry.page.timestamp,entry.page.site,entry.page.index);
    }
    if (failAt === 'positions') throw new Error('injected');
    const insertWinner = db.prepare('INSERT INTO original_page_position_winner VALUES(?,?,?,?,?,?,?)');
    const insertVisibility = db.prepare('INSERT INTO original_page_visibility_winner VALUES(?,?,?,?,?,?,?)');
    for (const page of history.pages.values()) {
      const winner = history.winners.get(key(page.identity));
      insertWinner.run(NOTE_ID,page.identity.timestamp,page.identity.site,page.identity.index,
        winner.timestamp,winner.site,winner.index);
      if (page.visibility !== null) insertVisibility.run(NOTE_ID,page.identity.timestamp,page.identity.site,
        page.identity.index,page.visibility.timestamp,page.visibility.site,page.visibility.deleted?1:0);
    }
    db.exec('COMMIT'); return { applied: true, reason: null };
  } catch (error) { db.exec('ROLLBACK'); throw error; }
}

function mappingCount(db) {
  return ['original_page_insert_group','original_page_identity','original_page_position_group',
    'original_page_position','original_page_position_winner','original_page_visibility_winner','original_deleted_page']
    .reduce((total,table)=>total+db.prepare(`SELECT COUNT(*) count FROM ${table}`).get().count,0);
}

function mappingMatches(db, history, pageIds) {
  if (mappingCount(db) === 0) return false;
  if (db.prepare('SELECT COUNT(*) count FROM original_page_insert_group').get().count !== history.creates.length ||
    db.prepare('SELECT COUNT(*) count FROM original_page_identity').get().count !== history.pages.size ||
    db.prepare('SELECT COUNT(*) count FROM original_page_position_group').get().count !== history.groups.length ||
    db.prepare('SELECT COUNT(*) count FROM original_page_position').get().count !==
      history.groups.reduce((sum,group)=>sum+group.positions.length,0) ||
    db.prepare('SELECT COUNT(*) count FROM original_page_visibility_winner').get().count !==
      [...history.pages.values()].filter(page=>page.visibility!==null).length ||
    db.prepare('SELECT COUNT(*) count FROM original_deleted_page').get().count !== 0) return false;
  for (const page of history.pages.values()) {
    const row = db.prepare(`SELECT page_id,visible FROM original_page_identity WHERE note_id=?
      AND seq_timestamp=? AND seq_site_id=? AND seq_index=?`).get(NOTE_ID,page.identity.timestamp,
      page.identity.site,page.identity.index);
    if (row === undefined || row.page_id !== (pageIds.get(key(page.identity))??null) ||
      row.visible !== (pageIds.has(key(page.identity))?1:0)) return false;
    const winner = history.winners.get(key(page.identity));
    const stored = db.prepare(`SELECT winner_timestamp timestamp,winner_site_id site,position_index
      FROM original_page_position_winner WHERE note_id=? AND page_timestamp=? AND page_site_id=? AND page_index=?`)
      .get(NOTE_ID,page.identity.timestamp,page.identity.site,page.identity.index);
    if (stored?.timestamp!==winner.timestamp||stored?.site!==winner.site||stored?.position_index!==winner.index) return false;
  }
  return true;
}

const A=seq(10,1,0),B=seq(10,1,1),C=seq(10,1,2),D=seq(11,1,0),MOVE_B=seq(50,2,0);
const operations = [
  { type:4,timestamp:50,site:2,pages:[B] },
  { type:3,timestamp:10,site:1,count:3 },
  { type:3,timestamp:11,site:1,count:1,location:B },
  { type:4,timestamp:40,site:9,pages:[B] },
  { type:25,timestamp:60,site:2,deletes:[B],undeletes:[] },
  { type:3,timestamp:61,site:1,count:1,location:MOVE_B },
  { type:25,timestamp:70,site:2,deletes:[],undeletes:[B] },
  { type:25,timestamp:80,site:2,deletes:[],undeletes:[C] },
  { type:25,timestamp:75,site:9,deletes:[C],undeletes:[] },
  { type:25,timestamp:90,site:2,deletes:[D],undeletes:[D] },
  { type:25,timestamp:100,site:2,deletes:[A],undeletes:[] },
];
const bytes = buildBundle(operations);
const bundle = decodeBundle(bytes);
assert.equal(bundle.noteId,NOTE_ID); assert.deepEqual([bundle.editorSite,bundle.schema],[9,7]);
assert.deepEqual(bundle.operations.map(operation=>operation.type),operations.map(operation=>operation.type));
const history = replay(bundle);
assert.equal(history.reason,null);
assert.deepEqual(history.order.map(key),['10:1:1','61:1:0','11:1:0','10:1:2']);
assert.deepEqual(history.winners.get(key(B)),{ timestamp:50,site:2,index:0 });
assert.deepEqual(history.pages.get(key(C)).visibility,{ timestamp:80,site:2,deleted:false });
assert.deepEqual(history.pages.get(key(D)).visibility,{ timestamp:90,site:2,deleted:false });
assert.deepEqual(history.pages.get(key(A)).visibility,{ timestamp:100,site:2,deleted:true });
assert.equal(unboundPageRemainsDeleted(history.pages.get(key(A)),seq(110,2,0),[A],[]),true);
assert.equal(unboundPageRemainsDeleted(history.pages.get(key(A)),seq(90,9,0),[],[A]),true);
assert.equal(unboundPageRemainsDeleted(history.pages.get(key(A)),seq(110,2,0),[],[A]),false);
assert.equal(unboundPageRemainsDeleted(history.pages.get(key(A)),seq(110,2,0),[A],[A]),false);

const db=database(['live-b','live-e','live-d','live-c']);
assert.deepEqual(applyIdentity(db,bundle),{ applied:true,reason:null });
assert.deepEqual(db.prepare(`SELECT seq_timestamp,seq_index,page_id,visible FROM original_page_identity
  ORDER BY seq_timestamp,seq_index`).all().map(row=>[row.seq_timestamp,row.seq_index,row.page_id,row.visible]),
  [[10,0,null,0],[10,1,'live-b',1],[10,2,'live-c',1],[11,0,'live-d',1],[61,0,'live-e',1]]);
const storedMoveWinner=db.prepare(`SELECT winner_timestamp,winner_site_id FROM original_page_position_winner
  WHERE page_timestamp=10 AND page_index=1`).get();
assert.deepEqual([storedMoveWinner.winner_timestamp,storedMoveWinner.winner_site_id],[50,2]);
const storedDeletedAnchor=db.prepare(`SELECT parent_timestamp,parent_site_id,parent_index
  FROM original_page_position_group WHERE op_timestamp=61`).get();
assert.deepEqual([storedDeletedAnchor.parent_timestamp,storedDeletedAnchor.parent_site_id,
  storedDeletedAnchor.parent_index],[50,2,0]);
assert.equal(db.prepare(`SELECT page_id FROM original_page_identity WHERE seq_timestamp=10 AND seq_index=0`).get().page_id,null);
assert.deepEqual(applyIdentity(db,bundle),{ applied:false,reason:null });
assert.equal(db.prepare('PRAGMA foreign_key_check').all().length,0);

const countMismatch=database(['one']);
assert.deepEqual(applyIdentity(countMismatch,bundle),{ applied:false,reason:'page-count' });
const diverged=database(['live-b','live-e','live-d','live-c']);
diverged.prepare('INSERT INTO operation_log VALUES(?,3)').run(NOTE_ID);
assert.deepEqual(applyIdentity(diverged,bundle),{ applied:false,reason:'local-diverged' });
const rollback=database(['live-b','live-e','live-d','live-c']);
assert.throws(()=>applyIdentity(rollback,bundle,'positions'),/injected/);
assert.equal(mappingCount(rollback),0);
const conflict=database(['live-b','live-e','live-d','live-c']);
assert.deepEqual(applyIdentity(conflict,bundle),{ applied:true,reason:null });
conflict.prepare(`UPDATE original_page_position_winner SET winner_timestamp=49
  WHERE page_timestamp=10 AND page_index=1`).run();
assert.deepEqual(applyIdentity(conflict,bundle),{ applied:false,reason:'identity-conflict' });

const missingBundle=decodeBundle(buildBundle([
  { type:3,timestamp:10,site:1,count:1 },
  { type:4,timestamp:20,site:1,pages:[seq(99,1,0)] },
]));
assert.equal(replay(missingBundle).reason,'missing-page');

console.log('success|note-bundle=r29|flatbuffer-history=11|create=3|pending-move=1|losing-move=1|delete-undelete=1|same-payload=1|losing-visibility=1|deleted-anchor=1|tombstone-unbound=1|repeat-tombstone=1|unbound-undelete-deferred=1|final-order=1|idempotent=1|count-deferred=1|local-diverged=1|conflict=1|missing-deferred=1|rollback=1');

function unboundPageRemainsDeleted(page,operation,deletes,undeletes) {
  assert(page.visibility !== null && page.visibility.deleted);
  let deleted=page.visibility.deleted;
  if(compareOp(operation,page.visibility)>=0&&deletes.some(value=>key(value)===key(page.identity))) deleted=true;
  if(compareOp(operation,page.visibility)>=0&&undeletes.some(value=>key(value)===key(page.identity))) deleted=false;
  return deleted;
}

function compareOp(left,right) {
  if (left.timestamp!==right.timestamp) return left.timestamp<right.timestamp?-1:1;
  return left.site===right.site?0:left.site<right.site?-1:1;
}
function javaInt(value) { return value>=0x80000000?value-0x100000000:value; }
function compareSeq(left,right) {
  const timestamp=(javaInt(left.timestamp)-javaInt(right.timestamp))|0;
  if (timestamp!==0) return Math.sign(timestamp);
  if (left.site!==right.site) return left.site<right.site?-1:1;
  return Math.sign((javaInt(right.index)-javaInt(left.index))|0);
}
function readSequence(bytes,offset) { return seq(u32(bytes,offset+4),u16(bytes,offset),u32(bytes,offset+8)); }
function writeSequence(bytes,offset,value) { w16(bytes,offset,value.site); w32(bytes,offset+4,value.timestamp); w32(bytes,offset+8,value.index); }
function leHex(bytes,start,count) { return [...bytes.slice(start,start+count)].reverse().map(v=>v.toString(16).padStart(2,'0')).join(''); }
function range(bytes,offset,size) { assert(offset>=0&&size>=0&&offset+size<=bytes.length); }
function u16(bytes,offset) { range(bytes,offset,2); return bytes[offset]+bytes[offset+1]*0x100; }
function u32(bytes,offset) { range(bytes,offset,4); return bytes[offset]+bytes[offset+1]*0x100+bytes[offset+2]*0x10000+bytes[offset+3]*0x1000000; }
function i32(bytes,offset) { const value=u32(bytes,offset); return value>=0x80000000?value-0x100000000:value; }
function w16(bytes,offset,value) { bytes[offset]=value&255; bytes[offset+1]=value>>>8; }
function w32(bytes,offset,value) { for(let i=0;i<4;i++) bytes[offset+i]=Math.floor(value/2**(i*8))&255; }
function w64(bytes,offset,value) { for(let i=0;i<8;i++){bytes[offset+i]=Number(value&255n);value>>=8n;} }
