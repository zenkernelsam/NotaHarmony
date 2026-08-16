import { describe, expect, it } from '@ohos/hypium';
import { PaperSize } from '../main/ets/core/model/NoteTypes';
import { encodeOriginalLocalCreatePage } from
  '../main/ets/data/OriginalCreatePagePayloadEncoder';
import { decodeOriginalCreatePage } from '../main/ets/data/OriginalCreatePageOperation';
import { encodeOriginalPageVisibility } from
  '../main/ets/data/OriginalDeleteEntitiesPayloadEncoder';
import { decodeOriginalDeleteEntities } from '../main/ets/data/OriginalDeleteEntitiesOperation';
import { persistOriginalCreatePage } from '../main/ets/data/OriginalPagePersistence';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';

export default function originalCreatePagePayloadEncoderTest() {
  describe('OriginalCreatePagePayloadEncoder', () => {
    it('preserves the original implicit Letter root-page defaults', 0, () => {
      expect(persistOriginalCreatePage !== undefined).assertTrue();
      const decoded = decodeOriginalCreatePage(wrap(3, encodeOriginalLocalCreatePage(null)));
      expect(decoded.location === null).assertTrue();
      expect(decoded.hasBackground).assertFalse();
      expect(decoded.pageCount).assertEqual(1);
      expect(decoded.bookmarked).assertFalse();
    });

    it('writes the original two-page blank-note create group', 0, () => {
      const decoded = decodeOriginalCreatePage(
        wrap(3, encodeOriginalLocalCreatePage(null, null, null, 2)));
      expect(decoded.location === null).assertTrue();
      expect(decoded.hasBackground).assertFalse();
      expect(decoded.pageCount).assertEqual(2);
      expect(decoded.bookmarked).assertFalse();
      expect(() => encodeOriginalLocalCreatePage(null, null, null, 0)).assertThrow();
    });

    it('round-trips a located A4 page through nz9 sourceSize', 0, () => {
      const decoded = decodeOriginalCreatePage(wrap(3, encodeOriginalLocalCreatePage({
        timestamp: 91, siteId: 7, index: 3,
      }, 210, 297)));
      expect(decoded.location === null).assertFalse();
      expect(decoded.location?.timestamp).assertEqual(91);
      expect(decoded.location?.siteId).assertEqual(7);
      expect(decoded.location?.index).assertEqual(3);
      expect(decoded.background === null).assertFalse();
      expect(Math.abs((decoded.background?.widthMm as number) - 210) < 0.001).assertTrue();
      expect(Math.abs((decoded.background?.heightMm as number) - 297) < 0.001).assertTrue();
      expect(decoded.background?.size).assertEqual(PaperSize.A4);
    });

    it('round-trips page delete and undelete sequence vectors', 0, () => {
      const decoded = decodeOriginalDeleteEntities(wrap(25, encodeOriginalPageVisibility(
        [{ timestamp: 12, siteId: 2, index: 4 }],
        [{ timestamp: 13, siteId: 3, index: 5 }])));
      expect(decoded.entityDeleteCount).assertEqual(0);
      expect(decoded.entityUndeleteCount).assertEqual(0);
      expect(decoded.pageDeletes.length).assertEqual(1);
      expect(decoded.pageDeletes[0].timestamp).assertEqual(12);
      expect(decoded.pageDeletes[0].siteId).assertEqual(2);
      expect(decoded.pageDeletes[0].index).assertEqual(4);
      expect(decoded.pageUndeletes.length).assertEqual(1);
      expect(decoded.pageUndeletes[0].timestamp).assertEqual(13);
      expect(decoded.pageUndeletes[0].siteId).assertEqual(3);
      expect(decoded.pageUndeletes[0].index).assertEqual(5);
    });
  });
}

function wrap(payloadType: number, payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: payloadType,
  }, payload);
}
