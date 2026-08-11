import { describe, it, expect } from '@ohos/hypium';
import {
  decodeOriginalReceiveOpsEvent, IncomingOperationAcknowledger, IncomingOperationInbox,
  IncomingOperationSyncCoordinator,
} from '../main/ets/data/IncomingOperationSyncCoordinator';
import { OriginalPageOperationApplier } from '../main/ets/data/OriginalPageOperationApplier';
import { OriginalPeerInteractionStore } from '../main/ets/data/OriginalPeerInteractionOperation';
import {
  IncomingSyncedOperation, ProcessSyncedOperationResult, ReceiveSyncedOperationsResult,
  SyncedOperationApplier,
} from '../main/ets/data/SyncedOperationInbox';

class FakeIncomingInbox implements IncomingOperationInbox {
  calls: string[] = [];
  operations: IncomingSyncedOperation[] = [];
  processResults: ProcessSyncedOperationResult[] = [
    ProcessSyncedOperationResult.APPLIED, ProcessSyncedOperationResult.EMPTY,
  ];
  failProcessing: boolean = false;

  async receiveBatch(_noteId: string, operations: IncomingSyncedOperation[],
    _receivedAt: number): Promise<ReceiveSyncedOperationsResult> {
    this.calls.push('receive');
    this.operations = operations;
    return {
      insertedOperationCount: operations.length,
      duplicateOperationCount: 0,
      lastServerTime: operations.length === 0 ? null : operations[operations.length - 1].serverTime,
    };
  }

  async processHead(_noteId: string, _applier: SyncedOperationApplier):
    Promise<ProcessSyncedOperationResult> {
    this.calls.push('process');
    if (this.failProcessing) {
      throw new Error('injected processing failure');
    }
    const result: ProcessSyncedOperationResult | undefined = this.processResults.shift();
    return result === undefined ? ProcessSyncedOperationResult.EMPTY : result;
  }
}

class FakeAcknowledger implements IncomingOperationAcknowledger {
  calls: string[];

  constructor(calls: string[]) {
    this.calls = calls;
  }

  async acknowledge(expectedAckReply: string): Promise<void> {
    this.calls.push(`ack:${expectedAckReply}`);
  }
}

export default function incomingOperationSyncCoordinatorTest() {
  describe('IncomingOperationSyncCoordinator', () => {
    it('rejects incomplete or invalid production peer identity configuration', 0, () => {
      let rejected: number = 0;
      for (const create of [
        (): IncomingOperationSyncCoordinator => new IncomingOperationSyncCoordinator(
          new FakeIncomingInbox(), new OriginalPageOperationApplier(),
          new OriginalPeerInteractionStore(), null),
        (): IncomingOperationSyncCoordinator => IncomingOperationSyncCoordinator.createProduction(
          new FakeIncomingInbox() as never, 0x10000),
      ]) {
        try {
          create();
        } catch (_error) {
          rejected++;
        }
      }
      expect(rejected).assertEqual(2);
    });

    it('decodes the original zgb fields and reroots its nested uq9 operation', 0, () => {
      const decoded = decodeOriginalReceiveOpsEvent('note', receiveOpsEventFixture());
      expect(decoded.schemaVersion).assertEqual(7);
      expect(decoded.expectedAckReply).assertEqual('ack');
      expect(decoded.operations.length).assertEqual(1);
      expect(decoded.operations[0].timestamp).assertEqual(9);
      expect(decoded.operations[0].siteId).assertEqual(3);
      expect(decoded.operations[0].clientTime).assertEqual('11');
      expect(decoded.operations[0].serverTime).assertEqual('12');
      expect(decoded.operations[0].payloadType).assertEqual(3);
    });

    it('acknowledges only after durable receive and ordered processing drain', 0, async () => {
      const inbox = new FakeIncomingInbox();
      const coordinator = new IncomingOperationSyncCoordinator(
        inbox, new OriginalPageOperationApplier());
      const result = await coordinator.receiveOpsEvent(
        'note', receiveOpsEventFixture(), 100, new FakeAcknowledger(inbox.calls));
      expect(result.appliedOperationCount).assertEqual(1);
      expect(result.terminalProcessResult).assertEqual(ProcessSyncedOperationResult.EMPTY);
      expect(inbox.calls.join(',')).assertEqual('receive,process,process,ack:ack');
    });

    it('does not acknowledge when inbox processing fails', 0, async () => {
      const inbox = new FakeIncomingInbox();
      inbox.failProcessing = true;
      const coordinator = new IncomingOperationSyncCoordinator(
        inbox, new OriginalPageOperationApplier());
      let rejected: boolean = false;
      try {
        await coordinator.receiveOpsEvent(
          'note', receiveOpsEventFixture(), 100, new FakeAcknowledger(inbox.calls));
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
      expect(inbox.calls.join(',')).assertEqual('receive,process');
    });

    it('acknowledges an original empty receive event without draining old inbox state', 0, async () => {
      const inbox = new FakeIncomingInbox();
      const payload: Uint8Array = receiveOpsEventFixture();
      writeU32(payload, 32, 0);
      const coordinator = new IncomingOperationSyncCoordinator(
        inbox, new OriginalPageOperationApplier());
      const result = await coordinator.receiveOpsEvent(
        'note', payload, 100, new FakeAcknowledger(inbox.calls));
      expect(result.insertedOperationCount).assertEqual(0);
      expect(result.appliedOperationCount).assertEqual(0);
      expect(inbox.calls.join(',')).assertEqual('ack:ack');
    });
  });
}

function receiveOpsEventFixture(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(112);
  writeU32(bytes, 0, 16);
  writeU16(bytes, 4, 10);
  writeU16(bytes, 6, 16);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 8);
  writeU16(bytes, 12, 12);
  writeU32(bytes, 16, 12);
  writeU32(bytes, 20, 12);
  writeU32(bytes, 24, 80);
  writeU16(bytes, 28, 7);
  writeU32(bytes, 32, 1);
  writeU32(bytes, 36, 20);

  writeU16(bytes, 40, 16);
  writeU16(bytes, 42, 36);
  writeU16(bytes, 44, 4);
  writeU16(bytes, 46, 12);
  writeU16(bytes, 48, 20);
  writeU16(bytes, 52, 28);
  writeU16(bytes, 54, 32);
  writeU32(bytes, 56, 16);
  writeU16(bytes, 60, 3);
  writeU32(bytes, 64, 9);
  writeDecimalU64(bytes, 68, '11');
  writeDecimalU64(bytes, 76, '12');
  bytes[84] = 3;
  writeU32(bytes, 88, 8);

  writeU16(bytes, 92, 4);
  writeU16(bytes, 94, 4);
  writeU32(bytes, 96, 4);
  writeU32(bytes, 104, 3);
  bytes[108] = 0x61;
  bytes[109] = 0x63;
  bytes[110] = 0x6B;
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
