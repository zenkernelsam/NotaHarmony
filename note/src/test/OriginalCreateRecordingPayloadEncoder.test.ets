import { describe, expect, it } from '@ohos/hypium';
import { originalAssetStorageHash } from '../main/ets/core/model/ImageBlockGeometry';
import {
  originalAssetHashBitsFromSha512, sha512BytesToHex,
} from '../main/ets/data/AssetDigest';
import { encodeOriginalLocalCreateRecording } from
  '../main/ets/data/OriginalCreateRecordingPayloadEncoder';
import {
  decodeOriginalCreateRecordingTable, OriginalCreateRecordingPayload,
} from '../main/ets/data/OriginalRecordingOperation';
import { persistCapturedOriginalRecording } from
  '../main/ets/data/OriginalRecordingPersistence';
import { OriginalFlatBufferTableReader } from
  '../main/ets/data/OriginalSyncedOperationFlatBuffer';

export default function originalCreateRecordingPayloadEncoderTest() {
  describe('OriginalCreateRecordingPayloadEncoder', () => {
    it('maps SHA-512 bytes to original little-endian uint64 words', 0, () => {
      expect(persistCapturedOriginalRecording !== undefined).assertTrue();
      const digest: Uint8Array = new Uint8Array(64);
      for (let index: number = 0; index < digest.length; index++) {
        digest[index] = index;
      }
      const bits: string[] = originalAssetHashBitsFromSha512(digest);
      expect(bits.length).assertEqual(8);
      expect(bits[0]).assertEqual('506097522914230528');
      expect(bits[7]).assertEqual('4557147201846524216');
      expect(originalAssetStorageHash(bits)).assertEqual(sha512BytesToHex(digest));
    });

    it('round-trips the original local CreateRecording fields', 0, () => {
      const digest: Uint8Array = new Uint8Array(64);
      for (let index: number = 0; index < digest.length; index++) {
        digest[index] = index;
      }
      const bits: string[] = originalAssetHashBitsFromSha512(digest);
      const bytes: Uint8Array = encodeOriginalLocalCreateRecording({
        assetHashBits: bits, fileName: 'recording_20260811_120000.m4a',
        mimeType: 'audio/mp4', fileSize: 4096,
      }, '100000', '101750');
      const decoded: OriginalCreateRecordingPayload = decodeOriginalCreateRecordingTable(
        OriginalFlatBufferTableReader.fromRoot(bytes));
      expect(decoded.metadata.assetHashBits.join(',')).assertEqual(bits.join(','));
      expect(decoded.metadata.fileName).assertEqual('recording_20260811_120000.m4a');
      expect(decoded.metadata.mimeType).assertEqual('audio/mp4');
      expect(decoded.metadata.fileSize).assertEqual(4096);
      expect(decoded.startTime).assertEqual('100000');
      expect(decoded.endTime).assertEqual('101750');
      expect(decoded.name).assertEqual('recording_20260811_120000.m4a');
      expect(decoded.segments === null).assertTrue();
      expect(decoded.zIndex).assertEqual('0');
    });
  });
}
