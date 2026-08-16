import assert from 'node:assert/strict';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = name => fs.readFileSync(`${originalRoot}${name}.java`, 'utf8');

const uge = original('uge');
const qgh = original('qgh');
const l3a = original('l3a');
const fad = original('fad');
const v69 = original('v69');
const l2d = original('l2d');
const m2d = original('m2d');
const nz9 = original('nz9');
const k3a = original('k3a');
const sw9 = original('sw9');
const model = read('note/src/main/ets/core/model/PageBackgroundModel.ets');
const encoder = read('note/src/main/ets/data/OriginalSetMetadataPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/OriginalNoteBackgroundPersistence.ets');
const reducer = read('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const createPage = read('note/src/main/ets/data/OriginalCreatePageOperation.ets');
const repository = read('note/src/main/ets/data/PageRepositoryImpl.ets');
const history = read('note/src/main/ets/data/PersistentHistory.ets');
const editor = read('note/src/main/ets/ui/editor/NotePage.ets');
const panel = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const picker = read('note/src/main/ets/core/model/OriginalTemplatePickerState.ets');
const opTypes = read('note/src/main/ets/core/model/OpTypes.ets');
const fixtures = read('note/src/test/OriginalSetMetadataPayloadEncoder.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

assert.match(uge, /qgh\.b\(l3a\.a\(\(l3a\) vgeVar\.R\.getValue\(\), null, null, 7\)\)/);
assert.match(uge, /qgh\.b\(l3a\.a\(\(l3a\) vgeVar\.R\.getValue\(\), null, \(\(a79\) x09Var\)\.K, 3\)\)/);
assert.match(qgh, /int iL = nz9Var != null \? vv7\.L\(nz9Var, aVarA\) : 0/);
assert.match(qgh, /aVarA\.C\(1\)[\s\S]*aVarA\.h\(0, iL\)[\s\S]*aVarA\.p\(aVarA\.n\(\)\)/);
assert.match(l3a, /h4a\.f\(h4aVar\.a\(\), 72\.0f\)/);
assert.match(l3a, /h4a\.f\(h4aVar\.a\(\), 2\.83465f\)/);
assert.match(l3a, /Boolean\.valueOf\(gq0Var\.a\.a\(\) != n3a\.LINES\)/);
assert.match(l3a, /sw9 sw9VarL = nz9Var2 != null \? nz9Var2\.l\(\) : null/);
assert.match(l3a, /Float fValueOf2 = nz9Var2 != null \? Float\.valueOf\(nz9Var2\.m\(\)\) : null/);
assert.match(l3a, /vy7Var = m09\.d/);
assert.match(fad, /w3aVar = fD > \(qedVarN3 != null \? qedVarN3\.c\(\) : 0\.0f\) \? w3a\.J : w3a\.I/);
assert.match(v69, /pageBackgroundRegister/);
assert.match(v69, /\(\(fqb\) ei0Var\.get\(\)\)\.c\(uq9Var5, m2dVarP\.j\(\)\)/);
assert.match(l2d, /int iC = c\(6\)/);
assert.match(m2d, /int iC = c\(4\)/);
for (const offset of [4, 6, 8, 10, 12]) assert.match(nz9, new RegExp(`int iC = c\\(${offset}\\)`));
assert.match(k3a, /int iC = c\(12\)/);
assert.match(sw9, /int iC = c\(14\)/);

assert.match(model, /ORIGINAL_A_SERIES_MM_TO_POINTS: number = 2\.83465/);
assert.match(model, /ORIGINAL_FLAIR_SPACING_PT: number = 36/);
assert.match(model, /ORIGINAL_MARGIN_PT: number = 36/);
assert.match(model, /export function originalPaperOrientation/);
assert.match(model, /background\.sourceWidthPt > background\.sourceHeightPt/);
assert.match(model, /orientation: orientation/);
assert.match(encoder, /l2d SetMetadata\.field1 -> m2d SetPageBackground\.field0 -> nz9 PageBackground/);
assert.match(encoder, /writeVtable\(bytes, layout\.setterVtable, 8, \[background === null \? 0 : 4\]\)/);
assert.match(encoder, /writeVtable\(bytes, layout\.metadataVtable, 80, \[4, 68, 72, 76\]\)/);
assert.match(encoder, /writeU32\(bytes, layout\.cropVector, pdf\.cropBoxes\.length\)/);
assert.match(persistence, /hasAlignedOriginalPageState\(store, noteId\)/);
assert.match(persistence, /OriginalSetMetadataOperationApplier\(\)\.apply/);
assert.match(persistence, /requested\.registerBackground/);
assert.match(persistence, /readOriginalNoteBackgroundState/);
assert.match(persistence, /toRevision !== fromRevision \+ 1/);
assert.match(persistence, /opType: OpType\.ORIGINAL_SET_METADATA/);
assert.match(persistence, /uploadImmediately: true/);
assert.match(persistence, /opType: OpType\.UPDATE_NOTE_BACKGROUND/);
assert.match(reducer, /WHERE page\.note_id = \? AND page\.background_json IS NULL/);
assert.match(createPage, /decoded === null[\s\S]*readEffectiveNoteBackground\(store, noteId\)/);
assert.match(createPage, /'background_json': serializePageBackground\(background\)/);
assert.match(repository, /original page settings must use note-level SET_METADATA/);
assert.match(repository, /persistOriginalNoteBackground/);
assert.match(editor, /UndoableActionType\.NOTE_BACKGROUND/);
assert.match(editor, /this\.pages = await this\.pageRepo\.getPages\(this\.noteId\)/);
assert.match(panel, /applyOriginalTemplatePickerSelection/);
assert.match(picker, /applyOriginalPaperSettings/);
assert.match(opTypes, /UPDATE_NOTE_BACKGROUND = 34/);
assert.match(opTypes, /ORIGINAL_SET_METADATA = 78/);
assert.match(history, /OpType\.ORIGINAL_SET_METADATA/);
assert.match(fixtures, /keeps SetPageBackground present for an explicit null reset/);
assert.match(fixtures, /sameNoteBackgroundSettings\(roundTripped, changed\)/);
assert.match(fixtures, /decoded\.before\.registerBackground === null/);
assert.match(fixtureList, /originalSetMetadataPayloadEncoderTest\(\)/);

const POINTS_TO_MM = 25.4 / 72;
const utf8 = new TextEncoder();
const textDecoder = new TextDecoder('utf-8', { fatal: true });
const align4 = value => (value + 3) & ~3;
const f32 = value => Math.fround(value);

function u16(bytes, offset) {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function u32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}

function f32At(bytes, offset) {
  return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).getFloat32(offset, true);
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

function writeFloat(bytes, offset, value) {
  new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength).setFloat32(offset, value, true);
}

function writeVtable(bytes, offset, objectSize, fields) {
  write16(bytes, offset, 4 + fields.length * 2);
  write16(bytes, offset + 2, objectSize);
  fields.forEach((field, index) => write16(bytes, offset + 4 + index * 2, field));
}

function storageHash(bits) {
  assert.equal(bits.length, 8);
  const bytes = [];
  for (const word of bits) {
    let value = BigInt(word);
    assert(value >= 0n && value <= 0xffffffffffffffffn);
    for (let index = 0; index < 8; index++) {
      bytes.push(Number(value & 255n));
      value >>= 8n;
    }
  }
  return bytes;
}

function encodeBackground(background) {
  const fileName = background?.pdf ? utf8.encode(background.pdf.metadata.fileName) : null;
  const mimeType = background?.pdf ? utf8.encode(background.pdf.metadata.mimeType) : null;
  const layout = {
    rootVtable: 4, rootTable: 24, setterVtable: 32, setterTable: 40,
    backgroundVtable: 0, backgroundTable: 0, paperVtable: 0, paperTable: 0,
    pdfVtable: 0, pdfTable: 0, metadataVtable: 0, metadataTable: 0,
    cropVector: 0, fileNameVector: 0, mimeTypeVector: 0, total: 48,
  };
  if (background !== null) {
    layout.backgroundVtable = 48;
    layout.backgroundTable = 64;
    let cursor = 104;
    if (background.paper !== null) {
      layout.paperVtable = cursor;
      layout.paperTable = align4(cursor + 16);
      cursor = layout.paperTable + 16;
    }
    if (background.pdf !== null) {
      layout.pdfVtable = cursor;
      layout.pdfTable = align4(cursor + 16);
      layout.metadataVtable = layout.pdfTable + 28;
      layout.metadataTable = align4(layout.metadataVtable + 12);
      layout.cropVector = align4(layout.metadataTable + 80);
      layout.fileNameVector = align4(layout.cropVector + 4 + background.pdf.cropBoxes.length * 8);
      layout.mimeTypeVector = align4(layout.fileNameVector + 4 + fileName.length + 1);
      cursor = layout.mimeTypeVector + 4 + mimeType.length + 1;
    }
    layout.total = align4(cursor);
  }
  const bytes = new Uint8Array(layout.total);
  write32(bytes, 0, layout.rootTable);
  writeVtable(bytes, layout.rootVtable, 8, [0, 4, 0, 0, 0, 0, 0, 0]);
  write32(bytes, layout.rootTable, layout.rootTable - layout.rootVtable);
  write32(bytes, layout.rootTable + 4, layout.setterTable - layout.rootTable - 4);
  writeVtable(bytes, layout.setterVtable, 8, [background === null ? 0 : 4]);
  write32(bytes, layout.setterTable, layout.setterTable - layout.setterVtable);
  if (background === null) return bytes;
  write32(bytes, layout.setterTable + 4, layout.backgroundTable - layout.setterTable - 4);
  const hasRotation = background.rotation !== 0;
  const hasSize = background.source !== null;
  writeVtable(bytes, layout.backgroundVtable, 40, [
    background.paper === null ? 0 : 4, background.pdf === null ? 0 : 8,
    hasRotation ? 12 : 0, hasSize ? 16 : 0, background.margins === null ? 0 : 24,
  ]);
  write32(bytes, layout.backgroundTable, layout.backgroundTable - layout.backgroundVtable);
  if (background.paper !== null)
    write32(bytes, layout.backgroundTable + 4, layout.paperTable - layout.backgroundTable - 4);
  if (background.pdf !== null)
    write32(bytes, layout.backgroundTable + 8, layout.pdfTable - layout.backgroundTable - 8);
  if (hasRotation) writeFloat(bytes, layout.backgroundTable + 12, background.rotation);
  if (hasSize) {
    writeFloat(bytes, layout.backgroundTable + 16, background.source[0]);
    writeFloat(bytes, layout.backgroundTable + 20, background.source[1]);
  }
  if (background.margins !== null)
    background.margins.forEach((value, index) => writeFloat(bytes, layout.backgroundTable + 24 + index * 4, value));
  if (background.paper !== null) {
    const paper = background.paper;
    writeVtable(bytes, layout.paperVtable, 16, [
      paper.flair === null ? 0 : 4, paper.spacing === null ? 0 : 8,
      paper.bleeds === null ? 0 : 5, paper.centered === null ? 0 : 6,
      paper.color === null ? 0 : 12, paper.legacy === null ? 0 : 7,
    ]);
    write32(bytes, layout.paperTable, layout.paperTable - layout.paperVtable);
    if (paper.flair !== null) bytes[layout.paperTable + 4] = paper.flair;
    if (paper.bleeds !== null) bytes[layout.paperTable + 5] = paper.bleeds ? 1 : 0;
    if (paper.centered !== null) bytes[layout.paperTable + 6] = paper.centered ? 1 : 0;
    if (paper.legacy !== null) bytes[layout.paperTable + 7] = paper.legacy;
    if (paper.spacing !== null) writeFloat(bytes, layout.paperTable + 8, paper.spacing);
    if (paper.color !== null) bytes.set(paper.color, layout.paperTable + 12);
  }
  if (background.pdf !== null) {
    const pdf = background.pdf;
    writeVtable(bytes, layout.pdfVtable, 28, [4, pdf.layout === 2 ? 0 : 8,
      pdf.total === 1 ? 0 : 12, pdf.consumed === 1 ? 0 : 16,
      pdf.offset === 0 ? 0 : 20, 24]);
    write32(bytes, layout.pdfTable, layout.pdfTable - layout.pdfVtable);
    write32(bytes, layout.pdfTable + 4, layout.metadataTable - layout.pdfTable - 4);
    if (pdf.layout !== 2) bytes[layout.pdfTable + 8] = pdf.layout;
    if (pdf.total !== 1) write32(bytes, layout.pdfTable + 12, pdf.total);
    if (pdf.consumed !== 1) write32(bytes, layout.pdfTable + 16, pdf.consumed);
    if (pdf.offset !== 0) write32(bytes, layout.pdfTable + 20, pdf.offset);
    write32(bytes, layout.pdfTable + 24, layout.cropVector - layout.pdfTable - 24);
    writeVtable(bytes, layout.metadataVtable, 80, [4, 68, 72, 76]);
    write32(bytes, layout.metadataTable, layout.metadataTable - layout.metadataVtable);
    bytes.set(storageHash(pdf.metadata.bits), layout.metadataTable + 4);
    write32(bytes, layout.metadataTable + 68, layout.fileNameVector - layout.metadataTable - 68);
    write32(bytes, layout.metadataTable + 72, layout.mimeTypeVector - layout.metadataTable - 72);
    write32(bytes, layout.metadataTable + 76, pdf.metadata.size);
    write32(bytes, layout.cropVector, pdf.cropBoxes.length);
    pdf.cropBoxes.forEach((crop, index) => {
      writeFloat(bytes, layout.cropVector + 4 + index * 8, crop[0]);
      writeFloat(bytes, layout.cropVector + 8 + index * 8, crop[1]);
    });
    for (const [offset, value] of [[layout.fileNameVector, fileName], [layout.mimeTypeVector, mimeType]]) {
      write32(bytes, offset, value.length);
      bytes.set(value, offset + 4);
      bytes[offset + 4 + value.length] = 0;
    }
  }
  return bytes;
}

function field(bytes, table, index) {
  const vtable = table - u32(bytes, table);
  const size = u16(bytes, vtable);
  return 4 + index * 2 < size ? u16(bytes, vtable + 4 + index * 2) : 0;
}

function tableField(bytes, table, index) {
  const offset = field(bytes, table, index);
  if (offset === 0) return null;
  const pointer = table + offset;
  return pointer + u32(bytes, pointer);
}

function stringField(bytes, table, index) {
  const pointerOffset = field(bytes, table, index);
  assert.notEqual(pointerOffset, 0);
  const pointer = table + pointerOffset;
  const vector = pointer + u32(bytes, pointer);
  const length = u32(bytes, vector);
  assert.equal(bytes[vector + 4 + length], 0);
  return textDecoder.decode(bytes.slice(vector + 4, vector + 4 + length));
}

function hashBits(bytes, offset) {
  const result = [];
  for (let word = 0; word < 8; word++) {
    let value = 0n;
    for (let index = 7; index >= 0; index--)
      value = value << 8n | BigInt(bytes[offset + word * 8 + index]);
    result.push(value.toString());
  }
  return result;
}

function normalizedRotation(value) {
  for (const cardinal of [0, Math.PI / 2, Math.PI, Math.PI * 3 / 2])
    if (Math.abs(value - cardinal) < 0.0001) return cardinal;
  throw new Error('non-cardinal rotation');
}

function decodeBackground(bytes) {
  const rootTable = u32(bytes, 0);
  const setter = tableField(bytes, rootTable, 1);
  assert.notEqual(setter, null, 'SetPageBackground table must be present');
  const backgroundTable = tableField(bytes, setter, 0);
  if (backgroundTable === null) return { present: true, background: null };
  const paperTable = tableField(bytes, backgroundTable, 0);
  const pdfTable = tableField(bytes, backgroundTable, 1);
  const rotationOffset = field(bytes, backgroundTable, 2);
  const sourceOffset = field(bytes, backgroundTable, 3);
  const marginsOffset = field(bytes, backgroundTable, 4);
  const paper = paperTable === null ? null : {
    flair: field(bytes, paperTable, 0) === 0 ? null : bytes[paperTable + field(bytes, paperTable, 0)],
    spacing: field(bytes, paperTable, 1) === 0 ? null : f32At(bytes, paperTable + field(bytes, paperTable, 1)),
    bleeds: field(bytes, paperTable, 2) === 0 ? null : bytes[paperTable + field(bytes, paperTable, 2)] !== 0,
    centered: field(bytes, paperTable, 3) === 0 ? null : bytes[paperTable + field(bytes, paperTable, 3)] !== 0,
    color: field(bytes, paperTable, 4) === 0 ? null :
      [...bytes.slice(paperTable + field(bytes, paperTable, 4), paperTable + field(bytes, paperTable, 4) + 4)],
    legacy: field(bytes, paperTable, 5) === 0 ? null : bytes[paperTable + field(bytes, paperTable, 5)],
  };
  let pdf = null;
  if (pdfTable !== null) {
    const metadata = tableField(bytes, pdfTable, 0);
    assert.notEqual(metadata, null);
    const cropPointer = pdfTable + field(bytes, pdfTable, 5);
    const cropVector = cropPointer + u32(bytes, cropPointer);
    const cropBoxes = [];
    for (let index = 0; index < u32(bytes, cropVector); index++)
      cropBoxes.push([f32At(bytes, cropVector + 4 + index * 8), f32At(bytes, cropVector + 8 + index * 8)]);
    pdf = {
      metadata: {
        bits: hashBits(bytes, metadata + field(bytes, metadata, 0)),
        fileName: stringField(bytes, metadata, 1), mimeType: stringField(bytes, metadata, 2),
        size: u32(bytes, metadata + field(bytes, metadata, 3)),
      },
      layout: field(bytes, pdfTable, 1) === 0 ? 2 : bytes[pdfTable + field(bytes, pdfTable, 1)],
      total: field(bytes, pdfTable, 2) === 0 ? 1 : u32(bytes, pdfTable + field(bytes, pdfTable, 2)),
      consumed: field(bytes, pdfTable, 3) === 0 ? 1 : u32(bytes, pdfTable + field(bytes, pdfTable, 3)),
      offset: field(bytes, pdfTable, 4) === 0 ? 0 : u32(bytes, pdfTable + field(bytes, pdfTable, 4)),
      cropBoxes,
    };
  }
  return { present: true, background: {
    paper, pdf,
    rotation: normalizedRotation(rotationOffset === 0 ? 0 : f32At(bytes, backgroundTable + rotationOffset)),
    source: sourceOffset === 0 ? null : [f32At(bytes, backgroundTable + sourceOffset),
      f32At(bytes, backgroundTable + sourceOffset + 4)],
    margins: marginsOffset === 0 ? null : [0, 1, 2, 3].map(index =>
      f32At(bytes, backgroundTable + marginsOffset + index * 4)),
  } };
}

const complete = {
  paper: { flair: 2, spacing: 36, bleeds: true, centered: false,
    color: [248, 249, 250, 255], legacy: 9 },
  pdf: {
    metadata: { bits: ['1','2','3','4','5','6','7','18446744073709551615'],
      fileName: '模板-一.pdf', mimeType: 'application/pdf', size: 987654 },
    layout: 0, total: 5, consumed: 2, offset: 1,
    cropBoxes: [[612, 792], [612, 1008]],
  },
  rotation: Math.PI / 2, source: [612, 792], margins: [36, 37, 38, 39],
};
assert.deepEqual(decodeBackground(encodeBackground(complete)).background, complete);
assert.deepEqual(decodeBackground(encodeBackground(null)), { present: true, background: null });
assert.equal(encodeBackground(null).length, 48);

function templateOf(background) {
  if (background.paper === null || background.paper.flair === null && background.paper.spacing === null) return 0;
  if (background.paper.flair === 2) return 2;
  if (background.paper.flair === 1) return 3;
  return 1;
}

function sizeOf(background) {
  const source = background.source ?? [612, 792];
  const short = Math.min(...source) * POINTS_TO_MM;
  const long = Math.max(...source) * POINTS_TO_MM;
  const candidates = [[0,297,420],[1,210,297],[2,148,210],[3,105,148],[4,74,105],
    [5,215.9,279.4],[6,215.9,355.6],[7,279.4,431.8]];
  return candidates.find(([,a,b]) => Math.abs(short-a) < 0.2 && Math.abs(long-b) < 0.2)?.[0] ?? 5;
}

function settings(background, registerBackground = background) {
  const source = background.source ?? [612, 792];
  const quarter = background.rotation === Math.PI / 2 || background.rotation === Math.PI * 3 / 2;
  return {
    background, registerBackground, template: templateOf(background), size: sizeOf(background),
    orientation: source[0] > source[1] ? 1 : 0,
    width: (quarter ? source[1] : source[0]) * POINTS_TO_MM,
    height: (quarter ? source[0] : source[1]) * POINTS_TO_MM,
  };
}

const a4Rotated = structuredClone(complete);
a4Rotated.paper = { flair: 0, spacing: 36, bleeds: false, centered: false,
  color: [255,255,255,255], legacy: null };
a4Rotated.source = [f32(210 * 2.83465), f32(297 * 2.83465)];
a4Rotated.margins = [36,36,36,36];
const a4RoundTrip = settings(decodeBackground(encodeBackground(a4Rotated)).background);
assert.equal(a4RoundTrip.orientation, 0, 'paper picker orientation ignores retained 90-degree rotation');
assert(a4RoundTrip.width > a4RoundTrip.height, 'rendered dimensions still include retained rotation');
assert.deepEqual(a4RoundTrip, settings(a4Rotated), 'Float32 A-series values must round-trip exactly');

const plainLetter = {
  paper: { flair: null, spacing: null, bleeds: null, centered: null,
    color: [255,255,255,255], legacy: null },
  pdf: null, rotation: 0, source: [612,792], margins: null,
};

const db = new DatabaseSync(':memory:');
db.exec(`CREATE TABLE note_meta(id TEXT PRIMARY KEY, revision INTEGER NOT NULL);
  CREATE TABLE page_info(note_id TEXT,page_id TEXT PRIMARY KEY,page_index INTEGER,size INTEGER,
    template INTEGER,orientation INTEGER,width REAL,height REAL,background TEXT);
  CREATE TABLE identity(note_id TEXT,page_id TEXT PRIMARY KEY,visible INTEGER,order_index INTEGER);
  CREATE TABLE note_background(note_id TEXT PRIMARY KEY,winner_ts INTEGER,winner_site INTEGER,
    value TEXT);
  CREATE TABLE operation_log(sequence INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT,upload INTEGER,
    history TEXT);
  INSERT INTO note_meta VALUES('note',0);
  INSERT INTO page_info VALUES('note','p1',0,5,0,0,215.9,279.4,NULL);
  INSERT INTO page_info VALUES('note','p2',1,5,2,0,215.9,279.4,'explicit-page-background');
  INSERT INTO identity VALUES('note','p1',1,0),('note','p2',1,1);`);

function effectiveSettings() {
  const row = db.prepare('SELECT value FROM note_background WHERE note_id=?').get('note');
  if (row === undefined || row.value === null)
    return settings(structuredClone(plainLetter), null);
  const concrete = JSON.parse(row.value);
  return settings(concrete, concrete);
}

function sameSettings(left, right) {
  return JSON.stringify(left) === JSON.stringify(right);
}

function coverageAligned() {
  const live = db.prepare('SELECT COUNT(*) count FROM page_info WHERE note_id=?').get('note').count;
  const mapped = db.prepare(`SELECT COUNT(*) count FROM page_info p JOIN identity i
    ON i.note_id=p.note_id AND i.page_id=p.page_id WHERE p.note_id=? AND i.visible=1`).get('note').count;
  if (live !== mapped) return false;
  const pages = db.prepare('SELECT page_id FROM page_info WHERE note_id=? ORDER BY page_index').all('note');
  const identities = db.prepare('SELECT page_id FROM identity WHERE note_id=? AND visible=1 ORDER BY order_index').all('note');
  return pages.map(row => row.page_id).join() === identities.map(row => row.page_id).join();
}

function materialize(value, timestamp) {
  const concrete = value === null ? null : decodeBackground(encodeBackground(value)).background;
  const canonical = concrete === null ? settings(structuredClone(plainLetter), null) :
    settings(concrete, concrete);
  db.prepare(`INSERT INTO note_background VALUES('note',?,7,?)
    ON CONFLICT(note_id) DO UPDATE SET winner_ts=excluded.winner_ts,winner_site=excluded.winner_site,
      value=excluded.value`).run(timestamp, value === null ? null : JSON.stringify(canonical.background));
  db.prepare(`UPDATE page_info SET size=?,template=?,orientation=?,width=?,height=?
    WHERE note_id='note' AND background IS NULL`).run(
      canonical.size, canonical.template, canonical.width > canonical.height ? 1 : 0,
      canonical.width, canonical.height);
  db.prepare("UPDATE note_meta SET revision=revision+1 WHERE id='note'").run();
  return canonical;
}

function persist(requested, selectedPageId, timestamp, historyId, injectFailure = false) {
  assert(coverageAligned(), 'complete aligned original page identity coverage is required');
  assert(db.prepare("SELECT 1 ok FROM page_info WHERE note_id='note' AND page_id=?").get(selectedPageId));
  const before = effectiveSettings();
  assert(!sameSettings(before, requested), 'unchanged note background');
  const revision = db.prepare("SELECT revision FROM note_meta WHERE id='note'").get().revision;
  db.exec('BEGIN IMMEDIATE');
  try {
    const after = materialize(requested.registerBackground, timestamp);
    assert(sameSettings(after, requested), 'reducer must materialize the canonical request');
    assert.equal(db.prepare("SELECT revision FROM note_meta WHERE id='note'").get().revision, revision + 1);
    if (injectFailure) throw new Error('injected after reducer');
    db.prepare('INSERT INTO operation_log(kind,upload,history) VALUES(?,?,NULL)')
      .run('ORIGINAL_SET_METADATA', 1);
    db.prepare('INSERT INTO operation_log(kind,upload,history) VALUES(?,?,?)')
      .run('UPDATE_NOTE_BACKGROUND', 0, historyId);
    db.exec('COMMIT');
    return { before, after };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}

function snapshot() {
  return JSON.stringify({
    meta: db.prepare('SELECT * FROM note_meta').all(), pages: db.prepare('SELECT * FROM page_info ORDER BY page_index').all(),
    background: db.prepare('SELECT * FROM note_background').all(), log: db.prepare('SELECT * FROM operation_log').all(),
  });
}

const changed = settings(a4Rotated);
const first = persist(changed, 'p1', 10, 'push');
assert.equal(first.before.size, 5);
assert.equal(db.prepare("SELECT template FROM page_info WHERE page_id='p1'").get().template, 1);
assert.equal(db.prepare("SELECT background FROM page_info WHERE page_id='p1'").get().background, null);
assert.equal(db.prepare("SELECT template FROM page_info WHERE page_id='p2'").get().template, 2,
  'explicit per-page background must not be overwritten by note fallback');

const inherited = effectiveSettings();
db.prepare(`INSERT INTO page_info VALUES('note','p3',2,?,?,?,?,?,NULL)`).run(
  inherited.size, inherited.template, inherited.width > inherited.height ? 1 : 0,
  inherited.width, inherited.height);
db.prepare("INSERT INTO identity VALUES('note','p3',1,2)").run();
assert.equal(db.prepare("SELECT template FROM page_info WHERE page_id='p3'").get().template, 1);
assert.equal(db.prepare("SELECT background FROM page_info WHERE page_id='p3'").get().background, null);

const undo = persist(first.before, 'p1', 20, 'undo');
assert.equal(undo.after.size, 5);
assert.equal(undo.after.registerBackground, null,
  'Undo must restore the nullable original register, not a concrete Letter nz9');
assert.equal(db.prepare("SELECT value FROM note_background WHERE note_id='note'").get().value, null);
persist(changed, 'p1', 30, 'redo');
const visibleHistory = db.prepare('SELECT kind,history FROM operation_log ORDER BY sequence').all()
  .filter(row => row.kind !== 'ORIGINAL_SET_METADATA').map(row => row.history);
assert.deepEqual(visibleHistory, ['push','undo','redo']);
assert.equal(db.prepare("SELECT COUNT(*) count FROM operation_log WHERE kind='ORIGINAL_SET_METADATA'").get().count, 3);
assert.equal(db.prepare("SELECT revision FROM note_meta WHERE id='note'").get().revision, 3);

const beforeFailure = snapshot();
assert.throws(() => persist(first.before, 'p1', 40, 'failed', true), /injected/);
assert.equal(snapshot(), beforeFailure, 'SET_METADATA, reducer and history companion must roll back together');

db.prepare("DELETE FROM identity WHERE page_id='p3'").run();
const beforeCoverageFailure = snapshot();
assert.throws(() => persist(first.before, 'p1', 50, 'coverage'), /coverage/);
assert.equal(snapshot(), beforeCoverageFailure);
db.close();

console.log('localSetMetadata=type1-explicit-null-full-flatbuffer-source-orientation-fallback-create-exact-null-undo-redo-history-transparent-rollback');
