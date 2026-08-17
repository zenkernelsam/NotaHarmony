import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const importer = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteImporter.ets'), 'utf8').replace(/\r\n?/g, '\n');
const zip = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/ZipArchive.ets'), 'utf8').replace(/\r\n?/g, '\n');
const checks = [
  ['shared archive byte budget is defined', zip.includes('ZIP_MAX_ARCHIVE_BYTES')],
  ['importer imports shared budget', importer.includes('ZIP_MAX_ARCHIVE_BYTES }')],
  ['stat size is checked before read', importer.includes('size > ZIP_MAX_ARCHIVE_BYTES') && importer.indexOf('size > ZIP_MAX_ARCHIVE_BYTES') < importer.indexOf('readFileFully(file.fd, size)')],
  ['oversized path closes file', importer.includes('fileIo.closeSync(file);\n        file = null;')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
