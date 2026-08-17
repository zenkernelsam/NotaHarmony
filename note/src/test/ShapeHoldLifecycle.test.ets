import { describe, it, expect } from '@ohos/hypium';
import {
  HARMONY_SHAPE_HOLD_FALLBACK_TOUCH_SLOP, ORIGINAL_SHAPE_HOLD_DELAY_MS,
  ORIGINAL_SHAPE_HOLD_FALLBACK_HANDWRITING_SLOP,
  ORIGINAL_SHAPE_HOLD_HANDWRITING_SLOP_MULTIPLIER,
  originalShapeHoldPauseThreshold, ShapeHoldPauseTracker,
} from '../main/ets/core/model/ShapeHoldLifecycle';
import { Point2D } from '../main/ets/core/model/GeometryTypes';

export default function shapeHoldLifecycleTest() {
  describe('ShapeHoldLifecycle', () => {
    it('uses the original 500 ms delay and tool-specific pause slop rule', 0, () => {
      expect(ORIGINAL_SHAPE_HOLD_DELAY_MS).assertEqual(500);
      expect(ORIGINAL_SHAPE_HOLD_FALLBACK_HANDWRITING_SLOP).assertEqual(2);
      expect(HARMONY_SHAPE_HOLD_FALLBACK_TOUCH_SLOP).assertEqual(8);
      expect(ORIGINAL_SHAPE_HOLD_HANDWRITING_SLOP_MULTIPLIER).assertEqual(4);
      expect(originalShapeHoldPauseThreshold(true)).assertEqual(8);
      expect(originalShapeHoldPauseThreshold(false)).assertEqual(8);
      expect(originalShapeHoldPauseThreshold(true, 3)).assertEqual(12);
      expect(originalShapeHoldPauseThreshold(false, 3)).assertEqual(3);
      expect(originalShapeHoldPauseThreshold(true, Number.NaN)).assertEqual(8);
      expect(originalShapeHoldPauseThreshold(false, 0)).assertEqual(8);
    });

    it('keeps the current timer anchor through sub-slop jitter', 0, () => {
      const tracker: ShapeHoldPauseTracker = new ShapeHoldPauseTracker();
      expect(tracker.update({ x: 10, y: 20 }, 8)).assertTrue();
      expect(tracker.update({ x: 13, y: 24 }, 8)).assertFalse();
      const unchanged: Point2D | null = tracker.getAnchor();
      expect(unchanged?.x).assertEqual(10);
      expect(unchanged?.y).assertEqual(20);
      expect(tracker.update({ x: 18, y: 20 }, 8)).assertTrue();
      const moved: Point2D | null = tracker.getAnchor();
      expect(moved?.x).assertEqual(18);
      expect(moved?.y).assertEqual(20);
    });

    it('fails closed for invalid input and clears its anchor on reset', 0, () => {
      const tracker: ShapeHoldPauseTracker = new ShapeHoldPauseTracker();
      expect(tracker.update({ x: 1, y: 2 }, 8)).assertTrue();
      expect(tracker.update({ x: Number.NaN, y: 3 }, 8)).assertFalse();
      expect(tracker.update({ x: 9, y: 2 }, -1)).assertFalse();
      expect(tracker.getAnchor()?.x).assertEqual(1);
      tracker.reset();
      expect(tracker.getAnchor() === null).assertTrue();
    });
  });
}
