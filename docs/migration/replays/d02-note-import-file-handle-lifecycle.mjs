import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/NoteImporter.ets'), 'utf8');
const checks = [
  ['import file has nullable ownership', source.includes('let file: fileIo.File | null = null;')],
  ['opened file is assigned to owned handle', source.includes('file = fileIo.openSync(uri')],
  ['successful close clears ownership', source.includes('fileIo.closeSync(file);\n      file = null;')],
  ['finally closes failure handle', source.includes('if (file !== null)') && source.includes('fileIo.closeSync(file); } catch (_)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
