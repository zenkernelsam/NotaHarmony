import { describe, it, expect } from '@ohos/hypium';
import { Op, OpSyncMetadata, OpType, SequencedOp } from '../main/ets/core/model/OpTypes';
import {
  OperationSyncCoordinator, OperationSyncOpenRequest, OperationSyncSession, OperationSyncStore,
  OperationSyncTransport, OperationUploadAcknowledgement, OperationUploadBatch,
} from '../main/ets/data/OperationSyncCoordinator';

function metadata(siteId: number = 7): OpSyncMetadata {
  return {
    noteId: 'note', editorSiteId: siteId, editorId: 'editor', creatorId: 'creator',
    createdAt: 1, updatedAt: 1, syncedOpCount: 0, maxOpTimestamp: 2,
    maxServerTime: null, schemaVersion: 1, uploadedThroughSequence: 0, ackedThroughSequence: 0,
  };
}

function operation(timestamp: number, sequence: number, siteId: number = 7): SequencedOp {
  const op: Op = {
    opId: `op:${timestamp.toString(16)}:${siteId.toString(16)}`, noteId: 'note',
    opType: OpType.UPDATE_TITLE, payload: new Uint8Array([timestamp]), clientTime: timestamp,
    opTimestamp: timestamp, editorSiteId: siteId, uploadImmediately: false,
  };
  return { sequence: sequence, op: op };
}

class FakeSyncStore implements OperationSyncStore {
  value: OpSyncMetadata = metadata();
  pending: SequencedOp[] = [operation(1, 2), operation(2, 4)];
  calls: string[] = [];
  rejectSiteChange: boolean = false;

  async getSyncMetadata(_noteId: string): Promise<OpSyncMetadata> { return this.value; }
  async resolveEditorSite(_noteId: string, resolvedSiteId: number): Promise<void> {
    this.calls.push(`site:${resolvedSiteId}`);
    if (this.rejectSiteChange && resolvedSiteId !== this.value.editorSiteId) {
      throw new Error('identity already established');
    }
    this.value.editorSiteId = resolvedSiteId;
  }
  async getPendingOps(_noteId: string, _limit: number): Promise<SequencedOp[]> { return this.pending; }
  async markOpsUploaded(_noteId: string, throughSequence: number): Promise<void> {
    this.calls.push(`upload:${throughSequence}`);
    this.value.uploadedThroughSequence = throughSequence;
  }
  async acknowledgeUploadedOps(_noteId: string, throughSequence: number,
    maxServerTime: string): Promise<void> {
    this.calls.push(`ack:${throughSequence}`);
    this.value.ackedThroughSequence = throughSequence;
    this.value.maxServerTime = maxServerTime;
  }
}

class FakeSyncTransport implements OperationSyncTransport {
  siteId: number = 7;
  acknowledgedSequence: number = 4;
  serverTime: string = '100';
  appendCount: number = 0;

  async open(request: OperationSyncOpenRequest): Promise<OperationSyncSession> {
    return { noteId: request.noteId, editorSiteId: this.siteId, sessionId: 'session' };
  }
  async append(batch: OperationUploadBatch): Promise<OperationUploadAcknowledgement> {
    this.appendCount++;
    return {
      noteId: batch.noteId, editorSiteId: batch.editorSiteId, sessionId: batch.sessionId,
      acknowledgedThroughSequence: this.acknowledgedSequence, maxServerTime: this.serverTime,
    };
  }
}

export default function operationSyncCoordinatorTest() {
  describe('OperationSyncCoordinator', () => {
    it('persists only an exact acknowledgement for the sent ordered batch', 0, async () => {
      const store = new FakeSyncStore();
      const coordinator = new OperationSyncCoordinator(store, new FakeSyncTransport());
      const result = await coordinator.synchronize('note', 16);
      expect(result.sentOperationCount).assertEqual(2);
      expect(result.acknowledgedThroughSequence).assertEqual(4);
      expect(store.calls.join(',')).assertEqual('site:7,upload:4,ack:4');
    });

    it('does not advance local watermarks for a missing expected ACK reply', 0, async () => {
      const store = new FakeSyncStore();
      const transport = new FakeSyncTransport();
      transport.acknowledgedSequence = 2;
      let rejected: boolean = false;
      try {
        await new OperationSyncCoordinator(store, transport).synchronize('note');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
      expect(store.calls.join(',')).assertEqual('site:7');
      expect(store.value.uploadedThroughSequence).assertEqual(0);
      expect(store.value.ackedThroughSequence).assertEqual(0);
    });

    it('rejects a lossless server cursor that moves behind the durable cursor', 0, async () => {
      const store = new FakeSyncStore();
      store.value.maxServerTime = '9007199254740993';
      const transport = new FakeSyncTransport();
      transport.serverTime = '9007199254740992';
      let rejected: boolean = false;
      try {
        await new OperationSyncCoordinator(store, transport).synchronize('note');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
      expect(store.calls.join(',')).assertEqual('site:7');
      expect(store.value.uploadedThroughSequence).assertEqual(0);
      expect(store.value.ackedThroughSequence).assertEqual(0);
    });

    it('refuses to rewrite an established operation site from a server session', 0, async () => {
      const store = new FakeSyncStore();
      store.rejectSiteChange = true;
      const transport = new FakeSyncTransport();
      transport.siteId = 8;
      let rejected: boolean = false;
      try {
        await new OperationSyncCoordinator(store, transport).synchronize('note');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
      expect(transport.appendCount).assertEqual(0);
      expect(store.value.editorSiteId).assertEqual(7);
    });

    it('adopts a server site before the first operation exists', 0, async () => {
      const store = new FakeSyncStore();
      store.value = metadata(0);
      store.value.maxOpTimestamp = 0;
      store.pending = [];
      const transport = new FakeSyncTransport();
      transport.siteId = 9;
      const result = await new OperationSyncCoordinator(store, transport).synchronize('note');
      expect(result.sentOperationCount).assertEqual(0);
      expect(store.value.editorSiteId).assertEqual(9);
      expect(transport.appendCount).assertEqual(0);
    });
  });
}
