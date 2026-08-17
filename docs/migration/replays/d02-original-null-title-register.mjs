import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8').replace(/\r\n/g, '\n');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = name => fs.readFileSync(
  `${originalRoot}sources/defpackage/${name}.java`, 'utf8').replace(/\r\n/g, '\n');

let total = 0;
let failed = 0;
function check(label, condition) {
  total++;
  if (condition) {
    console.log(`PASS: ${label}`);
  } else {
    failed++;
    console.error(`FAIL: ${label}`);
  }
}

const l2d = original('l2d');
const z2d = original('z2d');
const rz1 = original('rz1');
const v69 = original('v69');
const a79 = original('a79');
const dhh = original('dhh');
const u5j = original('u5j');
const m09 = original('m09');
const cl9 = original('cl9');
const ft0 = original('ft0');
const e47 = original('e47');
const titleEvidence = read(
  'docs/migration/evidence/original-local-set-metadata-title-outbound-jadx-2026-08-16.md');

check('original validator only rejects empty or overlong non-null inner title strings',
  /z2dVarQ != null && \(strJ2 = z2dVarQ\.j\(\)\) != null/.test(l2d) &&
    /strJ2\.length\(\) == 0/.test(l2d) && /strJ2\.length\(\) > 256/.test(l2d));
check('original SetString accessor returns null when its inner field is absent',
  /public final String j\(\)[\s\S]*int iC = c\(4\)[\s\S]*return null;/.test(z2d));
check('original title register merge skips only an absent wrapper and writes its nullable value',
  /void O\([\s\S]*if \(z2dVar == null\)[\s\S]*\.c\(uq9Var, z2dVar\.j\(\)\)/.test(rz1));
check('original SET_METADATA dispatch sends field0 to the independent title register',
  /"titleRegister"[\s\S]*l2dVar\.q\(\)/.test(v69));
check('original NoteImpl title accessor itself is nullable',
  /public final String f\(\)[\s\S]*return \(String\) xj2\.v\(this\.t/.test(a79));
check('original dhh.a(null) still creates a SetString wrapper with an absent inner field',
  /int iC = str != null \? dbj\.c\(str, aVarA\) : 0/.test(dhh) &&
    /aVarA\.C\(1\)[\s\S]*aVarA\.h\(0, iC\)/.test(dhh));
check('original SetString snapshot serialization preserves nullable inner values',
  /if \(z2dVar\.j\(\) != null\)[\s\S]*iM = 0;[\s\S]*aVar\.h\(0, iM\)/.test(dhh));
check('original note snapshot rebuild wraps the nullable title register again',
  /strF = a79Var\.f\(\)[\s\S]*z2d z2dVarA = dhh\.a\(strF\)/.test(u5j));
check('original NOTE_BUNDLE initialization carries the latest nullable title through',
  /l2dVar\.q\(\)\) == null\) \? null : z2dVarQ\.j\(\)/.test(m09));
check('original import projects a still-null title to an empty display string, not New Note',
  /if \(strF == null\)[\s\S]*strF = "";/.test(cl9) && !/strF = "New Note"/.test(cl9));
check('original metadata aggregation keeps a winning SQL NULL as finalTitle',
  /WHEN ctd\.titleOpTimestamp IS NULL THEN som\.title/.test(ft0) &&
    /CASE WHEN ca\.hasTitle = 1 THEN ctd\.clientTitle ELSE NULL END/.test(ft0));
check('original Room title columns are nullable in synced, client and note metadata tables',
  /`SyncedOpMetadata`[\s\S]*`title` TEXT, `titleOpId`/.test(e47) &&
    /`ClientOp`[\s\S]*`hasTitle` INTEGER NOT NULL, `title` TEXT,/.test(e47) &&
    /`SyncedNoteMetadata`[\s\S]*`title` TEXT, `createdAt`/.test(e47));
check('tracked APK DEX evidence shows Undo reads a79.f and rewraps it through dhh.a',
  /La79;->f\(\)Ljava\/lang\/String;/.test(titleEvidence) &&
    /Ldhh;->a\(Ljava\/lang\/String;\)Lz2d;/.test(titleEvidence));

const policy = read('note/src/main/ets/core/model/OriginalNoteTitlePolicy.ets');
const database = read('note/src/main/ets/data/DatabaseHelper.ets');
const operation = read('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const encoder = read('note/src/main/ets/data/OriginalSetMetadataPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/OriginalNoteTitlePersistence.ets');
const codec = read('note/src/main/ets/data/NoteTitleMutationCodec.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');
const editor = read('note/src/main/ets/ui/editor/NotePage.ets');
const databaseFixture = read('note/src/test/DatabaseHelper.test.ets');
const payloadFixture = read('note/src/test/OriginalSetMetadataPayloadEncoder.test.ets');
const inboxFixture = read('note/src/test/SyncedOperationInbox.test.ets');
const persistentFixture = read('note/src/test/PersistentHistory.test.ets');

check('Harmony wire policy accepts null while retaining the 1 to 256 concrete range',
  /return value === null \|\| value\.length >= 1/.test(policy) &&
    /ORIGINAL_NOTE_TITLE_WIRE_MAX_LENGTH/.test(policy));
check('Harmony materializes a null register as an empty title projection',
  /materializeOriginalNoteTitle\(value: string \| null\)/.test(policy) &&
    /return value === null \? '' : value/.test(policy));
check('v66 rebuilds the title winner with a nullable constrained title column',
  /DB_VERSION: number = 66/.test(database) &&
    /original_note_title_winner_v66/.test(database) &&
    /title TEXT CHECK \(title IS NULL OR length\(title\) BETWEEN 1 AND 256\)/.test(database));
check('the reducer no longer drops a winning explicit-null title',
  /interface StoredNoteTitleWinner[\s\S]*title: string \| null/.test(operation) &&
    /if \(applyTitle\) \{[\s\S]*writeTitleWinner[\s\S]*materializeTitle/.test(operation) &&
    !/applyTitle && payload\.title !== null/.test(operation));
check('the reducer reads SQL NULL distinctly and projects it through search materialization',
  /rows\.isColumnNull\(titleColumn\) \? null/.test(operation) &&
    /const materialized: string = materializeOriginalNoteTitle\(title\)/.test(operation) &&
    /foldSearchText\(materialized\)/.test(operation));
check('the outbound encoder emits a present title wrapper with an absent inner field for null',
  /encodeOriginalSetMetadataTitle\(title: string \| null\)/.test(encoder) &&
    /if \(title === null\)/.test(encoder) &&
    /writeVtable\(bytes, setterVtable, 4, \[0\]\)/.test(encoder));
check('local persistence reads winner and projection together and histories register values',
  /LEFT JOIN original_note_title_winner winner/.test(persistence) &&
    /winner\.note_id AS winner_note_id/.test(persistence) &&
    /before: before\.registerValue, after: after\.registerValue/.test(persistence));
check('NTL2 writes nullable flags while the decoder keeps NTL1 compatibility',
  /MAGIC_V1[\s\S]*0x31/.test(codec) && /MAGIC_V2[\s\S]*0x32/.test(codec) &&
    /before: string \| null/.test(codec) && /if \(version === 1\)/.test(codec));
check('runtime and restored title actions both retain nullable register values',
  /titleBefore: string \| null/.test(undo) && /titleAfter: string \| null/.test(undo) &&
    /titleBefore: mutation\.before/.test(history));
check('editor Undo validates the display projection but writes the exact nullable target',
  /const title: string \| null = isUndo/.test(editor) &&
    /materializeOriginalNoteTitle\(source\)/.test(editor) &&
    /action\.titleBefore = persisted\.before/.test(editor));
check('ArkTS fixtures cover v66, explicit-null FlatBuffer, NTL2 and legacy NTL1',
  /expect\(DB_VERSION\)\.assertEqual\(66\)/.test(databaseFixture) &&
    /flatBufferSetMetadataNullTitle\(\)/.test(inboxFixture) &&
    /encodeOriginalSetMetadataTitle\(null\)/.test(payloadFixture) &&
    /decodes legacy NTL1/.test(payloadFixture) &&
    /titleBefore === null/.test(persistentFixture));

function migrationModel() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys = ON;
    CREATE TABLE note_meta(
      id TEXT PRIMARY KEY, title TEXT NOT NULL, structure_revision INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE search_item(
      note_id TEXT NOT NULL, type INTEGER NOT NULL, sub_id TEXT NOT NULL,
      folded_text TEXT NOT NULL, PRIMARY KEY(note_id, type, sub_id),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    CREATE TABLE original_note_title_winner(
      note_id TEXT PRIMARY KEY,
      winner_timestamp INTEGER NOT NULL,
      winner_site_id INTEGER NOT NULL,
      title TEXT NOT NULL CHECK(length(title) BETWEEN 1 AND 256),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO note_meta VALUES('note', 'Legacy', 0);
    INSERT INTO search_item VALUES('note', 0, 'note', 'legacy');
    INSERT INTO original_note_title_winner VALUES('note', 10, 1, 'Legacy');`);
  db.exec(`PRAGMA foreign_keys = OFF;
    BEGIN;
    CREATE TABLE original_note_title_winner_v66(
      note_id TEXT PRIMARY KEY,
      winner_timestamp INTEGER NOT NULL CHECK(winner_timestamp BETWEEN 0 AND 4294967295),
      winner_site_id INTEGER NOT NULL CHECK(winner_site_id BETWEEN 0 AND 65535),
      title TEXT CHECK(title IS NULL OR length(title) BETWEEN 1 AND 256),
      FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
    INSERT INTO original_note_title_winner_v66
      SELECT note_id, winner_timestamp, winner_site_id, title FROM original_note_title_winner;
    DROP TABLE original_note_title_winner;
    ALTER TABLE original_note_title_winner_v66 RENAME TO original_note_title_winner;
    COMMIT;
    PRAGMA foreign_keys = ON;`);
  return db;
}

const db = migrationModel();
const titleColumn = db.prepare("PRAGMA table_info('original_note_title_winner')").all()
  .find(column => column.name === 'title');
check('v66 migration preserves old concrete winners and makes the title column nullable',
  titleColumn?.notnull === 0 &&
    db.prepare("SELECT title FROM original_note_title_winner WHERE note_id='note'").get().title === 'Legacy');
check('v66 SQL constraint accepts null but still rejects empty and overlong concrete titles', (() => {
  db.exec("INSERT INTO note_meta VALUES('null-note', '', 0)");
  db.prepare('INSERT INTO original_note_title_winner VALUES(?,?,?,?)')
    .run('null-note', 1, 1, null);
  assert.throws(() => db.prepare('UPDATE original_note_title_winner SET title=? WHERE note_id=?')
    .run('', 'null-note'));
  assert.throws(() => db.prepare('UPDATE original_note_title_winner SET title=? WHERE note_id=?')
    .run('x'.repeat(257), 'null-note'));
  return true;
})());

function compareIdentity(timestamp, siteId, winner) {
  if (timestamp !== winner.winner_timestamp) {
    return timestamp < winner.winner_timestamp ? -1 : 1;
  }
  return siteId === winner.winner_site_id ? 0 : siteId < winner.winner_site_id ? -1 : 1;
}

function snapshot(dbValue) {
  return JSON.stringify({
    note: dbValue.prepare("SELECT * FROM note_meta WHERE id='note'").get(),
    winner: dbValue.prepare(
      "SELECT * FROM original_note_title_winner WHERE note_id='note'").get(),
    search: dbValue.prepare(
      "SELECT * FROM search_item WHERE note_id='note' AND type=0").get(),
  });
}

function applyTitle(dbValue, timestamp, siteId, title) {
  assert(title === null || title.length >= 1 && title.length <= 256);
  const winner = dbValue.prepare(
    "SELECT * FROM original_note_title_winner WHERE note_id='note'").get();
  const compared = winner === undefined ? 1 : compareIdentity(timestamp, siteId, winner);
  if (compared < 0) return false;
  if (compared === 0) {
    if (winner.title !== title) throw new Error('SET_METADATA_TITLE_IDENTITY_CONFLICT');
    return false;
  }
  const projection = title ?? '';
  dbValue.exec('BEGIN');
  try {
    dbValue.prepare(`INSERT INTO original_note_title_winner VALUES('note',?,?,?)
      ON CONFLICT(note_id) DO UPDATE SET
        winner_timestamp=excluded.winner_timestamp,
        winner_site_id=excluded.winner_site_id,title=excluded.title`).run(timestamp, siteId, title);
    dbValue.prepare(
      "UPDATE note_meta SET title=?,structure_revision=structure_revision+1 WHERE id='note'")
      .run(projection);
    dbValue.prepare(`INSERT INTO search_item VALUES('note',0,'note',?)
      ON CONFLICT(note_id,type,sub_id) DO UPDATE SET folded_text=excluded.folded_text`)
      .run(projection.toLocaleLowerCase());
    dbValue.exec('COMMIT');
    return true;
  } catch (error) {
    dbValue.exec('ROLLBACK');
    throw error;
  }
}

check('newer explicit-null wins and materializes empty note and search projections', (() => {
  assert.equal(applyTitle(db, 20, 1, null), true);
  const state = JSON.parse(snapshot(db));
  return state.winner.title === null && state.note.title === '' &&
    state.search.folded_text === '' && state.note.structure_revision === 1;
})());
check('a stale concrete title cannot overwrite the explicit-null winner', (() => {
  const before = snapshot(db);
  assert.equal(applyTitle(db, 19, 65535, 'Stale'), false);
  return snapshot(db) === before;
})());
check('same identity plus null is idempotent and does not advance revision', (() => {
  const before = snapshot(db);
  assert.equal(applyTitle(db, 20, 1, null), false);
  return snapshot(db) === before;
})());
check('same identity plus a different concrete value conflicts before any write', (() => {
  const before = snapshot(db);
  assert.throws(() => applyTitle(db, 20, 1, 'Conflict'), /IDENTITY_CONFLICT/);
  return snapshot(db) === before;
})());
check('site tie-break can replace null with a concrete title without inventing New Note', (() => {
  assert.equal(applyTitle(db, 20, 2, 'Recovered'), true);
  const state = JSON.parse(snapshot(db));
  return state.winner.title === 'Recovered' && state.note.title === 'Recovered' &&
    state.note.structure_revision === 2;
})());
check('nullable title winner keeps ON DELETE CASCADE after the v66 rebuild', (() => {
  db.exec("DELETE FROM note_meta WHERE id='null-note'");
  return db.prepare(
    "SELECT COUNT(*) count FROM original_note_title_winner WHERE note_id='null-note'").get().count === 0;
})());

function encodeSafeInteger(value) {
  const bytes = Buffer.alloc(8);
  bytes.writeUInt32LE(value % 0x100000000, 0);
  bytes.writeUInt32LE(Math.floor(value / 0x100000000), 4);
  return bytes;
}
function sized(value) {
  const bytes = Buffer.from(value, 'utf8');
  const result = Buffer.alloc(4 + bytes.length);
  result.writeUInt32LE(bytes.length, 0);
  bytes.copy(result, 4);
  return result;
}
function encodeNtl1(value) {
  return Buffer.concat([Buffer.from('NTL1'), encodeSafeInteger(value.fromRevision),
    encodeSafeInteger(value.toRevision), sized(value.selectedPageId), sized(value.before),
    sized(value.after)]);
}
function encodeNtl2(value) {
  const flags = (value.before === null ? 0 : 1) | (value.after === null ? 0 : 2);
  const parts = [Buffer.from('NTL2'), encodeSafeInteger(value.fromRevision),
    encodeSafeInteger(value.toRevision), sized(value.selectedPageId), Buffer.from([flags])];
  if (value.before !== null) parts.push(sized(value.before));
  if (value.after !== null) parts.push(sized(value.after));
  return Buffer.concat(parts);
}
function decodeMutation(bytes) {
  let offset = 0;
  const magic = bytes.subarray(offset, offset + 4).toString('ascii');
  offset += 4;
  function safeInteger() {
    const value = bytes.readUInt32LE(offset) + bytes.readUInt32LE(offset + 4) * 0x100000000;
    offset += 8;
    return value;
  }
  function stringValue() {
    const length = bytes.readUInt32LE(offset);
    offset += 4;
    const value = bytes.subarray(offset, offset + length).toString('utf8');
    offset += length;
    return value;
  }
  const result = { fromRevision: safeInteger(), toRevision: safeInteger(),
    selectedPageId: stringValue(), before: null, after: null };
  if (magic === 'NTL1') {
    result.before = stringValue();
    result.after = stringValue();
  } else {
    assert.equal(magic, 'NTL2');
    const flags = bytes[offset++];
    assert(flags >= 0 && flags <= 3);
    result.before = (flags & 1) === 0 ? null : stringValue();
    result.after = (flags & 2) === 0 ? null : stringValue();
  }
  assert.equal(offset, bytes.length);
  return result;
}

check('NTL2 model round-trips null to concrete and concrete to null mutations',
  assert.deepEqual(decodeMutation(encodeNtl2({ fromRevision: 4, toRevision: 5,
    selectedPageId: 'page', before: null, after: 'After' })),
  { fromRevision: 4, toRevision: 5, selectedPageId: 'page', before: null, after: 'After' }) === undefined &&
  assert.deepEqual(decodeMutation(encodeNtl2({ fromRevision: 5, toRevision: 6,
    selectedPageId: 'page', before: 'After', after: null })),
  { fromRevision: 5, toRevision: 6, selectedPageId: 'page', before: 'After', after: null }) === undefined);
check('NTL2 decoder model remains backward-compatible with durable NTL1 rows',
  assert.deepEqual(decodeMutation(encodeNtl1({ fromRevision: 8, toRevision: 9,
    selectedPageId: 'legacy', before: 'Before', after: 'After' })),
  { fromRevision: 8, toRevision: 9, selectedPageId: 'legacy', before: 'Before', after: 'After' }) === undefined);

function write16(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
}
function write32(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
  bytes[offset + 2] = value >>> 16 & 255;
  bytes[offset + 3] = value >>> 24 & 255;
}
function writeVtable(bytes, offset, objectSize, fields) {
  write16(bytes, offset, 4 + fields.length * 2);
  write16(bytes, offset + 2, objectSize);
  fields.forEach((field, index) => write16(bytes, offset + 4 + index * 2, field));
}
function encodeNullTitleTable() {
  const bytes = new Uint8Array(48);
  write32(bytes, 0, 24);
  writeVtable(bytes, 4, 8, [4, 0, 0, 0, 0, 0, 0, 0]);
  write32(bytes, 24, 20);
  write32(bytes, 28, 12);
  writeVtable(bytes, 32, 4, [0]);
  write32(bytes, 40, 8);
  return bytes;
}
function read16(bytes, offset) {
  return bytes[offset] | bytes[offset + 1] << 8;
}
function read32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}
function field(bytes, table, index) {
  const vtable = table - read32(bytes, table);
  const size = read16(bytes, vtable);
  return 4 + index * 2 < size ? read16(bytes, vtable + 4 + index * 2) : 0;
}
function tableField(bytes, table, index) {
  const fieldOffset = field(bytes, table, index);
  if (fieldOffset === 0) return null;
  const pointer = table + fieldOffset;
  return pointer + read32(bytes, pointer);
}
check('explicit-null FlatBuffer model has a title wrapper, no inner string and no background patch', (() => {
  const bytes = encodeNullTitleTable();
  const rootTable = read32(bytes, 0);
  const setter = tableField(bytes, rootTable, 0);
  return setter !== null && field(bytes, setter, 0) === 0 &&
    tableField(bytes, rootTable, 1) === null;
})());

db.close();

if (failed > 0) {
  console.error(`D02_ORIGINAL_NULL_TITLE_REGISTER_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_ORIGINAL_NULL_TITLE_REGISTER_OK TOTAL=${total} FAILED=0`);
