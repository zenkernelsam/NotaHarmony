import { describe, expect, it } from '@ohos/hypium';
import {
  clampRecordingSeek, isSupportedRecordingPlaybackSpeed,
  OriginalRecordingPlaybackSpeed, OriginalRecordingPlaybackState,
} from '../main/ets/core/adaptation/OriginalRecordingPlaybackController';

export default function originalRecordingPlaybackControllerTest() {
  describe('OriginalRecordingPlaybackController', () => {
    it('clamps seek targets to the prepared media duration', 0, () => {
      expect(clampRecordingSeek(-1, 100)).assertEqual(0);
      expect(clampRecordingSeek(24.6, 100)).assertEqual(25);
      expect(clampRecordingSeek(101, 100)).assertEqual(100);
    });

    it('rejects non-finite positions and invalid durations', 0, () => {
      expect(clampRecordingSeek(Number.NaN, 100)).assertEqual(0);
      expect(clampRecordingSeek(20, 0)).assertEqual(0);
      expect(clampRecordingSeek(20, Number.MAX_SAFE_INTEGER + 1)).assertEqual(0);
    });

    it('keeps stable public playback state ordinals', 0, () => {
      expect(OriginalRecordingPlaybackState.IDLE).assertEqual(0);
      expect(OriginalRecordingPlaybackState.COMPLETED).assertEqual(5);
      expect(OriginalRecordingPlaybackState.RELEASED).assertEqual(7);
    });

    it('accepts only the three playback speeds exposed by the original app', 0, () => {
      expect(isSupportedRecordingPlaybackSpeed(
        OriginalRecordingPlaybackSpeed.SPEED_1_0)).assertTrue();
      expect(isSupportedRecordingPlaybackSpeed(
        OriginalRecordingPlaybackSpeed.SPEED_1_5)).assertTrue();
      expect(isSupportedRecordingPlaybackSpeed(
        OriginalRecordingPlaybackSpeed.SPEED_2_0)).assertTrue();
      expect(isSupportedRecordingPlaybackSpeed(3 as OriginalRecordingPlaybackSpeed)).assertFalse();
    });
  });
}
