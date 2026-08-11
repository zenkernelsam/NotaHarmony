import { describe, expect, it } from '@ohos/hypium';
import {
  recordingOpenPrecondition, validateRecordingAssetFileSize,
} from '../main/ets/core/adaptation/OriginalRecordingAssetLoader';
import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../main/ets/data/OriginalRecordingStore';

function recording(state: OriginalRecordingAssetState,
  localPath: string | null = null): MaterializedOriginalRecording {
  return {
    id: '1:1', timestamp: 1, siteId: 1, name: 'Recording', startTime: '0', endTime: '10',
    segments: [], zIndex: '0', assetHashBits: ['1', '2', '3', '4', '5', '6', '7', '8'],
    assetHash: 'hash', assetFileName: 'audio.m4a', assetMimeType: 'audio/mp4',
    assetFileSize: 10, assetState: state, localPath: localPath, assetError: 'unavailable',
  };
}

export default function originalRecordingAssetLoaderTest() {
  describe('OriginalRecordingAssetLoader', () => {
    it('preserves non-ready asset states without touching a file', 0, () => {
      const pending = recordingOpenPrecondition(recording(OriginalRecordingAssetState.PENDING));
      expect(pending === null).assertFalse();
      expect(pending?.state).assertEqual(OriginalRecordingAssetState.PENDING);
      expect(pending?.lease === null).assertTrue();
    });

    it('rejects a ready row without a usable path', 0, () => {
      const missingPath = recordingOpenPrecondition(recording(OriginalRecordingAssetState.READY));
      expect(missingPath?.state).assertEqual(OriginalRecordingAssetState.FAILED);
      expect(recordingOpenPrecondition(
        recording(OriginalRecordingAssetState.READY, 'audio.m4a')) === null).assertTrue();
    });

    it('requires a regular, non-empty, exact-size file', 0, () => {
      expect(validateRecordingAssetFileSize(10, 10, true)).assertNull();
      expect(validateRecordingAssetFileSize(10, 10, false))
        .assertEqual('recording asset path is not a regular file');
      expect(validateRecordingAssetFileSize(10, 0, true))
        .assertEqual('recording asset file is empty or has an invalid size');
      expect(validateRecordingAssetFileSize(10, 11, true))
        .assertEqual('recording asset file size does not match metadata');
    });
  });
}
