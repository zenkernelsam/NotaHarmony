import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = (path) => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const metadata = read('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const modifyPage = read('note/src/main/ets/data/OriginalModifyPageOperation.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const model = read('note/src/main/ets/core/model/PageBackgroundModel.ets');
const renderer = read('note/src/main/ets/rendering/PaperRenderer.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
CREATE TABLE note_meta (id TEXT PRIMARY KEY, structure_revision INTEGER NOT NULL DEFAULT 0);
CREATE TABLE original_page_identity (
  note_id TEXT NOT NULL, seq_timestamp INTEGER NOT NULL, seq_site_id INTEGER NOT NULL,
  seq_index INTEGER NOT NULL, page_id TEXT,
  PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index)
);
CREATE TABLE page_info (
  page_id TEXT PRIMARY KEY, note_id TEXT NOT NULL, size INTEGER NOT NULL,
  template INTEGER NOT NULL, orientation INTEGER NOT NULL,
  width_mm REAL NOT NULL, height_mm REAL NOT NULL, background_json TEXT
);
CREATE TABLE original_deleted_page (
  note_id TEXT NOT NULL, page_timestamp INTEGER NOT NULL, page_site_id INTEGER NOT NULL,
  page_index INTEGER NOT NULL, size INTEGER NOT NULL, template INTEGER NOT NULL,
  orientation INTEGER NOT NULL, width_mm REAL NOT NULL, height_mm REAL NOT NULL,
  background_json TEXT
);
CREATE TABLE original_page_background_winner (
  note_id TEXT NOT NULL, page_timestamp INTEGER NOT NULL, page_site_id INTEGER NOT NULL,
  page_index INTEGER NOT NULL, winner_timestamp INTEGER NOT NULL, winner_site_id INTEGER NOT NULL,
  size INTEGER NOT NULL, template INTEGER NOT NULL, orientation INTEGER NOT NULL,
  width_mm REAL NOT NULL, height_mm REAL NOT NULL, background_json TEXT NOT NULL,
  PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index)
);
INSERT INTO note_meta VALUES('n',0);
INSERT INTO original_page_identity VALUES('n',10,1,0,'p');
INSERT INTO page_info VALUES('p','n',5,0,0,215.9,279.4,NULL);
INSERT INTO original_page_background_winner VALUES
  ('n',10,1,0,20,1,5,0,0,215.9,279.4,'{"old":true}');
PRAGMA user_version=49;`);

db.exec(`BEGIN;
CREATE TABLE original_page_background_winner_v50 (
  note_id TEXT NOT NULL, page_timestamp INTEGER NOT NULL, page_site_id INTEGER NOT NULL,
  page_index INTEGER NOT NULL, winner_timestamp INTEGER NOT NULL, winner_site_id INTEGER NOT NULL,
  size INTEGER, template INTEGER, orientation INTEGER, width_mm REAL, height_mm REAL,
  background_json TEXT,
  CHECK ((background_json IS NULL AND size IS NULL AND template IS NULL AND orientation IS NULL
      AND width_mm IS NULL AND height_mm IS NULL)
    OR (background_json IS NOT NULL AND size IS NOT NULL AND template IS NOT NULL
      AND orientation IS NOT NULL AND width_mm IS NOT NULL AND height_mm IS NOT NULL)),
  PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index)
);
INSERT INTO original_page_background_winner_v50 SELECT * FROM original_page_background_winner;
DROP TABLE original_page_background_winner;
ALTER TABLE original_page_background_winner_v50 RENAME TO original_page_background_winner;
CREATE TABLE original_note_background_winner (
  note_id TEXT PRIMARY KEY, winner_timestamp INTEGER NOT NULL, winner_site_id INTEGER NOT NULL,
  size INTEGER, template INTEGER, orientation INTEGER, width_mm REAL, height_mm REAL,
  background_json TEXT,
  CHECK ((background_json IS NULL AND size IS NULL AND template IS NULL AND orientation IS NULL
      AND width_mm IS NULL AND height_mm IS NULL)
    OR (background_json IS NOT NULL AND size IS NOT NULL AND template IS NOT NULL
      AND orientation IS NOT NULL AND width_mm IS NOT NULL AND height_mm IS NOT NULL))
);
PRAGMA user_version=50;
COMMIT;`);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 50);
assert.equal(db.prepare(`SELECT background_json FROM original_page_background_winner
  WHERE note_id='n'`).get().background_json, '{"old":true}');

const newer = (timestamp, site, row) => row === undefined || timestamp > row.winner_timestamp ||
  (timestamp === row.winner_timestamp && site > row.winner_site_id);
const setNoteBackground = (timestamp, site, value) => {
  const row = db.prepare(`SELECT * FROM original_note_background_winner WHERE note_id='n'`).get();
  if (!newer(timestamp, site, row)) return false;
  const decoded = value ?? { size: null, template: null, orientation: null,
    width: null, height: null, json: null };
  db.prepare(`INSERT OR REPLACE INTO original_note_background_winner
    VALUES('n',?,?,?,?,?,?,?,?)`).run(timestamp, site, decoded.size, decoded.template,
      decoded.orientation, decoded.width, decoded.height, decoded.json);
  const effective = value ?? { size: 5, template: 0, orientation: 0,
    width: 215.9, height: 279.4 };
  db.prepare(`UPDATE page_info SET size=?,template=?,orientation=?,width_mm=?,height_mm=?
    WHERE note_id='n' AND background_json IS NULL`).run(effective.size, effective.template,
      effective.orientation, effective.width, effective.height);
  return true;
};
const grid = { size: 5, template: 2, orientation: 0, width: 215.9, height: 279.4,
  json: '{"paper":"grid"}' };
assert.equal(setNoteBackground(30, 2, grid), true);
assert.equal(setNoteBackground(29, 9, null), false);
assert.equal(db.prepare(`SELECT template,background_json FROM page_info WHERE page_id='p'`).get().template, 2);
assert.equal(db.prepare(`SELECT background_json FROM page_info WHERE page_id='p'`).get().background_json, null);

db.prepare(`UPDATE original_page_background_winner SET winner_timestamp=40,winner_site_id=3,
  size=NULL,template=NULL,orientation=NULL,width_mm=NULL,height_mm=NULL,background_json=NULL
  WHERE note_id='n'`).run();
assert.equal(setNoteBackground(41, 1, null), true);
const cleared = db.prepare(`SELECT size,template,background_json FROM page_info WHERE page_id='p'`).get();
assert.equal(cleared.size, 5);
assert.equal(cleared.template, 0);
assert.equal(cleared.background_json, null);
const clearWinner = db.prepare(`SELECT size,background_json FROM original_page_background_winner
  WHERE note_id='n'`).get();
assert.equal(clearWinner.size, null);
assert.equal(clearWinner.background_json, null);

assert.match(schema, /DB_VERSION: number = 59/);
assert.match(schema, /50: \[/);
assert.match(schema, /DDL_ORIGINAL_NOTE_BACKGROUND_WINNER/);
assert.match(schema, /DDL_ORIGINAL_NOTE_TITLE_WINNER/);
assert.match(schema, /original_page_background_winner_v50/);
assert.match(metadata, /ORIGINAL_SET_METADATA_PAYLOAD_TYPE: number = 1/);
assert.match(metadata, /compareOperationIdentity\(operation, winner\)/);
assert.match(metadata, /SET_METADATA_BACKGROUND_IDENTITY_CONFLICT/);
assert.match(metadata, /SET_METADATA_TITLE_IDENTITY_CONFLICT/);
assert.match(metadata, /original_note_title_winner/);
assert.match(metadata, /SearchItemType\.TITLE/);
assert.match(metadata, /originalDefaultNoteBackground/);
assert.match(modifyPage, /payload\.hasBackground &&[\s\S]*applyBackground/);
assert.doesNotMatch(modifyPage, /BACKGROUND_CLEAR_REQUIRES_NOTE_BACKGROUND/);
assert.match(bundle, /operation\.payloadType === ORIGINAL_SET_METADATA_PAYLOAD_TYPE/);
assert.match(bundle, /state\.background === null[\s\S]*readEffectiveNoteBackground/);
assert.match(model, /effectivePageBackground/);
assert.match(model, /sourceWidthPt: 612/);
assert.match(renderer, /effectivePageBackground\(page\)/);
assert.match(exporter, /const background: PageBackground \| null = effectivePageBackground\(p\)/);
assert.match(exporter, /background: background/);

console.log('D02_NOTE_BACKGROUND_FALLBACK_REPLAY_OK ' +
  'v49-v50-preserve=1|note-lww-stale=2|page-clear-null-winner=1|' +
  'default=612x792|metadata-bundle-renderer=closed');
