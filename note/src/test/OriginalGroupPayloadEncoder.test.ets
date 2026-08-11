import { describe, expect, it } from '@ohos/hypium';
import { encodeOriginalCreateGroup, encodeOriginalModifyGroup } from
  '../main/ets/data/OriginalGroupPayloadEncoder';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import { decodeOriginalCreateGroup, decodeOriginalModifyGroup } from
  '../main/ets/data/OriginalShapeGroupOperation';

export default function originalGroupPayloadEncoderTest() {
  describe('OriginalGroupPayloadEncoder', () => {
    it('round-trips canonical CREATE_GROUP members', 0, () => {
      const decoded = decodeOriginalCreateGroup(wrap(20, encodeOriginalCreateGroup([
        { timestamp: 20, siteId: 2 }, { timestamp: 30, siteId: 3 },
      ])));
      expect(decoded.members.length).assertEqual(2);
      expect(decoded.members[0].timestamp).assertEqual(20);
      expect(decoded.members[0].siteId).assertEqual(2);
      expect(decoded.members[1].timestamp).assertEqual(30);
      expect(decoded.members[1].siteId).assertEqual(3);
    });

    it('round-trips MODIFY_GROUP target and replacement members', 0, () => {
      const decoded = decodeOriginalModifyGroup(wrap(21, encodeOriginalModifyGroup(
        { timestamp: 40, siteId: 4 },
        [{ timestamp: 20, siteId: 2 }, { timestamp: 30, siteId: 3 }])));
      expect(decoded.group.timestamp).assertEqual(40);
      expect(decoded.group.siteId).assertEqual(4);
      expect(decoded.members.length).assertEqual(2);
      expect(decoded.members[1].timestamp).assertEqual(30);
    });

    it('rejects empty duplicate and invalid members', 0, () => {
      expect(() => encodeOriginalCreateGroup([])).assertThrow();
      expect(() => encodeOriginalCreateGroup([
        { timestamp: 20, siteId: 2 }, { timestamp: 20, siteId: 2 },
      ])).assertThrow();
      expect(() => encodeOriginalModifyGroup(
        { timestamp: 40, siteId: 4 }, [{ timestamp: -1, siteId: 2 }])).assertThrow();
    });
  });
}

function wrap(payloadType: number, payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: payloadType,
  }, payload);
}
