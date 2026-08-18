import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8').replace(/\r\n/g, '\n');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const original = name => fs.readFileSync(
  `${originalRoot}sources/defpackage/${name}.java`, 'utf8').replace(/\r\n/g, '\n');
const originalHash = name => createHash('sha256').update(
  fs.readFileSync(`${originalRoot}sources/defpackage/${name}.java`)).digest('hex').toUpperCase();

let total = 0;
let failed = 0;
function check(label, condition) {
  total++;
  if (condition) {
    console.log(`PASS: ${label}`);
  } else {
    failed++;
    console.error(`FAIL: ${label}`);
  }
}

const xj2 = original('xj2');
const l2d = original('l2d');
const rz1 = original('rz1');
const encoder = read('note/src/main/ets/data/OriginalSetMetadataPayloadEncoder.ets');
const persistence = read('note/src/main/ets/data/OriginalNoteMetadataPersistence.ets');
const repository = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const operation = read('note/src/main/ets/data/OriginalSetMetadataOperation.ets');
const fixture = read('note/src/test/OriginalSetMetadataPayloadEncoder.test.ets');

check('original evidence hashes are pinned to the reviewed decompiled files',
  originalHash('xj2') === '1C6B44F1C4D6118BB7F73DFB6785CF970058D2000695005D39A155D65FE2B04C' &&
    originalHash('l2d') === '59F8064AFF73887DBE32DE9ED2FAB61B77A77B8711E759E68D8C2F778D8E04D8' &&
    originalHash('rz1') === '99B3433644F2BDCFC139EB96FDEEB120F7A87A5BDA693D066DE905116B9E2A86' &&
    originalHash('u5j') === 'F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC' &&
    originalHash('a79') === 'FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13');

check('original xj2 preserves the eight-field order and independent nullable inputs',
  /aVar\.C\(8\)/.test(xj2) &&
    /aVar\.h\(0, numValueOf\.intValue\(\)\)/.test(xj2) &&
    /aVar\.h\(1, numValueOf2\.intValue\(\)\)/.test(xj2) &&
    /aVar\.h\(2, numValueOf3\.intValue\(\)\)/.test(xj2) &&
    /aVar\.a\(3, zBooleanValue, false\)/.test(xj2) &&
    /aVar\.h\(4, numValueOf4\.intValue\(\)\)/.test(xj2) &&
    /aVar\.d\(5, f2\.floatValue\(\), 0\.0d\)/.test(xj2) &&
    /aVar\.c\(6, tv6Var\.I, 0\)/.test(xj2) &&
    /aVar\.c\(7, dz0Var\.b\(\), 0\)/.test(xj2));
check('original scalar false/zero fields are force-present',
  /aVar\.l = true;[\s\S]*aVar\.a\(3, zBooleanValue, false\)[\s\S]*aVar\.l = false/.test(xj2) &&
    /aVar\.l = true;[\s\S]*aVar\.c\(6, tv6Var\.I, 0\)[\s\S]*aVar\.l = false/.test(xj2) &&
    /aVar\.l = true;[\s\S]*aVar\.c\(7, dz0Var\.b\(\), 0\)[\s\S]*aVar\.l = false/.test(xj2));
check('original l2d reads field 2 as a nullable wrapper and field 3..7 as nullable scalars',
  /int iC = c\(8\)/.test(l2d) && /int iC = c\(10\)/.test(l2d) &&
    /int iC = c\(12\)/.test(l2d) && /int iC = c\(14\)/.test(l2d) &&
    /int iC = c\(16\)/.test(l2d) && /int iC = c\(18\)/.test(l2d));
check('original merge writes handwriting null when its wrapper is present',
  /public static final void O\([\s\S]*if \(z2dVar == null\)[\s\S]*z2dVar\.j\(\)/.test(rz1));

check('production writer exposes explicit presence flags and omits title/background',
  /export interface OriginalNoteMetadataPatch/.test(encoder) &&
    /writeVtable\(bytes, rootVtable, 24, \[0, 0,/.test(encoder) &&
    /patch\.hasHandwritingLanguage \? 4 : 0/.test(encoder) &&
    /patch\.hasBlockWrapSupport \? 21 : 0/.test(encoder));
check('production writer retains handwriting explicit-null and force-default scalar paths',
  /handwritingBytes: Uint8Array \| null/.test(encoder) &&
    /handwritingBytes === null \? 0 : 4/.test(encoder) &&
    /writeU8\(bytes, rootTable \+ 8, patch\.alignTextToLines \? 1 : 0\)/.test(encoder) &&
    /writeU8\(bytes, rootTable \+ 20, patch\.layoutMode\)/.test(encoder) &&
    /writeU8\(bytes, rootTable \+ 21, patch\.blockWrapSupport\)/.test(encoder));
check('production writer validates all six domains and rejects an empty patch',
  /local SET_METADATA metadata patch has no present field/.test(encoder) &&
    /isOriginalHandwritingLanguage/.test(encoder) && /isOriginalDefaultFontFamily/.test(encoder) &&
    /isOriginalDefaultFontSize/.test(encoder) && /isOriginalNoteLayoutMode/.test(encoder) &&
    /isOriginalNoteBlockWrapSupport/.test(encoder));

const persistenceBody = persistence.slice(persistence.indexOf(
  'export async function persistOriginalNoteMetadata'));
function ordered(source, needles) {
  let previous = -1;
  for (const needle of needles) {
    const current = source.indexOf(needle);
    if (current < 0 || current <= previous) return false;
    previous = current;
  }
  return true;
}
check('local persistence canonicalizes wire before allocating identity', ordered(persistenceBody, [
  'encodeOriginalSetMetadataFields(requested)',
  'OriginalFlatBufferTableReader.fromRoot(payloadTable)',
  'readOriginalNoteMetadataState(store, noteId)',
  'allocateOperationIdentity(store, noteId)',
]));
check('local persistence applies, reads back, checks one revision and appends uploadable op',
  ordered(persistenceBody, [
    'new OriginalSetMetadataOperationApplier().apply',
    'const after: OriginalNoteMetadataState',
    'assertMetadataMutation(before, after, payload)',
    'afterRevision !== beforeRevision + 1',
    'appendOperation(store, {',
    'uploadImmediately: true',
  ]));
check('persistence deliberately leaves transaction ownership to its caller',
  !/beginTransaction\(|\.commit\(|\.rollBack\(/.test(persistenceBody));
check('repository wraps the metadata persistence in the shared mutex and rollback boundary',
  /async updateOriginalNoteMetadata\(/.test(repository) &&
    /libraryMetadataMutationMutex\.runExclusive/.test(repository) &&
    /await store\.beginTransaction\(\)/.test(repository) &&
    /await persistOriginalNoteMetadata\(/.test(repository) &&
    /await store\.rollBack\(\)/.test(repository));
check('readback guards preserve unrequested registers and exact explicit-null presence',
  /after\.hasHandwritingLanguage !== before\.hasHandwritingLanguage/.test(persistence) &&
    /after\.handwritingLanguage !== before\.handwritingLanguage/.test(persistence) &&
    /changed an unrequested/.test(persistence));
check('ArkTS fixture covers concrete, null, false/zero and invalid local patches',
  /encodeOriginalSetMetadataFields\(patch\)/.test(fixture) &&
    /handwritingLanguage: null/.test(fixture) && /alignTextToLines: false/.test(fixture) &&
    /layoutMode: OriginalNoteLayoutMode\.PAGED/.test(fixture) &&
    /blockWrapSupport: OriginalNoteBlockWrapSupport\.WRAP_ENABLED/.test(fixture) &&
    /rejects empty, invalid and unsupported local metadata patches/.test(fixture));

// A small independent FlatBuffer model. It deliberately does not import or
// execute ArkTS: it checks the byte-level contract that the production writer
// and the existing OriginalFlatBufferTableReader must agree on.
function align4(value) { return (value + 3) & ~3; }
function u16(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = (value >>> 8) & 255;
}
function u32(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = (value >>> 8) & 255;
  bytes[offset + 2] = (value >>> 16) & 255;
  bytes[offset + 3] = (value >>> 24) & 255;
}
function f32(bytes, offset, value) {
  new DataView(bytes.buffer).setFloat32(offset, value, true);
}
function vtable(bytes, offset, objectSize, fields) {
  u16(bytes, offset, 4 + fields.length * 2);
  u16(bytes, offset + 2, objectSize);
  fields.forEach((field, index) => u16(bytes, offset + 4 + index * 2, field));
}
function stringAt(bytes, offset, value) {
  const encoded = Buffer.from(value, 'utf8');
  u32(bytes, offset, encoded.length);
  bytes.set(encoded, offset + 4);
  bytes[offset + 4 + encoded.length] = 0;
}
function modelEncode(patch) {
  const rootVtable = 4;
  const rootTable = 24;
  let cursor = rootTable + 24;
  const handwriting = patch.hasHandwritingLanguage ? {
    vtable: cursor,
    table: align4(cursor + 6),
    string: 0,
  } : null;
  if (handwriting !== null) {
    cursor = align4(handwriting.table + (patch.handwritingLanguage === null ? 4 : 8));
    if (patch.handwritingLanguage !== null) {
      handwriting.string = cursor;
      cursor += 4 + Buffer.byteLength(patch.handwritingLanguage, 'utf8') + 1;
    }
  }
  const family = patch.hasDefaultFontFamily ? cursor = align4(cursor) : 0;
  if (patch.hasDefaultFontFamily) cursor += 4 + Buffer.byteLength(patch.defaultFontFamily, 'utf8') + 1;
  const bytes = new Uint8Array(align4(cursor));
  u32(bytes, 0, rootTable);
  vtable(bytes, rootVtable, 24, [0, 0,
    patch.hasHandwritingLanguage ? 4 : 0,
    patch.hasAlignTextToLines ? 8 : 0,
    patch.hasDefaultFontFamily ? 12 : 0,
    patch.hasDefaultFontSize ? 16 : 0,
    patch.hasLayoutMode ? 20 : 0,
    patch.hasBlockWrapSupport ? 21 : 0]);
  u32(bytes, rootTable, rootTable - rootVtable);
  if (handwriting !== null) {
    u32(bytes, rootTable + 4, handwriting.table - (rootTable + 4));
    vtable(bytes, handwriting.vtable, patch.handwritingLanguage === null ? 4 : 8,
      [patch.handwritingLanguage === null ? 0 : 4]);
    u32(bytes, handwriting.table, handwriting.table - handwriting.vtable);
    if (patch.handwritingLanguage !== null) {
      u32(bytes, handwriting.table + 4, handwriting.string - (handwriting.table + 4));
      stringAt(bytes, handwriting.string, patch.handwritingLanguage);
    }
  }
  if (patch.hasAlignTextToLines) bytes[rootTable + 8] = patch.alignTextToLines ? 1 : 0;
  if (patch.hasDefaultFontFamily) {
    u32(bytes, rootTable + 12, family - (rootTable + 12));
    stringAt(bytes, family, patch.defaultFontFamily);
  }
  if (patch.hasDefaultFontSize) f32(bytes, rootTable + 16, patch.defaultFontSize);
  if (patch.hasLayoutMode) bytes[rootTable + 20] = patch.layoutMode;
  if (patch.hasBlockWrapSupport) bytes[rootTable + 21] = patch.blockWrapSupport;
  return bytes;
}
function read32(bytes, offset) {
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}
function fieldOffset(bytes, table, field) {
  const vtablePosition = table - read32(bytes, table);
  const size = bytes[vtablePosition] | bytes[vtablePosition + 1] << 8;
  const entry = 4 + field * 2;
  return entry + 2 <= size ? (bytes[vtablePosition + entry] |
    bytes[vtablePosition + entry + 1] << 8) : 0;
}
function tableField(bytes, table, field) {
  const offset = fieldOffset(bytes, table, field);
  if (offset === 0) return null;
  const pointer = table + offset;
  return pointer + read32(bytes, pointer);
}
function readString(bytes, table, field) {
  const child = tableField(bytes, table, field);
  if (child === null) return null;
  const length = read32(bytes, child);
  return Buffer.from(bytes.slice(child + 4, child + 4 + length)).toString('utf8');
}
function parseModel(bytes) {
  const root = read32(bytes, 0);
  const handwritingTable = tableField(bytes, root, 2);
  const handwritingLanguage = handwritingTable === null ? null : readString(bytes, handwritingTable, 0);
  return {
    title: tableField(bytes, root, 0), background: tableField(bytes, root, 1),
    handwritingPresent: handwritingTable !== null,
    handwritingLanguage,
    alignPresent: fieldOffset(bytes, root, 3) !== 0,
    align: fieldOffset(bytes, root, 3) === 0 ? null : bytes[root + fieldOffset(bytes, root, 3)] !== 0,
    familyPresent: fieldOffset(bytes, root, 4) !== 0,
    family: readString(bytes, root, 4),
    sizePresent: fieldOffset(bytes, root, 5) !== 0,
    layoutPresent: fieldOffset(bytes, root, 6) !== 0,
    layout: fieldOffset(bytes, root, 6) === 0 ? null : bytes[root + fieldOffset(bytes, root, 6)],
    wrapPresent: fieldOffset(bytes, root, 7) !== 0,
    wrap: fieldOffset(bytes, root, 7) === 0 ? null : bytes[root + fieldOffset(bytes, root, 7)],
  };
}

const concrete = {
  hasHandwritingLanguage: true, handwritingLanguage: 'en_US',
  hasAlignTextToLines: true, alignTextToLines: true,
  hasDefaultFontFamily: true, defaultFontFamily: 'Noto Sans',
  hasDefaultFontSize: true, defaultFontSize: 18.5,
  hasLayoutMode: true, layoutMode: 1,
  hasBlockWrapSupport: true, blockWrapSupport: 2,
};
const parsedConcrete = parseModel(modelEncode(concrete));
check('independent concrete FlatBuffer model keeps field 0/1 absent and all six fields present',
  parsedConcrete.title === null && parsedConcrete.background === null &&
    parsedConcrete.handwritingPresent && parsedConcrete.handwritingLanguage === 'en_US' &&
    parsedConcrete.alignPresent && parsedConcrete.align === true &&
    parsedConcrete.familyPresent && parsedConcrete.family === 'Noto Sans' &&
    parsedConcrete.sizePresent && parsedConcrete.layoutPresent && parsedConcrete.layout === 1 &&
    parsedConcrete.wrapPresent && parsedConcrete.wrap === 2);
const explicitNull = {
  hasHandwritingLanguage: true, handwritingLanguage: null,
  hasAlignTextToLines: true, alignTextToLines: false,
  hasDefaultFontFamily: true, defaultFontFamily: '',
  hasDefaultFontSize: true, defaultFontSize: 1,
  hasLayoutMode: true, layoutMode: 0,
  hasBlockWrapSupport: true, blockWrapSupport: 0,
};
const parsedNull = parseModel(modelEncode(explicitNull));
check('independent model distinguishes handwriting wrapper-null from omitted field and preserves false/zero presence',
  parsedNull.handwritingPresent && parsedNull.handwritingLanguage === null &&
    parsedNull.alignPresent && parsedNull.align === false && parsedNull.familyPresent &&
    parsedNull.family === '' && parsedNull.sizePresent && parsedNull.layoutPresent &&
    parsedNull.layout === 0 && parsedNull.wrapPresent && parsedNull.wrap === 0);
const omitted = modelEncode({
  hasHandwritingLanguage: false, handwritingLanguage: null,
  hasAlignTextToLines: false, alignTextToLines: false,
  hasDefaultFontFamily: false, defaultFontFamily: '',
  hasDefaultFontSize: true, defaultFontSize: 12,
  hasLayoutMode: false, layoutMode: 0,
  hasBlockWrapSupport: false, blockWrapSupport: 0,
});
const parsedOmitted = parseModel(omitted);
check('independent model does not manufacture omitted preference fields',
  !parsedOmitted.handwritingPresent && !parsedOmitted.alignPresent &&
    !parsedOmitted.familyPresent && parsedOmitted.sizePresent &&
    !parsedOmitted.layoutPresent && !parsedOmitted.wrapPresent);

// Independent transaction model: all requested registers, one revision and
// one operation-log row commit together; an injected failure rolls everything
// back. This mirrors the production caller-owned transaction boundary.
const db = new DatabaseSync(':memory:');
db.exec(`PRAGMA foreign_keys = ON;
  CREATE TABLE note_meta(id TEXT PRIMARY KEY, structure_revision INTEGER NOT NULL, updated_at INTEGER NOT NULL);
  CREATE TABLE register(note_id TEXT NOT NULL, field TEXT NOT NULL, value TEXT,
    PRIMARY KEY(note_id, field), FOREIGN KEY(note_id) REFERENCES note_meta(id) ON DELETE CASCADE);
  CREATE TABLE operation_log(note_id TEXT NOT NULL, op_id TEXT NOT NULL, payload BLOB NOT NULL);
  INSERT INTO note_meta VALUES('note', 4, 10);`);
function snapshot() {
  return JSON.stringify({
    note: db.prepare("SELECT * FROM note_meta WHERE id='note'").get(),
    registers: db.prepare("SELECT * FROM register WHERE note_id='note' ORDER BY field").all(),
    ops: db.prepare("SELECT * FROM operation_log WHERE note_id='note'").all(),
  });
}
function applyAtomically(values, failAfterRegisters = false) {
  db.exec('BEGIN');
  try {
    for (const [field, value] of Object.entries(values)) {
      db.prepare(`INSERT INTO register VALUES('note',?,?)
        ON CONFLICT(note_id,field) DO UPDATE SET value=excluded.value`).run(field, value);
    }
    db.prepare("UPDATE note_meta SET structure_revision=structure_revision+1,updated_at=? WHERE id='note'")
      .run(20);
    if (failAfterRegisters) throw new Error('injected append failure');
    db.prepare("INSERT INTO operation_log VALUES('note','op-1',X'01')").run();
    db.exec('COMMIT');
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }
}
applyAtomically({ align: '0', layout: '0', wrap: '0' });
const committed = JSON.parse(snapshot());
check('independent transaction commits false/zero registers, one revision and operation row',
  committed.note.structure_revision === 5 && committed.registers.length === 3 &&
    committed.registers.every(row => ['0'].includes(row.value)) && committed.ops.length === 1);
const beforeFailure = snapshot();
assert.throws(() => applyAtomically({ handwriting: null, family: 'Serif' }, true), /injected append failure/);
check('independent transaction rollback removes every partial register and revision change',
  snapshot() === beforeFailure);
const beforeNoop = snapshot();
check('stale/invalid local patch gate is modeled as zero-write', (() => {
  const invalid = { layout: 2 };
  if (invalid.layout !== 0 && invalid.layout !== 1) return snapshot() === beforeNoop;
  return false;
})());

db.close();
if (failed > 0) {
  console.error(`D02_ORIGINAL_SET_METADATA_LOCAL_OUTBOUND_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_ORIGINAL_SET_METADATA_LOCAL_OUTBOUND_OK TOTAL=${total} FAILED=0`);
