import { describe, expect, it } from '@ohos/hypium';

class HistoryReleaseModel {
  private pending: number = 0;
  private settled: boolean = true;

  requestPage(): void {
    this.pending = -1;
    this.settled = false;
  }

  resume(loaded: boolean, dataLoading: boolean): boolean {
    if (this.pending === 0) {
      return false;
    }
    if (!loaded || dataLoading) {
      this.pending = 0;
      this.settled = true;
      return false;
    }
    this.pending = 0;
    this.settled = true;
    return true;
  }

  isReleased(): boolean {
    return this.pending === 0 && this.settled;
  }
}

export default function crossPageHistoryReleaseTest() {
  describe('CrossPageHistoryRelease', () => {
    it('releases the navigation lease after a failed page load', 0, () => {
      const model: HistoryReleaseModel = new HistoryReleaseModel();
      model.requestPage();
      expect(model.isReleased()).assertFalse();
      expect(model.resume(false, true)).assertFalse();
      expect(model.isReleased()).assertTrue();
    });

    it('keeps a normal resume releasable and non-pending', 0, () => {
      const model: HistoryReleaseModel = new HistoryReleaseModel();
      model.requestPage();
      expect(model.resume(true, false)).assertTrue();
      expect(model.isReleased()).assertTrue();
    });
  });
}
