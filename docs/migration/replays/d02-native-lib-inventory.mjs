// Phase 811 replay: native .so library inventory version diff.
// Reads each xapk's central directory, extracts config.arm64_v8a.apk
// (stored or deflated member), parses the inner zip central directory,
// and compares .so names + uncompressed sizes across versions.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import zlib from 'node:zlib';

const nroot = 'C:/Users/Cisco He/Desktop/Notability';
const XAPK = {
  '1.0.3': `${nroot}/Notability_1.0.3/Notability_+AI+Note+Workspace_1.0.3_APKPure.xapk`,
  '1.4.2': `${nroot}/Notability_1.4.2/Notability%3A+AI+Note+Workspace_1.4.2_apkcombo.com.xapk`,
};

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

function cdEntries(buf) {
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  const count = buf.readUInt16LE(eocd + 10);
  let off = buf.readUInt32LE(eocd + 16);
  const out = [];
  for (let i = 0; i < count; i++) {
    const method = buf.readUInt16LE(off + 10);
    const csize = buf.readUInt32LE(off + 20);
    const usize = buf.readUInt32LE(off + 24);
    const nlen = buf.readUInt16LE(off + 28);
    const xlen = buf.readUInt16LE(off + 30);
    const cmlen = buf.readUInt16LE(off + 32);
    const lho = buf.readUInt32LE(off + 42);
    const name = buf.toString('utf8', off + 46, off + 46 + nlen);
    out.push({ name, method, csize, usize, lho });
    off += 46 + nlen + xlen + cmlen;
  }
  return out;
}

function memberBytes(buf, e) {
  const lnlen = buf.readUInt16LE(e.lho + 26);
  const lxlen = buf.readUInt16LE(e.lho + 28);
  const start = e.lho + 30 + lnlen + lxlen;
  const raw = buf.subarray(start, start + e.csize);
  return e.method === 8 ? zlib.inflateRawSync(raw) : raw;
}

function soMap(xapkPath) {
  const buf = fs.readFileSync(xapkPath);
  const e = cdEntries(buf).find(x => x.name === 'config.arm64_v8a.apk');
  const inner = memberBytes(buf, e);
  const map = new Map();
  for (const c of cdEntries(inner)) {
    if (c.name.endsWith('.so')) map.set(c.name.split('/').pop(), c.usize);
  }
  return map;
}

const a = soMap(XAPK['1.0.3']);
const b = soMap(XAPK['1.4.2']);

check('lib counts 26 -> 31', a.size === 26 && b.size === 31,
  `${a.size}/${b.size}`);

const removed = [...a.keys()].filter(k => !b.has(k));
check('zero .so removed', removed.length === 0, removed.join(','));

const added = [...b.keys()].filter(k => !a.has(k)).sort();
check('exactly 5 new .so (crashlytics x4 + zstd)',
  JSON.stringify(added) === JSON.stringify([
    'libcrashlytics-common.so', 'libcrashlytics-handler.so',
    'libcrashlytics-trampoline.so', 'libcrashlytics.so',
    'libzstd-jni-1.5.7-4.so',
  ]), added.join(','));

// Size bumps corroborating earlier phases (MyScript/PDFTron/Rive/ink).
const bumped = [...a.keys()].filter(k => b.has(k) && a.get(k) !== b.get(k));
check('12 .so size deltas', bumped.length === 12, bumped.join(','));
check('rive runtime grew (matches 808 file-count upgrade)',
  b.get('librive-android.so') > a.get('librive-android.so'));
check('libink grew (matches 798 ink-storage / 778 nib model)',
  b.get('libink.so') > a.get('libink.so'));
check('libPDFNetC grew (PDFTron upgrade)',
  b.get('libPDFNetC.so') > a.get('libPDFNetC.so'));
check('libiink grew (MyScript engine upgrade)',
  b.get('libiink.so') > a.get('libiink.so'));

// Stable cores pinned.
for (const k of ['libicing.so', 'libmlkit_google_ocr_pipeline.so',
                 'libsqliteJni.so', 'libc++_shared.so']) {
  check(`${k} size unchanged`, a.get(k) === b.get(k));
}

// MyScript family grows (10 modules, all present both versions).
const myscript = [...a.keys()].filter(k => k.startsWith('libMyScript'));
check('MyScript family 10 modules in both versions',
  myscript.length === 10 &&
  myscript.every(k => b.has(k)));

console.log(`\nnative-lib replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
