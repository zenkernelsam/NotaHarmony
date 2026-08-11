import { describe, expect, it } from '@ohos/hypium';
import {
  compareMaterializedRecordings, MaterializedOriginalRecording,
  OriginalRecordingAssetState, parseOriginalRecordingAssetHashBits,
  parseOriginalRecordingSegments, resolveOriginalRecordingAsset,
} from '../main/ets/data/OriginalRecordingStore';
import { AssetStatus, NoteAsset } from '../main/ets/core/model/AssetTypes';
import { originalAssetStorageHash } from '../main/ets/core/model/ImageBlockGeometry';

const ASSET_BITS: string[] = ['1', '2', '3', '4', '5', '6', '7', '8'];

function asset(status: AssetStatus, path: string | null, fileSize: number = 10,
  mimeType: string = 'audio/mp4'): NoteAsset {
  return { assetHash: originalAssetStorageHash(ASSET_BITS), status: status, noteIds: ['n'],
    fileSize: fileSize, mimeType: mimeType, localPath: path };
}

function recording(timestamp: number, siteId: number, zIndex: string): MaterializedOriginalRecording {
  return {
    id: `${timestamp}:${siteId}`, timestamp: timestamp, siteId: siteId, name: 'Recording',
    startTime: '100', endTime: '200', segments: [{ startTime: '100', endTime: '200' }],
    zIndex: zIndex, assetHashBits: ['1', '2', '3', '4', '5', '6', '7', '8'],
    assetHash: 'hash', assetFileName: 'audio.m4a', assetMimeType: 'audio/mp4',
    assetFileSize: 10, assetState: OriginalRecordingAssetState.PENDING,
    localPath: null, assetError: null,
  };
}

export default function originalRecordingStoreTest() {
  describe('OriginalRecordingStore', () => {
    it('parses original segment uint64 values without Number precision loss', 0, () => {
      const segments = parseOriginalRecordingSegments(
        '[{"startTime":"9007199254740993","endTime":"18446744073709551615"}]',
        '18446744073709551615');
      expect(segments[0].startTime).assertEqual('9007199254740993');
      expect(segments[0].endTime).assertEqual('18446744073709551615');
    });

    it('rejects malformed and out-of-bounds segments', 0, () => {
      expect(() => parseOriginalRecordingSegments('[{"startTime":"20","endTime":"10"}]', '30'))
        .assertThrowError(new Error('recording segment 0 is outside recording bounds'));
      expect(() => parseOriginalRecordingSegments('[{"startTime":"1","endTime":"31"}]', '30'))
        .assertThrowError(new Error('recording segment 0 is outside recording bounds'));
    });

    it('requires the original eight canonical uint64 hash words', 0, () => {
      const bits: string[] = parseOriginalRecordingAssetHashBits(
        '["1","2","3","4","5","6","7","18446744073709551615"]');
      expect(bits.length).assertEqual(8);
      expect(() => parseOriginalRecordingAssetHashBits('["1","2"]'))
        .assertThrowError(new Error('recording asset hash must contain eight uint64 words'));
    });

    it('orders by unsigned z-index then recording identity', 0, () => {
      const values: MaterializedOriginalRecording[] = [
        recording(10, 2, '18446744073709551615'), recording(11, 2, '9'),
        recording(10, 3, '9'), recording(10, 1, '9'),
      ];
      values.sort(compareMaterializedRecordings);
      expect(values[0].timestamp).assertEqual(10);
      expect(values[0].siteId).assertEqual(1);
      expect(values[1].siteId).assertEqual(3);
      expect(values[2].timestamp).assertEqual(11);
      expect(values[3].zIndex).assertEqual('18446744073709551615');
    });

    it('does not treat missing, pending, failed or conflicting assets as ready', 0, () => {
      expect(resolveOriginalRecordingAsset(ASSET_BITS, 10, 'audio/mp4', []).state)
        .assertEqual(OriginalRecordingAssetState.MISSING);
      expect(resolveOriginalRecordingAsset(ASSET_BITS, 10, 'audio/mp4',
        [asset(AssetStatus.PENDING, null)]).state).assertEqual(OriginalRecordingAssetState.PENDING);
      expect(resolveOriginalRecordingAsset(ASSET_BITS, 10, 'audio/mp4',
        [asset(AssetStatus.FAILED, 'bad.m4a')]).state).assertEqual(OriginalRecordingAssetState.FAILED);
      expect(resolveOriginalRecordingAsset(ASSET_BITS, 10, 'audio/mp4',
        [asset(AssetStatus.LOCAL, 'ready.m4a', 11)]).state)
        .assertEqual(OriginalRecordingAssetState.FAILED);
    });

    it('exposes a matching local asset as ready', 0, () => {
      const resolved = resolveOriginalRecordingAsset(ASSET_BITS, 10, 'audio/mp4',
        [asset(AssetStatus.DOWNLOADED, 'ready.m4a')]);
      expect(resolved.state).assertEqual(OriginalRecordingAssetState.READY);
      expect(resolved.localPath).assertEqual('ready.m4a');
    });
  });
}
