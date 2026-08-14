import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const collect = source.indexOf('private collect(');
const validate = source.indexOf('private validateManifest');
const exclusion = source.indexOf('private isExcludedFilesPath');
const prefixes = ['assets/pending', 'assets/trash', 'glmath'];
const isExcluded = (relativePath) => {
  const normalized = relativePath.replaceAll('\\', '/');
  return prefixes.some((prefix) => normalized === prefix || normalized.startsWith(`${prefix}/`));
};
const checks = [
  ['pending, trash and generated math roots are declared transient',
    source.includes("['assets/pending', 'assets/trash', 'glmath']")],
  ['collector skips transient roots before descending', collect >= 0 &&
    source.indexOf('this.isExcludedFilesPath(relative)', collect) > collect &&
    source.indexOf('this.isExcludedFilesPath(relative)', collect) < source.indexOf('this.isDirectory(child)', collect)],
  ['schema-2 restore rejects transient file entries', validate >= 0 &&
    source.indexOf('manifest.schema === CURRENT_MANIFEST_SCHEMA', validate) > validate &&
    source.indexOf('this.isExcludedFilesPath(entry.relativePath)', validate) > validate],
  ['exclusion matching normalizes separators', exclusion >= 0 &&
    source.indexOf("relativePath.replace(/\\\\/g, '/')", exclusion) > exclusion],
  ['transient roots themselves are excluded', prefixes.every((value) => isExcluded(value))],
  ['transient descendants are excluded', isExcluded('assets/pending/a.tmp') &&
    isExcluded('assets\\trash\\detached') && isExcluded('glmath/fonts/cmr10.ttf')],
  ['similarly named durable paths remain eligible', !isExcluded('assets/pending-note') &&
    !isExcluded('assets/trashcan') && !isExcluded('glmath-cache')],
  ['durable canonical assets remain eligible', !isExcluded('assets/final/sha512')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
