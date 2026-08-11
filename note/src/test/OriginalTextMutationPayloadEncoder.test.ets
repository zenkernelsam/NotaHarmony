import { describe, expect, it } from '@ohos/hypium';
import {
  decodeOriginalInsertText, decodeOriginalTextVisibility,
  ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE,
  ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE, ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE,
  ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE, StoredCharacter,
} from '../main/ets/data/OriginalInsertTextOperation';
import {
  EncodedOriginalTextOperation, encodeOriginalTextInsertion,
  encodeOriginalTextVisibility,
} from '../main/ets/data/OriginalInsertTextPayloadEncoder';
import { planOriginalLocalTextMutation } from
  '../main/ets/data/OriginalLocalTextMutation';
import { decodeOriginalModifyBlock } from '../main/ets/data/OriginalModifyBlockOperation';
import { encodeOriginalBlockSize } from
  '../main/ets/data/OriginalModifyBlockPayloadEncoder';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';

export default function originalTextMutationPayloadEncoderTest() {
  describe('OriginalTextMutationPayloadEncoder', () => {
    it('uses INSERT_CHAR for one scalar and anchored INSERT_STRING for several', 0, () => {
      const single: EncodedOriginalTextOperation = encodeOriginalTextInsertion(
        null, '\uD83D\uDE00', { timestamp: 50, siteId: 7 });
      expect(single.payloadType).assertEqual(ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE);
      const decodedSingle = decodeOriginalInsertText(
        wrap(single.payloadType, single.payload), single.payloadType);
      expect(decodedSingle.location === null).assertTrue();
      expect(decodedSingle.scalars[0]).assertEqual(0x1F600);
      expect(decodedSingle.textField?.timestamp).assertEqual(50);

      const multiple: EncodedOriginalTextOperation = encodeOriginalTextInsertion(
        { timestamp: 60, siteId: 8, index: 2 }, 'A\u4E2D',
        { timestamp: 50, siteId: 7 });
      expect(multiple.payloadType).assertEqual(ORIGINAL_INSERT_STRING_PAYLOAD_TYPE);
      const decodedMultiple = decodeOriginalInsertText(
        wrap(multiple.payloadType, multiple.payload), multiple.payloadType);
      expect(decodedMultiple.location?.timestamp).assertEqual(60);
      expect(decodedMultiple.location?.siteId).assertEqual(8);
      expect(decodedMultiple.location?.index).assertEqual(2);
      expect(decodedMultiple.scalars.length).assertEqual(2);
      expect(decodedMultiple.scalars[1]).assertEqual(0x4E2D);
    });

    it('uses original single-remove, batch-remove and revive payloads', 0, () => {
      const block = { timestamp: 50, siteId: 7 };
      const first = { timestamp: 60, siteId: 8, index: 1 };
      const second = { timestamp: 60, siteId: 8, index: 2 };
      const single: EncodedOriginalTextOperation =
        encodeOriginalTextVisibility([first], block, false);
      expect(single.payloadType).assertEqual(ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE);
      expect(decodeOriginalTextVisibility(wrap(single.payloadType, single.payload),
        single.payloadType).locations.length).assertEqual(1);
      const batch: EncodedOriginalTextOperation =
        encodeOriginalTextVisibility([first, second], block, false);
      expect(batch.payloadType).assertEqual(ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE);
      expect(decodeOriginalTextVisibility(wrap(batch.payloadType, batch.payload),
        batch.payloadType).locations.length).assertEqual(2);
      const revive: EncodedOriginalTextOperation =
        encodeOriginalTextVisibility([first], block, true);
      expect(revive.payloadType).assertEqual(ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE);
      expect(decodeOriginalTextVisibility(wrap(revive.payloadType, revive.payload),
        revive.payloadType).visible).assertTrue();
    });

    it('plans insert, remove and identity-preserving undo-redo by Unicode scalar', 0, () => {
      const initial: StoredCharacter[] = initialCharacters();
      const inserted = planOriginalLocalTextMutation(initial, 'ABC', 'A\uD83D\uDE00BC');
      expect(inserted?.removed.length).assertEqual(0);
      expect(inserted?.insertedScalars.length).assertEqual(1);
      expect(inserted?.insertedScalars[0]).assertEqual(0x1F600);
      expect(inserted?.insertionLocation?.index).assertEqual(0);
      const removed = planOriginalLocalTextMutation(initial, 'ABC', 'AC');
      expect(removed?.removed.length).assertEqual(1);
      expect(removed?.removed[0].index).assertEqual(1);

      const replaced: StoredCharacter[] = replacementCharacters(false, true);
      const undo = planOriginalLocalTextMutation(replaced, 'AXC', 'ABC');
      expect(undo?.removed[0].timestamp).assertEqual(20);
      expect(undo?.revived[0].timestamp).assertEqual(10);
      expect(undo?.insertedScalars.length).assertEqual(0);
      const undone: StoredCharacter[] = replacementCharacters(true, false);
      const redo = planOriginalLocalTextMutation(undone, 'ABC', 'AXC');
      expect(redo?.removed[0].timestamp).assertEqual(10);
      expect(redo?.revived[0].timestamp).assertEqual(20);

      const interleaved: StoredCharacter[] = replacementCharacters(true, false);
      interleaved.push(character(21, 0, 0x59,
        { timestamp: 10, siteId: 7, index: 0 }, false));
      const interleavedRedo = planOriginalLocalTextMutation(interleaved, 'ABC', 'AXC');
      expect(interleavedRedo?.revived.length).assertEqual(1);
      expect(interleavedRedo?.revived[0].timestamp).assertEqual(20);
    });

    it('encodes Text auto-height as the original block size register', 0, () => {
      const decoded = decodeOriginalModifyBlock(wrap(19,
        encodeOriginalBlockSize([{ timestamp: 50, siteId: 7 }], 200, 64)));
      expect(decoded.blocks.length).assertEqual(1);
      expect(decoded.blocks[0].timestamp).assertEqual(50);
      expect(decoded.width).assertEqual(200);
      expect(decoded.height).assertEqual(64);
      expect(() => encodeOriginalBlockSize(
        [{ timestamp: 50, siteId: 7 }], Number.MAX_VALUE, 64)).assertThrowError();
    });
  });
}

function initialCharacters(): StoredCharacter[] {
  return [
    character(10, 0, 0x41, null, true),
    character(10, 1, 0x42, { timestamp: 10, siteId: 7, index: 0 }, true),
    character(10, 2, 0x43, { timestamp: 10, siteId: 7, index: 1 }, true),
  ];
}

function replacementCharacters(oldVisible: boolean, newVisible: boolean): StoredCharacter[] {
  return [
    character(10, 0, 0x41, null, true),
    character(10, 1, 0x42, { timestamp: 10, siteId: 7, index: 0 }, oldVisible),
    character(10, 2, 0x43, { timestamp: 10, siteId: 7, index: 1 }, true),
    character(20, 0, 0x58, { timestamp: 10, siteId: 7, index: 0 }, newVisible),
  ];
}

function character(timestamp: number, index: number, scalar: number,
  parent: { timestamp: number; siteId: number; index: number } | null,
  visible: boolean): StoredCharacter {
  return {
    identity: { timestamp: timestamp, siteId: 7, index: index }, parent: parent,
    scalar: scalar, visible: visible, visibilityWinner: null,
  };
}

function wrap(payloadType: number, payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: payloadType,
  }, payload);
}
