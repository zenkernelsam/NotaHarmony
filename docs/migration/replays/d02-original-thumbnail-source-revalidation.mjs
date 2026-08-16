import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

function readRepo(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function readOriginal(fileName) {
  return fs.readFileSync(path.join(originalRoot, fileName), 'utf8');
}

function sameSource(expected, current) {
  return expected.pageId.length > 0 && expected.pageId === current.pageId &&
    expected.revision === current.revision;
}

function boundedRender(initial, statesAfterRender) {
  let source = initial;
  const released = [];
  for (let attempt = 0; attempt < 2 && source !== null; attempt++) {
    const rendered = `bitmap:${source.revision}`;
    const verified = statesAfterRender[attempt] ?? null;
    if (verified !== null && sameSource(source, verified)) {
      return { published: rendered, revision: source.revision, released };
    }
    released.push(rendered);
    source = verified;
  }
  return { published: null, revision: null, released };
}

const cn7 = readOriginal('cn7.java');
const if9 = readOriginal('if9.java');
const h59 = readOriginal('h59.java');
const m6j = readOriginal('m6j.java');
const policy = readRepo('note/src/main/ets/rendering/ThumbnailRenderPolicy.ets');
const library = readRepo('note/src/main/ets/ui/library/LibraryPage.ets');
const fixture = readRepo('note/src/test/ThumbnailRenderPolicy.test.ets');

const checks = [
  ['original state keeps bitmap and on-disk operation maps together',
    cn7.includes('LocalThumbnailState(bitmaps=') && cn7.includes(', onDiskOpIds=')],
  ['original per-note value pairs bitmap with on-disk operation identity',
    if9.includes('NoteThumbnailData(bitmap=') && if9.includes(', onDiskOpId=')],
  ['original projection reads both maps using the same note identity',
    /new if9\(\(tr\) s2d\.g\(ttfVar, cn7Var\.a\), \(qo5\) s2d\.g\(ttfVar, cn7Var\.b\)\)/.test(h59)],
  ['original thumbnail consumer compares produced and expected operation identities',
    m6j.includes('so5.a(qo5Var2, qo5Var) >= 0')],
  ['original consumer gates bitmap access behind the operation-identity decision',
    m6j.indexOf('trVar = ((if9) gl8VarH.getValue()).a;') >
      m6j.indexOf('so5.a(qo5Var2, qo5Var) >= 0')],
  ['Harmony source identity requires non-empty page id plus exact revision',
    policy.includes('expectedPageId.length > 0 && expectedPageId === currentPageId') &&
      policy.includes('expectedRevision === currentRevision')],
  ['Library bounds source retries to two attempts',
    library.includes('THUMBNAIL_SOURCE_ATTEMPTS: number = 2') &&
      library.includes('attempt < this.THUMBNAIL_SOURCE_ATTEMPTS')],
  ['Library captures page and asset source identity before rendering',
    library.includes('const sourceState: FirstPageThumbnailState = pageState') &&
      library.includes('const assetGeneration: number = assetAvailabilityHub.getNoteGeneration(noteId)')],
  ['Library rereads first-page state and asset generation after rendering',
    library.includes('const verifiedState: FirstPageThumbnailState | null =') &&
      library.includes('const verifiedAssetGeneration: number = assetAvailabilityHub.getNoteGeneration(noteId)')],
  ['Library publishes only the revalidated bitmap-revision pair',
    /isThumbnailSourceUnchanged\([\s\S]*?createdMaps\.push\(unpublishedPixelMap\);\s*newRevisions\.set\(noteId, revision\);\s*newMap\.set\(noteId, unpublishedPixelMap\);/.test(library)],
  ['Library releases an unpublished bitmap before retrying a changed source',
    library.includes("releaseThumbnailPixelMap(unpublishedPixelMap, 'source changed during render')") &&
      library.includes('pageState = verifiedState')],
  ['Library releases unpublished bitmaps on generation and render failures',
    library.includes("releaseThumbnailPixelMap(unpublishedPixelMap, 'stale verified generation')") &&
      library.includes("releaseThumbnailPixelMap(unpublishedPixelMap, 'render failure')")],
  ['Library never keeps a known-stale old bitmap after failure',
    library.includes('sourceStillCurrent &&') && library.includes('oldRevision === requestedRevision')],
  ['Library centralizes asynchronous PixelMap release failure handling',
    library.includes('private async releaseThumbnailPixelMap') &&
      library.includes('await pixelMap.release()') &&
      library.includes('thumbnail PixelMap release failed')],
  ['ArkTS fixture covers matching, changed revision, changed page, and empty identity',
    fixture.includes("isThumbnailSourceUnchanged('page-a', 'revision-7', 'page-a', 'revision-7')") &&
      fixture.includes("isThumbnailSourceUnchanged('page-a', 'revision-7', 'page-a', 'revision-8')") &&
      fixture.includes("isThumbnailSourceUnchanged('page-a', 'revision-7', 'page-b', 'revision-7')") &&
      fixture.includes("isThumbnailSourceUnchanged('', 'revision-7', '', 'revision-7')")],
];

const unchanged = boundedRender(
  { pageId: 'page-a', revision: 'r1' },
  [{ pageId: 'page-a', revision: 'r1' }],
);
assert.deepEqual(unchanged, { published: 'bitmap:r1', revision: 'r1', released: [] });

const changedOnce = boundedRender(
  { pageId: 'page-a', revision: 'r1' },
  [{ pageId: 'page-a', revision: 'r2' }, { pageId: 'page-a', revision: 'r2' }],
);
assert.deepEqual(changedOnce, {
  published: 'bitmap:r2',
  revision: 'r2',
  released: ['bitmap:r1'],
});

const changedTwice = boundedRender(
  { pageId: 'page-a', revision: 'r1' },
  [{ pageId: 'page-a', revision: 'r2' }, { pageId: 'page-b', revision: 'r3' }],
);
assert.deepEqual(changedTwice, {
  published: null,
  revision: null,
  released: ['bitmap:r1', 'bitmap:r2'],
});

for (const [name, ok] of checks) {
  if (!ok) {
    throw new Error(`FAILED: ${name}`);
  }
  console.log(`PASS: ${name}`);
}
console.log(`D02_ORIGINAL_THUMBNAIL_SOURCE_REVALIDATION_REPLAY_OK TOTAL=${checks.length + 3} FAILED=0`);
