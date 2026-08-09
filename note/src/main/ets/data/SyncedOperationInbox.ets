import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
import {
  encodeOperationId, OperationIdentity, validateOperationIdentity,
} from './OperationIdentity';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

export enum SyncedOperationInboxState {
  RECEIVED = 0,
  DEFERRED = 1,
  APPLIED = 2,
}

export interface IncomingSyncedOperation extends OperationIdentity {
  noteId: string;
  clientTime: string;
  serverTime: string;
  schemaVersion: number;
  payloadType: number;
  rawOperation: Uint8Array;
}

export interface StoredSyncedOperation extends IncomingSyncedOperation {
  state: SyncedOperationInboxState;
  deferredReason: string | null;
  receivedAt: number;
}

export interface ReceiveSyncedOperationsResult {
  insertedOperationCount: number;
  duplicateOperationCount: number;
  lastServerTime: string | null;
}

const MAX_SYNCED_BATCH_COUNT: number = 4096;
const MAX_RAW_OPERATION_BYTES: number = 64 * 1024 * 1024;
const MAX_SYNCED_BATCH_BYTES: number = 128 * 1024 * 1024;

export function validateIncomingSyncedBatch(noteId: string,
  operations: IncomingSyncedOperation[]): void {
  if (noteId.length === 0 || operations.length > MAX_SYNCED_BATCH_COUNT) {
    throw new Error('incoming synced operation batch is invalid');
  }
  const identities: Set<string> = new Set<string>();
  let previous: IncomingSyncedOperation | null = null;
  let totalBytes: number = 0;
  for (const operation of operations) {
    validateIncomingSyncedOperation(operation, noteId);
    totalBytes += operation.rawOperation.length;
    if (!Number.isSafeInteger(totalBytes) || totalBytes > MAX_SYNCED_BATCH_BYTES) {
      throw new Error('incoming synced operation batch exceeds the byte budget');
    }
    const identity: string = encodeOperationId(operation);
    if (identities.has(identity)) {
      throw new Error('incoming synced operation batch repeats an operation identity');
    }
    identities.add(identity);
    if (previous !== null && compareIncomingSyncedOperationOrder(previous, operation) > 0) {
      throw new Error('incoming synced operation batch is not server-time ordered');
    }
    previous = operation;
  }
}

export function compareIncomingSyncedOperationOrder(left: IncomingSyncedOperation,
  right: IncomingSyncedOperation): number {
  let compared: number = compareUnsignedLongDecimal(left.serverTime, right.serverTime);
  if (compared !== 0) {
    return compared;
  }
  compared = compareUnsignedLongDecimal(left.clientTime, right.clientTime);
  return compared;
}

export function validateIncomingSyncedOperation(operation: IncomingSyncedOperation,
  expectedNoteId: string): void {
  if (operation.noteId !== expectedNoteId ||
    !Number.isSafeInteger(operation.schemaVersion) ||
    operation.schemaVersion < 0 || operation.schemaVersion > 65535 ||
    !Number.isSafeInteger(operation.payloadType) ||
    operation.payloadType < 0 || operation.payloadType > 255 ||
    operation.rawOperation.length < 1 || operation.rawOperation.length > MAX_RAW_OPERATION_BYTES) {
    throw new Error('incoming synced operation is invalid');
  }
  validateOperationIdentity(operation);
  validateUnsignedLongDecimal(operation.clientTime);
  validateUnsignedLongDecimal(operation.serverTime);
}

export class SyncedOperationInboxStore {
  private store: relationalStore.RdbStore;

  constructor(db: DatabaseManager) {
    this.store = db.getStore();
  }

  async receiveBatch(noteId: string, operations: IncomingSyncedOperation[],
    receivedAt: number): Promise<ReceiveSyncedOperationsResult> {
    validateIncomingSyncedBatch(noteId, operations);
    const snapshot: IncomingSyncedOperation[] = operations.map(
      (operation: IncomingSyncedOperation): IncomingSyncedOperation => ({
        noteId: operation.noteId,
        timestamp: operation.timestamp,
        siteId: operation.siteId,
        clientTime: operation.clientTime,
        serverTime: operation.serverTime,
        schemaVersion: operation.schemaVersion,
        payloadType: operation.payloadType,
        rawOperation: operation.rawOperation.slice(),
      }));
    validateIncomingSyncedBatch(noteId, snapshot);
    if (!Number.isSafeInteger(receivedAt) || receivedAt < 0) {
      throw new Error('incoming synced operation receive time is invalid');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<ReceiveSyncedOperationsResult> => {
      await this.store.beginTransaction();
      try {
        await this.requireNote(noteId);
        let insertedOperationCount: number = 0;
        let duplicateOperationCount: number = 0;
        for (const operation of snapshot) {
          const existing: StoredSyncedOperation | null = await this.readByIdentity(noteId, operation);
          if (existing !== null) {
            if (!sameIncomingOperation(existing, operation)) {
              throw new Error('incoming synced operation identity has conflicting bytes or metadata');
            }
            duplicateOperationCount++;
            continue;
          }
          const values: relationalStore.ValuesBucket = {
            'note_id': noteId,
            'op_timestamp': operation.timestamp,
            'editor_site_id': operation.siteId,
            'client_time': operation.clientTime,
            'server_time': operation.serverTime,
            'schema_version': operation.schemaVersion,
            'payload_type': operation.payloadType,
            'raw_operation': operation.rawOperation.slice(),
            'state': SyncedOperationInboxState.RECEIVED,
            'received_at': receivedAt,
          };
          await this.store.insert('synced_operation_inbox', values);
          insertedOperationCount++;
        }
        await this.store.commit();
        return {
          insertedOperationCount: insertedOperationCount,
          duplicateOperationCount: duplicateOperationCount,
          lastServerTime: snapshot.length === 0 ? null : snapshot[snapshot.length - 1].serverTime,
        };
      } catch (e) {
        await this.store.rollBack();
        throw new Error(`receive synced operations failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getReceived(noteId: string, limit: number = 128): Promise<StoredSyncedOperation[]> {
    if (noteId.length === 0 || !Number.isSafeInteger(limit) || limit < 1 || limit > 1024) {
      throw new Error('received synced operation query is invalid');
    }
    const rows = await this.store.querySql(
      `SELECT note_id, op_timestamp, editor_site_id, client_time, server_time,
        schema_version, payload_type, raw_operation, state, deferred_reason, received_at
       FROM synced_operation_inbox WHERE note_id = ? AND state = ?
       ORDER BY length(server_time), server_time, length(client_time), client_time,
         op_timestamp, editor_site_id LIMIT ?`,
      [noteId, SyncedOperationInboxState.RECEIVED, limit]);
    const result: StoredSyncedOperation[] = [];
    try {
      while (rows.goToNextRow()) {
        result.push(readStoredSyncedOperation(rows));
      }
    } finally {
      rows.close();
    }
    return result;
  }

  private async requireNote(noteId: string): Promise<void> {
    const rows = await this.store.querySql('SELECT id FROM note_meta WHERE id = ?', [noteId]);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('incoming synced operation note does not exist');
      }
    } finally {
      rows.close();
    }
  }

  private async readByIdentity(noteId: string,
    identity: OperationIdentity): Promise<StoredSyncedOperation | null> {
    const rows = await this.store.querySql(
      `SELECT note_id, op_timestamp, editor_site_id, client_time, server_time,
        schema_version, payload_type, raw_operation, state, deferred_reason, received_at
       FROM synced_operation_inbox
       WHERE note_id = ? AND op_timestamp = ? AND editor_site_id = ?`,
      [noteId, identity.timestamp, identity.siteId]);
    try {
      return rows.goToFirstRow() ? readStoredSyncedOperation(rows) : null;
    } finally {
      rows.close();
    }
  }
}

function readStoredSyncedOperation(rows: relationalStore.ResultSet): StoredSyncedOperation {
  const deferredReasonColumn: number = rows.getColumnIndex('deferred_reason');
  const operation: StoredSyncedOperation = {
    noteId: rows.getString(rows.getColumnIndex('note_id')),
    timestamp: rows.getLong(rows.getColumnIndex('op_timestamp')),
    siteId: rows.getLong(rows.getColumnIndex('editor_site_id')),
    clientTime: rows.getString(rows.getColumnIndex('client_time')),
    serverTime: rows.getString(rows.getColumnIndex('server_time')),
    schemaVersion: rows.getLong(rows.getColumnIndex('schema_version')),
    payloadType: rows.getLong(rows.getColumnIndex('payload_type')),
    rawOperation: rows.getBlob(rows.getColumnIndex('raw_operation')),
    state: rows.getLong(rows.getColumnIndex('state')) as SyncedOperationInboxState,
    deferredReason: rows.isColumnNull(deferredReasonColumn) ? null : rows.getString(deferredReasonColumn),
    receivedAt: rows.getLong(rows.getColumnIndex('received_at')),
  };
  validateIncomingSyncedOperation(operation, operation.noteId);
  if (!Number.isSafeInteger(operation.receivedAt) || operation.receivedAt < 0 ||
    operation.state < SyncedOperationInboxState.RECEIVED ||
    operation.state > SyncedOperationInboxState.APPLIED ||
    (operation.state === SyncedOperationInboxState.DEFERRED) !==
      (operation.deferredReason !== null && operation.deferredReason.length > 0)) {
    throw new Error('stored synced operation is corrupt');
  }
  return operation;
}

function sameIncomingOperation(stored: StoredSyncedOperation,
  incoming: IncomingSyncedOperation): boolean {
  return stored.noteId === incoming.noteId && stored.timestamp === incoming.timestamp &&
    stored.siteId === incoming.siteId && stored.clientTime === incoming.clientTime &&
    stored.serverTime === incoming.serverTime && stored.schemaVersion === incoming.schemaVersion &&
    stored.payloadType === incoming.payloadType && sameBytes(stored.rawOperation, incoming.rawOperation);
}

function sameBytes(left: Uint8Array, right: Uint8Array): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index: number = 0; index < left.length; index++) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}
