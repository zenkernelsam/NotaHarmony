import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const lg2 = original('sources/defpackage/lg2.java');
const u5j = original('sources/defpackage/u5j.java');
const clipboard = read('note/src/main/ets/rendering/StrokeClipboard.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixtures = read('note/src/test/StrokeClipboard.test.ets');

// Original copy walks selected Group descendants and asks the model to author fresh operations.
assert.match(lg2, /if \(!c\(set2, linkedHashSet3, linkedHashSet4, x09Var2, arrayList2, \(qo5\) it\.next\(\)\)\)/);
assert.match(lg2, /u5j\.c\(x09Var, au1\.A1\(au1\.T1\(set\), arrayList3\)/);
assert.match(u5j, /public static final ArrayList c\(x09 x09Var, ArrayList arrayList,[\s\S]*return b\.b\(\(a79\) x09Var, arrayList, aVar\)/);
assert.match(lg2, /if \(\(\(uq9\) next\)\.m\(\) == haa\.CREATE_GROUP\)/);
assert.match(lg2, /setH = ys2\.H\(au1\.X1\(arrayList8\), linkedHashSet\)/);

// Clipboard snapshots never retain the source CREATE reservation or silently flatten Groups.
assert.match(clipboard, /result\.originalCreate = undefined/);
assert.match(clipboard, /originalCreate: undefined/);
assert.match(clipboard, /private groupSnapshots: OriginalSelectionGroup\[\]/);
assert.match(clipboard, /this\.groupSnapshots\.length > 0 \|\| this\.size\(\) !== 1/);
assert.match(clipboard, /copyOriginalGroupGraph\(/);
assert.match(clipboard, /this\.imageSnapshots\.length > 0 \|\| this\.mathSnapshots\.length > 0/);
assert.match(clipboard, /text\.richText\.length === 0/);
assert.match(clipboard, /characterStyleRuns \?\? \[\]/);
assert.match(clipboard, /paragraphStyleRuns \?\? \[\]/);

// CREATE_INK/CREATE_SHAPE carry page-space geometry; paste translation is materialized before encode.
assert.match(clipboard, /materializeOriginalStrokeTransform\(stroke\)/);
assert.match(clipboard, /materializeOriginalShapeTransform\(shape\)/);
assert.match(clipboard, /stroke\.transform = \[1, 0, 0, 0, 1, 0, 0, 0, 1\]/);
assert.match(clipboard, /shape\.transform = \[1, 0, 0, 0, 1, 0, 0, 0, 1\]/);
assert.match(clipboard, /transformPointInPlace\(entry\.backingPencilReferencePoint, transform\)/);
assert.match(clipboard, /stroke\.renderSpec\.brushWidth \*= scale/);
assert.match(clipboard, /point\.azimuthUnitX = \(transform\[0\] \* azimuthX/);
assert.match(clipboard, /splat\.rotation = Math\.atan2/);

// UI reserves only after strict production encoders accept the copied snapshot.
assert.match(canvas, /this\.canEncodeOriginalClipboardSource\(source\)/);
assert.match(canvas, /encodeOriginalLocalCreateInk\(\{ timestamp: 1, siteId: 1, index: 0 \}, source\.stroke\)/);
assert.match(canvas, /encodeOriginalLocalCreateShape\(\{ timestamp: 1, siteId: 1, index: 0 \}, source\.shape, null\)/);
assert.match(canvas, /encodeOriginalLocalCreateTextBlock\(\{ timestamp: 1, siteId: 1, index: 0 \}, source\.textBlock\)/);
assert.match(canvas, /encodeOriginalInitialInsertString\(\{ timestamp: 1, siteId: 1 \}, source\.textBlock\.richText\)/);
assert.match(canvas, /this\.persistence\.reserveOriginalInkCreate\(this\.noteId, pageId\)/);
assert.match(canvas, /encodeOperationId\(\{ timestamp: originalCreate\.timestamp, siteId: originalCreate\.siteId \}\)/);
assert.match(canvas, /this\.persist\(originalCreate !== null\)/);
assert.match(canvas, /UndoableActionType\.ADD_ELEMENTS/);

// Persistence recognizes exactly one appended reserved entity and retains type-25 Undo/Redo.
assert.match(persistence, /next\.length !== current\.length \+ 1/);
assert.match(persistence, /const added: PreparedElement = next\[next\.length - 1\]/);
assert.match(persistence, /await this\.writeOriginalCreateInk/);
assert.match(persistence, /await this\.writeOriginalCreateShape/);
assert.match(persistence, /await this\.writeOriginalCreateText/);
assert.match(persistence, /ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE/);
assert.match(fixtures, /drops the source create reservation and exposes only safe single-create candidates/);
assert.match(fixtures, /materializes original Ink and Shape paste offsets without transform registers/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE entity(id TEXT PRIMARY KEY,kind TEXT NOT NULL,deleted INTEGER NOT NULL);
  CREATE TABLE operation_log(seq INTEGER PRIMARY KEY AUTOINCREMENT,type INTEGER NOT NULL,
    target TEXT NOT NULL,upload_immediately INTEGER NOT NULL);
  CREATE TABLE history(seq INTEGER PRIMARY KEY AUTOINCREMENT,effect TEXT NOT NULL,
    target TEXT NOT NULL);`);

function mutate(type, effect, id, deleted, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    if (type === 17 || type === 18 || type === 22) {
      db.prepare('INSERT INTO entity VALUES(?,?,0)').run(id,
        type === 17 ? 'ink' : type === 18 ? 'shape' : 'text');
    } else {
      db.prepare('UPDATE entity SET deleted=? WHERE id=?').run(deleted, id);
    }
    db.prepare('INSERT INTO operation_log(type,target,upload_immediately) VALUES(?,?,1)')
      .run(type, id);
    db.prepare('INSERT INTO history(effect,target) VALUES(?,?)').run(effect, id);
    if (fail) throw new Error('injected clipboard transaction failure');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

for (const [type, id] of [[17, 'ink-copy'], [18, 'shape-copy'], [22, 'text-copy']]) {
  mutate(type, 'PUSH', id, 0);
  mutate(25, 'UNDO', id, 1);
  assert.equal(db.prepare('SELECT deleted FROM entity WHERE id=?').get(id).deleted, 1);
  mutate(25, 'REDO', id, 0);
  assert.equal(db.prepare('SELECT deleted FROM entity WHERE id=?').get(id).deleted, 0);
}
assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log WHERE type IN (17,18,22)').get().count, 3);
assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log WHERE type=25').get().count, 6);
assert.equal(db.prepare('SELECT MIN(upload_immediately) value FROM operation_log').get().value, 1);

const beforeFailure = db.prepare('SELECT COUNT(*) count FROM operation_log').get().count;
assert.throws(() => mutate(25, 'UNDO', 'ink-copy', 1, true), /injected clipboard transaction failure/);
assert.equal(db.prepare('SELECT deleted FROM entity WHERE id=?').get('ink-copy').deleted, 0);
assert.equal(db.prepare('SELECT COUNT(*) count FROM operation_log').get().count, beforeFailure);
db.close();

console.log('originalSingleClipboardPaste=fresh-identity-strict-preflight-page-space-' +
  'ink-shape-text-create-type25-undo-redo-rollback-group-graph-guard');
