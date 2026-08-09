import { describe, it, expect } from '@ohos/hypium';
import { monotonicOperationTime } from '../main/ets/data/OpStoreImpl';
import {
  compareOperationIdentity, encodeOperationId, MAX_OPERATION_TIMESTAMP, nextOperationTimestamp,
} from '../main/ets/data/OperationIdentity';

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

    it('models the original unsigned timestamp then site ordering without 64-bit numbers', 0, () => {
      expect(encodeOperationId({ timestamp: 12, siteId: 7 })).assertEqual('op:c:7');
      expect(compareOperationIdentity(
        { timestamp: 12, siteId: 7 }, { timestamp: 13, siteId: 0 })).assertEqual(-1);
      expect(compareOperationIdentity(
        { timestamp: 12, siteId: 7 }, { timestamp: 12, siteId: 8 })).assertEqual(-1);
      expect(compareOperationIdentity(
        { timestamp: 12, siteId: 7 }, { timestamp: 12, siteId: 7 })).assertEqual(0);
      expect(nextOperationTimestamp(12)).assertEqual(13);
    });

    it('rejects an exhausted original operation clock', 0, () => {
      let rejected: boolean = false;
      try {
        nextOperationTimestamp(MAX_OPERATION_TIMESTAMP);
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
