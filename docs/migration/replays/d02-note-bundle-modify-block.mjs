import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const blockSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalModifyBlockOperation.ets', rootPath), 'utf8');
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');

const TEXT = 0;
const IMAGE = 1;
const MATH = 2;

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE page_state(id TEXT PRIMARY KEY,revision INTEGER);
    CREATE TABLE block_state(
      id TEXT PRIMARY KEY,type INTEGER,page_id TEXT,archived INTEGER,
      values_json TEXT NOT NULL,winners_json TEXT NOT NULL);
    INSERT INTO page_state VALUES('live',0),('archived',0);`);
  seed(db, 'text', TEXT, 'live', false, {
    pageOrigin: ['live', 1, 2], rotation: null, scale: null, size: [200, 40],
    corner: 0, textWrap: 0, caption: false, paper: null, resizesWidth: false,
    positionLocked: false, zIndex: '10',
  });
  seed(db, 'image', IMAGE, 'live', false, {
    pageOrigin: ['live', 3, 4], rotation: null, scale: null, size: [300, 200],
    corner: 0, textWrap: 0, caption: false, crop: null, flipHorizontal: false,
    flipVertical: false, positionLocked: false, zIndex: '20',
  });
  seed(db, 'math', MATH, 'archived', true, {
    pageOrigin: ['archived', 5, 6], rotation: null, scale: null, size: [100, 50],
    corner: 0, textWrap: 0, caption: false, latex: 'x', color: -16777216,
    positionLocked: false, zIndex: '30',
  });
  return db;
}

function seed(db, id, type, pageId, archived, values) {
  db.prepare('INSERT INTO block_state VALUES(?,?,?,?,?,?)').run(
    id, type, pageId, archived ? 1 : 0, JSON.stringify(values), '{}');
}

function op(timestamp, site, targets, fields) {
  return { type: 23, timestamp, site, targets, fields };
}

function identity(operation) {
  return [operation.timestamp, operation.site];
}

function compareIdentity(left, right) {
  return left[0] === right[0] ? Math.sign(left[1] - right[1]) : Math.sign(left[0] - right[0]);
}

function same(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function fieldFamily(fields) {
  const text = 'paper' in fields || 'resizesWidth' in fields;
  const image = 'crop' in fields || 'flipHorizontal' in fields || 'flipVertical' in fields;
  const math = 'latex' in fields || 'color' in fields;
  return [text, image, math].filter(Boolean).length;
}

function preflight(operations) {
  for (const operation of operations) {
    if (operation.type !== 23) throw new Error(`NOTE_BUNDLE_PAYLOAD_${operation.type}_UNSUPPORTED`);
    if (!Array.isArray(operation.targets) || operation.targets.length === 0 ||
      new Set(operation.targets).size !== operation.targets.length) {
      throw new Error('NOTE_BUNDLE_MALFORMED_MODIFY_BLOCK_PAYLOAD');
    }
    if (fieldFamily(operation.fields) > 1) {
      throw new Error('NOTE_BUNDLE_MODIFY_BLOCK_MIXED_TYPE_SPECIFIC_FIELDS');
    }
    for (const value of Object.values(operation.fields)) {
      if (typeof value === 'number' && !Number.isFinite(value)) {
        throw new Error('NOTE_BUNDLE_MODIFY_BLOCK_GEOMETRY_UNSUPPORTED');
      }
    }
    if ('size' in operation.fields &&
      (operation.fields.size[0] < 0 || operation.fields.size[1] < 0)) {
      throw new Error('NOTE_BUNDLE_MODIFY_BLOCK_GEOMETRY_UNSUPPORTED');
    }
  }
}

function requiredType(fields) {
  if ('paper' in fields || 'resizesWidth' in fields) return TEXT;
  if ('crop' in fields || 'flipHorizontal' in fields || 'flipVertical' in fields) return IMAGE;
  if ('latex' in fields || 'color' in fields) return MATH;
  return null;
}

function applyOperation(db, operation) {
  const planned = [];
  const incoming = identity(operation);
  for (const id of operation.targets) {
    const row = db.prepare('SELECT * FROM block_state WHERE id=?').get(id);
    if (!row) throw new Error('MODIFY_BLOCK_TARGET_MISSING_OR_UNBOUND');
    const type = requiredType(operation.fields);
    if (type !== null && row.type !== type) throw new Error('MODIFY_BLOCK_TYPE_FIELDS_MISMATCH');
    const values = JSON.parse(row.values_json);
    const winners = JSON.parse(row.winners_json);
    const replacements = {};
    for (const [field, value] of Object.entries(operation.fields)) {
      const winner = winners[field] ?? null;
      if (winner !== null && compareIdentity(winner, incoming) === 0) {
        if (!same(values[field], value)) {
          throw new Error(`original modify-block identity conflicts with persisted ${field}`);
        }
        continue;
      }
      if (winner === null || compareIdentity(incoming, winner) > 0) replacements[field] = value;
    }
    planned.push({ row, values, winners, replacements });
  }
  const affectedPages = new Set();
  for (const plannedRow of planned) {
    if (Object.keys(plannedRow.replacements).length === 0) continue;
    Object.assign(plannedRow.values, plannedRow.replacements);
    for (const field of Object.keys(plannedRow.replacements)) {
      plannedRow.winners[field] = incoming;
    }
    db.prepare(`UPDATE block_state SET values_json=?,winners_json=? WHERE id=?`).run(
      JSON.stringify(plannedRow.values), JSON.stringify(plannedRow.winners), plannedRow.row.id);
    affectedPages.add(plannedRow.row.page_id);
  }
  return affectedPages;
}

function replay(db, operations, failAfter = -1) {
  try {
    preflight(operations);
  } catch (error) {
    return error.message;
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    const affectedPages = new Set();
    let applied = 0;
    for (const operation of operations) {
      for (const pageId of applyOperation(db, operation)) affectedPages.add(pageId);
      if (++applied === failAfter) throw new Error('injected bundle modify-block failure');
    }
    for (const pageId of affectedPages) {
      db.prepare('UPDATE page_state SET revision=revision+1 WHERE id=?').run(pageId);
    }
    db.exec('COMMIT');
    return null;
  } catch (error) {
    db.exec('ROLLBACK');
    return error.message;
  }
}

function value(db, id, field) {
  return JSON.parse(db.prepare('SELECT values_json FROM block_state WHERE id=?').get(id)
    .values_json)[field];
}

const operations = [
  op(100, 1, ['text', 'image'], { rotation: 0.5, scale: [2, 3],
    positionLocked: true, zIndex: '40' }),
  op(101, 1, ['text'], { paper: { color: 1, spacing: 18 }, resizesWidth: true }),
  op(102, 1, ['image'], { crop: [-5, 2, 100, 50], flipHorizontal: true,
    flipVertical: true }),
  op(103, 1, ['math'], { latex: '\\frac{a}{b}', color: -2146360781 }),
];

const db = database();
assert.equal(replay(db, operations), null);
assert.equal(value(db, 'text', 'rotation'), 0.5);
assert.deepEqual(value(db, 'text', 'scale'), [2, 3]);
assert.equal(value(db, 'text', 'positionLocked'), true);
assert.equal(value(db, 'text', 'zIndex'), '40');
assert.equal(value(db, 'text', 'resizesWidth'), true);
assert.deepEqual(value(db, 'image', 'crop'), [-5, 2, 100, 50]);
assert.equal(value(db, 'image', 'flipHorizontal'), true);
assert.equal(value(db, 'image', 'flipVertical'), true);
assert.equal(value(db, 'math', 'latex'), '\\frac{a}{b}');
assert.equal(value(db, 'math', 'color'), -2146360781);
assert.equal(db.prepare("SELECT revision FROM page_state WHERE id='live'").get().revision, 1);
assert.equal(db.prepare("SELECT revision FROM page_state WHERE id='archived'").get().revision, 1);

const snapshot = JSON.stringify(db.prepare('SELECT * FROM block_state ORDER BY id').all());
assert.equal(replay(db, operations), null);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM block_state ORDER BY id').all()), snapshot);
assert.equal(db.prepare("SELECT revision FROM page_state WHERE id='live'").get().revision, 1);

assert.match(replay(db, [op(101, 1, ['text'], {
  paper: { color: 2, spacing: 18 }, resizesWidth: true,
})]), /identity conflicts/);
assert.equal(value(db, 'text', 'paper').color, 1);

assert.equal(replay(db, [op(99, 9, ['text'], { zIndex: '1' })]), null);
assert.equal(value(db, 'text', 'zIndex'), '40');
assert.equal(db.prepare("SELECT revision FROM page_state WHERE id='live'").get().revision, 1);

for (const invalid of [
  op(200, 1, ['text'], { paper: {}, crop: null }),
  op(201, 1, [], { zIndex: '1' }),
  op(202, 1, ['text'], { size: [-1, 2] }),
]) {
  const rejected = database();
  const before = JSON.stringify(rejected.prepare('SELECT * FROM block_state ORDER BY id').all());
  assert.match(replay(rejected, [invalid]), /MIXED|MALFORMED|GEOMETRY/);
  assert.equal(JSON.stringify(rejected.prepare('SELECT * FROM block_state ORDER BY id').all()), before);
}

const failed = database();
const beforeFailure = JSON.stringify(failed.prepare('SELECT * FROM block_state ORDER BY id').all());
assert.equal(replay(failed, operations, 3), 'injected bundle modify-block failure');
assert.equal(JSON.stringify(failed.prepare('SELECT * FROM block_state ORDER BY id').all()), beforeFailure);
assert.equal(failed.prepare('SELECT SUM(revision) total FROM page_state').get().total, 0);

const missing = database();
const beforeMissing = JSON.stringify(missing.prepare('SELECT * FROM block_state ORDER BY id').all());
assert.match(replay(missing, [op(300, 1, ['missing'], { zIndex: '9' })]),
  /TARGET_MISSING/);
assert.equal(JSON.stringify(missing.prepare('SELECT * FROM block_state ORDER BY id').all()),
  beforeMissing);
assert.equal(missing.prepare('SELECT SUM(revision) total FROM page_state').get().total, 0);

assert.match(blockSource, /export function decodeOriginalModifyBlockTable/);
assert.match(blockSource, /preflightTable\(table: OriginalFlatBufferTableReader/);
assert.match(blockSource, /assertMatchingModifyBlockWinners/);
for (const group of ['pageOrigin', 'rotation', 'scale', 'size', 'corner', 'textWrap',
  'enableCaption', 'paper', 'resizesWidth', 'imageCrop', 'imageFlipHorizontal',
  'imageFlipVertical', 'mathLatex', 'mathColor', 'positionLocked', 'zIndex']) {
  assert.match(blockSource, new RegExp(`winnerMatches\\(state\\.${group}\\.winner`));
}
assert.match(bundleSource, /modifyBlock\.preflightTable/);
assert.match(bundleSource, /await modifyBlock\.applyTable/);
assert.match(bundleSource, /content diverged after preflight/);

console.log('success|bundle-modify-block=4|common-targets=2|text=1|image=1|math=1|' +
  'live-revision=1|archived-revision=1|retry-idempotent=1|identity-conflict=1|' +
  'stale-noop=1|invalid-zero-write=3|runtime-deferred-rollback=1|' +
  'failure-full-rollback=1|register-guards=16');
