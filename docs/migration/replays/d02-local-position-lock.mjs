import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const dsc = original('sources/defpackage/dsc.java');
const dhb = original('sources/defpackage/dhb.java');
const ux9 = original('sources/defpackage/ux9.java');
const a1j = original('sources/defpackage/a1j.java');
const td8 = original('sources/defpackage/td8.java');
const cz3 = original('sources/defpackage/cz3.java');
const strings = original('resources/res/values/strings.xml');
const shapeEncoder = read('note/src/main/ets/data/OriginalModifyShapePayloadEncoder.ets');
const blockEncoder = read('note/src/main/ets/data/OriginalModifyBlockPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const selection = read('note/src/main/ets/rendering/SelectionTool.ets');
const shapeGeometry = read('note/src/main/ets/core/model/ShapeGeometry.ets');
const overlay = read('note/src/main/ets/ui/components/SelectionOverlay.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const payloadFixtures = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const blockFixtures = read('note/src/test/OriginalModifyBlockPayloadEncoder.test.ets');
const persistenceFixtures = read('note/src/test/StrokePersistence.test.ets');
const selectionFixtures = read('note/src/test/SelectionTool.test.ets');
const geometryFixtures = read('note/src/test/ShapeGeometry.test.ets');

assert.match(dsc, /new dsc\("LOCK", 18\)/);
assert.match(dsc, /new dsc\("UNLOCK", 19\)/);
assert.match(strings, /feature_note__selection_menu_lock">Lock</);
assert.match(strings, /feature_note__selection_menu_unlock">Unlock</);
assert.match(ux9, /feature_note__selection_menu_lock/);
assert.match(ux9, /feature_note__selection_menu_unlock/);
assert.match(dhb, /Boolean\.valueOf\(!\(\(oy0\) be5VarI\)\.t\(\)\)/);
assert.match(dhb, /Boolean\.valueOf\(!\(\(n5d\) m4dVar\)\.t\(\)\)/);
assert.match(dhb, /m4dVarQ8[\s\S]*\(\(n5d\) m4dVarQ8\)\.t\(\) != z15/);
assert.match(a1j, /aVarA\.a\(14, bool3\.booleanValue\(\), false\)/);
assert.match(td8, /public final Boolean u\(\)[\s\S]*c\(38\)/);
assert.match(cz3, /EntitySelectionData[\s\S]*positionLocked=/);

assert.match(shapeEncoder, /fields\[14\] = update\.positionLocked === null \? 0 : 24/);
assert.match(shapeEncoder, /bytes\[table \+ 24\] = update\.positionLocked \? 1 : 0/);
assert.match(blockEncoder, /fields\[17\] = 8/);
assert.match(blockEncoder, /bytes\[table \+ 8\] = locked \? 1 : 0/);
assert.match(payloadFixtures, /positionLocked: false[\s\S]*expect\(unlocked\.positionLocked\)\.assertFalse/);
assert.match(blockFixtures, /position lock presence for true and false/);

assert.match(selection, /if \(this\.elementBoundsSelected\(shape\.bounds\)\)/);
assert.match(selection, /if \(selectionPathHitsTextBlock\(selectionPath, textBlock\)\)/);
assert.doesNotMatch(selection,
  /!isTextBlockPositionLocked\(textBlock\) && selectionPathHitsTextBlock/);
assert.match(selectionFixtures, /position-locked text blocks so they can be unlocked/);
assert.match(selectionFixtures, /position-locked images/);
assert.match(shapeGeometry, /!selected\.has\(shape\.id\) \|\| shape\.positionLocked === true/);
assert.match(shapeGeometry, /eraserPath\.length === 0 \|\| shape\.positionLocked === true/);
assert.match(geometryFixtures, /position-locked Shapes immovable and whole-eraser safe/);
assert.match(overlay, /positionLocked \? \$r\('app\.string\.unlock'\) : \$r\('app\.string\.lock'\)/);
assert.match(canvas, /const onlyShapesSelected: boolean/);
assert.match(canvas, /selectedCount === 1 && state\.selectedGroupIds\.length === 0/);
assert.match(canvas, /private setSelectedPositionLocked\(locked: boolean\)/);
assert.match(canvas, /type: UndoableActionType\.TRANSFORM_ELEMENTS/);
assert.match(canvas, /this\.setSelectedPositionLocked\(!this\.selectionPositionLocked\)/);

assert.match(persistence, /classifyOriginalPositionLockMutation/);
assert.match(persistence, /candidate\.positionLocked = locked/);
assert.match(persistence, /sameByteArrays\(encodePersistedElement/);
assert.match(persistence, /SELECT resolved_payload FROM original_shape_state/);
assert.match(persistence, /SELECT create_position_locked, position_locked_value/);
assert.match(persistence, /metadata\.positionLocked !== batch\.expectedLocked\[index\]/);
assert.match(persistence, /encodeOriginalShapeRenderRegisters\(batch\.identities/);
assert.match(persistence,
  /encodeOriginalBlockPositionLocked\(\s*batch\.identities, batch\.locked\)/);
assert.match(persistence, /const revisionBatch: OriginalPageMutationBatch = new OriginalPageMutationBatch\(\)/);
assert.match(persistence, /await this\.appendHistoryCompanion/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /payload\.positionLocked === undefined \? false/);
assert.match(persistenceFixtures, /mixed Shape and Block lock with reversible source state/);
assert.match(persistenceFixtures, /\{"tool":2,"style":1\}/);

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE entity(id TEXT PRIMARY KEY,kind TEXT NOT NULL,position_locked INTEGER NOT NULL);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT NOT NULL,
    payload_type INTEGER NOT NULL,position_locked INTEGER NOT NULL,upload_immediately INTEGER NOT NULL);
  CREATE TABLE history(sequence INTEGER PRIMARY KEY AUTOINCREMENT,before_state TEXT NOT NULL,
    after_state TEXT NOT NULL);
  CREATE TABLE page(id INTEGER PRIMARY KEY,revision INTEGER NOT NULL);
  INSERT INTO entity VALUES('shape','shape',0),('image','block',0);
  INSERT INTO page VALUES(1,0);`);

function applyPositionLock(targets, locked, failAfter = -1) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const before = [];
    for (let index = 0; index < targets.length; index++) {
      const target = targets[index];
      const row = db.prepare('SELECT kind,position_locked FROM entity WHERE id=?').get(target.id);
      if (row === undefined || row.position_locked !== Number(target.expectedLocked)) {
        throw new Error('stale position-lock source');
      }
      before.push({ id: target.id, locked: row.position_locked !== 0 });
      db.prepare('UPDATE entity SET position_locked=? WHERE id=?').run(Number(locked), target.id);
      if (index === failAfter) throw new Error('injected position-lock failure');
    }
    for (const kind of ['shape', 'block']) {
      if (targets.some(target => target.kind === kind)) {
        db.prepare(`INSERT INTO operation_log(kind,payload_type,position_locked,upload_immediately)
          VALUES(?,?,?,1)`).run(kind, kind === 'shape' ? 19 : 23, Number(locked));
      }
    }
    db.prepare('INSERT INTO history(before_state,after_state) VALUES(?,?)').run(
      JSON.stringify(before), JSON.stringify(targets.map(target => ({ id: target.id, locked }))));
    db.exec('UPDATE page SET revision=revision+1 WHERE id=1');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const forward = [
  { id: 'shape', kind: 'shape', expectedLocked: false },
  { id: 'image', kind: 'block', expectedLocked: false },
];
applyPositionLock(forward, true);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM entity WHERE position_locked=1').get().value, 2);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 1);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM operation_log').get().value, 2);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM operation_log WHERE payload_type=19').get().value, 1);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM operation_log WHERE payload_type=23').get().value, 1);
assert.equal(db.prepare('SELECT MIN(upload_immediately) AS value FROM operation_log').get().value, 1);
assert.throws(() => applyPositionLock(forward, true), /stale position-lock source/);

const reverse = forward.map(target => ({ ...target, expectedLocked: true }));
applyPositionLock(reverse, false);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM entity WHERE position_locked=0').get().value, 2);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 2);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM history').get().value, 2);

const beforeFailure = JSON.stringify(db.prepare('SELECT * FROM entity ORDER BY id').all());
assert.throws(() => applyPositionLock(forward, true, 0), /injected position-lock failure/);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM entity ORDER BY id').all()), beforeFailure);
assert.equal(db.prepare('SELECT revision FROM page').get().revision, 2);
assert.equal(db.prepare('SELECT COUNT(*) AS value FROM operation_log').get().value, 4);
db.close();

console.log('localPositionLock=original-type19-type23-select-unlock-source-preflight-' +
  'single-revision-undo-redo-rollback');
