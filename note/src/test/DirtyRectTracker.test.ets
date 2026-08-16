import { describe, it, expect } from '@ohos/hypium';
import { Rect2D } from '../main/ets/core/model/GeometryTypes';
import { DirtyRectTracker } from '../main/ets/rendering/DirtyRectTracker';

function rect(left: number, top: number, right: number, bottom: number): Rect2D {
  return { left: left, top: top, right: right, bottom: bottom };
}

export default function dirtyRectTrackerTest() {
  describe('DirtyRectTracker', () => {
    it('keeps distant page regions separate', 0, () => {
      const tracker: DirtyRectTracker = new DirtyRectTracker(0, 8);
      tracker.markDirty(rect(0, 0, 10, 10));
      tracker.markDirty(rect(100, 100, 110, 110));
      expect(tracker.consume().length).assertEqual(2);
      expect(tracker.isDirty()).assertFalse();
    });

    it('merges all regions connected by a bridging update', 0, () => {
      const tracker: DirtyRectTracker = new DirtyRectTracker(0, 8);
      tracker.markDirty(rect(0, 0, 2, 2));
      tracker.markDirty(rect(4, 0, 6, 2));
      tracker.markDirty(rect(2, 0, 4, 2));
      const regions: Rect2D[] = tracker.consume();
      expect(regions.length).assertEqual(1);
      expect(regions[0].left).assertEqual(0);
      expect(regions[0].right).assertEqual(6);
    });

    it('converts screen padding to page coordinates using zoom', 0, () => {
      const tracker: DirtyRectTracker = new DirtyRectTracker(3, 8);
      tracker.markDirty(rect(10, 20, 30, 40), 0.25);
      const padded: Rect2D = tracker.consume()[0];
      expect(padded.left).assertEqual(-2);
      expect(padded.top).assertEqual(8);
      expect(padded.right).assertEqual(42);
      expect(padded.bottom).assertEqual(52);
    });

    it('falls back to unit zoom for non-finite zoom values', 0, () => {
      const invalidZooms: number[] = [Number.NaN, Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY];
      for (const invalidZoom of invalidZooms) {
        const tracker: DirtyRectTracker = new DirtyRectTracker(3, 8);
        tracker.markDirty(rect(10, 20, 30, 40), invalidZoom);
        const padded: Rect2D = tracker.consume()[0];
        expect(padded.left).assertEqual(7);
        expect(padded.top).assertEqual(17);
        expect(padded.right).assertEqual(33);
        expect(padded.bottom).assertEqual(43);
      }
    });

    it('collapses to one union only after the region limit is exceeded', 0, () => {
      const tracker: DirtyRectTracker = new DirtyRectTracker(0, 2);
      tracker.markDirty(rect(0, 0, 1, 1));
      tracker.markDirty(rect(10, 10, 11, 11));
      tracker.markDirty(rect(20, 20, 21, 21));
      const regions: Rect2D[] = tracker.consume();
      expect(regions.length).assertEqual(1);
      expect(regions[0].left).assertEqual(0);
      expect(regions[0].bottom).assertEqual(21);
    });
  });
}
