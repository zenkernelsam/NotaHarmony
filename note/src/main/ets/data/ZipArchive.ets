// T-026 最小 ZIP 读写器（纯 ArkTS，不引入第三方库）
// 支持 STORE(0) + DEFLATE(8) 两种模式；little-endian；CRC32 查表法；
// 读取走 Central Directory 定位（兼容 data descriptor 标准 ZIP）
import { zlib } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export interface ZipEntry {
  name: string;           // 文件路径（如 "manifest.json"）
  data: Uint8Array;       // 文件内容（已解压）
  compressed: boolean;    // 源条目是否 DEFLATE 压缩
}

// === 常量 ===
const SIG_LOCAL: number = 0x04034b50;
const SIG_CENTRAL: number = 0x02014b50;
const SIG_EOCD: number = 0x06054b50;
const FLAG_UTF8: number = 0x0800;
const METHOD_STORE: number = 0;
const METHOD_DEFLATE: number = 8;

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

// === raw DEFLATE（ZIP 格式要求 RFC1951，windowBits=-15）===
function toArrayBuffer(data: Uint8Array): ArrayBuffer {
  return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) as ArrayBuffer;
}

async function deflateRaw(data: Uint8Array): Promise<Uint8Array> {
  try {
    const input = toArrayBuffer(data);
    const zip: zlib.Zip = zlib.createZipSync();
    const strm: zlib.ZStream = await zip.getZStream();
    strm.nextIn = input;
    strm.availableIn = input.byteLength;
    // deflate 膨胀上界 ≈ input + input/4096*5 + 64（raw 无头更小，留足余量）
    const outCap: number = input.byteLength + (input.byteLength >> 12) * 5 + 64;
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
    await zip.deflateEnd(strm);
    if (status !== zlib.ReturnStatus.STREAM_END && status !== zlib.ReturnStatus.OK) {
      throw new Error('deflate failed: ' + status);
    }
    const outLen: number = strm.totalOut ?? 0;
    return new Uint8Array(outBuf.slice(0, outLen));
  } catch (e) {
    throw new Error('deflateRaw failed: ' + JSON.stringify(e));
  }
}

async function inflateRaw(data: Uint8Array, expectedSize: number): Promise<Uint8Array> {
  try {
    const input = toArrayBuffer(data);
    const zip: zlib.Zip = zlib.createZipSync();
    const strm: zlib.ZStream = await zip.getZStream();
    strm.nextIn = input;
    strm.availableIn = input.byteLength;
    const outCap: number = Math.max(expectedSize, 1024);
    const outBuf = new ArrayBuffer(outCap);
    strm.nextOut = outBuf;
    strm.availableOut = outCap;
    let status: zlib.ReturnStatus = await zip.inflateInit2(strm, -15);
    if (status !== zlib.ReturnStatus.OK) {
      await zip.inflateEnd(strm);
      throw new Error('inflateInit2 failed: ' + status);
    }
    status = await zip.inflate(strm, zlib.CompressFlushMode.FINISH);
    await zip.inflateEnd(strm);
    if (status !== zlib.ReturnStatus.STREAM_END && status !== zlib.ReturnStatus.OK) {
      throw new Error('inflate failed: ' + status);
    }
    const outLen: number = strm.totalOut ?? 0;
    return new Uint8Array(outBuf.slice(0, outLen));
  } catch (e) {
    throw new Error('inflateRaw failed: ' + JSON.stringify(e));
  }
}

// === ZipWriter ===
interface PreparedEntry {
  name: string;
  nameBytes: Uint8Array;
  data: Uint8Array;
  compressed: boolean;
  method: number;
  crc: number;
}

export class ZipWriter {
  private entries: ZipEntry[] = [];

  // 添加条目；compress=false 时 STORE，否则尝试 DEFLATE（压缩无收益自动回退 STORE）
  addEntry(name: string, data: Uint8Array, compress?: boolean): void {
    this.entries.push({ name: name, data: data, compressed: compress !== false });
  }

  // 生成 ZIP 二进制（Local File Header + Central Directory + End Record）
  async build(): Promise<Uint8Array> {
    const prepared: PreparedEntry[] = [];
    for (const e of this.entries) {
      const raw: Uint8Array = e.data;
      const crc: number = crc32(raw);
      let payload: Uint8Array = raw;
      let method: number = METHOD_STORE;
      let compressed: boolean = false;
      if (e.compressed && raw.length > 64) {
        try {
          const deflated: Uint8Array = await deflateRaw(raw);
          if (deflated.length < raw.length) {
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
      prepared.push({
        name: e.name,
        nameBytes: encodeUtf8(e.name),
        data: payload,
        compressed: compressed,
        method: method,
        crc: crc,
      });
    }

    // === Local File Headers + 数据 ===
    const localWriter = new ByteWriter();
    const localOffsets: number[] = [];
    for (const p of prepared) {
      localOffsets.push(localWriter.length());
      localWriter.writeU32(SIG_LOCAL);
      localWriter.writeU16(20);                       // version needed
      localWriter.writeU16(FLAG_UTF8);                // general purpose bit 11 (UTF-8)
      localWriter.writeU16(p.method);                 // compression method
      localWriter.writeU16(0);                        // mod time
      localWriter.writeU16(0);                        // mod date
      localWriter.writeU32(p.crc);                    // crc32
      localWriter.writeU32(p.data.length);            // compressed size
      localWriter.writeU32(p.data.length);            // uncompressed size
      localWriter.writeU16(p.nameBytes.length);       // name len
      localWriter.writeU16(0);                        // extra len
      localWriter.writeBytes(p.nameBytes);
      localWriter.writeBytes(p.data);
    }
    const localData: Uint8Array = localWriter.build();

    // === Central Directory ===
    const cdWriter = new ByteWriter();
    for (let i = 0; i < prepared.length; i++) {
      const p = prepared[i];
      cdWriter.writeU32(SIG_CENTRAL);
      cdWriter.writeU16(20);                          // version made by
      cdWriter.writeU16(20);                          // version needed
      cdWriter.writeU16(FLAG_UTF8);
      cdWriter.writeU16(p.method);
      cdWriter.writeU16(0);                           // mod time
      cdWriter.writeU16(0);                           // mod date
      cdWriter.writeU32(p.crc);
      cdWriter.writeU32(p.data.length);               // compressed size
      cdWriter.writeU32(p.data.length);               // uncompressed size
      cdWriter.writeU16(p.nameBytes.length);
      cdWriter.writeU16(0);                           // extra len
      cdWriter.writeU16(0);                           // comment len
      cdWriter.writeU16(0);                           // disk number start
      cdWriter.writeU16(0);                           // internal attrs
      cdWriter.writeU32(0);                           // external attrs
      cdWriter.writeU32(localOffsets[i]);             // local header offset
      cdWriter.writeBytes(p.nameBytes);
    }
    const cdData: Uint8Array = cdWriter.build();

    // === End of Central Directory ===
    const eocd = new ByteWriter();
    eocd.writeU32(SIG_EOCD);
    eocd.writeU16(0);                                 // disk number
    eocd.writeU16(0);                                 // cd start disk
    eocd.writeU16(prepared.length);                   // entries this disk
    eocd.writeU16(prepared.length);                   // total entries
    eocd.writeU32(cdData.length);                     // cd size
    eocd.writeU32(localData.length);                  // cd offset
    eocd.writeU16(0);                                 // comment len

    const eocdData: Uint8Array = eocd.build();
    const result = new Uint8Array(localData.length + cdData.length + eocdData.length);
    result.set(localData, 0);
    result.set(cdData, localData.length);
    result.set(eocdData, localData.length + cdData.length);
    return result;
  }
}

// === ZipReader ===
export class ZipReader {
  // 从 ZIP 二进制解析所有条目；损坏/非 ZIP 返回 null（不抛异常）
  static async parse(data: Uint8Array): Promise<ZipEntry[] | null> {
    try {
      if (data.length < 22) {
        return null;
      }
      // 1. 定位 EOCD（末尾 64KB 内搜索）
      const eocd = findEocd(data);
      if (eocd === null) {
        return null;
      }
      const entryCount: number = readU16(data, eocd + 10);
      const cdSize: number = readU32(data, eocd + 12);
      const cdOffset: number = readU32(data, eocd + 16);
      if (cdOffset + cdSize > data.length) {
        return null;
      }
      // 2. 遍历 Central Directory
      const entries: ZipEntry[] = [];
      let pos: number = cdOffset;
      for (let i = 0; i < entryCount; i++) {
        if (pos + 46 > data.length || readU32(data, pos) !== SIG_CENTRAL) {
          return null;
        }
        const method: number = readU16(data, pos + 10);
        const crc: number = readU32(data, pos + 16);
        const csize: number = readU32(data, pos + 20);
        const usize: number = readU32(data, pos + 24);
        const nameLen: number = readU16(data, pos + 28);
        const extraLen: number = readU16(data, pos + 30);
        const commentLen: number = readU16(data, pos + 32);
        const localOffset: number = readU32(data, pos + 42);
        const name: string = decodeUtf8(data, pos + 46, nameLen);
        // 3. Local File Header 定位数据
        if (localOffset + 30 > data.length || readU32(data, localOffset) !== SIG_LOCAL) {
          return null;
        }
        const lNameLen: number = readU16(data, localOffset + 26);
        const lExtraLen: number = readU16(data, localOffset + 28);
        const dataStart: number = localOffset + 30 + lNameLen + lExtraLen;
        if (dataStart + csize > data.length) {
          return null;
        }
        const compressedData: Uint8Array = data.slice(dataStart, dataStart + csize);
        // 4. 解压
        let content: Uint8Array;
        if (method === METHOD_STORE) {
          content = compressedData;
        } else if (method === METHOD_DEFLATE) {
          content = await inflateRaw(compressedData, usize);
          if (content.length !== usize) {
            return null;
          }
        } else {
          // 不支持的压缩方法
          return null;
        }
        // 5. CRC32 校验（损坏 → null）
        if (crc32(content) !== crc) {
          return null;
        }
        entries.push({ name: name, data: content, compressed: method === METHOD_DEFLATE });
        pos += 46 + nameLen + extraLen + commentLen;
      }
      return entries;
    } catch (e) {
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
