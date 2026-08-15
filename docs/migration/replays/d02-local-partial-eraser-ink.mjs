import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const dh5 = original('sources/defpackage/dh5.java');
const o8j = original('sources/defpackage/o8j.java');
const evidence = read(
  'docs/migration/evidence/original-partial-erase-entity-replacement-jadx-2026-08-15.md');
const groupEvidence = read(
  'docs/migration/evidence/original-partial-erase-group-replacement-jadx-2026-08-15.md');
const eraser = read('note/src/main/ets/rendering/EraserEngine.ets');
const encoder = read('note/src/main/ets/data/OriginalCreateInkPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const undo = read('note/src/main/ets/rendering/UndoRedoManager.ets');
const persistentHistory = read('note/src/main/ets/data/PersistentHistory.ets');
const codec = read('note/src/main/ets/data/OriginalPartialEraseMutationCodec.ets');
const groupPlanner = read('note/src/main/ets/data/OriginalPartialEraseGroupPlanner.ets');
const encoderFixture = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');
const eraserFixture = read('note/src/test/EraserEngine.test.ets');
const historyFixture = read('note/src/test/PersistentHistory.test.ets');
const undoFixture = read('note/src/test/UndoRedoManager.test.ets');
const persistenceFixture = read('note/src/test/StrokePersistence.test.ets');
const groupPlannerFixture = read('note/src/test/OriginalPartialEraseGroupPlanner.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

// Direct original evidence: normal drawing expects CREATE_INK, while partial erase takes jt1.
assert.match(dh5, /new wc\(arrayList5[\s\S]{0,120}, 2\)/);
assert.match(dh5, /No CREATE_INK op found in dispatchEndActiveStroke/);
assert.match(dh5, /q4fVar\.b\(\) == d04\.J[\s\S]{0,1000}new jt1\(/);

// o8j creates a new Ink for every retained geometry interval and derives its audio interval.
assert.match(o8j, /new ls1\(dMin \/ d2, dMax \/ d2\)/);
assert.match(o8j, /\(ls1Var\.J - d5\) \* dG0/);
assert.match(o8j, /new xgb\(xgbVar\.I \+ rh8\.x/);
assert.match(o8j, /new jrb\(u5j\.g\(/);
assert.match(o8j, /arrayList9\.add\(jrbVar\)/);

// Fallback-only jt1/wc evidence is preserved in-repo instead of depending on %TEMP% at replay time.
assert.match(evidence, /n8j\.e/);
assert.match(evidence, /o8j\.a/);
assert.match(evidence, /new wc\(\.\.\., 3\)/);
assert.match(evidence, /u5j\.l/);
assert.match(evidence, /oqi\.a/);
assert.match(evidence, /22E7F02B2483D45FEB577541C79CD90A601BC17EBE8FACAFE94859B06856BEA5/);
assert.match(evidence, /17A0E86702415B5A4181F8F2B1E81E147AD23D3B6DA1DEDB3C60B58B97679895/);
assert.match(groupEvidence, /removeAll\(sourceId\)/);
assert.match(groupEvidence, /append all remnants/);
assert.match(groupEvidence, /CREATE_INK → MODIFY_GROUP → DELETE_ENTITIES/);
assert.match(groupEvidence, /B4DA5DB3C578DD38D308B38DCFCD87E12BB5CDE42CE3A875708825E2CA950E5B/);

// Harmony authoring clips into entities. Historical incoming tool-5 Ink remains supported, but
// local partial erase no longer appends a permanent destination-out maskPath entity.
assert.match(eraser, /partialReplacements: PartialEraseReplacement\[\]/);
assert.match(eraser, /replacements\.push\(\{ sourceStroke: stroke, remnants: remnants \}\)/);
assert.match(eraser, /maskPath: \[\]/);
assert.doesNotMatch(eraser, /ERASER_PATH_BREAK_COORDINATE/);
assert.match(eraser, /remnantAudioTiming/);
assert.match(eraser, /shiftAudioStart/);
assert.match(eraser,
  /inkEffectPhase: \(source\.renderSpec\.inkEffectPhase \?\? 0\) \+ run\[0\]\.distance/);

assert.match(canvas, /const previewToken: number \| null = this\.partialEraserPreview\.finish\(\)/);
assert.match(canvas, /commitOriginalPartialErase\(plan, previewToken\)/);
assert.doesNotMatch(canvas, /commitOriginalPartialEraser/);
assert.match(canvas, /this\.areCanonicalOriginalPositionSelection\(strokeIds, shapeIds/);
assert.match(canvas, /this\.applyPartialEraseLocally\(plan\)/);
assert.match(canvas, /new OriginalShapePartialEraser\(this\.eraserEngine\.getWidth\(\)\)/);
assert.match(canvas, /sourceKind: PageElementKind\.SHAPE/);
assert.match(canvas, /addedStrokes: added/);
assert.match(canvas, /addedStrokeIndices: addedIndices/);
assert.match(canvas, /addedStrokeCounts: addedCounts/);
assert.match(canvas, /partialEraseBeforeGroups: groupPlan\.beforeGroups/);
assert.match(canvas, /partialEraseAfterGroups: groupPlan\.afterGroups/);
assert.match(canvas, /planLocalPartialEraseGroups\(this\.selectionGroups, groupReplacements\)/);
assert.match(canvas, /private partialEraserCandidateStrokes\(\)[\s\S]{0,120}completedStrokes\.slice/);
assert.match(canvas, /restoreRemovedStrokes\(addedStrokes, addedStrokeIndices\)/);
assert.match(canvas, /validatePartialEraseElementHistoryState/);
assert.match(canvas, /existingElementIds\.has\(remnant\.id\)/);
assert.match(canvas, /invalidateOriginalInkReservation\(\)/);
assert.match(undo, /buildPartialEraseReplacementMap/);
assert.match(undo, /partialEraseElementOrder/);
assert.match(undo, /validInsertionIndices/);
assert.match(groupPlanner, /highestIdentityParentByMember/);
assert.match(groupPlanner, /withoutMember\(working\.members, replacement\.sourceId\)/);
assert.match(groupPlanner, /working\.members\.push\(remnantId\)/);
assert.match(groupPlanner, /firstEmptyAffectedGroup/);

// CREATE_INK remnants retain transform, source z-index and nullable uint32 audioDuration.
assert.match(encoder, /decomposeInkTransform/);
assert.match(encoder, /zIndex\?: string/);
assert.match(encoder, /hasAudioDuration \? 76 : 0/);
assert.match(encoder, /writeU32\(bytes, table \+ 76, stroke\.audioDuration as number\)/);
assert.match(encoder, /audio duration is not uint32/);

const commitStart = persistence.indexOf('async commitOriginalPartialErase(');
const historyStart = persistence.indexOf('async applyOriginalPartialEraseHistory(', commitStart);
assert.ok(commitStart >= 0 && historyStart > commitStart);
const commitSource = persistence.slice(commitStart, historyStart);
const historyEnd = persistence.indexOf('async commitOriginalClipboardPaste(', historyStart);
assert.ok(historyEnd > historyStart);
const historySource = persistence.slice(historyStart, historyEnd);

// CREATE remnants use one deliberately unflushed batch. DELETE sources performs the only page
// revision CAS, then search and dedicated history are rebuilt in the same outer transaction.
assert.match(commitSource, /await store\.beginTransaction\(\)/);
assert.match(commitSource, /const revisionBatch: OriginalPageMutationBatch/);
assert.match(commitSource, /applyBatchedPayload\([\s\S]*?revisionBatch\)/);
assert.doesNotMatch(commitSource, /revisionBatch\.flush/);
assert.ok(commitSource.indexOf('applyBatchedPayload(') <
  commitSource.indexOf('new OriginalDeleteEntitiesOperationApplier().apply'));
assert.ok(commitSource.indexOf('applyBatchedPayload(') <
  commitSource.indexOf('applyOriginalPartialEraseGroupModifications('));
assert.ok(commitSource.indexOf('applyOriginalPartialEraseGroupModifications(') <
  commitSource.indexOf('new OriginalDeleteEntitiesOperationApplier().apply'));
assert.match(commitSource, /groupPlan\.emptyGroups/);
assert.match(commitSource, /revisionAfter !== currentRevision \+ 1/);
assert.match(commitSource, /rebuildPageSearchState\(store, finalSnapshot, revisionAfter, true\)/);
assert.match(commitSource, /appendOriginalPartialEraseHistory/);
assert.match(commitSource, /await store\.commit\(\)/);
assert.match(commitSource, /await store\.rollBack\(\)/);

// Undo/redo reverse Group member registers plus one visibility operation/page revision,
// while persistent history still moves as one dedicated action.
assert.match(historySource, /replayPageMutation\([\s\S]{0,80}mutation\.pageMutation, forward\)/);
assert.match(historySource, /replayOriginalPartialEraseGroups/);
assert.match(historySource, /applyOriginalPartialEraseGroupModifications/);
assert.match(historySource, /encodeOriginalEntityVisibility\(deletes, undeletes\)/);
assert.match(historySource, /revisionAfter !== revisionBefore \+ 1/);
assert.match(historySource, /rebuildPageSearchState\(store, finalSnapshot, revisionAfter, true\)/);
assert.match(undo, /ORIGINAL_PARTIAL_ERASE/);
assert.match(persistentHistory, /decodeOriginalPartialEraseMutation/);
assert.match(codec, /validateOriginalPartialEraseMutation/);
assert.match(codec, /MAX_ORIGINAL_DELETE_ENTITY_COUNT/);
assert.match(codec, /LEGACY_PAGE_MAGIC/);
assert.match(codec, /NPE2/);
assert.match(codec, /planOriginalPartialEraseGroups/);
assert.match(codec, /Group snapshots contradict replacement mapping/);
assert.match(persistence, /remnantIds\.has\(sourceId\)/);

assert.match(encoderFixture, /preserves CREATE_INK origin rotation scale and source z-index/);
assert.match(encoderFixture, /decoded\.audioDuration\)\.assertEqual\(0xFFFFFFFF\)/);
assert.match(eraserFixture, /recomputes each AudioLinked Ink remnant interval/);
assert.match(eraserFixture, /remnants\[0\]\.audioStartTime === remnants\[1\]\.audioStartTime/);
assert.match(historyFixture, /restores original partial erase as one dedicated action across UNDO/);
assert.match(undoFixture, /preserves local partial-erase remnant positions across undo and redo/);
assert.match(persistenceFixture,
  /rejects a partial-erase source identity already used by an earlier remnant/);
assert.match(encoderFixture, /caps original partial-erase history at one type-25 visibility payload/);
assert.match(encoderFixture, /round-trips NPE2 modified and recursively deleted Group snapshots/);
assert.match(groupPlannerFixture, /uses the highest-identity parent and appends remnants/);
assert.match(groupPlannerFixture, /recursively deletes empty Groups/);
assert.match(groupPlannerFixture, /draft remnant IDs/);
assert.match(groupPlannerFixture, /another local erase after a draft remnant entered the Group/);
assert.match(fixtureList, /eraserEngineTest\(\)/);
assert.match(fixtureList, /originalCreateInkPayloadEncoderTest\(\)/);
assert.match(fixtureList, /persistentHistoryTest\(\)/);
assert.match(fixtureList, /originalPartialEraseGroupPlannerTest\(\)/);

function createFixture() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE page_info(
      note_id TEXT NOT NULL, page_id TEXT NOT NULL, content_revision INTEGER NOT NULL,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(
      note_id TEXT NOT NULL, page_id TEXT NOT NULL, element_id TEXT NOT NULL,
      kind INTEGER NOT NULL, payload TEXT NOT NULL, revision INTEGER NOT NULL,
      element_order INTEGER NOT NULL, PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE original_deleted_page(
      note_id TEXT NOT NULL, page_timestamp INTEGER NOT NULL, page_site_id INTEGER NOT NULL,
      page_index INTEGER NOT NULL, page_id TEXT NOT NULL, content_revision INTEGER NOT NULL,
      indexed_revision INTEGER, PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(
      note_id TEXT NOT NULL, page_timestamp INTEGER NOT NULL, page_site_id INTEGER NOT NULL,
      page_index INTEGER NOT NULL, element_id TEXT NOT NULL, kind INTEGER NOT NULL,
      payload TEXT NOT NULL, revision INTEGER NOT NULL, element_order INTEGER NOT NULL,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE operation_log(
      operation_id TEXT PRIMARY KEY, payload_type INTEGER NOT NULL, effect TEXT NOT NULL);
    CREATE TABLE history_log(
      operation_id TEXT PRIMARY KEY, effect TEXT NOT NULL, revision_before INTEGER NOT NULL,
      revision_after INTEGER NOT NULL);
    CREATE TABLE search_page_state(
      note_id TEXT NOT NULL, page_id TEXT NOT NULL, indexed_revision INTEGER NOT NULL,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE search_item(
      note_id TEXT NOT NULL, page_id TEXT NOT NULL, element_id TEXT NOT NULL,
      type INTEGER NOT NULL, text TEXT NOT NULL,
      PRIMARY KEY(note_id,page_id,element_id,type));
  `);
  db.exec(`
    INSERT INTO page_info VALUES('n','p',7);
    INSERT INTO page_element_snapshot VALUES('n','p','op:20:2',1,'source',7,0);
    INSERT INTO page_element_snapshot VALUES('n','p','op:30:2',2,'other',7,1);
    INSERT INTO search_page_state VALUES('n','p',7);
    INSERT INTO search_item VALUES('n','p','op:20:2',1,'source ink');
    INSERT INTO search_item VALUES('n','p','op:30:2',2,'other text');
    INSERT INTO original_deleted_page VALUES('n',99,9,0,'archived',3,3);
    INSERT INTO original_deleted_page_element
      VALUES('n',99,9,0,'op:7:9',1,'archived ink',3,0);
  `);
  return db;
}

function queryRows(db, table, orderBy) {
  return db.prepare(`SELECT * FROM ${table} ORDER BY ${orderBy}`).all();
}

function snapshot(db) {
  return JSON.stringify({
    page: queryRows(db, 'page_info', 'note_id,page_id'),
    elements: queryRows(db, 'page_element_snapshot', 'note_id,page_id,element_order,element_id'),
    archive: queryRows(db, 'original_deleted_page',
      'note_id,page_timestamp,page_site_id,page_index'),
    archiveElements: queryRows(db, 'original_deleted_page_element',
      'note_id,page_timestamp,page_site_id,page_index,element_order,element_id'),
    operations: queryRows(db, 'operation_log', 'operation_id'),
    history: queryRows(db, 'history_log', 'operation_id'),
    searchState: queryRows(db, 'search_page_state', 'note_id,page_id'),
    search: queryRows(db, 'search_item', 'note_id,page_id,type,element_id'),
  });
}

function inject(stage, requested) {
  if (stage === requested) throw new Error(`injected-${stage}`);
}

function rebuildSearch(db, revision, visibleIds) {
  db.prepare(`DELETE FROM search_page_state WHERE note_id='n' AND page_id='p'`).run();
  db.prepare(`DELETE FROM search_item WHERE note_id='n' AND page_id='p'`).run();
  for (const id of visibleIds) {
    db.prepare(`INSERT INTO search_item VALUES('n','p',?,1,?)`).run(id, `ink-${id}`);
  }
  db.prepare(`INSERT INTO search_item VALUES('n','p','op:30:2',2,'other text')`).run();
  db.prepare(`INSERT INTO search_page_state VALUES('n','p',?)`).run(revision);
}

function applyStep(db, mode, failAt = '') {
  db.exec('BEGIN IMMEDIATE');
  try {
    const revisionBefore = db.prepare(
      `SELECT content_revision FROM page_info WHERE note_id='n' AND page_id='p'`).get()
      .content_revision;
    const revisionAfter = revisionBefore + 1;
    if (mode === 'commit') {
      // CREATE remnants share an unflushed batch: rows are current+1 while page stays current.
      db.prepare(`UPDATE page_element_snapshot SET element_order=2
        WHERE note_id='n' AND page_id='p' AND element_id='op:30:2'`).run();
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:21:2',1,
        'left-remnant',?,0)`).run(revisionAfter);
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:22:2',1,
        'right-remnant',?,1)`).run(revisionAfter);
      db.prepare(`INSERT INTO operation_log VALUES('create-left',15,'CREATE_INK')`).run();
      db.prepare(`INSERT INTO operation_log VALUES('create-right',15,'CREATE_INK')`).run();
      assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision,
        revisionBefore);
      inject('after-create', failAt);
      db.prepare(`DELETE FROM page_element_snapshot WHERE element_id='op:20:2'`).run();
      db.prepare(`INSERT INTO operation_log VALUES('delete-source',25,'DELETE_SOURCE')`).run();
    } else if (mode === 'undo') {
      db.prepare(`DELETE FROM page_element_snapshot
        WHERE element_id IN ('op:21:2','op:22:2')`).run();
      db.prepare(`UPDATE page_element_snapshot SET element_order=1 WHERE element_id='op:30:2'`).run();
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:20:2',1,
        'source',?,0)`).run(revisionAfter);
      db.prepare(`INSERT INTO operation_log VALUES('visibility-undo',25,'UNDO_VISIBILITY')`).run();
    } else {
      assert.equal(mode, 'redo');
      db.prepare(`DELETE FROM page_element_snapshot WHERE element_id='op:20:2'`).run();
      db.prepare(`UPDATE page_element_snapshot SET element_order=2 WHERE element_id='op:30:2'`).run();
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:21:2',1,
        'left-remnant',?,0)`).run(revisionAfter);
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p','op:22:2',1,
        'right-remnant',?,1)`).run(revisionAfter);
      db.prepare(`INSERT INTO operation_log VALUES('visibility-redo',25,'REDO_VISIBILITY')`).run();
    }

    const updated = db.prepare(`UPDATE page_info SET content_revision=?
      WHERE note_id='n' AND page_id='p' AND content_revision=?`).run(
      revisionAfter, revisionBefore).changes;
    assert.equal(updated, 1);
    db.prepare(`UPDATE page_element_snapshot SET revision=?
      WHERE note_id='n' AND page_id='p'`).run(revisionAfter);
    db.prepare(`DELETE FROM search_page_state WHERE note_id='n' AND page_id='p'`).run();
    db.prepare(`DELETE FROM search_item WHERE note_id='n' AND page_id='p'`).run();
    inject('after-delete', failAt);
    rebuildSearch(db, revisionAfter,
      mode === 'undo' ? ['op:20:2'] : ['op:21:2', 'op:22:2']);
    inject('after-search', failAt);
    db.prepare(`INSERT INTO history_log VALUES(?,?,?,?)`).run(
      `history-${mode}`, mode.toUpperCase(), revisionBefore, revisionAfter);
    inject('after-history', failAt);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function assertRevisionAndSearch(db, expected) {
  assert.equal(db.prepare(`SELECT content_revision FROM page_info`).get().content_revision, expected);
  assert.equal(db.prepare(`SELECT indexed_revision FROM search_page_state`).get().indexed_revision,
    expected);
}

const committed = createFixture();
const archiveBefore = JSON.stringify({
  page: queryRows(committed, 'original_deleted_page',
    'note_id,page_timestamp,page_site_id,page_index'),
  elements: queryRows(committed, 'original_deleted_page_element',
    'note_id,page_timestamp,page_site_id,page_index,element_order,element_id'),
});

applyStep(committed, 'commit');
assertRevisionAndSearch(committed, 8);
assert.deepEqual(queryRows(committed, 'page_element_snapshot', 'element_order')
  .map(row => row.element_id), ['op:21:2', 'op:22:2', 'op:30:2']);
assert.equal(queryRows(committed, 'operation_log', 'operation_id').length, 3);
assert.equal(queryRows(committed, 'history_log', 'operation_id').length, 1);

applyStep(committed, 'undo');
assertRevisionAndSearch(committed, 9);
assert.deepEqual(queryRows(committed, 'page_element_snapshot', 'element_order')
  .map(row => row.element_id), ['op:20:2', 'op:30:2']);

applyStep(committed, 'redo');
assertRevisionAndSearch(committed, 10);
assert.deepEqual(queryRows(committed, 'page_element_snapshot', 'element_order')
  .map(row => row.element_id), ['op:21:2', 'op:22:2', 'op:30:2']);
assert.equal(queryRows(committed, 'operation_log', 'operation_id').length, 5);
assert.equal(queryRows(committed, 'history_log', 'operation_id').length, 3);
assert.equal(JSON.stringify({
  page: queryRows(committed, 'original_deleted_page',
    'note_id,page_timestamp,page_site_id,page_index'),
  elements: queryRows(committed, 'original_deleted_page_element',
    'note_id,page_timestamp,page_site_id,page_index,element_order,element_id'),
}), archiveBefore);

// Faults after CREATE, delete/search invalidation, rebuild, or history append roll back page,
// archive, original operations, Harmony history and search state together.
for (const stage of ['after-create', 'after-delete', 'after-search', 'after-history']) {
  const failed = createFixture();
  const before = snapshot(failed);
  assert.throws(() => applyStep(failed, 'commit', stage), new RegExp(`injected-${stage}`));
  assert.equal(snapshot(failed), before, `${stage} must leave the whole database unchanged`);
  failed.close();
}

committed.close();
console.log('localPartialEraser=original-evidence-entity-remnants-source-delete-' +
  'transform-zindex-audio-single-revision-search-history-rollback');
