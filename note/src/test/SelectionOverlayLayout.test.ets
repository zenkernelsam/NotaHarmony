import { describe, it, expect } from '@ohos/hypium';
import { Rect2D } from '../main/ets/core/model/GeometryTypes';
import {
  SelectionOverlayPosition, selectionOverlayPosition, standalonePastePosition,
} from '../main/ets/ui/components/SelectionOverlayLayout';

export default function selectionOverlayLayoutTest() {
  describe('SelectionOverlayLayout', () => {
    it('places the action group below the selection when it fits', 0, () => {
      const rect: Rect2D = { left: 100, top: 100, right: 200, bottom: 200 };
      const position: SelectionOverlayPosition = selectionOverlayPosition(rect, 400, 600, false);
      expect(position.x).assertEqual(100);
      expect(position.actionY).assertEqual(208);
    });

    it('moves both buttons above and clamps them away from the right edge', 0, () => {
      const rect: Rect2D = { left: 360, top: 530, right: 390, bottom: 580 };
      const position: SelectionOverlayPosition = selectionOverlayPosition(rect, 400, 600, true);
      expect(position.x).assertEqual(262);
      expect(position.actionY).assertEqual(438);
      expect(position.pasteY).assertEqual(482);
    });

    it('keeps controls reachable when neither side of the selection has enough room', 0, () => {
      const rect: Rect2D = { left: -20, top: 20, right: 50, bottom: 580 };
      const position: SelectionOverlayPosition = selectionOverlayPosition(rect, 400, 600, true);
      expect(position.x).assertEqual(8);
      expect(position.actionY).assertEqual(8);
      expect(position.pasteY).assertEqual(52);
    });

    it('clamps standalone paste and invalid container geometry', 0, () => {
      expect(standalonePastePosition(400)).assertEqual(16);
      expect(standalonePastePosition(140)).assertEqual(8);
      const rect: Rect2D = { left: Number.NaN, top: Number.NaN, right: 0, bottom: Number.NaN };
      const position: SelectionOverlayPosition = selectionOverlayPosition(rect, Number.NaN, Number.NaN, false);
      expect(position.x).assertEqual(8);
      expect(position.actionY).assertEqual(8);
    });
  });
}
