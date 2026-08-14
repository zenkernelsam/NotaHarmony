import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const originalCopy = fs.readFileSync(path.join(originalRoot, 'fag.java'), 'utf8');

const createSnapshot = source.slice(source.indexOf('private async createSnapshotLocked('),
  source.indexOf('private async restoreSnapshot('));
const writeText = source.slice(source.indexOf('private writeText('),
  source.indexOf('private errorMessage('));

const manifestWrite = createSnapshot.indexOf('this.writeText(this.join(staging, MANIFEST)');
const publishing = createSnapshot.indexOf("this.state.phase = 'publishing'");
const publishRename = createSnapshot.indexOf('fileIo.renameSync(staging, snapshot)');
const outerCatch = createSnapshot.lastIndexOf('} catch (e) {');
const failedCleanup = createSnapshot.indexOf('this.removeTreeInside(backupDir, STAGING)', outerCatch);

const checks = [
  ['original file copy loops over bounded reads before writing',
    originalCopy.includes('byte[] bArr = new byte[8192]') &&
      originalCopy.includes('while (true)') &&
      originalCopy.includes('outputStream.write(bArr, 0, i)')],
  ['backup manifest writer loops until all encoded bytes are consumed',
    writeText.includes('while (total < bytes.byteLength)') &&
      writeText.includes('total += written')],
  ['manifest writes are bounded and preserve the exact TypedArray view',
    writeText.includes('Math.min(COPY_BUFFER_SIZE, bytes.byteLength - total)') &&
      writeText.includes('bytes.byteOffset + total') &&
      writeText.includes('writeSync(file.fd, exact)')],
  ['zero, negative, and oversized progress are rejected',
    writeText.includes('written <= 0 || written > requested')],
  ['manifest file is synced and length-verified before success',
    writeText.indexOf('fileIo.fsyncSync(file.fd)') > writeText.indexOf('while (total < bytes.byteLength)') &&
      writeText.includes('fileIo.statSync(path).size !== bytes.byteLength')],
  ['manifest completion precedes every snapshot publication step',
    manifestWrite >= 0 && manifestWrite < publishing && publishing < publishRename],
  ['manifest write failure remains inside staging cleanup boundary',
    outerCatch > publishRename && failedCleanup > outerCatch &&
      createSnapshot.indexOf("this.state.phase = 'failed'", outerCatch) > failedCleanup],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

function writeFullyModel(bytes, writePlan, chunkSize = 5) {
  const output = [];
  let total = 0;
  let call = 0;
  while (total < bytes.length) {
    const requested = Math.min(chunkSize, bytes.length - total);
    const written = Math.min(writePlan[Math.min(call, writePlan.length - 1)], requested);
    if (written <= 0 || written > requested) {
      throw new Error(`invalid progress at ${total}/${bytes.length}`);
    }
    output.push(...bytes.subarray(total, total + written));
    total += written;
    call++;
  }
  return Uint8Array.from(output);
}

const manifest = new TextEncoder().encode('{"schema":2,"entries":[{"size":7}]}');
assert.deepEqual(writeFullyModel(manifest, [3, 1, 2, 4]), manifest,
  'FAILED: short manifest writes did not preserve the complete JSON byte sequence');
console.log('PASS: runtime model retries short manifest writes without truncation');
assert.throws(() => writeFullyModel(manifest, [0]), /invalid progress/,
  'FAILED: zero-progress manifest write was not rejected');
console.log('PASS: runtime model rejects zero-progress manifest writes');

console.log(`TOTAL=${checks.length + 2} FAILED=0`);
