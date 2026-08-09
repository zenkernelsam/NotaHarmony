import { describe, it, expect } from '@ohos/hypium';
import {
  advanceSyncedOperationCount, safeOperationCompactionBoundary,
} from '../main/ets/data/OperationCompaction';

export default function operationCompactionTest() {
  describe('OperationCompaction', () => {
    it('requires both ACK and history checkpoint watermarks', 0, () => {
      expect(safeOperationCompactionBoundary(0, 12)).assertEqual(0);
      expect(safeOperationCompactionBoundary(12, 0)).assertEqual(0);
      expect(safeOperationCompactionBoundary(8, 12)).assertEqual(8);
      expect(safeOperationCompactionBoundary(12, 8)).assertEqual(8);
      expect(safeOperationCompactionBoundary(8, 8)).assertEqual(8);
    });

    it('keeps acknowledged counts cumulative after physical deletion', 0, () => {
      expect(advanceSyncedOperationCount(5, 3)).assertEqual(8);
      expect(advanceSyncedOperationCount(8, 0)).assertEqual(8);
    });

    it('rejects corrupt compaction watermarks and exhausted counts', 0, () => {
      let badWatermark: boolean = false;
      let exhausted: boolean = false;
      try {
        safeOperationCompactionBoundary(-1, 2);
      } catch (_error) {
        badWatermark = true;
      }
      try {
        advanceSyncedOperationCount(Number.MAX_SAFE_INTEGER, 1);
      } catch (_error) {
        exhausted = true;
      }
      expect(badWatermark).assertTrue();
      expect(exhausted).assertTrue();
    });
  });
}
