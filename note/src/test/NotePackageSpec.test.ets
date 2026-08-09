import { describe, expect, it } from '@ohos/hypium';
import { isSupportedPageElementKind } from '../main/ets/data/NotePackageSpec';

export default function notePackageSpecTest() {
  describe('NotePackageSpec', () => {
    it('accepts every element kind emitted by the package exporter', 0, () => {
      expect(isSupportedPageElementKind('stroke')).assertTrue();
      expect(isSupportedPageElementKind('text')).assertTrue();
      expect(isSupportedPageElementKind('shape')).assertTrue();
      expect(isSupportedPageElementKind('unknown')).assertFalse();
    });
  });
}
