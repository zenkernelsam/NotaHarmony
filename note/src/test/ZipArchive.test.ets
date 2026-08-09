import { describe, it, expect } from '@ohos/hypium';
import { util } from '@kit.ArkTS';
import { ZipEntry, ZipParseResult, ZipReader, ZipWriter } from '../main/ets/data/ZipArchive';

function expectBytesEqual(actual: Uint8Array, expected: Uint8Array): void {
  expect(actual.length).assertEqual(expected.length);
  for (let i: number = 0; i < expected.length; i++) {
    expect(actual[i]).assertEqual(expected[i]);
  }
}

function readU16(data: Uint8Array, offset: number): number {
  return data[offset] | (data[offset + 1] << 8);
}

function readU32(data: Uint8Array, offset: number): number {
  return (data[offset] | (data[offset + 1] << 8) | (data[offset + 2] << 16) |
    (data[offset + 3] << 24)) >>> 0;
}

function readU64(data: Uint8Array, offset: number): number {
  return readU32(data, offset + 4) * 0x100000000 + readU32(data, offset);
}

function writeU16(data: Uint8Array, offset: number, value: number): void {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >>> 8) & 0xFF;
}

function writeU32(data: Uint8Array, offset: number, value: number): void {
  data[offset] = value & 0xFF;
  data[offset + 1] = (value >>> 8) & 0xFF;
  data[offset + 2] = (value >>> 16) & 0xFF;
  data[offset + 3] = (value >>> 24) & 0xFF;
}

function clearUtf8Flags(data: Uint8Array): void {
  const eocdOffset: number = data.length - 22;
  const entryCount: number = readU16(data, eocdOffset + 10);
  let centralOffset: number = readU32(data, eocdOffset + 16);
  for (let i: number = 0; i < entryCount; i++) {
    const localOffset: number = readU32(data, centralOffset + 42);
    writeU16(data, centralOffset + 8, readU16(data, centralOffset + 8) & ~0x0800);
    writeU16(data, localOffset + 6, readU16(data, localOffset + 6) & ~0x0800);
    centralOffset += 46 + readU16(data, centralOffset + 28) + readU16(data, centralOffset + 30) +
      readU16(data, centralOffset + 32);
  }
}

export default function zipArchiveTest() {
  describe('ZipArchive', () => {
    it('round trips STORE, DEFLATE and UTF-8 names', 0, async () => {
      const encoder = new util.TextEncoder();
      const stored: Uint8Array = encoder.encodeInto('stored bytes');
      const compressible: Uint8Array = encoder.encodeInto('NotaHarmony '.repeat(512));
      const writer = new ZipWriter();
      const timestamp: number = 946684800000;
      writer.addEntry('plain.bin', stored, false, timestamp);
      writer.addEntry('pages/page_0.json', compressible, true);
      writer.addEntry('中文/标题.txt', encoder.encodeInto('你好，Notability'), true);
      writer.addDirectory('pages', timestamp);

      const archive: Uint8Array = await writer.build();
      const parsed: ZipParseResult | null = await ZipReader.parse(archive);
      expect(parsed === null).assertEqual(false);
      if (parsed === null) {
        return;
      }
      const entries: ZipEntry[] = parsed.entries;

      expect(entries.length).assertEqual(4);
      expect(parsed.failed.length).assertEqual(0);
      expect(parsed.encrypted.length).assertEqual(0);
      expect(readU16(archive, 12) > 0).assertEqual(true);
      const directory: ZipEntry | null = ZipReader.findEntry(entries, 'pages/');
      expect(directory !== null && directory.directory === true).assertEqual(true);
      expectBytesEqual(ZipReader.findEntry(entries, 'plain.bin')!.data, stored);
      const deflated: ZipEntry | null = ZipReader.findEntry(entries, 'pages/page_0.json');
      expect(deflated === null).assertEqual(false);
      if (deflated !== null) {
        expect(deflated.compressed).assertEqual(true);
        expectBytesEqual(deflated.data, compressible);
      }
      const utf8: ZipEntry | null = ZipReader.findEntry(entries, '中文/标题.txt');
      expect(utf8 === null).assertEqual(false);
      if (utf8 !== null) {
        expectBytesEqual(utf8.data, encoder.encodeInto('你好，Notability'));
      }

      // Clear bit 11 and inject CP437 0x82 ('é') in both file-name records.
      const legacy: Uint8Array = archive.slice();
      const eocdOffset: number = legacy.length - 22;
      const centralOffset: number = readU32(legacy, eocdOffset + 16);
      legacy[6] = 0;
      legacy[7] = 0;
      legacy[30] = 0x82;
      legacy[centralOffset + 8] = 0;
      legacy[centralOffset + 9] = 0;
      legacy[centralOffset + 46] = 0x82;
      const legacyParsed: ZipParseResult | null = await ZipReader.parse(legacy);
      expect(legacyParsed === null).assertEqual(false);
      if (legacyParsed !== null) {
        expect(ZipReader.findEntry(legacyParsed.entries, 'élain.bin') === null).assertEqual(false);
      }

      // A broken noncritical entry must not discard the rest of the archive.
      const damaged: Uint8Array = archive.slice();
      const storedDataOffset: number = 30 + encoder.encodeInto('plain.bin').length;
      damaged[storedDataOffset] = damaged[storedDataOffset] ^ 0xFF;
      const recovered: ZipParseResult | null = await ZipReader.parse(damaged);
      expect(recovered === null).assertEqual(false);
      if (recovered !== null) {
        expect(recovered.failed.length).assertEqual(1);
        expect(recovered.failed[0]).assertEqual('plain.bin');
        expect(recovered.entries.length).assertEqual(3);
        expect(ZipReader.findEntry(recovered.entries, 'pages/page_0.json') === null).assertEqual(false);
      }
    });

    it('rejects duplicate names, split archives and unsafe expansion metadata', 0, async () => {
      const encoder = new util.TextEncoder();
      const writer = new ZipWriter();
      writer.addEntry('a.bin', encoder.encodeInto('a'), false);
      writer.addEntry('b.bin', encoder.encodeInto('b'), false);
      const archive: Uint8Array = await writer.build();
      clearUtf8Flags(archive);
      const eocdOffset: number = archive.length - 22;
      const centralOffset: number = readU32(archive, eocdOffset + 16);
      const secondCentralOffset: number = centralOffset + 46 + 5;
      const secondLocalOffset: number = readU32(archive, secondCentralOffset + 42);

      const duplicate: Uint8Array = archive.slice();
      duplicate[secondCentralOffset + 46] = 'a'.charCodeAt(0);
      duplicate[secondLocalOffset + 30] = 'a'.charCodeAt(0);
      expect(await ZipReader.parse(duplicate) === null).assertEqual(true);

      const split: Uint8Array = archive.slice();
      writeU16(split, eocdOffset + 4, 1);
      expect(await ZipReader.parse(split) === null).assertEqual(true);

      const expansion: Uint8Array = archive.slice();
      writeU32(expansion, centralOffset + 24, 2 * 1024 * 1024);
      expect(await ZipReader.parse(expansion) === null).assertEqual(true);

      const duplicateWriter = new ZipWriter();
      duplicateWriter.addEntry('same', new Uint8Array(0), false);
      duplicateWriter.addEntry('same', new Uint8Array(0), false);
      let duplicateWriteRejected: boolean = false;
      try {
        await duplicateWriter.build();
      } catch (_e) {
        duplicateWriteRejected = true;
      }
      expect(duplicateWriteRejected).assertEqual(true);
    });

    it('skips an entry whose local and central headers disagree', 0, async () => {
      const encoder = new util.TextEncoder();
      const writer = new ZipWriter();
      writer.addEntry('safe.bin', encoder.encodeInto('payload'), false);
      const archive: Uint8Array = await writer.build();
      clearUtf8Flags(archive);
      const mismatched: Uint8Array = archive.slice();
      writeU16(mismatched, 8, 8);
      const parsed: ZipParseResult | null = await ZipReader.parse(mismatched);
      expect(parsed === null).assertEqual(false);
      if (parsed !== null) {
        expect(parsed.entries.length).assertEqual(0);
        expect(parsed.failed.length).assertEqual(1);
      }
    });

    it('reads a legal ZIP64 archive and its 0x0001 size and offset extra', 0, async () => {
      const payload: Uint8Array = new Uint8Array([1, 2, 3, 4]);
      const writer = new ZipWriter();
      writer.addEntry('zip64.bin', payload, false);
      const archive: Uint8Array = await writer.build(true);
      const eocdOffset: number = archive.length - 22;
      const locatorOffset: number = eocdOffset - 20;
      const zip64EocdOffset: number = readU64(archive, locatorOffset + 8);
      const centralOffset: number = readU64(archive, zip64EocdOffset + 48);
      const nameLength: number = readU16(archive, centralOffset + 28);

      expect(readU32(archive, zip64EocdOffset)).assertEqual(0x06064b50);
      expect(readU32(archive, locatorOffset)).assertEqual(0x07064b50);
      expect(readU16(archive, eocdOffset + 10)).assertEqual(0xFFFF);
      expect(readU32(archive, centralOffset + 20)).assertEqual(0xFFFFFFFF);
      expect(readU16(archive, centralOffset + 46 + nameLength)).assertEqual(0x0001);

      writeU16(archive, 6, readU16(archive, 6) & ~0x0800);
      writeU16(archive, centralOffset + 8, readU16(archive, centralOffset + 8) & ~0x0800);
      const parsed: ZipParseResult | null = await ZipReader.parse(archive);
      expect(parsed === null).assertEqual(false);
      if (parsed !== null) {
        expect(parsed.entries.length).assertEqual(1);
        if (parsed.entries.length === 1) {
          expectBytesEqual(parsed.entries[0].data, payload);
        }
      }
    });
  });
}
