import { relationalStore } from '@kit.ArkData';
import { DatabaseManager } from './DatabaseManager';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
import { crc32Signed, validateFlatBufferRoot } from './OriginalSyncedOperationFlatBuffer';
import {
  OriginalNoteBundlePageIdentityBootstrapper, OriginalPageIdentityBootstrapResult,
} from './OriginalNoteBundlePageIdentity';

export enum DeferredSyncedOperationTableType {
  NOTE_BUNDLE = 'NOTE_BUNDLE',
  OPS_BUNDLE = 'OPS_BUNDLE',
  RECEIVE_OPS_EVENT = 'RECEIVE_OPS_EVENT',
}

export interface DeferredSyncedOperationBundle {
  id: number;
  noteId: string;
  schemaVersion: number;
  tableType: DeferredSyncedOperationTableType;
  payload: Uint8Array;
  payloadSize: number;
  checksum: number;
  receivedAt: number;
}

const MAX_DEFERRED_BUNDLE_BYTES: number = 64 * 1024 * 1024;

export function validateDeferredSyncedOperationTableType(value: string):
  DeferredSyncedOperationTableType {
  if (value === DeferredSyncedOperationTableType.NOTE_BUNDLE) {
    return DeferredSyncedOperationTableType.NOTE_BUNDLE;
  }
  if (value === DeferredSyncedOperationTableType.OPS_BUNDLE) {
    return DeferredSyncedOperationTableType.OPS_BUNDLE;
  }
  if (value === DeferredSyncedOperationTableType.RECEIVE_OPS_EVENT) {
    return DeferredSyncedOperationTableType.RECEIVE_OPS_EVENT;
  }
  throw new Error('unknown original deferred synced-operation table type');
}

export class DeferredSyncedOperationBundleStore {
  private store: relationalStore.RdbStore;

  constructor(db: DatabaseManager) {
    this.store = db.getStore();
  }

  async put(noteId: string, schemaVersion: number, tableType: DeferredSyncedOperationTableType,
    payload: Uint8Array, receivedAt: number): Promise<number> {
    validateBundleInput(noteId, schemaVersion, tableType, payload, receivedAt);
    const snapshot: Uint8Array = payload.slice();
    validateBundleInput(noteId, schemaVersion, tableType, snapshot, receivedAt);
    const checksum: number = crc32Signed(snapshot);
    return editorPersistenceMutex.runExclusive(async (): Promise<number> => {
      await this.store.beginTransaction();
      try {
        await requireNote(this.store, noteId);
        const values: relationalStore.ValuesBucket = {
          'note_id': noteId,
          'schema_version': schemaVersion,
          'table_type': tableType,
          'payload': snapshot,
          'payload_size': snapshot.length,
          'checksum': checksum,
          'received_at': receivedAt,
        };
        const id: number = await this.store.insert('deferred_synced_operation_bundle', values);
        await this.store.commit();
        return id;
      } catch (e) {
        await this.store.rollBack();
        throw new Error(`persist deferred synced-operation bundle failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async get(id: number): Promise<DeferredSyncedOperationBundle | null> {
    if (!Number.isSafeInteger(id) || id < 1) {
      throw new Error('deferred synced-operation bundle id is invalid');
    }
    return this.readStoredBundle(id);
  }

  async bootstrapOriginalPageIdentity(id: number): Promise<OriginalPageIdentityBootstrapResult> {
    if (!Number.isSafeInteger(id) || id < 1) {
      throw new Error('deferred synced-operation bundle id is invalid');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<OriginalPageIdentityBootstrapResult> => {
      await this.store.beginTransaction();
      try {
        const bundle: DeferredSyncedOperationBundle | null = await this.readStoredBundle(id);
        if (bundle === null) {
          throw new Error('deferred synced-operation bundle does not exist');
        }
        if (bundle.tableType !== DeferredSyncedOperationTableType.NOTE_BUNDLE) {
          await this.store.commit();
          return { applied: false, deferredReason: 'DEFERRED_BUNDLE_IS_NOT_NOTE_BUNDLE' };
        }
        await requireNote(this.store, bundle.noteId);
        const result: OriginalPageIdentityBootstrapResult =
          await new OriginalNoteBundlePageIdentityBootstrapper().apply(
            this.store, bundle.noteId, bundle.schemaVersion, bundle.payload);
        await this.store.commit();
        return result;
      } catch (e) {
        await this.store.rollBack();
        throw new Error(`bootstrap original page identity failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async readStoredBundle(id: number): Promise<DeferredSyncedOperationBundle | null> {
    const rows = await this.store.querySql(
      `SELECT id, note_id, schema_version, table_type, payload, payload_size, checksum, received_at
       FROM deferred_synced_operation_bundle WHERE id = ?`, [id]);
    try {
      if (!rows.goToFirstRow()) {
        return null;
      }
      const payload: Uint8Array = rows.getBlob(rows.getColumnIndex('payload'));
      const bundle: DeferredSyncedOperationBundle = {
        id: rows.getLong(rows.getColumnIndex('id')),
        noteId: rows.getString(rows.getColumnIndex('note_id')),
        schemaVersion: rows.getLong(rows.getColumnIndex('schema_version')),
        tableType: validateDeferredSyncedOperationTableType(
          rows.getString(rows.getColumnIndex('table_type'))),
        payload: payload,
        payloadSize: rows.getLong(rows.getColumnIndex('payload_size')),
        checksum: rows.getLong(rows.getColumnIndex('checksum')),
        receivedAt: rows.getLong(rows.getColumnIndex('received_at')),
      };
      validateStoredBundle(bundle);
      return bundle;
    } finally {
      rows.close();
    }
  }
}

function validateBundleInput(noteId: string, schemaVersion: number,
  tableType: DeferredSyncedOperationTableType, payload: Uint8Array, receivedAt: number): void {
  if (noteId.length === 0 || !Number.isSafeInteger(schemaVersion) || schemaVersion < 0 ||
    schemaVersion > 0xFFFF || !Number.isSafeInteger(receivedAt) || receivedAt < 0 ||
    payload.length < 1 || payload.length > MAX_DEFERRED_BUNDLE_BYTES) {
    throw new Error('deferred synced-operation bundle is invalid');
  }
  validateDeferredSyncedOperationTableType(tableType);
  validateFlatBufferRoot(payload);
}

function validateStoredBundle(bundle: DeferredSyncedOperationBundle): void {
  validateBundleInput(bundle.noteId, bundle.schemaVersion, bundle.tableType,
    bundle.payload, bundle.receivedAt);
  if (bundle.payload.length !== bundle.payloadSize || crc32Signed(bundle.payload) !== bundle.checksum) {
    throw new Error('deferred synced-operation bundle length or CRC32 is corrupt');
  }
}

async function requireNote(store: relationalStore.RdbStore, noteId: string): Promise<void> {
  const rows = await store.querySql('SELECT id FROM note_meta WHERE id = ?', [noteId]);
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('deferred synced-operation bundle note does not exist');
    }
  } finally {
    rows.close();
  }
}
