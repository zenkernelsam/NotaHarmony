import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const reducer = read('note/src/main/ets/data/OriginalUpdateCheckboxOperation.ets');
const state = read('note/src/main/ets/data/OriginalRichTextStyleState.ets');
const insert = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const style = read('note/src/main/ets/data/OriginalRichTextStyleOperation.ets');
const router = read('note/src/main/ets/data/OriginalPageOperationApplier.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');

const checkboxDdl = extractTemplate(schema, 'DDL_ORIGINAL_TEXT_CHECKBOX_STATE');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=52;
    CREATE TABLE original_element_z_index(
      note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE original_block_state(
      note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
      PRIMARY KEY(note_id,block_timestamp,block_site_id),
      FOREIGN KEY(note_id,block_timestamp,block_site_id)
        REFERENCES original_element_z_index(note_id,element_timestamp,element_site_id)
        ON DELETE CASCADE);
    CREATE TABLE original_text_character(
      note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
      char_timestamp INTEGER,char_site_id INTEGER,char_index INTEGER,visible INTEGER,
      PRIMARY KEY(note_id,char_timestamp,char_site_id,char_index),
      FOREIGN KEY(note_id,block_timestamp,block_site_id)
        REFERENCES original_block_state(note_id,block_timestamp,block_site_id)
        ON DELETE CASCADE);
    INSERT INTO original_element_z_index VALUES('n',20,2),('n',21,2);
    INSERT INTO original_block_state VALUES('n',20,2),('n',21,2);
    INSERT INTO original_text_character VALUES
      ('n',20,2,100,7,0,1),('n',20,2,100,7,1,1),('n',21,2,101,7,0,1);`);
  return db;
}

function migrateV53(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(checkboxDdl);
    if (fail) throw new Error('injected v53 migration failure');
    db.exec('PRAGMA user_version=53; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const key = { timestamp: 100, siteId: 7, index: 0 };
const otherKey = { timestamp: 100, siteId: 7, index: 1 };
const block = { timestamp: 20, siteId: 2 };
const id = (timestamp, siteId) => ({ timestamp, siteId });

function compare(left, right) {
  return left.timestamp === right.timestamp ? Math.sign(left.siteId - right.siteId) :
    Math.sign(left.timestamp - right.timestamp);
}

function apply(db, targetBlock, location, checked, operation) {
  const character = db.prepare(`SELECT block_timestamp,block_site_id
    FROM original_text_character WHERE note_id='n' AND char_timestamp=?
      AND char_site_id=? AND char_index=?`).get(location.timestamp, location.siteId, location.index);
  if (!character || character.block_timestamp !== targetBlock.timestamp ||
    character.block_site_id !== targetBlock.siteId) return 'TARGET_MISSING_OR_CROSS_BLOCK';
  const reused = db.prepare(`SELECT * FROM original_text_checkbox_state
    WHERE note_id='n' AND winner_timestamp=? AND winner_site_id=?`)
    .get(operation.timestamp, operation.siteId);
  if (reused) {
    const exact = reused.block_timestamp === targetBlock.timestamp &&
      reused.block_site_id === targetBlock.siteId &&
      reused.location_timestamp === location.timestamp &&
      reused.location_site_id === location.siteId && reused.location_index === location.index &&
      reused.is_checked === (checked ? 1 : 0);
    if (!exact) throw new Error('identity conflict');
    return 'IDEMPOTENT';
  }
  const current = db.prepare(`SELECT * FROM original_text_checkbox_state WHERE note_id='n'
    AND block_timestamp=? AND block_site_id=? AND location_timestamp=?
    AND location_site_id=? AND location_index=?`).get(targetBlock.timestamp, targetBlock.siteId,
    location.timestamp, location.siteId, location.index);
  if (current && compare(operation,
    { timestamp: current.winner_timestamp, siteId: current.winner_site_id }) <= 0) return 'STALE';
  db.prepare(`INSERT INTO original_text_checkbox_state VALUES('n',?,?,?,?,?,?,?,?)
    ON CONFLICT(note_id,block_timestamp,block_site_id,location_timestamp,location_site_id,location_index)
    DO UPDATE SET is_checked=excluded.is_checked,winner_timestamp=excluded.winner_timestamp,
      winner_site_id=excluded.winner_site_id`).run(targetBlock.timestamp, targetBlock.siteId,
    location.timestamp, location.siteId, location.index, checked ? 1 : 0,
    operation.timestamp, operation.siteId);
  return 'APPLIED';
}

function materialize(db, location, decoratorStyle, visible = true) {
  if (!visible || decoratorStyle !== 3) return {};
  const row = db.prepare(`SELECT is_checked FROM original_text_checkbox_state WHERE note_id='n'
    AND block_timestamp=20 AND block_site_id=2 AND location_timestamp=?
    AND location_site_id=? AND location_index=?`).get(location.timestamp, location.siteId, location.index);
  return row ? { decoratorStyle, isChecked: row.is_checked === 1 } : { decoratorStyle };
}

const db = database();
migrateV53(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 53);
assert.equal(apply(db, block, key, true, id(10, 1)), 'APPLIED');
assert.deepEqual(materialize(db, key, 3), { decoratorStyle: 3, isChecked: true });
assert.equal(apply(db, block, key, false, id(9, 9)), 'STALE');
assert.equal(apply(db, block, key, false, id(10, 0)), 'STALE');
assert.equal(apply(db, block, key, false, id(10, 2)), 'APPLIED');
assert.deepEqual(materialize(db, key, 3), { decoratorStyle: 3, isChecked: false });
assert.equal(apply(db, block, key, false, id(10, 2)), 'IDEMPOTENT');
assert.throws(() => apply(db, block, key, true, id(10, 2)), /identity conflict/);
assert.throws(() => apply(db, block, otherKey, false, id(10, 2)), /identity conflict/);

const writesBeforeMissing = db.prepare('SELECT COUNT(*) count FROM original_text_checkbox_state').get().count;
assert.equal(apply(db, block, { timestamp: 999, siteId: 1, index: 0 }, true, id(11, 1)),
  'TARGET_MISSING_OR_CROSS_BLOCK');
assert.equal(apply(db, { timestamp: 21, siteId: 2 }, key, true, id(11, 2)),
  'TARGET_MISSING_OR_CROSS_BLOCK');
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_text_checkbox_state').get().count,
  writesBeforeMissing);

// The independent CRDT register survives non-checkbox styling and character visibility changes.
const revision = { value: 7 };
const hiddenStyle = materialize(db, key, 1);
assert.deepEqual(hiddenStyle, {});
assert.equal(revision.value, 7);
assert.deepEqual(materialize(db, key, 3), { decoratorStyle: 3, isChecked: false });
db.prepare(`UPDATE original_text_character SET visible=0 WHERE note_id='n'
  AND char_timestamp=100 AND char_site_id=7 AND char_index=0`).run();
assert.deepEqual(materialize(db, key, 3, false), {});
db.prepare(`UPDATE original_text_character SET visible=1 WHERE note_id='n'
  AND char_timestamp=100 AND char_site_id=7 AND char_index=0`).run();
assert.deepEqual(materialize(db, key, 3), { decoratorStyle: 3, isChecked: false });

db.exec(`DELETE FROM original_element_z_index
  WHERE note_id='n' AND element_timestamp=20 AND element_site_id=2`);
assert.equal(db.prepare('SELECT COUNT(*) count FROM original_text_checkbox_state').get().count, 0);
db.close();

const failed = database();
assert.throws(() => migrateV53(failed, true), /injected v53 migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 52);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name='original_text_checkbox_state'`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 55/);
assert.match(schema, /53: \[[\s\S]*DDL_ORIGINAL_TEXT_CHECKBOX_STATE/);
assert.match(manager, /DDL_ORIGINAL_TEXT_CHECKBOX_STATE/);
assert.match(reducer, /ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE: number = 28/);
assert.match(reducer, /readInlineBytes\(0, 8\)/);
assert.match(reducer, /readInlineSequence\(1\)/);
assert.match(reducer, /readUint8\(2, 0\)/);
assert.match(reducer, /UPDATE_CHECKBOX_TARGET_MISSING_OR_CROSS_BLOCK/);
assert.match(reducer, /compareOperationIdentity\(identity, current\.winner\) <= 0/);
assert.match(state, /readOriginalCheckboxStates/);
assert.match(state, /paragraphStyle\.decoratorStyle === 3/);
assert.match(insert, /readOriginalCheckboxStates/);
assert.match(style, /readOriginalCheckboxStates/);
assert.match(router, /ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE/);
assert.match(bundle, /updateCheckbox\.preflightTable/);
assert.match(bundle, /updateCheckbox\.applyTable/);
assert.match(renderer, /isChecked === true \? '\\u2611 ' : '\\u2610 '/);
assert.match(fixture, /flatBufferUpdateCheckbox/);
assert.match(fixture, /MALFORMED_UPDATE_CHECKBOX_PAYLOAD/);

console.log('D02_UPDATE_CHECKBOX_REPLAY_OK ' +
  'v52-v53=1|toggle=2|stale-site-tie=2|exact-retry=1|identity-conflict=2|' +
  'missing-cross-block-zero-write=2|non-checkbox-no-revision=1|style-restore=1|' +
  'remove-revive=1|cascade=1|rollback=1|renderer=checked-unchecked|note-bundle=1');

function extractTemplate(source, name) {
  const match = source.match(new RegExp('(?:export )?const ' + name +
    ': string = `([\\s\\S]*?)`;'));
  assert(match, `${name} missing`);
  return match[1];
}
