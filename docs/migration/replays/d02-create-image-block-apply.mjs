import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const BITS = ['0', '1', '9007199254740993', '18446744073709551614',
  '42', '4294967296', '9223372036854775808', '18446744073709551615'];
const LEGACY_HASH = BITS.join(':');
const STORAGE_HASH = storageHash(BITS);
const METADATA = { fileName: 'original.png', mimeType: 'image/png', fileSize: 4096,
  intrinsicWidth: 4032, intrinsicHeight: 3024 };

function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(`PRAGMA foreign_keys=ON; PRAGMA user_version=42;
    CREATE TABLE note_meta(id TEXT PRIMARY KEY);
    CREATE TABLE note_asset(asset_hash TEXT PRIMARY KEY,status INTEGER NOT NULL,
      note_ids TEXT NOT NULL,file_size INTEGER NOT NULL,mime_type TEXT NOT NULL,local_path TEXT);
    CREATE TABLE original_page_identity(note_id TEXT,seq_timestamp INTEGER,seq_site_id INTEGER,
      seq_index INTEGER,page_id TEXT,visible INTEGER,
      PRIMARY KEY(note_id,seq_timestamp,seq_site_id,seq_index));
    CREATE TABLE original_element_z_index(note_id TEXT,element_timestamp INTEGER,element_site_id INTEGER,
      page_timestamp INTEGER,page_site_id INTEGER,page_index INTEGER,kind INTEGER,z_index TEXT,
      PRIMARY KEY(note_id,element_timestamp,element_site_id));
    CREATE TABLE original_block_state(note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER,
      block_type INTEGER,create_page_timestamp INTEGER,create_page_site_id INTEGER,
      create_page_index INTEGER,create_origin_x REAL,create_origin_y REAL,create_rotation REAL,
      create_scale_x REAL,create_scale_y REAL,create_width REAL,create_height REAL,
      create_corner INTEGER,create_text_wrap INTEGER,create_enable_caption INTEGER,
      create_position_locked INTEGER,create_resizes_width INTEGER,create_text_paper TEXT,
      create_margin_top REAL,create_margin_bottom REAL,create_margin_left REAL,
      create_margin_right REAL,create_z_index TEXT,
      PRIMARY KEY(note_id,block_timestamp,block_site_id),
      FOREIGN KEY(note_id,block_timestamp,block_site_id) REFERENCES
        original_element_z_index(note_id,element_timestamp,element_site_id) ON DELETE CASCADE);
    CREATE TABLE page_info(note_id TEXT,page_id TEXT,content_revision INTEGER,
      PRIMARY KEY(note_id,page_id));
    CREATE TABLE page_element_snapshot(note_id TEXT,page_id TEXT,element_id TEXT,kind INTEGER,
      payload BLOB,revision INTEGER,element_order INTEGER,
      PRIMARY KEY(note_id,page_id,element_id,kind));
    CREATE TABLE original_deleted_page(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,page_id TEXT,content_revision INTEGER,indexed_revision INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index));
    CREATE TABLE original_deleted_page_element(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,element_id TEXT,kind INTEGER,payload BLOB,revision INTEGER,
      element_order INTEGER,
      PRIMARY KEY(note_id,page_timestamp,page_site_id,page_index,element_id,kind));
    CREATE TABLE search_page_state(note_id TEXT,page_id TEXT,indexed_revision INTEGER);
    CREATE TABLE search_item(note_id TEXT,page_id TEXT,type INTEGER,sub_id TEXT);
    CREATE TABLE original_deleted_page_search(note_id TEXT,page_timestamp INTEGER,page_site_id INTEGER,
      page_index INTEGER,type INTEGER,sub_id TEXT);
    CREATE TABLE synced_operation_inbox(note_id TEXT,timestamp INTEGER,site_id INTEGER,state INTEGER,
      deferred_reason TEXT,PRIMARY KEY(note_id,timestamp,site_id));
    CREATE TABLE note_sync_metadata(note_id TEXT PRIMARY KEY,incoming_cursor TEXT,
      applied_operation_count INTEGER);
    INSERT INTO note_meta VALUES('n'),('other');
    INSERT INTO original_page_identity VALUES('n',10,2,3,'p',1);
    INSERT INTO page_info VALUES('n','p',0);
    INSERT INTO synced_operation_inbox VALUES('n',90,7,0,NULL);
    INSERT INTO note_sync_metadata VALUES('n','122',0);`);
  migrate43(db);
  return db;
}

const imageColumns = [
  'create_image_hash_bits TEXT', 'create_image_file_name TEXT',
  'create_image_mime_type TEXT', 'create_image_file_size INTEGER',
  'create_image_width REAL', 'create_image_height REAL',
  'create_image_crop_x REAL', 'create_image_crop_y REAL',
  'create_image_crop_width REAL', 'create_image_crop_height REAL',
  'create_image_web_url TEXT', 'create_image_flipped_horizontally INTEGER',
  'create_image_flipped_vertically INTEGER',
];

function migrate43(db, fail = false) {
  db.exec('BEGIN IMMEDIATE');
  try {
    for (let index = 0; index < imageColumns.length; index++) {
      db.exec(`ALTER TABLE original_block_state ADD COLUMN ${imageColumns[index]}`);
      if (fail && index === 5) throw new Error('injected migration');
    }
    db.exec('PRAGMA user_version=43; COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function applyImage(db, options = {}) {
  const noteId = options.noteId ?? 'n';
  const timestamp = options.timestamp ?? 90;
  const siteId = options.siteId ?? 7;
  const zIndex = options.zIndex ?? '15';
  const archived = options.archived === true;
  const rows = db.prepare('SELECT * FROM note_asset WHERE asset_hash=? OR asset_hash=?')
    .all(STORAGE_HASH, LEGACY_HASH);
  if (rows.some(row => row.file_size !== METADATA.fileSize ||
    row.mime_type.toLowerCase() !== METADATA.mimeType)) {
    return 'CREATE_BLOCK_IMAGE_ASSET_METADATA_CONFLICT';
  }
  if (rows.length === 2 && rows[0].local_path !== null && rows[1].local_path !== null &&
    rows[0].local_path !== rows[1].local_path) {
    return 'CREATE_BLOCK_IMAGE_ASSET_PATH_CONFLICT';
  }
  const inbox = db.prepare(`SELECT state FROM synced_operation_inbox
    WHERE note_id=? AND timestamp=? AND site_id=?`).get(noteId, timestamp, siteId);
  if (inbox?.state === 2) return null;
  const table = archived ? 'original_deleted_page_element' : 'page_element_snapshot';
  const pageWhere = archived ?
    "note_id='n' AND page_timestamp=10 AND page_site_id=2 AND page_index=3" :
    "note_id='n' AND page_id='p'";
  const beforeElements = db.prepare(`SELECT element_id,kind FROM ${table} WHERE ${pageWhere}`).all();
  const trackedBefore = db.prepare(`SELECT element_timestamp,element_site_id,kind,z_index
    FROM original_element_z_index WHERE note_id='n' AND page_timestamp=10
    AND page_site_id=2 AND page_index=3`).all();
  const trackedKeys = new Set(trackedBefore.map(row => `${row.kind}:${elementId(row)}`));
  if (beforeElements.length !== trackedBefore.length ||
    !beforeElements.every(row => trackedKeys.has(`${row.kind}:${row.element_id}`))) {
    return 'CREATE_BLOCK_ELEMENT_ORDER_DIVERGED';
  }
  db.exec('BEGIN IMMEDIATE');
  try {
    mergeAsset(db, rows, noteId);
    fail(options, 'asset');
    db.prepare(`INSERT INTO original_element_z_index VALUES(?,?,?,?,?,?,4,?)`)
      .run(noteId, timestamp, siteId, 10, 2, 3, zIndex);
    fail(options, 'z-index');
    db.prepare(`INSERT INTO original_block_state(
      note_id,block_timestamp,block_site_id,block_type,create_page_timestamp,
      create_page_site_id,create_page_index,create_origin_x,create_origin_y,create_rotation,
      create_scale_x,create_scale_y,create_width,create_height,create_corner,create_text_wrap,
      create_enable_caption,create_position_locked,create_resizes_width,create_text_paper,
      create_margin_top,create_margin_bottom,create_margin_left,create_margin_right,create_z_index,
      create_image_hash_bits,create_image_file_name,create_image_mime_type,create_image_file_size,
      create_image_width,create_image_height,create_image_crop_x,create_image_crop_y,
      create_image_crop_width,create_image_crop_height,create_image_web_url,
      create_image_flipped_horizontally,create_image_flipped_vertically)
      VALUES(?,?,?,1,10,2,3,12,34,0.5,2,3,200,150,1,0,0,1,0,NULL,
        3,10,5,5,?,
        ?,?,?,?,?,?,
        ?,?,?,?,
        ?,?,?)`)
      .run(noteId, timestamp, siteId, zIndex, JSON.stringify(BITS), METADATA.fileName,
        METADATA.mimeType, METADATA.fileSize, METADATA.intrinsicWidth, METADATA.intrinsicHeight,
        -5, 2, 100, 50, 'https://example.test/image.png', 1, 1);
    fail(options, 'block-state');
    const tracked = trackedBefore.concat([{
      element_timestamp: timestamp, element_site_id: siteId, kind: 4, z_index: zIndex,
    }]).sort(compareRows);
    const id = elementId({ element_timestamp: timestamp, element_site_id: siteId });
    const payload = Buffer.from(JSON.stringify({ kind: 'image', data: {
      id, type: 4, transform: [1.755165, -1.438277, 12, 0.958851, 2.632748, 34, 0, 0, 1],
      bounds: { left: -203.74155, top: 34, right: 363.033, bottom: 560.4122 },
      assetHash: LEGACY_HASH, assetHashBits: BITS, fileName: METADATA.fileName,
      mimeType: METADATA.mimeType, fileSize: METADATA.fileSize,
      intrinsicWidth: METADATA.intrinsicWidth, intrinsicHeight: METADATA.intrinsicHeight,
      cropRect: { left: -5, top: 2, right: 95, bottom: 52 }, blockWidth: 200,
      blockHeight: 150, rotationRadians: 0.5, corner: 1, textWrap: 0,
      enableCaption: false, webUrl: 'https://example.test/image.png',
      imageFlippedHorizontally: true, imageFlippedVertically: true, positionLocked: true,
    } }));
    const revision = currentRevision(db, archived) + 1;
    const order = tracked.findIndex(row => row.element_timestamp === timestamp &&
      row.element_site_id === siteId);
    if (archived) {
      db.prepare(`INSERT INTO original_deleted_page_element
        VALUES('n',10,2,3,?,4,?,?,?)`).run(id, payload, revision, order);
    } else {
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p',?,4,?,?,?)`)
        .run(id, payload, revision, order);
    }
    fail(options, 'snapshot');
    for (let index = 0; index < tracked.length; index++) {
      const row = tracked[index];
      const changed = db.prepare(`UPDATE ${table} SET element_order=? WHERE ${pageWhere}
        AND element_id=? AND kind=?`).run(index, elementId(row), row.kind).changes;
      assert.equal(changed, 1);
    }
    fail(options, 'reorder');
    if (archived) {
      db.exec(`UPDATE original_deleted_page SET content_revision=content_revision+1,
        indexed_revision=NULL WHERE note_id='n' AND page_timestamp=10 AND page_site_id=2
        AND page_index=3; DELETE FROM original_deleted_page_search WHERE note_id='n'
        AND page_timestamp=10 AND page_site_id=2 AND page_index=3 AND type=2;`);
    } else {
      db.exec(`UPDATE page_info SET content_revision=content_revision+1
        WHERE note_id='n' AND page_id='p';
        DELETE FROM search_page_state WHERE note_id='n' AND page_id='p';
        DELETE FROM search_item WHERE note_id='n' AND page_id='p' AND type=2;`);
    }
    fail(options, 'revision');
    db.prepare(`UPDATE synced_operation_inbox SET state=2,deferred_reason=NULL
      WHERE note_id=? AND timestamp=? AND site_id=?`).run(noteId, timestamp, siteId);
    fail(options, 'inbox');
    db.prepare(`UPDATE note_sync_metadata SET incoming_cursor='124',
      applied_operation_count=applied_operation_count+1 WHERE note_id=?`).run(noteId);
    fail(options, 'cursor');
    db.exec('COMMIT');
    return null;
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function mergeAsset(db, rows, noteId) {
  if (rows.length === 0) {
    db.prepare('INSERT INTO note_asset VALUES(?,0,?,?,?,NULL)')
      .run(STORAGE_HASH, JSON.stringify([noteId]), METADATA.fileSize, METADATA.mimeType);
    return;
  }
  if (rows.length === 1) {
    const ids = mergeIds(JSON.parse(rows[0].note_ids), [noteId]);
    db.prepare('UPDATE note_asset SET note_ids=? WHERE asset_hash=?')
      .run(JSON.stringify(ids), rows[0].asset_hash);
    return;
  }
  const canonical = rows.find(row => row.asset_hash === STORAGE_HASH);
  const legacy = rows.find(row => row.asset_hash === LEGACY_HASH);
  const preferred = canonical.local_path !== null ? canonical : legacy.local_path !== null ? legacy :
    ([0, 4].includes(canonical.status) && ![0, 4].includes(legacy.status) ? legacy : canonical);
  const ids = mergeIds(mergeIds(JSON.parse(canonical.note_ids), JSON.parse(legacy.note_ids)), [noteId]);
  db.prepare(`UPDATE note_asset SET status=?,note_ids=?,local_path=? WHERE asset_hash=?`)
    .run(preferred.status, JSON.stringify(ids), preferred.local_path, STORAGE_HASH);
  db.prepare('DELETE FROM note_asset WHERE asset_hash=?').run(LEGACY_HASH);
}

function seedPriorElements(db, archived = false) {
  const values = [
    [80, 1, 1, '5'], [81, 1, 2, '15'], [82, 1, 3, '25'],
  ];
  for (const [timestamp, site, kind, zIndex] of values) {
    const id = elementId({ element_timestamp: timestamp, element_site_id: site });
    db.prepare(`INSERT INTO original_element_z_index VALUES('n',?,?,10,2,3,?,?)`)
      .run(timestamp, site, kind, zIndex);
    if (archived) {
      db.prepare(`INSERT INTO original_deleted_page_element
        VALUES('n',10,2,3,?,?,X'7B7D',0,?)`).run(id, kind, kind - 1);
    } else {
      db.prepare(`INSERT INTO page_element_snapshot VALUES('n','p',?,?,X'7B7D',0,?)`)
        .run(id, kind, kind - 1);
    }
  }
}

function archive(db) {
  db.exec(`INSERT INTO original_deleted_page VALUES('n',10,2,3,'p',0,0);
    DELETE FROM page_info;`);
}

function currentRevision(db, archived) {
  return archived ? db.prepare('SELECT content_revision FROM original_deleted_page').get().content_revision :
    db.prepare('SELECT content_revision FROM page_info').get().content_revision;
}

function fail(options, point) {
  if (options.failAt === point) throw new Error(`injected ${point}`);
}

function compareRows(left, right) {
  if (left.z_index.length !== right.z_index.length) return left.z_index.length - right.z_index.length;
  if (left.z_index !== right.z_index) return left.z_index < right.z_index ? -1 : 1;
  return left.element_timestamp - right.element_timestamp || left.element_site_id - right.element_site_id;
}

function elementId(row) {
  return `op:${row.element_timestamp.toString(16)}:${row.element_site_id.toString(16)}`;
}

function mergeIds(left, right) {
  const result = [];
  for (const id of left.concat(right)) if (!result.includes(id)) result.push(id);
  return result;
}

function storageHash(bits) {
  let result = '';
  for (const bit of bits) {
    let value = BigInt(bit);
    for (let index = 0; index < 8; index++) {
      result += Number(value & 255n).toString(16).padStart(2, '0');
      value >>= 8n;
    }
  }
  return result;
}

function snapshot(db) {
  const tables = ['note_asset', 'original_element_z_index', 'original_block_state',
    'page_info', 'page_element_snapshot', 'original_deleted_page',
    'original_deleted_page_element', 'synced_operation_inbox', 'note_sync_metadata'];
  return JSON.stringify(tables.map(table => [table,
    db.prepare(`SELECT * FROM ${table} ORDER BY rowid`).all()]));
}

const migrationFailure = new DatabaseSync(':memory:');
migrationFailure.exec(`PRAGMA user_version=42; CREATE TABLE original_block_state(
  note_id TEXT,block_timestamp INTEGER,block_site_id INTEGER);`);
assert.throws(() => migrate43(migrationFailure, true), /injected migration/);
assert.equal(migrationFailure.prepare('PRAGMA user_version').get().user_version, 42);
assert.equal(migrationFailure.prepare(`SELECT count(*) count FROM pragma_table_info(
  'original_block_state') WHERE name LIKE 'create_image_%'`).get().count, 0);

const live = database(); seedPriorElements(live);
assert.equal(applyImage(live, { zIndex: '15' }), null);
const asset = live.prepare('SELECT * FROM note_asset').get();
assert.equal(asset.asset_hash, STORAGE_HASH); assert.equal(asset.status, 0);
assert.deepEqual(JSON.parse(asset.note_ids), ['n']); assert.equal(asset.local_path, null);
const block = live.prepare('SELECT * FROM original_block_state').get();
assert.deepEqual(JSON.parse(block.create_image_hash_bits), BITS);
assert.equal(block.create_image_file_name, METADATA.fileName);
assert.equal(block.create_image_crop_x, -5); assert.equal(block.create_image_flipped_vertically, 1);
const materialized = JSON.parse(Buffer.from(live.prepare(`SELECT payload FROM page_element_snapshot
  WHERE kind=4`).get().payload).toString());
assert.equal(materialized.kind, 'image'); assert.equal(materialized.data.assetHash, LEGACY_HASH);
assert.deepEqual(materialized.data.cropRect, { left: -5, top: 2, right: 95, bottom: 52 });
assert.deepEqual(live.prepare(`SELECT kind FROM page_element_snapshot ORDER BY element_order`).all()
  .map(row => row.kind), [1, 2, 4, 3]);
assert.equal(live.prepare('SELECT state FROM synced_operation_inbox').get().state, 2);
const cursor = live.prepare(`SELECT incoming_cursor,applied_operation_count
  FROM note_sync_metadata`).get();
assert.equal(cursor.incoming_cursor, '124'); assert.equal(cursor.applied_operation_count, 1);
const idempotent = snapshot(live); assert.equal(applyImage(live), null); assert.equal(snapshot(live), idempotent);

const existingLocal = database();
existingLocal.prepare('INSERT INTO note_asset VALUES(?,1,?,?,?,?)')
  .run(STORAGE_HASH, JSON.stringify(['other']), METADATA.fileSize, 'IMAGE/PNG', '/asset/local');
assert.equal(applyImage(existingLocal), null);
const preserved = existingLocal.prepare('SELECT * FROM note_asset').get();
assert.equal(preserved.status, 1); assert.equal(preserved.local_path, '/asset/local');
assert.deepEqual(JSON.parse(preserved.note_ids), ['other', 'n']);

const dual = database();
dual.prepare('INSERT INTO note_asset VALUES(?,0,?,?,?,NULL)')
  .run(STORAGE_HASH, JSON.stringify(['a']), METADATA.fileSize, METADATA.mimeType);
dual.prepare('INSERT INTO note_asset VALUES(?,3,?,?,?,?)')
  .run(LEGACY_HASH, JSON.stringify(['b']), METADATA.fileSize, METADATA.mimeType, '/legacy/local');
assert.equal(applyImage(dual), null);
assert.equal(dual.prepare('SELECT count(*) count FROM note_asset').get().count, 1);
const merged = dual.prepare('SELECT * FROM note_asset').get();
assert.equal(merged.asset_hash, STORAGE_HASH); assert.equal(merged.status, 3);
assert.equal(merged.local_path, '/legacy/local');
assert.deepEqual(JSON.parse(merged.note_ids), ['a', 'b', 'n']);

const conflict = database();
conflict.prepare('INSERT INTO note_asset VALUES(?,1,?,?,?,?)')
  .run(STORAGE_HASH, JSON.stringify(['other']), 99, METADATA.mimeType, '/asset/local');
const conflictBefore = snapshot(conflict);
assert.equal(applyImage(conflict), 'CREATE_BLOCK_IMAGE_ASSET_METADATA_CONFLICT');
assert.equal(snapshot(conflict), conflictBefore);

const pathConflict = database();
pathConflict.prepare('INSERT INTO note_asset VALUES(?,1,?,?,?,?)')
  .run(STORAGE_HASH, JSON.stringify(['a']), METADATA.fileSize, METADATA.mimeType, '/canonical');
pathConflict.prepare('INSERT INTO note_asset VALUES(?,3,?,?,?,?)')
  .run(LEGACY_HASH, JSON.stringify(['b']), METADATA.fileSize, METADATA.mimeType, '/legacy');
const pathConflictBefore = snapshot(pathConflict);
assert.equal(applyImage(pathConflict), 'CREATE_BLOCK_IMAGE_ASSET_PATH_CONFLICT');
assert.equal(snapshot(pathConflict), pathConflictBefore);

const archived = database(); archive(archived); seedPriorElements(archived, true);
assert.equal(applyImage(archived, { archived: true }), null);
assert.equal(archived.prepare('SELECT count(*) count FROM original_deleted_page_element WHERE kind=4')
  .get().count, 1);
assert.equal(archived.prepare('SELECT content_revision FROM original_deleted_page').get()
  .content_revision, 1);

for (const failAt of ['asset', 'z-index', 'block-state', 'snapshot', 'reorder',
  'revision', 'inbox', 'cursor']) {
  const failed = database(); seedPriorElements(failed);
  const before = snapshot(failed);
  assert.throws(() => applyImage(failed, { failAt }), new RegExp(`injected ${failAt}`));
  assert.equal(snapshot(failed), before, failAt);
}

const source = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalCreateBlockOperation.ets', import.meta.url), 'utf8');
const schema = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/DatabaseHelper.ets', import.meta.url), 'utf8');
const canonicalDdl = schema.match(
  /export const DDL_ORIGINAL_BLOCK_STATE: string = `([\s\S]*?)`;/)?.[1];
assert.notEqual(canonicalDdl, undefined);
const canonicalSchema = new DatabaseSync(':memory:');
canonicalSchema.exec(canonicalDdl);
assert.equal(canonicalSchema.prepare(`SELECT count(*) count FROM pragma_table_info(
  'original_block_state') WHERE name LIKE 'create_image_%'`).get().count, 13);
assert.doesNotMatch(source, /CREATE_BLOCK_IMAGE_UNSUPPORTED/);
assert.match(source, /originalAssetStorageHash\(asset\.assetHash\.bits\)/);
assert.match(source, /AssetStatus\.PENDING/);
assert.match(source, /kind === PageElementKind\.MATH \? 'math' : 'text'/);
assert.match(source, /CREATE_BLOCK_IMAGE_ASSET_METADATA_CONFLICT/);
assert.match(schema, /DB_VERSION: number = 48/);
assert.match(schema, /43: \[[\s\S]*create_image_hash_bits/);

console.log('success|v42-v43=1|metadata-only=1|pending=1|local-preserved=1|' +
  'legacy-key-merged=1|metadata-conflict=1|path-conflict=1|live=1|archive=1|four-kind-order=1|' +
  'idempotent=1|inbox-cursor-atomic=1|rollback=8');
