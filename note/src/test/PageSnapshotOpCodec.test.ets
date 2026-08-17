import { describe, it, expect } from '@ohos/hypium';
import {
  decodePageSnapshotOp, encodePageSnapshotOp, PageSnapshotOpPayload,
} from '../main/ets/data/PageSnapshotOpCodec';

export default function pageSnapshotOpCodecTest() {
  describe('PageSnapshotOpCodec', () => {
    it('round-trips an ordered snapshot above the uint32 revision boundary', 0, () => {
      const source: PageSnapshotOpPayload = {
        pageId: 'page-中文',
        revision: 0x100000000 + 17,
        elements: [
          { elementId: 'stroke-1', kind: 1, payload: new Uint8Array([0, 1, 255]) },
          { elementId: '文本-2', kind: 2, payload: new Uint8Array([4, 5]) },
        ],
      };
      const restored: PageSnapshotOpPayload = decodePageSnapshotOp(encodePageSnapshotOp(source));

      expect(restored.pageId).assertEqual(source.pageId);
      expect(restored.revision).assertEqual(source.revision);
      expect(restored.elements.length).assertEqual(2);
      expect(restored.elements[0].elementId).assertEqual('stroke-1');
      expect(restored.elements[0].payload[2]).assertEqual(255);
      expect(restored.elements[1].elementId).assertEqual('文本-2');
    });

    it('rejects truncation, trailing bytes and invalid magic', 0, () => {
      const valid: Uint8Array = encodePageSnapshotOp({
        pageId: 'page', revision: 1,
        elements: [{ elementId: 'stroke', kind: 1, payload: new Uint8Array([7]) }],
      });
      const truncated: Uint8Array = valid.slice(0, valid.length - 1);
      const trailing = new Uint8Array(valid.length + 1);
      trailing.set(valid);
      const invalidMagic: Uint8Array = valid.slice();
      invalidMagic[0] = 0;

      expectReject(truncated);
      expectReject(trailing);
      expectReject(invalidMagic);
    });

    it('rejects invalid snapshot identities before encoding', 0, () => {
      let rejected: boolean = false;
      try {
        encodePageSnapshotOp({ pageId: '', revision: 1, elements: [] });
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('rejects duplicate cross-kind IDs and unsupported kinds', 0, () => {
      expectEncodeReject({
        pageId: 'page', revision: 1,
        elements: [
          { elementId: 'shared', kind: 1, payload: new Uint8Array([1]) },
          { elementId: 'shared', kind: 2, payload: new Uint8Array([2]) },
        ],
      });
      expectEncodeReject({ pageId: 'page', revision: 1,
        elements: [{ elementId: 'zero', kind: 0, payload: new Uint8Array([1]) }] });
      expectEncodeReject({ pageId: 'page', revision: 1,
        elements: [{ elementId: 'future', kind: 6, payload: new Uint8Array([1]) }] });
    });
  });
}

function expectReject(bytes: Uint8Array): void {
  let rejected: boolean = false;
  try {
    decodePageSnapshotOp(bytes);
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}

function expectEncodeReject(value: PageSnapshotOpPayload): void {
  let rejected: boolean = false;
  try {
    encodePageSnapshotOp(value);
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}
