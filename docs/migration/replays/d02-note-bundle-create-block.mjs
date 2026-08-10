import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const rootPath = new URL('../../../', import.meta.url);
const bundleSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalNoteBundlePageIdentity.ets', rootPath), 'utf8');
const blockSource = fs.readFileSync(new URL(
  'note/src/main/ets/data/OriginalCreateBlockOperation.ets', rootPath), 'utf8');

const TEXT = 0;
const IMAGE = 1;
const MATH = 2;

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`CREATE TABLE original_page_identity(
      note_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,page_id TEXT,
      PRIMARY KEY(note_id,ts,site,idx));
    CREATE TABLE page_info(
      note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE original_deleted_page(
      note_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,ts,site,idx));
    CREATE TABLE original_element_z_index(
      note_id TEXT,ts INTEGER,site INTEGER,page_ts INTEGER,page_site INTEGER,page_idx INTEGER,
      kind INTEGER,z_index TEXT,PRIMARY KEY(note_id,ts,site));
    CREATE TABLE original_block_state(
      note_id TEXT,ts INTEGER,site INTEGER,block_type INTEGER,baseline TEXT,
      PRIMARY KEY(note_id,ts,site));
    CREATE TABLE snapshot(
      note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,payload TEXT,
      element_order INTEGER,revision INTEGER,
      PRIMARY KEY(note_id,page_id,element_id));
    CREATE TABLE archived_snapshot(
      note_id TEXT,page_ts INTEGER,page_site INTEGER,page_idx INTEGER,
      element_id TEXT,kind INTEGER,payload TEXT,element_order INTEGER,revision INTEGER,
      PRIMARY KEY(note_id,page_ts,page_site,page_idx,element_id));
    CREATE TABLE note_asset(
      asset_hash TEXT PRIMARY KEY,status INTEGER,note_ids TEXT,file_size INTEGER,
      mime_type TEXT,local_path TEXT);`);
  return db;
}

const page = { type: 3, timestamp: 10, site: 1, index: 0, pageId: 'page', archived: false };
const archivedPage = { ...page, pageId: 'archived', archived: true };

function block(timestamp, site, blockType, overrides = {}) {
  return {
    type: 22, timestamp, site, pageTimestamp: 10, pageSite: 1, pageIndex: 0,
    blockType, originX: 12, originY: 34, rotation: null, scaleX: null, scaleY: null,
    width: 200, height: 40, corner: 0, textWrap: 0, caption: false,
    positionLocked: false, resizesWidth: false, paper: null, margins: [3, 10, 5, 5],
    zIndex: String(timestamp), image: null, crop: null, webUrl: null,
    flipHorizontal: false, flipVertical: false, mathLatex: null, mathColor: null,
    ...overrides,
  };
}

const image = block(30, 3, IMAGE, {
  image: { hash: 'sha512-image', fileName: 'photo.png', mimeType: 'image/png',
    fileSize: 1234, width: 4032, height: 3024 },
  crop: [-5, 2, 100, 50], webUrl: 'https://example.test/photo.png',
  flipHorizontal: true, flipVertical: true,
});
const math = block(40, 4, MATH, { mathLatex: '\\frac{a}{b}', mathColor: -2146360781 });
const text = block(20, 2, TEXT, { paper: { flair: 2, spacing: 18 }, resizesWidth: true });

function baseline(operation) {
  const { type: _type, timestamp: _timestamp, site: _site, ...value } = operation;
  return JSON.stringify(value);
}

function validateBlock(operation) {
  if (![TEXT, IMAGE, MATH].includes(operation.blockType)) {
    throw new Error('NOTE_BUNDLE_MALFORMED_CREATE_BLOCK_PAYLOAD');
  }
  if (operation.blockType === IMAGE && !operation.image) {
    throw new Error('NOTE_BUNDLE_CREATE_BLOCK_IMAGE_MISSING_ASSET');
  }
  if (operation.blockType !== IMAGE && (operation.image || operation.crop || operation.webUrl)) {
    throw new Error('NOTE_BUNDLE_CREATE_BLOCK_IMAGE_FIELDS_ON_TEXT');
  }
  if (operation.blockType === MATH &&
    (operation.mathLatex === null || operation.mathColor === null)) {
    throw new Error('NOTE_BUNDLE_CREATE_BLOCK_MATH_FIELDS_MISSING');
  }
  if (operation.blockType !== MATH &&
    (operation.mathLatex !== null || operation.mathColor !== null)) {
    throw new Error('NOTE_BUNDLE_CREATE_BLOCK_MATH_FIELDS_ON_TEXT');
  }
  if (![operation.originX, operation.originY, operation.width, operation.height]
    .every(Number.isFinite)) throw new Error('NOTE_BUNDLE_CREATE_BLOCK_SIZE_UNSUPPORTED');
}

function preflight(operations) {
  const pages = new Set(operations.filter(operation => operation.type === 3)
    .map(operation => `${operation.timestamp}:${operation.site}:${operation.index}`));
  for (const operation of operations) {
    if (operation.type !== 3 && operation.type !== 22) {
      throw new Error(`NOTE_BUNDLE_PAYLOAD_${operation.type}_UNSUPPORTED`);
    }
    if (operation.type !== 22) continue;
    validateBlock(operation);
    if (!pages.has(`${operation.pageTimestamp}:${operation.pageSite}:${operation.pageIndex}`)) {
      throw new Error('NOTE_BUNDLE_CREATE_BLOCK_PAGE_MISSING');
    }
  }
}

function createBlock(db, operation, target) {
  const expected = baseline(operation);
  const existing = db.prepare(`SELECT z.kind,z.z_index,state.block_type,state.baseline
    FROM original_element_z_index z LEFT JOIN original_block_state state
    ON state.note_id=z.note_id AND state.ts=z.ts AND state.site=z.site
    WHERE z.note_id='note' AND z.ts=? AND z.site=?`).get(operation.timestamp, operation.site);
  const kind = operation.blockType === TEXT ? 2 : operation.blockType === IMAGE ? 4 : 5;
  if (existing) {
    const payloadCount = db.prepare(`SELECT
      (SELECT COUNT(*) FROM snapshot WHERE note_id='note' AND element_id=? AND kind=?) +
      (SELECT COUNT(*) FROM archived_snapshot WHERE note_id='note' AND element_id=? AND kind=?) count`)
      .get(`${operation.timestamp}:${operation.site}`, kind,
        `${operation.timestamp}:${operation.site}`, kind).count;
    const asset = operation.image === null ? null :
      db.prepare('SELECT * FROM note_asset WHERE asset_hash=?').get(operation.image.hash);
    if (existing.kind === kind && existing.block_type === operation.blockType &&
      existing.baseline === expected &&
      payloadCount === 1 && (operation.image === null || (asset &&
        asset.file_size === operation.image.fileSize &&
        asset.mime_type.toLowerCase() === operation.image.mimeType.toLowerCase() &&
        JSON.parse(asset.note_ids).includes('note')))) return false;
    throw new Error('original create-block identity conflicts with persisted state');
  }
  if (operation.blockType === IMAGE) {
    const asset = db.prepare('SELECT * FROM note_asset WHERE asset_hash=?').get(operation.image.hash);
    if (asset && (asset.file_size !== operation.image.fileSize ||
      asset.mime_type.toLowerCase() !== operation.image.mimeType.toLowerCase())) {
      throw new Error('CREATE_BLOCK_IMAGE_ASSET_METADATA_CONFLICT');
    }
    if (!asset) db.prepare(`INSERT INTO note_asset VALUES(?,0,'["note"]',?,?,NULL)`)
      .run(operation.image.hash, operation.image.fileSize, operation.image.mimeType);
  }
  db.prepare(`INSERT INTO original_element_z_index VALUES('note',?,?,?,?,?,?,?)`).run(
    operation.timestamp, operation.site, operation.pageTimestamp, operation.pageSite,
    operation.pageIndex, kind, operation.zIndex);
  db.prepare(`INSERT INTO original_block_state VALUES('note',?,?,?,?)`).run(
    operation.timestamp, operation.site, operation.blockType, expected);

  const payload = JSON.stringify({ id: `${operation.timestamp}:${operation.site}`,
    type: operation.blockType, baseline: operation });
  if (target.archived) db.prepare(`INSERT INTO archived_snapshot VALUES(
    'note',?,?,?,?,?,?,0,?)`).run(operation.pageTimestamp, operation.pageSite,
    operation.pageIndex, `${operation.timestamp}:${operation.site}`, kind, payload,
    target.revision + 1);
  else db.prepare(`INSERT INTO snapshot VALUES('note',?,?,?,?,0,?)`).run(target.pageId,
    `${operation.timestamp}:${operation.site}`, kind, payload, target.revision + 1);
  return true;
}

function reorderAndAdvance(db, target) {
  const rows = db.prepare(`SELECT ts,site,kind FROM original_element_z_index
    WHERE note_id='note' AND page_ts=10 AND page_site=1 AND page_idx=0
    ORDER BY length(z_index),z_index,ts,site`).all();
  rows.forEach((row, index) => {
    const elementId = `${row.ts}:${row.site}`;
    if (target.archived) db.prepare(`UPDATE archived_snapshot SET element_order=?
      WHERE note_id='note' AND page_ts=10 AND page_site=1 AND page_idx=0 AND element_id=?`)
      .run(index, elementId);
    else db.prepare(`UPDATE snapshot SET element_order=?
      WHERE note_id='note' AND page_id=? AND element_id=?`).run(index, target.pageId, elementId);
  });
  if (target.archived) db.exec(`UPDATE original_deleted_page
    SET content_revision=content_revision+1 WHERE note_id='note'`);
  else db.prepare(`UPDATE page_info SET content_revision=content_revision+1
    WHERE note_id='note' AND page_id=?`).run(target.pageId);
  target.revision++;
}

function replay(db, operations, failAfter = -1) {
  try {
    preflight(operations);
  } catch (error) {
    return error.message;
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    const pageOperation = operations.find(operation => operation.type === 3);
    db.prepare(`INSERT OR IGNORE INTO original_page_identity VALUES('note',?,?,?,?)`)
      .run(pageOperation.timestamp, pageOperation.site, pageOperation.index, pageOperation.pageId);
    if (pageOperation.archived) db.prepare(
      `INSERT OR IGNORE INTO original_deleted_page VALUES('note',?,?,?,?,0)`)
      .run(pageOperation.timestamp, pageOperation.site, pageOperation.index, pageOperation.pageId);
    else db.prepare(`INSERT OR IGNORE INTO page_info VALUES('note',?,0)`).run(pageOperation.pageId);
    const target = { pageId: pageOperation.pageId, archived: pageOperation.archived,
      revision: pageOperation.archived ? db.prepare('SELECT content_revision revision FROM original_deleted_page').get().revision :
        db.prepare('SELECT content_revision revision FROM page_info').get().revision };
    let applied = 0;
    for (const operation of operations.filter(operation => operation.type === 22)) {
      if (createBlock(db, operation, target)) {
        reorderAndAdvance(db, target);
        if (++applied === failAfter) throw new Error('injected bundle block failure');
      }
    }
    db.exec('COMMIT');
    return null;
  } catch (error) {
    db.exec('ROLLBACK');
    return error.message;
  }
}

const complete = [page, text, image, math];
const db = database();
assert.equal(replay(db, complete), null);
assert.equal(db.prepare('SELECT count(*) count FROM original_block_state').get().count, 3);
assert.deepEqual(db.prepare('SELECT block_type FROM original_block_state ORDER BY ts').all()
  .map(row => row.block_type), [TEXT, IMAGE, MATH]);
assert.equal(db.prepare('SELECT count(*) count FROM note_asset').get().count, 1);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 3);

const partial = database();
assert.equal(replay(partial, complete), null);
partial.exec('DELETE FROM note_asset');
assert.equal(replay(partial, complete),
  'original create-block identity conflicts with persisted state');
assert.deepEqual(db.prepare('SELECT element_id FROM snapshot ORDER BY element_order').all()
  .map(row => row.element_id), ['20:2', '30:3', '40:4']);
const snapshot = JSON.stringify(db.prepare('SELECT * FROM snapshot ORDER BY element_id').all());
assert.equal(replay(db, complete), null);
assert.equal(JSON.stringify(db.prepare('SELECT * FROM snapshot ORDER BY element_id').all()), snapshot);
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 3);
db.exec(`UPDATE original_element_z_index SET z_index='999' WHERE ts=20 AND site=2`);
assert.equal(replay(db, complete), null);
assert.equal(db.prepare('SELECT z_index FROM original_element_z_index WHERE ts=20').get().z_index,
  '999');
assert.equal(replay(db, [page, { ...text, width: 201 }]),
  'original create-block identity conflicts with persisted state');
assert.equal(db.prepare('SELECT content_revision FROM page_info').get().content_revision, 3);

const archived = database();
assert.equal(replay(archived, [archivedPage, text]), null);
assert.equal(archived.prepare('SELECT count(*) count FROM archived_snapshot').get().count, 1);
assert.equal(archived.prepare('SELECT content_revision FROM original_deleted_page').get()
  .content_revision, 1);

for (const operations of [
  [page, block(50, 5, IMAGE)],
  [page, block(50, 5, MATH)],
  [{ ...text, pageTimestamp: 99 }, page],
]) {
  const rejected = database();
  assert.match(replay(rejected, operations), /MISSING|FIELDS|PAGE_MISSING/);
  assert.equal(rejected.prepare('SELECT count(*) count FROM original_page_identity').get().count, 0);
  assert.equal(rejected.prepare('SELECT count(*) count FROM original_block_state').get().count, 0);
}

const failed = database();
assert.equal(replay(failed, complete, 2), 'injected bundle block failure');
assert.equal(failed.prepare('SELECT count(*) count FROM original_page_identity').get().count, 0);
assert.equal(failed.prepare('SELECT count(*) count FROM original_block_state').get().count, 0);
assert.equal(failed.prepare('SELECT count(*) count FROM note_asset').get().count, 0);
assert.equal(failed.prepare('SELECT count(*) count FROM snapshot').get().count, 0);

assert.match(blockSource, /export function decodeOriginalCreateBlockTable/);
assert.match(blockSource, /preflightTable\(table: OriginalFlatBufferTableReader/);
assert.match(blockSource, /originalCreateMatches/);
assert.match(blockSource, /originalMaterializedElementExists/);
assert.match(blockSource, /imageAssetReferenceMatches/);
for (const column of ['create_page_timestamp', 'create_origin_x', 'create_rotation',
  'create_scale_x', 'create_width', 'create_corner', 'create_text_paper',
  'create_math_latex', 'create_math_color', 'create_image_hash_bits',
  'create_image_crop_x', 'create_image_flipped_horizontally', 'create_margin_top',
  'create_z_index']) assert.match(blockSource, new RegExp(column));
assert.match(bundleSource, /createBlock\.preflightTable/);
assert.match(bundleSource, /await createBlock\.applyTable/);

console.log('success|bundle-create-block=3|text=1|image=1|math=1|asset-pending=1|' +
  'z-order=3|revision=3|archived=1|retry-idempotent=1|identity-conflict=1|' +
  'post-modify-create-retry=1|partial-state-rejected=1|invalid-zero-write=3|' +
  'failure-full-rollback=1');
