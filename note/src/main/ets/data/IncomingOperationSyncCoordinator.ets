import { AsyncMutex } from './AsyncMutex';
import {
  DeferredSyncedOperationBundle, DeferredSyncedOperationTableType,
  validateDeferredSyncedOperationBundle,
} from './DeferredSyncedOperationBundle';
import { OriginalPageOperationApplier } from './OriginalPageOperationApplier';
import { validateOperationIdentity } from './OperationIdentity';
import {
  consumeOriginalPeerInteractionBatch, OriginalPeerInteractionBatchResult,
  OriginalPeerInteractionStore,
} from './OriginalPeerInteractionOperation';
import {
  OriginalFlatBufferTableReader, OriginalSyncedOperationEnvelope,
  parseOriginalSyncedOperationEnvelope,
} from './OriginalSyncedOperationFlatBuffer';
import {
  IncomingSyncedOperation, ProcessSyncedOperationResult, ReceiveSyncedOperationsResult,
  SyncedOperationApplier, SyncedOperationInboxStore,
} from './SyncedOperationInbox';

export enum OriginalIncomingOperationBundleType {
  OPS_BUNDLE = 'OPS_BUNDLE',
  RECEIVE_OPS_EVENT = 'RECEIVE_OPS_EVENT',
}

export interface DecodedOriginalIncomingOperationBundle {
  type: OriginalIncomingOperationBundleType;
  schemaVersion: number;
  expectedAckReply: string | null;
  operations: IncomingSyncedOperation[];
}

export interface IncomingOperationInbox {
  receiveBatch(noteId: string, operations: IncomingSyncedOperation[],
    receivedAt: number): Promise<ReceiveSyncedOperationsResult>;
  processHead(noteId: string, applier: SyncedOperationApplier):
    Promise<ProcessSyncedOperationResult>;
}

export interface IncomingOperationAcknowledger {
  acknowledge(expectedAckReply: string): Promise<void>;
}

export interface IncomingOperationSyncResult extends ReceiveSyncedOperationsResult {
  schemaVersion: number;
  appliedOperationCount: number;
  terminalProcessResult: ProcessSyncedOperationResult;
  expectedAckReply: string | null;
  peerInteractionOperationCount: number;
  peerInteractionUpdateCount: number;
  discardedPeerInteractionCount: number;
}

const MAX_INCOMING_OPERATION_COUNT: number = 4096;
const MAX_REROOTED_OPERATION_BYTES: number = 128 * 1024 * 1024;
const MAX_ACK_REPLY_BYTES: number = 4096;

export class IncomingOperationSyncCoordinator {
  private inbox: IncomingOperationInbox;
  private applier: SyncedOperationApplier;
  private peerInteractions: OriginalPeerInteractionStore | null;
  private localSiteId: number | null;
  private mutex: AsyncMutex = new AsyncMutex();

  constructor(inbox: IncomingOperationInbox, applier: SyncedOperationApplier,
    peerInteractions: OriginalPeerInteractionStore | null = null,
    localSiteId: number | null = null) {
    if ((peerInteractions === null) !== (localSiteId === null)) {
      throw new Error('incoming peer interaction configuration is incomplete');
    }
    if (localSiteId !== null) {
      validateOperationIdentity({ timestamp: 0, siteId: localSiteId });
    }
    this.inbox = inbox;
    this.applier = applier;
    this.peerInteractions = peerInteractions;
    this.localSiteId = localSiteId;
  }

  static createProduction(inbox: SyncedOperationInboxStore, localSiteId: number,
    peerInteractions: OriginalPeerInteractionStore = new OriginalPeerInteractionStore()):
    IncomingOperationSyncCoordinator {
    return new IncomingOperationSyncCoordinator(
      inbox, new OriginalPageOperationApplier(), peerInteractions, localSiteId);
  }

  async receiveOpsEvent(noteId: string, payload: Uint8Array, receivedAt: number,
    acknowledger: IncomingOperationAcknowledger): Promise<IncomingOperationSyncResult> {
    const bundle: DecodedOriginalIncomingOperationBundle =
      decodeOriginalReceiveOpsEvent(noteId, payload);
    return this.receiveDecoded(noteId, bundle, receivedAt, acknowledger);
  }

  async replayOpsBundle(noteId: string, payload: Uint8Array,
    receivedAt: number): Promise<IncomingOperationSyncResult> {
    const bundle: DecodedOriginalIncomingOperationBundle = decodeOriginalOpsBundle(noteId, payload);
    return this.receiveDecoded(noteId, bundle, receivedAt, null);
  }

  async replayDeferredBundle(bundle: DeferredSyncedOperationBundle,
    acknowledger: IncomingOperationAcknowledger | null = null):
    Promise<IncomingOperationSyncResult> {
    validateDeferredSyncedOperationBundle(bundle);
    let decoded: DecodedOriginalIncomingOperationBundle;
    if (bundle.tableType === DeferredSyncedOperationTableType.OPS_BUNDLE) {
      decoded = decodeOriginalOpsBundle(bundle.noteId, bundle.payload);
    } else if (bundle.tableType === DeferredSyncedOperationTableType.RECEIVE_OPS_EVENT) {
      decoded = decodeOriginalReceiveOpsEvent(bundle.noteId, bundle.payload);
    } else {
      throw new Error('NOTE_BUNDLE must use its page-identity bootstrap transaction');
    }
    if (decoded.schemaVersion !== bundle.schemaVersion) {
      throw new Error('deferred incoming operation bundle schema version is inconsistent');
    }
    return this.receiveDecoded(bundle.noteId, decoded, bundle.receivedAt, acknowledger);
  }

  private async receiveDecoded(noteId: string, bundle: DecodedOriginalIncomingOperationBundle,
    receivedAt: number, acknowledger: IncomingOperationAcknowledger | null):
    Promise<IncomingOperationSyncResult> {
    if (noteId.length === 0 || !Number.isSafeInteger(receivedAt) || receivedAt < 0) {
      throw new Error('incoming operation sync request is invalid');
    }
    if ((bundle.expectedAckReply === null) !== (acknowledger === null)) {
      throw new Error('incoming operation sync acknowledgement contract is invalid');
    }
    return this.mutex.runExclusive(async (): Promise<IncomingOperationSyncResult> => {
      if (bundle.operations.length === 0) {
        if (acknowledger !== null && bundle.expectedAckReply !== null) {
          await acknowledger.acknowledge(bundle.expectedAckReply);
        }
        return {
          insertedOperationCount: 0,
          duplicateOperationCount: 0,
          lastServerTime: null,
          schemaVersion: bundle.schemaVersion,
          appliedOperationCount: 0,
          terminalProcessResult: ProcessSyncedOperationResult.EMPTY,
          expectedAckReply: bundle.expectedAckReply,
          peerInteractionOperationCount: 0,
          peerInteractionUpdateCount: 0,
          discardedPeerInteractionCount: 0,
        };
      }
      let peers: OriginalPeerInteractionBatchResult = {
        operationCount: 0, updateCount: 0, discardedCount: 0,
      };
      if (this.peerInteractions !== null && this.localSiteId !== null) {
        peers = consumeOriginalPeerInteractionBatch(
          noteId, bundle.operations, this.peerInteractions, this.localSiteId);
      }
      const received: ReceiveSyncedOperationsResult =
        await this.inbox.receiveBatch(noteId, bundle.operations, receivedAt);
      let appliedOperationCount: number = 0;
      let terminal: ProcessSyncedOperationResult;
      while (true) {
        terminal = await this.inbox.processHead(noteId, this.applier);
        if (terminal !== ProcessSyncedOperationResult.APPLIED) {
          break;
        }
        appliedOperationCount++;
      }
      if (acknowledger !== null && bundle.expectedAckReply !== null) {
        await acknowledger.acknowledge(bundle.expectedAckReply);
      }
      return {
        insertedOperationCount: received.insertedOperationCount,
        duplicateOperationCount: received.duplicateOperationCount,
        lastServerTime: received.lastServerTime,
        schemaVersion: bundle.schemaVersion,
        appliedOperationCount: appliedOperationCount,
        terminalProcessResult: terminal,
        expectedAckReply: bundle.expectedAckReply,
        peerInteractionOperationCount: peers.operationCount,
        peerInteractionUpdateCount: peers.updateCount,
        discardedPeerInteractionCount: peers.discardedCount,
      };
    });
  }
}

export function decodeOriginalOpsBundle(noteId: string,
  payload: Uint8Array): DecodedOriginalIncomingOperationBundle {
  const root: OriginalFlatBufferTableReader = OriginalFlatBufferTableReader.fromRoot(payload);
  const schemaVersion: number = root.readUint16(1, 0);
  return {
    type: OriginalIncomingOperationBundleType.OPS_BUNDLE,
    schemaVersion: schemaVersion,
    expectedAckReply: null,
    operations: decodeOperations(noteId, schemaVersion,
      root.readTableVectorAsRoots(
        0, MAX_INCOMING_OPERATION_COUNT, MAX_REROOTED_OPERATION_BYTES)),
  };
}

export function decodeOriginalReceiveOpsEvent(noteId: string,
  payload: Uint8Array): DecodedOriginalIncomingOperationBundle {
  const root: OriginalFlatBufferTableReader = OriginalFlatBufferTableReader.fromRoot(payload);
  const expectedAckReply: string | null = root.readUtf8String(1, true, MAX_ACK_REPLY_BYTES);
  if (expectedAckReply === null) {
    throw new Error('original receive-ops event has no expected ACK reply');
  }
  const schemaVersion: number = root.readUint16(2, 0);
  return {
    type: OriginalIncomingOperationBundleType.RECEIVE_OPS_EVENT,
    schemaVersion: schemaVersion,
    expectedAckReply: expectedAckReply,
    operations: decodeOperations(noteId, schemaVersion,
      root.readTableVectorAsRoots(
        0, MAX_INCOMING_OPERATION_COUNT, MAX_REROOTED_OPERATION_BYTES)),
  };
}

function decodeOperations(noteId: string, schemaVersion: number,
  rawOperations: Uint8Array[]): IncomingSyncedOperation[] {
  if (noteId.length === 0) {
    throw new Error('original incoming operation note id is invalid');
  }
  return rawOperations.map((rawOperation: Uint8Array): IncomingSyncedOperation => {
    const envelope: OriginalSyncedOperationEnvelope =
      parseOriginalSyncedOperationEnvelope(rawOperation);
    return {
      noteId: noteId,
      timestamp: envelope.timestamp,
      siteId: envelope.siteId,
      clientTime: envelope.clientTime,
      serverTime: envelope.serverTime,
      audioTime: envelope.audioTime,
      schemaVersion: schemaVersion,
      payloadType: envelope.payloadType,
      rawOperation: rawOperation,
    };
  });
}
