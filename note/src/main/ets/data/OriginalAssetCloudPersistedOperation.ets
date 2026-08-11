import { relationalStore } from '@kit.ArkData';
import {
  OriginalFlatBufferTableReader, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE: number = 2;

const ASSET_HASH_BYTES: number = 64;
const HEX_DIGITS: string = '0123456789abcdef';

export interface OriginalAssetCloudPersistedPayload {
  storageHash: string;
}

export function decodeOriginalAssetCloudPersistedTable(
  table: OriginalFlatBufferTableReader): OriginalAssetCloudPersistedPayload {
  const bytes: Uint8Array | null = table.readInlineBytes(0, ASSET_HASH_BYTES);
  if (bytes === null) {
    throw new Error('AssetCloudPersisted has no required assetHash');
  }
  let storageHash: string = '';
  for (let index: number = 0; index < bytes.length; index++) {
    storageHash += HEX_DIGITS.charAt((bytes[index] >>> 4) & 0x0F);
    storageHash += HEX_DIGITS.charAt(bytes[index] & 0x0F);
  }
  return { storageHash: storageHash };
}

export class OriginalAssetCloudPersistedOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let table: OriginalFlatBufferTableReader;
    try {
      table = readOriginalPayloadTable(
        operation.rawOperation, ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_ASSET_CLOUD_PERSISTED_PAYLOAD' };
    }
    return this.applyTable(store, operation, table);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    try {
      decodeOriginalAssetCloudPersistedTable(table);
    } catch (_error) {
      return 'MALFORMED_ASSET_CLOUD_PERSISTED_PAYLOAD';
    }
    for (let field: number = 1; field <= 1024; field++) {
      if (table.hasField(field)) {
        return 'ASSET_CLOUD_PERSISTED_FIELDS_UNSUPPORTED';
      }
    }
    return null;
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    const reason: string | null = this.preflightTable(table);
    if (reason !== null) {
      return { deferredReason: reason };
    }
    const payload: OriginalAssetCloudPersistedPayload =
      decodeOriginalAssetCloudPersistedTable(table);
    await store.executeSql(
      `INSERT OR IGNORE INTO original_asset_cloud_state
       (note_id, asset_hash, cloud_persisted) VALUES (?, ?, 1)`,
      [operation.noteId, payload.storageHash]);
    return { deferredReason: null };
  }
}
