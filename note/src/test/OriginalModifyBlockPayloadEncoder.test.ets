import { describe, expect, it } from '@ohos/hypium';
import { decodeOriginalModifyBlock } from '../main/ets/data/OriginalModifyBlockOperation';
import {
  encodeOriginalImageCrop, encodeOriginalImageFlip,
} from '../main/ets/data/OriginalModifyBlockPayloadEncoder';
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

    it('round-trips the original composite image crop registers', 0, () => {
      const decoded = decodeOriginalModifyBlock(wrap(encodeOriginalImageCrop(
        [{ timestamp: 30, siteId: 3 }],
        { page: { timestamp: 40, siteId: 4, index: 2 }, originX: 12.5, originY: -8.25 },
        { x: 1.5, y: 2.25 }, 160, 90,
        { x: 20, y: 10, width: 160, height: 90 })));
      expect(decoded.blocks.length).assertEqual(1);
      expect(decoded.pageOrigin?.page.timestamp).assertEqual(40);
      expect(decoded.pageOrigin?.page.index).assertEqual(2);
      expect(decoded.pageOrigin?.originX).assertEqual(12.5);
      expect(decoded.pageOrigin?.originY).assertEqual(-8.25);
      expect(decoded.scale.present).assertTrue();
      expect(decoded.scale.value?.x).assertEqual(1.5);
      expect(decoded.scale.value?.y).assertEqual(2.25);
      expect(decoded.width).assertEqual(160);
      expect(decoded.height).assertEqual(90);
      expect(decoded.cropRect.present).assertTrue();
      expect(decoded.cropRect.value?.x).assertEqual(20);
      expect(decoded.cropRect.value?.height).assertEqual(90);
    });

    it('keeps field 12 present while clearing the nullable crop register for Undo', 0, () => {
      const decoded = decodeOriginalModifyBlock(wrap(encodeOriginalImageCrop(
        [{ timestamp: 30, siteId: 3 }],
        { page: { timestamp: 40, siteId: 4, index: 2 }, originX: 1, originY: 2 },
        { x: 1, y: 1 }, 200, 100, null)));
      expect(decoded.cropRect.present).assertTrue();
      expect(decoded.cropRect.value === null).assertTrue();
      expect(decoded.scale.present).assertTrue();
      expect(decoded.width).assertEqual(200);
      expect(decoded.height).assertEqual(100);
    });

    it('rejects malformed composite crop geometry', 0, () => {
      const page = { page: { timestamp: 40, siteId: 4, index: 2 }, originX: 1, originY: 2 };
      expect(() => encodeOriginalImageCrop([], page, { x: 1, y: 1 }, 10, 10, null))
        .assertThrow();
      expect(() => encodeOriginalImageCrop([{ timestamp: 30, siteId: 3 }], page,
        { x: 0, y: 1 }, 10, 10, null)).assertThrow();
      expect(() => encodeOriginalImageCrop([{ timestamp: 30, siteId: 3 }], page,
        { x: 1, y: 1 }, -1, 10, null)).assertThrow();
      expect(() => encodeOriginalImageCrop([{ timestamp: 30, siteId: 3 }], page,
        { x: 1, y: 1 }, 10, 10, { x: 0, y: 0, width: 0, height: 10 })).assertThrow();
    });
  });
}

function wrap(payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234',
    serverTime: null, audioTime: null, payloadType: 23,
  }, payload);
}
