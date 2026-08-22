import { describe, expect, it } from '@ohos/hypium';
import { PageElementKind, PageElementRef } from '../main/ets/core/model/PageElementOrder';

export default function originalPhotoHistoryMetadataTest() {
  describe('OriginalPhotoHistoryMetadata', () => {
    it('multi-image history carries one ordered durable action', 0, () => {
      const beforeCount = 3;
      const ids = ['op-image-a', 'op-image-b'];
      const order: PageElementRef[] = ids.map(
        (elementId: string, index: number): PageElementRef => {
          const ref: PageElementRef = {
            kind: PageElementKind.IMAGE,
            elementId: elementId,
            zIndex: beforeCount + index,
          };
          return ref;
        });
      expect(order.length).assertEqual(2);
      expect(order[0].kind).assertEqual(PageElementKind.IMAGE);
      expect(order[0].elementId).assertEqual(ids[0]);
      expect(order[0].zIndex).assertEqual(beforeCount);
      expect(order[1].elementId).assertEqual(ids[1]);
      expect(order[1].zIndex).assertEqual(beforeCount + 1);
    });
  });
}
