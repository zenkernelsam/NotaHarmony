import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalEntityVisibilityWinner, originalEntityVisibilityUpdateApplies,
} from '../main/ets/data/OriginalEntityVisibilityState';

export default function originalEntityVisibilityStateTest() {
  describe('OriginalEntityVisibilityState', () => {
    it('accepts an initial or newer winner and ignores a stale winner', 0, () => {
      const winner: OriginalEntityVisibilityWinner = {
        timestamp: 20, siteId: 2, deleted: true,
      };
      expect(originalEntityVisibilityUpdateApplies(
        { timestamp: 10, siteId: 9 }, false, null)).assertTrue();
      expect(originalEntityVisibilityUpdateApplies(
        { timestamp: 21, siteId: 1 }, false, winner)).assertTrue();
      expect(originalEntityVisibilityUpdateApplies(
        { timestamp: 19, siteId: 9 }, false, winner)).assertFalse();
    });

    it('uses site as the equal-timestamp tiebreaker', 0, () => {
      const winner: OriginalEntityVisibilityWinner = {
        timestamp: 20, siteId: 2, deleted: true,
      };
      expect(originalEntityVisibilityUpdateApplies(
        { timestamp: 20, siteId: 3 }, false, winner)).assertTrue();
      expect(originalEntityVisibilityUpdateApplies(
        { timestamp: 20, siteId: 1 }, false, winner)).assertFalse();
    });

    it('accepts an exact retry and rejects an opposite exact value', 0, () => {
      const winner: OriginalEntityVisibilityWinner = {
        timestamp: 20, siteId: 2, deleted: true,
      };
      expect(originalEntityVisibilityUpdateApplies(
        { timestamp: 20, siteId: 2 }, true, winner)).assertFalse();
      let conflicted: boolean = false;
      try {
        originalEntityVisibilityUpdateApplies(
          { timestamp: 20, siteId: 2 }, false, winner);
      } catch (_error) {
        conflicted = true;
      }
      expect(conflicted).assertTrue();
    });
  });
}
