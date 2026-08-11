import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const cie = original('cie.java');
const n5d = original('n5d.java');
const rbb = original('rbb.java');
const persistence = read('note/src/main/ets/data/StrokePersistence.ets');
const fixtures = read('note/src/test/StrokePersistence.test.ets');

const shapeCopyStart = n5d.indexOf('public final qo5 u(a aVar)');
assert.notEqual(shapeCopyStart, -1);
const shapeCopy = n5d.slice(shapeCopyStart);
assert.match(shapeCopy, /return a\.b\(aVar, laj\.a\(/);
assert.doesNotMatch(shapeCopy, /this\.s/);
assert.doesNotMatch(shapeCopy, /m4cVar\.u\(aVar\)/);
assert.match(cie, /m4c m4cVar = this\.c;[\s\S]*?m4cVar\.u\(aVar\)/);
assert.match(rbb, /m4c m4cVar = new m4c\(null\)/);

assert.match(persistence,
  /export function originalClipboardShapeForPaste\([\s\S]*?shape\.richText = '';[\s\S]*?shape\.characterStyleRuns = \[\];[\s\S]*?shape\.paragraphStyleRuns = \[\];/);
assert.match(persistence,
  /encodeOriginalLocalCreateShape\(page, originalClipboardShapeForPaste\(shape\), null\)/);
assert.match(persistence, /const shape: ShapeElement = originalClipboardShapeForPaste\(source\)/);
assert.doesNotMatch(persistence, /Shape RichText is unsupported/);
assert.match(fixtures,
  /resets Shape RichText during original clipboard Paste without mutating source/);

const source = {
  richText: 'AB',
  characterStyleRuns: [{ start: 0, end: 2, style: { bold: true } }],
  paragraphStyleRuns: [{ start: 0, end: 2, style: { alignment: 2 } }],
};
const copy = structuredClone(source);
copy.richText = '';
copy.characterStyleRuns = [];
copy.paragraphStyleRuns = [];
assert.deepEqual(copy, { richText: '', characterStyleRuns: [], paragraphStyleRuns: [] });
assert.equal(source.richText, 'AB');
assert.equal(source.characterStyleRuns.length, 1);

console.log('originalGroupPasteShapeRichText=' +
  'n5d-create-only-rbb-empty-no-type7-14-source-immutable-copy-reset');
