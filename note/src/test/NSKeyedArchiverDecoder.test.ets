import { describe, it, expect } from '@ohos/hypium';
import { PlistType, PlistValue } from '../main/ets/data/BinaryPlistParser';
import { ArchiveDecodeResult, NSKeyedArchiverDecoder } from '../main/ets/data/NSKeyedArchiverDecoder';

function uid(index: number): PlistValue {
  return PlistValue.ofNumber(PlistType.UID, index);
}

function archive(objects: PlistValue[], archiver: string = 'NSKeyedArchiver',
  version: number = 100000, topValue: PlistValue = uid(1)): PlistValue {
  return PlistValue.ofDict(
    ['$archiver', '$version', '$top', '$objects'],
    [
      PlistValue.ofString(archiver),
      PlistValue.ofNumber(PlistType.INT, version),
      PlistValue.ofDict(['root'], [topValue]),
      PlistValue.ofArray(PlistType.ARRAY, objects),
    ],
  );
}

function byteString(bytes: number[]): PlistValue {
  return PlistValue.ofDict(['NS.bytes'], [PlistValue.ofData(new Uint8Array(bytes))]);
}

export default function nsKeyedArchiverDecoderTest() {
  describe('NSKeyedArchiverDecoder validation', () => {
    it('accepts the standard and evidenced Notability archivers at version 100000', 0, () => {
      const objects: PlistValue[] = [PlistValue.ofString('$null'), PlistValue.ofDict([], [])];
      const standard: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(archive(objects));
      const notability: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(
        archive(objects, 'GLKeyedArchiver'));
      expect(standard.error).assertEqual('');
      expect(standard.decoder?.archiverName).assertEqual('NSKeyedArchiver');
      expect(notability.error).assertEqual('');
      expect(notability.decoder?.archiverName).assertEqual('GLKeyedArchiver');
    });

    it('rejects unknown archivers and unsupported or mistyped versions', 0, () => {
      const objects: PlistValue[] = [PlistValue.ofString('$null'), PlistValue.ofDict([], [])];
      const unknown: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(
        archive(objects, 'UntrustedArchiver'));
      const oldVersion: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(
        archive(objects, 'NSKeyedArchiver', 99999));
      const malformed: PlistValue = PlistValue.ofDict(
        ['$archiver', '$version', '$top', '$objects'],
        [
          PlistValue.ofString('NSKeyedArchiver'), PlistValue.ofString('100000'),
          PlistValue.ofDict(['root'], [uid(1)]), PlistValue.ofArray(PlistType.ARRAY, objects),
        ],
      );
      expect(unknown.decoder === null).assertTrue();
      expect(unknown.error.indexOf('归档器') >= 0).assertTrue();
      expect(oldVersion.decoder === null).assertTrue();
      expect(oldVersion.error.indexOf('版本') >= 0).assertTrue();
      expect(NSKeyedArchiverDecoder.decode(malformed).decoder === null).assertTrue();
    });

    it('rejects out-of-range UIDs in top and nested object fields', 0, () => {
      const basicObjects: PlistValue[] = [PlistValue.ofString('$null'), PlistValue.ofDict([], [])];
      const badTop: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(
        archive(basicObjects, 'NSKeyedArchiver', 100000, uid(2)));
      const nestedObjects: PlistValue[] = [
        PlistValue.ofString('$null'), PlistValue.ofDict(['child'], [uid(3)]),
      ];
      const badNested: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(archive(nestedObjects));
      expect(badTop.decoder === null).assertTrue();
      expect(badTop.error.indexOf('UID 越界') >= 0).assertTrue();
      expect(badNested.decoder === null).assertTrue();
      expect(badNested.error.indexOf('UID 越界') >= 0).assertTrue();
    });

    it('validates every stored dictionary value even when keys repeat', 0, () => {
      const objects: PlistValue[] = [
        PlistValue.ofString('$null'), PlistValue.ofDict(['child', 'child'], [uid(0), uid(3)]),
      ];
      const result: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(archive(objects));
      expect(result.decoder === null).assertTrue();
      expect(result.error.indexOf('UID 越界') >= 0).assertTrue();
    });

    it('decodes valid four-byte UTF-8 from NS.bytes', 0, () => {
      const objects: PlistValue[] = [
        PlistValue.ofString('$null'), byteString([0xF0, 0x9F, 0x98, 0x80]),
      ];
      const result: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(archive(objects));
      expect(result.error).assertEqual('');
      expect(result.decoder?.rootNode()?.asText('')).assertEqual('😀');
    });

    it('rejects every malformed UTF-8 class before exposing a decoder', 0, () => {
      const malformed: number[][] = [
        [0xC0, 0x80],             // overlong NUL
        [0x80],                   // isolated continuation
        [0xED, 0xA0, 0x80],       // UTF-16 surrogate
        [0xF4, 0x90, 0x80, 0x80], // above U+10FFFF
        [0xF0, 0x9F, 0x98],       // truncated sequence
      ];
      for (const bytes of malformed) {
        const objects: PlistValue[] = [PlistValue.ofString('$null'), byteString(bytes)];
        const result: ArchiveDecodeResult = NSKeyedArchiverDecoder.decode(archive(objects));
        expect(result.decoder === null).assertTrue();
        expect(result.error.indexOf('UTF-8') >= 0).assertTrue();
      }
    });
  });
}
