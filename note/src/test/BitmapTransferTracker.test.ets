import { describe, it, expect } from '@ohos/hypium';
import {
  BitmapTransferKind, BitmapTransferMetrics, BitmapTransferTracker,
} from '../main/ets/core/adaptation/BitmapTransferTracker';

export default function bitmapTransferTrackerTest() {
  describe('BitmapTransferTracker', () => {
    it('attributes transfers to the frame that consumes them', 0, () => {
      const tracker: BitmapTransferTracker = new BitmapTransferTracker();
      tracker.recordTransfer(BitmapTransferKind.PENCIL_TINT);
      tracker.finishFrame(false, 2);
      let metrics: BitmapTransferMetrics = tracker.snapshot();
      expect(metrics.frameCount).assertEqual(1);
      expect(metrics.totalTransfers).assertEqual(1);
      expect(metrics.pencilTintTransfers).assertEqual(1);
      expect(metrics.pencilTextureTransfers).assertEqual(0);
      expect(metrics.lastFrameTransfers).assertEqual(1);
      expect(metrics.lastDirtyRegionCount).assertEqual(2);

      tracker.finishFrame(false, 2);
      metrics = tracker.snapshot();
      expect(metrics.lastFrameTransfers).assertEqual(0);
      expect(metrics.maxFrameTransfers).assertEqual(1);
      expect(metrics.maxDirtyRegionCount).assertEqual(2);
    });

    it('counts completed and isolated transfers during a full rebuild frame', 0, () => {
      const tracker: BitmapTransferTracker = new BitmapTransferTracker();
      tracker.recordTransfer(BitmapTransferKind.ISOLATED_MASK);
      tracker.recordTransfer(BitmapTransferKind.ISOLATED_MASK);
      tracker.recordTransfer(BitmapTransferKind.COMPLETED_LAYER);
      tracker.finishFrame(true, 1);
      const metrics: BitmapTransferMetrics = tracker.snapshot();
      expect(metrics.fullFrameCount).assertEqual(1);
      expect(metrics.totalTransfers).assertEqual(3);
      expect(metrics.isolatedMaskTransfers).assertEqual(2);
      expect(metrics.completedLayerTransfers).assertEqual(1);
      expect(metrics.maxFrameTransfers).assertEqual(3);
    });
  });
}
