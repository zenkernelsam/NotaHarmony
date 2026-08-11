import { relationalStore } from '@kit.ArkData';
import { AssetStatus, NoteAsset } from '../core/model/AssetTypes';
import { originalAssetHashKey, originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import { OpType } from '../core/model/OpTypes';
import { AssetRepositoryImpl } from './AssetRepositoryImpl';
import { DatabaseManager } from './DatabaseManager';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
import { encodeOperationId, OperationIdentity } from './OperationIdentity';
import {
  allocateOperationIdentity, AllocatedOperationIdentity, appendOperation,
} from './OpStoreImpl';
import {
  ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, OriginalDeleteEntitiesOperationApplier,
} from './OriginalDeleteEntitiesOperation';
import { encodeOriginalEntityDeletes } from './OriginalDeleteEntitiesPayloadEncoder';
import { OriginalRecordingSegment } from './OriginalRecordingOperation';
import { OriginalFlatBufferTableReader } from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';
import { compareUnsignedLongDecimal, validateUnsignedLongDecimal } from './UnsignedDecimal';

const MAX_RECORDING_SEGMENTS: number = 100000;

export enum OriginalRecordingAssetState {
  MISSING = 0,
  PENDING = 1,
  READY = 2,
  FAILED = 3,
}

export interface MaterializedOriginalRecording {
  id: string;
  timestamp: number;
  siteId: number;
  name: string;
  startTime: string;
  endTime: string;
  segments: OriginalRecordingSegment[];
  zIndex: string;
  assetHashBits: string[];
  assetHash: string;
  assetFileName: string;
  assetMimeType: string;
  assetFileSize: number;
  assetState: OriginalRecordingAssetState;
  localPath: string | null;
  assetError: string | null;
}

interface StoredRecordingRow {
  identity: OperationIdentity;
  name: string;
  startTime: string;
  endTime: string;
  segments: OriginalRecordingSegment[];
  zIndex: string;
  assetHashBits: string[];
  assetFileName: string;
  assetMimeType: string;
  assetFileSize: number;
}

export interface RecordingAssetResolution {
  state: OriginalRecordingAssetState;
  assetHash: string;
  localPath: string | null;
  error: string | null;
}

export class OriginalRecordingStore {
  private db: DatabaseManager;
  private assets: AssetRepositoryImpl;

  constructor(db: DatabaseManager) {
    this.db = db;
    this.assets = new AssetRepositoryImpl(db);
  }

  async listVisible(noteId: string): Promise<MaterializedOriginalRecording[]> {
    if (noteId.length === 0) {
      throw new Error('recording query requires a note ID');
    }
    const stored: StoredRecordingRow[] = await readVisibleRows(this.db.getStore(), noteId);
    const noteAssets: NoteAsset[] = await this.assets.getAssetsByNote(noteId);
    const recordings: MaterializedOriginalRecording[] = [];
    for (const row of stored) {
      const asset: RecordingAssetResolution = resolveOriginalRecordingAsset(
        row.assetHashBits, row.assetFileSize, row.assetMimeType, noteAssets);
      recordings.push({
        id: encodeOperationId(row.identity), timestamp: row.identity.timestamp,
        siteId: row.identity.siteId, name: row.name, startTime: row.startTime,
        endTime: row.endTime, segments: cloneSegments(row.segments), zIndex: row.zIndex,
        assetHashBits: row.assetHashBits.slice(), assetHash: asset.assetHash,
        assetFileName: row.assetFileName, assetMimeType: row.assetMimeType,
        assetFileSize: row.assetFileSize, assetState: asset.state,
        localPath: asset.localPath, assetError: asset.error,
      });
    }
    recordings.sort(compareMaterializedRecordings);
    return recordings;
  }

  async deleteVisible(noteId: string, targets: OperationIdentity[]): Promise<number> {
    if (noteId.length === 0 || targets.length === 0) {
      throw new Error('recording delete requires a note and targets');
    }
    return editorPersistenceMutex.runExclusive(async (): Promise<number> => {
      const store: relationalStore.RdbStore = this.db.getStore();
      await store.beginTransaction();
      try {
        const visible: OperationIdentity[] = await filterVisibleRecordingTargets(
          store, noteId, targets);
        if (visible.length === 0) {
          await store.commit();
          return 0;
        }
        const identity: AllocatedOperationIdentity =
          await allocateOperationIdentity(store, noteId);
        const payload: Uint8Array = encodeOriginalEntityDeletes(visible);
        const operation: StoredSyncedOperation = {
          noteId: noteId, timestamp: identity.timestamp, siteId: identity.siteId,
          clientTime: identity.clientTime.toString(), serverTime: '0', audioTime: null,
          schemaVersion: 1, payloadType: ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE,
          rawOperation: payload, state: SyncedOperationInboxState.APPLIED,
          deferredReason: null, receivedAt: identity.clientTime,
        };
        const result: SyncedOperationApplyResult =
          await new OriginalDeleteEntitiesOperationApplier().applyEntityTable(
          store, operation, OriginalFlatBufferTableReader.fromRoot(payload));
        if (result.deferredReason !== null) {
          throw new Error(`recording delete was deferred: ${result.deferredReason}`);
        }
        await appendOperation(store, {
          opId: identity.opId, noteId: noteId,
          opType: OpType.ORIGINAL_DELETE_ENTITIES, payload: payload,
          clientTime: identity.clientTime, opTimestamp: identity.timestamp,
          editorSiteId: identity.siteId, uploadImmediately: true,
        });
        await store.commit();
        return visible.length;
      } catch (error) {
        await store.rollBack();
        throw new Error(`delete original recordings failed: ${JSON.stringify(error)}`);
      }
    });
  }
}

async function filterVisibleRecordingTargets(store: relationalStore.RdbStore, noteId: string,
  targets: OperationIdentity[]): Promise<OperationIdentity[]> {
  const unique: Map<string, OperationIdentity> = new Map<string, OperationIdentity>();
  for (const target of targets) {
    unique.set(encodeOperationId(target), target);
  }
  const result: OperationIdentity[] = [];
  for (const target of unique.values()) {
    const rows = await store.querySql(
      `SELECT COALESCE(visibility.deleted, 0) AS deleted
         FROM original_recording_state recording
         LEFT JOIN original_entity_visibility_winner visibility
           ON visibility.note_id = recording.note_id
          AND visibility.entity_timestamp = recording.recording_timestamp
          AND visibility.entity_site_id = recording.recording_site_id
        WHERE recording.note_id = ? AND recording.recording_timestamp = ?
          AND recording.recording_site_id = ?`, [noteId, target.timestamp, target.siteId]);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('recording delete target does not exist');
      }
      if (rows.getLong(rows.getColumnIndex('deleted')) === 0) {
        result.push({ timestamp: target.timestamp, siteId: target.siteId });
      }
    } finally {
      rows.close();
    }
  }
  return result;
}

async function readVisibleRows(store: relationalStore.RdbStore,
  noteId: string): Promise<StoredRecordingRow[]> {
  const rows = await store.querySql(
    `SELECT recording.recording_timestamp, recording.recording_site_id,
            recording.asset_hash_bits, recording.asset_file_name,
            recording.asset_mime_type, recording.asset_file_size,
            recording.start_time, recording.end_time, recording.name_value,
            recording.segments_value, recording.z_index_value
       FROM original_recording_state recording
       LEFT JOIN original_entity_visibility_winner visibility
         ON visibility.note_id = recording.note_id
        AND visibility.entity_timestamp = recording.recording_timestamp
        AND visibility.entity_site_id = recording.recording_site_id
      WHERE recording.note_id = ? AND COALESCE(visibility.deleted, 0) = 0`, [noteId]);
  const result: StoredRecordingRow[] = [];
  try {
    while (rows.goToNextRow()) {
      const startTime: string = rows.getString(rows.getColumnIndex('start_time'));
      const endTime: string = rows.getString(rows.getColumnIndex('end_time'));
      validateRecordingBounds(startTime, endTime);
      const assetFileSize: number = rows.getLong(rows.getColumnIndex('asset_file_size'));
      if (!Number.isSafeInteger(assetFileSize) || assetFileSize <= 0) {
        throw new Error('recording asset size is invalid');
      }
      const fileName: string = rows.getString(rows.getColumnIndex('asset_file_name'));
      const mimeType: string = rows.getString(rows.getColumnIndex('asset_mime_type'));
      if (fileName.length === 0 || mimeType.length === 0) {
        throw new Error('recording asset metadata is incomplete');
      }
      const zIndex: string = rows.getString(rows.getColumnIndex('z_index_value'));
      validateUnsignedLongDecimal(zIndex);
      result.push({
        identity: {
          timestamp: rows.getLong(rows.getColumnIndex('recording_timestamp')),
          siteId: rows.getLong(rows.getColumnIndex('recording_site_id')),
        },
        name: rows.getString(rows.getColumnIndex('name_value')),
        startTime: startTime, endTime: endTime,
        segments: parseOriginalRecordingSegments(
          rows.getString(rows.getColumnIndex('segments_value')), endTime),
        zIndex: zIndex,
        assetHashBits: parseOriginalRecordingAssetHashBits(
          rows.getString(rows.getColumnIndex('asset_hash_bits'))),
        assetFileName: fileName, assetMimeType: mimeType, assetFileSize: assetFileSize,
      });
    }
    return result;
  } finally {
    rows.close();
  }
}

export function parseOriginalRecordingSegments(raw: string,
  recordingEndTime: string): OriginalRecordingSegment[] {
  validateUnsignedLongDecimal(recordingEndTime);
  const parsed = JSON.parse(raw) as Object[];
  if (!Array.isArray(parsed) || parsed.length > MAX_RECORDING_SEGMENTS) {
    throw new Error('recording segments are not a bounded array');
  }
  const result: OriginalRecordingSegment[] = [];
  for (let index: number = 0; index < parsed.length; index++) {
    const value = parsed[index] as Record<string, Object>;
    if (value === null || typeof value !== 'object' ||
      typeof value.startTime !== 'string' || typeof value.endTime !== 'string') {
      throw new Error(`recording segment ${index} is invalid`);
    }
    const startTime: string = value.startTime as string;
    const endTime: string = value.endTime as string;
    validateUnsignedLongDecimal(startTime);
    validateUnsignedLongDecimal(endTime);
    if (compareUnsignedLongDecimal(startTime, endTime) > 0 ||
      compareUnsignedLongDecimal(endTime, recordingEndTime) > 0) {
      throw new Error(`recording segment ${index} is outside recording bounds`);
    }
    result.push({ startTime: startTime, endTime: endTime });
  }
  return result;
}

export function parseOriginalRecordingAssetHashBits(raw: string): string[] {
  const parsed = JSON.parse(raw) as string[];
  if (!Array.isArray(parsed) || parsed.length !== 8) {
    throw new Error('recording asset hash must contain eight uint64 words');
  }
  const result: string[] = [];
  for (let index: number = 0; index < parsed.length; index++) {
    if (typeof parsed[index] !== 'string') {
      throw new Error(`recording asset hash word ${index} is invalid`);
    }
    result.push(parsed[index]);
  }
  // The canonical storage encoder performs the exact uint64 validation.
  originalAssetStorageHash(result);
  return result;
}

export function compareMaterializedRecordings(left: MaterializedOriginalRecording,
  right: MaterializedOriginalRecording): number {
  const zOrder: number = compareUnsignedLongDecimal(left.zIndex, right.zIndex);
  if (zOrder !== 0) {
    return zOrder;
  }
  if (left.timestamp !== right.timestamp) {
    return left.timestamp < right.timestamp ? -1 : 1;
  }
  return left.siteId === right.siteId ? 0 : left.siteId < right.siteId ? -1 : 1;
}

export function resolveOriginalRecordingAsset(assetHashBits: string[], assetFileSize: number,
  assetMimeType: string, assets: NoteAsset[]): RecordingAssetResolution {
  const canonical: string = originalAssetStorageHash(assetHashBits);
  const legacy: string = originalAssetHashKey(assetHashBits);
  let asset: NoteAsset | null = null;
  for (const candidate of assets) {
    if (candidate.assetHash === canonical) {
      asset = candidate;
      break;
    }
    if (asset === null && candidate.assetHash === legacy) {
      asset = candidate;
    }
  }
  if (asset === null) {
    return { state: OriginalRecordingAssetState.MISSING, assetHash: canonical,
      localPath: null, error: 'asset metadata is absent' };
  }
  if (asset.fileSize !== assetFileSize ||
    asset.mimeType.toLowerCase() !== assetMimeType.toLowerCase()) {
    return { state: OriginalRecordingAssetState.FAILED, assetHash: asset.assetHash,
      localPath: null, error: 'asset metadata does not match the recording' };
  }
  if (asset.status === AssetStatus.FAILED) {
    return { state: OriginalRecordingAssetState.FAILED, assetHash: asset.assetHash,
      localPath: null, error: 'asset is marked failed' };
  }
  if (asset.localPath === null || asset.localPath.length === 0) {
    return { state: OriginalRecordingAssetState.PENDING, assetHash: asset.assetHash,
      localPath: null, error: 'asset has no local file yet' };
  }
  return { state: OriginalRecordingAssetState.READY, assetHash: asset.assetHash,
    localPath: asset.localPath, error: null };
}

function validateRecordingBounds(startTime: string, endTime: string): void {
  validateUnsignedLongDecimal(startTime);
  validateUnsignedLongDecimal(endTime);
  if (compareUnsignedLongDecimal(startTime, endTime) > 0) {
    throw new Error('recording starts after it ends');
  }
}

function cloneSegments(segments: OriginalRecordingSegment[]): OriginalRecordingSegment[] {
  return segments.map((segment: OriginalRecordingSegment): OriginalRecordingSegment => ({
    startTime: segment.startTime, endTime: segment.endTime,
  }));
}
