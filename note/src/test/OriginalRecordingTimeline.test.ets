import { describe, expect, it } from '@ohos/hypium';
import {
  buildOriginalRecordingTimeline, locateOriginalRecordingTimeline,
  nextTimelineRecordingId, originalRecordingEffectiveDurationMs,
  timelinePositionForRecording,
} from '../main/ets/core/adaptation/OriginalRecordingTimeline';
import {
  MaterializedOriginalRecording, OriginalRecordingAssetState,
} from '../main/ets/data/OriginalRecordingStore';
import { OriginalRecordingSegment } from '../main/ets/data/OriginalRecordingOperation';

export default function originalRecordingTimelineTest() {
  describe('OriginalRecordingTimeline', () => {
    it('uses the first segment and exposes only internal cumulative boundaries', 0, () => {
      const recordings: MaterializedOriginalRecording[] = [
        recording('first', '1000', '4000', [], OriginalRecordingAssetState.READY),
        recording('second', '0', '1000', [{ startTime: '100', endTime: '600' }],
          OriginalRecordingAssetState.READY),
        recording('missing', '0', '9000', [], OriginalRecordingAssetState.MISSING),
      ];
      const timeline = buildOriginalRecordingTimeline(recordings);
      expect(timeline.entries.length).assertEqual(2);
      expect(timeline.totalDurationMs).assertEqual(3500);
      expect(timeline.boundaryTimesMs.length).assertEqual(1);
      expect(timeline.boundaryTimesMs[0]).assertEqual(3000);
    });

    it('maps exact boundaries to the next recording and total to the final end', 0, () => {
      const timeline = buildOriginalRecordingTimeline([
        recording('first', '0', '3000', [], OriginalRecordingAssetState.READY),
        recording('second', '0', '500', [], OriginalRecordingAssetState.READY),
      ]);
      const boundary = locateOriginalRecordingTimeline(timeline, 3000);
      if (boundary === null) {
        throw new Error('boundary location is absent');
      }
      expect(boundary.recordingId).assertEqual('second');
      expect(boundary.localPositionMs).assertEqual(0);
      const end = locateOriginalRecordingTimeline(timeline, 9999);
      if (end === null) {
        throw new Error('end location is absent');
      }
      expect(end.recordingId).assertEqual('second');
      expect(end.localPositionMs).assertEqual(500);
      expect(timelinePositionForRecording(timeline, 'second', 250)).assertEqual(3250);
      expect(nextTimelineRecordingId(timeline, 'first')).assertEqual('second');
      expect(nextTimelineRecordingId(timeline, 'second')).assertNull();
    });

    it('subtracts large uint64 absolute timestamps without precision loss', 0, () => {
      const value = recording('large', '18446744073709551600', '18446744073709551615', [],
        OriginalRecordingAssetState.READY);
      expect(originalRecordingEffectiveDurationMs(value)).assertEqual(15);
    });
  });
}

function recording(id: string, startTime: string, endTime: string,
  segments: OriginalRecordingSegment[],
  assetState: OriginalRecordingAssetState): MaterializedOriginalRecording {
  return {
    id: id, timestamp: 1, siteId: 1, name: id, startTime: startTime, endTime: endTime,
    segments: segments, zIndex: '1', assetHashBits: ['0', '0', '0', '0', '0', '0', '0', '0'],
    assetHash: id, assetFileName: `${id}.m4a`, assetMimeType: 'audio/mp4', assetFileSize: 1,
    assetState: assetState, localPath: assetState === OriginalRecordingAssetState.READY ? id : null,
    assetError: null,
  };
}
