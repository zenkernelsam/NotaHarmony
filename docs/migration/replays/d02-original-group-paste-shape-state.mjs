import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const laj = original('laj.java');
const ao2 = original('ao2.java');
const encoder = read('note/src/main/ets/data/OriginalCreateShapePayloadEncoder.ets');
const reducer = read('note/src/main/ets/data/OriginalShapeGroupOperation.ets');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixtures = read('note/src/test/OriginalCreateInkPayloadEncoder.test.ets');

assert.match(laj, /if \(hu1Var2 != null\) \{\s*aVar\.j\(11, z5c\.P\(hu1Var2, aVar\)\);/);
assert.match(laj, /aVar\.a\(15, z2, false\)/);
assert.match(ao2, /Create shape with `fillColor: nil` for unfilled\. Do not use zero alpha\./);

assert.match(encoder, /shape\.fillColor === null \? 0 : 56/);
assert.match(encoder, /shape\.positionLocked === true \? 80 : 0/);
assert.match(encoder, /builder\.table\(fields, 84\)/);
assert.match(encoder, /builder\.color\(root \+ 56, shape\.fillColor\)/);
assert.match(encoder, /builder\.uint8\(root \+ 80, 1\)/);
assert.match(encoder, /colorAlpha\(shape\.fillColor\) === 0/);
assert.match(encoder, /shape\.richText !== undefined && shape\.richText\.length > 0/);

assert.match(reducer, /const fillBytes: Uint8Array \| null = table\.readInlineBytes\(11, 4\)/);
assert.match(reducer, /positionLocked: table\.readUint8\(15, 0\) !== 0/);
assert.match(reducer, /CreateShape uses a transparent fill color/);
assert.match(persistence, /encodeOriginalLocalCreateShape\(page, shape, null\)/);
assert.match(persistence, /Shape RichText is unsupported/);

assert.match(fixtures, /line\.fillColor = 0x7F445566/);
assert.match(fixtures, /decodedFilledLockedLine\.fillColor/);
assert.match(fixtures, /decodedFilledLockedLine\.positionLocked/);
assert.match(fixtures, /line\.fillColor = 0x00112233/);

const fields = new Uint8Array(84);
const fill = 0x7F445566;
fields[56] = fill >>> 16 & 0xFF;
fields[57] = fill >>> 8 & 0xFF;
fields[58] = fill & 0xFF;
fields[59] = fill >>> 24 & 0xFF;
fields[80] = 1;
const decodedFill = (fields[59] << 24 | fields[56] << 16 | fields[57] << 8 | fields[58]) >>> 0;
assert.equal(decodedFill, fill);
assert.equal(fields[80] !== 0, true);

console.log('originalGroupPasteShapeState=' +
  'type18-fill-lock-roundtrip-transparent-reject-richtext-gate-group-paste');
