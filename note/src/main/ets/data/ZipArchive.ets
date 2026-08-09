// T-026 最小 ZIP 读写器（纯 ArkTS，不引入第三方库）
// 支持 STORE(0) + DEFLATE(8) 两种模式；little-endian；CRC32 查表法；
// 读取走 Central Directory 定位（兼容 data descriptor 标准 ZIP）
import { zlib } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export interface ZipEntry {
  name: string;           // 文件路径（如 "manifest.json"）
  data: Uint8Array;       // 文件内容（已解压）
  compressed: boolean;    // 源条目是否 DEFLATE 压缩
  modifiedAt?: number;    // Writer-only timestamp in Unix milliseconds
  directory?: boolean;    // Writer-only directory marker
}

// === 常量 ===
const SIG_LOCAL: number = 0x04034b50;
const SIG_CENTRAL: number = 0x02014b50;
const SIG_EOCD: number = 0x06054b50;
const SIG_ZIP64_EOCD: number = 0x06064b50;
const SIG_ZIP64_LOCATOR: number = 0x07064b50;
const EXTRA_ZIP64: number = 0x0001;
const ZIP16_SENTINEL: number = 0xFFFF;
const ZIP32_SENTINEL: number = 0xFFFFFFFF;
const FLAG_UTF8: number = 0x0800;
const FLAG_DATA_DESCRIPTOR: number = 0x0008;
const METHOD_STORE: number = 0;
const METHOD_DEFLATE: number = 8;
export const ZIP_MAX_ENTRY_COUNT: number = 65535;
export const ZIP_MAX_ENTRY_UNCOMPRESSED_SIZE: number = 512 * 1024 * 1024;
export const ZIP_MAX_TOTAL_UNCOMPRESSED_SIZE: number = 1024 * 1024 * 1024;
export const ZIP_MAX_COMPRESSION_RATIO: number = 1000;
const ZIP_RATIO_BUDGET_MIN_SIZE: number = 1024 * 1024;

// === CRC32（查表法，256 项表）===
const CRC_TABLE: number[] = buildCrcTable();

function buildCrcTable(): number[] {
  const table: number[] = [];
  for (let n = 0; n < 256; n++) {
    let c: number = n;
    for (let k = 0; k < 8; k++) {
      c = (c & 1) !== 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table.push(c >>> 0);
  }
  return table;
}

function crc32(data: Uint8Array): number {
  let crc: number = 0xFFFFFFFF;
  for (let i = 0; i < data.length; i++) {
    crc = (crc >>> 8) ^ CRC_TABLE[(crc ^ data[i]) & 0xFF];
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

// === 二进制流写入（little-endian）===
class ByteWriter {
  private chunks: Uint8Array[] = [];
  private total: number = 0;

  writeU16(value: number): void {
    const v: number = value & 0xFFFF;
    const b: Uint8Array = new Uint8Array([v & 0xFF, (v >>> 8) & 0xFF]);
    this.chunks.push(b);
    this.total += 2;
  }

  writeU32(value: number): void {
    const v: number = value >>> 0;
    const b: Uint8Array = new Uint8Array([v & 0xFF, (v >>> 8) & 0xFF, (v >>> 16) & 0xFF, (v >>> 24) & 0xFF]);
    this.chunks.push(b);
    this.total += 4;
  }

  writeU64(value: number): void {
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new Error('ZIP64 value is outside the safe integer range');
    }
    this.writeU32(value % 0x100000000);
    this.writeU32(Math.floor(value / 0x100000000));
  }

  writeBytes(bytes: Uint8Array): void {
    this.chunks.push(bytes);
    this.total += bytes.length;
  }

  length(): number {
    return this.total;
  }

  build(): Uint8Array {
    const out = new Uint8Array(this.total);
    let pos: number = 0;
    for (const c of this.chunks) {
      out.set(c, pos);
      pos += c.length;
    }
    return out;
  }
}

// === 二进制读取（little-endian）===
function readU16(data: Uint8Array, offset: number): number {
  return (data[offset] & 0xFF) | ((data[offset + 1] & 0xFF) << 8);
}

function readU32(data: Uint8Array, offset: number): number {
  return ((data[offset] & 0xFF) | ((data[offset + 1] & 0xFF) << 8) |
    ((data[offset + 2] & 0xFF) << 16) | ((data[offset + 3] & 0xFF) << 24)) >>> 0;
}

// === UTF-8 编解码 ===
function encodeUtf8(text: string): Uint8Array {
  const encoder = new util.TextEncoder();
  return encoder.encodeInto(text);
}

function decodeUtf8(data: Uint8Array, offset: number, length: number): string {
  const decoder = util.TextDecoder.create('utf-8');
  const slice = data.slice(offset, offset + length);
  // decodeToString（API 12+，替代弃用的 decode/decodeWithStream）
  return decoder.decodeToString(slice);
}

function readU64(data: Uint8Array, offset: number): number | null {
  if (offset < 0 || offset + 8 > data.length) {
    return null;
  }
  const value: number = readU32(data, offset + 4) * 0x100000000 + readU32(data, offset);
  return Number.isSafeInteger(value) ? value : null;
}

interface Zip64ExtraValues {
  usize: number;
  csize: number;
  localOffset: number;
  diskStart: number;
}

function readZip64Extra(data: Uint8Array, offset: number, length: number, needUsize: boolean,
  needCsize: boolean, needLocalOffset: boolean, needDiskStart: boolean): Zip64ExtraValues | null {
  const end: number = offset + length;
  if (offset < 0 || end > data.length) {
    return null;
  }
  let pos: number = offset;
  while (pos + 4 <= end) {
    const headerId: number = readU16(data, pos);
    const fieldLength: number = readU16(data, pos + 2);
    const fieldStart: number = pos + 4;
    const fieldEnd: number = fieldStart + fieldLength;
    if (fieldEnd > end) {
      return null;
    }
    if (headerId === EXTRA_ZIP64) {
      const values: Zip64ExtraValues = { usize: -1, csize: -1, localOffset: -1, diskStart: -1 };
      let cursor: number = fieldStart;
      if (needUsize) {
        const value: number | null = readU64(data, cursor);
        if (value === null || cursor + 8 > fieldEnd) {
          return null;
        }
        values.usize = value;
        cursor += 8;
      }
      if (needCsize) {
        const value: number | null = readU64(data, cursor);
        if (value === null || cursor + 8 > fieldEnd) {
          return null;
        }
        values.csize = value;
        cursor += 8;
      }
      if (needLocalOffset) {
        const value: number | null = readU64(data, cursor);
        if (value === null || cursor + 8 > fieldEnd) {
          return null;
        }
        values.localOffset = value;
        cursor += 8;
      }
      if (needDiskStart) {
        if (cursor + 4 > fieldEnd) {
          return null;
        }
        values.diskStart = readU32(data, cursor);
      }
      return values;
    }
    pos = fieldEnd;
  }
  return null;
}

function bytesEqual(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let i: number = 0; i < left.length; i++) {
    if (left[i] !== right[i]) {
      return false;
    }
  }
  return true;
}

// === raw DEFLATE（ZIP 格式要求 RFC1951，windowBits=-15）===
function toArrayBuffer(data: Uint8Array): ArrayBuffer {
  return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) as ArrayBuffer;
}

async function deflateRaw(data: Uint8Array): Promise<Uint8Array> {
  const input = toArrayBuffer(data);
  let outCap: number = Math.max(64, input.byteLength + (input.byteLength >> 12) * 5 + 64);
  let lastStatus: zlib.ReturnStatus = zlib.ReturnStatus.OK;
  for (let attempt: number = 0; attempt < 4; attempt++) {
    const zip: zlib.Zip = zlib.createZipSync();
    const strm: zlib.ZStream = await zip.getZStream();
    strm.nextIn = input;
    strm.availableIn = input.byteLength;
    const outBuf = new ArrayBuffer(outCap);
    strm.nextOut = outBuf;
    strm.availableOut = outCap;
    let status: zlib.ReturnStatus = await zip.deflateInit2(strm,
      zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
      zlib.CompressMethod.DEFLATED, -15, zlib.MemLevel.MEM_LEVEL_MAX,
      zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY);
    if (status !== zlib.ReturnStatus.OK) {
      await zip.deflateEnd(strm);
      throw new Error('deflateInit2 failed: ' + status);
    }
    status = await zip.deflate(strm, zlib.CompressFlushMode.FINISH);
    lastStatus = status;
    const outLen: number = strm.totalOut ?? 0;
    const remainingInput: number = strm.availableIn ?? 0;
    await zip.deflateEnd(strm);
    if (status === zlib.ReturnStatus.STREAM_END && remainingInput === 0) {
      return new Uint8Array(outBuf.slice(0, outLen));
    }
    if (status !== zlib.ReturnStatus.OK) {
      throw new Error('deflate failed: ' + status);
    }
    outCap *= 2;
  }
  throw new Error('deflate output buffer exhausted: ' + lastStatus);
}

export interface ZipParseResult {
  entries: ZipEntry[];
  failed: string[];
  encrypted: string[];
}

async function inflateRaw(data: Uint8Array, expectedSize: number): Promise<Uint8Array> {
  const input = toArrayBuffer(data);
  let outCap: number = Math.max(expectedSize, 1024);
  let lastStatus: zlib.ReturnStatus = zlib.ReturnStatus.OK;
  for (let attempt: number = 0; attempt < 4; attempt++) {
    const zip: zlib.Zip = zlib.createZipSync();
    const strm: zlib.ZStream = await zip.getZStream();
    strm.nextIn = input;
    strm.availableIn = input.byteLength;
    const outBuf = new ArrayBuffer(outCap);
    strm.nextOut = outBuf;
    strm.availableOut = outCap;
    let status: zlib.ReturnStatus = await zip.inflateInit2(strm, -15);
    if (status !== zlib.ReturnStatus.OK) {
      await zip.inflateEnd(strm);
      throw new Error('inflateInit2 failed: ' + status);
    }
    status = await zip.inflate(strm, zlib.CompressFlushMode.FINISH);
    lastStatus = status;
    const outLen: number = strm.totalOut ?? 0;
    await zip.inflateEnd(strm);
    if (status === zlib.ReturnStatus.STREAM_END) {
      return new Uint8Array(outBuf.slice(0, outLen));
    }
    if (status !== zlib.ReturnStatus.OK) {
      throw new Error('inflate failed: ' + status);
    }
    outCap *= 2;
  }
  throw new Error('inflate output buffer exhausted: ' + lastStatus);
}

// === ZipWriter ===
interface PreparedEntry {
  name: string;
  nameBytes: Uint8Array;
  data: Uint8Array;
  rawSize: number;
  compressed: boolean;
  method: number;
  crc: number;
  dosTime: number;
  dosDate: number;
  directory: boolean;
}

export class ZipWriter {
  private entries: ZipEntry[] = [];

  // 添加条目；compress=false 时 STORE，否则尝试 DEFLATE（压缩无收益自动回退 STORE）
  addEntry(name: string, data: Uint8Array, compress?: boolean, modifiedAt?: number): void {
    this.entries.push({ name: name, data: data, compressed: compress !== false,
      modifiedAt: modifiedAt, directory: false });
  }

  addDirectory(name: string, modifiedAt?: number): void {
    const normalized: string = name.endsWith('/') ? name : name + '/';
    this.entries.push({ name: normalized, data: new Uint8Array(0), compressed: false,
      modifiedAt: modifiedAt, directory: true });
  }

  // 生成 ZIP 二进制（Local File Header + Central Directory + End Record）
  async build(forceZip64?: boolean): Promise<Uint8Array> {
    if (this.entries.length > ZIP_MAX_ENTRY_COUNT) {
      throw new Error('ZIP entry count exceeds safety budget');
    }
    const prepared: PreparedEntry[] = [];
    const names: Set<string> = new Set<string>();
    let totalRawSize: number = 0;
    for (const e of this.entries) {
      if (names.has(e.name)) {
        throw new Error('duplicate ZIP entry name: ' + e.name);
      }
      names.add(e.name);
      const raw: Uint8Array = e.data;
      if (raw.length > ZIP_MAX_ENTRY_UNCOMPRESSED_SIZE ||
        totalRawSize > ZIP_MAX_TOTAL_UNCOMPRESSED_SIZE - raw.length) {
        throw new Error('ZIP uncompressed size exceeds safety budget');
      }
      totalRawSize += raw.length;
      const crc: number = crc32(raw);
      let payload: Uint8Array = raw;
      let method: number = METHOD_STORE;
      let compressed: boolean = false;
      if (e.compressed && raw.length > 64) {
        try {
          const deflated: Uint8Array = await deflateRaw(raw);
          const ratioWithinBudget: boolean = raw.length < ZIP_RATIO_BUDGET_MIN_SIZE ||
            (deflated.length > 0 && raw.length / deflated.length <= ZIP_MAX_COMPRESSION_RATIO);
          if (deflated.length < raw.length && ratioWithinBudget) {
            payload = deflated;
            method = METHOD_DEFLATE;
            compressed = true;
          }
        } catch (err) {
          // 压缩失败回退 STORE
          payload = raw;
          method = METHOD_STORE;
        }
      }
      const dos: number[] = toDosDateTime(e.modifiedAt);
      const nameBytes: Uint8Array = encodeUtf8(e.name);
      if (nameBytes.length > 0xFFFF) {
        throw new Error('ZIP entry name is too long');
      }
      prepared.push({
        name: e.name,
        nameBytes: nameBytes,
        data: payload,
        rawSize: raw.length,
        compressed: compressed,
        method: method,
        crc: crc,
        dosTime: dos[0],
        dosDate: dos[1],
        directory: e.directory === true,
      });
    }

    // === Local File Headers + 数据 ===
    const localWriter = new ByteWriter();
    const localOffsets: number[] = [];
    for (const p of prepared) {
      localOffsets.push(localWriter.length());
      const zip64Size: boolean = forceZip64 === true || p.data.length >= ZIP32_SENTINEL ||
        p.rawSize >= ZIP32_SENTINEL;
      const localExtra = new ByteWriter();
      if (zip64Size) {
        localExtra.writeU16(EXTRA_ZIP64);
        localExtra.writeU16(16);
        localExtra.writeU64(p.rawSize);
        localExtra.writeU64(p.data.length);
      }
      const localExtraData: Uint8Array = localExtra.build();
      localWriter.writeU32(SIG_LOCAL);
      localWriter.writeU16(zip64Size ? 45 : 20);      // version needed
      localWriter.writeU16(FLAG_UTF8);                // general purpose bit 11 (UTF-8)
      localWriter.writeU16(p.method);                 // compression method
      localWriter.writeU16(p.dosTime);                // DOS mod time
      localWriter.writeU16(p.dosDate);                // DOS mod date
      localWriter.writeU32(p.crc);                    // crc32
      localWriter.writeU32(zip64Size ? ZIP32_SENTINEL : p.data.length);
      localWriter.writeU32(zip64Size ? ZIP32_SENTINEL : p.rawSize);
      localWriter.writeU16(p.nameBytes.length);       // name len
      localWriter.writeU16(localExtraData.length);    // extra len
      localWriter.writeBytes(p.nameBytes);
      localWriter.writeBytes(localExtraData);
      localWriter.writeBytes(p.data);
    }
    const localData: Uint8Array = localWriter.build();

    // === Central Directory ===
    const cdWriter = new ByteWriter();
    for (let i = 0; i < prepared.length; i++) {
      const p = prepared[i];
      const zip64Usize: boolean = forceZip64 === true || p.rawSize >= ZIP32_SENTINEL;
      const zip64Csize: boolean = forceZip64 === true || p.data.length >= ZIP32_SENTINEL;
      const zip64Offset: boolean = forceZip64 === true || localOffsets[i] >= ZIP32_SENTINEL;
      const centralExtraPayload = new ByteWriter();
      if (zip64Usize) {
        centralExtraPayload.writeU64(p.rawSize);
      }
      if (zip64Csize) {
        centralExtraPayload.writeU64(p.data.length);
      }
      if (zip64Offset) {
        centralExtraPayload.writeU64(localOffsets[i]);
      }
      const centralExtraPayloadData: Uint8Array = centralExtraPayload.build();
      const centralExtra = new ByteWriter();
      if (centralExtraPayloadData.length > 0) {
        centralExtra.writeU16(EXTRA_ZIP64);
        centralExtra.writeU16(centralExtraPayloadData.length);
        centralExtra.writeBytes(centralExtraPayloadData);
      }
      const centralExtraData: Uint8Array = centralExtra.build();
      const zip64Entry: boolean = centralExtraData.length > 0;
      cdWriter.writeU32(SIG_CENTRAL);
      cdWriter.writeU16(zip64Entry ? 45 : 20);        // version made by
      cdWriter.writeU16(zip64Entry ? 45 : 20);        // version needed
      cdWriter.writeU16(FLAG_UTF8);
      cdWriter.writeU16(p.method);
      cdWriter.writeU16(p.dosTime);                   // DOS mod time
      cdWriter.writeU16(p.dosDate);                   // DOS mod date
      cdWriter.writeU32(p.crc);
      cdWriter.writeU32(zip64Csize ? ZIP32_SENTINEL : p.data.length);
      cdWriter.writeU32(zip64Usize ? ZIP32_SENTINEL : p.rawSize);
      cdWriter.writeU16(p.nameBytes.length);
      cdWriter.writeU16(centralExtraData.length);     // extra len
      cdWriter.writeU16(0);                           // comment len
      cdWriter.writeU16(0);                           // disk number start
      cdWriter.writeU16(0);                           // internal attrs
      cdWriter.writeU32(p.directory ? 0x10 : 0);      // DOS directory attribute
      cdWriter.writeU32(zip64Offset ? ZIP32_SENTINEL : localOffsets[i]);
      cdWriter.writeBytes(p.nameBytes);
      cdWriter.writeBytes(centralExtraData);
    }
    const cdData: Uint8Array = cdWriter.build();

    // === End of Central Directory ===
    const forceZip64Archive: boolean = forceZip64 === true;
    const zip64EntryCount: boolean = forceZip64Archive || prepared.length > 0xFFFE;
    const zip64CdSize: boolean = cdData.length >= ZIP32_SENTINEL;
    const zip64CdOffset: boolean = localData.length >= ZIP32_SENTINEL;
    const needsZip64: boolean = zip64EntryCount || zip64CdSize || zip64CdOffset;
    const zip64Records = new ByteWriter();
    if (needsZip64) {
      const zip64EocdOffset: number = localData.length + cdData.length;
      zip64Records.writeU32(SIG_ZIP64_EOCD);
      zip64Records.writeU64(44);                      // record payload size
      zip64Records.writeU16(45);                      // version made by
      zip64Records.writeU16(45);                      // version needed
      zip64Records.writeU32(0);                       // disk number
      zip64Records.writeU32(0);                       // cd start disk
      zip64Records.writeU64(prepared.length);         // entries this disk
      zip64Records.writeU64(prepared.length);         // total entries
      zip64Records.writeU64(cdData.length);           // cd size
      zip64Records.writeU64(localData.length);        // cd offset
      zip64Records.writeU32(SIG_ZIP64_LOCATOR);
      zip64Records.writeU32(0);                       // disk containing Zip64 EOCD
      zip64Records.writeU64(zip64EocdOffset);
      zip64Records.writeU32(1);                       // total disks
    }
    const zip64Data: Uint8Array = zip64Records.build();
    const eocd = new ByteWriter();
    eocd.writeU32(SIG_EOCD);
    eocd.writeU16(0);                                 // disk number
    eocd.writeU16(0);                                 // cd start disk
    eocd.writeU16(zip64EntryCount ? ZIP16_SENTINEL : prepared.length);
    eocd.writeU16(zip64EntryCount ? ZIP16_SENTINEL : prepared.length);
    eocd.writeU32(zip64CdSize ? ZIP32_SENTINEL : cdData.length);
    eocd.writeU32(zip64CdOffset ? ZIP32_SENTINEL : localData.length);
    eocd.writeU16(0);                                 // comment len

    const eocdData: Uint8Array = eocd.build();
    const result = new Uint8Array(localData.length + cdData.length + zip64Data.length + eocdData.length);
    result.set(localData, 0);
    result.set(cdData, localData.length);
    result.set(zip64Data, localData.length + cdData.length);
    result.set(eocdData, localData.length + cdData.length + zip64Data.length);
    return result;
  }
}

// === ZipReader ===
interface CentralDirectoryInfo {
  entryCount: number;
  cdSize: number;
  cdOffset: number;
}

function readCentralDirectoryInfo(data: Uint8Array, eocd: number): CentralDirectoryInfo | null {
  const diskNumber: number = readU16(data, eocd + 4);
  const cdDiskNumber: number = readU16(data, eocd + 6);
  const entriesOnDisk16: number = readU16(data, eocd + 8);
  const entryCount16: number = readU16(data, eocd + 10);
  const cdSize32: number = readU32(data, eocd + 12);
  const cdOffset32: number = readU32(data, eocd + 16);
  if (diskNumber !== 0 || cdDiskNumber !== 0) {
    return null;
  }
  const needsZip64: boolean = entriesOnDisk16 === ZIP16_SENTINEL || entryCount16 === ZIP16_SENTINEL ||
    cdSize32 === ZIP32_SENTINEL || cdOffset32 === ZIP32_SENTINEL;
  if (!needsZip64) {
    return entriesOnDisk16 === entryCount16
      ? { entryCount: entryCount16, cdSize: cdSize32, cdOffset: cdOffset32 } : null;
  }
  const locatorOffset: number = eocd - 20;
  if (locatorOffset < 0 || readU32(data, locatorOffset) !== SIG_ZIP64_LOCATOR ||
    readU32(data, locatorOffset + 4) !== 0 || readU32(data, locatorOffset + 16) !== 1) {
    return null;
  }
  const zip64EocdOffset: number | null = readU64(data, locatorOffset + 8);
  if (zip64EocdOffset === null || zip64EocdOffset + 56 > locatorOffset ||
    readU32(data, zip64EocdOffset) !== SIG_ZIP64_EOCD) {
    return null;
  }
  const recordSize: number | null = readU64(data, zip64EocdOffset + 4);
  if (recordSize === null || recordSize < 44 || zip64EocdOffset + 12 + recordSize > locatorOffset ||
    readU32(data, zip64EocdOffset + 16) !== 0 || readU32(data, zip64EocdOffset + 20) !== 0) {
    return null;
  }
  const entriesOnDisk: number | null = readU64(data, zip64EocdOffset + 24);
  const entryCount: number | null = readU64(data, zip64EocdOffset + 32);
  const cdSize: number | null = readU64(data, zip64EocdOffset + 40);
  const cdOffset: number | null = readU64(data, zip64EocdOffset + 48);
  if (entriesOnDisk === null || entryCount === null || cdSize === null || cdOffset === null ||
    entriesOnDisk !== entryCount) {
    return null;
  }
  return { entryCount: entryCount, cdSize: cdSize, cdOffset: cdOffset };
}

export class ZipReader {
  // Central Directory 损坏返回 null；条目级损坏记录到 failed 并继续恢复其它条目。
  static async parse(data: Uint8Array): Promise<ZipParseResult | null> {
    try {
      if (data.length < 22) {
        return null;
      }
      // 1. 定位 EOCD（末尾 64KB 内搜索）
      const eocd = findEocd(data);
      if (eocd === null) {
        return null;
      }
      const directoryInfo: CentralDirectoryInfo | null = readCentralDirectoryInfo(data, eocd);
      if (directoryInfo === null) {
        return null;
      }
      const entryCount: number = directoryInfo.entryCount;
      const cdSize: number = directoryInfo.cdSize;
      const cdOffset: number = directoryInfo.cdOffset;
      if (entryCount > ZIP_MAX_ENTRY_COUNT || cdOffset > data.length || cdSize > data.length - cdOffset ||
        cdOffset + cdSize > eocd) {
        return null;
      }
      // 2. 遍历 Central Directory
      const entries: ZipEntry[] = [];
      const failed: string[] = [];
      const encrypted: string[] = [];
      const names: Set<string> = new Set<string>();
      let totalUncompressedSize: number = 0;
      let pos: number = cdOffset;
      for (let i = 0; i < entryCount; i++) {
        if (pos + 46 > data.length || readU32(data, pos) !== SIG_CENTRAL) {
          return null;
        }
        const flags: number = readU16(data, pos + 8);
        const method: number = readU16(data, pos + 10);
        const crc: number = readU32(data, pos + 16);
        let csize: number = readU32(data, pos + 20);
        let usize: number = readU32(data, pos + 24);
        const nameLen: number = readU16(data, pos + 28);
        const extraLen: number = readU16(data, pos + 30);
        const commentLen: number = readU16(data, pos + 32);
        let diskStart: number = readU16(data, pos + 34);
        let localOffset: number = readU32(data, pos + 42);
        const nextPos: number = pos + 46 + nameLen + extraLen + commentLen;
        if (nextPos > cdOffset + cdSize || nextPos > data.length) {
          return null;
        }
        const needZip64Usize: boolean = usize === ZIP32_SENTINEL;
        const needZip64Csize: boolean = csize === ZIP32_SENTINEL;
        const needZip64Offset: boolean = localOffset === ZIP32_SENTINEL;
        const needZip64Disk: boolean = diskStart === ZIP16_SENTINEL;
        if (needZip64Usize || needZip64Csize || needZip64Offset || needZip64Disk) {
          const zip64: Zip64ExtraValues | null = readZip64Extra(data, pos + 46 + nameLen, extraLen,
            needZip64Usize, needZip64Csize, needZip64Offset, needZip64Disk);
          if (zip64 === null) {
            return null;
          }
          usize = needZip64Usize ? zip64.usize : usize;
          csize = needZip64Csize ? zip64.csize : csize;
          localOffset = needZip64Offset ? zip64.localOffset : localOffset;
          diskStart = needZip64Disk ? zip64.diskStart : diskStart;
        }
        const nameBytes: Uint8Array = data.slice(pos + 46, pos + 46 + nameLen);
        const name: string = (flags & FLAG_UTF8) !== 0
          ? decodeUtf8(data, pos + 46, nameLen) : decodeCp437(data, pos + 46, nameLen);
        if (diskStart !== 0 || names.has(name) || usize > ZIP_MAX_ENTRY_UNCOMPRESSED_SIZE ||
          totalUncompressedSize > ZIP_MAX_TOTAL_UNCOMPRESSED_SIZE - usize ||
          (usize >= ZIP_RATIO_BUDGET_MIN_SIZE && csize === 0) ||
          (usize >= ZIP_RATIO_BUDGET_MIN_SIZE && csize > 0 && usize / csize > ZIP_MAX_COMPRESSION_RATIO)) {
          return null;
        }
        names.add(name);
        totalUncompressedSize += usize;
        try {
          if ((flags & 0x0001) !== 0) {
            encrypted.push(name);
            throw new Error('encrypted ZIP entries are unsupported');
          }
          // 3. Local File Header 定位数据
          if (localOffset + 30 > data.length || readU32(data, localOffset) !== SIG_LOCAL) {
            throw new Error('invalid local file header');
          }
          const localFlags: number = readU16(data, localOffset + 6);
          const localMethod: number = readU16(data, localOffset + 8);
          const localCrc: number = readU32(data, localOffset + 14);
          let localCsize: number = readU32(data, localOffset + 18);
          let localUsize: number = readU32(data, localOffset + 22);
          const lNameLen: number = readU16(data, localOffset + 26);
          const lExtraLen: number = readU16(data, localOffset + 28);
          const dataStart: number = localOffset + 30 + lNameLen + lExtraLen;
          const localNameBytes: Uint8Array = data.slice(localOffset + 30, localOffset + 30 + lNameLen);
          if ((localFlags & FLAG_DATA_DESCRIPTOR) === 0 &&
            (localUsize === ZIP32_SENTINEL || localCsize === ZIP32_SENTINEL)) {
            const localZip64: Zip64ExtraValues | null = readZip64Extra(data, localOffset + 30 + lNameLen,
              lExtraLen, localUsize === ZIP32_SENTINEL, localCsize === ZIP32_SENTINEL, false, false);
            if (localZip64 === null) {
              throw new Error('missing local ZIP64 size extra field');
            }
            localUsize = localUsize === ZIP32_SENTINEL ? localZip64.usize : localUsize;
            localCsize = localCsize === ZIP32_SENTINEL ? localZip64.csize : localCsize;
          }
          if (localFlags !== flags || localMethod !== method || !bytesEqual(localNameBytes, nameBytes) ||
            ((flags & FLAG_DATA_DESCRIPTOR) === 0 &&
              (localCrc !== crc || localCsize !== csize || localUsize !== usize))) {
            throw new Error('local and central headers disagree');
          }
          if (dataStart > cdOffset || csize > cdOffset - dataStart) {
            throw new Error('entry data exceeds archive bounds');
          }
          const compressedData: Uint8Array = data.slice(dataStart, dataStart + csize);
          let content: Uint8Array;
          if (method === METHOD_STORE) {
            content = compressedData;
          } else if (method === METHOD_DEFLATE) {
            content = await inflateRaw(compressedData, usize);
            if (content.length !== usize) {
              throw new Error('uncompressed size mismatch');
            }
          } else {
            throw new Error(`unsupported compression method ${method}`);
          }
          if (content.length !== usize) {
            throw new Error('uncompressed size mismatch');
          }
          if (crc32(content) !== crc) {
            throw new Error('CRC32 mismatch');
          }
          entries.push({ name: name, data: content, compressed: method === METHOD_DEFLATE,
            directory: name.endsWith('/') });
        } catch (e) {
          console.warn(`ZIP entry skipped: ${name}: ${JSON.stringify(e)}`);
          failed.push(name);
        }
        pos = nextPos;
      }
      if (pos !== cdOffset + cdSize) {
        return null;
      }
      return { entries: entries, failed: failed, encrypted: encrypted };
    } catch (e) {
      const message: string = e instanceof Error ? e.message : JSON.stringify(e);
      console.error(`ZIP central directory parse failed: ${message}`);
      return null;
    }
  }

  // 查找指定名称的条目
  static findEntry(entries: ZipEntry[], name: string): ZipEntry | null {
    for (const e of entries) {
      if (e.name === name) {
        return e;
      }
    }
    return null;
  }
}

const CP437_HIGH: number[] = [
  0x00C7, 0x00FC, 0x00E9, 0x00E2, 0x00E4, 0x00E0, 0x00E5, 0x00E7,
  0x00EA, 0x00EB, 0x00E8, 0x00EF, 0x00EE, 0x00EC, 0x00C4, 0x00C5,
  0x00C9, 0x00E6, 0x00C6, 0x00F4, 0x00F6, 0x00F2, 0x00FB, 0x00F9,
  0x00FF, 0x00D6, 0x00DC, 0x00A2, 0x00A3, 0x00A5, 0x20A7, 0x0192,
  0x00E1, 0x00ED, 0x00F3, 0x00FA, 0x00F1, 0x00D1, 0x00AA, 0x00BA,
  0x00BF, 0x2310, 0x00AC, 0x00BD, 0x00BC, 0x00A1, 0x00AB, 0x00BB,
  0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
  0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
  0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F,
  0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
  0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B,
  0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
  0x03B1, 0x00DF, 0x0393, 0x03C0, 0x03A3, 0x03C3, 0x00B5, 0x03C4,
  0x03A6, 0x0398, 0x03A9, 0x03B4, 0x221E, 0x03C6, 0x03B5, 0x2229,
  0x2261, 0x00B1, 0x2265, 0x2264, 0x2320, 0x2321, 0x00F7, 0x2248,
  0x00B0, 0x2219, 0x00B7, 0x221A, 0x207F, 0x00B2, 0x25A0, 0x00A0,
];

function decodeCp437(data: Uint8Array, offset: number, length: number): string {
  let result: string = '';
  for (let i: number = 0; i < length; i++) {
    const value: number = data[offset + i];
    result += String.fromCharCode(value < 0x80 ? value : CP437_HIGH[value - 0x80]);
  }
  return result;
}

function toDosDateTime(timestamp?: number): number[] {
  const millis: number = timestamp !== undefined && Number.isFinite(timestamp) && timestamp > 0
    ? timestamp : Date.now();
  const date = new Date(millis);
  const year: number = Math.max(1980, Math.min(2107, date.getFullYear()));
  const dosTime: number = (date.getHours() << 11) | (date.getMinutes() << 5) |
    Math.floor(date.getSeconds() / 2);
  const dosDate: number = ((year - 1980) << 9) | ((date.getMonth() + 1) << 5) | date.getDate();
  return [dosTime, dosDate];
}

// 从末尾向前搜索 EOCD 签名（ZIP 规范：EOCD 在文件末尾，comment ≤ 65535）
function findEocd(data: Uint8Array): number | null {
  const maxComment: number = 65535;
  const start: number = Math.max(0, data.length - 22 - maxComment);
  for (let i = data.length - 22; i >= start; i--) {
    if (readU32(data, i) === SIG_EOCD) {
      // 校验 comment 长度是否与文件长度一致
      const commentLen: number = readU16(data, i + 20);
      if (i + 22 + commentLen === data.length) {
        return i;
      }
    }
  }
  return null;
}
