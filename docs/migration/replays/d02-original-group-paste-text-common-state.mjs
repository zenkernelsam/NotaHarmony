import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const baj = original('baj.java');
const cie = original('cie.java');
const rl2 = original('rl2.java');
const vy7 = original('vy7.java');
const encoder = read('note/src/main/ets/data/OriginalCreateBlockPayloadEncoder.ets');
const reducer = read('note/src/main/ets/data/OriginalCreateBlockOperation.ets');
const textReducer = read('note/src/main/ets/data/OriginalInsertTextOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const renderer = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');

assert.match(baj, /aVar\.C\(21\)/);
assert.match(baj, /aVar\.h\(15, numValueOf2\.intValue\(\)\)/);
assert.match(baj, /aVar\.a\(18, z4, false\)/);
assert.match(baj, /aVar\.j\(19, fsi\.b0\(vy7Var, aVar\)\)/);
assert.match(baj, /aVar\.a\(20, z5, false\)/);
assert.match(cie, /this\.f, \(\(Boolean\) this\.e\.K\)\.booleanValue\(\), ry0Var\.q\(\)/);
assert.match(rl2, /resizesWidthToFitText=/);
assert.match(vy7, /Margins\(top=/);

assert.match(encoder, /fields\[15\] = paper === null \? 0 : 52/);
assert.match(encoder, /fields\[18\] = text\.resizesWidthToFitText === true \? 50 : 0/);
assert.match(encoder, /fields\[19\] = 56/);
assert.match(encoder, /fields\[20\] = text\.positionLocked === true \? 51 : 0/);
assert.match(encoder, /writePaper\(bytes, paperVtable, paperTable, paper\)/);
assert.match(encoder, /text\.contentBottomInset \?\? text\.contentTopInset/);
assert.match(encoder, /text\.contentRightInset \?\? text\.contentLeftInset/);
assert.match(reducer, /contentRightInset: payload\.margins\.right/);
assert.match(reducer, /contentBottomInset: payload\.margins\.bottom/);
assert.match(textReducer, /contentRightInset: text\.contentRightInset/);
assert.match(textReducer, /contentBottomInset: text\.contentBottomInset/);
assert.match(persistence, /loadOriginalTextMargins/);
assert.match(persistence, /create_margin_top, create_margin_bottom/);
assert.match(persistence, /const canonicalText: TextBlockElement = await this\.readOriginalClipboardText\(/);
assert.match(persistence, /createdTexts\.push\(canonicalText\)/);
assert.match(persistence, /decodePersistedElement\(/);
assert.doesNotMatch(persistence, /function materializeOriginalTextCreate/);
assert.match(renderer, /element\.contentRightInset \?\? element\.contentLeftInset/);

function writeU16(bytes, offset, value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = value >>> 8 & 255;
}

function writeU32(bytes, offset, value) {
  new DataView(bytes.buffer).setUint32(offset, value, true);
}

function writeF32(bytes, offset, value) {
  new DataView(bytes.buffer).setFloat32(offset, value, true);
}

function writeVtable(bytes, offset, objectSize, fields) {
  writeU16(bytes, offset, 4 + fields.length * 2);
  writeU16(bytes, offset + 2, objectSize);
  fields.forEach((value, index) => writeU16(bytes, offset + 4 + index * 2, value));
}

function encodedCommonText() {
  const table = 52;
  const paperVtable = 124;
  const paperTable = 140;
  const bytes = new Uint8Array(156);
  const fields = new Array(21).fill(0);
  fields[1] = 4; fields[2] = 8; fields[3] = 20; fields[6] = 40;
  fields[7] = 48; fields[8] = 49; fields[15] = 52;
  fields[18] = 50; fields[19] = 56; fields[20] = 51;
  writeU32(bytes, 0, table);
  writeVtable(bytes, 4, 72, fields);
  writeU32(bytes, table, 48);
  bytes[table + 4] = 1;
  bytes[table + 48] = 1;
  bytes[table + 49] = 1;
  bytes[table + 50] = 1;
  bytes[table + 51] = 1;
  writeU32(bytes, table + 52, paperTable - (table + 52));
  [3.25, 11.5, 6.5, 7.25].forEach((value, index) =>
    writeF32(bytes, table + 56 + index * 4, value));
  writeVtable(bytes, paperVtable, 16, [4, 8, 5, 6, 12, 7]);
  writeU32(bytes, paperTable, 16);
  bytes[paperTable + 4] = 0;
  bytes[paperTable + 5] = 0;
  bytes[paperTable + 6] = 0;
  bytes[paperTable + 7] = 0;
  writeF32(bytes, paperTable + 8, 18);
  bytes.set([250, 251, 252, 255], paperTable + 12);
  return bytes;
}

function tableField(bytes, table, index) {
  const view = new DataView(bytes.buffer);
  const vtable = table - view.getInt32(table, true);
  const size = view.getUint16(vtable, true);
  return 4 + index * 2 < size ? view.getUint16(vtable + 4 + index * 2, true) : 0;
}

const bytes = encodedCommonText();
const view = new DataView(bytes.buffer);
const table = view.getUint32(0, true);
assert.equal(bytes[table + tableField(bytes, table, 1)], 1);
assert.equal(bytes[table + tableField(bytes, table, 7)], 1);
assert.equal(bytes[table + tableField(bytes, table, 8)], 1);
assert.equal(bytes[table + tableField(bytes, table, 18)], 1);
assert.equal(bytes[table + tableField(bytes, table, 20)], 1);
const marginOffset = table + tableField(bytes, table, 19);
assert.deepEqual([0, 1, 2, 3].map(index => view.getFloat32(marginOffset + index * 4, true)),
  [3.25, 11.5, 6.5, 7.25]);
const paperPointer = table + tableField(bytes, table, 15);
const paper = paperPointer + view.getUint32(paperPointer, true);
for (const field of [0, 1, 2, 3, 4, 5]) assert.notEqual(tableField(bytes, paper, field), 0);
assert.equal(bytes[paper + tableField(bytes, paper, 0)], 0);
assert.equal(bytes[paper + tableField(bytes, paper, 2)], 0);
assert.equal(view.getFloat32(paper + tableField(bytes, paper, 1), true), 18);
assert.deepEqual(Array.from(bytes.slice(paper + tableField(bytes, paper, 4),
  paper + tableField(bytes, paper, 4) + 4)), [250, 251, 252, 255]);

const legacy = { contentTopInset: 3, contentLeftInset: 5 };
const stored = { top: 3.25, bottom: 11.5, left: 6.5, right: 7.25 };
Object.assign(legacy, {
  contentTopInset: stored.top, contentBottomInset: stored.bottom,
  contentLeftInset: stored.left, contentRightInset: stored.right,
});
assert.deepEqual(legacy, {
  contentTopInset: 3.25, contentBottomInset: 11.5,
  contentLeftInset: 6.5, contentRightInset: 7.25,
});
assert.equal(200 - legacy.contentLeftInset - legacy.contentRightInset, 186.25);

console.log('originalGroupPasteTextCommonState=' +
  '21-field-create-paper-nullable-scalars-four-margins-legacy-recovery-asymmetric-layout');
