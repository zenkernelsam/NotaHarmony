import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = name => fs.readFileSync(`${originalRoot}${name}.java`, 'utf8');

const id7 = original('id7');
const haj = original('haj');
const ln2 = original('ln2');
const o59 = original('o59');
const ss8 = original('ss8');
const l3a = original('l3a');
const pq1 = original('pq1');
const oq1 = original('oq1');
const noteRepo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const bootstrap = read('note/src/main/ets/data/OriginalBlankNoteBootstrapPersistence.ets');
const createEncoder = read('note/src/main/ets/data/OriginalCreatePagePayloadEncoder.ets');
const metadataEncoder = read('note/src/main/ets/data/OriginalSetMetadataPayloadEncoder.ets');
const settings = read('note/src/main/ets/data/EditorSettingsStore.ets');
const defaultTemplate = read('note/src/main/ets/core/model/OriginalDefaultTemplate.ets');
const defaultTemplateCodec = read('note/src/main/ets/data/OriginalDefaultTemplateCodec.ets');
const library = read('note/src/main/ets/ui/library/LibraryPage.ets');
const editor = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const settingsPage = read('note/src/main/ets/ui/settings/SettingsPage.ets');
const defaultTemplatePage = read('note/src/main/ets/ui/settings/DefaultTemplatePage.ets');
const fixtures = read('note/src/test/OriginalBlankNoteBootstrap.test.ets');
const fixtureList = read('note/src/test/List.test.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');

assert.match(id7, /java\.lang\.Object r8 = r13\.h\(r14, r10\)/);
assert.match(id7, /ln2 r0 = defpackage\.haj\.a\(r4, r4, r2, r4, r0\)/);
assert.match(id7, /r7\[r12\] = r0[\s\S]*r8\[r3\] = r0[\s\S]*m18\.m0\(r8\)/);
assert.match(id7, /o59\.e\(this\.l, sc7Var\)/);
assert.match(id7, /xj2\.d\(z2dVar, qgh\.b\(l3a\.a\(\(l3a\) objE, null, null, 7\)\)/);
assert.match(haj, /aVarA\.e\(2, i, 1\)/);
assert.match(ln2, /CreatePage\(location=[\s\S]*pageCount=/);
assert.match(ln2, /return "Cannot create 0 pages"/);
assert.match(o59, /new eua\("selectedDefaultTemplate"\)/);
assert.match(o59, /return l3a\.d/);
assert.match(o59, /byte\[\] bArr = \(byte\[\]\) guaVar\.b\(s\)/);
assert.match(ss8, /aVar\.p\(vv7\.L\(l3a\.a\(l3aVar, null, null, 7\), aVar\)\)/);
assert.match(ss8, /tk8Var\.g\(euaVar, aVar\.A\(\)\)/);
assert.match(l3a, /vy7Var = m09\.d/);
assert.match(pq1, /case 5:[\s\S]*while \(it4\.hasNext\(\)\)[\s\S]*xq9Var\.a\(new wq9/);
assert.match(oq1, /CreatePage op with positive pageCount not found/);
assert.match(oq1, /SetMetadata op not found/);

assert.match(noteRepo, /resolveDefaultTemplate\(\)/);
assert.match(noteRepo, /persistOriginalBlankNoteBootstrap\(store, note\.id, note\.title, defaultTemplate\)/);
assert.doesNotMatch(noteRepo.slice(noteRepo.indexOf('async createNote('),
  noteRepo.indexOf('async createNoteWithMeta(')), /persistOriginalCreatePage/);
const metadataEncode = bootstrap.indexOf(
  'const metadataTable: Uint8Array = encodeOriginalSetMetadataTitleAndPageBackground');
const metadataAppend = bootstrap.indexOf('await appendOperation(store, {', metadataEncode);
const pageCreate = bootstrap.indexOf(
  'const created: PersistedOriginalPageGroup = await persistOriginalCreatePages');
assert(metadataEncode >= 0 && metadataAppend > metadataEncode && pageCreate > metadataAppend);
assert.match(bootstrap, /ORIGINAL_BLANK_NOTE_PAGE_COUNT: number = 2/);
assert.match(bootstrap, /persistOriginalCreatePages\([\s\S]*ORIGINAL_BLANK_NOTE_PAGE_COUNT/);
assert.match(bootstrap, /structure_revision'\)\) !== 2/);
assert.match(bootstrap, /OpType\.ORIGINAL_SET_METADATA[\s\S]*OpType\.ORIGINAL_CREATE_PAGE/);
assert.match(createEncoder, /pageCount === 1 \? 0 : 20/);
assert.match(createEncoder, /writeU32\(bytes, rootTable \+ 20, pageCount\)/);
assert.match(metadataEncoder, /encodeOriginalSetMetadataTitleAndPageBackground/);
assert.match(metadataEncoder, /writeVtable\(bytes, rootVtable, 12, \[4, 8, 0, 0, 0, 0, 0, 0\]\)/);
assert.match(settings, /STORE_NAME: string = 'noteEditorSettings'/);
assert.match(settings, /SELECTED_DEFAULT_TEMPLATE_KEY: string = 'selectedDefaultTemplate'/);
assert.match(settings, /raw instanceof Uint8Array/);
assert.match(settings, /clearWrongTypeDefaultTemplate/);
assert.match(defaultTemplate, /PaperSize\.LETTER/);
assert.match(defaultTemplate, /originalDefaultTemplateSettings/);
assert.match(defaultTemplate, /flairSpacingPt = source === null \? null : source\.flairSpacingPt/);
assert.match(defaultTemplate, /paper\.legacyPaperIndex = source === null \? null : source\.legacyPaperIndex/);
assert.match(defaultTemplate, /selected default template did not produce concrete paper settings/);
assert.match(defaultTemplateCodec, /encodeOriginalPageBackgroundRoot/);
assert.match(defaultTemplateCodec, /OriginalFlatBufferTableReader\.fromRoot\(encoded\)/);
assert.match(metadataEncoder, /encodeOriginalPageBackgroundRoot/);
assert.match(metadataEncoder, /writeU32\(bytes, 0, layout\.backgroundTable\)/);
assert.match(library, /new NoteRepositoryImpl\([\s\S]*new EditorSettingsStore\(context\)\)/);
assert.doesNotMatch(editor, /saveSelectedDefaultTemplate/);
assert.doesNotMatch(panel, /set_default_template|onSetDefault/);
assert.match(settingsPage, /ui\/settings\/DefaultTemplatePage/);
assert.match(defaultTemplatePage, /saveSelectedDefaultTemplate/);
assert.match(fixtures, /ORIGINAL_BLANK_NOTE_PAGE_COUNT\)\.assertEqual\(2\)/);
assert.match(fixtures, /paper\.flairSpacingPt\)\.assertEqual\(18\)/);
assert.match(fixtures, /paper\.legacyPaperIndex\)\.assertEqual\(7\)/);
assert.match(fixtureList, /originalBlankNoteBootstrapTest\(\)/);
assert.match(importer, /pageCount: ORIGINAL_BLANK_NOTE_PAGE_COUNT/);

// Independent FlatBuffer field probe for the two non-default values introduced by this phase.
function u16(bytes, offset) {
  return bytes[offset] | bytes[offset + 1] << 8;
}
function u32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}
function write16(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
}
function write32(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
  bytes[offset + 2] = value >>> 16 & 255;
  bytes[offset + 3] = value >>> 24 & 255;
}
function writeVtable(bytes, offset, objectSize, fields) {
  write16(bytes, offset, 4 + fields.length * 2);
  write16(bytes, offset + 2, objectSize);
  fields.forEach((value, index) => write16(bytes, offset + 4 + index * 2, value));
}
function field(bytes, table, index) {
  const vtable = table - u32(bytes, table);
  const length = u16(bytes, vtable);
  return 4 + index * 2 >= length ? 0 : u16(bytes, vtable + 4 + index * 2);
}
function createPageCountTwo() {
  const bytes = new Uint8Array(44);
  write32(bytes, 0, 16);
  writeVtable(bytes, 4, 28, [0, 0, 20, 0]);
  write32(bytes, 16, 12);
  write32(bytes, 36, 2);
  return bytes;
}
const createPayload = createPageCountTwo();
const createRoot = u32(createPayload, 0);
assert.equal(u32(createPayload, createRoot + field(createPayload, createRoot, 2)), 2);
assert.equal(field(createPayload, createRoot, 1), 0);

const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys=ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY,title TEXT NOT NULL,structure_revision INTEGER NOT NULL);
  CREATE TABLE title_winner(note_id TEXT PRIMARY KEY,ts INTEGER,site INTEGER,title TEXT);
  CREATE TABLE background_winner(note_id TEXT PRIMARY KEY,ts INTEGER,site INTEGER,
    size INTEGER,template INTEGER,orientation INTEGER,width REAL,height REAL);
  CREATE TABLE search_item(note_id TEXT,type INTEGER,folded TEXT);
  CREATE TABLE page_info(note_id TEXT,page_id TEXT PRIMARY KEY,page_index INTEGER,
    size INTEGER,template INTEGER,orientation INTEGER,width REAL,height REAL,
    background TEXT,page_in_asset INTEGER);
  CREATE TABLE page_identity(note_id TEXT,page_id TEXT,ts INTEGER,site INTEGER,idx INTEGER,
    PRIMARY KEY(note_id,ts,site,idx));
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,note_id TEXT,
    kind TEXT,ts INTEGER,site INTEGER,page_count INTEGER,upload INTEGER);
`);

function snapshot() {
  const tables = ['note_meta', 'title_winner', 'background_winner', 'search_item',
    'page_info', 'page_identity', 'operation_log'];
  return Object.fromEntries(tables.map(table => [table,
    db.prepare(`SELECT * FROM ${table} ORDER BY rowid`).all()]));
}

function bootstrapNote(id, title, paper, failAt = '') {
  db.exec('BEGIN IMMEDIATE');
  try {
    db.prepare('INSERT INTO note_meta VALUES(?,?,0)').run(id, title);
    const metadataTs = 1;
    db.prepare('INSERT INTO title_winner VALUES(?,?,0,?)').run(id, metadataTs, title);
    db.prepare('INSERT INTO background_winner VALUES(?,?,0,?,?,?,?,?)').run(
      id, metadataTs, paper.size, paper.template, paper.orientation, paper.width, paper.height);
    db.prepare('INSERT INTO search_item VALUES(?,0,?)').run(id, title.toLowerCase());
    db.prepare('UPDATE note_meta SET structure_revision=1 WHERE id=?').run(id);
    db.prepare('INSERT INTO operation_log(note_id,kind,ts,site,page_count,upload) VALUES(?,?,?,?,NULL,1)')
      .run(id, 'SET_METADATA', metadataTs, 0);
    if (failAt === 'after-metadata') throw new Error('injected after metadata');

    const createTs = 2;
    for (let index = 0; index < 2; index++) {
      const pageId = `${id}:${createTs}:0:${index}`;
      db.prepare('INSERT INTO page_identity VALUES(?,?,?,?,?)').run(
        id, pageId, createTs, 0, index);
      db.prepare('INSERT INTO page_info VALUES(?,?,?,?,?,?,?,?,NULL,?)').run(
        id, pageId, index, paper.size, paper.template, paper.orientation,
        paper.width, paper.height, index);
      if (failAt === 'after-first-page' && index === 0) {
        throw new Error('injected after first page');
      }
    }
    db.prepare('UPDATE note_meta SET structure_revision=2 WHERE id=?').run(id);
    if (failAt === 'before-create-op') throw new Error('injected before create op');
    db.prepare('INSERT INTO operation_log(note_id,kind,ts,site,page_count,upload) VALUES(?,?,?,?,2,1)')
      .run(id, 'CREATE_PAGE', createTs, 0);
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

const custom = { size: 1, template: 2, orientation: 1, width: 297, height: 210 };
bootstrapNote('note-a', 'New Note', custom);
assert.deepEqual(db.prepare(
  'SELECT kind,page_count,upload FROM operation_log WHERE note_id=? ORDER BY sequence').all('note-a')
  .map(row => ({ ...row })), [
  { kind: 'SET_METADATA', page_count: null, upload: 1 },
  { kind: 'CREATE_PAGE', page_count: 2, upload: 1 },
]);
assert.deepEqual(db.prepare(
  'SELECT page_index,size,template,orientation,width,height,background,page_in_asset FROM page_info WHERE note_id=? ORDER BY page_index')
  .all('note-a').map(row => ({ ...row })), [
  { page_index: 0, size: 1, template: 2, orientation: 1,
    width: 297, height: 210, background: null, page_in_asset: 0 },
  { page_index: 1, size: 1, template: 2, orientation: 1,
    width: 297, height: 210, background: null, page_in_asset: 1 },
]);
assert.equal(db.prepare('SELECT structure_revision FROM note_meta WHERE id=?').get('note-a')
  .structure_revision, 2);
assert.equal(db.prepare('SELECT COUNT(*) count FROM title_winner WHERE note_id=?').get('note-a').count, 1);
assert.equal(db.prepare('SELECT COUNT(*) count FROM background_winner WHERE note_id=?').get('note-a').count, 1);

for (const failure of ['after-metadata', 'after-first-page', 'before-create-op']) {
  const before = snapshot();
  assert.throws(() => bootstrapNote(`failed-${failure}`, 'New Note', custom, failure), /injected/);
  assert.deepEqual(snapshot(), before, `${failure} must roll back the complete note bootstrap`);
}
db.close();

console.log('blankNoteBootstrap=combined-set-metadata-then-two-page-create-selected-default-rollback');
