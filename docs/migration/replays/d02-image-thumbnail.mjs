import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const thumbnail = fs.readFileSync(new URL(
  'note/src/main/ets/rendering/ThumbnailRenderer.ets', root), 'utf8');
const imageRenderer = fs.readFileSync(new URL(
  'note/src/main/ets/rendering/ImageCanvasRenderer.ets', root), 'utf8');
const library = fs.readFileSync(new URL(
  'note/src/main/ets/ui/library/LibraryPage.ets', root), 'utf8');

assert.match(thumbnail, /ImageAssetLoader/);
assert.match(thumbnail, /originalAssetStorageHash\(block\.assetHashBits\)/);
assert.match(thumbnail, /if \(!imageAssets\.has\(storageHash\)\)/);
assert.match(thumbnail, /element\.kind === PageElementKind\.IMAGE/);
assert.match(thumbnail, /asset\.state === ImageAssetLoadState\.READY/);
assert.match(thumbnail, /this\.imageRenderer\.renderImage\(element\.data, asset\.bitmap, renderContext\)/);
assert.match(thumbnail, /finally \{/);
assert.match(thumbnail, /imageLoader\.release\(asset\)/);
assert.match(library,
  /renderer\.renderThumbnail\(\s*noteId, this\.persistence, sourceState\.page, theme, this\.db\)/);

assert.match(imageRenderer, /imageRenderGeometry/);
assert.ok(imageRenderer.indexOf('ctx.clip()') <
  imageRenderer.indexOf('ctx.translate(geometry.flipTranslateX'));

console.log('d02-image-thumbnail: PASS');
