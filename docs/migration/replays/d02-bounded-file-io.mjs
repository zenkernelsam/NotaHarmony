import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = value => fs.readFileSync(originalRoot + value, 'utf8');

const importer = read('note/src/main/ets/data/NoteImporter.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const images = read('note/src/main/ets/data/ImageAssetPackageStore.ets');
const recordings = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const backup = read('note/src/main/ets/notebackupability/NoteBackupAbility.ets');
const originalImport = original('jv5.java');
const originalIo = original('fag.java');
const originalCopy = original('l96.java');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('original URI import copies through an 8 KiB buffered stream',
  originalImport.includes('new BufferedOutputStream(new FileOutputStream(file), 8192)') &&
  originalIo.includes('byte[] bArr = new byte[8192]') &&
  originalIo.includes('outputStream.write(bArr, 0, i)'));
check('original asset persistence streams through a fixed 64 KiB buffer',
  originalIo.includes('l96.i0(inputStream, digestOutputStream, 65536)') &&
  originalCopy.includes('byte[] bArr = new byte[i]') &&
  originalCopy.includes('i2 = inputStream.read(bArr)'));

const importerRead = importer.slice(importer.indexOf('function readFileFully('));
check('note import keeps its required aggregate output but bounds every read buffer',
  importer.includes('const FILE_READ_CHUNK_SIZE: number = 64 * 1024') &&
  importerRead.includes('Math.min(FILE_READ_CHUNK_SIZE, size - total)') &&
  importerRead.includes('new ArrayBuffer(requested)') &&
  !importerRead.includes('new ArrayBuffer(size - total)'));
check('note import rejects zero negative and oversized read progress',
  importerRead.includes('read <= 0 || read > requested'));

const exportCopy = exporter.slice(exporter.indexOf('function copyFileFully('));
check('note export streams the temporary file instead of allocating a second archive-sized array',
  exporter.includes("copyFileFully(srcFile.fd, dstFile.fd, size, 'destination export')") &&
  !exporter.includes('readFileFully(srcFile.fd, size)') &&
  exportCopy.includes('Math.min(FILE_READ_CHUNK_SIZE, size - total)'));
check('note export releases aggregate archive bytes before awaiting the picker',
  exporter.includes('let data: Uint8Array | null = await this.exportNote(noteId)') &&
  exporter.includes('const expectedSize: number = data.byteLength') &&
  exporter.indexOf('data = null;') < exporter.indexOf('await documentPicker.save(saveOptions)'));
check('note export forwards the exact read view into complete-write handling',
  exportCopy.includes('new Uint8Array(chunkBuffer, 0, read)') &&
  exportCopy.includes('writeFileFully(destinationFd'));

const imageRead = images.slice(images.indexOf('function readFileFully('),
  images.indexOf('function writeFileAtomically('));
const imageWrite = images.slice(images.indexOf('function writeFileAtomically('),
  images.indexOf('function fileContentsEqual('));
const imageCompare = images.slice(images.indexOf('function fileContentsEqual('));
check('image asset reads and writes use fixed-size chunks',
  images.includes('const FILE_IO_CHUNK_SIZE: number = 64 * 1024') &&
  imageRead.includes('Math.min(FILE_IO_CHUNK_SIZE, size - total)') &&
  imageWrite.includes('Math.min(bytes.length, offset + FILE_IO_CHUNK_SIZE)') &&
  !imageRead.includes('new ArrayBuffer(size - total)'));
check('image asset writes use exact views and reject impossible progress',
  imageWrite.includes('bytes.subarray(offset, end)') &&
  imageWrite.includes('view.byteOffset + view.byteLength') &&
  imageWrite.includes('written <= 0 || written > view.byteLength'));
check('existing image asset comparison is streaming rather than full-file duplication',
  imageCompare.includes('Math.min(FILE_IO_CHUNK_SIZE, expected.length - total)') &&
  imageCompare.includes('expected[total + index]') &&
  !imageCompare.includes('readFileFully(file.fd, expected.length)'));

const recordingCompare = recordings.slice(recordings.indexOf('function filesEqual('),
  recordings.indexOf('function baseName('));
const backupCompare = backup.slice(backup.indexOf('private filesEqual('),
  backup.indexOf('private replaceFile('));
check('recording comparison fills each logical chunk independently before comparing',
  recordingCompare.includes('readChunkFully(left.fd, requested)') &&
  recordingCompare.includes('readChunkFully(right.fd, requested)') &&
  recordingCompare.includes('while (total < size)'));
check('system backup comparison fills each logical chunk independently before comparing',
  backupCompare.includes('this.readChunkFully(left.fd, requested)') &&
  backupCompare.includes('this.readChunkFully(right.fd, requested)') &&
  backupCompare.includes('while (total < size)'));

function plannedReader(bytes, plan) {
  let offset = 0;
  let call = 0;
  return {
    read(requested) {
      if (offset >= bytes.length) return new Uint8Array(0);
      const planned = plan[Math.min(call, plan.length - 1)];
      const count = Math.min(requested, planned, bytes.length - offset);
      const result = bytes.slice(offset, offset + count);
      offset += count;
      call++;
      return result;
    },
  };
}

function readExactly(reader, size) {
  const output = new Uint8Array(size);
  let total = 0;
  while (total < size) {
    const chunk = reader.read(size - total);
    if (chunk.length <= 0 || chunk.length > size - total) return null;
    output.set(chunk, total);
    total += chunk.length;
  }
  return output;
}

function comparePlanned(left, right, leftPlan, rightPlan, chunkSize) {
  if (left.length !== right.length) return false;
  const leftReader = plannedReader(left, leftPlan);
  const rightReader = plannedReader(right, rightPlan);
  let total = 0;
  while (total < left.length) {
    const requested = Math.min(chunkSize, left.length - total);
    const leftChunk = readExactly(leftReader, requested);
    const rightChunk = readExactly(rightReader, requested);
    if (leftChunk === null || rightChunk === null) return false;
    if (!leftChunk.every((value, index) => value === rightChunk[index])) return false;
    total += requested;
  }
  return true;
}

const sample = Uint8Array.from({ length: 37 }, (_, index) => (index * 17) & 0xff);
check('runtime model accepts identical files with different legal short-read schedules',
  comparePlanned(sample, sample.slice(), [1, 7, 2, 5], [6, 1, 3, 4], 8));
const changed = sample.slice();
changed[19] ^= 0xff;
check('runtime model still rejects a byte difference',
  !comparePlanned(sample, changed, [1, 7, 2, 5], [6, 1, 3, 4], 8));
check('runtime model rejects premature zero progress',
  !comparePlanned(sample, sample.slice(), [4], [0], 8));

console.log(`TOTAL=${checks.length} FAILED=0`);
