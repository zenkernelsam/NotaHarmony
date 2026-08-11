import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const reducerSource = read('note/src/main/ets/data/OriginalModifyPositionsOperation.ets');
const batchSource = read('note/src/main/ets/data/OriginalPageMutationBatch.ets');
const routerSource = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundleSource = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const inkSource = read('note/src/main/ets/data/OriginalModifyInkOperation.ets');
const blockSource = read('note/src/main/ets/data/OriginalModifyBlockOperation.ets');
const fixtureSource = read('note/src/test/SyncedOperationInbox.test.ets');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE page_state(id TEXT PRIMARY KEY,revision INTEGER NOT NULL);
    CREATE TABLE entity(
      id TEXT PRIMARY KEY,kind TEXT NOT NULL,page_id TEXT NOT NULL,x REAL,y REAL,
      rotation REAL,scale_x REAL,scale_y REAL,z_index TEXT NOT NULL,
      values_json TEXT NOT NULL,winners_json TEXT NOT NULL);
    CREATE TABLE search_item(page_id TEXT NOT NULL,type TEXT NOT NULL);
    INSERT INTO page_state VALUES('page-a',7),('page-b',3);
    INSERT INTO search_item VALUES('page-a','INK'),('page-a','TEXT_BLOCK');`);
  seed(db, 'ink', 'INK', 'page-a', 1, 2, 0.25, 2, 2, '10');
  seed(db, 'text', 'BLOCK', 'page-a', 3, 4, 0.5, 3, 3, '20');
  seed(db, 'shape', 'SHAPE', 'page-a', 5, 6, 0, 1, 1, '30');
  return db;
}

function seed(db, id, kind, pageId, x, y, rotation, scaleX, scaleY, zIndex) {
  const values = { pageId, x, y, rotation, scale: [scaleX, scaleY], zIndex };
  db.prepare(`INSERT INTO entity VALUES(?,?,?,?,?,?,?,?,?,?,?)`).run(
    id, kind, pageId, x, y, rotation, scaleX, scaleY, zIndex,
    JSON.stringify(values), JSON.stringify({}));
}

function compareIdentity(left, right) {
  return left[0] === right[0] ? Math.sign(left[1] - right[1]) : Math.sign(left[0] - right[0]);
}

function same(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function classifyAll(db, modifications) {
  if (!Array.isArray(modifications) || modifications.length === 0 ||
    new Set(modifications.map(item => item.target)).size !== modifications.length) {
    return 'MALFORMED_MODIFY_POSITIONS_PAYLOAD';
  }
  const classified = [];
  for (const modification of modifications) {
    const row = db.prepare('SELECT kind FROM entity WHERE id=?').get(modification.target);
    if (!row) return 'MODIFY_POSITIONS_TARGET_MISSING';
    if (row.kind === 'SHAPE' || row.kind === 'GROUP') {
      return 'MODIFY_POSITIONS_SHAPE_OR_GROUP_UNSUPPORTED';
    }
    if (row.kind !== 'INK' && row.kind !== 'BLOCK') {
      return 'MODIFY_POSITIONS_TARGET_STATE_DIVERGED';
    }
    classified.push({ ...modification, kind: row.kind });
  }
  return classified;
}

function applyRegister(values, winners, field, value, operation) {
  const winner = winners[field] ?? null;
  if (winner !== null && compareIdentity(operation, winner) === 0) {
    if (!same(values[field], value)) throw new Error(`identity conflict: ${field}`);
    return false;
  }
  if (winner !== null && compareIdentity(operation, winner) < 0) return false;
  values[field] = value;
  winners[field] = operation;
  return true;
}

function applyOne(db, modification, operation, affectedPages) {
  const row = db.prepare('SELECT * FROM entity WHERE id=?').get(modification.target);
  const values = JSON.parse(row.values_json);
  const winners = JSON.parse(row.winners_json);
  let changed = false;
  if ('pageOrigin' in modification) {
    const pageOrigin = modification.pageOrigin;
    changed = applyRegister(values, winners, 'pageOrigin', pageOrigin, operation) || changed;
    if (pageOrigin !== null) {
      values.pageId = pageOrigin.pageId;
      values.x = pageOrigin.x;
      values.y = pageOrigin.y;
    }
  }
  if ('rotation' in modification) {
    changed = applyRegister(values, winners, 'rotation', modification.rotation, operation) || changed;
  }
  if ('scale' in modification) {
    changed = applyRegister(values, winners, 'scale', modification.scale, operation) || changed;
  }
  if ('zIndex' in modification) {
    changed = applyRegister(values, winners, 'zIndex', modification.zIndex, operation) || changed;
  }
  if (!changed) return;
  affectedPages.add(row.page_id);
  affectedPages.add(values.pageId);
  db.prepare(`UPDATE entity SET page_id=?,x=?,y=?,rotation=?,scale_x=?,scale_y=?,
    z_index=?,values_json=?,winners_json=? WHERE id=?`).run(
    values.pageId, values.x, values.y, values.rotation,
    values.scale === null ? 1 : values.scale[0], values.scale === null ? 1 : values.scale[1],
    values.zIndex, JSON.stringify(values), JSON.stringify(winners), modification.target);
}

function replay(db, modifications, operation = [100, 1], options = {}) {
  if (options.transient) return 'TRANSIENT_MODIFY_POSITIONS_UNSUPPORTED';
  const classified = classifyAll(db, modifications);
  if (typeof classified === 'string') return classified;
  db.exec('BEGIN IMMEDIATE; SAVEPOINT original_modify_positions');
  try {
    const affectedPages = new Set();
    for (let index = 0; index < classified.length; index++) {
      if (index === options.deferAt) {
        db.exec('ROLLBACK TO original_modify_positions; RELEASE original_modify_positions; COMMIT');
        return 'INJECTED_SECOND_REDUCER_DEFERRED';
      }
      applyOne(db, classified[index], operation, affectedPages);
      if (index === options.throwAfter) throw new Error('injected reducer failure');
    }
    for (const pageId of affectedPages) {
      db.prepare('UPDATE page_state SET revision=revision+1 WHERE id=?').run(pageId);
      db.prepare('DELETE FROM search_item WHERE page_id=?').run(pageId);
    }
    db.exec('RELEASE original_modify_positions; COMMIT');
    return null;
  } catch (error) {
    db.exec('ROLLBACK');
    return error.message;
  }
}

function snapshot(db) {
  return JSON.stringify({
    entities: db.prepare('SELECT * FROM entity ORDER BY id').all(),
    pages: db.prepare('SELECT * FROM page_state ORDER BY id').all(),
    search: db.prepare('SELECT * FROM search_item ORDER BY page_id,type').all(),
  });
}

function values(db, id) {
  return JSON.parse(db.prepare('SELECT values_json FROM entity WHERE id=?').get(id).values_json);
}

const mixed = database();
assert.equal(replay(mixed, [
  { target: 'ink', pageOrigin: { pageId: 'page-a', x: 11, y: 12 },
    rotation: null, scale: null, zIndex: '40' },
  { target: 'text', pageOrigin: { pageId: 'page-a', x: 21, y: 22 },
    rotation: 1.5, scale: [4, 5], zIndex: '50' },
]), null);
assert.deepEqual(values(mixed, 'ink').pageOrigin, { pageId: 'page-a', x: 11, y: 12 });
assert.equal(values(mixed, 'ink').rotation, null);
assert.equal(values(mixed, 'ink').scale, null);
assert.deepEqual(values(mixed, 'text').scale, [4, 5]);
assert.equal(mixed.prepare("SELECT revision FROM page_state WHERE id='page-a'").get().revision, 8);
assert.equal(mixed.prepare('SELECT COUNT(*) count FROM search_item').get().count, 0);
assert.deepEqual(mixed.prepare(`SELECT id FROM entity WHERE kind!='SHAPE'
  ORDER BY length(z_index),z_index`).all().map(row => row.id), ['ink', 'text']);

const afterMixed = snapshot(mixed);
assert.equal(replay(mixed, [
  { target: 'ink', pageOrigin: { pageId: 'page-a', x: 11, y: 12 },
    rotation: null, scale: null, zIndex: '40' },
  { target: 'text', pageOrigin: { pageId: 'page-a', x: 21, y: 22 },
    rotation: 1.5, scale: [4, 5], zIndex: '50' },
]), null);
assert.equal(snapshot(mixed), afterMixed);

assert.equal(replay(mixed, [{ target: 'ink', zIndex: '1' }], [99, 9]), null);
assert.equal(values(mixed, 'ink').zIndex, '40');
assert.equal(snapshot(mixed), afterMixed);
assert.match(replay(mixed, [{ target: 'ink', zIndex: '41' }], [100, 1]), /identity conflict/);
assert.equal(snapshot(mixed), afterMixed);

for (const [target, reason] of [
  ['missing', 'MODIFY_POSITIONS_TARGET_MISSING'],
  ['shape', 'MODIFY_POSITIONS_SHAPE_OR_GROUP_UNSUPPORTED'],
]) {
  const rejected = database();
  const before = snapshot(rejected);
  assert.equal(replay(rejected, [{ target: 'ink', zIndex: '90' }, { target, zIndex: '91' }]), reason);
  assert.equal(snapshot(rejected), before);
}

const deferred = database();
const beforeDeferred = snapshot(deferred);
assert.equal(replay(deferred, [
  { target: 'ink', zIndex: '90' }, { target: 'text', zIndex: '91' },
], [200, 1], { deferAt: 1 }), 'INJECTED_SECOND_REDUCER_DEFERRED');
assert.equal(snapshot(deferred), beforeDeferred);

const failed = database();
const beforeFailure = snapshot(failed);
assert.equal(replay(failed, [
  { target: 'ink', zIndex: '90' }, { target: 'text', zIndex: '91' },
], [200, 1], { throwAfter: 0 }), 'injected reducer failure');
assert.equal(snapshot(failed), beforeFailure);

const transient = database();
const beforeTransient = snapshot(transient);
assert.equal(replay(transient, [{ target: 'ink', zIndex: '90' }], [200, 1],
  { transient: true }), 'TRANSIENT_MODIFY_POSITIONS_UNSUPPORTED');
assert.equal(snapshot(transient), beforeTransient);

assert.match(reducerSource, /readTableVector\(0, MAX_MODIFY_POSITION_COUNT\)/);
assert.match(reducerSource, /original modify-positions repeats a target/);
assert.match(reducerSource, /SAVEPOINT \$\{SAVEPOINT_NAME\}/);
assert.match(reducerSource, /ROLLBACK TO SAVEPOINT \$\{SAVEPOINT_NAME\}/);
assert.match(reducerSource, /await this\.classifyTargets[\s\S]*return this\.applyClassified/);
assert.match(reducerSource, /TRANSIENT_MODIFY_POSITIONS_UNSUPPORTED/);
assert.match(batchSource, /entries: Map<string, OriginalMutationPageEntry>/);
assert.match(batchSource, /predicates\.equalTo\('content_revision', target\.revision\)/);
assert.match(inkSource, /applyPositionPayload[\s\S]*revisionBatch/);
assert.match(blockSource, /applyPositionPayload[\s\S]*revisionBatch/);
assert.match(routerSource, /ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE/);
assert.match(routerSource, /TRANSIENT_ORIGINAL_OPERATION_UNSUPPORTED/);
assert.match(bundleSource, /modifyPositions\.preflightTable/);
assert.match(bundleSource, /await modifyPositions\.applyTable/);
assert.match(bundleSource, /decodeOriginalModifyPositionsTable\(operation\.payload\)/);
assert.match(bundleSource, /NOTE_BUNDLE_TRANSIENT_OPERATION_UNSUPPORTED/);
assert.match(fixtureSource, /flatBufferModifyPositions/);
assert.match(fixtureSource, /18446744073709551615/);

console.log('D02_MODIFY_POSITIONS_REPLAY_OK ' +
  'mixed-ink-block=1|same-page-revision=1|z-order=1|nullable-clear=2|' +
  'retry-idempotent=1|stale-noop=1|tie-conflict=1|preflight-zero-write=2|' +
  'runtime-deferred-rollback=1|exception-rollback=1|transient-zero-write=1|' +
  'note-bundle-route=1|archived-page-binding=1');
