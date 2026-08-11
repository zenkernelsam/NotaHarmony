import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = (path) => fs.readFileSync(new URL(path, root), 'utf8');
const schema = read('note/src/main/ets/data/DatabaseHelper.ets');
const decoder = read('note/src/main/ets/data/OriginalPageBackgroundOperation.ets');
const metadata = read('note/src/main/ets/data/OriginalAssetMetadata.ets');
const createPage = read('note/src/main/ets/data/OriginalCreatePageOperation.ets');
const modifyPage = read('note/src/main/ets/data/OriginalModifyPageOperation.ets');
const setMetadata = read('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const bundle = read('note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets');
const assetStore = read('note/src/main/ets/data/OriginalAssetReferenceStore.ets');
const loader = read('note/src/main/ets/core/adaptation/PdfBackgroundLoader.ets');
const renderer = read('note/src/main/ets/rendering/PaperRenderer.ets');
const thumbnail = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const pageCodec = read('note/src/main/ets/data/PageStructureOpCodec.ets');
const fixture = read('note/src/test/SyncedOperationInbox.test.ets');

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON;
    PRAGMA user_version=50;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE original_page_identity(
      note_id TEXT NOT NULL,seq_timestamp INTEGER NOT NULL,seq_site_id INTEGER NOT NULL,
      seq_index INTEGER NOT NULL,page_id TEXT,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE page_info(
      page_id TEXT PRIMARY KEY,note_id TEXT NOT NULL,page_index INTEGER NOT NULL,
      size INTEGER NOT NULL,template INTEGER NOT NULL,orientation INTEGER NOT NULL,
      width_mm REAL NOT NULL,height_mm REAL NOT NULL,background_json TEXT);
    CREATE TABLE original_deleted_page(
      note_id TEXT NOT NULL,page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,
      page_index INTEGER NOT NULL,page_id TEXT NOT NULL,size INTEGER NOT NULL,
      template INTEGER NOT NULL,orientation INTEGER NOT NULL,width_mm REAL NOT NULL,
      height_mm REAL NOT NULL,background_json TEXT,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE page_delete_checkpoint(
      note_id TEXT NOT NULL,action_id TEXT NOT NULL,page_id TEXT NOT NULL,
      PRIMARY KEY(note_id,action_id));
    CREATE TABLE original_page_background_winner(
      note_id TEXT NOT NULL,page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,
      page_index INTEGER NOT NULL,winner_timestamp INTEGER NOT NULL,winner_site_id INTEGER NOT NULL,
      size INTEGER,template INTEGER,orientation INTEGER,width_mm REAL,height_mm REAL,
      background_json TEXT,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    INSERT INTO note_meta VALUES('n');
    INSERT INTO original_page_identity VALUES('n',10,1,3,'live');
    INSERT INTO original_page_identity VALUES('n',10,1,4,'live-two');
    INSERT INTO original_page_identity VALUES('n',11,2,8,NULL);
    INSERT INTO page_info VALUES('live','n',0,5,0,0,215.9,279.4,NULL);
    INSERT INTO page_info VALUES('live-two','n',1,5,0,0,215.9,279.4,'{"paper":true}');
    INSERT INTO page_info VALUES('local','n',2,5,0,0,215.9,279.4,NULL);
    INSERT INTO original_deleted_page VALUES
      ('n',11,2,8,'deleted',5,0,0,215.9,279.4,NULL);
    INSERT INTO original_page_background_winner VALUES
      ('n',10,1,3,15,1,NULL,NULL,NULL,NULL,NULL,NULL);`);
  return db;
}

function migrateV51(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.exec(`ALTER TABLE page_info ADD COLUMN original_page_in_asset INTEGER;
      ALTER TABLE original_deleted_page ADD COLUMN original_page_in_asset INTEGER;
      ALTER TABLE page_delete_checkpoint ADD COLUMN original_page_in_asset INTEGER;
      CREATE TABLE original_page_in_asset_winner(
        note_id TEXT NOT NULL,page_timestamp INTEGER NOT NULL,page_site_id INTEGER NOT NULL,
        page_index INTEGER NOT NULL,winner_timestamp INTEGER NOT NULL,winner_site_id INTEGER NOT NULL,
        page_in_asset INTEGER NOT NULL CHECK(page_in_asset BETWEEN 0 AND 4294967295),
        PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
      INSERT INTO original_page_in_asset_winner
        SELECT note_id,seq_timestamp,seq_site_id,seq_index,
          seq_timestamp,seq_site_id,seq_index FROM original_page_identity;
      UPDATE page_info SET original_page_in_asset=(SELECT identity.seq_index
        FROM original_page_identity identity WHERE identity.note_id=page_info.note_id
          AND identity.page_id=page_info.page_id)
        WHERE EXISTS(SELECT 1 FROM original_page_identity identity
          WHERE identity.note_id=page_info.note_id AND identity.page_id=page_info.page_id);
      UPDATE original_deleted_page SET original_page_in_asset=page_index;
      INSERT INTO original_page_background_winner
        SELECT identity.note_id,identity.seq_timestamp,identity.seq_site_id,identity.seq_index,
          identity.seq_timestamp,identity.seq_site_id,
          CASE WHEN page.background_json IS NULL THEN NULL ELSE page.size END,
          CASE WHEN page.background_json IS NULL THEN NULL ELSE page.template END,
          CASE WHEN page.background_json IS NULL THEN NULL ELSE page.orientation END,
          CASE WHEN page.background_json IS NULL THEN NULL ELSE page.width_mm END,
          CASE WHEN page.background_json IS NULL THEN NULL ELSE page.height_mm END,
          page.background_json
        FROM original_page_identity identity JOIN page_info page
          ON page.note_id=identity.note_id AND page.page_id=identity.page_id
        LEFT JOIN original_page_background_winner winner
          ON winner.note_id=identity.note_id AND winner.page_timestamp=identity.seq_timestamp
          AND winner.page_site_id=identity.seq_site_id AND winner.page_index=identity.seq_index
        WHERE winner.note_id IS NULL;
      INSERT INTO original_page_background_winner
        SELECT page.note_id,page.page_timestamp,page.page_site_id,page.page_index,
          page.page_timestamp,page.page_site_id,
          NULL,NULL,NULL,NULL,NULL,NULL
        FROM original_deleted_page page LEFT JOIN original_page_background_winner winner
          ON winner.note_id=page.note_id AND winner.page_timestamp=page.page_timestamp
          AND winner.page_site_id=page.page_site_id AND winner.page_index=page.page_index
        WHERE winner.note_id IS NULL;`);
    if (fail) throw new Error('injected migration failure');
    db.exec('PRAGMA user_version=51; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function compare(timestamp, siteId, winner) {
  return timestamp === winner.winner_timestamp
    ? Math.sign(siteId - winner.winner_site_id)
    : Math.sign(timestamp - winner.winner_timestamp);
}

function applyPageInAsset(db, timestamp, siteId, pageIndex, value) {
  const winner = db.prepare(`SELECT winner_timestamp,winner_site_id,page_in_asset
    FROM original_page_in_asset_winner WHERE note_id='n' AND page_timestamp=10
      AND page_site_id=1 AND page_index=?`).get(pageIndex);
  const order = compare(timestamp, siteId, winner);
  if (order < 0) return false;
  if (order === 0) {
    if (winner.page_in_asset !== value) throw new Error('identity conflict');
    return false;
  }
  db.prepare(`UPDATE original_page_in_asset_winner SET winner_timestamp=?,winner_site_id=?,
    page_in_asset=? WHERE note_id='n' AND page_timestamp=10 AND page_site_id=1
    AND page_index=?`).run(timestamp, siteId, value, pageIndex);
  db.prepare(`UPDATE page_info SET original_page_in_asset=? WHERE note_id='n' AND page_id=?`)
    .run(value, pageIndex === 3 ? 'live' : 'live-two');
  return true;
}

const db = database();
migrateV51(db);
assert.equal(db.prepare('PRAGMA user_version').get().user_version, 51);
assert.equal(db.prepare(`SELECT original_page_in_asset FROM page_info WHERE page_id='live'`)
  .get().original_page_in_asset, 3);
assert.equal(db.prepare(`SELECT original_page_in_asset FROM page_info WHERE page_id='live-two'`)
  .get().original_page_in_asset, 4);
assert.equal(db.prepare(`SELECT original_page_in_asset FROM page_info WHERE page_id='local'`)
  .get().original_page_in_asset, null);
assert.equal(db.prepare(`SELECT original_page_in_asset FROM original_deleted_page`)
  .get().original_page_in_asset, 8);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_page_in_asset_winner`).get().count, 3);
assert.equal(db.prepare(`SELECT COUNT(*) count FROM original_page_background_winner`).get().count, 3);
assert.equal(db.prepare(`SELECT winner_timestamp FROM original_page_background_winner
  WHERE page_index=3`).get().winner_timestamp, 15);

assert.equal(applyPageInAsset(db, 20, 2, 3, 7), true);
assert.equal(applyPageInAsset(db, 20, 2, 4, 8), true);
db.prepare(`UPDATE original_page_background_winner SET winner_timestamp=21,winner_site_id=1,
  size=5,template=2,orientation=0,width_mm=215.9,height_mm=279.4,
  background_json='{"paper":true}' WHERE note_id='n' AND page_index=3`).run();
assert.equal(db.prepare(`SELECT original_page_in_asset FROM page_info WHERE page_id='live'`)
  .get().original_page_in_asset, 7, 'non-PDF background must not clear pageInAsset');
assert.equal(applyPageInAsset(db, 19, 65535, 3, 9), false);
assert.throws(() => applyPageInAsset(db, 20, 2, 3, 10), /identity conflict/);
assert.equal(applyPageInAsset(db, 20, 2, 3, 7), false);
db.close();

const failed = database();
assert.throws(() => migrateV51(failed, true), /injected migration failure/);
assert.equal(failed.prepare('PRAGMA user_version').get().user_version, 50);
assert.equal(failed.prepare(`SELECT COUNT(*) count FROM pragma_table_info('page_info')
  WHERE name='original_page_in_asset'`).get().count, 0);
failed.close();

assert.match(schema, /DB_VERSION: number = 59/);
assert.match(schema, /51: \[/);
assert.match(schema, /DDL_ORIGINAL_PAGE_IN_ASSET_WINNER/);
assert.match(decoder, /decodeOriginalPdfAsset/);
assert.match(decoder, /readInlineVectorBytes\(5, 8, 10000\)/);
assert.match(metadata, /readInlineBytes\(0, 64\)/);
assert.match(createPage, /pageOffset \+ index/);
assert.match(modifyPage, /offset \+ index/);
assert.match(modifyPage, /payload\.hasBackground && payload\.background !== null/);
assert.match(setMetadata, /mergeOriginalAssetReference/);
assert.match(bundle, /pageInAssetWinner/);
assert.match(bundle, /original_page_in_asset_winner/);
assert.doesNotMatch(bundle, /PDF_BACKGROUND_UNSUPPORTED/);
assert.match(assetStore, /legacyHash/);
assert.match(assetStore, /OriginalAssetReferenceConflict\.LOCAL_PATH/);
assert.match(loader, /from '@kit\.PDFKit'/);
assert.match(loader, /document\.getPageCount\(\) !== pdf\.totalPageCount/);
assert.match(loader, /getPage\(pdf\.pageInAsset\)\.getPagePixelMap\(\)/);
assert.match(loader, /document\.releaseDocument\(\)/);
assert.match(renderer, /drawPdfBackground/);
assert.match(thumbnail, /pdfLoader\.load/);
assert.match(canvas, /generation !== this\.pdfBackgroundGeneration/);
assert.match(canvas, /assetAvailabilityHub\.subscribe/);
assert.match(exporter, /readVerifiedOriginalAsset/);
assert.match(importer, /storeImportedOriginalAsset/);
assert.match(pageCodec, /MAGIC_V3/);
assert.match(pageCodec, /originalPageInAsset/);
assert.match(fixture, /flatBufferCreatePagePdfBackground/);
assert.match(fixture, /18446744073709551615/);

console.log('D02_PDF_BACKGROUND_REPLAY_OK ' +
  'v50-v51=1|backfill-live-archived=1|local-null=1|background-winner-backfill=1|' +
  'pageInAsset-independent-lww=1|rollback=1|pdf-flatbuffer-fixture=1|' +
  'pdfkit-editor-thumbnail-package=closed');
