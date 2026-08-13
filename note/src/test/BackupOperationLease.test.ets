import { describe, it, expect } from '@ohos/hypium';
import {
  BackupOperationLease, BackupOperationRelease,
} from '../main/ets/data/BackupOperationLease';

export default function backupOperationLeaseTest() {
  describe('BackupOperationLease', () => {
    it('rejects another page instance until the active operation releases', 0, () => {
      const lease = new BackupOperationLease();
      const first: BackupOperationRelease | null = lease.tryAcquire();
      expect(first === null).assertFalse();
      expect(lease.isActive()).assertTrue();
      expect(lease.tryAcquire() === null).assertTrue();
      if (first !== null) {
        first();
      }
      expect(lease.isActive()).assertFalse();
      const second: BackupOperationRelease | null = lease.tryAcquire();
      expect(second === null).assertFalse();
      if (second !== null) {
        second();
      }
    });

    it('makes release idempotent so stale finally paths cannot unlock a newer owner', 0, () => {
      const lease = new BackupOperationLease();
      const first: BackupOperationRelease | null = lease.tryAcquire();
      if (first === null) {
        expect(false).assertTrue();
        return;
      }
      first();
      const second: BackupOperationRelease | null = lease.tryAcquire();
      expect(second === null).assertFalse();
      first();
      expect(lease.isActive()).assertTrue();
      if (second !== null) {
        second();
      }
    });
  });
}
