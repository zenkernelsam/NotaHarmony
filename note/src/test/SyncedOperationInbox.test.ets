import { describe, it, expect } from '@ohos/hypium';
import {
  compareIncomingSyncedOperationOrder, IncomingSyncedOperation, validateIncomingSyncedBatch,
} from '../main/ets/data/SyncedOperationInbox';
import {
  crc32Signed, parseOriginalSyncedOperationEnvelope,
} from '../main/ets/data/OriginalSyncedOperationFlatBuffer';
import {
  DeferredSyncedOperationTableType, validateDeferredSyncedOperationTableType,
} from '../main/ets/data/DeferredSyncedOperationBundle';
import {
  decodeOriginalCreatePage, ORIGINAL_DEFAULT_PAGE_HEIGHT_MM, ORIGINAL_DEFAULT_PAGE_WIDTH_MM,
} from '../main/ets/data/OriginalCreatePageOperation';
import {
  compareOriginalSequenceIdentity, encodeOriginalPageStorageId, encodeOriginalSequenceId,
} from '../main/ets/data/OperationIdentity';

function operation(timestamp: number, serverTime: string,
  clientTime: string = serverTime, payloadType: number = 3): IncomingSyncedOperation {
  return {
    noteId: 'note', timestamp: timestamp, siteId: 7, clientTime: clientTime,
    serverTime: serverTime, schemaVersion: 1, payloadType: payloadType,
    rawOperation: flatBufferOperation(timestamp, 7, clientTime, serverTime, payloadType),
  };
}

export default function syncedOperationInboxTest() {
  describe('SyncedOperationInbox', () => {
    it('orders full unsigned server and client times without number conversion', 0, () => {
      const first = operation(1, '9007199254740993', '18446744073709551614');
      const second = operation(2, '18446744073709551615', '0');
      expect(compareIncomingSyncedOperationOrder(first, second)).assertEqual(-1);
      validateIncomingSyncedBatch('note', [first, second]);
    });

    it('rejects out-of-order and repeated operation identities before persistence', 0, () => {
      const first = operation(1, '10');
      const second = operation(2, '9');
      let rejected: number = 0;
      try {
        validateIncomingSyncedBatch('note', [first, second]);
      } catch (_error) {
        rejected++;
      }
      try {
        validateIncomingSyncedBatch('note', [first, operation(1, '11')]);
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('parses the original little-endian uq9 root without losing uint64 values', 0, () => {
      const source: IncomingSyncedOperation = operation(
        0xFFFFFFFF, '18446744073709551615', '9007199254740993', 31);
      const parsed = parseOriginalSyncedOperationEnvelope(source.rawOperation);
      expect(parsed.timestamp).assertEqual(0xFFFFFFFF);
      expect(parsed.siteId).assertEqual(7);
      expect(parsed.clientTime).assertEqual('9007199254740993');
      expect(parsed.serverTime).assertEqual('18446744073709551615');
      expect(parsed.payloadType).assertEqual(31);
      expect(parsed.payloadTypeKnown).assertTrue();
    });

    it('rejects metadata substitution and malformed FlatBuffer roots', 0, () => {
      let rejected: number = 0;
      const valid: IncomingSyncedOperation = operation(1, '10');
      try {
        validateIncomingSyncedBatch('note', [{ ...valid, serverTime: '11' }]);
      } catch (_error) {
        rejected++;
      }
      try {
        validateIncomingSyncedBatch('note', [{ ...valid, rawOperation: new Uint8Array([1, 2, 3]) }]);
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('uses standard signed CRC32 and the original deferred type allowlist', 0, () => {
      expect(crc32Signed(new Uint8Array([0x31, 0x32, 0x33, 0x34, 0x35,
        0x36, 0x37, 0x38, 0x39]))).assertEqual(-873187034);
      expect(validateDeferredSyncedOperationTableType('OPS_BUNDLE')).assertEqual(
        DeferredSyncedOperationTableType.OPS_BUNDLE);
      let rejected: boolean = false;
      try {
        validateDeferredSyncedOperationTableType('OPS');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('decodes original CREATE_PAGE inline SeqId and default-safe fields', 0, () => {
      const raw: Uint8Array = flatBufferCreatePage(9, 4, '11', '12',
        7, 3, 2, 2, false);
      const payload = decodeOriginalCreatePage(raw);
      expect(payload.location?.timestamp).assertEqual(7);
      expect(payload.location?.siteId).assertEqual(3);
      expect(payload.location?.index).assertEqual(2);
      expect(payload.pageCount).assertEqual(2);
      expect(payload.hasBackground).assertFalse();
      expect(payload.bookmarked).assertFalse();
      expect(ORIGINAL_DEFAULT_PAGE_WIDTH_MM).assertEqual(215.9);
      expect(ORIGINAL_DEFAULT_PAGE_HEIGHT_MM).assertEqual(279.4);
      const rootPayload = decodeOriginalCreatePage(flatBufferCreatePage(
        10, 4, '13', '14', 0, 0, 0, 1, true, false, true));
      expect(rootPayload.location === null).assertTrue();
      expect(rootPayload.hasBackground).assertTrue();
      expect(rootPayload.bookmarked).assertTrue();
    });

    it('keeps original SeqId comparison and note-scoped storage IDs', 0, () => {
      const older = { timestamp: 5, siteId: 2, index: 0 };
      const newer = { timestamp: 6, siteId: 1, index: 0 };
      expect(compareOriginalSequenceIdentity(older, newer)).assertEqual(-1);
      expect(compareOriginalSequenceIdentity({ timestamp: 5, siteId: 2, index: 1 }, older))
        .assertEqual(-1);
      expect(encodeOriginalSequenceId(older)).assertEqual('seq:5:2:0');
      expect(encodeOriginalPageStorageId('a', older)).assertEqual('original-page:1:a:seq:5:2:0');
    });
  });
}

function flatBufferCreatePage(timestamp: number, siteId: number, clientTime: string,
  serverTime: string, locationTimestamp: number, locationSite: number,
  locationIndex: number, pageCount: number, bookmarked: boolean,
  hasLocation: boolean = true, hasBackground: boolean = false): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(96);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, siteId);
  writeU32(bytes, 32, timestamp);
  writeDecimalU64(bytes, 36, clientTime);
  writeDecimalU64(bytes, 44, serverTime);
  bytes[52] = 3;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 24);
  writeU16(bytes, 64, hasLocation ? 4 : 0);
  writeU16(bytes, 66, hasBackground ? 4 : 0);
  writeU16(bytes, 68, 16);
  writeU16(bytes, 70, 20);
  writeU32(bytes, 72, 12);
  writeU16(bytes, 76, locationSite);
  writeU32(bytes, 80, locationTimestamp);
  writeU32(bytes, 84, locationIndex);
  writeU32(bytes, 88, pageCount);
  bytes[92] = bookmarked ? 1 : 0;
  return bytes;
}

function flatBufferOperation(timestamp: number, siteId: number, clientTime: string,
  serverTime: string, payloadType: number): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(68);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, siteId);
  writeU32(bytes, 32, timestamp);
  writeDecimalU64(bytes, 36, clientTime);
  writeDecimalU64(bytes, 44, serverTime);
  bytes[52] = payloadType;
  writeU32(bytes, 56, 8);
  writeU16(bytes, 60, 4);
  writeU16(bytes, 62, 4);
  writeU32(bytes, 64, 4);
  return bytes;
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = Math.floor(value / 0x100) & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = Math.floor(value / 0x100) & 0xFF;
  bytes[offset + 2] = Math.floor(value / 0x10000) & 0xFF;
  bytes[offset + 3] = Math.floor(value / 0x1000000) & 0xFF;
}

function writeDecimalU64(bytes: Uint8Array, offset: number, decimal: string): void {
  let remaining: string = decimal;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let carry: number = 0;
    for (let digit: number = 0; digit < remaining.length; digit++) {
      const value: number = carry * 10 + remaining.charCodeAt(digit) - 0x30;
      const part: number = Math.floor(value / 256);
      carry = value % 256;
      if (quotient.length > 0 || part > 0) {
        quotient += part.toString();
      }
    }
    bytes[offset + index] = carry;
    remaining = quotient.length === 0 ? '0' : quotient;
  }
}
