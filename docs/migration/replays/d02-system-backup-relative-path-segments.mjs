import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const helper = source.indexOf('private assertRelative(path: string)');
const split = source.indexOf("path.replace(/\\\\/g, '/').split('/')", helper);
const segmentGuard = source.indexOf("segment === '..'", split);
const oldSubstringGuard = source.indexOf("path.indexOf('..')", helper);
const checks = [
  ['path validator exists', helper >= 0],
  ['mixed separators normalize into segments', split > helper],
  ['parent segment is rejected exactly', segmentGuard > split],
  ['substring-wide dot rejection is removed', oldSubstringGuard < 0],
  ['absolute and drive paths remain rejected', source.indexOf("path.startsWith('/')", helper) > helper &&
    source.indexOf("path.indexOf(':')", helper) > helper],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
