import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const checks = [
  ['cache hit requires revision and PixelMap', source.includes('oldRevision === revision && oldPixelMap !== undefined')],
  ['cache hit publishes both halves', source.includes('newRevisions.set(noteId, revision);\n            newMap.set(noteId, oldPixelMap);')],
  ['new revision is published only with a PixelMap', /if \(pixelMap !== null\) \{\s*newRevisions\.set\(noteId, revision\);\s*newMap\.set\(noteId, pixelMap\);/.test(source)],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
