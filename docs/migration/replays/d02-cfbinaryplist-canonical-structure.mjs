import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const normalize = value => value.replaceAll('\r\n', '\n');
const readText = relative => normalize(fs.readFileSync(path.join(root, relative), 'utf8'));
const parserSource = readText('note/src/main/ets/data/BinaryPlistParser.ets');
const decoderSource = readText('note/src/main/ets/data/NSKeyedArchiverDecoder.ets');
const parserTestSource = readText('note/src/test/BinaryPlistParser.test.ets');

let total = 0;
let failed = 0;

function check(name, condition) {
  total++;
  if (!condition) {
    failed++;
    console.error(`FAIL: ${name}`);
    return;
  }
  console.log(`PASS: ${name}`);
}

function readU64BE(data, offset) {
  const value = data.readBigUInt64BE(offset);
  if (value > BigInt(Number.MAX_SAFE_INTEGER)) return null;
  return Number(value);
}

function byteWidthCanRepresentExclusiveLimit(size, value) {
  return size >= 1 && size <= 8 && value >= 0 &&
    (1n << BigInt(size * 8)) > BigInt(value);
}

function validateTopLevel(data) {
  if (data.length < 40 || data.subarray(0, 8).toString('ascii') !== 'bplist00') {
    return { ok: false, reason: 'magic' };
  }
  const trailer = data.length - 32;
  const offsetSize = data[trailer + 6];
  const refSize = data[trailer + 7];
  const count = readU64BE(data, trailer + 8);
  const top = readU64BE(data, trailer + 16);
  const table = readU64BE(data, trailer + 24);
  if (count === null || top === null || table === null || count < 1 || top >= count) {
    return { ok: false, reason: 'trailer-values' };
  }
  if (!byteWidthCanRepresentExclusiveLimit(refSize, count)) {
    return { ok: false, reason: 'ref-width' };
  }
  if (!byteWidthCanRepresentExclusiveLimit(offsetSize, table)) {
    return { ok: false, reason: 'offset-width' };
  }
  if (table <= 8 || table + count * offsetSize !== trailer) {
    return { ok: false, reason: 'table-adjacency' };
  }
  for (let index = 0; index < count; index++) {
    let offset = 0;
    for (let byte = 0; byte < offsetSize; byte++) {
      offset = offset * 256 + data[table + index * offsetSize + byte];
    }
    if (offset < 8 || offset >= table) {
      return { ok: false, reason: 'object-offset' };
    }
  }
  return { ok: true, reason: '', count, top, table, offsetSize, refSize };
}

function writeU64BE(data, offset, value) {
  data.writeBigUInt64BE(BigInt(value), offset);
}

function writeSizedBE(data, offset, size, value) {
  let remaining = value;
  for (let index = size - 1; index >= 0; index--) {
    data[offset + index] = remaining % 256;
    remaining = Math.floor(remaining / 256);
  }
}

function buildNullPlist(count, offsetSize, refSize, gap = 0) {
  const table = 8 + count;
  const trailer = table + count * offsetSize + gap;
  const data = Buffer.alloc(trailer + 32);
  data.write('bplist00', 0, 'ascii');
  for (let index = 0; index < count; index++) {
    data[8 + index] = 0x00;
    writeSizedBE(data, table + index * offsetSize, offsetSize, 8 + index);
  }
  data[trailer + 6] = offsetSize;
  data[trailer + 7] = refSize;
  writeU64BE(data, trailer + 8, count);
  writeU64BE(data, trailer + 16, 0);
  writeU64BE(data, trailer + 24, table);
  return data;
}

const samples = [
  ['Session.plist', 'test_notes/OP-AMP-extracted/OP-AMP/Session.plist', 308, 557533, 4, 2],
  ['metadata.plist', 'test_notes/OP-AMP-extracted/OP-AMP/metadata.plist', 97, 729, 2, 1],
  ['HandwritingIndex/index.plist',
    'test_notes/OP-AMP-extracted/OP-AMP/HandwritingIndex/index.plist', 161, 9917, 2, 1],
];
for (const [name, relative, expectedCount, expectedTable, expectedOffsetSize, expectedRefSize] of samples) {
  const result = validateTopLevel(fs.readFileSync(path.join(root, relative)));
  check(`${name} keeps a canonical trailer-adjacent offset table`, result.ok);
  check(`${name} trailer identity matches the tracked fixture`, result.ok &&
    result.count === expectedCount && result.table === expectedTable &&
    result.offsetSize === expectedOffsetSize && result.refSize === expectedRefSize);
}

check('a byte inserted between offset table and trailer is rejected',
  validateTopLevel(buildNullPlist(1, 1, 1, 1)).reason === 'table-adjacency');
check('one-byte object references cannot claim 256 objects',
  validateTopLevel(buildNullPlist(256, 2, 1)).reason === 'ref-width');
check('one-byte offsets cannot claim an offset table beyond byte 255',
  validateTopLevel(buildNullPlist(249, 1, 1)).reason === 'offset-width');

check('production validates object reference capacity',
  parserSource.includes('byteWidthCanRepresentExclusiveLimit(objectRefSize, numObjects)'));
check('production validates offset integer capacity',
  parserSource.includes('byteWidthCanRepresentExclusiveLimit(offsetIntSize, offsetTableOffset)'));
check('production requires offset table to end exactly at the trailer',
  parserSource.includes('offsetTableOffset + offsetTableSize !== t'));
check('referenced fill marker fails rather than becoming null',
  parserSource.includes("this.fail('fill marker 0x0F 不能作为对象被引用')"));
check('ordered set no longer silently degrades to an array',
  parserSource.includes("this.fail('ordered-set marker 0xB 在 bplist00 中不受支持')"));
check('binary plist dictionaries reject duplicate keys',
  parserSource.includes('const seenKeys: Set<string> = new Set<string>();') &&
    parserSource.includes('dict 含重复键'));
check('keyed archive validation independently rejects duplicate dictionaries',
  decoderSource.includes('含重复字典键'));
check('container cycles remain a hard parser error',
  parserSource.includes('this.fail(`检测到循环对象引用 index=${index}`)'));
check('ArkTS fixture no longer expects warning plus null for a cycle',
  parserTestSource.includes("expect(result.error.indexOf('循环对象引用') >= 0).assertTrue()") &&
    !parserTestSource.includes('keeps a true cycle as an explicit warning'));

if (failed > 0) {
  console.error(`D02_CFBINARYPLIST_CANONICAL_STRUCTURE_FAILED TOTAL=${total} FAILED=${failed}`);
  process.exit(1);
}
console.log(`D02_CFBINARYPLIST_CANONICAL_STRUCTURE_OK TOTAL=${total} FAILED=0`);
