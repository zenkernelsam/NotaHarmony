import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const exporter = fs.readFileSync(
  path.join(root, 'note/src/main/ets/data/NoteExporter.ets'), 'utf8');
const originalImport = fs.readFileSync(path.join(originalRoot, 'jv5.java'), 'utf8');
const originalCopy = fs.readFileSync(path.join(originalRoot, 'fag.java'), 'utf8');

const exportToFile = exporter.slice(exporter.indexOf('async exportToFile('),
  exporter.indexOf('async exportAllNotes('));
const writeHelper = exporter.slice(exporter.indexOf('function writeFileFully('),
  exporter.indexOf('function readFileFully('));

const checks = [
  ['original private-file copy uses a buffered output stream',
    originalImport.includes('new BufferedOutputStream(new FileOutputStream(file), 8192)')],
  ['original copy helper loops over 8 KiB reads and writes each complete read',
    originalCopy.includes('byte[] bArr = new byte[8192]') &&
      originalCopy.includes('while (true)') &&
      originalCopy.includes('outputStream.write(bArr, 0, i)')],
  ['both Harmony export destinations use complete-write handling',
    exportToFile.includes("writeFileFully(tmpFile.fd, data, 'temporary export')") &&
      exportToFile.includes("writeFileFully(dstFile.fd, bytes, 'destination export')")],
  ['export path no longer ignores raw writeSync results',
    !exportToFile.includes('fileIo.writeSync(')],
  ['complete-write helper loops until the full byte view is consumed',
    writeHelper.includes('while (total < bytes.byteLength)') &&
      writeHelper.includes('total += written')],
  ['writes are bounded to exact fixed-size views',
    exporter.includes('const FILE_WRITE_CHUNK_SIZE: number = 64 * 1024') &&
      writeHelper.includes('bytes.subarray(total, end)') &&
      writeHelper.includes('exactArrayBuffer(chunk)')],
  ['zero, negative, or oversized progress is rejected',
    writeHelper.includes('written <= 0 || written > chunk.byteLength')],
  ['temporary and destination files remain synced only after complete writing',
    exportToFile.indexOf("writeFileFully(tmpFile.fd, data, 'temporary export')") <
      exportToFile.indexOf('fileIo.fsyncSync(tmpFile.fd)') &&
      exportToFile.indexOf("writeFileFully(dstFile.fd, bytes, 'destination export')") <
        exportToFile.indexOf('fileIo.fsyncSync(dstFile.fd)')],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

function writeFullyModel(bytes, writePlan, chunkSize = 4) {
  const output = [];
  let total = 0;
  let call = 0;
  while (total < bytes.length) {
    const end = Math.min(bytes.length, total + chunkSize);
    const chunk = bytes.subarray(total, end);
    const requested = writePlan[Math.min(call, writePlan.length - 1)];
    const written = Math.min(requested, chunk.length);
    if (written <= 0 || written > chunk.length) {
      throw new Error(`invalid progress at ${total}/${bytes.length}`);
    }
    output.push(...chunk.subarray(0, written));
    total += written;
    call++;
  }
  return Uint8Array.from(output);
}

const expected = Uint8Array.from([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
assert.deepEqual(writeFullyModel(expected, [2, 1, 3, 1, 4]), expected,
  'FAILED: short-write model did not preserve every byte in order');
console.log('PASS: runtime model retries short writes without truncation or duplication');
assert.throws(() => writeFullyModel(expected, [0]), /invalid progress/,
  'FAILED: zero-progress write was not rejected');
console.log('PASS: runtime model rejects zero-progress writes');

console.log(`TOTAL=${checks.length + 2} FAILED=0`);
