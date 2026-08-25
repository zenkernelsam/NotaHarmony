import { describe, expect, it } from '@ohos/hypium';

class PhotoHistoryRecoveryLeaseModel {
  photoImportBusy: boolean = false;
  historyRecoveryBusy: boolean = false;
  historyBusy: boolean = false;

  requestHistoryReset(): boolean {
    if (this.historyRecoveryBusy || this.photoImportBusy || this.historyBusy) {
      return false;
    }
    this.historyRecoveryBusy = true;
    this.historyBusy = true;
    return true;
  }

  finishIngress(): void {
    this.photoImportBusy = false;
  }
}

export default function photoHistoryRecoveryLeaseTest() {
  describe('PhotoHistoryRecoveryLease', () => {
    it('blocks history reset while shared photo ingress is active', 0, () => {
      const model: PhotoHistoryRecoveryLeaseModel =
        new PhotoHistoryRecoveryLeaseModel();
      model.photoImportBusy = true;
      expect(model.requestHistoryReset()).assertFalse();
      model.finishIngress();
      expect(model.requestHistoryReset()).assertTrue();
    });
  });
}
