import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const textSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalInsertTextOperation.ets', rootPath), 'utf8');
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE text_block(
      id TEXT PRIMARY KEY,page_id TEXT,archived INTEGER,text_value TEXT,revision INTEGER);
    CREATE TABLE character_state(
      block_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,parent_key TEXT,scalar INTEGER,
      visible INTEGER,winner_ts INTEGER,winner_site INTEGER,winner_present INTEGER,
      PRIMARY KEY(block_id,ts,site,idx));
    INSERT INTO text_block VALUES('live','p',0,'',0),('archived','d',1,'',0),
      ('other','q',0,'',0);`);
  return db;
}

function insert(timestamp, site, block, scalars, location = null, type = 8) {
  return { type, timestamp, site, block, scalars, location };
}

function visibility(type, timestamp, site, block, locations) {
  return { type, timestamp, site, block, locations, visible: type === 11 };
}

function charKey(value) {
  return `${value.timestamp}:${value.site}:${value.index}`;
}

function operationKey(operation, index) {
  return `${operation.timestamp}:${operation.site}:${index}`;
}

function compareOperation(leftTimestamp, leftSite, rightTimestamp, rightSite) {
  return leftTimestamp === rightTimestamp ? Math.sign(leftSite - rightSite) :
    Math.sign(leftTimestamp - rightTimestamp);
}

function validScalar(value) {
  return Number.isSafeInteger(value) && value >= 0 && value <= 0x10FFFF &&
    !(value >= 0xD800 && value <= 0xDFFF);
}

function preflight(operations) {
  for (const operation of operations) {
    if (operation.type === 7 || operation.type === 8) {
      if (!Array.isArray(operation.scalars) || operation.scalars.length === 0 ||
        !operation.scalars.every(validScalar) || operation.type === 7 && operation.scalars.length !== 1) {
        throw new Error('NOTE_BUNDLE_MALFORMED_INSERT_TEXT_PAYLOAD');
      }
      continue;
    }
    if (![9, 10, 11].includes(operation.type) || !Array.isArray(operation.locations) ||
      operation.locations.length === 0 || operation.locations.some(location =>
        location.timestamp === 0 && location.site === 0xFFFF && location.index === 0)) {
      throw new Error('NOTE_BUNDLE_MALFORMED_TEXT_VISIBILITY_PAYLOAD');
    }
  }
}

function characters(db, block) {
  return db.prepare(`SELECT ts timestamp,site,idx [index],parent_key,scalar,visible,
    winner_ts,winner_site,winner_present FROM character_state WHERE block_id=?`).all(block);
}

function materialize(db, block) {
  const rows = characters(db, block), byId = new Map(rows.map(row => [charKey(row), row]));
  const children = new Map();
  for (const row of rows) {
    if (row.parent_key !== null && !byId.has(row.parent_key)) return null;
    const parent = row.parent_key ?? 'ROOT';
    const values = children.get(parent) ?? [];
    values.push(row); children.set(parent, values);
  }
  for (const values of children.values()) {
    values.sort((left, right) => right.timestamp-left.timestamp || right.site-left.site ||
      left.index-right.index);
  }
  const pending = [...(children.get('ROOT') ?? [])].reverse(), seen = new Set(), output = [];
  while (pending.length > 0) {
    const row = pending.pop(), key = charKey(row);
    if (seen.has(key)) return null;
    seen.add(key); if (row.visible) output.push(String.fromCodePoint(row.scalar));
    const descendants = children.get(key) ?? [];
    for (let index = descendants.length - 1; index >= 0; index--) pending.push(descendants[index]);
  }
  return seen.size === rows.length ? output.join('') : null;
}

function updateText(db, block, before) {
  const after = materialize(db, block);
  if (after === null) throw new Error('invalid character tree');
  if (after === before) return false;
  db.prepare('UPDATE text_block SET text_value=?,revision=revision+1 WHERE id=?').run(after, block);
  return true;
}

function applyInsert(db, operation) {
  const target = db.prepare('SELECT * FROM text_block WHERE id=?').get(operation.block);
  if (!target) throw new Error('INSERT_TEXT_TARGET_MISSING_OR_UNBOUND');
  const before = materialize(db, operation.block);
  if (before === null || before !== target.text_value) throw new Error('INSERT_TEXT_STATE_DIVERGED');
  if (operation.location !== null) {
    const anchor = db.prepare(`SELECT block_id FROM character_state WHERE ts=? AND site=? AND idx=?`)
      .get(operation.location.timestamp, operation.location.site, operation.location.index);
    if (!anchor || anchor.block_id !== operation.block) throw new Error('INSERT_TEXT_ANCHOR_MISSING');
  }
  const existing = db.prepare('SELECT * FROM character_state WHERE ts=? AND site=?')
    .all(operation.timestamp, operation.site);
  if (existing.length > 0) {
    if (existing.length !== operation.scalars.length) throw new Error('insert identity conflict');
    let parent = operation.location === null ? null : charKey(operation.location);
    for (let index = 0; index < operation.scalars.length; index++) {
      const row = existing.find(value => value.idx === index);
      if (!row || row.block_id !== operation.block || row.parent_key !== parent ||
        row.scalar !== operation.scalars[index]) throw new Error('insert identity conflict');
      parent = operationKey(operation, index);
    }
    return false;
  }
  let parent = operation.location === null ? null : charKey(operation.location);
  for (let index = 0; index < operation.scalars.length; index++) {
    db.prepare(`INSERT INTO character_state VALUES(?,?,?,?,?,?,1,NULL,NULL,0)`).run(
      operation.block, operation.timestamp, operation.site, index, parent, operation.scalars[index]);
    parent = operationKey(operation, index);
  }
  return updateText(db, operation.block, before);
}

function applyVisibility(db, operation) {
  const target = db.prepare('SELECT * FROM text_block WHERE id=?').get(operation.block);
  if (!target) throw new Error('TEXT_VISIBILITY_TARGET_MISSING');
  const before = materialize(db, operation.block);
  if (before === null || before !== target.text_value) throw new Error('TEXT_VISIBILITY_STATE_DIVERGED');
  const unique = new Map(operation.locations.map(location => [charKey(location), location]));
  const winning = [];
  for (const location of unique.values()) {
    const row = db.prepare(`SELECT * FROM character_state WHERE ts=? AND site=? AND idx=?`)
      .get(location.timestamp, location.site, location.index);
    if (!row || row.block_id !== operation.block) throw new Error('TEXT_VISIBILITY_CHARACTER_MISSING');
    const comparison = row.winner_present ? compareOperation(
      operation.timestamp, operation.site, row.winner_ts, row.winner_site) : 1;
    if (comparison === 0) {
      if (Boolean(row.visible) !== operation.visible) throw new Error('visibility identity conflict');
    } else if (comparison > 0) winning.push(row);
  }
  for (const row of winning) {
    db.prepare(`UPDATE character_state SET visible=?,winner_ts=?,winner_site=?,winner_present=1
      WHERE block_id=? AND ts=? AND site=? AND idx=?`).run(operation.visible ? 1 : 0,
      operation.timestamp, operation.site, row.block_id, row.ts, row.site, row.idx);
  }
  return winning.length > 0 && updateText(db, operation.block, before);
}

function replay(db, operations, failAfter = -1) {
  try { preflight(operations); } catch (error) { return error.message; }
  db.exec('BEGIN IMMEDIATE');
  try {
    operations.forEach((operation, index) => {
      if (operation.type === 7 || operation.type === 8) applyInsert(db, operation);
      else applyVisibility(db, operation);
      if (index + 1 === failAfter) throw new Error('injected bundle text failure');
    });
    db.exec('COMMIT'); return null;
  } catch (error) {
    db.exec('ROLLBACK'); return error.message;
  }
}

const operations = [
  insert(10, 1, 'live', [0x41], null, 7),
  insert(20, 2, 'live', [0x1F600, 0x42], { timestamp: 10, site: 1, index: 0 }, 8),
  visibility(9, 30, 3, 'live', [{ timestamp: 10, site: 1, index: 0 }]),
  visibility(10, 31, 3, 'live', [{ timestamp: 20, site: 2, index: 0 }]),
  visibility(11, 32, 3, 'live', [
    { timestamp: 10, site: 1, index: 0 }, { timestamp: 20, site: 2, index: 0 },
  ]),
];

const db = database();
assert.equal(replay(db, operations), null);
assert.equal(db.prepare("SELECT text_value FROM text_block WHERE id='live'").get().text_value,
  'A😀B');
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision, 5);
assert.equal(characters(db, 'live').length, 3);

const snapshot = JSON.stringify(db.prepare('SELECT * FROM character_state ORDER BY ts,site,idx').all());
assert.equal(replay(db, operations), null);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM character_state ORDER BY ts,site,idx').all()),
  snapshot);
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision, 5);

assert.match(replay(db, [insert(20, 2, 'live', [0x1F601, 0x42],
  { timestamp: 10, site: 1, index: 0 }, 8)]), /identity conflict/);
assert.match(replay(db, [insert(20, 2, 'other', [0x1F600, 0x42], null, 8)]),
  /identity conflict/);
assert.match(replay(db, [visibility(10, 32, 3, 'live', [
  { timestamp: 20, site: 2, index: 0 },
])]), /visibility identity conflict/);

const revisionBeforeStale = db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision;
assert.equal(replay(db, [visibility(10, 29, 9, 'live', [
  { timestamp: 10, site: 1, index: 0 },
])]), null);
assert.equal(db.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision,
  revisionBeforeStale);

const archivedOps = [insert(40, 4, 'archived', [0x58, 0x59], null, 8),
  visibility(9, 41, 4, 'archived', [{ timestamp: 40, site: 4, index: 0 }])];
assert.equal(replay(db, archivedOps), null);
assert.equal(db.prepare("SELECT text_value FROM text_block WHERE id='archived'").get().text_value,
  'Y');

for (const invalid of [
  insert(50, 5, 'live', [0xD800], null, 7),
  visibility(10, 51, 5, 'live', [{ timestamp: 0, site: 0xFFFF, index: 0 }]),
]) {
  const rejected = database(), before = JSON.stringify(rejected.prepare('SELECT * FROM text_block').all());
  assert.match(replay(rejected, [invalid]), /MALFORMED/);
  assert.equal(JSON.stringify(rejected.prepare('SELECT * FROM text_block').all()), before);
}

const failed = database(), beforeFailure = JSON.stringify(failed.prepare('SELECT * FROM text_block').all());
assert.equal(replay(failed, [operations[0], visibility(9, 60, 6, 'live', [
  { timestamp: 999, site: 1, index: 0 },
])]), 'TEXT_VISIBILITY_CHARACTER_MISSING');
assert.equal(JSON.stringify(failed.prepare('SELECT * FROM text_block').all()), beforeFailure);
assert.equal(failed.prepare('SELECT COUNT(*) count FROM character_state').get().count, 0);

const injected = database();
assert.equal(replay(injected, operations, 3), 'injected bundle text failure');
assert.equal(injected.prepare('SELECT COUNT(*) count FROM character_state').get().count, 0);
assert.equal(injected.prepare("SELECT revision FROM text_block WHERE id='live'").get().revision, 0);

assert.match(textSource, /export function decodeOriginalInsertTextTable/);
assert.match(textSource, /export function decodeOriginalTextVisibilityTable/);
assert.match(textSource, /insertBaselineStatus/);
assert.match(textSource, /identity conflicts with persisted visibility/);
assert.match(textSource, /comparison === 0/);
assert.match(bundleSource, /insertText\.preflightTable/);
assert.match(bundleSource, /textVisibility\.preflightTable/);
assert.match(bundleSource, /await insertText\.applyTable/);
assert.match(bundleSource, /await textVisibility\.applyTable/);

console.log('success|bundle-text-types=5|insert-char=1|insert-string=2|unicode=1|' +
  'remove-char=1|remove-chars=1|revive=2|revision=5|retry-idempotent=1|' +
  'insert-conflict=2|visibility-conflict=1|stale-noop=1|archived=1|' +
  'invalid-zero-write=2|runtime-deferred-rollback=1|failure-full-rollback=1');
