import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const createSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalCreateBlockOperation.ets', rootPath), 'utf8');
const modifySource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalModifyBlockOperation.ets', rootPath), 'utf8');
const schema = fs.readFileSync(new URL(
  'note/src/main/ets/data/DatabaseHelper.ets', rootPath), 'utf8');

const migrationBody = schema.match(/45:\s*\[([\s\S]*?)\n\s*\],\n\s*46:/);
assert(migrationBody);
const migrationStatements = Array.from(
  migrationBody[1].matchAll(/(?:'([^']+)'|`([\s\S]*?)`)/g), match => match[1] ?? match[2]);
assert.equal(migrationStatements.length, 10);

function v44Database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA user_version=44;
    CREATE TABLE original_block_state(note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
      PRIMARY KEY(note_id,block_timestamp,block_site_id));
    INSERT INTO original_block_state VALUES('legacy',1,1);`);
  return db;
}

function migrate45(db, failAt = -1) {
  db.exec('BEGIN IMMEDIATE');
  try {
    migrationStatements.forEach((statement, index) => {
      db.exec(statement);
      if (index === failAt) throw new Error('injected migration');
    });
    db.exec('PRAGMA user_version=45; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const migrated = v44Database();
migrate45(migrated);
assert.equal(migrated.prepare('PRAGMA user_version').get().user_version, 45);
assert.equal(migrated.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name LIKE 'create_math_%' OR name LIKE 'math_%'`).get().count, 10);
const legacy = migrated.prepare(`SELECT math_latex_winner_present,math_color_winner_present
  FROM original_block_state`).get();
assert.equal(legacy.math_latex_winner_present, 0);
assert.equal(legacy.math_color_winner_present, 0);
const failedMigration = v44Database();
assert.throws(() => migrate45(failedMigration, 4), /injected migration/);
assert.equal(failedMigration.prepare('PRAGMA user_version').get().user_version, 44);
assert.equal(failedMigration.prepare(`SELECT count(*) count FROM pragma_table_info('original_block_state')
  WHERE name='math_latex_winner_present'`).get().count, 0);

function materializationDatabase() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE block_state(
      id TEXT PRIMARY KEY,kind INTEGER NOT NULL,block_type INTEGER NOT NULL,page_id TEXT NOT NULL,
      z_index TEXT NOT NULL,create_latex TEXT NOT NULL,create_color INTEGER NOT NULL,
      latex_value TEXT,latex_timestamp INTEGER,latex_site INTEGER,latex_present INTEGER NOT NULL DEFAULT 0,
      color_value INTEGER,color_timestamp INTEGER,color_site INTEGER,color_present INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE snapshot(page_id TEXT,id TEXT,kind INTEGER,payload TEXT,element_order INTEGER,
      PRIMARY KEY(page_id,id,kind));
    CREATE TABLE archived(page_id TEXT,id TEXT,kind INTEGER,payload TEXT,element_order INTEGER,
      PRIMARY KEY(page_id,id,kind));`);
  return db;
}

function createMath(db, input, failAt = '') {
  db.exec('BEGIN IMMEDIATE');
  try {
    if (input.blockType !== 2 || input.latex === null || input.color === null) {
      throw new Error('Must provide latex and color for a Math Block');
    }
    const data = {
      id: input.id, type: 7, latex: input.latex, color: input.color,
      transform: input.transform, bounds: input.bounds, blockWidth: input.width,
      blockHeight: input.height, rotationRadians: input.rotation,
    };
    db.prepare(`INSERT INTO block_state(id,kind,block_type,page_id,z_index,create_latex,create_color)
      VALUES(?,5,2,?,?,?,?)`).run(input.id, input.pageId, input.zIndex, input.latex, input.color);
    if (failAt === 'state') throw new Error('injected create');
    db.prepare('INSERT INTO snapshot VALUES(?,?,5,?,0)')
      .run(input.pageId, input.id, JSON.stringify({ kind: 'math', data }));
    if (failAt === 'snapshot') throw new Error('injected create');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function accepts(row, prefix, timestamp, site) {
  return row[`${prefix}_present`] === 0 || timestamp > row[`${prefix}_timestamp`] ||
    timestamp === row[`${prefix}_timestamp`] && site > row[`${prefix}_site`];
}

function modifyMath(db, id, operation, failAt = '') {
  db.exec('BEGIN IMMEDIATE');
  try {
    const state = db.prepare('SELECT * FROM block_state WHERE id=?').get(id);
    if (!state || state.kind !== 5 || state.block_type !== 2) throw new Error('type gate');
    const table = state.page_id === 'deleted' ? 'archived' : 'snapshot';
    const row = db.prepare(`SELECT payload FROM ${table} WHERE page_id=? AND id=? AND kind=5`)
      .get(state.page_id, id);
    const payload = JSON.parse(row.payload);
    if ('latex' in operation && accepts(state, 'latex', operation.timestamp, operation.site)) {
      db.prepare(`UPDATE block_state SET latex_value=?,latex_timestamp=?,latex_site=?,latex_present=1
        WHERE id=?`).run(operation.latex, operation.timestamp, operation.site, id);
      payload.data.latex = operation.latex ?? '';
    }
    if ('color' in operation && accepts(state, 'color', operation.timestamp, operation.site)) {
      db.prepare(`UPDATE block_state SET color_value=?,color_timestamp=?,color_site=?,color_present=1
        WHERE id=?`).run(operation.color, operation.timestamp, operation.site, id);
      payload.data.color = operation.color ?? -16777216;
    }
    if (operation.transform) {
      payload.data.transform = operation.transform;
      payload.data.bounds = operation.bounds;
    }
    if (failAt === 'state') throw new Error('injected modify');
    if (operation.pageId && operation.pageId !== state.page_id && state.page_id !== 'deleted') {
      db.prepare('DELETE FROM snapshot WHERE page_id=? AND id=? AND kind=5').run(state.page_id, id);
      db.prepare('UPDATE block_state SET page_id=?,z_index=? WHERE id=?')
        .run(operation.pageId, operation.zIndex, id);
      db.prepare('INSERT INTO snapshot VALUES(?,?,5,?,0)')
        .run(operation.pageId, id, JSON.stringify(payload));
    } else {
      db.prepare(`UPDATE ${table} SET payload=? WHERE page_id=? AND id=? AND kind=5`)
        .run(JSON.stringify(payload), state.page_id, id);
    }
    if (failAt === 'snapshot') throw new Error('injected modify');
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function rgbaToSignedArgb(red, green, blue, alpha) {
  return ((alpha << 24) | (red << 16) | (green << 8) | blue) | 0;
}

const db = materializationDatabase();
const base = {
  id: 'm1', blockType: 2, pageId: 'p1', zIndex: '17', latex: '\\frac{a}{b}',
  color: rgbaToSignedArgb(0x11, 0x22, 0x33, 0x80),
  transform: [1, 0, 12, 0, 1, 34, 0, 0, 1],
  bounds: { left: 12, top: 34, right: 212, bottom: 114 },
  width: 200, height: 80, rotation: 0,
};
assert.equal(base.color, -2146360781);
for (const invalid of [{ ...base, id: 'missing-latex', latex: null },
  { ...base, id: 'missing-color', color: null }]) {
  const before = db.prepare('SELECT count(*) count FROM block_state').get().count;
  assert.throws(() => createMath(db, invalid), /Must provide latex and color/);
  assert.equal(db.prepare('SELECT count(*) count FROM block_state').get().count, before);
  assert.equal(db.prepare('SELECT count(*) count FROM snapshot').get().count, 0);
}
createMath(db, base);
let state = db.prepare("SELECT * FROM block_state WHERE id='m1'").get();
assert.equal(state.kind, 5);
assert.equal(state.block_type, 2);
let payload = JSON.parse(db.prepare("SELECT payload FROM snapshot WHERE id='m1'").get().payload);
assert.equal(payload.kind, 'math');
assert.equal(payload.data.latex, '\\frac{a}{b}');
assert.equal(payload.data.color, -2146360781);

modifyMath(db, 'm1', { timestamp: 100, site: 2, latex: 'x^2+y^2' });
state = db.prepare("SELECT * FROM block_state WHERE id='m1'").get();
assert.equal(state.latex_value, 'x^2+y^2');
assert.equal(state.color_present, 0);
modifyMath(db, 'm1', { timestamp: 90, site: 9, latex: 'stale', color: -1 });
state = db.prepare("SELECT * FROM block_state WHERE id='m1'").get();
assert.equal(state.latex_value, 'x^2+y^2');
assert.equal(state.color_value, -1);
modifyMath(db, 'm1', { timestamp: 110, site: 1, latex: null });
modifyMath(db, 'm1', { timestamp: 120, site: 1, color: null });
state = db.prepare("SELECT * FROM block_state WHERE id='m1'").get();
assert.equal(state.latex_value, null);
assert.equal(state.color_value, null);
payload = JSON.parse(db.prepare("SELECT payload FROM snapshot WHERE id='m1'").get().payload);
assert.equal(payload.data.latex, '');
assert.equal(payload.data.color, -16777216);

modifyMath(db, 'm1', {
  timestamp: 130, site: 1, pageId: 'p2', zIndex: '99',
  transform: [0, -1, 30, 1, 0, 40, 0, 0, 1],
  bounds: { left: -50, top: 40, right: 30, bottom: 240 },
});
state = db.prepare("SELECT * FROM block_state WHERE id='m1'").get();
assert.equal(state.page_id, 'p2');
assert.equal(state.z_index, '99');
assert.equal(db.prepare("SELECT count(*) count FROM snapshot WHERE page_id='p1'").get().count, 0);
assert.equal(db.prepare("SELECT count(*) count FROM snapshot WHERE page_id='p2'").get().count, 1);

createMath(db, { ...base, id: 'archived', pageId: 'deleted' });
db.exec(`INSERT INTO archived SELECT * FROM snapshot WHERE id='archived';
  DELETE FROM snapshot WHERE id='archived';`);
modifyMath(db, 'archived', { timestamp: 140, site: 1, latex: 'archived-value' });
assert.equal(JSON.parse(db.prepare("SELECT payload FROM archived WHERE id='archived'").get().payload)
  .data.latex, 'archived-value');

const beforeFailure = JSON.stringify(db.prepare("SELECT * FROM block_state WHERE id='m1'").get());
const beforePayload = db.prepare("SELECT payload FROM snapshot WHERE id='m1'").get().payload;
assert.throws(() => modifyMath(db, 'm1', { timestamp: 150, site: 1, latex: 'rollback' },
  'snapshot'), /injected modify/);
assert.equal(JSON.stringify(db.prepare("SELECT * FROM block_state WHERE id='m1'").get()), beforeFailure);
assert.equal(db.prepare("SELECT payload FROM snapshot WHERE id='m1'").get().payload, beforePayload);
assert.throws(() => createMath(db, { ...base, id: 'create-rollback' }, 'state'), /injected create/);
assert.equal(db.prepare("SELECT count(*) count FROM block_state WHERE id='create-rollback'").get().count, 0);

assert.match(createSource, /unsupportedOriginalCreateBlockReason/);
assert.match(createSource, /CREATE_BLOCK_MATH_FIELDS_MISSING/);
assert.doesNotMatch(createSource,
  /if \(payload\.hasImage \|\| payload\.hasCropRect[\s\S]{0,250}CREATE_BLOCK_IMAGE_FIELDS_ON_TEXT/);
assert.match(createSource, /kind === PageElementKind\.MATH \? 'math' : 'text'/);
assert.match(modifySource, /replaceMathLatex[\s\S]*replaceMathColor/);
assert.match(modifySource, /updatedMath\.latex = payload\.mathLatex\.value === null \? ''/);
assert.match(modifySource, /updatedMath\.color = payload\.mathColor\.value === null \? DEFAULT_MATH_COLOR/);
assert.match(schema, /DB_VERSION: number = 54/);

console.log('success|v44-v45=1|migration-rollback=1|missing-fields-zero-write=2|' +
  'kind=5|snapshot-kind=math|rgba-argb=1|independent-lww=2|stale-noop=1|latex-clear=1|' +
  'color-clear=1|common-transform=1|cross-page=1|z-index=1|live=1|archive=1|' +
  'modify-rollback=1|create-rollback=1|valid-type-gate-regression=1');
