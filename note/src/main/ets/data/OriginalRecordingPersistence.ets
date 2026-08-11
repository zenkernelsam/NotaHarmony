import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { AssetStatus } from '../core/model/AssetTypes';
import { originalAssetHashKey, originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import { OpType } from '../core/model/OpTypes';
import { OriginalRecordingCaptureResult } from '../core/adaptation/OriginalRecordingCaptureController';
import {
  assetMutationMutex, mergeNoteIds, parseAssetNoteIds,
} from './AssetRepositoryImpl';
import {
  originalAssetHashBitsFromSha512, sha512BytesToHex,
} from './AssetDigest';
import { assetAvailabilityHub } from './AssetAvailabilityHub';
import { DatabaseManager } from './DatabaseManager';
import { editorPersistenceMutex } from './EditorPersistenceMutex';
import { encodeOriginalLocalCreateRecording } from './OriginalCreateRecordingPayloadEncoder';
import { OperationIdentity } from './OperationIdentity';
import {
  allocateOperationIdentity, AllocatedOperationIdentity, appendOperation,
} from './OpStoreImpl';
import {
  ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE, OriginalRecordingOperationApplier,
} from './OriginalRecordingOperation';
import { OriginalFlatBufferTableReader } from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplyResult, SyncedOperationInboxState,
} from './SyncedOperationInbox';

const MAX_ORIGINAL_ASSET_SIZE: number = 0xFFFFFFFF;
const COPY_BUFFER_SIZE: number = 65536;

export interface PersistedOriginalRecording {
  identity: OperationIdentity;
  assetHashBits: string[];
  assetHash: string;
  localPath: string;
  payload: Uint8Array;
}

interface PreparedRecordingAsset {
  metadata: OriginalAssetMetadata;
  storageHash: string;
  legacyHash: string;
  finalPath: string;
  createdFinalFile: boolean;
}

interface StoredAssetRow {
  assetHash: string;
  status: AssetStatus;
  noteIds: string[];
  fileSize: number;
  mimeType: string;
  localPath: string | null;
}

export async function persistCapturedOriginalRecording(database: DatabaseManager, noteId: string,
  capture: OriginalRecordingCaptureResult): Promise<PersistedOriginalRecording> {
  return await assetMutationMutex.runExclusive(async (): Promise<PersistedOriginalRecording> => {
    let prepared: PreparedRecordingAsset | null = null;
    let committed: boolean = false;
    try {
      validateCapture(noteId, capture);
      prepared = await prepareRecordingAsset(database, capture);
      const completed: PreparedRecordingAsset = prepared;
      const result: PersistedOriginalRecording = await editorPersistenceMutex.runExclusive(
        async (): Promise<PersistedOriginalRecording> => {
          const store: relationalStore.RdbStore = database.getStore();
          await store.beginTransaction();
          try {
            const identity: AllocatedOperationIdentity = await allocateOperationIdentity(store, noteId);
            const payload: Uint8Array = encodeOriginalLocalCreateRecording(completed.metadata,
              capture.startTime.toString(), capture.endTime.toString());
            const operation: StoredSyncedOperation = {
              noteId: noteId, timestamp: identity.timestamp, siteId: identity.siteId,
              clientTime: identity.clientTime.toString(), serverTime: '0', audioTime: null,
              schemaVersion: 1, payloadType: ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE,
              rawOperation: payload, state: SyncedOperationInboxState.APPLIED,
              deferredReason: null, receivedAt: identity.clientTime,
            };
            const applyResult: SyncedOperationApplyResult =
              await new OriginalRecordingOperationApplier().applyTable(
                store, operation, OriginalFlatBufferTableReader.fromRoot(payload));
            if (applyResult.deferredReason !== null) {
              throw new Error(`local CreateRecording was deferred: ${applyResult.deferredReason}`);
            }
            await markAssetLocal(store, noteId, completed);
            await appendOperation(store, {
              opId: identity.opId, noteId: noteId, opType: OpType.ORIGINAL_CREATE_RECORDING,
              payload: payload, clientTime: identity.clientTime, opTimestamp: identity.timestamp,
              editorSiteId: identity.siteId, uploadImmediately: true,
            });
            await store.commit();
            return {
              identity: { timestamp: identity.timestamp, siteId: identity.siteId },
              assetHashBits: completed.metadata.assetHashBits.slice(),
              assetHash: completed.storageHash, localPath: completed.finalPath, payload: payload,
            };
          } catch (error) {
            try {
              await store.rollBack();
            } catch (rollbackError) {
              console.error(`local CreateRecording rollback failed: ${JSON.stringify(rollbackError)}`);
            }
            throw new Error(`persisting local CreateRecording failed: ${JSON.stringify(error)}`);
          }
        });
      committed = true;
      assetAvailabilityHub.publish(result.assetHash, [noteId]);
      return result;
    } finally {
      unlinkIfPresent(capture.temporaryPath);
      if (!committed && prepared !== null && prepared.createdFinalFile) {
        unlinkIfPresent(prepared.finalPath);
      }
    }
  });
}

async function prepareRecordingAsset(database: DatabaseManager,
  capture: OriginalRecordingCaptureResult): Promise<PreparedRecordingAsset> {
  const sourceStat = fileIo.statSync(capture.temporaryPath);
  if (!sourceStat.isFile() || sourceStat.size !== capture.fileSize || sourceStat.size <= 0) {
    throw new Error('captured recording file does not match stop metadata');
  }
  const pendingDirectory: string = database.getFilesDir() + '/assets/pending';
  const finalDirectory: string = database.getFilesDir() + '/assets/final';
  fileIo.mkdirSync(pendingDirectory, true);
  fileIo.mkdirSync(finalDirectory, true);
  const pendingPath: string = pendingDirectory +
    `/pending_recording_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.tmp`;
  const digest = cryptoFramework.createMd('SHA512');
  let source: fileIo.File | null = null;
  let pending: fileIo.File | null = null;
  let copied: boolean = false;
  try {
    try {
      source = fileIo.openSync(capture.temporaryPath, fileIo.OpenMode.READ_ONLY);
      pending = fileIo.openSync(pendingPath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      let total: number = 0;
      while (total < capture.fileSize) {
        const requested: number = Math.min(COPY_BUFFER_SIZE, capture.fileSize - total);
        const buffer: ArrayBuffer = new ArrayBuffer(requested);
        const read: number = fileIo.readSync(source.fd, buffer);
        if (read <= 0 || read > requested) {
          throw new Error(`short recording asset read at ${total}/${capture.fileSize}`);
        }
        const chunk: Uint8Array = new Uint8Array(buffer, 0, read);
        await digest.update({ data: chunk });
        writeChunk(pending.fd, chunk, total, capture.fileSize);
        total += read;
      }
      if (total !== capture.fileSize) {
        throw new Error('recording asset copy ended at the wrong size');
      }
      const copiedSourceStat = fileIo.statSync(capture.temporaryPath);
      if (!copiedSourceStat.isFile() || copiedSourceStat.size !== capture.fileSize) {
        throw new Error('captured recording file changed while it was copied');
      }
      fileIo.fsyncSync(pending.fd);
      copied = true;
    } finally {
      try {
        if (pending !== null) {
          fileIo.closeSync(pending);
        }
      } finally {
        if (source !== null) {
          fileIo.closeSync(source);
        }
      }
    }
  } catch (error) {
    unlinkIfPresent(pendingPath);
    throw new Error(`copying recording asset failed: ${JSON.stringify(error)}`);
  }
  if (!copied) {
    unlinkIfPresent(pendingPath);
    throw new Error('recording asset copy did not complete');
  }

  let createdFinalFile: boolean = false;
  let finalPath: string = '';
  try {
    const digestBlob: cryptoFramework.DataBlob = await digest.digest();
    const hashBits: string[] = originalAssetHashBitsFromSha512(digestBlob.data);
    const storageHash: string = sha512BytesToHex(digestBlob.data);
    if (originalAssetStorageHash(hashBits) !== storageHash) {
      throw new Error('recording AssetHash conversion is inconsistent');
    }
    finalPath = finalDirectory + '/' + storageHash;
    if (fileIo.accessSync(finalPath)) {
      if (!filesEqual(pendingPath, finalPath, capture.fileSize)) {
        throw new Error('existing recording asset conflicts with captured bytes');
      }
      unlinkIfPresent(pendingPath);
    } else {
      try {
        fileIo.renameSync(pendingPath, finalPath);
        createdFinalFile = true;
      } catch (error) {
        if (!fileIo.accessSync(finalPath) || !filesEqual(pendingPath, finalPath, capture.fileSize)) {
          throw new Error(`moving recording asset into final storage failed: ${JSON.stringify(error)}`);
        }
        unlinkIfPresent(pendingPath);
      }
    }
    return {
      metadata: {
        assetHashBits: hashBits, fileName: baseName(capture.temporaryPath),
        mimeType: capture.mimeType, fileSize: capture.fileSize,
      },
      storageHash: storageHash, legacyHash: originalAssetHashKey(hashBits),
      finalPath: finalPath, createdFinalFile: createdFinalFile,
    };
  } catch (error) {
    unlinkIfPresent(pendingPath);
    if (createdFinalFile && finalPath.length > 0) {
      unlinkIfPresent(finalPath);
    }
    throw new Error(`preparing recording asset failed: ${JSON.stringify(error)}`);
  }
}

async function markAssetLocal(store: relationalStore.RdbStore, noteId: string,
  prepared: PreparedRecordingAsset): Promise<void> {
  const rows: StoredAssetRow[] = await readAssetRows(
    store, prepared.storageHash, prepared.legacyHash);
  let noteIds: string[] = [noteId];
  let targetStatus: AssetStatus = AssetStatus.LOCAL;
  for (const row of rows) {
    if (row.fileSize !== prepared.metadata.fileSize ||
      row.mimeType.toLowerCase() !== prepared.metadata.mimeType.toLowerCase()) {
      throw new Error('local recording asset metadata conflicts with its reference');
    }
    if (row.localPath !== null && row.localPath.length > 0 && row.localPath !== prepared.finalPath) {
      throw new Error('local recording asset has a conflicting stored path');
    }
    noteIds = mergeNoteIds(noteIds, row.noteIds);
    if (row.status === AssetStatus.UPLOADED) {
      targetStatus = AssetStatus.UPLOADED;
    } else if (targetStatus !== AssetStatus.UPLOADED && row.status === AssetStatus.DOWNLOADED) {
      targetStatus = AssetStatus.DOWNLOADED;
    }
  }
  const canonical: StoredAssetRow | undefined = rows.find(
    (row: StoredAssetRow): boolean => row.assetHash === prepared.storageHash);
  const bucket: relationalStore.ValuesBucket = {
    'status': targetStatus, 'note_ids': JSON.stringify(noteIds),
    'file_size': prepared.metadata.fileSize, 'mime_type': prepared.metadata.mimeType,
    'local_path': prepared.finalPath,
  };
  if (canonical === undefined) {
    await store.insert('note_asset', {
      'asset_hash': prepared.storageHash, 'status': targetStatus,
      'note_ids': JSON.stringify(noteIds), 'file_size': prepared.metadata.fileSize,
      'mime_type': prepared.metadata.mimeType, 'local_path': prepared.finalPath,
    });
  } else {
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', prepared.storageHash);
    if (await store.update(bucket, predicates) !== 1) {
      throw new Error('local recording asset changed concurrently');
    }
  }
  if (prepared.legacyHash !== prepared.storageHash && rows.some(
    (row: StoredAssetRow): boolean => row.assetHash === prepared.legacyHash)) {
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', prepared.legacyHash);
    if (await store.delete(predicates) !== 1) {
      throw new Error('legacy local recording asset changed concurrently');
    }
  }
}

async function readAssetRows(store: relationalStore.RdbStore, storageHash: string,
  legacyHash: string): Promise<StoredAssetRow[]> {
  const resultSet = storageHash === legacyHash ? await store.querySql(
    `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
       FROM note_asset WHERE asset_hash = ?`, [storageHash]) : await store.querySql(
    `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
       FROM note_asset WHERE asset_hash = ? OR asset_hash = ?`, [storageHash, legacyHash]);
  const result: StoredAssetRow[] = [];
  try {
    while (resultSet.goToNextRow()) {
      const status: number = resultSet.getLong(resultSet.getColumnIndex('status'));
      if (status < AssetStatus.PENDING || status > AssetStatus.FAILED) {
        throw new Error('local recording asset status is invalid');
      }
      const pathColumn: number = resultSet.getColumnIndex('local_path');
      result.push({
        assetHash: resultSet.getString(resultSet.getColumnIndex('asset_hash')),
        status: status as AssetStatus,
        noteIds: parseAssetNoteIds(resultSet.getString(resultSet.getColumnIndex('note_ids'))),
        fileSize: resultSet.getLong(resultSet.getColumnIndex('file_size')),
        mimeType: resultSet.getString(resultSet.getColumnIndex('mime_type')),
        localPath: resultSet.isColumnNull(pathColumn) ? null : resultSet.getString(pathColumn),
      });
    }
    return result;
  } finally {
    resultSet.close();
  }
}

function validateCapture(noteId: string, capture: OriginalRecordingCaptureResult): void {
  if (noteId.length === 0 || capture.temporaryPath.length === 0 || capture.mimeType.length === 0 ||
    !Number.isSafeInteger(capture.fileSize) || capture.fileSize <= 0 ||
    capture.fileSize > MAX_ORIGINAL_ASSET_SIZE || !Number.isSafeInteger(capture.startTime) ||
    !Number.isSafeInteger(capture.endTime) || capture.startTime <= 0 ||
    capture.endTime < capture.startTime || !Number.isSafeInteger(capture.durationMs) ||
    capture.durationMs < 0 || capture.endTime !== capture.startTime + capture.durationMs) {
    throw new Error('captured recording cannot be persisted');
  }
}

function writeChunk(fd: number, chunk: Uint8Array, total: number, expected: number): void {
  let offset: number = 0;
  while (offset < chunk.length) {
    const buffer: ArrayBuffer = chunk.buffer.slice(
      chunk.byteOffset + offset, chunk.byteOffset + chunk.length) as ArrayBuffer;
    const written: number = fileIo.writeSync(fd, buffer);
    if (written <= 0) {
      throw new Error(`short recording asset write at ${total + offset}/${expected}`);
    }
    offset += written;
  }
}

function filesEqual(leftPath: string, rightPath: string, expectedSize: number): boolean {
  const leftStat = fileIo.statSync(leftPath);
  const rightStat = fileIo.statSync(rightPath);
  if (!leftStat.isFile() || !rightStat.isFile() || leftStat.size !== expectedSize ||
    rightStat.size !== expectedSize) {
    return false;
  }
  let left: fileIo.File | null = null;
  let right: fileIo.File | null = null;
  try {
    left = fileIo.openSync(leftPath, fileIo.OpenMode.READ_ONLY);
    right = fileIo.openSync(rightPath, fileIo.OpenMode.READ_ONLY);
    let total: number = 0;
    while (total < expectedSize) {
      const requested: number = Math.min(COPY_BUFFER_SIZE, expectedSize - total);
      const leftBuffer: ArrayBuffer = new ArrayBuffer(requested);
      const rightBuffer: ArrayBuffer = new ArrayBuffer(requested);
      const leftRead: number = fileIo.readSync(left.fd, leftBuffer);
      const rightRead: number = fileIo.readSync(right.fd, rightBuffer);
      if (leftRead !== rightRead || leftRead <= 0) {
        return false;
      }
      const leftBytes: Uint8Array = new Uint8Array(leftBuffer, 0, leftRead);
      const rightBytes: Uint8Array = new Uint8Array(rightBuffer, 0, rightRead);
      for (let index: number = 0; index < leftRead; index++) {
        if (leftBytes[index] !== rightBytes[index]) {
          return false;
        }
      }
      total += leftRead;
    }
    return total === expectedSize;
  } finally {
    try {
      if (right !== null) {
        fileIo.closeSync(right);
      }
    } finally {
      if (left !== null) {
        fileIo.closeSync(left);
      }
    }
  }
}

function baseName(path: string): string {
  const slash: number = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
  const name: string = slash < 0 ? path : path.substring(slash + 1);
  if (name.length === 0) {
    throw new Error('captured recording file name is empty');
  }
  return name;
}

function unlinkIfPresent(path: string): void {
  try {
    if (path.length > 0 && fileIo.accessSync(path)) {
      fileIo.unlinkSync(path);
    }
  } catch (error) {
    console.error(`recording asset cleanup failed: ${JSON.stringify(error)}`);
  }
}
