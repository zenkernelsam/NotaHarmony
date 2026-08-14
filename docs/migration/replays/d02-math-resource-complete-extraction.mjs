import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';

const engine = fs.readFileSync(
  path.join(root, 'note/src/main/ets/rendering/OriginalMathEngine.ets'), 'utf8');
const backup = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const original = fs.readFileSync(path.join(originalRoot, 's18.java'), 'utf8');

const prepare = engine.slice(engine.indexOf('private async prepare('),
  engine.indexOf('export const originalMathEngine'));
const extract = engine.slice(engine.indexOf('function extractResources('),
  engine.indexOf('function createCompletionMarker('));

const originalRootPath = original.indexOf('"glmath/v1"');
const originalMarker = original.indexOf('new File(file, ".complete")', originalRootPath);
const originalCleanup = original.indexOf('tf4.u0(file)', originalMarker);
const originalExtract = original.indexOf('a(file, "glmath")', originalCleanup);
const originalCommit = original.indexOf('file2.createNewFile()', originalExtract);

const markerCheck = prepare.indexOf('if (!isRegularFile(marker))');
const cleanup = prepare.indexOf('removeTree(baseRoot)', markerCheck);
const extraction = prepare.indexOf('extractResources(context, root)', cleanup);
const markerCommit = prepare.indexOf('createCompletionMarker(marker)', extraction);
const nativeInit = prepare.indexOf('initializeNative(root)', markerCommit);

const checks = [
  ['original uses versioned glmath/v1 resources and a completion marker',
    originalRootPath >= 0 && originalMarker > originalRootPath],
  ['original deletes incomplete extraction before copying and commits marker last',
    originalCleanup > originalMarker && originalExtract > originalCleanup &&
      originalCommit > originalExtract],
  ['original resource copy uses an 8 KiB complete stream copy',
    original.includes('l96.i0(inputStreamOpen, fileOutputStream, 8192)')],
  ['Harmony uses the same versioned-root and completion-marker ownership',
    engine.includes("const RESOURCE_VERSION: string = 'v1'") &&
      engine.includes("const COMPLETE_MARKER: string = '.complete'")],
  ['Harmony removes incomplete or legacy root before extraction and commits marker last',
    markerCheck >= 0 && cleanup > markerCheck && extraction > cleanup &&
      markerCommit > extraction && nativeInit > markerCommit],
  ['resource writer loops over bounded exact byte views',
    extract.includes('while (total < bytes.byteLength)') &&
      extract.includes('Math.min(RESOURCE_WRITE_CHUNK_SIZE, bytes.byteLength - total)') &&
      extract.includes('bytes.byteOffset + total') && extract.includes('total += written')],
  ['resource writer rejects invalid progress, syncs, and verifies final length',
    extract.includes('written <= 0 || written > requested') &&
      extract.includes('fileIo.fsyncSync(file.fd)') &&
      extract.includes('fileIo.statSync(path).size !== bytes.byteLength')],
  ['unsafe resource paths fail extraction instead of being silently skipped',
    engine.includes('if (!isSafeRelativeResourcePath(relative))') &&
      engine.includes('throw new Error(`glmath resource path is unsafe: ${relative}`)')],
  ['recursive cleanup re-proves direct-child paths and completion remains outside backup',
    engine.includes('directChildPath(path, child)') &&
      engine.includes('glmath cleanup refused a non-child path') &&
      engine.includes('fileIo.lstatSync(path)') && engine.includes('stat.isSymbolicLink()') &&
      backup.includes("['assets/pending', 'assets/trash', 'glmath']")],
];

for (const [name, ok] of checks) {
  assert.equal(ok, true, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

function extractModel(baseRoot, resources, writePlan) {
  const versionRoot = path.join(baseRoot, 'v1');
  const marker = path.join(versionRoot, '.complete');
  if (fs.existsSync(marker) && fs.statSync(marker).isFile()) return false;
  fs.rmSync(baseRoot, { recursive: true, force: true });
  fs.mkdirSync(versionRoot, { recursive: true });
  try {
    for (const [relative, bytes] of resources) {
      const destination = path.join(versionRoot, relative);
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      const written = [];
      let total = 0;
      let call = 0;
      while (total < bytes.length) {
        const requested = Math.min(4, bytes.length - total);
        const count = Math.min(writePlan[Math.min(call, writePlan.length - 1)], requested);
        if (count <= 0 || count > requested) throw new Error('invalid progress');
        written.push(...bytes.subarray(total, total + count));
        total += count;
        call++;
      }
      fs.writeFileSync(destination, Uint8Array.from(written));
    }
    fs.writeFileSync(marker, '');
    return true;
  } catch (error) {
    fs.rmSync(baseRoot, { recursive: true, force: true });
    throw error;
  }
}

const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'nota-math-extract-'));
try {
  const baseRoot = path.join(temporaryRoot, 'glmath');
  fs.mkdirSync(path.join(baseRoot, 'v1'), { recursive: true });
  fs.writeFileSync(path.join(baseRoot, 'legacy-font.ttf'), 'legacy');
  fs.writeFileSync(path.join(baseRoot, 'v1', 'partial.xml'), 'partial');
  const resources = [
    ['fonts/cmr10.ttf', Uint8Array.from([1, 2, 3, 4, 5, 6])],
    ['mappings.xml', Uint8Array.from([7, 8, 9])],
  ];
  assert.equal(extractModel(baseRoot, resources, [2, 1, 3]), true);
  assert.equal(fs.existsSync(path.join(baseRoot, 'legacy-font.ttf')), false);
  assert.equal(fs.existsSync(path.join(baseRoot, 'v1', 'partial.xml')), false);
  assert.deepEqual(fs.readFileSync(path.join(baseRoot, 'v1', 'fonts', 'cmr10.ttf')),
    Buffer.from(resources[0][1]));
  assert.equal(fs.existsSync(path.join(baseRoot, 'v1', '.complete')), true);
  console.log('PASS: runtime model replaces an incomplete legacy tree and commits exact resources');
  assert.equal(extractModel(baseRoot, resources, [1]), false,
    'FAILED: completed resource tree was unnecessarily rewritten');
  console.log('PASS: runtime model reuses a completed version without rewriting');
  fs.rmSync(baseRoot, { recursive: true, force: true });
  fs.mkdirSync(path.join(baseRoot, 'v1'), { recursive: true });
  assert.throws(() => extractModel(baseRoot, resources, [0]), /invalid progress/);
  assert.equal(fs.existsSync(baseRoot), false,
    'FAILED: failed extraction left a partial tree without a completion marker');
  console.log('PASS: runtime model removes partial resources after zero-progress failure');
} finally {
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
}

console.log(`TOTAL=${checks.length + 3} FAILED=0`);
