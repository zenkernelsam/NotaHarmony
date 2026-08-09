import { OpSyncMetadata, SequencedOp } from '../core/model/OpTypes';
import { AsyncMutex } from './AsyncMutex';
import { encodeOperationId, validateOperationIdentity } from './OperationIdentity';

export interface OperationSyncStore {
  getSyncMetadata(noteId: string): Promise<OpSyncMetadata>;
  resolveEditorSite(noteId: string, resolvedSiteId: number): Promise<void>;
  getPendingOps(noteId: string, limit: number): Promise<SequencedOp[]>;
  markOpsUploaded(noteId: string, throughSequence: number): Promise<void>;
  acknowledgeUploadedOps(noteId: string, throughSequence: number, maxServerTime: number): Promise<void>;
}

export interface OperationSyncOpenRequest {
  noteId: string;
  editorId: string;
  creatorId: string;
  currentEditorSiteId: number;
  maxServerTime: number | null;
}

export interface OperationSyncSession {
  noteId: string;
  editorSiteId: number;
  sessionId: string;
}

export interface OperationUploadBatch {
  noteId: string;
  sessionId: string;
  editorSiteId: number;
  acknowledgedThroughSequence: number;
  operations: SequencedOp[];
}

export interface OperationUploadAcknowledgement {
  noteId: string;
  sessionId: string;
  editorSiteId: number;
  acknowledgedThroughSequence: number;
  maxServerTime: number;
}

export interface OperationSyncTransport {
  open(request: OperationSyncOpenRequest): Promise<OperationSyncSession>;
  append(batch: OperationUploadBatch): Promise<OperationUploadAcknowledgement>;
}

export interface OperationSyncResult {
  sentOperationCount: number;
  acknowledgedThroughSequence: number;
  maxServerTime: number | null;
}

export class OperationSyncCoordinator {
  private store: OperationSyncStore;
  private transport: OperationSyncTransport;
  private mutex: AsyncMutex = new AsyncMutex();

  constructor(store: OperationSyncStore, transport: OperationSyncTransport) {
    this.store = store;
    this.transport = transport;
  }

  async synchronize(noteId: string, batchLimit: number = 128): Promise<OperationSyncResult> {
    if (noteId.length === 0 || !Number.isSafeInteger(batchLimit) || batchLimit < 1 || batchLimit > 1024) {
      throw new Error('operation sync request is invalid');
    }
    return this.mutex.runExclusive(async (): Promise<OperationSyncResult> => {
      const beforeOpen: OpSyncMetadata = await this.store.getSyncMetadata(noteId);
      const session: OperationSyncSession = await this.transport.open({
        noteId: noteId,
        editorId: beforeOpen.editorId,
        creatorId: beforeOpen.creatorId,
        currentEditorSiteId: beforeOpen.editorSiteId,
        maxServerTime: beforeOpen.maxServerTime,
      });
      validateSession(session, noteId);
      await this.store.resolveEditorSite(noteId, session.editorSiteId);
      const metadata: OpSyncMetadata = await this.store.getSyncMetadata(noteId);
      if (metadata.editorSiteId !== session.editorSiteId) {
        throw new Error('resolved editor site was not persisted');
      }
      const pending: SequencedOp[] = await this.store.getPendingOps(noteId, batchLimit);
      if (pending.length === 0) {
        return {
          sentOperationCount: 0,
          acknowledgedThroughSequence: metadata.ackedThroughSequence,
          maxServerTime: metadata.maxServerTime,
        };
      }
      validatePendingBatch(pending, metadata);
      const expectedSequence: number = pending[pending.length - 1].sequence;
      const acknowledgement: OperationUploadAcknowledgement = await this.transport.append({
        noteId: noteId,
        sessionId: session.sessionId,
        editorSiteId: session.editorSiteId,
        acknowledgedThroughSequence: metadata.ackedThroughSequence,
        operations: pending,
      });
      validateAcknowledgement(acknowledgement, session, expectedSequence, metadata.maxServerTime);
      // Persisting upload after the reply makes a transport retry harmless: stable op identities are resent.
      await this.store.markOpsUploaded(noteId, expectedSequence);
      await this.store.acknowledgeUploadedOps(
        noteId, expectedSequence, acknowledgement.maxServerTime);
      return {
        sentOperationCount: pending.length,
        acknowledgedThroughSequence: expectedSequence,
        maxServerTime: acknowledgement.maxServerTime,
      };
    });
  }
}

export function validateSession(session: OperationSyncSession, expectedNoteId: string): void {
  if (session.noteId !== expectedNoteId || session.sessionId.length === 0) {
    throw new Error('operation sync session identity is invalid');
  }
  validateOperationIdentity({ timestamp: 0, siteId: session.editorSiteId });
}

export function validatePendingBatch(pending: SequencedOp[], metadata: OpSyncMetadata): void {
  let previousSequence: number = metadata.ackedThroughSequence;
  for (const item of pending) {
    const opTimestamp: number | undefined = item.op.opTimestamp;
    const editorSiteId: number | undefined = item.op.editorSiteId;
    if (!Number.isSafeInteger(item.sequence) || item.sequence <= previousSequence ||
      item.op.noteId !== metadata.noteId || opTimestamp === undefined || editorSiteId === undefined ||
      editorSiteId !== metadata.editorSiteId) {
      throw new Error('pending operation batch identity is invalid');
    }
    validateOperationIdentity({ timestamp: opTimestamp, siteId: editorSiteId });
    if (item.op.opId !== encodeOperationId({ timestamp: opTimestamp, siteId: editorSiteId })) {
      throw new Error('pending operation ID does not match its original clock identity');
    }
    previousSequence = item.sequence;
  }
}

export function validateAcknowledgement(acknowledgement: OperationUploadAcknowledgement,
  session: OperationSyncSession, expectedSequence: number, previousServerTime: number | null): void {
  if (acknowledgement.noteId !== session.noteId || acknowledgement.sessionId !== session.sessionId ||
    acknowledgement.editorSiteId !== session.editorSiteId ||
    !Number.isSafeInteger(acknowledgement.acknowledgedThroughSequence) ||
    acknowledgement.acknowledgedThroughSequence !== expectedSequence ||
    !Number.isSafeInteger(acknowledgement.maxServerTime) || acknowledgement.maxServerTime < 0 ||
    (previousServerTime !== null && acknowledgement.maxServerTime < previousServerTime)) {
    throw new Error('operation upload acknowledgement does not match the expected reply');
  }
}
