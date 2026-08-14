import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteExporter.ets'), 'utf8');
const checks = [
  ['temporary export uses the complete-write helper',
    source.includes("writeFileFully(tmpFile.fd, data, 'temporary export')")],
  ['picker destination uses the complete-write helper',
    source.includes("writeFileFully(dstFile.fd, bytes, 'destination export')")],
  ['complete-write helper passes an exact chunk view',
    source.includes('fileIo.writeSync(fd, exactArrayBuffer(chunk))')],
  ['helper uses byte offset', source.includes('bytes.byteOffset')],
  ['helper uses byte length', source.includes('bytes.byteLength')],
  ['helper returns sliced ArrayBuffer', source.includes('as ArrayBuffer')],
  ['export pipeline remains present', source.includes('async exportToFile') && source.includes('async exportNote')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
