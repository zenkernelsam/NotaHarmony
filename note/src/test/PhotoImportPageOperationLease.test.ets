import { describe, expect, it } from '@ohos/hypium';

class PhotoImportPageOperationLeaseModel {
  photoImportLeaseActive: boolean = false;
  pageOperationBusy: boolean = false;

  requestInsertPhotos(): void {
    if (this.photoImportLeaseActive || this.pageOperationBusy) {
      return;
    }
    this.photoImportLeaseActive = true;
  }

  finishIngress(): void {
    this.photoImportLeaseActive = false;
  }

  requestPageOperation(): boolean {
    if (this.photoImportLeaseActive || this.pageOperationBusy) {
      return false;
    }
    this.pageOperationBusy = true;
    return true;
  }
}

export default function photoImportPageOperationLeaseTest() {
  describe('PhotoImportPageOperationLease', () => {
    it('blocks page structure while photo ingress is active', 0, () => {
      const model: PhotoImportPageOperationLeaseModel =
        new PhotoImportPageOperationLeaseModel();
      model.requestInsertPhotos();
      expect(model.requestPageOperation()).assertFalse();
      model.finishIngress();
      expect(model.requestPageOperation()).assertTrue();
    });

    it('does not start a second photo ingress from a stale toolbar signal', 0, () => {
      const model: PhotoImportPageOperationLeaseModel =
        new PhotoImportPageOperationLeaseModel();
      model.requestInsertPhotos();
      model.requestInsertPhotos();
      expect(model.photoImportLeaseActive).assertTrue();
      model.finishIngress();
      expect(model.photoImportLeaseActive).assertFalse();
    });
  });
}
