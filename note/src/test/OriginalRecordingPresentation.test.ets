import { describe, expect, it } from '@ohos/hypium';
import {
  buildOriginalRecordingPresentation, formatOriginalRecordingDuration,
  parseOriginalRecordingDateMilliseconds,
} from '../main/ets/core/adaptation/OriginalRecordingPresentation';
import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../main/ets/data/OriginalRecordingStore';

function recording(startTime: string, endTime: string,
  segmentStart: string | null, segmentEnd: string | null): MaterializedOriginalRecording {
  return {
    id: '1:1', timestamp: 1, siteId: 1, name: 'internal.m4a',
    startTime: startTime, endTime: endTime,
    segments: segmentStart === null || segmentEnd === null ? [] :
      [{ startTime: segmentStart, endTime: segmentEnd }],
    zIndex: '0', assetHashBits: ['0', '0', '0', '0', '0', '0', '0', '0'],
    assetHash: 'hash', assetFileName: 'internal.m4a', assetMimeType: 'audio/mp4',
    assetFileSize: 1, assetState: OriginalRecordingAssetState.READY,
    localPath: '/tmp/internal.m4a', assetError: null,
  };
}

export default function originalRecordingPresentationTest() {
  describe('OriginalRecordingPresentation', () => {
    it('matches the original duration units', 0, () => {
      expect(formatOriginalRecordingDuration(0)).assertEqual('0s');
      expect(formatOriginalRecordingDuration(59000)).assertEqual('59s');
      expect(formatOriginalRecordingDuration(65000)).assertEqual('1m 5s');
      expect(formatOriginalRecordingDuration(3661000)).assertEqual('1h 1m 1s');
    });

    it('uses the first segment duration and date when one exists', 0, () => {
      const presentation = buildOriginalRecordingPresentation(
        recording('1000', '9000', '2500', '6500'));
      expect(presentation.duration).assertEqual('4s');
      expect(presentation.startTimeMs).assertEqual(2500);
    });

    it('rejects unsafe or non-canonical date milliseconds', 0, () => {
      expect(() => parseOriginalRecordingDateMilliseconds('9007199254740992')).assertThrow();
      expect(() => parseOriginalRecordingDateMilliseconds('01')).assertThrow();
    });
  });
}
