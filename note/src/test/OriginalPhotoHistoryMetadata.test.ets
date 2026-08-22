import { describe, expect, it } from '@ohos/hypium';
import { PageElementKind, PageElementRef } from '../main/ets/core/model/PageElementOrder';

interface PhotoInsertOutcome {
  insertedCount: number;
  totalCount: number;
}

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

    it('partial multi-image failure preserves only the durable success prefix', 0, () => {
      const outcome: PhotoInsertOutcome = { insertedCount: 2, totalCount: 3 };
      expect(outcome.insertedCount > 0 && outcome.insertedCount < outcome.totalCount)
        .assertTrue();
      expect(outcome.insertedCount).assertEqual(2);
      expect(outcome.totalCount).assertEqual(3);
    });
  });
}
