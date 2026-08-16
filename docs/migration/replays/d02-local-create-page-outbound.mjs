import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalCreate = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/ln2.java', 'utf8');
const originalWriter = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/haj.java', 'utf8');
const originalSequence = fs.readFileSync(
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/cxc.java', 'utf8');
const encoder = read('note/src/main/ets/data/OriginalCreatePagePayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/OriginalPagePersistence.ets');
const pageRepo = read('note/src/main/ets/data/PageRepositoryImpl.ets');
const noteRepo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const editor = read('note/src/main/ets/ui/editor/NotePage.ets');
const deleteEncoder = read('note/src/main/ets/data/OriginalDeleteEntitiesPayloadEncoder.ets');
const tests = read('note/src/test/OriginalCreatePagePayloadEncoder.test.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const historyTests = read('note/src/test/PersistentHistory.test.ets');

assert.match(originalCreate, /new cxc\(\)[\s\S]*c\(4\)/);
assert.match(originalCreate, /new nz9\(\)[\s\S]*c\(6\)/);
assert.match(originalCreate, /c\(8\)[\s\S]*getInt/);
assert.match(originalCreate, /return 1/);
assert.match(originalWriter, /aVarA\.j\(0, nti\.X\(cxcVar, aVarA\)\)/);
assert.match(originalWriter, /aVarA\.h\(1, numValueOf\.intValue\(\)\)/);
assert.match(originalWriter, /aVarA\.e\(2, i, 1\)/);
assert.match(originalWriter, /aVarA\.c\(3, oz9Var\.I, 0\)/);
assert.match(originalSequence, /getShort\(this\.I\)/);
assert.match(originalSequence, /getInt\(this\.I \+ 4\)/);
assert.match(originalSequence, /getInt\(this\.I \+ 8\)/);

assert.match(encoder, /writeVtable\(bytes, rootVtable, 28/);
assert.match(encoder, /backgroundTable \+ 4, \(widthMm as number\) \* MM_TO_POINTS/);
assert.match(persistence, /readTailPosition/);
assert.match(persistence, /winner\.winner_timestamp, winner\.winner_site_id, winner\.position_index/);
assert.match(persistence, /OriginalCreatePageOperationApplier\(\)\.apply/);
assert.match(persistence, /OriginalDeleteEntitiesOperationApplier\(\)\.apply/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /hasAlignedOriginalPageState/);
assert.match(pageRepo, /history\.effect === HistoryEffect\.REDO/);
assert.match(pageRepo, /appendStructureHistoryMutation/);
assert.match(pageRepo, /editorPersistenceMutex\.lock\(\)/);
assert.match(deleteEncoder, /encodeOriginalPageVisibility/);
assert.match(noteRepo, /persistOriginalBlankNoteBootstrap\(store, note\.id, note\.title, defaultTemplate\)/);
assert.equal((importer.match(/addImportedPage\(note\.id, pageInfo\)/g) ?? []).length, 2);
assert.match(editor, /action\.pageId = assignedPage\.pageId/);
assert.match(editor, /ADD_PAGE redo changed the original page identity/);
assert.match(tests, /round-trips a located A4 page through nz9 sourceSize/);
assert.match(tests, /round-trips page delete and undelete sequence vectors/);
assert.match(history, /isOriginalOutboundCompanion/);
assert.match(history, /operation\.opType === OpType\.ORIGINAL_CREATE_PAGE/);
assert.match(historyTests, /keeps original outbound companions transparent to local history/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page_info(page_id TEXT PRIMARY KEY,page_index INTEGER);
  CREATE TABLE identity(page_id TEXT PRIMARY KEY,ts INTEGER,site INTEGER,idx INTEGER,visible INTEGER);
  CREATE TABLE winner(page_id TEXT PRIMARY KEY,ts INTEGER,site INTEGER,idx INTEGER);
  CREATE TABLE archive(page_id TEXT PRIMARY KEY,page_index INTEGER);
  CREATE TABLE operation_log(seq INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,payload TEXT);
  INSERT INTO page_info VALUES('page:1:7:0',0);
  INSERT INTO identity VALUES('page:1:7:0',1,7,0,1);
  INSERT INTO winner VALUES('page:1:7:0',20,9,4);`);

function snapshot() {
  return {
    pages: db.prepare('SELECT * FROM page_info ORDER BY page_index').all(),
    identities: db.prepare('SELECT * FROM identity ORDER BY page_id').all(),
    winners: db.prepare('SELECT * FROM winner ORDER BY page_id').all(),
    archive: db.prepare('SELECT * FROM archive ORDER BY page_id').all(),
    operations: db.prepare('SELECT kind,payload FROM operation_log ORDER BY seq').all(),
  };
}

function create(ts, site, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const tail = db.prepare(`SELECT winner.ts,winner.site,winner.idx FROM page_info page
      JOIN winner ON winner.page_id=page.page_id ORDER BY page.page_index DESC LIMIT 1`).get();
    const id = `page:${ts}:${site}:0`;
    db.prepare('INSERT INTO identity VALUES(?,?,?,?,1)').run(id, ts, site, 0);
    db.prepare('INSERT INTO winner VALUES(?,?,?,0)').run(id, ts, site);
    db.prepare('INSERT INTO page_info VALUES(?,?)')
      .run(id, db.prepare('SELECT COUNT(*) count FROM page_info').get().count);
    if (fail) throw new Error('injected create failure');
    db.prepare('INSERT INTO operation_log(kind,payload) VALUES(?,?)')
      .run('CREATE_PAGE', JSON.stringify({ location: tail, widthMm: 210, heightMm: 297 }));
    db.exec('COMMIT');
    return id;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function visibility(pageId, deleted) {
  db.exec('BEGIN IMMEDIATE');
  try {
    if (deleted) {
      const page = db.prepare('SELECT * FROM page_info WHERE page_id=?').get(pageId);
      db.prepare('INSERT INTO archive VALUES(?,?)').run(pageId, page.page_index);
      db.prepare('DELETE FROM page_info WHERE page_id=?').run(pageId);
    } else {
      const page = db.prepare('SELECT * FROM archive WHERE page_id=?').get(pageId);
      db.prepare('INSERT INTO page_info VALUES(?,?)').run(pageId, page.page_index);
      db.prepare('DELETE FROM archive WHERE page_id=?').run(pageId);
    }
    db.prepare('INSERT INTO operation_log(kind,payload) VALUES(?,?)')
      .run('DELETE_ENTITIES', JSON.stringify({ pageId, deleted }));
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const added = create(21, 7);
const createPayload = JSON.parse(db.prepare(
  `SELECT payload FROM operation_log WHERE kind='CREATE_PAGE'`).get().payload);
assert.deepEqual(createPayload.location, { ts: 20, site: 9, idx: 4 });
assert.equal(added, 'page:21:7:0');
visibility(added, true);
assert.equal(db.prepare('SELECT COUNT(*) count FROM page_info WHERE page_id=?').get(added).count, 0);
visibility(added, false);
assert.equal(db.prepare('SELECT COUNT(*) count FROM page_info WHERE page_id=?').get(added).count, 1);
const beforeFailure = snapshot();
assert.throws(() => create(22, 7, true), /injected create failure/);
assert.deepEqual(snapshot(), beforeFailure);
db.close();

console.log('localCreatePage=original-seqid-tail-canonical-visibility-rollback');
