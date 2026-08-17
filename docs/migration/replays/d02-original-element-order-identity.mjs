import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { DatabaseSync } from 'node:sqlite';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const readRepo = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = name => fs.readFileSync(path.join(originalRoot, name), 'utf8');
const template = (source, name) => {
  const match = source.match(new RegExp('export const ' + name + ': string = `([\\s\\S]*?)`;'));
  assert.ok(match, `missing ${name}`);
  return match[1];
};

const vnd = readOriginal('vnd.java');
const zh9 = readOriginal('zh9.java');
const ssc = readOriginal('ssc.java');
const order = readRepo('note/src/main/ets/core/model/PageElementOrder.ets');
const identity = readRepo('note/src/main/ets/data/PageElementIdentity.ets');
const database = readRepo('note/src/main/ets/data/DatabaseHelper.ets');
const manager = readRepo('note/src/main/ets/data/DatabaseManager.ets');
const persistence = readRepo('note/src/main/ets/data/StrokePersistence.ets');
const repository = readRepo('note/src/main/ets/data/PageRepositoryImpl.ets');
const importer = readRepo('note/src/main/ets/data/NoteImporter.ets');
const codec = readRepo('note/src/main/ets/data/PersistedElementCodec.ets');
const clipboard = readRepo('note/src/main/ets/rendering/StrokeClipboard.ets');
const groupSelection = readRepo('note/src/main/ets/core/model/OriginalGroupSelection.ets');
const groupLayering = readRepo('note/src/main/ets/data/OriginalGroupLayering.ets');
const inbox = readRepo('note/src/main/ets/data/SyncedOperationInbox.ets');
const opStore = readRepo('note/src/main/ets/data/OpStoreImpl.ets');
const fixture = readRepo('note/src/test/PageElementIdentity.test.ets');
const orderFixture = readRepo('note/src/test/PageElementOrder.test.ets');
const clipboardFixture = readRepo('note/src/test/StrokeClipboard.test.ets');
const persistenceFixture = readRepo('note/src/test/StrokePersistence.test.ets');
const databaseFixture = readRepo('note/src/test/DatabaseHelper.test.ets');

const snapshotDdl = template(database, 'DDL_PAGE_ELEMENT_SNAPSHOT');
const identityIndex = template(database, 'DDL_PAGE_ELEMENT_IDENTITY_INDEX');
const insertGuard = template(database, 'DDL_PAGE_ELEMENT_IDENTITY_INSERT_GUARD');
const updateGuard = template(database, 'DDL_PAGE_ELEMENT_IDENTITY_UPDATE_GUARD');

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE page_element_snapshot(
  note_id TEXT NOT NULL, page_id TEXT NOT NULL, element_id TEXT NOT NULL,
  kind INTEGER NOT NULL, payload BLOB NOT NULL, revision INTEGER NOT NULL,
  element_order INTEGER NOT NULL,
  PRIMARY KEY(note_id,page_id,element_id,kind))`);
const insert = db.prepare(`INSERT INTO page_element_snapshot
  (note_id,page_id,element_id,kind,payload,revision,element_order) VALUES(?,?,?,?,X'01',0,?)`);

// Legacy corruption does not make v64 initialization fail.
insert.run('legacy', 'page-a', 'shared', 1, 0);
insert.run('legacy', 'page-b', 'shared', 2, 0);
db.exec(identityIndex);
const queryPlan = db.prepare(`EXPLAIN QUERY PLAN SELECT 1
  FROM page_element_snapshot WHERE note_id = ? AND element_id = ?`).all('legacy', 'shared');
assert.ok(queryPlan.some(row => String(row.detail).includes('idx_page_snapshot_identity')));
db.exec(insertGuard);
db.exec(updateGuard);
assert.equal(db.prepare(`SELECT COUNT(*) AS count FROM page_element_snapshot
  WHERE note_id='legacy' AND element_id='shared'`).get().count, 2);

insert.run('note', 'page-a', 'stroke', 1, 0);
insert.run('note', 'page-a', 'text', 2, 1);
assert.throws(() => insert.run('note', 'page-b', 'stroke', 3, 0),
  /duplicate note page element identity/);
assert.throws(() => insert.run('note', 'page-a', 'text', 5, 2),
  /duplicate note page element identity/);
insert.run('note', 'page-b', 'shape', 3, 0);
assert.throws(() => db.prepare(`UPDATE page_element_snapshot SET element_id='stroke'
  WHERE note_id='note' AND page_id='page-b' AND element_id='shape'`).run(),
  /duplicate note page element identity/);
assert.equal(db.prepare(`UPDATE page_element_snapshot SET revision=1
  WHERE note_id='note' AND page_id='page-a' AND element_id='stroke'`).run().changes, 1);

db.exec('BEGIN IMMEDIATE');
try {
  insert.run('note', 'page-b', 'temporary', 4, 1);
  insert.run('note', 'page-b', 'stroke', 4, 2);
  db.exec('COMMIT');
  assert.fail('conflicting transaction unexpectedly committed');
} catch (error) {
  db.exec('ROLLBACK');
  assert.match(String(error), /duplicate note page element identity/);
}
assert.equal(db.prepare(`SELECT COUNT(*) AS count FROM page_element_snapshot
  WHERE note_id='note' AND element_id='temporary'`).get().count, 0);
db.close();

const checks = [
  ['original element wrapper equality is ID-only',
    vnd.includes('return this.I.getId().equals(((vnd) obj).I.getId())') &&
      vnd.includes('return this.I.getId().hashCode()')],
  ['original z-order collector keys groups or leaves by one shared ID type',
    zh9.includes('id = undVar.a') && zh9.includes('id = vndVar.I.getId()') &&
      zh9.includes('linkedHashMap.put(id, obj2)')],
  ['original z-order unit contains ID z-index and group flag but no payload kind identity',
    ssc.includes('public final qo5 a;') && ssc.includes('public final long b;') &&
      ssc.includes('public final boolean c;') && !ssc.includes('kind')],
  ['Harmony strict order rejects duplicate identity independently of kind',
    order.includes('expectedKind !== ref.kind || seen.has(ref.elementId)')],
  ['non-empty damaged order stays fail-closed at clipboard admission',
    clipboard.includes('const normalizedOrder: PageElementRef[] | null = strictPageElementOrder(') &&
      clipboard.includes('if (normalizedOrder === null)') &&
      orderFixture.includes("it('accepts only the empty legacy order or one complete contiguous explicit order'") &&
      clipboardFixture.includes("it('rejects a non-empty Copy order instead of repairing missing or non-contiguous members'")],
  ['stored row ID and discriminator are bound to the embedded payload identity',
    codec.includes("persisted.kind !== expectedKind || persisted.data.id !== elementId") &&
      persistenceFixture.includes("it('binds a stored row kind and ID to its persisted payload'")],
  ['Group and leaf entities share one identity gate',
    groupSelection.includes('orderedIdentities.has(group.id) || groupIds.has(group.id)') &&
      groupLayering.includes('entityIds.has(group.id) || groupIds.has(group.id)')],
  ['note-wide reservation is atomic and ID-only',
    identity.includes('pending.has(elementId) || reserved.has(elementId)') &&
      identity.indexOf('for (const elementId of pending)') > identity.indexOf('return false')],
  ['save and grouped history query other live pages before mutation',
    persistence.match(/assertLivePageElementIdsAvailable\(/g)?.length >= 3],
  ['deleted-page restore rejects identity captured by another live page',
    repository.includes('await assertLivePageElementIdsAvailable(') &&
      repository.includes('checkpointElementIds.push(element.elementId)')],
  ['both package import paths reserve identity before creating the note',
    importer.match(/reserveNotePageElementIds\(noteElementIds, pageElementIds\)/g)?.length === 2 &&
      importer.includes('页面元素身份跨页冲突') &&
      importer.includes('Notability 页面元素身份跨页冲突')],
  ['v64 installs insert and update guards without a legacy-breaking unique index',
    database.includes('export const DB_VERSION: number = 64') &&
      database.includes('64: [') && !snapshotDdl.includes('UNIQUE(note_id, element_id)')],
  ['v64 builds the non-unique identity lookup index before both guards',
    database.indexOf('DDL_PAGE_ELEMENT_IDENTITY_INDEX,', database.indexOf('64: [')) <
      database.indexOf('DDL_PAGE_ELEMENT_IDENTITY_INSERT_GUARD,', database.indexOf('64: [')) &&
      databaseFixture.includes("expect(MIGRATIONS[64][0]).assertContain('idx_page_snapshot_identity')")],
  ['latest-schema initialization installs the lookup index before both guards',
    manager.includes('DDL_PAGE_ELEMENT_IDENTITY_INDEX, DDL_PAGE_ELEMENT_IDENTITY_INSERT_GUARD') &&
      manager.includes('DDL_PAGE_ELEMENT_IDENTITY_UPDATE_GUARD')],
  ['hidden or archived operations cannot reuse an existing original operation identity',
    database.includes('PRIMARY KEY(note_id, op_timestamp, editor_site_id)') &&
      inbox.includes('incoming synced operation identity has conflicting bytes or metadata') &&
      opStore.includes('SELECT editor_site_id, max_op_timestamp FROM note_sync_metadata') &&
      opStore.includes("predicates.equalTo('max_op_timestamp', currentTimestamp)") &&
      opStore.includes("throw new Error('operation clock changed concurrently')") &&
      opStore.includes('cannot replace an editor site after operation identity has been established')],
  ['ArkTS fixture covers cross-page cross-kind and atomic failure',
    fixture.includes('rejects a cross-page ID regardless of payload kind') &&
      fixture.includes('rejects an invalid page atomically')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

console.log(`D02_ORIGINAL_ELEMENT_ORDER_IDENTITY_REPLAY_OK TOTAL=${checks.length + 10} FAILED=0`);
