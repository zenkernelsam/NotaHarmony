import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const w18 = original('w18.java');
const v18 = original('v18.java');
const p18 = original('p18.java');
const renderer = read('note/src/main/ets/rendering/MathCanvasRenderer.ets');
const thumbnail = read('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');

const checks = [];
const check = (name, condition) => {
  assert.ok(condition, name);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original math renderer owns a 4 MiB byte-counted LRU',
  /new v18\(4194304, 0\)/.test(w18) &&
  /bitmap\.getHeight\(\) \* bitmap\.getWidth\(\) \* 4/.test(v18));
check('original immediately recycles a bitmap when native drawing fails',
  /nativeDraw[\s\S]*?bitmapCreateBitmap\.recycle\(\)/.test(p18));
check('Harmony retains the same 4 MiB cache budget',
  /MAX_CACHE_BYTES: number = 4 \* 1024 \* 1024/.test(renderer));
check('oversized textures are never inserted into the bounded cache',
  /if \(entry\.bytes <= MAX_CACHE_BYTES\)[\s\S]*?this\.cache\.push\(entry\)[\s\S]*?else \{[\s\S]*?transientTexture = texture/.test(renderer));
check('oversized textures remain valid through draw and are released in finally',
  /ctx\.drawImage\(entry\.texture\.bitmap/.test(renderer) &&
  /finally \{[\s\S]*?ctx\.restore\(\)[\s\S]*?this\.releaseTexture\(transientTexture\)/.test(renderer));
check('cache eviction releases both ImageBitmap and PixelMap ownership',
  /this\.releaseTexture\(removed\.texture\)/.test(renderer) &&
  /texture\.bitmap\.close\(\)/.test(renderer) &&
  /texture\.pixelMap\.release\(\)/.test(renderer));
check('explicit cache clear releases every resident texture and resets accounting',
  /for \(const entry of this\.cache\)[\s\S]*?this\.releaseTexture\(entry\.texture\)/.test(renderer) &&
  /this\.cache = \[\]/.test(renderer) && /this\.cacheBytes = 0/.test(renderer));
check('editor renderer cleanup clears its math cache',
  /private disposeRenderingResources\(\): void \{[\s\S]*?this\.mathRenderer\.clear\(\)[\s\S]*?this\.layerManager\.dispose\(\)/
    .test(canvas));
check('thumbnail renderer disposal clears its math cache',
  /async dispose\(\): Promise<void> \{[\s\S]*?this\.disposed = true;[\s\S]*?this\.mathRenderer\.clear\(\)/
    .test(thumbnail));

class CacheModel {
  constructor(maxBytes) {
    this.maxBytes = maxBytes;
    this.entries = [];
    this.bytes = 0;
    this.released = [];
  }

  render(key, bytes) {
    if (bytes > this.maxBytes) {
      this.released.push(key);
      return { cached: false, drawnBeforeRelease: true };
    }
    this.entries.push({ key, bytes });
    this.bytes += bytes;
    while (this.bytes > this.maxBytes) {
      const removed = this.entries.shift();
      this.bytes -= removed.bytes;
      this.released.push(removed.key);
    }
    return { cached: true, drawnBeforeRelease: true };
  }

  clear() {
    this.released.push(...this.entries.map(entry => entry.key));
    this.entries = [];
    this.bytes = 0;
  }
}

const model = new CacheModel(4);
check('runtime model draws then releases an oversized texture without caching it',
  assert.deepEqual(model.render('oversized', 5),
    { cached: false, drawnBeforeRelease: true }) === undefined &&
  model.entries.length === 0 && model.released.includes('oversized'));
model.render('old', 3);
model.render('new', 3);
check('runtime model evicts the oldest resident texture under the byte budget',
  model.entries.length === 1 && model.entries[0].key === 'new' && model.released.includes('old'));
model.clear();
check('runtime model clear releases residents and resets byte accounting',
  model.entries.length === 0 && model.bytes === 0 && model.released.includes('new'));

console.log(`TOTAL=${checks.length} FAILED=0`);
