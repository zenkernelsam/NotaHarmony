import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const reducer = read('note/src/main/ets/data/OriginalModifyPdfFieldOperation.ets');
const hashReducer = read('note/src/main/ets/data/OriginalAssetCloudPersistedOperation.ets');
const router = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const pdfLoader = read('note/src/main/ets/core/adaptation/PdfBackgroundLoader.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');
const ddl = extractTemplate(schema, 'DDL_ORIGINAL_PDF_FIELD_STATE');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=53;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE note_asset(asset_hash TEXT PRIMARY KEY);
    INSERT INTO note_meta VALUES('n'),('other');`);
  return db;
}

function migrateV54(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(ddl);
    if (fail) throw new Error('injected v54 migration failure');
    db.exec('PRAGMA user_version=54; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const hash = Array.from({ length: 64 }, (_, index) =>
  index.toString(16).padStart(2, '0')).join('');
const otherHash = 'ff'.repeat(64);
const id = (timestamp, siteId) => ({ timestamp, siteId });
const stringValue = value => ({ type: 0, string: value, boolean: null });
const booleanValue = value => ({ type: 1, string: null, boolean: value ? 1 : 0 });

function compare(left, right) {
  return left.timestamp === right.timestamp ? Math.sign(left.siteId - right.siteId) :
    Math.sign(left.timestamp - right.timestamp);
}

function apply(db, noteId, assetHash, key, value, operation) {
  const reused = db.prepare(`SELECT * FROM original_pdf_field_state
    WHERE note_id=? AND winner_timestamp=? AND winner_site_id=?`)
    .get(noteId, operation.timestamp, operation.siteId);
  if (reused) {
    const exact = reused.asset_hash === assetHash && reused.field_key === key &&
      reused.value_type === value.type && reused.string_value === value.string &&
      reused.boolean_value === value.boolean;
    if (!exact) throw new Error('identity conflict');
    return 'IDEMPOTENT';
  }
  const current = db.prepare(`SELECT * FROM original_pdf_field_state
    WHERE note_id=? AND asset_hash=? AND field_key=?`).get(noteId, assetHash, key);
  if (current && compare(operation,
    { timestamp: current.winner_timestamp, siteId: current.winner_site_id }) <= 0) return 'STALE';
  db.prepare(`INSERT INTO original_pdf_field_state
    (note_id,asset_hash,field_key,value_type,string_value,boolean_value,
     winner_timestamp,winner_site_id) VALUES(?,?,?,?,?,?,?,?)
    ON CONFLICT(note_id,asset_hash,field_key) DO UPDATE SET
      value_type=excluded.value_type,string_value=excluded.string_value,
      boolean_value=excluded.boolean_value,winner_timestamp=excluded.winner_timestamp,
      winner_site_id=excluded.winner_site_id`).run(noteId, assetHash, key, value.type,
    value.string, value.boolean, operation.timestamp, operation.siteId);
  return 'APPLIED';
}

const db = database();
migrateV54(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 54);

// The original map is model state and may arrive before local asset metadata/reference.
assert.equal(apply(db, 'n', hash, 'name', stringValue('Alice'), id(10, 1)), 'APPLIED');
assert.equal(db.prepare('SELECT COUNT(*) count FROM note_asset').get().count, 0);
const storedName = db.prepare(`SELECT value_type,string_value,boolean_value
  FROM original_pdf_field_state WHERE note_id='n' AND field_key='name'`).get();
assert.equal(storedName.value_type, 0);
assert.equal(storedName.string_value, 'Alice');
assert.equal(storedName.boolean_value, null);

assert.equal(apply(db, 'n', hash, 'enabled', booleanValue(true), id(11, 1)), 'APPLIED');
assert.equal(apply(db, 'n', hash, 'locked', booleanValue(false), id(12, 1)), 'APPLIED');
assert.equal(apply(db, 'n', hash, 'name', stringValue('stale'), id(9, 9)), 'STALE');
assert.equal(apply(db, 'n', hash, 'name', stringValue('site-stale'), id(10, 0)), 'STALE');
assert.equal(apply(db, 'n', hash, 'name', stringValue('Bob'), id(10, 2)), 'APPLIED');
assert.equal(apply(db, 'n', hash, 'name', stringValue('Bob'), id(10, 2)), 'IDEMPOTENT');
assert.throws(() => apply(db, 'n', hash, 'name', stringValue('Eve'), id(10, 2)),
  /identity conflict/);
assert.throws(() => apply(db, 'n', hash, 'other', stringValue('Bob'), id(10, 2)),
  /identity conflict/);
assert.throws(() => apply(db, 'n', otherHash, 'name', stringValue('Bob'), id(10, 2)),
  /identity conflict/);

assert.equal(apply(db, 'n', hash, 'other', stringValue('x'), id(13, 1)), 'APPLIED');
assert.equal(apply(db, 'n', otherHash, 'name', stringValue('y'), id(14, 1)), 'APPLIED');
assert.equal(apply(db, 'other', hash, 'name', stringValue('z'), id(10, 2)), 'APPLIED');

// NOTE_BUNDLE applies model writes inside its caller transaction; a later failure rolls them back.
db.exec('BEGIN IMMEDIATE');
apply(db, 'n', hash, 'bundle', booleanValue(true), id(15, 1));
db.exec('ROLLBACK');
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_pdf_field_state
  WHERE note_id='n' AND field_key='bundle'`).get().count, 0);

db.exec("DELETE FROM note_meta WHERE id='n'");
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_pdf_field_state
  WHERE note_id='n'`).get().count, 0);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_pdf_field_state
  WHERE note_id='other'`).get().count, 1);
db.close();

const failed = database();
assert.throws(() => migrateV54(failed, true), /injected v54 migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 53);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='original_pdf_field_state'`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 60/);
assert.match(schema, /54: \[[\s\S]*DDL_ORIGINAL_PDF_FIELD_STATE/);
assert.match(schema, /UNIQUE\(note_id, winner_timestamp, winner_site_id\)/);
assert.doesNotMatch(ddl, /REFERENCES note_asset/);
assert.match(manager, /DDL_ORIGINAL_PDF_FIELD_STATE/);
assert.match(hashReducer, /originalAssetHashBytesToStorageHash/);
assert.match(reducer, /ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE: number = 27/);
assert.match(reducer, /table\.hasField\(4\)/);
assert.match(reducer, /compareOperationIdentity\(winner, current\.winner\) <= 0/);
assert.match(reducer, /readOriginalPdfFieldValue/);
assert.match(router, /ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE/);
assert.match(bundle, /modifyPdfField\.preflightTable/);
assert.match(bundle, /modifyPdfField\.applyTable/);
assert.match(fixture, /flatBufferModifyPdfField/);
assert.match(fixture, /MALFORMED_MODIFY_PDF_FIELD_PAYLOAD/);

// PdfBackgroundLoader currently renders flattened page pixels only. State is intentionally
// exposed for a future form-overlay/cache consumer, without pretending visual AcroForm parity.
assert.doesNotMatch(pdfLoader, /readOriginalPdfFieldValue/);

console.log('D02_MODIFY_PDF_FIELD_REPLAY_OK ' +
  'v53-v54=1|string=1|boolean-true-false=2|different-keys-hashes-notes=3|' +
  'stale-site-tie=2|exact-retry=1|identity-conflict=3|event-before-asset=1|' +
  'note-bundle-rollback=1|cascade=1|migration-rollback=1|visual-overlay=pending');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
