import { describe, it, expect } from '@ohos/hypium';
import { monotonicOperationTime } from '../main/ets/data/OpStoreImpl';

export default function opStoreTest() {
  describe('OpStore time policy', () => {
    it('keeps getOpsSince cursors lossless across equal or regressing wall clocks', 0, () => {
      expect(monotonicOperationTime(null, 100)).assertEqual(100);
      expect(monotonicOperationTime(100, 100)).assertEqual(101);
      expect(monotonicOperationTime(101, 90)).assertEqual(102);
      expect(monotonicOperationTime(102, 200)).assertEqual(200);
    });

    it('rejects unsafe persisted clock values', 0, () => {
      let rejected: boolean = false;
      try {
        monotonicOperationTime(Number.MAX_SAFE_INTEGER, 1);
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
