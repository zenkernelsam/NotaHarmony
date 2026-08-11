import { describe, expect, it } from '@ohos/hypium';
import { decodeOriginalModifyBlock } from '../main/ets/data/OriginalModifyBlockOperation';
import { encodeOriginalImageFlip } from '../main/ets/data/OriginalModifyBlockPayloadEncoder';
import { encodeOriginalOperationEnvelope } from '../main/ets/data/OriginalOperationEnvelopeEncoder';

export default function originalModifyBlockPayloadEncoderTest() {
  describe('OriginalModifyBlockPayloadEncoder', () => {
    it('round-trips image flip registers including explicit false presence', 0, () => {
      const horizontal = decodeOriginalModifyBlock(wrap(encodeOriginalImageFlip([
        { timestamp: 20, siteId: 2 }, { timestamp: 22, siteId: 4 },
      ], false, null)));
      expect(horizontal.blocks.length).assertEqual(2);
      expect(horizontal.blocks[0].timestamp).assertEqual(20);
      expect(horizontal.blocks[1].siteId).assertEqual(4);
      expect(horizontal.imageFlippedHorizontally).assertFalse();
      expect(horizontal.imageFlippedVertically === null).assertTrue();

      const vertical = decodeOriginalModifyBlock(wrap(encodeOriginalImageFlip(
        [{ timestamp: 24, siteId: 6 }], null, true)));
      expect(vertical.imageFlippedHorizontally === null).assertTrue();
      expect(vertical.imageFlippedVertically).assertTrue();

      const cropped = decodeOriginalModifyBlock(wrap(encodeOriginalImageFlip(
        [{ timestamp: 26, siteId: 8 }], true, null,
        { x: 20, y: 10, width: 80, height: 40 })));
      expect(cropped.cropRect.present).assertTrue();
      expect(cropped.cropRect.value?.x).assertEqual(20);
      expect(cropped.cropRect.value?.height).assertEqual(40);
    });

    it('rejects empty, duplicate, and no-op image flip payloads', 0, () => {
      expect(() => encodeOriginalImageFlip([], true, null)).assertThrow();
      expect(() => encodeOriginalImageFlip([
        { timestamp: 20, siteId: 2 }, { timestamp: 20, siteId: 2 },
      ], true, null)).assertThrow();
      expect(() => encodeOriginalImageFlip(
        [{ timestamp: 20, siteId: 2 }], null, null)).assertThrow();
    });
  });
}

function wrap(payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234',
    serverTime: null, audioTime: null, payloadType: 23,
  }, payload);
}
