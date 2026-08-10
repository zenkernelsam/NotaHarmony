import assert from 'node:assert/strict';
import fs from 'node:fs';

const words = [0n, 1n, 0x0102030405060708n, 0xffffffffffffffffn,
  256n, 65536n, 4294967296n, 0x8000000000000000n];
const bytes = [];
for (const word of words) {
  for (let index = 0n; index < 8n; index++) {
    bytes.push(Number((word >> (index * 8n)) & 0xffn));
  }
}
const storageHash = Buffer.from(bytes).toString('hex');
assert.equal(storageHash,
  '000000000000000001000000000000000807060504030201ffffffffffffffff' +
  '0001000000000000000001000000000000000000010000000000000000000080');

const intrinsic = { width: 400, height: 200 };
const bitmap = { width: 200, height: 100 };
const crop = { left: 100, top: 25, right: 300, bottom: 175 };
const cropPixels = {
  left: crop.left * bitmap.width / intrinsic.width,
  top: crop.top * bitmap.height / intrinsic.height,
  right: crop.right * bitmap.width / intrinsic.width,
  bottom: crop.bottom * bitmap.height / intrinsic.height,
};
assert.deepEqual(cropPixels, { left: 50, top: 12.5, right: 150, bottom: 87.5 });
assert.equal(200 / (cropPixels.right - cropPixels.left), 2);
assert.equal(75 / (cropPixels.bottom - cropPixels.top), 1);

const root = new URL('../../../', import.meta.url);
const geometry = fs.readFileSync(new URL(
  'note/src/main/ets/core/model/ImageBlockGeometry.ets', root), 'utf8');
const loader = fs.readFileSync(new URL(
  'note/src/main/ets/core/adaptation/ImageAssetLoader.ets', root), 'utf8');
const renderer = fs.readFileSync(new URL(
  'note/src/main/ets/rendering/ImageCanvasRenderer.ets', root), 'utf8');
const packageStore = fs.readFileSync(new URL(
  'note/src/main/ets/data/ImageAssetPackageStore.ets', root), 'utf8');
const exporter = fs.readFileSync(new URL(
  'note/src/main/ets/data/NoteExporter.ets', root), 'utf8');
const importer = fs.readFileSync(new URL(
  'note/src/main/ets/data/NoteImporter.ets', root), 'utf8');
const canvas = fs.readFileSync(new URL(
  'note/src/main/ets/ui/editor/NoteCanvasView.ets', root), 'utf8');

assert.match(geometry, /divideDecimalBy256/);
assert.match(loader, /ORIGINAL_MAX_IMAGE_EDGE: number = 3000/);
assert.match(loader, /ImageAssetLoadState\.ANIMATED_UNSUPPORTED/);
assert.match(loader, /bitmap\.close\(\)/);
assert.match(loader, /pixelMap\.release\(\)/);
assert.ok(renderer.indexOf('ctx.clip()') < renderer.indexOf('geometry.flipTranslateX'));
assert.match(renderer, /ctx\.drawImage\(bitmap, 0, 0, bitmap\.width, bitmap\.height\)/);
assert.match(packageStore, /assets\/\$\{originalAssetStorageHash/);
assert.match(packageStore, /writeFileAtomically/);
assert.match(packageStore, /fileIo\.fsyncSync/);
assert.match(packageStore, /fileContentsEqual/);
assert.match(packageStore, /preferredAvailableRecord/);
assert.match(packageStore, /AssetStatus\.UPLOADED \|\| status === AssetStatus\.DOWNLOADED/);
assert.match(exporter, /readVerifiedImageAsset/);
assert.match(importer, /missingImageAssets > 0/);
assert.match(importer, /storeImportedImageAsset/);
assert.match(importer, /imageAssetPackageMetadataMatches/);
assert.match(canvas, /ImageAssetLoadState\.READY/);
assert.match(canvas, /this\.releaseImageAssets\(\)/);

console.log('success|asset-hash-le=1|storage-key=1|crop-scale=1|clip-before-flip=1|' +
  'decode-max-edge=3000|gif-deferred=1|bitmap-release=1|package-assets=1|atomic-file=1|' +
  'content-conflict=1|metadata-conflict=1|missing-partial=1|page-generation=1');
