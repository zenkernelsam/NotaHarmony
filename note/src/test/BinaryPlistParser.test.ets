import { describe, it, expect } from '@ohos/hypium';
import { BinaryPlistParser, PlistParseResult } from '../main/ets/data/BinaryPlistParser';

const MAGIC_BYTES: number[] = [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30];

function writeU32BE(data: Uint8Array, offset: number, value: number): void {
  data[offset] = Math.floor(value / 0x1000000) & 0xFF;
  data[offset + 1] = Math.floor(value / 0x10000) & 0xFF;
  data[offset + 2] = Math.floor(value / 0x100) & 0xFF;
  data[offset + 3] = value & 0xFF;
}

function writeU64BE(data: Uint8Array, offset: number, value: number): void {
  const high: number = Math.floor(value / 4294967296);
  const low: number = value - high * 4294967296;
  writeU32BE(data, offset, high);
  writeU32BE(data, offset + 4, low);
}

function buildPlist(objects: number[][], topIndex: number = 0,
  offsetOverrides: number[] | null = null): Uint8Array {
  const offsets: number[] = [];
  let objectEnd: number = MAGIC_BYTES.length;
  for (const object of objects) {
    offsets.push(objectEnd);
    objectEnd += object.length;
  }
  const offsetTableOffset: number = objectEnd;
  const result: Uint8Array = new Uint8Array(offsetTableOffset + objects.length + 32);
  for (let i: number = 0; i < MAGIC_BYTES.length; i++) {
    result[i] = MAGIC_BYTES[i];
  }
  for (let i: number = 0; i < objects.length; i++) {
    const object: number[] = objects[i];
    for (let j: number = 0; j < object.length; j++) {
      result[offsets[i] + j] = object[j];
    }
    result[offsetTableOffset + i] = offsetOverrides === null ? offsets[i] : offsetOverrides[i];
  }
  const trailer: number = result.length - 32;
  result[trailer + 6] = 1;
  result[trailer + 7] = 1;
  writeU64BE(result, trailer + 8, objects.length);
  writeU64BE(result, trailer + 16, topIndex);
  writeU64BE(result, trailer + 24, offsetTableOffset);
  return result;
}

function parseObject(object: number[]): PlistParseResult {
  return BinaryPlistParser.parse(buildPlist([object]));
}

export default function binaryPlistParserTest() {
  describe('BinaryPlistParser hardening', () => {
    it('accepts every supported standard marker including UTF-8 strings', 0, () => {
      const objects: number[][] = [
        [0x00], [0x08], [0x09], [0x10, 0x2A],
        [0x22, 0x3F, 0x80, 0x00, 0x00],
        [0x33, 0, 0, 0, 0, 0, 0, 0, 0], [0x41, 0x7F], [0x51, 0x41],
        [0x73, 0xE4, 0xB8, 0xAD], [0x61, 0x00, 0x41], [0x80, 0x00],
        [0xA0], [0xB0], [0xC0], [0xD0],
      ];
      for (const object of objects) {
        const result: PlistParseResult = parseObject(object);
        expect(result.error).assertEqual('');
        expect(result.value !== null).assertTrue();
      }
      expect(parseObject([0x73, 0xE4, 0xB8, 0xAD]).value?.asString('')).assertEqual('中');
      expect(parseObject([0x74, 0xF0, 0x9F, 0x98, 0x80]).value?.asString('')).assertEqual('😀');
    });

    it('accepts supported URL and UUID marker payloads', 0, () => {
      const absoluteUrl: PlistParseResult = BinaryPlistParser.parse(
        buildPlist([[0x0C, 0x01], [0x53, 0x61, 0x62, 0x63]]));
      const relativeUrl: PlistParseResult = BinaryPlistParser.parse(
        buildPlist([[0x0D, 0x01, 0x02], [0x54, 0x62, 0x61, 0x73, 0x65], [0x53, 0x72, 0x65, 0x6C]]));
      const uuid: PlistParseResult = parseObject(
        [0x0E, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
      expect(absoluteUrl.error).assertEqual('');
      expect(absoluteUrl.value?.asString('')).assertEqual('abc');
      expect(relativeUrl.error).assertEqual('');
      expect(relativeUrl.value?.asString('')).assertEqual('rel');
      expect(uuid.error).assertEqual('');
      expect(uuid.value?.asData()?.length).assertEqual(16);
    });

    it('rejects an object offset that points into the bplist00 header', 0, () => {
      const result: PlistParseResult = BinaryPlistParser.parse(buildPlist([[0x00]], 0, [0]));
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('对象偏移越界') >= 0).assertTrue();
    });

    it('propagates a bad child reference instead of inserting null and succeeding', 0, () => {
      const result: PlistParseResult = BinaryPlistParser.parse(buildPlist([[0xA1, 0x01]]));
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('对象下标越界') >= 0).assertTrue();
    });

    it('keeps a true cycle as an explicit warning and null placeholder', 0, () => {
      const result: PlistParseResult = BinaryPlistParser.parse(buildPlist([[0xA1, 0x00]]));
      expect(result.error).assertEqual('');
      expect(result.warnings.length).assertEqual(1);
      expect(result.value?.arrayItems()[0].isNull()).assertTrue();
    });

    it('rejects pseudo-date markers outside the standard 0x33 marker', 0, () => {
      const result: PlistParseResult = parseObject([0x30, 0, 0, 0, 0, 0, 0, 0, 0]);
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('非标准') >= 0).assertTrue();
    });

    it('rejects an extended scalar length before allocation or range multiplication', 0, () => {
      const result: PlistParseResult = parseObject([0x4F, 0x12, 0xFF, 0xFF, 0xFF, 0xFF]);
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('安全预算') >= 0).assertTrue();
    });

    it('rejects overlong and malformed UTF-8 instead of manufacturing text', 0, () => {
      const overlong: PlistParseResult = parseObject([0x72, 0xC0, 0x80]);
      const surrogate: PlistParseResult = parseObject([0x73, 0xED, 0xA0, 0x80]);
      const tooLarge: PlistParseResult = parseObject([0x74, 0xF4, 0x90, 0x80, 0x80]);
      expect(overlong.value === null).assertTrue();
      expect(overlong.error.indexOf('utf8') >= 0).assertTrue();
      expect(surrogate.value === null).assertTrue();
      expect(tooLarge.value === null).assertTrue();
    });

    it('rejects unpaired UTF-16 surrogate code units', 0, () => {
      const high: PlistParseResult = parseObject([0x61, 0xD8, 0x00]);
      const low: PlistParseResult = parseObject([0x61, 0xDC, 0x00]);
      expect(high.value === null).assertTrue();
      expect(high.error.indexOf('utf16') >= 0).assertTrue();
      expect(low.value === null).assertTrue();
    });

    it('rejects UID values outside the JavaScript safe integer range', 0, () => {
      const result: PlistParseResult = parseObject([0x87, 0x00, 0x20, 0, 0, 0, 0, 0, 0]);
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('安全整数') >= 0).assertTrue();
    });

    it('rejects containers deeper than the configured safety limit', 0, () => {
      const objects: number[][] = [];
      for (let i: number = 0; i < 65; i++) {
        objects.push([0xA1, i + 1]);
      }
      objects.push([0x00]);
      const result: PlistParseResult = BinaryPlistParser.parse(buildPlist(objects));
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('嵌套超过安全上限') >= 0).assertTrue();
    });

    it('rejects non-string dictionary keys as structural corruption', 0, () => {
      const result: PlistParseResult = BinaryPlistParser.parse(
        buildPlist([[0xD1, 0x01, 0x02], [0x10, 0x01], [0x00]]));
      expect(result.value === null).assertTrue();
      expect(result.error.indexOf('dict key') >= 0).assertTrue();
    });
  });
}
