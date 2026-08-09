// T-032 Apple CFBinaryPlist (bplist00) 解析器
// 纯 ArkTS，无平台依赖（禁止 import @ohos.* / @kit.*），供 Notability .note 导入使用。
//
// 格式（Apple CFBinaryPlist v0）：
//   [0..7]        magic "bplist00"
//   [8..N]        对象区：每个对象首字节高 4 位为类型标记，低 4 位为长度/尺寸
//   [offsetTable] numObjects 个偏移，每个 offsetIntSize 字节，大端
//   [末尾 32 字节] trailer
//
// trailer 布局（32 字节）：
//   0..5   unused
//   6      offsetIntSize
//   7      objectRefSize
//   8..15  numObjects        (u64 BE)
//   16..23 topObjectIndex    (u64 BE)
//   24..31 offsetTableOffset (u64 BE)
//
// 注意：plist 容器内的整数/浮点/偏移全部为 **大端**；
//      但 NSData 负载（如 Notability 的 curvespoints）是 iOS 内存直存，为 **小端**，
//      因此下方字节工具同时提供 BE/LE 两种读法。
// 注意：ArkTS 不支持 DataView，所有多字节数值均手工拼字节 + 手工 IEEE-754 解码。

// ============================ 字节工具（导出供其它解析器复用）============================

// 读无符号大端整数。8 字节值拆成高低 32 位；超出 JS 安全整数时饱和，
// 调用方必须先按字段语义做范围校验。
export function uintBE(data: Uint8Array, offset: number, size: number): number {
  if (size === 8) {
    const hi: number = uintBE(data, offset, 4);
    const lo: number = uintBE(data, offset + 4, 4);
    if (hi > 0x1FFFFF) {
      return Number.MAX_SAFE_INTEGER;
    }
    return hi * 4294967296.0 + lo;
  }
  let value: number = 0;
  for (let i = 0; i < size; i++) {
    value = value * 256 + (data[offset + i] & 0xFF);
  }
  return value;
}

// 读无符号小端 32 位整数
export function uint32LE(data: Uint8Array, offset: number): number {
  return ((data[offset] & 0xFF) | ((data[offset + 1] & 0xFF) << 8) |
    ((data[offset + 2] & 0xFF) << 16) | ((data[offset + 3] & 0xFF) << 24)) >>> 0;
}

// IEEE-754 单精度解码（手工，兼容任意平台字节序）
export function float32From(data: Uint8Array, offset: number, littleEndian: boolean): number {
  let b0: number;
  let b1: number;
  let b2: number;
  let b3: number;
  if (littleEndian) {
    b0 = data[offset + 3] & 0xFF;
    b1 = data[offset + 2] & 0xFF;
    b2 = data[offset + 1] & 0xFF;
    b3 = data[offset] & 0xFF;
  } else {
    b0 = data[offset] & 0xFF;
    b1 = data[offset + 1] & 0xFF;
    b2 = data[offset + 2] & 0xFF;
    b3 = data[offset + 3] & 0xFF;
  }
  const sign: number = (b0 & 0x80) !== 0 ? -1 : 1;
  const exponent: number = ((b0 & 0x7F) << 1) | (b1 >>> 7);
  const mantissa: number = ((b1 & 0x7F) << 16) | (b2 << 8) | b3;
  if (exponent === 0) {
    // 非规格化数
    return sign * mantissa * Math.pow(2, -149);
  }
  if (exponent === 0xFF) {
    return mantissa === 0 ? sign * Number.POSITIVE_INFINITY : Number.NaN;
  }
  return sign * (1 + mantissa / 8388608.0) * Math.pow(2, exponent - 127);
}

// IEEE-754 双精度解码（手工）
export function float64From(data: Uint8Array, offset: number, littleEndian: boolean): number {
  const b: number[] = [];
  for (let i = 0; i < 8; i++) {
    b.push(data[offset + (littleEndian ? 7 - i : i)] & 0xFF);
  }
  const sign: number = (b[0] & 0x80) !== 0 ? -1 : 1;
  const exponent: number = ((b[0] & 0x7F) << 4) | (b[1] >>> 4);
  // 52 位尾数拆成高 20 位 + 低 32 位，避免 32 位移位溢出
  const hi: number = ((b[1] & 0x0F) << 16) | (b[2] << 8) | b[3];
  const lo: number = (((b[4] << 24) | (b[5] << 16) | (b[6] << 8) | b[7]) >>> 0);
  const mantissa: number = hi * 4294967296.0 + lo;
  if (exponent === 0) {
    return sign * mantissa * Math.pow(2, -1074);
  }
  if (exponent === 0x7FF) {
    return mantissa === 0 ? sign * Number.POSITIVE_INFINITY : Number.NaN;
  }
  return sign * (1 + mantissa / 4503599627370496.0) * Math.pow(2, exponent - 1023);
}

// ============================ plist 值模型 ============================

export enum PlistType {
  NULL = 0,
  BOOL = 1,
  INT = 2,
  REAL = 3,
  DATE = 4,
  DATA = 5,
  STRING = 6,
  UID = 7,
  ARRAY = 8,
  SET = 9,
  DICT = 10,
}

// 标记联合体：ArkTS 对 union 支持受限，这里用带 type 标签的类承载全部 plist 类型
export class PlistValue {
  readonly type: PlistType;
  private num: number = 0;
  private flag: boolean = false;
  private text: string = '';
  private bytes: Uint8Array | null = null;
  private items: PlistValue[] | null = null;
  private keyNames: string[] | null = null;
  private keyValues: PlistValue[] | null = null;

  constructor(type: PlistType) {
    this.type = type;
  }

  static ofNull(): PlistValue {
    return new PlistValue(PlistType.NULL);
  }

  static ofBool(value: boolean): PlistValue {
    const v = new PlistValue(PlistType.BOOL);
    v.flag = value;
    return v;
  }

  static ofNumber(type: PlistType, value: number): PlistValue {
    const v = new PlistValue(type);
    v.num = value;
    return v;
  }

  static ofString(value: string): PlistValue {
    const v = new PlistValue(PlistType.STRING);
    v.text = value;
    return v;
  }

  static ofData(value: Uint8Array): PlistValue {
    const v = new PlistValue(PlistType.DATA);
    v.bytes = value;
    return v;
  }

  static ofArray(type: PlistType, value: PlistValue[]): PlistValue {
    const v = new PlistValue(type);
    v.items = value;
    return v;
  }

  static ofDict(keys: string[], values: PlistValue[]): PlistValue {
    const v = new PlistValue(PlistType.DICT);
    v.keyNames = keys;
    v.keyValues = values;
    return v;
  }

  // ---- 访问器（类型不符时返回默认值，不抛异常）----

  isNull(): boolean {
    return this.type === PlistType.NULL;
  }

  asNumber(fallback: number): number {
    if (this.type === PlistType.INT || this.type === PlistType.REAL ||
      this.type === PlistType.DATE || this.type === PlistType.UID) {
      return this.num;
    }
    if (this.type === PlistType.BOOL) {
      return this.flag ? 1 : 0;
    }
    return fallback;
  }

  asBool(fallback: boolean): boolean {
    if (this.type === PlistType.BOOL) {
      return this.flag;
    }
    if (this.type === PlistType.INT) {
      return this.num !== 0;
    }
    return fallback;
  }

  asString(fallback: string): string {
    return this.type === PlistType.STRING ? this.text : fallback;
  }

  asData(): Uint8Array | null {
    return this.type === PlistType.DATA ? this.bytes : null;
  }

  // UID 值即 $objects 数组下标；非 UID 返回 -1
  asUid(): number {
    return this.type === PlistType.UID ? this.num : -1;
  }

  arrayItems(): PlistValue[] {
    return this.items !== null ? this.items : [];
  }

  isContainer(): boolean {
    return this.type === PlistType.ARRAY || this.type === PlistType.SET || this.type === PlistType.DICT;
  }

  dictKeys(): string[] {
    return this.keyNames !== null ? this.keyNames : [];
  }

  dictGet(key: string): PlistValue | null {
    if (this.keyNames === null || this.keyValues === null) {
      return null;
    }
    for (let i = 0; i < this.keyNames.length; i++) {
      if (this.keyNames[i] === key) {
        return this.keyValues[i];
      }
    }
    return null;
  }

  dictHas(key: string): boolean {
    return this.dictGet(key) !== null;
  }

  // 结构摘要（用于探测日志）
  describe(): string {
    switch (this.type) {
      case PlistType.NULL: return 'null';
      case PlistType.BOOL: return this.flag ? 'true' : 'false';
      case PlistType.INT: return `int(${this.num})`;
      case PlistType.REAL: return `real(${this.num})`;
      case PlistType.DATE: return `date(${this.num})`;
      case PlistType.DATA: return `data(len=${this.bytes !== null ? this.bytes.length : 0})`;
      case PlistType.STRING: return `"${this.text.length > 48 ? this.text.substring(0, 48) + '…' : this.text}"`;
      case PlistType.UID: return `UID(${this.num})`;
      case PlistType.ARRAY: return `array(${this.items !== null ? this.items.length : 0})`;
      case PlistType.SET: return `set(${this.items !== null ? this.items.length : 0})`;
      case PlistType.DICT: return `dict(${this.keyNames !== null ? this.keyNames.length : 0})`;
      default: return 'unknown';
    }
  }
}

export class PlistParseResult {
  value: PlistValue | null = null;
  error: string = '';
  warnings: string[] = [];
}

// ============================ 解析器 ============================

const MAGIC: string = 'bplist00';
const TRAILER_SIZE: number = 32;
const MAX_OBJECT_COUNT: number = 250000;
const MAX_DATA_BYTES: number = 64 * 1024 * 1024;
const MAX_STRING_STORAGE_BYTES: number = 16 * 1024 * 1024;
const MAX_TOTAL_ALLOCATION_BYTES: number = 128 * 1024 * 1024;
const MAX_CONTAINER_ITEMS: number = 250000;
const MAX_OBJECT_DEPTH: number = 64;

export class BinaryPlistParser {
  // 解析 bplist00；任何异常/损坏都返回带 error 的结果，绝不抛出
  static parse(data: Uint8Array): PlistParseResult {
    const out = new PlistParseResult();
    try {
      if (data === null || data.length < MAGIC.length + TRAILER_SIZE) {
        out.error = '数据过短，不是有效的 binary plist';
        return out;
      }
      for (let i = 0; i < MAGIC.length; i++) {
        if (data[i] !== MAGIC.charCodeAt(i)) {
          out.error = '缺少 bplist00 魔数（可能是 XML plist 或非 plist 文件）';
          return out;
        }
      }
      const t: number = data.length - TRAILER_SIZE;
      const offsetIntSize: number = data[t + 6] & 0xFF;
      const objectRefSize: number = data[t + 7] & 0xFF;
      if (uintBE(data, t + 8, 4) > 0x1FFFFF || uintBE(data, t + 16, 4) > 0x1FFFFF ||
        uintBE(data, t + 24, 4) > 0x1FFFFF) {
        out.error = 'trailer 含超出 JavaScript 安全整数范围的 64 位字段';
        return out;
      }
      const numObjects: number = uintBE(data, t + 8, 8);
      const topIndex: number = uintBE(data, t + 16, 8);
      const offsetTableOffset: number = uintBE(data, t + 24, 8);

      if (offsetIntSize < 1 || offsetIntSize > 8 || objectRefSize < 1 || objectRefSize > 8) {
        out.error = `trailer 尺寸字段非法 offsetIntSize=${offsetIntSize} objectRefSize=${objectRefSize}`;
        return out;
      }
      if (numObjects <= 0 || topIndex >= numObjects) {
        out.error = `trailer 对象数非法 numObjects=${numObjects} top=${topIndex}`;
        return out;
      }
      if (numObjects > MAX_OBJECT_COUNT) {
        out.error = `对象数超出安全预算 ${numObjects} > ${MAX_OBJECT_COUNT}`;
        return out;
      }
      if (offsetTableOffset < MAGIC.length || offsetTableOffset > t ||
        !rangeWithin(offsetTableOffset, numObjects, offsetIntSize, t)) {
        out.error = '偏移表越界';
        return out;
      }

      // 读取偏移表
      const offsets: number[] = [];
      for (let i = 0; i < numObjects; i++) {
        const objectOffset: number = uintBE(data, offsetTableOffset + i * offsetIntSize, offsetIntSize);
        if (objectOffset < MAGIC.length || objectOffset >= offsetTableOffset) {
          out.error = `对象偏移越界 index=${i} offset=${objectOffset}`;
          return out;
        }
        offsets.push(objectOffset);
      }

      const ctx = new ParseContext(data, offsets, objectRefSize, offsetTableOffset);
      const root: PlistValue | null = ctx.objectAt(topIndex, 0);
      for (let i: number = 0; i < ctx.warnings.length; i++) {
        out.warnings.push(ctx.warnings[i]);
      }
      if (root === null || ctx.error.length > 0) {
        out.error = ctx.error.length > 0 ? ctx.error : '根对象解析失败';
        return out;
      }
      out.value = root;
      return out;
    } catch (e) {
      out.error = `binary plist 解析异常: ${JSON.stringify(e)}`;
      return out;
    }
  }
}

function rangeWithin(start: number, count: number, unitSize: number, limit: number): boolean {
  if (!Number.isSafeInteger(start) || !Number.isSafeInteger(count) || !Number.isSafeInteger(unitSize) ||
    start < 0 || count < 0 || unitSize < 0 || start > limit) {
    return false;
  }
  if (unitSize === 0) {
    return count === 0;
  }
  return count <= Math.floor((limit - start) / unitSize);
}

// 解析上下文：负责按下标解码对象，带记忆化与递归深度保护
class ParseContext {
  private data: Uint8Array;
  private offsets: number[];
  private refSize: number;
  private limit: number;                    // 对象区上界（偏移表起点之前）
  private cache: Map<number, PlistValue> = new Map<number, PlistValue>();
  private visiting: Set<number> = new Set<number>();
  private allocatedBytes: number = 0;
  error: string = '';
  warnings: string[] = [];

  constructor(data: Uint8Array, offsets: number[], refSize: number, limit: number) {
    this.data = data;
    this.offsets = offsets;
    this.refSize = refSize;
    this.limit = limit;
  }

  objectAt(index: number, depth: number): PlistValue | null {
    if (this.error.length > 0) {
      return null;
    }
    if (index < 0 || index >= this.offsets.length) {
      this.fail(`对象下标越界 ${index}`);
      return null;
    }
    const cached: PlistValue | undefined = this.cache.get(index);
    if (cached !== undefined) {
      return cached;
    }
    if (depth > MAX_OBJECT_DEPTH) {
      this.fail(`对象嵌套超过安全上限 ${MAX_OBJECT_DEPTH}`);
      return null;
    }
    if (this.visiting.has(index)) {
      const warning: string = `检测到循环对象引用 index=${index}，已用 null 占位`;
      if (this.warnings.indexOf(warning) < 0) {
        this.warnings.push(warning);
      }
      return PlistValue.ofNull();
    }
    this.visiting.add(index);
    const value: PlistValue | null = this.decode(this.offsets[index], depth);
    this.visiting.delete(index);
    if (value !== null) {
      this.cache.set(index, value);
    }
    return value;
  }

  private decode(pos: number, depth: number): PlistValue | null {
    if (pos < MAGIC.length || pos >= this.limit) {
      this.fail(`对象偏移越界 ${pos}`);
      return null;
    }
    const marker: number = this.data[pos] & 0xFF;
    const high: number = marker >>> 4;
    const low: number = marker & 0x0F;

    switch (high) {
      case 0x0:
        if (low === 0x0) {
          return PlistValue.ofNull();
        }
        if (low === 0x8) {
          return PlistValue.ofBool(false);
        }
        if (low === 0x9) {
          return PlistValue.ofBool(true);
        }
        if (low === 0xF) {
          return PlistValue.ofNull();   // fill byte
        }
        if (low === 0xC || low === 0xD) {
          const refCount: number = low === 0xC ? 1 : 2;
          if (!rangeWithin(pos + 1, refCount, this.refSize, this.limit)) {
            this.fail('URL 对象引用越界');
            return null;
          }
          // URLWithBase 的首个引用是 base，最后一个引用是 URL 字符串。
          const stringRefOffset: number = pos + 1 + (refCount - 1) * this.refSize;
          const stringRef: number = uintBE(this.data, stringRefOffset, this.refSize);
          const stringValue: PlistValue | null = this.objectAt(stringRef, depth + 1);
          if (stringValue === null || stringValue.type !== PlistType.STRING) {
            this.fail('URL 对象的字符串引用无效');
            return null;
          }
          return PlistValue.ofString(stringValue.asString(''));
        }
        if (low === 0xE) {
          if (!rangeWithin(pos + 1, 1, 16, this.limit)) {
            this.fail('UUID 对象越界');
            return null;
          }
          if (!this.reserve(16, 'UUID')) {
            return null;
          }
          return PlistValue.ofData(this.data.slice(pos + 1, pos + 17));
        }
        this.fail(`未知的 0x0 系标记 0x${marker.toString(16)}`);
        return null;

      case 0x1: {
        // int：字节数 = 2^low；8 字节按有符号处理（bplist 规范）
        const size: number = 1 << low;
        if (size > 8 || !rangeWithin(pos + 1, 1, size, this.limit)) {
          this.fail(`int 长度非法 size=${size}`);
          return null;
        }
        let v: number;
        if (size === 8) {
          const hi: number = uintBE(this.data, pos + 1, 4);
          const lo: number = uintBE(this.data, pos + 5, 4);
          v = (hi & 0x80000000) !== 0
            ? (hi - 4294967296.0) * 4294967296.0 + lo
            : hi * 4294967296.0 + lo;
          if (!Number.isSafeInteger(v)) {
            this.fail('64 位整数超出 JavaScript 安全整数范围');
            return null;
          }
        } else {
          v = uintBE(this.data, pos + 1, size);
        }
        return PlistValue.ofNumber(PlistType.INT, v);
      }

      case 0x2: {
        const size: number = 1 << low;
        if (!rangeWithin(pos + 1, 1, size, this.limit)) {
          this.fail(`real 长度非法 size=${size}`);
          return null;
        }
        if (size === 4) {
          return PlistValue.ofNumber(PlistType.REAL, float32From(this.data, pos + 1, false));
        }
        if (size === 8) {
          return PlistValue.ofNumber(PlistType.REAL, float64From(this.data, pos + 1, false));
        }
        this.fail(`不支持的 real 宽度 ${size}`);
        return null;
      }

      case 0x3: {
        // date：8 字节 double，Core Data 纪元（2001-01-01 起的秒数）
        if (low !== 0x3) {
          this.fail(`date marker 非标准 0x33：0x${marker.toString(16)}`);
          return null;
        }
        if (!rangeWithin(pos + 1, 1, 8, this.limit)) {
          this.fail('date 越界');
          return null;
        }
        return PlistValue.ofNumber(PlistType.DATE, float64From(this.data, pos + 1, false));
      }

      case 0x4: {
        const len: LengthRead | null = this.readLength(pos, low);
        if (len === null) {
          return null;
        }
        const start: number = len.next;
        if (!this.validateDataLength(len.count) ||
          !rangeWithin(start, len.count, 1, this.limit)) {
          this.fail('data 越界或超出安全预算');
          return null;
        }
        if (!this.reserve(len.count, 'data')) {
          return null;
        }
        return PlistValue.ofData(this.data.slice(start, start + len.count));
      }

      case 0x5: {
        // ASCII 字符串
        const len: LengthRead | null = this.readLength(pos, low);
        if (len === null) {
          return null;
        }
        if (!this.validateStringLength(len.count, 1, 'ascii string') ||
          !rangeWithin(len.next, len.count, 1, this.limit)) {
          this.fail('ascii string 越界或超出安全预算');
          return null;
        }
        if (!this.reserve(len.count * 2, 'ascii string')) {
          return null;
        }
        const chunks: string[] = [];
        let chunk: string = '';
        for (let i = 0; i < len.count; i++) {
          const code: number = this.data[len.next + i] & 0xFF;
          if (code > 0x7F) {
            this.fail(`ascii string 含非 ASCII 字节 @${i}`);
            return null;
          }
          chunk += String.fromCharCode(code);
          if (chunk.length >= 4096) {
            chunks.push(chunk);
            chunk = '';
          }
        }
        chunks.push(chunk);
        return PlistValue.ofString(chunks.join(''));
      }

      case 0x6: {
        // UTF-16BE 字符串，count 为字符（码元）数
        const len: LengthRead | null = this.readLength(pos, low);
        if (len === null) {
          return null;
        }
        if (!this.validateStringLength(len.count, 2, 'utf16 string') ||
          !rangeWithin(len.next, len.count, 2, this.limit)) {
          this.fail('utf16 string 越界或超出安全预算');
          return null;
        }
        if (!this.reserve(len.count * 2, 'utf16 string')) {
          return null;
        }
        const chunks: string[] = [];
        let chunk: string = '';
        for (let i = 0; i < len.count; i++) {
          const p: number = len.next + i * 2;
          const codeUnit: number = ((this.data[p] & 0xFF) << 8) | (this.data[p + 1] & 0xFF);
          if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
            if (i + 1 >= len.count) {
              this.fail(`utf16 string 含孤立高代理项 @${i}`);
              return null;
            }
            const nextPos: number = p + 2;
            const nextCodeUnit: number = ((this.data[nextPos] & 0xFF) << 8) |
              (this.data[nextPos + 1] & 0xFF);
            if (nextCodeUnit < 0xDC00 || nextCodeUnit > 0xDFFF) {
              this.fail(`utf16 string 含孤立高代理项 @${i}`);
              return null;
            }
            chunk += String.fromCharCode(codeUnit, nextCodeUnit);
            i++;
          } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
            this.fail(`utf16 string 含孤立低代理项 @${i}`);
            return null;
          } else {
            chunk += String.fromCharCode(codeUnit);
          }
          if (chunk.length >= 4096) {
            chunks.push(chunk);
            chunk = '';
          }
        }
        chunks.push(chunk);
        return PlistValue.ofString(chunks.join(''));
      }

      case 0x7: {
        const len: LengthRead | null = this.readLength(pos, low);
        if (len === null) {
          return null;
        }
        if (!this.validateStringLength(len.count, 1, 'utf8 string') ||
          !rangeWithin(len.next, len.count, 1, this.limit)) {
          this.fail('utf8 string 越界或超出安全预算');
          return null;
        }
        if (!this.reserve(len.count * 2, 'utf8 string')) {
          return null;
        }
        const decoded: string | null = this.decodeUtf8(len.next, len.count);
        return decoded === null ? null : PlistValue.ofString(decoded);
      }

      case 0x8: {
        // UID：字节数 = low + 1
        const size: number = low + 1;
        if (size > 8 || !rangeWithin(pos + 1, 1, size, this.limit)) {
          this.fail('uid 越界或宽度超出安全整数');
          return null;
        }
        if (size === 8 && uintBE(this.data, pos + 1, 4) > 0x1FFFFF) {
          this.fail('UID 超出 JavaScript 安全整数范围');
          return null;
        }
        const uid: number = uintBE(this.data, pos + 1, size);
        if (!Number.isSafeInteger(uid)) {
          this.fail('UID 超出 JavaScript 安全整数范围');
          return null;
        }
        return PlistValue.ofNumber(PlistType.UID, uid);
      }

      case 0xA:
      case 0xB:
      case 0xC: {
        const len: LengthRead | null = this.readLength(pos, low);
        if (len === null) {
          return null;
        }
        if (!this.validateContainerLength(len.count, 'array/set') ||
          !rangeWithin(len.next, len.count, this.refSize, this.limit)) {
          this.fail('array/set 越界或超出安全预算');
          return null;
        }
        if (!this.reserve(len.count * 8, 'array/set')) {
          return null;
        }
        const items: PlistValue[] = [];
        for (let i = 0; i < len.count; i++) {
          const ref: number = uintBE(this.data, len.next + i * this.refSize, this.refSize);
          const child: PlistValue | null = this.objectAt(ref, depth + 1);
          if (child === null) {
            return null;
          }
          items.push(child);
        }
        return PlistValue.ofArray(high === 0xC ? PlistType.SET : PlistType.ARRAY, items);
      }

      case 0xD: {
        const len: LengthRead | null = this.readLength(pos, low);
        if (len === null) {
          return null;
        }
        const keyBase: number = len.next;
        if (!this.validateContainerLength(len.count, 'dict') ||
          !rangeWithin(keyBase, len.count, this.refSize * 2, this.limit)) {
          this.fail('dict 越界或超出安全预算');
          return null;
        }
        const valBase: number = keyBase + len.count * this.refSize;
        if (!this.reserve(len.count * 16, 'dict')) {
          return null;
        }
        const keys: string[] = [];
        const values: PlistValue[] = [];
        for (let i = 0; i < len.count; i++) {
          const kRef: number = uintBE(this.data, keyBase + i * this.refSize, this.refSize);
          const vRef: number = uintBE(this.data, valBase + i * this.refSize, this.refSize);
          const kv: PlistValue | null = this.objectAt(kRef, depth + 1);
          const vv: PlistValue | null = this.objectAt(vRef, depth + 1);
          if (kv === null || vv === null) {
            return null;
          }
          if (kv.type !== PlistType.STRING) {
            this.fail(`dict key 不是字符串 ref=${kRef}`);
            return null;
          }
          keys.push(kv.asString(''));
          values.push(vv);
        }
        return PlistValue.ofDict(keys, values);
      }

      default:
        this.fail(`未知对象标记 0x${marker.toString(16)} @${pos}`);
        return null;
    }
  }

  private validateDataLength(count: number): boolean {
    if (!Number.isSafeInteger(count) || count < 0 || count > MAX_DATA_BYTES) {
      this.fail(`data 长度超出安全预算 count=${count}`);
      return false;
    }
    return true;
  }

  private validateStringLength(count: number, unitSize: number, label: string): boolean {
    if (!Number.isSafeInteger(count) || count < 0 || unitSize <= 0 ||
      count > Math.floor(MAX_STRING_STORAGE_BYTES / unitSize)) {
      this.fail(`${label} 长度超出安全预算 count=${count}`);
      return false;
    }
    return true;
  }

  private validateContainerLength(count: number, label: string): boolean {
    if (!Number.isSafeInteger(count) || count < 0 || count > MAX_CONTAINER_ITEMS) {
      this.fail(`${label} 元素数超出安全预算 count=${count}`);
      return false;
    }
    return true;
  }

  private reserve(bytes: number, label: string): boolean {
    if (!Number.isSafeInteger(bytes) || bytes < 0 ||
      bytes > MAX_TOTAL_ALLOCATION_BYTES - this.allocatedBytes) {
      this.fail(`${label} 使总分配量超出安全预算 ${MAX_TOTAL_ALLOCATION_BYTES}`);
      return false;
    }
    this.allocatedBytes += bytes;
    return true;
  }

  private decodeUtf8(start: number, count: number): string | null {
    const end: number = start + count;
    const chunks: string[] = [];
    let chunk: string = '';
    let index: number = start;
    while (index < end) {
      const first: number = this.data[index] & 0xFF;
      let codePoint: number;
      let width: number;
      if (first <= 0x7F) {
        codePoint = first;
        width = 1;
      } else if (first >= 0xC2 && first <= 0xDF) {
        width = 2;
        if (index + width > end || !isUtf8Continuation(this.data[index + 1] & 0xFF)) {
          this.fail(`utf8 string 含非法双字节序列 @${index - start}`);
          return null;
        }
        codePoint = ((first & 0x1F) << 6) | (this.data[index + 1] & 0x3F);
      } else if (first >= 0xE0 && first <= 0xEF) {
        width = 3;
        if (index + width > end) {
          this.fail(`utf8 string 被截断 @${index - start}`);
          return null;
        }
        const second: number = this.data[index + 1] & 0xFF;
        const third: number = this.data[index + 2] & 0xFF;
        const validSecond: boolean = first === 0xE0 ? second >= 0xA0 && second <= 0xBF :
          first === 0xED ? second >= 0x80 && second <= 0x9F : isUtf8Continuation(second);
        if (!validSecond || !isUtf8Continuation(third)) {
          this.fail(`utf8 string 含非法三字节序列 @${index - start}`);
          return null;
        }
        codePoint = ((first & 0x0F) << 12) | ((second & 0x3F) << 6) | (third & 0x3F);
      } else if (first >= 0xF0 && first <= 0xF4) {
        width = 4;
        if (index + width > end) {
          this.fail(`utf8 string 被截断 @${index - start}`);
          return null;
        }
        const second: number = this.data[index + 1] & 0xFF;
        const third: number = this.data[index + 2] & 0xFF;
        const fourth: number = this.data[index + 3] & 0xFF;
        const validSecond: boolean = first === 0xF0 ? second >= 0x90 && second <= 0xBF :
          first === 0xF4 ? second >= 0x80 && second <= 0x8F : isUtf8Continuation(second);
        if (!validSecond || !isUtf8Continuation(third) || !isUtf8Continuation(fourth)) {
          this.fail(`utf8 string 含非法四字节序列 @${index - start}`);
          return null;
        }
        codePoint = ((first & 0x07) << 18) | ((second & 0x3F) << 12) |
          ((third & 0x3F) << 6) | (fourth & 0x3F);
      } else {
        this.fail(`utf8 string 含非法起始字节 0x${first.toString(16)} @${index - start}`);
        return null;
      }
      if (codePoint <= 0xFFFF) {
        chunk += String.fromCharCode(codePoint);
      } else {
        const adjusted: number = codePoint - 0x10000;
        chunk += String.fromCharCode(0xD800 + (adjusted >>> 10), 0xDC00 + (adjusted & 0x3FF));
      }
      if (chunk.length >= 4096) {
        chunks.push(chunk);
        chunk = '';
      }
      index += width;
    }
    chunks.push(chunk);
    return chunks.join('');
  }

  private fail(message: string): void {
    if (this.error.length === 0) {
      this.error = message;
    }
  }

  // 读取容器/字符串/data 的长度：low==0xF 时长度另存为一个 int 对象紧随其后
  private readLength(pos: number, low: number): LengthRead | null {
    if (low !== 0x0F) {
      const r = new LengthRead();
      r.count = low;
      r.next = pos + 1;
      return r;
    }
    if (pos + 1 >= this.limit) {
      this.fail('长度字段越界');
      return null;
    }
    const sizeMarker: number = this.data[pos + 1] & 0xFF;
    if ((sizeMarker >>> 4) !== 0x1) {
      this.fail(`长度标记非 int：0x${sizeMarker.toString(16)}`);
      return null;
    }
    const size: number = 1 << (sizeMarker & 0x0F);
    if (size > 8 || !rangeWithin(pos + 2, 1, size, this.limit)) {
      this.fail(`长度字段越界 size=${size}`);
      return null;
    }
    const r = new LengthRead();
    r.count = uintBE(this.data, pos + 2, size);
    if (!Number.isSafeInteger(r.count)) {
      this.fail('长度字段超出 JavaScript 安全整数范围');
      return null;
    }
    r.next = pos + 2 + size;
    return r;
  }
}

function isUtf8Continuation(value: number): boolean {
  return value >= 0x80 && value <= 0xBF;
}

class LengthRead {
  count: number = 0;
  next: number = 0;
}

// Core Data 纪元（2001-01-01T00:00:00Z）转 Unix 毫秒
export function appleTimeToUnixMillis(appleSeconds: number): number {
  return Math.round((appleSeconds + 978307200) * 1000);
}
