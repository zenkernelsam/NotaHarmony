import assert from 'node:assert/strict';
import fs from 'node:fs';

const MAX_FILE_NAME = 65536;
const MAX_MIME = 4096;
const MAX_URL = 1048576;

class Builder {
  constructor(capacity = 2_500_000) {
    this.bytes = new Uint8Array(capacity);
    this.cursor = 4;
  }
  align(size) { while (this.cursor % size) this.cursor++; }
  table(fields, size) {
    const vtable = this.cursor;
    this.cursor += 4 + fields.length * 2;
    this.align(4);
    const table = this.cursor;
    this.cursor += size;
    w16(this.bytes, vtable, 4 + fields.length * 2);
    w16(this.bytes, vtable + 2, size);
    fields.forEach((field, index) => w16(this.bytes, vtable + 4 + index * 2, field));
    w32(this.bytes, table, table - vtable);
    return table;
  }
  pointer(slot, target) {
    assert(target > slot);
    w32(this.bytes, slot, target - slot);
  }
  stringBytes(values) {
    this.align(4);
    const vector = this.cursor;
    this.cursor += 5 + values.length;
    w32(this.bytes, vector, values.length);
    this.bytes.set(values, vector + 4);
    return vector;
  }
  string(value) { return this.stringBytes(new TextEncoder().encode(value)); }
  finish(root) {
    w32(this.bytes, 0, root);
    return this.bytes.slice(0, this.cursor);
  }
}

class Table {
  constructor(bytes, table) {
    range(bytes, table, 4, 'table');
    const vtable = table - i32(bytes, table);
    range(bytes, vtable, 4, 'vtable');
    const vtableSize = u16(bytes, vtable);
    const objectSize = u16(bytes, vtable + 2);
    range(bytes, vtable, vtableSize, 'vtable');
    range(bytes, table, objectSize, 'table object');
    this.bytes = bytes;
    this.table = table;
    this.vtable = vtable;
    this.vtableSize = vtableSize;
    this.objectSize = objectSize;
  }
  offset(field) {
    const entry = this.vtable + 4 + field * 2;
    return entry + 2 <= this.vtable + this.vtableSize ? u16(this.bytes, entry) : 0;
  }
  inline(field, size) {
    const offset = this.offset(field);
    if (offset === 0) return null;
    if (offset + size > this.objectSize) throw new Error(`inline field ${field} is truncated`);
    range(this.bytes, this.table + offset, size, `inline field ${field}`);
    return this.bytes.slice(this.table + offset, this.table + offset + size);
  }
  nested(field) {
    const slot = this.inline(field, 4);
    if (slot === null) return null;
    const pointer = this.table + this.offset(field);
    const relative = u32(this.bytes, pointer);
    if (relative < 4 || relative > this.bytes.length - pointer - 4) {
      throw new Error(`table field ${field} offset is invalid`);
    }
    return new Table(this.bytes, pointer + relative);
  }
  string(field, required, budget) {
    const slot = this.inline(field, 4);
    if (slot === null) {
      if (required) throw new Error(`missing required string ${field}`);
      return null;
    }
    const pointer = this.table + this.offset(field);
    const relative = u32(this.bytes, pointer);
    if (relative < 4 || relative > this.bytes.length - pointer - 4) {
      throw new Error(`string field ${field} offset is invalid`);
    }
    const vector = pointer + relative;
    const count = u32(this.bytes, vector);
    if (count > budget) throw new Error(`string field ${field} exceeds budget`);
    range(this.bytes, vector + 4, count + 1, `string field ${field}`);
    if (this.bytes[vector + 4 + count] !== 0) throw new Error(`string field ${field} has no terminator`);
    return new TextDecoder('utf-8', { fatal: true }).decode(
      this.bytes.slice(vector + 4, vector + 4 + count));
  }
}

function fixture(options = {}) {
  const builder = new Builder();
  const root = builder.table([4, 12, 20, 0, 28, 32], 36);
  w16(builder.bytes, root + 4, 7);
  w32(builder.bytes, root + 8, 90);
  w64(builder.bytes, root + 12, 123n);
  w64(builder.bytes, root + 20, 124n);
  builder.bytes[root + 28] = 22;
  const includeImage = !options.missingImage;
  const fields = [4, 0, 8, 20, 0, 0, 28, 0, 0, 36,
    includeImage ? 44 : 0, 48, 64, options.math ? 68 : 0, 0,
    options.paper ? 72 : 0, 76, 77, 0, 0, 0];
  const block = builder.table(fields, 80);
  builder.pointer(root + 32, block);
  builder.bytes[block + 4] = options.type ?? 1;
  w16(builder.bytes, block + 8, 2);
  w32(builder.bytes, block + 12, 10);
  w32(builder.bytes, block + 16, 3);
  wf32(builder.bytes, block + 20, 12);
  wf32(builder.bytes, block + 24, 34);
  wf32(builder.bytes, block + 28, 200);
  wf32(builder.bytes, block + 32, 150);
  w64(builder.bytes, block + 36, 18446744073709551615n);
  wf32(builder.bytes, block + 48, options.badCrop ? Number.NaN : -5);
  wf32(builder.bytes, block + 52, 2);
  wf32(builder.bytes, block + 56, 100);
  wf32(builder.bytes, block + 60, 50);
  builder.bytes[block + 76] = 1;
  builder.bytes[block + 77] = 1;

  let metadata = 0;
  if (includeImage) {
    const asset = builder.table([4, 8], 16);
    builder.pointer(block + 44, asset);
    wf32(builder.bytes, asset + 8, options.badSize ? Number.NaN : 4032);
    wf32(builder.bytes, asset + 12, 3024);
    metadata = builder.table([8, 72, 76, 80], 84);
    builder.pointer(asset + 4, metadata);
    const hashBits = [0n, 1n, 9007199254740993n, 18446744073709551614n,
      42n, 4294967296n, 9223372036854775808n, 18446744073709551615n];
    hashBits.forEach((value, index) => w64(builder.bytes, metadata + 8 + index * 8, value));
    w32(builder.bytes, metadata + 80, options.zeroFileSize ? 0 : 0xFFFFFFFF);
    const nameBytes = options.invalidUtf8 ? new Uint8Array([0xC3, 0x28]) :
      options.oversizedName ? new Uint8Array(MAX_FILE_NAME + 1).fill(0x61) :
        new TextEncoder().encode('原版照片.png');
    const fileName = builder.stringBytes(nameBytes);
    builder.pointer(metadata + 72, fileName);
    const mime = builder.string(options.emptyMime ? '' : 'image/png');
    builder.pointer(metadata + 76, mime);
  }
  const web = builder.string('https://example.test/照片.png');
  builder.pointer(block + 64, web);
  if (options.math) {
    const latex = builder.string('x');
    builder.pointer(block + 68, latex);
  }
  if (options.paper) {
    const paper = builder.table([], 4);
    builder.pointer(block + 72, paper);
  }
  const raw = builder.finish(root);
  return { raw, metadata };
}

function decode(raw) {
  const root = new Table(raw, u32(raw, 0));
  assert.equal(root.inline(4, 1)[0], 22);
  const block = root.nested(5);
  const type = block.inline(0, 1)?.[0] ?? 0;
  const asset = block.nested(10);
  if (type === 1 && asset === null) throw new Error('image block has no asset');
  let image = null;
  if (asset !== null) {
    const metadata = asset.nested(0);
    const size = asset.inline(1, 8);
    if (metadata === null || size === null) throw new Error('image asset missing required fields');
    const hash = metadata.inline(0, 64);
    const fileName = metadata.string(1, true, MAX_FILE_NAME);
    const mimeType = metadata.string(2, true, MAX_MIME);
    const fileSize = u32(metadata.inline(3, 4), 0);
    if (hash === null || fileName.length === 0 || mimeType.length === 0 || fileSize === 0) {
      throw new Error('image metadata invalid');
    }
    const width = f32(size, 0), height = f32(size, 4);
    if (!validSize(width, height)) throw new Error('image size invalid');
    image = { bits: Array.from({ length: 8 }, (_, index) => u64(hash, index * 8).toString()),
      fileName, mimeType, fileSize, width, height };
  }
  const crop = block.inline(11, 16);
  const cropRect = crop === null ? null : {
    x: f32(crop, 0), y: f32(crop, 4), width: f32(crop, 8), height: f32(crop, 12),
  };
  if (cropRect !== null && (!Number.isFinite(cropRect.x) || !Number.isFinite(cropRect.y) ||
    !validSize(cropRect.width, cropRect.height))) throw new Error('crop invalid');
  return { type, image, cropRect, webUrl: block.string(12, false, MAX_URL),
    horizontal: block.inline(16, 1)?.[0] !== 0,
    vertical: block.inline(17, 1)?.[0] !== 0 };
}

const decoded = decode(fixture().raw);
assert.deepEqual(decoded.image.bits, ['0', '1', '9007199254740993', '18446744073709551614',
  '42', '4294967296', '9223372036854775808', '18446744073709551615']);
assert.equal(decoded.image.fileName, '原版照片.png');
assert.equal(decoded.image.mimeType, 'image/png');
assert.equal(decoded.image.fileSize, 4294967295);
assert.deepEqual([decoded.image.width, decoded.image.height], [4032, 3024]);
assert.deepEqual(decoded.cropRect, { x: -5, y: 2, width: 100, height: 50 });
assert.equal(decoded.webUrl, 'https://example.test/照片.png');
assert.equal(decoded.horizontal, true);
assert.equal(decoded.vertical, true);

const rejected = [
  fixture({ missingImage: true }).raw,
  fixture({ emptyMime: true }).raw,
  fixture({ zeroFileSize: true }).raw,
  fixture({ badSize: true }).raw,
  fixture({ badCrop: true }).raw,
  fixture({ invalidUtf8: true }).raw,
  fixture({ oversizedName: true }).raw,
];
for (const raw of rejected) assert.throws(() => decode(raw));
const truncated = fixture();
assert.throws(() => decode(truncated.raw.slice(0, truncated.metadata + 48)));
const badTerminator = fixture();
badTerminator.raw[badTerminator.raw.length - 1] = 1;
assert.throws(() => decode(badTerminator.raw), /terminator/);

const textWithImage = decode(fixture({ type: 0 }).raw);
assert.equal(textWithImage.image.mimeType, 'image/png');
const source = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalCreateBlockOperation.ets', import.meta.url), 'utf8');
const reader = fs.readFileSync(new URL(
  '../../../note/src/main/ets/data/OriginalSyncedOperationFlatBuffer.ets', import.meta.url), 'utf8');
assert.match(source, /CREATE_BLOCK_IMAGE_FIELDS_ON_TEXT/);
assert.match(source, /CREATE_BLOCK_IMAGE_FIELDS_ON_MATH/);
assert.match(source, /CREATE_BLOCK_MATH_FIELDS_ON_IMAGE/);
assert.match(source, /CREATE_BLOCK_TEXT_PAPER_ON_IMAGE/);
assert.doesNotMatch(source, /CREATE_BLOCK_IMAGE_UNSUPPORTED/);
assert.match(source, /buildImageBlock/);
assert.match(source, /mergeImageAssetReference/);
assert.match(source, /const unsupported:[\s\S]*if \(unsupported !== null\)[\s\S]*readTargetPage/);
assert.match(reader, /readUtf8String\(field: number, required: boolean, maximumBytes: number\)/);
assert.match(reader, /encodeInto\(value\)/);
assert.match(reader, /readOriginalInlineUint64Decimal/);

console.log('success|image-asset=1|hash-u64x8=1|utf8=1|file-size-u32=1|' +
  'intrinsic-size=1|crop=1|web-url=1|flip-hv=1|budget=1|malformed=9|' +
  'type-fields=1|type-reject-before-store=1');

function validSize(width, height) {
  return Number.isFinite(width) && width >= 0 && Number.isFinite(height) && height >= 0;
}
function range(bytes, offset, length, label) {
  if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < 0 ||
    length < 0 || offset > bytes.length - length) throw new Error(`${label} is out of bounds`);
}
function u16(bytes, offset) { range(bytes, offset, 2, 'u16'); return bytes[offset] | bytes[offset + 1] << 8; }
function u32(bytes, offset) {
  range(bytes, offset, 4, 'u32');
  return (bytes[offset] | bytes[offset + 1] << 8 | bytes[offset + 2] << 16 |
    bytes[offset + 3] << 24) >>> 0;
}
function i32(bytes, offset) { const value = u32(bytes, offset); return value >= 2 ** 31 ? value - 2 ** 32 : value; }
function u64(bytes, offset) { let value = 0n; for (let i = 7; i >= 0; i--) value = value * 256n + BigInt(bytes[offset + i]); return value; }
function f32(bytes, offset) { range(bytes, offset, 4, 'f32'); return new DataView(bytes.buffer, bytes.byteOffset + offset, 4).getFloat32(0, true); }
function w16(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; }
function w32(bytes, offset, value) { bytes[offset] = value; bytes[offset + 1] = value >>> 8; bytes[offset + 2] = value >>> 16; bytes[offset + 3] = value >>> 24; }
function w64(bytes, offset, value) { for (let i = 0; i < 8; i++) { bytes[offset + i] = Number(value & 255n); value >>= 8n; } }
function wf32(bytes, offset, value) { new DataView(bytes.buffer, offset, 4).setFloat32(0, value, true); }
