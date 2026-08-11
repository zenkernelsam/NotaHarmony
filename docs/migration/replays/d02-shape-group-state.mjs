import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const reducer = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const positions = read('note/src/main/ets/data/OriginalModifyPositionsOperation.ets');
const router = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');
const shapeStateDdl = extractTemplate(schema, 'DDL_ORIGINAL_SHAPE_STATE');
const shapeModificationDdl = extractTemplate(schema, 'DDL_ORIGINAL_SHAPE_MODIFICATION');
const groupStateDdl = extractTemplate(schema, 'DDL_ORIGINAL_GROUP_STATE');
const groupModificationDdl = extractTemplate(schema, 'DDL_ORIGINAL_GROUP_MODIFICATION');

const id = (timestamp, siteId) => ({ timestamp, siteId });
const compare = (left, right) => left.timestamp === right.timestamp ?
  Math.sign(left.siteId - right.siteId) : Math.sign(left.timestamp - right.timestamp);

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=55;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE shape_visibility(
      note_id TEXT NOT NULL, shape_timestamp INTEGER NOT NULL, shape_site_id INTEGER NOT NULL,
      winner_timestamp INTEGER NOT NULL, winner_site_id INTEGER NOT NULL,
      deleted INTEGER NOT NULL CHECK(deleted IN (0,1)),
      PRIMARY KEY(note_id,shape_timestamp,shape_site_id));
    INSERT INTO note_meta(id) VALUES('n'),('other');`);
  return db;
}

function migrateV56(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(shapeStateDdl);
    db.exec(shapeModificationDdl);
    db.exec(groupStateDdl);
    db.exec(groupModificationDdl);
    if (fail) throw new Error('injected v56 migration failure');
    db.exec('PRAGMA user_version=56; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const page = (timestamp, siteId, index) => ({ timestamp, siteId, index });
const baseShape = () => ({
  page: page(1, 1, 0), originX: 12, originY: 24, rotation: 0.5,
  scale: { x: 1, y: 1 }, definition: { type: 3, width: 80, height: 40 },
  tool: 1, style: 1, tapePattern: null, color: 0xff112233,
  borderWidth: 4, fillColor: 0x88123456, zIndex: '100', smartHighlight: false,
  force: null, positionLocked: false, inkEffects: '0', inkEffectsTinted: true,
});

function visibility(db, noteId, shape, operation, deleted) {
  const current = db.prepare(`SELECT * FROM shape_visibility WHERE note_id=?
    AND shape_timestamp=? AND shape_site_id=?`).get(noteId, shape.timestamp, shape.siteId);
  if (current && compare(operation,
    id(current.winner_timestamp, current.winner_site_id)) <= 0) return 'STALE';
  db.prepare(`INSERT INTO shape_visibility VALUES(?,?,?,?,?,?)
    ON CONFLICT(note_id,shape_timestamp,shape_site_id) DO UPDATE SET
      winner_timestamp=excluded.winner_timestamp,winner_site_id=excluded.winner_site_id,
      deleted=excluded.deleted`).run(noteId, shape.timestamp, shape.siteId,
    operation.timestamp, operation.siteId, deleted ? 1 : 0);
  return 'APPLIED';
}

function createShape(db, noteId, shape, payload = baseShape(), signature = JSON.stringify(payload)) {
  const previous = db.prepare(`SELECT create_signature FROM original_shape_state WHERE note_id=?
    AND shape_timestamp=? AND shape_site_id=?`).get(noteId, shape.timestamp, shape.siteId);
  if (previous) {
    if (previous.create_signature !== signature) throw new Error('create Shape identity conflict');
    return 'IDEMPOTENT';
  }
  db.prepare(`INSERT INTO original_shape_state VALUES(?,?,?,?,?,?,?)`).run(
    noteId, shape.timestamp, shape.siteId, JSON.stringify(payload), JSON.stringify(payload),
    '[]', signature);
  return 'APPLIED';
}

function modifyShape(db, noteId, operation, shape, changes, journal = true) {
  const signature = JSON.stringify({ shape, changes });
  if (journal) {
    const replay = db.prepare(`SELECT payload_signature FROM original_shape_modification
      WHERE note_id=? AND operation_timestamp=? AND operation_site_id=?`)
      .get(noteId, operation.timestamp, operation.siteId);
    if (replay) {
      if (replay.payload_signature !== signature) throw new Error('modify Shape identity conflict');
      return 'IDEMPOTENT';
    }
  }
  const row = db.prepare(`SELECT * FROM original_shape_state WHERE note_id=?
    AND shape_timestamp=? AND shape_site_id=?`).get(noteId, shape.timestamp, shape.siteId);
  if (!row) return 'MISSING';
  if (journal) db.prepare(`INSERT INTO original_shape_modification VALUES(?,?,?,?)`).run(
    noteId, operation.timestamp, operation.siteId, signature);
  const resolved = JSON.parse(row.resolved_payload);
  const winners = JSON.parse(row.register_winners);
  let changed = false;
  for (const [field, value] of Object.entries(changes)) {
    const winner = winners.find(candidate => candidate.field === field);
    if (winner && compare(operation, winner) <= 0) continue;
    if (field === 'pageOrigin') {
      resolved.page = value.page; resolved.originX = value.x; resolved.originY = value.y;
    } else {
      resolved[field] = value;
    }
    if (winner) Object.assign(winner, operation);
    else winners.push({ field, ...operation });
    changed = true;
  }
  if (changed) db.prepare(`UPDATE original_shape_state SET resolved_payload=?,register_winners=?
    WHERE note_id=? AND shape_timestamp=? AND shape_site_id=?`).run(
    JSON.stringify(resolved), JSON.stringify(winners), noteId, shape.timestamp, shape.siteId);
  return changed ? 'APPLIED' : 'STALE';
}

function createGroup(db, noteId, group, members, signature = JSON.stringify(members)) {
  const previous = db.prepare(`SELECT create_signature FROM original_group_state WHERE note_id=?
    AND group_timestamp=? AND group_site_id=?`).get(noteId, group.timestamp, group.siteId);
  if (previous) {
    if (previous.create_signature !== signature) throw new Error('create Group identity conflict');
    return 'IDEMPOTENT';
  }
  const value = JSON.stringify(members);
  db.prepare(`INSERT INTO original_group_state VALUES(?,?,?,?,?,?,?,?,?)`).run(
    noteId, group.timestamp, group.siteId, value, value, 0, 0, 0, signature);
  return 'APPLIED';
}

function modifyGroup(db, noteId, operation, group, members) {
  const signature = JSON.stringify({ group, members });
  const replay = db.prepare(`SELECT payload_signature FROM original_group_modification
    WHERE note_id=? AND operation_timestamp=? AND operation_site_id=?`)
    .get(noteId, operation.timestamp, operation.siteId);
  if (replay) {
    if (replay.payload_signature !== signature) throw new Error('modify Group identity conflict');
    return 'IDEMPOTENT';
  }
  const row = db.prepare(`SELECT * FROM original_group_state WHERE note_id=?
    AND group_timestamp=? AND group_site_id=?`).get(noteId, group.timestamp, group.siteId);
  if (!row) return 'MISSING';
  db.prepare(`INSERT INTO original_group_modification VALUES(?,?,?,?,?,?)`).run(
    noteId, operation.timestamp, operation.siteId, group.timestamp, group.siteId, signature);
  const current = row.members_winner_present === 1 ?
    id(row.members_winner_timestamp, row.members_winner_site_id) : null;
  if (current && compare(operation, current) <= 0) return 'STALE';
  db.prepare(`UPDATE original_group_state SET members_value=?,members_winner_timestamp=?,
    members_winner_site_id=?,members_winner_present=1 WHERE note_id=?
    AND group_timestamp=? AND group_site_id=?`).run(JSON.stringify(members),
    operation.timestamp, operation.siteId, noteId, group.timestamp, group.siteId);
  return 'APPLIED';
}

const db = database();
migrateV56(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 56);
const shape = id(20, 2);
assert.equal(createShape(db, 'n', shape), 'APPLIED');
assert.equal(createShape(db, 'n', shape), 'IDEMPOTENT');
assert.throws(() => createShape(db, 'n', shape, baseShape(), 'different'),
  /create Shape identity conflict/);

assert.equal(modifyShape(db, 'n', id(30, 1), shape,
  { rotation: null, color: 0xffabcdef }), 'APPLIED');
assert.equal(modifyShape(db, 'n', id(29, 9), shape,
  { rotation: 9, scale: null, fillColor: null }), 'APPLIED');
let stored = JSON.parse(db.prepare(`SELECT resolved_payload FROM original_shape_state
  WHERE note_id='n'`).get().resolved_payload);
assert.equal(stored.rotation, null);
assert.equal(stored.scale, null);
assert.equal(stored.fillColor, null);
assert.equal(stored.color, 0xffabcdef);

// A same-timestamp higher site wins only the registers it writes.
assert.equal(modifyShape(db, 'n', id(30, 2), shape,
  { rotation: 1.25, zIndex: '18446744073709551615' }), 'APPLIED');
assert.equal(modifyShape(db, 'n', id(30, 2), shape,
  { rotation: 1.25, zIndex: '18446744073709551615' }), 'IDEMPOTENT');
assert.throws(() => modifyShape(db, 'n', id(30, 2), shape, { rotation: 2 }),
  /modify Shape identity conflict/);
assert.equal(modifyShape(db, 'n', id(40, 1), shape,
  { pageOrigin: { page: page(2, 3, 1), x: -5, y: 8 }, zIndex: '7' }), 'APPLIED');
stored = JSON.parse(db.prepare(`SELECT resolved_payload FROM original_shape_state
  WHERE note_id='n'`).get().resolved_payload);
assert.deepEqual(stored.page, page(2, 3, 1));
assert.deepEqual([stored.originX, stored.originY, stored.zIndex], [-5, 8, '7']);

// Hidden Shapes keep accepting field winners and become visible with the resolved payload.
assert.equal(visibility(db, 'n', shape, id(50, 1), true), 'APPLIED');
assert.equal(modifyShape(db, 'n', id(51, 1), shape, { fillColor: null }), 'APPLIED');
assert.equal(visibility(db, 'n', shape, id(50, 9), false), 'APPLIED');
assert.equal(db.prepare(`SELECT deleted FROM shape_visibility WHERE note_id='n'`).get().deleted, 0);

// MODIFY_POSITIONS reuses its own operation identity and must not claim a type-19 journal row.
assert.equal(modifyShape(db, 'n', id(60, 4), shape,
  { rotation: null, scale: { x: 2, y: 0.5 }, zIndex: '9' }, false), 'APPLIED');
assert.equal(modifyShape(db, 'n', id(60, 4), shape,
  { rotation: null, scale: { x: 2, y: 0.5 }, zIndex: '9' }, false), 'STALE');
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_shape_modification
  WHERE operation_timestamp=60 AND operation_site_id=4`).get().count, 0);

const group = id(70, 3);
const memberA = id(20, 2), memberB = id(21, 2), memberC = id(22, 2);
assert.equal(createGroup(db, 'n', group, [memberA, memberB]), 'APPLIED');
assert.equal(createGroup(db, 'n', group, [memberA, memberB]), 'IDEMPOTENT');
assert.throws(() => createGroup(db, 'n', group, [memberA], 'different'),
  /create Group identity conflict/);
assert.equal(modifyGroup(db, 'n', id(80, 1), group, [memberC]), 'APPLIED');
assert.equal(modifyGroup(db, 'n', id(79, 9), group, [memberA]), 'STALE');
assert.equal(modifyGroup(db, 'n', id(80, 2), group, [memberA, memberC]), 'APPLIED');
assert.equal(modifyGroup(db, 'n', id(80, 2), group, [memberA, memberC]), 'IDEMPOTENT');
assert.deepEqual(JSON.parse(db.prepare(`SELECT members_value FROM original_group_state
  WHERE note_id='n'`).get().members_value), [memberA, memberC]);
assert.equal(modifyGroup(db, 'n', id(90, 1), id(999, 1), [memberA]), 'MISSING');

db.exec("DELETE FROM note_meta WHERE id='n'");
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_shape_state').get().count, 0);
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_group_state').get().count, 0);
db.close();

const failed = database();
assert.throws(() => migrateV56(failed, true), /injected v56 migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 55);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master WHERE type='table'
  AND name IN ('original_shape_state','original_shape_modification',
    'original_group_state','original_group_modification')`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 57/);
assert.match(shapeStateDdl, /register_winners TEXT NOT NULL DEFAULT '\[\]'/);
assert.match(schema, /56: \[[\s\S]*DDL_ORIGINAL_SHAPE_STATE[\s\S]*DDL_ORIGINAL_GROUP_MODIFICATION/);
assert.match(manager, /DDL_ORIGINAL_SHAPE_STATE[\s\S]*DDL_ORIGINAL_GROUP_MODIFICATION/);
assert.match(reducer, /ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE: number = 18/);
assert.match(reducer, /ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE: number = 19/);
assert.match(reducer, /ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE: number = 20/);
assert.match(reducer, /ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE: number = 21/);
assert.match(reducer, /OriginalShapeDefinitionType\.ELLIPSE/);
assert.match(reducer, /compareOperationIdentity\(operation, winner\) > 0/);
assert.match(positions, /PositionTargetType\.SHAPE/);
assert.match(positions, /this\.shape\.applyPositionPayload/);
assert.match(bundle, /shapeGroup\.preflightTable/);
assert.match(bundle, /shapeGroup\.applyTable/);
assert.match(bundle, /originalShapeGroupStateSignature/);
assert.match(fixture, /function flatBufferCreateShape/);
assert.match(fixture, /flatBufferModifyShape/);
assert.match(fixture, /flatBufferCreateGroup/);
assert.match(fixture, /flatBufferModifyGroup/);

const supportsBody = router.match(/supports\(payloadType: number\): boolean \{([\s\S]*?)\n  \}/);
assert(supportsBody, 'production supports() body missing');
const routedTypes = new Set(supportsBody[1].match(/ORIGINAL_[A-Z_]+_PAYLOAD_TYPE/g));
assert.equal(routedTypes.size, 31);

console.log('D02_SHAPE_GROUP_STATE_REPLAY_OK ' +
  'v55-v56=1|shape-create-retry-conflict=2|independent-lww-null=4|stale-site-tie=3|' +
  'cross-page-z-index=1|hidden-modify-undelete=3|group-whole-list-lww=4|' +
  'modify-positions-shape=2|bundle-state-signature=1|routing=31/31|' +
  'shape-rich-text=pending|group-selection-consumer=pending');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
