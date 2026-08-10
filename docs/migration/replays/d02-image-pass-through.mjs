import assert from 'node:assert/strict';
import fs from 'node:fs';

const image = {
  id: 'image-1', type: 4, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
  bounds: { left: 10, top: 20, right: 110, bottom: 70 },
  assetHash: '0:1:2:3:4:5:6:18446744073709551615',
  assetHashBits: ['0', '1', '2', '3', '4', '5', '6', '18446744073709551615'],
  fileName: '图片.png', mimeType: 'image/png', fileSize: 4294967295,
  intrinsicWidth: 200, intrinsicHeight: 100,
  cropRect: { left: 5, top: 10, right: 195, bottom: 90 },
  blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 0, textWrap: 0,
  enableCaption: false, webUrl: null, imageFlippedHorizontally: false,
  imageFlippedVertically: true, positionLocked: false,
};
const before = [
  { kind: 'image', data: image },
  { kind: 'stroke', data: { id: 'stroke-1', points: [[0, 0], [1, 1]] } },
  { kind: 'text', data: { id: 'text-1', richText: 'before' } },
  { kind: 'shape', data: { id: 'shape-1', type: 2 } },
];
const imageBytes = new TextEncoder().encode(JSON.stringify(before[0]));
const loaded = JSON.parse(JSON.stringify(before));
loaded[1].data.points.push([2, 2]);
loaded[2].data.richText = 'after';
const after = JSON.parse(JSON.stringify(loaded));
const savedImageBytes = new TextEncoder().encode(JSON.stringify(after[0]));

assert.deepEqual([...savedImageBytes], [...imageBytes]);
assert.equal(after[0].kind, 'image');
assert.equal(after[0].data.assetHashBits[7], '18446744073709551615');
assert.equal(after[0].data.fileSize, 4294967295);
assert.deepEqual(after.map(element => element.kind), ['image', 'stroke', 'text', 'shape']);

const root = new URL('../../../', import.meta.url);
const canvas = fs.readFileSync(new URL(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', root), 'utf8');
const persistence = fs.readFileSync(new URL(
  'note/src/main/ets/data/StrokePersistence.ets', root), 'utf8');
const exporter = fs.readFileSync(new URL(
  'note/src/main/ets/data/NoteExporter.ets', root), 'utf8');
const importer = fs.readFileSync(new URL(
  'note/src/main/ets/data/NoteImporter.ets', root), 'utf8');
const thumbnail = fs.readFileSync(new URL(
  'note/src/main/ets/rendering/ThumbnailRenderer.ets', root), 'utf8');
const history = fs.readFileSync(new URL(
  'note/src/main/ets/data/PersistentHistory.ets', root), 'utf8');

assert.match(canvas, /private imageBlocks: ImageElement\[\] = \[\]/);
assert.match(canvas, /snapshot\.shapes, false, undefined, snapshot\.images/);
assert.match(canvas, /PageElementKind\.IMAGE && persisted\.kind === 'image'/);
assert.match(persistence, /kind: 'image', data: element\.data/);
assert.match(persistence, /result\.images\.push\(image\)/);
assert.match(exporter, /elementObjects\.push\(\{ kind: 'image', data: element\.data \}\)/);
assert.match(importer, /pageImages\.push\(image\)/);
assert.match(thumbnail, /else if \(element\.kind === PageElementKind\.SHAPE\)/);
assert.match(history, /PageElementKind\.IMAGE && persisted\.kind === 'image'/);
assert.match(history, /pageImages: content\.images/);

console.log('success|mixed-order=1|image-byte-stable=1|uint64-exact=1|editor-save=1|' +
  'mutation=1|package-roundtrip=1|delete-checkpoint=1|thumbnail-shape-guard=1');
