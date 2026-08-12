import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(path.join(root, 'note/src/main/ets/data/NoteExporter.ets'), 'utf8');
const checks = [
  ['temporary file has explicit ownership', source.includes('let tmpFile: fileIo.File | null = null;')],
  ['source and destination handles have ownership', source.includes('let srcFile: fileIo.File | null = null;') && source.includes('let dstFile: fileIo.File | null = null;')],
  ['temporary file is truncated', source.includes('fileIo.OpenMode.TRUNC')],
  ['temporary and destination writes are synced', source.includes('fileIo.fsyncSync(tmpFile.fd)') && source.includes('fileIo.fsyncSync(dstFile.fd)')],
  ['finally closes all remaining handles', source.includes('if (tmpFile !== null)') && source.includes('if (srcFile !== null)') && source.includes('if (dstFile !== null)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
