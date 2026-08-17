import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = name => fs.readFileSync(`${originalRoot}sources/defpackage/${name}.java`, 'utf8');

const de4 = original('de4');
const dp = original('dp');
const xj2 = original('xj2');
const l2d = original('l2d');
const z2d = original('z2d');
const dhh = original('dhh');
const v69 = original('v69');
const vnf = original('vnf');
const zm7 = original('zm7');
const originalStrings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

assert.match(de4, /lvd\.b1\(200, a00Var\.J\)/);
assert.match(de4, /strB1\.length\(\) < a00Var\.J\.length\(\)/);
assert.match(dp, /if \(strB1\.length\(\) == 0\)[\s\S]*feature_note__default_title/);
assert.match(dp, /if \(length3 > 200\)[\s\S]*lvd\.b1\(200, strB1\)/);
assert.match(dp, /xj2\.d\(dhh\.a\(strB1\), null, null, null, null, null, null, null, 510\)/);
assert.match(xj2, /aVar\.h\(0, numValueOf\.intValue\(\)\)/);
assert.match(xj2, /aVar\.h\(1, numValueOf2\.intValue\(\)\)/);
assert.match(l2d, /Title cannot be empty/);
assert.match(l2d, /strJ2\.length\(\) > 256/);
assert.match(l2d, /int iC = c\(4\)[\s\S]*z2dVar\.d/);
assert.match(z2d, /int iC = c\(4\)/);
assert.match(dhh, /aVarA\.C\(1\)[\s\S]*aVarA\.h\(0, iC\)/);
assert.match(v69, /"titleRegister"[\s\S]*l2dVar\.q\(\)/);
assert.match(vnf, /Method not decompiled: defpackage\.vnf\.c/);
assert.match(zm7, /xj2\.d\(dhh\.a\(\(String\) obj4\), qgh\.b\(\(nz9\) obj3\)/);
assert.match(originalStrings, /<string name="feature_note__default_title">New Note<\/string>/);

const policy = read('note/src/main/ets/core/model/OriginalNoteTitlePolicy.ets');
const encoder = read('note/src/main/ets/data/OriginalSetMetadataPayloadEncoder.ets');
const reducer = read('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const persistence = read('note/src/main/ets/data/OriginalNoteTitlePersistence.ets');
const repository = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const editor = read('note/src/main/ets/ui/editor/NotePage.ets');
const library = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const fixtures = read('note/src/test/OriginalSetMetadataPayloadEncoder.test.ets');
const persistentFixtures = read('note/src/test/PersistentHistory.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

assert.match(policy, /ORIGINAL_NOTE_TITLE_EDIT_MAX_LENGTH: number = 200/);
assert.match(policy, /ORIGINAL_NOTE_TITLE_WIRE_MAX_LENGTH: number = 256/);
assert.match(policy, /ORIGINAL_NOTE_DEFAULT_TITLE: string = 'New Note'/);
assert.match(policy, /before >= 0xD800[\s\S]*after >= 0xDC00/);
assert.doesNotMatch(policy, /\.trim\(/);
assert.match(encoder, /l2d SetMetadata\.field0 -> z2d SetString\.field0 -> UTF-8 title/);
assert.match(encoder, /writeVtable\(bytes, rootVtable, 8, \[4, 0, 0, 0, 0, 0, 0, 0\]\)/);
assert.match(encoder, /writeVtable\(bytes, setterVtable, 8, \[4\]\)/);
assert.match(reducer, /if \(!hasMetadataField\(payload\)\)/);
assert.match(reducer, /payload\.hasPageBackground[\s\S]*readBackgroundWinner/);
assert.match(reducer, /payload\.hasTitle[\s\S]*readTitleWinner/);
assert.match(reducer, /foldSearchText\(materialized\)/);
assert.match(persistence, /OriginalSetMetadataOperationApplier\(\)\.apply/);
assert.match(persistence, /opType: OpType\.ORIGINAL_SET_METADATA/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /opType: OpType\.UPDATE_TITLE/);
assert.match(persistence, /Math\.max\(current, updatedAt\)/);
assert.match(repository, /persistOriginalNoteTitle/);
assert.match(repository, /updateNoteTitle\(/);
assert.match(history, /OpType\.UPDATE_TITLE/);
assert.match(history, /UndoableActionType\.NOTE_TITLE/);
assert.match(history, /operation\.opType === OpType\.ORIGINAL_SET_METADATA/);
assert.match(editor, /commitOriginalNoteTitleDraft\(this\.titleDraft\)/);
assert.match(editor, /this\.titleSaveQueue = queued\.catch/);
assert.match(editor, /await this\.titleSaveQueue/);
assert.match(editor, /generation === this\.titleSaveGeneration && !this\.editingTitle/);
assert.match(editor, /repository\.updateNoteTitle/);
assert.match(editor, /runtime history sync failed after durable commit/);
assert.match(library, /createNote\(ORIGINAL_NOTE_DEFAULT_TITLE, folderId\)/);
assert.match(opTypes, /UPDATE_TITLE = 30/);
assert.match(opTypes, /ORIGINAL_SET_METADATA = 78/);
assert.match(fixtures, /writes a title-only SetMetadata without resetting note background/);
assert.match(fixtures, /mirrors original title draft and empty-submit policy/);
assert.match(fixtures, /round-trips NTL2 nullable title history and decodes legacy NTL1/);
assert.match(persistentFixtures, /restores note title history after its original SET_METADATA row/);
assert.match(fixtureList, /originalSetMetadataPayloadEncoderTest\(\)/);

const utf8 = new TextEncoder();
const utf8Fatal = new TextDecoder('utf-8', { fatal: true });
const align4 = value => (value + 3) & ~3;

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

function read16(bytes, offset) {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function read32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}

function writeVtable(bytes, offset, objectSize, fields) {
  write16(bytes, offset, 4 + fields.length * 2);
  write16(bytes, offset + 2, objectSize);
  fields.forEach((field, index) => write16(bytes, offset + 4 + index * 2, field));
}

function encodeTitle(title) {
  assert(title.length >= 1 && title.length <= 256, 'wire title must have 1..256 UTF-16 units');
  const value = utf8.encode(title);
  assert(value.length >= 1 && value.length <= 1024);
  assert.equal(utf8Fatal.decode(value), title, 'wire title must be valid Unicode');
  const bytes = new Uint8Array(align4(48 + 4 + value.length + 1));
  write32(bytes, 0, 24);
  writeVtable(bytes, 4, 8, [4, 0, 0, 0, 0, 0, 0, 0]);
  write32(bytes, 24, 20);
  write32(bytes, 28, 12);
  writeVtable(bytes, 32, 8, [4]);
  write32(bytes, 40, 8);
  write32(bytes, 44, 4);
  write32(bytes, 48, value.length);
  bytes.set(value, 52);
  bytes[52 + value.length] = 0;
  return bytes;
}

function field(bytes, table, index) {
  const vtable = table - read32(bytes, table);
  const size = read16(bytes, vtable);
  return 4 + index * 2 < size ? read16(bytes, vtable + 4 + index * 2) : 0;
}

function tableField(bytes, table, index) {
  const offset = field(bytes, table, index);
  if (offset === 0) return null;
  const pointer = table + offset;
  return pointer + read32(bytes, pointer);
}

function stringField(bytes, table, index) {
  const offset = field(bytes, table, index);
  assert.notEqual(offset, 0);
  const pointer = table + offset;
  const vector = pointer + read32(bytes, pointer);
  const length = read32(bytes, vector);
  assert.equal(bytes[vector + 4 + length], 0);
  return utf8Fatal.decode(bytes.slice(vector + 4, vector + 4 + length));
}

function decodeTitle(bytes) {
  const rootTable = read32(bytes, 0);
  const setter = tableField(bytes, rootTable, 0);
  assert.notEqual(setter, null, 'SetMetadata.title wrapper must be present');
  assert.equal(tableField(bytes, rootTable, 1), null,
    'title-only SetMetadata must leave pageBackground absent');
  return stringField(bytes, setter, 0);
}

assert.equal(decodeTitle(encodeTitle('标题 😀')), '标题 😀');
assert.equal(decodeTitle(encodeTitle(' '.repeat(3))), '   ');
assert.equal(decodeTitle(encodeTitle('x'.repeat(256))).length, 256);
assert.throws(() => encodeTitle(''), /wire title/);
assert.throws(() => encodeTitle('x'.repeat(257)), /wire title/);

function truncateDraft(value) {
  if (value.length <= 200) return value;
  let end = 200;
  const before = value.charCodeAt(end - 1);
  const after = value.charCodeAt(end);
  if (before >= 0xD800 && before <= 0xDBFF && after >= 0xDC00 && after <= 0xDFFF) end--;
  return value.slice(0, end);
}

function commitDraft(value) {
  const truncated = truncateDraft(value);
  return truncated.length === 0 ? 'New Note' : truncated;
}

assert.equal(commitDraft(''), 'New Note');
assert.equal(commitDraft('   '), '   ');
assert.equal(commitDraft('x'.repeat(201)).length, 200);
assert.equal(commitDraft('x'.repeat(199) + '😀'), 'x'.repeat(199));

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE note_meta(
    id TEXT PRIMARY KEY, title TEXT NOT NULL, updated_at INTEGER NOT NULL,
    structure_revision INTEGER NOT NULL);
  CREATE TABLE page_info(note_id TEXT NOT NULL, page_id TEXT NOT NULL,
    PRIMARY KEY(note_id,page_id));
  CREATE TABLE title_winner(note_id TEXT PRIMARY KEY, winner_ts INTEGER NOT NULL,
    winner_site INTEGER NOT NULL, title TEXT NOT NULL);
  CREATE TABLE background_winner(note_id TEXT PRIMARY KEY, winner_ts INTEGER NOT NULL,
    winner_site INTEGER NOT NULL, value TEXT);
  CREATE TABLE search_item(note_id TEXT NOT NULL, type INTEGER NOT NULL,
    sub_id TEXT NOT NULL, folded_text TEXT NOT NULL, PRIMARY KEY(note_id,type,sub_id));
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,
    kind TEXT NOT NULL, upload INTEGER NOT NULL, history TEXT, title TEXT NOT NULL);
  INSERT INTO note_meta VALUES('note','New Note',5000,0);
  INSERT INTO page_info VALUES('note','page-1');
  INSERT INTO background_winner VALUES('note',7,3,'A4-grid');
  INSERT INTO search_item VALUES('note',0,'note','new note');`);

function compareIdentity(timestamp, site, winner) {
  if (timestamp !== winner.winner_ts) return timestamp < winner.winner_ts ? -1 : 1;
  return site === winner.winner_site ? 0 : site < winner.winner_site ? -1 : 1;
}

function applySetMetadata({ timestamp, site, hasTitle, title, hasBackground, background }) {
  let changed = false;
  if (hasTitle) {
    assert(title.length >= 1 && title.length <= 256);
    const winner = db.prepare('SELECT * FROM title_winner WHERE note_id=?').get('note');
    if (winner === undefined || compareIdentity(timestamp, site, winner) > 0) {
      db.prepare(`INSERT INTO title_winner VALUES('note',?,?,?)
        ON CONFLICT(note_id) DO UPDATE SET winner_ts=excluded.winner_ts,
          winner_site=excluded.winner_site,title=excluded.title`).run(timestamp, site, title);
      db.prepare("UPDATE note_meta SET title=? WHERE id='note'").run(title);
      db.prepare(`INSERT INTO search_item VALUES('note',0,'note',?)
        ON CONFLICT(note_id,type,sub_id) DO UPDATE SET folded_text=excluded.folded_text`)
        .run(title.toLocaleLowerCase());
      changed = true;
    } else if (compareIdentity(timestamp, site, winner) === 0 && winner.title !== title) {
      throw new Error('SET_METADATA_TITLE_IDENTITY_CONFLICT');
    }
  }
  if (hasBackground) {
    const winner = db.prepare('SELECT * FROM background_winner WHERE note_id=?').get('note');
    if (winner === undefined || compareIdentity(timestamp, site, winner) > 0) {
      db.prepare(`INSERT INTO background_winner VALUES('note',?,?,?)
        ON CONFLICT(note_id) DO UPDATE SET winner_ts=excluded.winner_ts,
          winner_site=excluded.winner_site,value=excluded.value`).run(timestamp, site, background);
      changed = true;
    } else if (compareIdentity(timestamp, site, winner) === 0 && winner.value !== background) {
      throw new Error('SET_METADATA_BACKGROUND_IDENTITY_CONFLICT');
    }
  }
  if (changed) db.prepare("UPDATE note_meta SET structure_revision=structure_revision+1 WHERE id='note'").run();
}

function persistTitle(requested, timestamp, clientTime, historyId, injectFailure = false) {
  assert(db.prepare("SELECT 1 ok FROM page_info WHERE note_id='note' AND page_id='page-1'").get());
  const before = db.prepare("SELECT title,updated_at,structure_revision FROM note_meta WHERE id='note'").get();
  assert.notEqual(before.title, requested);
  db.exec('BEGIN IMMEDIATE');
  try {
    applySetMetadata({ timestamp, site: 9, hasTitle: true, title: requested,
      hasBackground: false, background: null });
    const after = db.prepare("SELECT title,updated_at,structure_revision FROM note_meta WHERE id='note'").get();
    assert.equal(after.title, requested);
    assert.equal(after.structure_revision, before.structure_revision + 1);
    db.prepare("UPDATE note_meta SET updated_at=MAX(updated_at,?) WHERE id='note'").run(clientTime);
    if (injectFailure) throw new Error('injected after reducer');
    db.prepare('INSERT INTO operation_log(kind,upload,history,title) VALUES(?,?,NULL,?)')
      .run('ORIGINAL_SET_METADATA', 1, requested);
    db.prepare('INSERT INTO operation_log(kind,upload,history,title) VALUES(?,?,?,?)')
      .run('UPDATE_TITLE', 0, historyId, requested);
    db.exec('COMMIT');
    return { before: before.title, after: requested };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function snapshot() {
  return JSON.stringify({
    note: db.prepare('SELECT * FROM note_meta').all(),
    title: db.prepare('SELECT * FROM title_winner').all(),
    background: db.prepare('SELECT * FROM background_winner').all(),
    search: db.prepare('SELECT * FROM search_item').all(),
    operations: db.prepare('SELECT * FROM operation_log ORDER BY sequence').all(),
  });
}

const pushed = persistTitle('项目 标题', 10, 1000, 'push');
assert.equal(pushed.before, 'New Note');
assert.equal(db.prepare("SELECT value FROM background_winner WHERE note_id='note'").get().value, 'A4-grid',
  'title-only SetMetadata must not reset the independent background register');
assert.equal(db.prepare("SELECT folded_text FROM search_item WHERE note_id='note' AND type=0").get().folded_text,
  '项目 标题');
assert.equal(db.prepare("SELECT updated_at FROM note_meta WHERE id='note'").get().updated_at, 5000,
  'a monotonic title mutation must not move note updated_at backwards');

persistTitle('New Note', 20, 6000, 'undo');
persistTitle('项目 标题', 30, 6001, 'redo');
assert.equal(db.prepare("SELECT updated_at FROM note_meta WHERE id='note'").get().updated_at, 6001);
assert.equal(db.prepare("SELECT COUNT(*) count FROM operation_log WHERE kind='ORIGINAL_SET_METADATA'").get().count, 3);
assert.equal(db.prepare("SELECT COUNT(*) count FROM operation_log WHERE kind='UPDATE_TITLE'").get().count, 3);
assert.deepEqual(db.prepare("SELECT history FROM operation_log WHERE kind='UPDATE_TITLE' ORDER BY sequence").all()
  .map(row => row.history), ['push', 'undo', 'redo']);
assert(db.prepare("SELECT upload FROM operation_log WHERE kind='ORIGINAL_SET_METADATA' LIMIT 1").get().upload === 1);

const beforeStale = snapshot();
applySetMetadata({ timestamp: 25, site: 9, hasTitle: true, title: 'stale',
  hasBackground: false, background: null });
assert.equal(snapshot(), beforeStale, 'a stale title register write must be a complete no-op');

const beforeConflict = snapshot();
db.exec('BEGIN IMMEDIATE');
try {
  assert.throws(() => applySetMetadata({ timestamp: 30, site: 9, hasTitle: true,
    title: 'conflict', hasBackground: false, background: null }), /IDENTITY_CONFLICT/);
  db.exec('ROLLBACK');
} catch (error) {
  db.exec('ROLLBACK');
  throw error;
}
assert.equal(snapshot(), beforeConflict);

const beforeFailure = snapshot();
assert.throws(() => persistTitle('rollback-title', 40, 7000, 'failed', true), /injected/);
assert.equal(snapshot(), beforeFailure,
  'winner, materialized title, search row, revision, updated_at and both operations must roll back together');

const visibleHistory = db.prepare('SELECT kind,history FROM operation_log ORDER BY sequence').all()
  .filter(row => row.kind !== 'ORIGINAL_SET_METADATA');
assert.deepEqual(visibleHistory.map(row => row.history), ['push', 'undo', 'redo'],
  'upload-only original rows must remain transparent to durable Harmony history');

db.close();

console.log('localSetMetadataTitle=type1-title-only-utf8-200-edit-256-wire-default-space-independent-lww-search-monotonic-time-push-undo-redo-history-transparent-rollback');
