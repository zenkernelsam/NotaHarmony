import { relationalStore } from '@kit.ArkData';
import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import { compareOperationIdentity, OperationIdentity, validateOperationIdentity } from
  './OperationIdentity';
import { decodeOriginalAssetMetadata } from './OriginalAssetMetadata';
import {
  OriginalAssetReferenceConflict, mergeOriginalAssetReference,
} from './OriginalAssetReferenceStore';
import { readOriginalEntityVisibilityWinner } from './OriginalEntityVisibilityState';
import {
  OriginalFlatBufferTableReader, readOriginalInlineUint64Decimal, readOriginalPayloadTable,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

export const ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE: number = 5;
export const ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE: number = 6;
const MAX_RECORDING_NAME_BYTES: number = 65536;
const MAX_RECORDING_SEGMENTS: number = 10000;

export interface OriginalRecordingSegment {
  startTime: string;
  endTime: string;
}

export interface OriginalCreateRecordingPayload {
  metadata: OriginalAssetMetadata;
  startTime: string;
  endTime: string;
  name: string | null;
  segments: OriginalRecordingSegment[] | null;
  zIndex: string | null;
}

export interface OriginalModifyRecordingPayload {
  recording: OperationIdentity;
  name: string | null;
  segments: OriginalRecordingSegment[] | null;
  zIndex: string | null;
}

interface StoredRecordingBounds {
  startTime: string;
  endTime: string;
}

export function decodeOriginalCreateRecording(bytes: Uint8Array): OriginalCreateRecordingPayload {
  return decodeOriginalCreateRecordingTable(
    readOriginalPayloadTable(bytes, ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE));
}

export function decodeOriginalCreateRecordingTable(
  table: OriginalFlatBufferTableReader): OriginalCreateRecordingPayload {
  rejectFieldsFrom(table, 6, 'CreateRecording payload');
  const recording: OriginalFlatBufferTableReader | null = table.readTable(0);
  if (recording === null) {
    throw new Error('CreateRecording recording asset is missing');
  }
  rejectFieldsFrom(recording, 1, 'RecordingAsset');
  const metadataTable: OriginalFlatBufferTableReader | null = recording.readTable(0);
  if (metadataTable === null) {
    throw new Error('RecordingAsset metadata is missing');
  }
  rejectFieldsFrom(metadataTable, 4, 'Recording asset metadata');
  const startTime: string = table.readUint64Decimal(1, '0') as string;
  const endTime: string = table.readUint64Decimal(2, '0') as string;
  validateUnsignedLongDecimal(startTime);
  validateUnsignedLongDecimal(endTime);
  if (compareUnsignedLongDecimal(startTime, endTime) > 0) {
    throw new Error('CreateRecording starts after it ends');
  }
  const segments: OriginalRecordingSegment[] | null = decodeSegments(table, 4);
  if (segments !== null) {
    for (const segment of segments) {
      // yn2.a() deliberately checks only this bound for inbound CREATE_RECORDING.
      if (compareUnsignedLongDecimal(segment.endTime, endTime) > 0) {
        throw new Error('CreateRecording segment extends beyond recording end');
      }
    }
  }
  const zIndex: string | null = table.readUint64Decimal(5, null);
  if (zIndex !== null) {
    validateUnsignedLongDecimal(zIndex);
  }
  return {
    metadata: decodeOriginalAssetMetadata(metadataTable),
    startTime: startTime,
    endTime: endTime,
    name: table.readUtf8String(3, false, MAX_RECORDING_NAME_BYTES),
    segments: segments,
    zIndex: zIndex,
  };
}

export function decodeOriginalModifyRecording(bytes: Uint8Array): OriginalModifyRecordingPayload {
  return decodeOriginalModifyRecordingTable(
    readOriginalPayloadTable(bytes, ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE));
}

export function decodeOriginalModifyRecordingTable(
  table: OriginalFlatBufferTableReader): OriginalModifyRecordingPayload {
  rejectFieldsFrom(table, 4, 'ModifyRecording payload');
  const rawRecording: Uint8Array | null = table.readInlineBytes(0, 8);
  if (rawRecording === null) {
    throw new Error('ModifyRecording target is missing');
  }
  const zIndex: string | null = table.readUint64Decimal(3, null);
  if (zIndex !== null) {
    validateUnsignedLongDecimal(zIndex);
  }
  return {
    recording: readIdentity(rawRecording),
    name: table.readUtf8String(1, false, MAX_RECORDING_NAME_BYTES),
    segments: decodeSegments(table, 2),
    zIndex: zIndex,
  };
}

export class OriginalRecordingOperationApplier implements SyncedOperationApplier {
  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let table: OriginalFlatBufferTableReader;
    try {
      table = readOriginalPayloadTable(operation.rawOperation, operation.payloadType);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_RECORDING_PAYLOAD' };
    }
    return this.applyTable(store, operation, table);
  }

  preflightTable(table: OriginalFlatBufferTableReader, payloadType: number): string | null {
    try {
      if (payloadType === ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE) {
        decodeOriginalCreateRecordingTable(table);
      } else if (payloadType === ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE) {
        decodeOriginalModifyRecordingTable(table);
      } else {
        return 'RECORDING_PAYLOAD_TYPE_UNSUPPORTED';
      }
      return null;
    } catch (_error) {
      return 'MALFORMED_RECORDING_PAYLOAD';
    }
  }

  async applyTable(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    table: OriginalFlatBufferTableReader): Promise<SyncedOperationApplyResult> {
    try {
      validateOperationIdentity(operation);
    } catch (_error) {
      return { deferredReason: 'MALFORMED_RECORDING_PAYLOAD' };
    }
    try {
      if (operation.payloadType === ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE) {
        let payload: OriginalCreateRecordingPayload;
        try {
          payload = decodeOriginalCreateRecordingTable(table);
        } catch (_error) {
          return { deferredReason: 'MALFORMED_RECORDING_PAYLOAD' };
        }
        return await this.applyCreate(store, operation, payload);
      }
      if (operation.payloadType === ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE) {
        let payload: OriginalModifyRecordingPayload;
        try {
          payload = decodeOriginalModifyRecordingTable(table);
        } catch (_error) {
          return { deferredReason: 'MALFORMED_RECORDING_PAYLOAD' };
        }
        return await this.applyModify(store, operation, payload);
      }
      return { deferredReason: 'RECORDING_PAYLOAD_TYPE_UNSUPPORTED' };
    } catch (error) {
      if (error instanceof RecordingDeferredError) {
        return { deferredReason: error.reason };
      }
      throw new Error(`applying original Recording operation failed: ${JSON.stringify(error)}`);
    }
  }

  private async applyCreate(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalCreateRecordingPayload): Promise<SyncedOperationApplyResult> {
    const existing: string | null = await recordingCreateSignature(
      store, operation.noteId, operation.timestamp, operation.siteId);
    const signature: string = createSignature(operation, payload);
    if (existing !== null) {
      if (existing !== signature) {
        throw new Error('original CreateRecording identity conflicts with persisted state');
      }
      return { deferredReason: null };
    }
    const assetConflict: OriginalAssetReferenceConflict = await mergeOriginalAssetReference(
      store, operation.noteId, payload.metadata);
    if (assetConflict !== OriginalAssetReferenceConflict.NONE) {
      throw new RecordingDeferredError('CREATE_RECORDING_ASSET_METADATA_CONFLICT');
    }
    const segments: OriginalRecordingSegment[] = payload.segments === null ? [{
      startTime: payload.startTime, endTime: payload.endTime,
    }] : payload.segments;
    const name: string = payload.name === null ?
      `Recording ID Id(site=${operation.siteId}, timestamp=${operation.timestamp})` : payload.name;
    const zIndex: string = payload.zIndex === null ? operation.clientTime : payload.zIndex;
    validateUnsignedLongDecimal(zIndex);
    await store.insert('original_recording_state', {
      'note_id': operation.noteId,
      'recording_timestamp': operation.timestamp,
      'recording_site_id': operation.siteId,
      'asset_hash_bits': JSON.stringify(payload.metadata.assetHashBits),
      'asset_file_name': payload.metadata.fileName,
      'asset_mime_type': payload.metadata.mimeType,
      'asset_file_size': payload.metadata.fileSize,
      'start_time': payload.startTime,
      'end_time': payload.endTime,
      'create_name': name,
      'name_value': name,
      'name_winner_timestamp': 0,
      'name_winner_site_id': 0,
      'name_winner_present': 0,
      'create_segments': encodeSegments(segments),
      'segments_value': encodeSegments(segments),
      'segments_winner_timestamp': 0,
      'segments_winner_site_id': 0,
      'segments_winner_present': 0,
      'create_z_index': zIndex,
      'z_index_value': zIndex,
      'z_index_winner_timestamp': 0,
      'z_index_winner_site_id': 0,
      'z_index_winner_present': 0,
      'create_signature': signature,
    });
    await refreshOriginalRecordingPresence(store, operation.noteId);
    return { deferredReason: null };
  }

  private async applyModify(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    payload: OriginalModifyRecordingPayload): Promise<SyncedOperationApplyResult> {
    const bounds: StoredRecordingBounds | null = await readRecordingBounds(
      store, operation.noteId, payload.recording);
    if (bounds === null) {
      throw new RecordingDeferredError('MODIFY_RECORDING_TARGET_MISSING');
    }
    if (payload.segments !== null) {
      validateModifiedSegments(payload.segments, bounds);
    }
    const signature: string = modifySignature(payload);
    const previous: string | null = await modificationSignature(store, operation);
    if (previous !== null) {
      if (previous !== signature) {
        throw new Error('original ModifyRecording identity conflicts with persisted state');
      }
      return { deferredReason: null };
    }
    await store.insert('original_recording_modification', {
      'note_id': operation.noteId,
      'operation_timestamp': operation.timestamp,
      'operation_site_id': operation.siteId,
      'recording_timestamp': payload.recording.timestamp,
      'recording_site_id': payload.recording.siteId,
      'payload_signature': signature,
    });
    if (payload.name !== null) {
      await this.updateRegister(store, operation, payload.recording, 'name', payload.name);
    }
    if (payload.segments !== null) {
      await this.updateRegister(store, operation, payload.recording,
        'segments', encodeSegments(payload.segments));
    }
    if (payload.zIndex !== null) {
      await this.updateRegister(store, operation, payload.recording, 'z_index', payload.zIndex);
    }
    return { deferredReason: null };
  }

  private async updateRegister(store: relationalStore.RdbStore, operation: StoredSyncedOperation,
    recording: OperationIdentity, prefix: string, value: string): Promise<void> {
    const rows = await store.querySql(
      `SELECT ${prefix}_winner_present, ${prefix}_winner_timestamp, ${prefix}_winner_site_id
       FROM original_recording_state WHERE note_id = ?
       AND recording_timestamp = ? AND recording_site_id = ?`,
      [operation.noteId, recording.timestamp, recording.siteId]);
    let applies: boolean = true;
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('original recording disappeared during modification');
      }
      if (rows.getLong(rows.getColumnIndex(`${prefix}_winner_present`)) === 1) {
        applies = compareOperationIdentity(operation, {
          timestamp: rows.getLong(rows.getColumnIndex(`${prefix}_winner_timestamp`)),
          siteId: rows.getLong(rows.getColumnIndex(`${prefix}_winner_site_id`)),
        }) > 0;
      }
    } finally {
      rows.close();
    }
    if (!applies) {
      return;
    }
    const predicates = new relationalStore.RdbPredicates('original_recording_state');
    predicates.equalTo('note_id', operation.noteId);
    predicates.equalTo('recording_timestamp', recording.timestamp);
    predicates.equalTo('recording_site_id', recording.siteId);
    const values: relationalStore.ValuesBucket = {};
    values[`${prefix}_value`] = value;
    values[`${prefix}_winner_timestamp`] = operation.timestamp;
    values[`${prefix}_winner_site_id`] = operation.siteId;
    values[`${prefix}_winner_present`] = 1;
    if (await store.update(values, predicates) !== 1) {
      throw new Error('original recording register changed concurrently');
    }
  }
}

export async function refreshOriginalRecordingPresence(store: relationalStore.RdbStore,
  noteId: string): Promise<void> {
  const rows = await store.querySql(
    `SELECT COUNT(*) AS value FROM original_recording_state recording
     LEFT JOIN original_entity_visibility_winner visibility
       ON visibility.note_id = recording.note_id
      AND visibility.entity_timestamp = recording.recording_timestamp
      AND visibility.entity_site_id = recording.recording_site_id
     WHERE recording.note_id = ? AND COALESCE(visibility.deleted, 0) = 0`, [noteId]);
  let hasRecordings: boolean = false;
  try {
    if (!rows.goToFirstRow()) {
      throw new Error('original recording presence query returned no row');
    }
    hasRecordings = rows.getLong(rows.getColumnIndex('value')) > 0;
  } finally {
    rows.close();
  }
  const predicates = new relationalStore.RdbPredicates('note_meta');
  predicates.equalTo('id', noteId);
  if (await store.update({ 'has_recordings': hasRecordings ? 1 : 0 }, predicates) !== 1) {
    throw new Error('original recording presence lost its note');
  }
}

function decodeSegments(table: OriginalFlatBufferTableReader,
  field: number): OriginalRecordingSegment[] | null {
  if (!table.hasField(field)) {
    return null;
  }
  const bytes: Uint8Array | null = table.readInlineVectorBytes(field, 16, MAX_RECORDING_SEGMENTS);
  if (bytes === null) {
    return [];
  }
  const result: OriginalRecordingSegment[] = [];
  for (let offset: number = 0; offset < bytes.length; offset += 16) {
    const startTime: string = readUint64(bytes, offset);
    const endTime: string = readUint64(bytes, offset + 8);
    validateUnsignedLongDecimal(startTime);
    validateUnsignedLongDecimal(endTime);
    result.push({ startTime: startTime, endTime: endTime });
  }
  return result;
}

function validateModifiedSegments(segments: OriginalRecordingSegment[],
  bounds: StoredRecordingBounds): void {
  const duration: string = subtractUnsigned(bounds.endTime, bounds.startTime);
  for (const segment of segments) {
    if (compareUnsignedLongDecimal(segment.startTime, segment.endTime) > 0 ||
      compareUnsignedLongDecimal(segment.startTime, bounds.startTime) < 0 ||
      compareUnsignedLongDecimal(segment.endTime, bounds.endTime) > 0 ||
      compareUnsignedLongDecimal(subtractUnsigned(segment.endTime, segment.startTime), duration) > 0) {
      throw new RecordingDeferredError('MODIFY_RECORDING_SEGMENTS_OUT_OF_BOUNDS');
    }
  }
}

async function readRecordingBounds(store: relationalStore.RdbStore, noteId: string,
  recording: OperationIdentity): Promise<StoredRecordingBounds | null> {
  const rows = await store.querySql(
    `SELECT start_time, end_time FROM original_recording_state WHERE note_id = ?
     AND recording_timestamp = ? AND recording_site_id = ?`,
    [noteId, recording.timestamp, recording.siteId]);
  try {
    if (!rows.goToFirstRow()) {
      return null;
    }
    return {
      startTime: rows.getString(rows.getColumnIndex('start_time')),
      endTime: rows.getString(rows.getColumnIndex('end_time')),
    };
  } finally {
    rows.close();
  }
}

async function recordingCreateSignature(store: relationalStore.RdbStore, noteId: string,
  timestamp: number, siteId: number): Promise<string | null> {
  const rows = await store.querySql(
    `SELECT create_signature FROM original_recording_state WHERE note_id = ?
     AND recording_timestamp = ? AND recording_site_id = ?`, [noteId, timestamp, siteId]);
  try {
    return rows.goToFirstRow() ? rows.getString(rows.getColumnIndex('create_signature')) : null;
  } finally {
    rows.close();
  }
}

async function modificationSignature(store: relationalStore.RdbStore,
  operation: StoredSyncedOperation): Promise<string | null> {
  const rows = await store.querySql(
    `SELECT payload_signature FROM original_recording_modification WHERE note_id = ?
     AND operation_timestamp = ? AND operation_site_id = ?`,
    [operation.noteId, operation.timestamp, operation.siteId]);
  try {
    return rows.goToFirstRow() ? rows.getString(rows.getColumnIndex('payload_signature')) : null;
  } finally {
    rows.close();
  }
}

function createSignature(operation: StoredSyncedOperation,
  payload: OriginalCreateRecordingPayload): string {
  return JSON.stringify({
    metadata: payload.metadata, startTime: payload.startTime, endTime: payload.endTime,
    name: payload.name, segments: payload.segments, zIndex: payload.zIndex,
    defaultZIndex: payload.zIndex === null ? operation.clientTime : null,
  });
}

function modifySignature(payload: OriginalModifyRecordingPayload): string {
  return JSON.stringify(payload);
}

function encodeSegments(segments: OriginalRecordingSegment[]): string {
  return JSON.stringify(segments);
}

function readIdentity(bytes: Uint8Array): OperationIdentity {
  const identity: OperationIdentity = {
    timestamp: readU32(bytes, 4), siteId: readU16(bytes, 0),
  };
  validateOperationIdentity(identity);
  return identity;
}

function readUint64(bytes: Uint8Array, offset: number): string {
  return readOriginalInlineUint64Decimal(bytes, offset);
}

function subtractUnsigned(left: string, right: string): string {
  validateUnsignedLongDecimal(left);
  validateUnsignedLongDecimal(right);
  if (compareUnsignedLongDecimal(left, right) < 0) {
    throw new RecordingDeferredError('MODIFY_RECORDING_SEGMENTS_OUT_OF_BOUNDS');
  }
  let borrow: number = 0;
  let result: string = '';
  let li: number = left.length - 1;
  let ri: number = right.length - 1;
  while (li >= 0) {
    let digit: number = left.charCodeAt(li) - 48 - borrow -
      (ri >= 0 ? right.charCodeAt(ri) - 48 : 0);
    if (digit < 0) {
      digit += 10;
      borrow = 1;
    } else {
      borrow = 0;
    }
    result = String.fromCharCode(48 + digit) + result;
    li--;
    ri--;
  }
  let first: number = 0;
  while (first < result.length - 1 && result.charCodeAt(first) === 48) {
    first++;
  }
  return result.substring(first);
}

function rejectFieldsFrom(table: OriginalFlatBufferTableReader, first: number,
  name: string): void {
  for (let field: number = first; field <= 1024; field++) {
    if (table.hasField(field)) {
      throw new Error(`${name} has an unknown field`);
    }
  }
}

function readU16(bytes: Uint8Array, offset: number): number {
  return bytes[offset] | bytes[offset + 1] << 8;
}

function readU32(bytes: Uint8Array, offset: number): number {
  return (bytes[offset] + bytes[offset + 1] * 0x100 +
    bytes[offset + 2] * 0x10000 + bytes[offset + 3] * 0x1000000) >>> 0;
}

class RecordingDeferredError extends Error {
  reason: string;

  constructor(reason: string) {
    super(reason);
    this.reason = reason;
  }
}
