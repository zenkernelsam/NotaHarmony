import { describe, expect, it } from '@ohos/hypium';
import {
  formatRecordingTime, shouldShowRecordingTimeline,
} from '../main/ets/ui/editor/RecordingPanel';

export default function recordingPanelTest() {
  describe('RecordingPanel', () => {
    it('formats progress without locale-dependent clock behavior', 0, () => {
      expect(formatRecordingTime(0)).assertEqual('0:00');
      expect(formatRecordingTime(65000)).assertEqual('1:05');
      expect(formatRecordingTime(3661000)).assertEqual('1:01:01');
    });

    it('normalizes invalid progress values', 0, () => {
      expect(formatRecordingTime(-1)).assertEqual('0:00');
      expect(formatRecordingTime(Number.NaN)).assertEqual('0:00');
    });

    it('keeps only the timeline conditional on a selected recording', 0, () => {
      expect(shouldShowRecordingTimeline(null)).assertFalse();
      expect(shouldShowRecordingTimeline('recording-id')).assertTrue();
    });
  });
}
