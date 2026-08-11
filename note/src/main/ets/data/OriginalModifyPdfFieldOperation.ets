import { relationalStore } from '@kit.ArkData';
import { compareOperationIdentity, OperationIdentity, validateOperationIdentity } from
  './OperationIdentity';
import {
  ORIGINAL_ASSET_HASH_BYTES, originalAssetHashBytesToStorageHash,
} from './OriginalAssetCloudPersistedOperation';
import { OriginalFlatBufferTableReader, readOriginalPayloadTable } from
  './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export const ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE: number = 27;
export const ORIGINAL_PDF_FIELD_STRING_VALUE: number = 0;
export const ORIGINAL_PDF_FIELD_BOOLEAN_VALUE: number = 1;
const MAX_PDF_FIELD_TEXT_BYTES: number = 65536;

export interface OriginalModifyPdfFieldPayload {
  storageHash: string;
  key: string;
  valueType: number;
  stringValue: string | null;
  booleanValue: boolean | null;
}

export interface StoredOriginalPdfFieldValue {
  valueType: number;
  stringValue: string | null;
  booleanValue: boolean | null;
  winner: OperationIdentity;
}

export function decodeOriginalModifyPdfField(bytes: Uint8Array): OriginalModifyPdfFieldPayload {
  return decodeOriginalModifyPdfFieldTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE));
}

export function decodeOriginalModifyPdfFieldTable(
  table: OriginalFlatBufferTableReader): OriginalModifyPdfFieldPayload {
  for (let field: number = 5; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error('ModifyPDFField has unsupported fields');
    }
  }
  const hashBytes: Uint8Array | null = table.readInlineBytes(0, ORIGINAL_ASSET_HASH_BYTES);
  const key: string | null = table.readUtf8String(1, true, MAX_PDF_FIELD_TEXT_BYTES);
  if (hashBytes === null || key === null || key.length === 0) {
    throw new Error('ModifyPDFField has no required assetHash or key');
  }
  const valueType: number = table.readUint8(2, ORIGINAL_PDF_FIELD_STRING_VALUE);
  if (valueType !== ORIGINAL_PDF_FIELD_STRING_VALUE &&
    valueType !== ORIGINAL_PDF_FIELD_BOOLEAN_VALUE) {
    throw new Error('ModifyPDFField has an unknown value type');
  }
  const stringValue: string | null = table.readUtf8String(
    3, false, MAX_PDF_FIELD_TEXT_BYTES);
  const hasBoolean: boolean = table.hasField(4);
  const rawBoolean: number = table.readUint8(4, 0);
  if (hasBoolean && rawBoolean !== 0 && rawBoolean !== 1) {
    throw new Error('ModifyPDFField bool is not canonical');
  }
  if ((valueType === ORIGINAL_PDF_FIELD_STRING_VALUE &&
      (stringValue === null || hasBoolean)) ||
    (valueType === ORIGINAL_PDF_FIELD_BOOLEAN_VALUE &&
      (stringValue !== null || !hasBoolean))) {
    throw new Error('ModifyPDFField value does not match its type');
  }
  return {
    storageHash: originalAssetHashBytesToStorageHash(hashBytes),
    key: key,
    valueType: valueType,
    stringValue: stringValue,
    booleanValue: hasBoolean ? rawBoolean === 1 : null,
  };
}

export async function readOriginalPdfFieldValue(store: relationalStore.RdbStore,
  noteId: string, storageHash: string, key: string): Promise<StoredOriginalPdfFieldValue | null> {
  const rows = await store.querySql(
    `SELECT value_type, string_value, boolean_value, winner_timestamp, winner_site_id
     FROM original_pdf_field_state WHERE note_id = ? AND asset_hash = ? AND field_key = ?`,
    [noteId, storageHash, key]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    const valueType: number = rows.getLong(rows.getColumnIndex('value_type'));
    return {
      valueType: valueType,
      stringValue: valueType === ORIGINAL_PDF_FIELD_STRING_VALUE ?
        rows.getString(rows.getColumnIndex('string_value')) : null,
      booleanValue: valueType === ORIGINAL_PDF_FIELD_BOOLEAN_VALUE ?
        rows.getLong(rows.getColumnIndex('boolean_value')) === 1 : null,
      winner: {
        timestamp: rows.getLong(rows.getColumnIndex('winner_timestamp')),
        siteId: rows.getLong(rows.getColumnIndex('winner_site_id')),
      },
    };
  } finally {
    rows.close();
  }
}

export class OriginalModifyPdfFieldOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let table: OriginalFlatBufferTableReader;
    try {
      table = readOriginalPayloadTable(
        operation.rawOperation, ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD' };
    }
    return this.applyTable(store, operation, table);
  }

  preflightTable(table: OriginalFlatBufferTableReader): string | null {
    try {
      decodeOriginalModifyPdfFieldTable(table);
      return null;
    } catch (_error) {
      return 'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD';
    }
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    let payload: OriginalModifyPdfFieldPayload;
    try {
      payload = decodeOriginalModifyPdfFieldTable(table);
      validateOperationIdentity({ timestamp: operation.timestamp, siteId: operation.siteId });
    } catch (_error) {
      return { deferredReason: 'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD' };
    }
    const identityStatus: number = await this.identityStatus(store, operation, payload);
    if (identityStatus < 0) {
      throw new Error('original ModifyPDFField identity conflicts with persisted state');
    }
    if (identityStatus > 0) {
      return { deferredReason: null };
    }
    const current: StoredOriginalPdfFieldValue | null = await readOriginalPdfFieldValue(
      store, operation.noteId, payload.storageHash, payload.key);
    const winner: OperationIdentity = { timestamp: operation.timestamp, siteId: operation.siteId };
    if (current !== null && compareOperationIdentity(winner, current.winner) <= 0) {
      return { deferredReason: null };
    }
    const values: relationalStore.ValuesBucket = pdfFieldValues(operation, payload);
    if (current === null) {
      await store.insert('original_pdf_field_state', values);
    } else {
      const predicates = new relationalStore.RdbPredicates('original_pdf_field_state');
      predicates.equalTo('note_id', operation.noteId);
      predicates.equalTo('asset_hash', payload.storageHash);
      predicates.equalTo('field_key', payload.key);
      if (await store.update(values, predicates) !== 1) {
        throw new Error('original ModifyPDFField lost its persisted register');
      }
    }
    return { deferredReason: null };
  }

  private async identityStatus(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation, payload: OriginalModifyPdfFieldPayload): Promise<number> {
    const rows = await store.querySql(
      `SELECT asset_hash, field_key, value_type, string_value, boolean_value
       FROM original_pdf_field_state WHERE note_id = ?
       AND winner_timestamp = ? AND winner_site_id = ?`,
      [operation.noteId, operation.timestamp, operation.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        return 0;
      }
      const valueType: number = rows.getLong(rows.getColumnIndex('value_type'));
      const sameValue: boolean = valueType === payload.valueType &&
        (valueType === ORIGINAL_PDF_FIELD_STRING_VALUE ?
          rows.getString(rows.getColumnIndex('string_value')) === payload.stringValue :
          (rows.getLong(rows.getColumnIndex('boolean_value')) === 1) === payload.booleanValue);
      return rows.getString(rows.getColumnIndex('asset_hash')) === payload.storageHash &&
        rows.getString(rows.getColumnIndex('field_key')) === payload.key && sameValue ? 1 : -1;
    } finally {
      rows.close();
    }
  }
}

function pdfFieldValues(operation: StoredSyncedOperation,
  payload: OriginalModifyPdfFieldPayload): relationalStore.ValuesBucket {
  return {
    'note_id': operation.noteId,
    'asset_hash': payload.storageHash,
    'field_key': payload.key,
    'value_type': payload.valueType,
    'string_value': payload.stringValue,
    'boolean_value': payload.booleanValue === null ? null : (payload.booleanValue ? 1 : 0),
    'winner_timestamp': operation.timestamp,
    'winner_site_id': operation.siteId,
  };
}
