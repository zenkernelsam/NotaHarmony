import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const desktopRoot = process.env.NOTABILITY_DESKTOP_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability';
const originalRoot = path.join(desktopRoot, 'decompiled_1.0.3/sources/defpackage');
const normalize = value => value.replaceAll('\r\n', '\n');
const readRepo = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const readOriginal = name => normalize(fs.readFileSync(path.join(originalRoot, name), 'utf8'));
const hashFile = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex').toUpperCase();

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

function ordered(source, needles) {
  let previous = -1;
  for (const needle of needles) {
    const current = source.indexOf(needle, previous + 1);
    if (current < 0) return false;
    previous = current;
  }
  return true;
}

const vnfPath = path.join(desktopRoot, '.codex-tmp-phase273-vnf-simple.java');
const vnf = normalize(fs.readFileSync(vnfPath, 'utf8'));
const u5j = readOriginal('u5j.java');
const xj2 = readOriginal('xj2.java');
const er6 = readOriginal('er6.java');
const m09 = readOriginal('m09.java');
const a79 = readOriginal('a79.java');
const dhh = readOriginal('dhh.java');

check('reviewed original and simplified JADX evidence hashes are pinned',
  hashFile(vnfPath) === '01B9909A8979D966360432BAAE84E3E49CC64D18715F4561853D49A6A7281FD2' &&
  hashFile(path.join(originalRoot, 'u5j.java')) ===
    'F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC' &&
  hashFile(path.join(originalRoot, 'xj2.java')) ===
    '1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C' &&
  hashFile(path.join(originalRoot, 'er6.java')) ===
    '2B3A14557D9289DD6C5E66DA96DCB0B884129B4DDFFB0D988F73C758CDF12724' &&
  hashFile(path.join(originalRoot, 'm09.java')) ===
    '3B6E92A54E7A5F15BB450A8B89A0A62ED25F2882D65F159595303CD29B6B214A' &&
  hashFile(path.join(originalRoot, 'a79.java')) ===
    'FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13' &&
  hashFile(path.join(originalRoot, 'dhh.java')) ===
    '393843AF7454BDEF6DD8A4B06679CDD6548E3296183944A89F9521E8A680B900');

check('original SET_METADATA undo reads each touched current register and builds a new inverse action',
  /l2d r209 = \(l2d\) zq9\.c\(r23\)/.test(vnf) &&
  /if \(r209\.n\(\) == null\)[\s\S]*xj2\.v\(\(\(a79\)[\s\S]*\.A, a79\.M\[6\]\)/.test(vnf) &&
  /if \(r209\.j\(\) == null\)[\s\S]*xj2\.v\(\(\(a79\)[\s\S]*\.w, a79\.M\[3\]\)/.test(vnf) &&
  /u5j\.H\(r112, r298, r299, r2100, r2101, r2102, r2103, r2104, r2105\)/.test(vnf));
check('original u5j.H forwards the snapshot to a newly encoded xj2 SET_METADATA',
  /public static final l2d H\([\s\S]*return xj2\.d\(z2dVar, m2dVar, z2dVar2, f, str, bool, tv6Var, dz0Var, 256\)/.test(u5j));
check('original nullable ordinary scalar inputs are omitted while false and zero remain force-present',
  /if \(f2 != null\)[\s\S]*aVar\.d\(5, f2\.floatValue\(\), 0\.0d\)/.test(xj2) &&
  /if \(bool != null\)[\s\S]*aVar\.l = true;[\s\S]*aVar\.a\(3, zBooleanValue, false\)/.test(xj2) &&
  /if \(tv6Var != null\)[\s\S]*aVar\.c\(6, tv6Var\.I, 0\)/.test(xj2) &&
  /if \(dz0Var != null\)[\s\S]*aVar\.c\(7, dz0Var\.b\(\), 0\)/.test(xj2));
check('original handwriting wrapper can be present with an absent inner string',
  /int iC = str != null \? dbj\.c\(str, aVarA\) : 0/.test(dhh) &&
  /aVarA\.C\(1\);[\s\S]*aVarA\.h\(0, iC\)/.test(dhh));
check('original note registers accept nullable initial values and blank-note construction passes nulls',
  (er6.match(/new yc6\(obj2,/g) ?? []).length >= 8 &&
  /return a79\.L\.c\(ye9Var, list, str,[\s\S]*\? null : null/.test(m09) &&
  /"defaultFontFamily"[\s\S]*"defaultFontSize"[\s\S]*"alignTextToLines"[\s\S]*"layoutMode"[\s\S]*"blockWrapSupport"[\s\S]*"handwritingLanguage"/.test(a79));

const codec = readRepo('note/src/main/ets/data/NoteMetadataMutationCodec.ets');
const persistence = readRepo('note/src/main/ets/data/OriginalNoteMetadataPersistence.ets');
const repository = readRepo('note/src/main/ets/data/NoteRepositoryImpl.ets');
const history = readRepo('note/src/main/ets/data/PersistentHistory.ets');
const manager = readRepo('note/src/main/ets/rendering/UndoRedoManager.ets');
const editor = readRepo('note/src/main/ets/ui/editor/NotePage.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const opTypes = readRepo('note/src/main/ets/core/model/OpTypes.ets');
const fixture = readRepo('note/src/test/NoteMetadataMutationCodec.test.ets');
const historyFixture = readRepo('note/src/test/PersistentHistory.test.ets');
const fixtureList = readRepo('note/src/test/List.test.ets');

check('Harmony uses a distinct NMD1 companion with six touched-field bits',
  /const MAGIC: number\[\] = \[0x4E, 0x4D, 0x44, 0x31\]/.test(codec) &&
  /NOTE_METADATA_FIELD_HANDWRITING_LANGUAGE: number = 1/.test(codec) &&
  /NOTE_METADATA_FIELD_BLOCK_WRAP_SUPPORT: number = 32/.test(codec) &&
  /NOTE_METADATA_FIELD_ALL: number = 63/.test(codec));
check('companion validation requires one revision step a non-empty mask and an actual touched change',
  /mutation\.toRevision !== mutation\.fromRevision \+ 1/.test(codec) &&
  /fieldMask <= 0/.test(codec) &&
  /fieldMask & ~NOTE_METADATA_FIELD_ALL/.test(codec) &&
  /mutation does not change a touched register/.test(codec));
check('companion JSON decoder rejects non-object missing extra and wrong-typed fields',
  /typeof parsed !== 'object' \|\| Array\.isArray\(parsed\)/.test(codec) &&
  /keys\.length !== fields\.length/.test(codec) &&
  /!keys\.includes\(key\)/.test(codec) &&
  /typeof state\.alignTextToLines !== 'boolean'/.test(codec) &&
  /typeof state\.defaultFontSize !== 'number'/.test(codec));
check('ordinary touched null values fail closed while handwriting touched null remains encodable',
  /state\.alignTextToLines === null/.test(codec) &&
  /state\.defaultFontFamily === null/.test(codec) &&
  /state\.defaultFontSize === null/.test(codec) &&
  /hasHandwritingLanguage:[\s\S]*handwritingLanguage: handwriting/.test(codec));
check('every durable state must be re-encodable by the production original writer',
  /encodeOriginalSetMetadataFields\(patchFromValidatedState\(state, fieldMask\)\)/.test(codec) &&
  /state cannot be restored on original wire/.test(codec) &&
  /rejects history values that the local original writer cannot restore/.test(fixture));

const persistenceBody = persistence.slice(persistence.indexOf(
  'export async function persistOriginalNoteMetadata'));
const originalAppend = persistenceBody.indexOf('opType: OpType.ORIGINAL_SET_METADATA');
const companionAppend = persistenceBody.indexOf('opType: OpType.UPDATE_NOTE_METADATA');
check('ordinary local outbound without history does not construct an irreversible before snapshot',
  /let beforeHistoryState: NoteMetadataMutationState \| null = null;[\s\S]*if \(history !== undefined\) \{[\s\S]*beforeHistoryState = historyStateFromOriginalState/.test(persistenceBody));
check('history metadata and page identity are validated before any operation identity allocation',
  ordered(persistenceBody, [
    'validateHistoryMetadata(history)',
    'await requireLiveSelectedPage(store, noteId, selectedPageId)',
    'const identity: AllocatedOperationIdentity',
  ]));
check('undo and redo require an expected source and compare it before mutation',
  /history\.effect !== HistoryEffect\.PUSH && expectedSource === undefined/.test(persistenceBody) &&
  ordered(persistenceBody, [
    'sameNoteMetadataMutationState(beforeHistoryState, expectedSource, fieldMask)',
    'const identity: AllocatedOperationIdentity',
  ]) &&
  /history source state changed concurrently/.test(persistenceBody));
check('absent winners have explicit history failure gates for all six registers',
  ['handwriting winner is absent', 'align winner is absent', 'font-family winner is absent',
    'font-size winner is absent', 'layout winner is absent', 'block-wrap winner is absent']
    .every(value => persistence.includes(value)));
check('the uploadable original row precedes the local-only history companion',
  originalAppend >= 0 && companionAppend > originalAppend &&
  /uploadImmediately: true/.test(persistenceBody) &&
  /history: history/.test(persistenceBody));
check('repository owns one mutex transaction and rolls both rows back together',
  /async updateOriginalNoteMetadata\(/.test(repository) &&
  /libraryMetadataMutationMutex\.runExclusive/.test(repository) &&
  /await store\.beginTransaction\(\)/.test(repository) &&
  /await persistOriginalNoteMetadata\(/.test(repository) &&
  /await store\.rollBack\(\)/.test(repository) &&
  !/beginTransaction\(|\.commit\(|\.rollBack\(/.test(persistenceBody));
check('persistent history materializes exactly one note metadata companion',
  /OpType\.UPDATE_NOTE_METADATA/.test(history) &&
  /persistent note metadata action must contain exactly one mutation/.test(history) &&
  /UndoableActionType\.NOTE_METADATA/.test(history));
check('runtime manager and editor route metadata through durable source-checked Undo and Redo',
  /NOTE_METADATA = 23/.test(manager) &&
  /metadataBefore: NoteMetadataHistoryState/.test(manager) &&
  /type === UndoableActionType\.NOTE_METADATA/.test(canvas) &&
  /patchFromNoteMetadataState\(target, action\.fieldMask\)/.test(editor) &&
  /updateOriginalNoteMetadata\([\s\S]*history, source/.test(editor));
check('ArkTS fixtures cover codec corruption history materialization and suite registration',
  /fails closed on malformed JSON shape types and trailing bytes/.test(fixture) &&
  /rejects absent ordinary winners/.test(fixture) &&
  /keeps the original metadata action across durable undo and redo movements/.test(historyFixture) &&
  /rejects a metadata action containing more than one companion mutation/.test(historyFixture) &&
  /noteMetadataMutationCodecTest\(\)/.test(fixtureList));
check('operation and action enums reserve dedicated stable values',
  /UPDATE_NOTE_METADATA = 35/.test(opTypes) && /NOTE_METADATA = 23/.test(manager));

const fields = [
  { name: 'handwritingLanguage', bit: 1, nullable: true },
  { name: 'alignTextToLines', bit: 2, nullable: false },
  { name: 'defaultFontFamily', bit: 4, nullable: false },
  { name: 'defaultFontSize', bit: 8, nullable: false },
  { name: 'layoutMode', bit: 16, nullable: false },
  { name: 'blockWrapSupport', bit: 32, nullable: false },
];

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys = ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY, revision INTEGER NOT NULL, updated_at INTEGER NOT NULL);
  CREATE TABLE page_info(note_id TEXT NOT NULL, page_id TEXT NOT NULL,
    PRIMARY KEY(note_id,page_id), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE winner(note_id TEXT NOT NULL, field TEXT NOT NULL, value TEXT,
    winner_ts INTEGER NOT NULL, winner_site INTEGER NOT NULL,
    PRIMARY KEY(note_id,field), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT, note_id TEXT NOT NULL,
    op_ts INTEGER NOT NULL, kind TEXT NOT NULL, upload INTEGER NOT NULL,
    action_id TEXT, effect TEXT, field_mask INTEGER);
  INSERT INTO note_meta VALUES('note',10,1000),('fresh',0,1000),('fresh-history',0,1000);
  INSERT INTO page_info VALUES('note','page-1'),('fresh','page-1'),('fresh-history','page-1');`);

function encodeValue(value) {
  if (value === null) return null;
  return JSON.stringify(value);
}

function decodeValue(value) {
  return value === null ? null : JSON.parse(value);
}

function maskOf(patch) {
  let mask = 0;
  for (const field of fields) {
    if (Object.hasOwn(patch, field.name)) mask |= field.bit;
  }
  return mask;
}

function winner(noteId, name) {
  const row = db.prepare('SELECT value,winner_ts,winner_site FROM winner WHERE note_id=? AND field=?')
    .get(noteId, name);
  return row === undefined ? null : {
    value: decodeValue(row.value), timestamp: row.winner_ts, siteId: row.winner_site,
  };
}

function touchedState(noteId, mask, requirePresence) {
  const state = {};
  for (const field of fields) {
    if ((mask & field.bit) === 0) {
      state[field.name] = null;
      continue;
    }
    const row = winner(noteId, field.name);
    if (row === null) {
      if (requirePresence) throw new Error(`${field.name} winner is absent`);
      state[field.name] = null;
    } else {
      state[field.name] = row.value;
    }
  }
  return state;
}

function sameTouched(left, right, mask) {
  return fields.every(field => (mask & field.bit) === 0 ||
    Object.is(left[field.name], right[field.name]));
}

function validatePatch(patch) {
  const mask = maskOf(patch);
  assert(mask > 0);
  for (const field of fields) {
    if (!Object.hasOwn(patch, field.name)) continue;
    const value = patch[field.name];
    if (value === null && !field.nullable) throw new Error('ordinary null is not encodable');
  }
  return mask;
}

function nextTimestamp(noteId) {
  const row = db.prepare('SELECT COALESCE(MAX(op_ts),0) value FROM operation_log WHERE note_id=?')
    .get(noteId);
  return row.value + 1;
}

function applyAtomic(noteId, patch, options = {}) {
  const mask = validatePatch(patch);
  db.exec('BEGIN IMMEDIATE');
  try {
    const page = db.prepare('SELECT 1 ok FROM page_info WHERE note_id=? AND page_id=?')
      .get(noteId, options.selectedPageId ?? 'page-1');
    assert(page !== undefined);
    const note = db.prepare('SELECT revision,updated_at FROM note_meta WHERE id=?').get(noteId);
    assert(note !== undefined);
    let beforeHistory = null;
    if (options.history !== undefined) {
      beforeHistory = touchedState(noteId, mask, true);
      if (options.history.effect !== 'PUSH' && options.expectedSource === undefined) {
        throw new Error('expected source required');
      }
      if (options.expectedSource !== undefined &&
        !sameTouched(beforeHistory, options.expectedSource, mask)) {
        throw new Error('source state changed concurrently');
      }
    }
    let changed = false;
    for (const field of fields) {
      if (!Object.hasOwn(patch, field.name)) continue;
      const row = winner(noteId, field.name);
      if (row === null || !Object.is(row.value, patch[field.name])) changed = true;
    }
    if (!changed) throw new Error('unchanged');
    const originalTimestamp = nextTimestamp(noteId);
    for (const field of fields) {
      if (!Object.hasOwn(patch, field.name)) continue;
      db.prepare(`INSERT INTO winner(note_id,field,value,winner_ts,winner_site) VALUES(?,?,?,?,7)
        ON CONFLICT(note_id,field) DO UPDATE SET value=excluded.value,
          winner_ts=excluded.winner_ts,winner_site=excluded.winner_site`)
        .run(noteId, field.name, encodeValue(patch[field.name]), originalTimestamp);
    }
    db.prepare('UPDATE note_meta SET revision=revision+1,updated_at=MAX(updated_at,?) WHERE id=?')
      .run(2000 + originalTimestamp, noteId);
    db.prepare(`INSERT INTO operation_log(note_id,op_ts,kind,upload,field_mask)
      VALUES(?,?,'ORIGINAL_SET_METADATA',1,?)`).run(noteId, originalTimestamp, mask);
    if (options.failAfterOriginal === true) throw new Error('injected companion failure');
    const afterHistory = options.history === undefined ? null : touchedState(noteId, mask, true);
    if (options.history !== undefined) {
      const companionTimestamp = nextTimestamp(noteId);
      db.prepare(`INSERT INTO operation_log(note_id,op_ts,kind,upload,action_id,effect,field_mask)
        VALUES(?,?,'UPDATE_NOTE_METADATA',0,?,?,?)`)
        .run(noteId, companionTimestamp, options.history.actionId, options.history.effect, mask);
    }
    db.exec('COMMIT');
    return {
      fromRevision: note.revision, toRevision: note.revision + 1,
      fieldMask: mask, before: beforeHistory, after: afterHistory,
    };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function initializeWinners(noteId) {
  const initial = {
    handwritingLanguage: null,
    alignTextToLines: false,
    defaultFontFamily: '',
    defaultFontSize: 1,
    layoutMode: 0,
    blockWrapSupport: 0,
  };
  for (const field of fields) {
    db.prepare('INSERT INTO winner VALUES(?,?,?,?,?)')
      .run(noteId, field.name, encodeValue(initial[field.name]), 1, 7);
  }
}

function snapshot(noteId) {
  return JSON.stringify({
    note: db.prepare('SELECT * FROM note_meta WHERE id=?').get(noteId),
    winners: db.prepare('SELECT * FROM winner WHERE note_id=? ORDER BY field').all(noteId),
    operations: db.prepare('SELECT * FROM operation_log WHERE note_id=? ORDER BY sequence').all(noteId),
  });
}

const firstWrite = applyAtomic('fresh', { alignTextToLines: false });
check('independent model permits a first ordinary winner write when no history is requested',
  firstWrite.before === null && winner('fresh', 'alignTextToLines').value === false &&
  db.prepare("SELECT COUNT(*) count FROM operation_log WHERE note_id='fresh'").get().count === 1);

const absentBefore = snapshot('fresh-history');
assert.throws(() => applyAtomic('fresh-history', { alignTextToLines: true }, {
  history: { actionId: 'absent', effect: 'PUSH' },
}), /winner is absent/);
check('independent model rejects irreversible history but rolls back the requested write',
  snapshot('fresh-history') === absentBefore);

initializeWinners('note');
const push = applyAtomic('note', {
  handwritingLanguage: 'en_US', alignTextToLines: true, layoutMode: 1,
}, { history: { actionId: 'metadata-action', effect: 'PUSH' } });
check('PUSH captures explicit-null handwriting false and zero before writing new winners',
  push.before.handwritingLanguage === null && push.before.alignTextToLines === false &&
  push.before.layoutMode === 0 && push.after.handwritingLanguage === 'en_US' &&
  push.after.alignTextToLines === true && push.after.layoutMode === 1);
check('PUSH advances revision once and writes original then companion rows',
  push.fromRevision === 10 && push.toRevision === 11 &&
  db.prepare("SELECT revision FROM note_meta WHERE id='note'").get().revision === 11 &&
  db.prepare("SELECT kind FROM operation_log WHERE note_id='note' ORDER BY sequence LIMIT 1").get().kind ===
    'ORIGINAL_SET_METADATA');

applyAtomic('note', { defaultFontFamily: 'Serif' });
const undo = applyAtomic('note', {
  handwritingLanguage: null, alignTextToLines: false, layoutMode: 0,
}, {
  history: { actionId: 'metadata-action', effect: 'UNDO' },
  expectedSource: push.after,
});
check('UNDO writes a newer SET_METADATA and restores touched values including explicit null',
  winner('note', 'handwritingLanguage') !== null &&
  winner('note', 'handwritingLanguage').value === null &&
  winner('note', 'alignTextToLines').value === false && winner('note', 'layoutMode').value === 0 &&
  undo.before.handwritingLanguage === 'en_US' && undo.after.handwritingLanguage === null);
check('an unrelated winner change is preserved and does not invalidate touched source state',
  winner('note', 'defaultFontFamily').value === 'Serif' &&
  winner('note', 'blockWrapSupport').value === 0);

const redo = applyAtomic('note', {
  handwritingLanguage: 'en_US', alignTextToLines: true, layoutMode: 1,
}, {
  history: { actionId: 'metadata-action', effect: 'REDO' },
  expectedSource: undo.after,
});
check('REDO writes another newer SET_METADATA instead of restoring an old operation identity',
  redo.after.alignTextToLines === true && redo.after.layoutMode === 1 &&
  winner('note', 'alignTextToLines').timestamp > winner('note', 'defaultFontFamily').timestamp);

applyAtomic('note', { alignTextToLines: false });
const beforeConflict = snapshot('note');
assert.throws(() => applyAtomic('note', {
  handwritingLanguage: null, alignTextToLines: false, layoutMode: 0,
}, {
  history: { actionId: 'metadata-action', effect: 'UNDO' },
  expectedSource: redo.after,
}), /source state changed concurrently/);
check('concurrent touched-source mismatch performs no winner revision or log mutation',
  snapshot('note') === beforeConflict);

const beforeFailure = snapshot('note');
assert.throws(() => applyAtomic('note', { layoutMode: 0 }, {
  history: { actionId: 'rollback-action', effect: 'PUSH' }, failAfterOriginal: true,
}), /injected companion failure/);
check('companion append failure rolls the original winner revision and upload row back together',
  snapshot('note') === beforeFailure);

const operations = db.prepare(`SELECT kind,upload,action_id,effect,op_ts
  FROM operation_log WHERE note_id='note' ORDER BY sequence`).all();
check('successful operation log keeps upload rows transparent and companion effects ordered',
  operations.map(row => row.kind).join(',') ===
    'ORIGINAL_SET_METADATA,UPDATE_NOTE_METADATA,ORIGINAL_SET_METADATA,' +
    'ORIGINAL_SET_METADATA,UPDATE_NOTE_METADATA,ORIGINAL_SET_METADATA,' +
    'UPDATE_NOTE_METADATA,ORIGINAL_SET_METADATA' &&
  operations.filter(row => row.kind === 'ORIGINAL_SET_METADATA').every(row => row.upload === 1) &&
  operations.filter(row => row.kind === 'UPDATE_NOTE_METADATA').every(row => row.upload === 0) &&
  operations.filter(row => row.kind === 'UPDATE_NOTE_METADATA').map(row => row.effect).join(',') ===
    'PUSH,UNDO,REDO');
check('operation identities are strictly increasing and companions never advance document revision',
  operations.every((row, index) => index === 0 || row.op_ts > operations[index - 1].op_ts) &&
  db.prepare("SELECT revision FROM note_meta WHERE id='note'").get().revision === 15);

db.close();

if (failed > 0) {
  console.error(`D02_ORIGINAL_SET_METADATA_HISTORY_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_ORIGINAL_SET_METADATA_HISTORY_OK TOTAL=${total} FAILED=0`);
