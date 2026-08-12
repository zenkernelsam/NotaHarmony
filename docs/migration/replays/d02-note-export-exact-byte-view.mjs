import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteExporter.ets'), 'utf8');
const checks = [
  ['temporary export uses exact byte view', source.includes('writeSync(tmpFile.fd, exactArrayBuffer(data))')],
  ['picker destination uses exact byte view', source.includes('writeSync(dstFile.fd, exactArrayBuffer(bytes))')],
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

