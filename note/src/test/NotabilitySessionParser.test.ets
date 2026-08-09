import { describe, it, expect } from '@ohos/hypium';
import {
  createNotabilityContentInventory, NotabilityContentInventory,
  resolveNotabilityPageCount, summarizeNotabilityContentLoss,
} from '../main/ets/data/NotabilitySessionParser';

export default function notabilitySessionParserTest() {
  describe('NotabilitySessionParser', () => {
    it('does not report an intentionally blank note as partial content loss', 0, () => {
      const inventory: NotabilityContentInventory = createNotabilityContentInventory();
      expect(summarizeNotabilityContentLoss(inventory).length).assertEqual(0);
    });

    it('reports typed and media content with exact recovered and lost counts', 0, () => {
      const inventory: NotabilityContentInventory = createNotabilityContentInventory();
      inventory.textCharacters.found = 18;
      inventory.media.found = 2;
      const details: string[] = summarizeNotabilityContentLoss(inventory);
      expect(details.length).assertEqual(2);
      expect(details[0]).assertContain('发现 18 字符');
      expect(details[0]).assertContain('丢失 18 字符');
      expect(details[1]).assertContain('发现 2 项');
      expect(details[1]).assertContain('丢失 2 项');
    });

    it('reports quantified, degraded and structurally unknown shape loss', 0, () => {
      const inventory: NotabilityContentInventory = createNotabilityContentInventory();
      inventory.shapes.found = 4;
      inventory.shapes.recovered = 2;
      inventory.shapes.degraded = 1;
      inventory.shapes.unquantifiedLoss = true;
      const details: string[] = summarizeNotabilityContentLoss(inventory);
      expect(details.length).assertEqual(3);
      expect(details[0]).assertContain('丢失 2 个');
      expect(details[1]).assertContain('1 个');
      expect(details[2]).assertContain('数量未知');
    });

    it('uses the larger of content-derived pages and index hint', 0, () => {
      expect(resolveNotabilityPageCount(4, 2)).assertEqual(4);
      expect(resolveNotabilityPageCount(2, 5)).assertEqual(5);
      expect(resolveNotabilityPageCount(0, 0)).assertEqual(1);
    });
  });
}
