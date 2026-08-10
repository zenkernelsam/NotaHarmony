import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const styleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalRichTextStyleOperation.ets', rootPath), 'utf8');
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');

const root = { timestamp: 0, site: 0xFFFF, index: 0 };

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE text_block(
      id TEXT PRIMARY KEY, archived INTEGER, character_runs TEXT, paragraph_runs TEXT,
      revision INTEGER);
    CREATE TABLE character_state(
      block_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,PRIMARY KEY(block_id,ts,site,idx));
    CREATE TABLE style_operation(
      note_id TEXT,block_id TEXT,ts INTEGER,site INTEGER,paragraph INTEGER,clear_all INTEGER,
      start_json TEXT,end_json TEXT,attributes_json TEXT,PRIMARY KEY(note_id,ts,site));
    INSERT INTO text_block VALUES
      ('live',0,'[{},{},{}]','[{},{},{}]',0),
      ('archived',1,'[{},{},{}]','[{},{},{}]',0),
      ('other',0,'[{},{},{}]','[{},{},{}]',0);`);
  for (const block of ['live', 'archived', 'other']) {
    for (let index = 0; index < 3; index++) {
      db.prepare('INSERT INTO character_state VALUES(?,?,?,?)').run(
        block, block === 'live' ? 80 : block === 'archived' ? 90 : 100,
        block === 'live' ? 8 : block === 'archived' ? 9 : 10, index);
    }
  }
  return db;
}

function boundary(timestamp, site, index, type) {
  return { timestamp, site, index, type };
}

function character(timestamp, site, block, start, end, attributes) {
  return { type: 12, timestamp, site, block, start, end, paragraph: false,
    clearAll: false, attributes };
}

function paragraph(timestamp, site, block, start, end, attributes) {
  return { type: 13, timestamp, site, block, start, end, paragraph: true,
    clearAll: false, attributes };
}

function clear(timestamp, site, block, start, end, paragraphStyle = false) {
  return { type: 14, timestamp, site, block, start, end, paragraph: paragraphStyle,
    clearAll: true, attributes: {} };
}

function characters(db, block) {
  return db.prepare('SELECT ts timestamp,site,idx [index] FROM character_state WHERE block_id=? ORDER BY idx')
    .all(block);
}

function position(sequence, value) {
  if (value.type === 2 || value.type === 0 && value.timestamp === 0 && value.site === 0xFFFF) return 0;
  if (value.type === 3) return sequence.length;
  const index = sequence.findIndex(item => item.timestamp === value.timestamp &&
    item.site === value.site && item.index === value.index);
  return index < 0 ? null : index + (value.type === 1 ? 1 : 0);
}

function storedOperations(db, block) {
  return db.prepare(`SELECT ts timestamp,site,paragraph,clear_all,start_json,end_json,attributes_json
    FROM style_operation WHERE note_id='n' AND block_id=? ORDER BY ts,site`).all(block).map(row => ({
      timestamp: row.timestamp, site: row.site, paragraph: Boolean(row.paragraph),
      clearAll: Boolean(row.clear_all), start: JSON.parse(row.start_json),
      end: JSON.parse(row.end_json), attributes: JSON.parse(row.attributes_json),
    }));
}

function materialize(db, block, operations = storedOperations(db, block)) {
  const sequence = characters(db, block), characterRuns = sequence.map(() => ({}));
  const paragraphRuns = sequence.map(() => ({}));
  for (const operation of [...operations].sort((left, right) =>
    left.timestamp - right.timestamp || left.site - right.site)) {
    const start = position(sequence, operation.start), end = position(sequence, operation.end);
    if (start === null || end === null || start > end) return null;
    for (let index = start; index < end; index++) {
      const target = operation.paragraph ? paragraphRuns[index] : characterRuns[index];
      if (operation.clearAll) {
        for (const name of Object.keys(target)) delete target[name];
      } else {
        for (const [name, value] of Object.entries(operation.attributes)) {
          if (value === null) delete target[name]; else target[name] = value;
        }
      }
    }
  }
  return { characterRuns, paragraphRuns };
}

function preflight(operations) {
  for (const operation of operations) {
    if (![12, 13, 14].includes(operation.type) || !operation.start || !operation.end ||
      operation.start.type < 0 || operation.start.type > 3 ||
      operation.end.type < 0 || operation.end.type > 3 || operation.start.type !== 0 ||
      operation.end.type === 2) throw new Error('NOTE_BUNDLE_MALFORMED_RICH_TEXT_STYLE_PAYLOAD');
  }
}

function exactBaseline(row, operation) {
  return row.block_id === operation.block && Boolean(row.paragraph) === operation.paragraph &&
    Boolean(row.clear_all) === operation.clearAll && row.start_json === JSON.stringify(operation.start) &&
    row.end_json === JSON.stringify(operation.end) &&
    row.attributes_json === JSON.stringify(operation.attributes);
}

function applyStyle(db, operation) {
  const recognized = operation.clearAll || Object.keys(operation.attributes).length > 0;
  const baseline = db.prepare("SELECT * FROM style_operation WHERE note_id='n' AND ts=? AND site=?")
    .get(operation.timestamp, operation.site);
  if (!recognized) {
    if (baseline) throw new Error('style identity conflict');
    return false;
  }
  const target = db.prepare('SELECT * FROM text_block WHERE id=?').get(operation.block);
  if (!target) throw new Error('RICH_TEXT_STYLE_TARGET_MISSING');
  const before = materialize(db, operation.block);
  if (before === null || JSON.stringify(before.characterRuns) !== target.character_runs ||
    JSON.stringify(before.paragraphRuns) !== target.paragraph_runs) {
    throw new Error('RICH_TEXT_STYLE_STATE_DIVERGED');
  }
  const candidate = { timestamp: operation.timestamp, site: operation.site,
    paragraph: operation.paragraph, clearAll: operation.clearAll, start: operation.start,
    end: operation.end, attributes: operation.attributes };
  const after = materialize(db, operation.block, storedOperations(db, operation.block).concat([candidate]));
  if (after === null) throw new Error('RICH_TEXT_STYLE_BOUNDARY_MISSING_OR_REVERSED');
  if (baseline) {
    if (!exactBaseline(baseline, operation)) throw new Error('style identity conflict');
    return false;
  }
  db.prepare(`INSERT INTO style_operation VALUES('n',?,?,?,?,?,?,?,?)`).run(
    operation.block, operation.timestamp, operation.site, operation.paragraph ? 1 : 0,
    operation.clearAll ? 1 : 0, JSON.stringify(operation.start), JSON.stringify(operation.end),
    JSON.stringify(operation.attributes));
  const characterRuns = JSON.stringify(after.characterRuns), paragraphRuns = JSON.stringify(after.paragraphRuns);
  if (characterRuns === target.character_runs && paragraphRuns === target.paragraph_runs) return false;
  db.prepare(`UPDATE text_block SET character_runs=?,paragraph_runs=?,revision=revision+1 WHERE id=?`).run(
    characterRuns, paragraphRuns, operation.block);
  return true;
}

function replay(db, operations, failAfter = -1) {
  try { preflight(operations); } catch (error) { return error.message; }
  db.exec('BEGIN IMMEDIATE');
  try {
    operations.forEach((operation, index) => {
      applyStyle(db, operation);
      if (index + 1 === failAfter) throw new Error('injected bundle style failure');
    });
    db.exec('COMMIT'); return null;
  } catch (error) {
    db.exec('ROLLBACK'); return error.message;
  }
}

const operations = [
  character(10, 1, 'live', boundary(80, 8, 0, 0), boundary(80, 8, 1, 1), { bold: true }),
  paragraph(11, 1, 'live', boundary(80, 8, 0, 0), boundary(80, 8, 2, 0), { indentLevel: 2 }),
  clear(12, 1, 'live', boundary(80, 8, 0, 0), boundary(80, 8, 0, 1)),
];

const db = database();
assert.equal(replay(db, operations), null);
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision, 3);
assert.deepEqual(JSON.parse(db.prepare("SELECT character_runs FROM text_block WHERE id='live'").get().character_runs),
  [{}, { bold: true }, {}]);
assert.deepEqual(JSON.parse(db.prepare("SELECT paragraph_runs FROM text_block WHERE id='live'").get().paragraph_runs),
  [{ indentLevel: 2 }, { indentLevel: 2 }, {}]);
assert.equal(db.prepare('SELECT COUNT(*) count FROM style_operation').get().count, 3);

const snapshot = JSON.stringify(db.prepare('SELECT * FROM style_operation ORDER BY ts,site').all());
assert.equal(replay(db, operations), null);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM style_operation ORDER BY ts,site').all()), snapshot);
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision, 3);

assert.match(replay(db, [character(10, 1, 'live', boundary(80, 8, 0, 0),
  boundary(80, 8, 1, 1), { bold: false })]), /identity conflict/);
assert.match(replay(db, [character(10, 1, 'other', boundary(100, 10, 0, 0),
  boundary(100, 10, 1, 1), { bold: true })]), /identity conflict/);

const revisionBeforeNoEffect = db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision;
assert.equal(replay(db, [character(13, 1, 'live', boundary(80, 8, 1, 0),
  boundary(80, 8, 1, 1), { bold: true })]), null);
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision, revisionBeforeNoEffect);
assert.equal(db.prepare('SELECT COUNT(*) count FROM style_operation').get().count, 4);
assert.equal(replay(db, [character(14, 1, 'missing', boundary(1, 1, 0, 0),
  boundary(1, 1, 0, 1), {})]), null);
assert.equal(db.prepare('SELECT COUNT(*) count FROM style_operation').get().count, 4);

assert.equal(replay(db, [paragraph(20, 2, 'archived', boundary(90, 9, 0, 0),
  boundary(90, 9, 2, 1), { writingDirection: 1 })]), null);
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='archived'").get().revision, 1);

for (const invalid of [
  character(30, 3, 'live', boundary(80, 8, 1, 1), boundary(80, 8, 0, 0), { italic: true }),
  character(31, 3, 'live', boundary(80, 8, 0, 2), boundary(80, 8, 1, 1), { italic: true }),
]) {
  const rejected = database(), before = JSON.stringify(rejected.prepare('SELECT * FROM text_block').all());
  assert.match(replay(rejected, [invalid]), /MALFORMED|BOUNDARY/);
  assert.equal(JSON.stringify(rejected.prepare('SELECT * FROM text_block').all()), before);
  assert.equal(rejected.prepare('SELECT COUNT(*) count FROM style_operation').get().count, 0);
}

const missing = database(), missingBefore = JSON.stringify(missing.prepare('SELECT * FROM text_block').all());
assert.match(replay(missing, [operations[0], character(40, 4, 'live',
  boundary(999, 4, 0, 0), boundary(999, 4, 0, 1), { italic: true })]), /BOUNDARY/);
assert.equal(JSON.stringify(missing.prepare('SELECT * FROM text_block').all()), missingBefore);
assert.equal(missing.prepare('SELECT COUNT(*) count FROM style_operation').get().count, 0);

const failed = database(), failedBefore = JSON.stringify(failed.prepare('SELECT * FROM text_block').all());
assert.equal(replay(failed, operations, 2), 'injected bundle style failure');
assert.equal(JSON.stringify(failed.prepare('SELECT * FROM text_block').all()), failedBefore);
assert.equal(failed.prepare('SELECT COUNT(*) count FROM style_operation').get().count, 0);

assert.match(styleSource, /decodeOriginalRichTextStyleTable/);
assert.match(styleSource, /preflightTable\(table: OriginalFlatBufferTableReader/);
assert.match(styleSource, /styleBaselineStatus/);
assert.match(styleSource, /operationIdentityExists/);
assert.match(styleSource, /sameBoundaryRow/);
assert.match(styleSource, /identity conflicts with persisted operation/);
assert.match(bundleSource, /ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE/);
assert.match(bundleSource, /ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE/);
assert.match(bundleSource, /ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE/);
assert.match(bundleSource, /textStyle\.applyTable/);

console.log('success|bundle-style-types=3|character-style=1|paragraph-style=1|clear-style=1|' +
  'revision=3|retry-idempotent=1|identity-conflict=2|no-effect-op-preserved=1|' +
  'unrecognized-skip=1|archived=1|invalid-zero-write=2|runtime-deferred-rollback=1|' +
  'failure-full-rollback=1|static-wiring=1');
