import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const checks = [
  ['cache hit requires revision and PixelMap', source.includes('oldRevision === revision && oldPixelMap !== undefined')],
  ['cache hit publishes both halves',
    /newRevisions\.set\(noteId, revision\);\s*newMap\.set\(noteId, oldPixelMap\);/.test(source)],
  ['new revision is published only after source revalidation',
    /isThumbnailSourceUnchanged\([\s\S]*?createdMaps\.push\(unpublishedPixelMap\);\s*newRevisions\.set\(noteId, revision\);\s*newMap\.set\(noteId, unpublishedPixelMap\);/.test(source)],
  ['unpublished PixelMap is released when its source changes',
    source.includes("releaseThumbnailPixelMap(unpublishedPixelMap, 'source changed during render')")],
  ['failed rendering retains an old pair only when that exact source is still current',
    source.includes('sourceStillCurrent &&') && source.includes('oldRevision === requestedRevision')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
