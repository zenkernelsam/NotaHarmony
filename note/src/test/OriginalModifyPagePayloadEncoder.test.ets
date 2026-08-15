import { describe, expect, it } from '@ohos/hypium';
import { encodeOriginalModifyPageMove } from
  '../main/ets/data/OriginalModifyPagePayloadEncoder';
import { decodeOriginalModifyPage } from '../main/ets/data/OriginalModifyPageOperation';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import { persistOriginalPageReorder } from '../main/ets/data/OriginalPagePersistence';
import {
  OriginalPageReorderPlan, planOriginalPageReorder,
} from '../main/ets/data/OriginalPageReorderPlanner';

export default function originalModifyPagePayloadEncoderTest() {
  describe('OriginalModifyPagePayloadEncoder', () => {
    it('round-trips one canonical page move with an explicit predecessor', 0, () => {
      expect(persistOriginalPageReorder !== undefined).assertTrue();
      const decoded = decodeOriginalModifyPage(wrap(encodeOriginalModifyPageMove([
        { timestamp: 17, siteId: 3, index: 2 },
      ], { timestamp: 41, siteId: 7, index: 5 })));
      expect(decoded.pages.length).assertEqual(1);
      expect(decoded.pages[0].timestamp).assertEqual(17);
      expect(decoded.pages[0].siteId).assertEqual(3);
      expect(decoded.pages[0].index).assertEqual(2);
      expect(decoded.hasMove).assertTrue();
      expect(decoded.moveTo === null).assertFalse();
      expect(decoded.moveTo?.timestamp).assertEqual(41);
      expect(decoded.moveTo?.siteId).assertEqual(7);
      expect(decoded.moveTo?.index).assertEqual(5);
      expect(decoded.hasBackground).assertFalse();
      expect(decoded.hasBookmarked).assertFalse();
    });

    it('keeps SeqMove present while moving a page to the root', 0, () => {
      const decoded = decodeOriginalModifyPage(wrap(encodeOriginalModifyPageMove([
        { timestamp: 19, siteId: 4, index: 0 },
      ], null)));
      expect(decoded.pages.length).assertEqual(1);
      expect(decoded.hasMove).assertTrue();
      expect(decoded.moveTo === null).assertTrue();
      expect(decoded.hasBackground).assertFalse();
      expect(decoded.hasBookmarked).assertFalse();
    });

    it('plans relocation from the explicit dragged page identity', 0, () => {
      const movedB: OriginalPageReorderPlan = planOriginalPageReorder(
        ['A', 'B', 'C', 'D'], ['A', 'C', 'B', 'D'], 'B');
      expect(movedB.movedPageId).assertEqual('B');
      expect(movedB.predecessorPageId).assertEqual('C');
      const movedC: OriginalPageReorderPlan = planOriginalPageReorder(
        ['A', 'B', 'C', 'D'], ['A', 'C', 'B', 'D'], 'C');
      expect(movedC.movedPageId).assertEqual('C');
      expect(movedC.predecessorPageId).assertEqual('A');
      const movedToRoot: OriginalPageReorderPlan = planOriginalPageReorder(
        ['A', 'B', 'C'], ['C', 'A', 'B'], 'C');
      expect(movedToRoot.predecessorPageId === null).assertTrue();
    });

    it('rejects mutations that are not one relocation of the named page', 0, () => {
      expect(() => planOriginalPageReorder(
        ['A', 'B', 'C', 'D'], ['B', 'A', 'D', 'C'], 'A')).assertThrow();
      expect(() => planOriginalPageReorder(
        ['A', 'B', 'C'], ['A', 'B', 'C'], 'B')).assertThrow();
      expect(() => planOriginalPageReorder(
        ['A', 'B', 'C'], ['A', 'B', 'X'], 'B')).assertThrow();
      expect(() => encodeOriginalModifyPageMove([], null)).assertThrow();
      expect(() => encodeOriginalModifyPageMove([
        { timestamp: 1, siteId: 1, index: 0 },
        { timestamp: 1, siteId: 1, index: 0 },
      ], null)).assertThrow();
    });
  });
}

function wrap(payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: 4,
  }, payload);
}
