import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const manager = read('note/src/main/ets/data/DatabaseManager.ets');
const model = read('note/src/main/ets/core/model/OriginalPaperSettings.ets');
const storeSource = read('note/src/main/ets/data/OriginalPaperSettingsStore.ets');
const fixtureSource = read('note/src/test/OriginalPaperSettings.test.ets');
const pickerSource = read('note/src/main/ets/core/model/OriginalTemplatePickerState.ets');
const panelSource = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const defaultTemplatePageSource = read('note/src/main/ets/ui/settings/DefaultTemplatePage.ets');
const pageManagerSource = read('note/src/main/ets/ui/editor/PageManagerBar.ets');

const spacingPresets = [
  Math.fround(0.1968505), Math.fround(0.25), Math.fround(0.393701), Math.fround(0.5),
  Math.fround(0.5905515), Math.fround(0.75), Math.fround(0.787402), Math.fround(1),
  Math.fround(1.181103), Math.fround(1.5),
];
const packedSizes = new Map([
  ['A3', '4869657835720540160'], ['A4', '4850939749765251072'],
  ['A5', '4833488301204832256'], ['A6', '4814910952737865728'],
  ['A7', '4797459504177479680'], ['LETTER', '4852600450409280307'],
  ['LEGAL', '4852600450411777229'], ['TABLOID', '4867180855066879590'],
]);

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec('PRAGMA user_version=62');
  return db;
}

function migrateV63(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`CREATE TABLE IF NOT EXISTS PaperBackground (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      paperSize INTEGER NOT NULL,
      paperOrientation TEXT NOT NULL,
      backgroundColor INTEGER,
      legacyPaperIndex INTEGER,
      paperLineType TEXT NOT NULL,
      spacing REAL,
      hasOptions INTEGER NOT NULL
    )`);
    if (fail) throw new Error('injected paper settings migration failure');
    db.exec(`CREATE TABLE IF NOT EXISTS BackgroundInfo (
      paperLineType TEXT NOT NULL PRIMARY KEY,
      spacing REAL,
      hasOptions INTEGER NOT NULL
    )`);
    db.exec('PRAGMA user_version=63; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function defaultInfo(lineType) {
  return lineType === 'PLAIN'
    ? { lineType, spacing: null, hasOptions: false }
    : { lineType, spacing: Math.fround(0.5), hasOptions: true };
}

function readInfo(db, lineType) {
  const row = db.prepare(`SELECT paperLineType lineType, spacing, hasOptions
    FROM BackgroundInfo WHERE paperLineType=?`).get(lineType);
  if (!row) return defaultInfo(lineType);
  return { lineType: row.lineType, spacing: row.spacing === null ? null : Math.fround(row.spacing),
    hasOptions: row.hasOptions === 1 };
}

function saveSpacing(db, lineType, spacing, fail = false) {
  if (lineType === 'PLAIN') return defaultInfo(lineType);
  const normalized = Math.fround(spacing);
  assert(spacingPresets.includes(normalized));
  db.exec('BEGIN IMMEDIATE');
  try {
    const current = db.prepare(`SELECT hasOptions FROM BackgroundInfo
      WHERE paperLineType=?`).get(lineType);
    if (current) {
      db.prepare(`UPDATE BackgroundInfo SET spacing=?,hasOptions=? WHERE paperLineType=?`)
        .run(normalized, current.hasOptions, lineType);
    } else {
      db.prepare(`INSERT INTO BackgroundInfo(paperLineType,spacing,hasOptions)
        VALUES(?,?,1)`).run(lineType, normalized);
    }
    if (fail) throw new Error('injected spacing failure');
    db.exec('COMMIT');
    return readInfo(db, lineType);
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function semanticKey(value) {
  return JSON.stringify([
    value.paperSize, value.paperOrientation, value.backgroundColor, value.legacyPaperIndex,
    value.paperLineType, value.spacing, value.hasOptions,
  ]);
}

function listFavorites(db) {
  return db.prepare(`SELECT id,CAST(paperSize AS TEXT) paperSize,paperOrientation,
    backgroundColor,legacyPaperIndex,paperLineType,spacing,hasOptions
    FROM PaperBackground ORDER BY id`).all().map(row => ({ ...row,
      spacing: row.spacing === null ? null : Math.fround(row.spacing),
      hasOptions: row.hasOptions === 1,
    }));
}

function insertFavoriteRow(db, value) {
  return Number(db.prepare(`INSERT INTO PaperBackground(
    paperSize,paperOrientation,backgroundColor,legacyPaperIndex,paperLineType,spacing,hasOptions)
    VALUES(CAST(? AS INTEGER),?,?,?,?,?,?)`).run(value.paperSize, value.paperOrientation,
      value.backgroundColor, value.legacyPaperIndex, value.paperLineType, value.spacing,
      value.hasOptions ? 1 : 0).lastInsertRowid);
}

function addFavorite(db, value, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const existing = listFavorites(db).find(row => semanticKey(row) === semanticKey(value));
    if (existing) {
      db.exec('COMMIT');
      return existing;
    }
    const id = insertFavoriteRow(db, value);
    if (fail) throw new Error('injected favorite failure');
    db.exec('COMMIT');
    return { ...value, id };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function removeFavorite(db, value) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const stored = listFavorites(db).find(row => semanticKey(row) === semanticKey(value));
    if (!stored) {
      db.exec('COMMIT');
      return false;
    }
    const result = db.prepare('DELETE FROM PaperBackground WHERE id=?').run(stored.id);
    assert.equal(result.changes, 1);
    db.exec('COMMIT');
    return true;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const failedMigration = database();
assert.throws(() => migrateV63(failedMigration, true), /injected paper settings migration failure/);
assert.equal(failedMigration.prepare('PRAGMA user_version').get().user_version, 62);
assert.equal(failedMigration.prepare(`SELECT COUNT(*) count FROM sqlite_master
  WHERE type='table' AND name IN ('PaperBackground','BackgroundInfo')`).get().count, 0);
failedMigration.close();

const db = database();
migrateV63(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 63);
for (const lineType of ['PLAIN', 'LINES', 'GRID', 'DOTS']) {
  assert.deepEqual(readInfo(db, lineType), defaultInfo(lineType));
}
assert.equal(db.prepare('SELECT COUNT(*) count FROM BackgroundInfo').get().count, 0);
assert.deepEqual(saveSpacing(db, 'PLAIN', 1.5), defaultInfo('PLAIN'));
assert.equal(db.prepare('SELECT COUNT(*) count FROM BackgroundInfo').get().count, 0);
assert.equal(saveSpacing(db, 'LINES', 0.75).spacing, Math.fround(0.75));
db.prepare(`UPDATE BackgroundInfo SET hasOptions=0 WHERE paperLineType='LINES'`).run();
assert.equal(saveSpacing(db, 'LINES', 1).hasOptions, false);
assert.equal(readInfo(db, 'LINES').spacing, Math.fround(1));
assert.throws(() => saveSpacing(db, 'GRID', 1.5, true), /injected spacing failure/);
assert.deepEqual(readInfo(db, 'GRID'), defaultInfo('GRID'));

for (const [name, packed] of packedSizes) {
  const favorite = {
    id: 0, paperSize: packed, paperOrientation: name === 'TABLOID' ? 'LANDSCAPE' : 'PORTRAIT',
    backgroundColor: -1, legacyPaperIndex: null, paperLineType: 'LINES',
    spacing: Math.fround(0.5), hasOptions: true,
  };
  const inserted = addFavorite(db, favorite);
  const duplicate = addFavorite(db, { ...favorite, id: 999 });
  assert.equal(duplicate.id, inserted.id);
  assert.equal(db.prepare(`SELECT typeof(paperSize) type FROM PaperBackground
    WHERE id=?`).get(inserted.id).type, 'integer');
  assert.equal(listFavorites(db).find(row => row.id === inserted.id).paperSize, packed);
}
assert.equal(listFavorites(db).length, 8);

const letter = listFavorites(db).find(row => row.paperSize === packedSizes.get('LETTER'));
assert(letter);
assert.equal(removeFavorite(db, { ...letter, id: 0 }), true);
assert.equal(removeFavorite(db, { ...letter, id: 0 }), false);
assert.equal(listFavorites(db).length, 7);
const beforeRollback = listFavorites(db).length;
assert.throws(() => addFavorite(db, {
  id: 0, paperSize: packedSizes.get('LETTER'), paperOrientation: 'LANDSCAPE',
  backgroundColor: -1, legacyPaperIndex: 13, paperLineType: 'DOTS',
  spacing: Math.fround(1.5), hasOptions: true,
}, true), /injected favorite failure/);
assert.equal(listFavorites(db).length, beforeRollback);
db.close();

for (const spacing of spacingPresets) {
  const points = Math.fround(Math.fround(spacing) * Math.fround(72));
  assert.equal(Math.fround(Math.fround(points) / Math.fround(72)), spacing);
}
const translucentArgb = (128 << 24) | (18 << 16) | (52 << 8) | 86;
assert.equal(translucentArgb, -2146290602);
assert.equal((translucentArgb >>> 24) & 255, 128);

assert.match(schema, /DB_VERSION: number = (?:6[3-9]|[7-9][0-9]|[1-9][0-9]{2,})/);
assert.match(schema, /63: \[[\s\S]*DDL_ORIGINAL_PAPER_BACKGROUND[\s\S]*DDL_ORIGINAL_BACKGROUND_INFO/);
assert.match(manager, /DDL_ORIGINAL_PAPER_BACKGROUND, DDL_ORIGINAL_BACKGROUND_INFO/);
assert.match(model, /4852600450409280307/);
assert.match(model, /4852600450411777229/);
assert.match(model, /4867180855066879590/);
assert.match(model, /Math\.fround\(Math\.fround\(spacing\) \* Math\.fround\(72\.0\)\)/);
assert.match(model, /normalizeStoredOriginalPaperSpacingInches/);
assert.doesNotMatch(model, /paper color must be opaque|alpha !== 255/);
assert.match(storeSource, /databaseWriteMutex\.runExclusive/);
assert.match(storeSource, /CAST\(paperSize AS TEXT\) AS paperSizeText/);
assert.match(storeSource, /sameOriginalPaperBackground\(favorite, requested\)/);
assert.match(storeSource, /predicates\.equalTo\('id', stored\.id\)/);
assert.match(storeSource, /await store\.rollBack\(\)/);
assert.match(fixtureSource, /maps all eight ndj\.f packed Float32 paper sizes/);
assert.match(pickerSource, /originalTemplatePickerFavorite/);
assert.match(pickerSource, /originalPaperSpacingPointsFromInches/);
assert.match(panelSource, /new OriginalPaperSettingsStore/);
assert.match(panelSource, /await database\.initialize\(getContext\(this\)/);
assert.match(panelSource, /store\.listBackgroundInfos\(\)/);
assert.match(panelSource, /store\.listFavorites\(\)/);
assert.match(panelSource, /store\.saveSpacing/);
assert.match(panelSource, /store\.addFavorite/);
assert.match(panelSource, /store\.removeFavorite/);
assert.match(panelSource, /applyOriginalTemplatePickerSelection\([\s\S]*backgroundInfoForTemplate/);
assert.match(panelSource, /Slider\(\{[\s\S]*ORIGINAL_PAPER_SPACING_INCHES\.length - 1/);
assert.match(panelSource,
  /mode === SliderChangeMode\.End \|\| mode === SliderChangeMode\.Click/);
assert.match(panelSource, /this\.spacingSaveBusy = true/);
assert.doesNotMatch(panelSource, /selectedDefaultTemplate|saveSelectedDefaultTemplate/);
assert.match(defaultTemplatePageSource, /PageSettingsPanel\(\{/);
assert.match(pageManagerSource, /PageSettingsPanel\(\{/);

console.log('D02_ORIGINAL_PAPER_SETTINGS_REPLAY_OK ' +
  'v62-v63-atomic=1|empty-fallbacks=4|spacing-presets=10|plain-noop=1|' +
  'spacing-upsert-preserves-options=1|packed-sizes=8|integer-affinity=1|' +
  'favorite-dedupe-id-reuse-delete=1|shared-settings-editor-ui=1|slider-final-commit=1|' +
  'self-db-init=1|nullable-legacy-spacing=1|rollback=1|argb-alpha=1');
