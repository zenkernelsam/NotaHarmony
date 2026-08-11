import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { ImageElement } from '../core/model/ElementTypes';
import {
  originalAssetHashKey, originalAssetLookupKeys, originalAssetStorageHash,
} from '../core/model/ImageBlockGeometry';
import { AssetStatus, NoteAsset } from '../core/model/AssetTypes';
import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import { assetMutationMutex, AssetRepositoryImpl, mergeNoteIds, parseAssetNoteIds } from './AssetRepositoryImpl';
import { assetAvailabilityHub } from './AssetAvailabilityHub';
import { sha512Hex } from './AssetDigest';
import { DatabaseManager } from './DatabaseManager';

export interface OriginalImageAssetArrival {
  assetHashBits: string[];
  bytes: Uint8Array;
  expectedFileSize: number;
  expectedMimeType: string;
}

export type OriginalAssetArrival = OriginalImageAssetArrival;

export function originalAssetPackageEntry(metadata: OriginalAssetMetadata): string {
  return `assets/${originalAssetStorageHash(metadata.assetHashBits)}`;
}

export async function resolveOriginalAsset(repository: AssetRepositoryImpl,
  metadata: OriginalAssetMetadata): Promise<NoteAsset | null> {
  const storageHash: string = originalAssetStorageHash(metadata.assetHashBits);
  const legacyHash: string = originalAssetHashKey(metadata.assetHashBits);
  const canonical: NoteAsset | null = await repository.getAsset(storageHash);
  return canonical !== null || legacyHash === storageHash
    ? canonical : await repository.getAsset(legacyHash);
}

export function readVerifiedOriginalAsset(asset: NoteAsset,
  metadata: OriginalAssetMetadata): Uint8Array {
  if (asset.localPath === null || asset.localPath.length === 0) {
    throw new Error(`asset ${originalAssetStorageHash(metadata.assetHashBits)} has no local file`);
  }
  const stat = fileIo.statSync(asset.localPath);
  if (stat.size <= 0 || stat.size !== metadata.fileSize ||
    (asset.fileSize > 0 && stat.size !== asset.fileSize)) {
    throw new Error('asset file size does not match metadata');
  }
  const file: fileIo.File = fileIo.openSync(asset.localPath, fileIo.OpenMode.READ_ONLY);
  try {
    return readFileFully(file.fd, stat.size);
  } finally {
    fileIo.closeSync(file);
  }
}

interface StoredAssetRecord {
  assetHash: string;
  status: AssetStatus;
  noteIds: string[];
  fileSize: number;
  mimeType: string;
  localPath: string | null;
}

interface AssetWriteResult {
  storageHash: string;
  noteIds: string[];
  becameAvailable: boolean;
}

export function imageAssetPackageEntry(element: ImageElement): string {
  return `assets/${originalAssetStorageHash(element.assetHashBits)}`;
}

export async function resolveImageAsset(repository: AssetRepositoryImpl,
  element: ImageElement): Promise<NoteAsset | null> {
  const keys: string[] = originalAssetLookupKeys(element);
  for (const key of keys) {
    const asset: NoteAsset | null = await repository.getAsset(key);
    if (asset !== null) {
      return asset;
    }
  }
  return null;
}

export function readVerifiedImageAsset(asset: NoteAsset, element: ImageElement): Uint8Array {
  if (asset.localPath === null || asset.localPath.length === 0) {
    throw new Error(`image asset ${element.id} has no local file`);
  }
  const stat = fileIo.statSync(asset.localPath);
  if (stat.size <= 0 || stat.size !== element.fileSize ||
    (asset.fileSize > 0 && stat.size !== asset.fileSize)) {
    throw new Error(`image asset ${element.id} file size does not match metadata`);
  }
  const file: fileIo.File = fileIo.openSync(asset.localPath, fileIo.OpenMode.READ_ONLY);
  try {
    return readFileFully(file.fd, stat.size);
  } finally {
    fileIo.closeSync(file);
  }
}

export async function storeImportedImageAsset(database: DatabaseManager, element: ImageElement,
  bytes: Uint8Array, noteId: string): Promise<void> {
  const result: AssetWriteResult = await writeOriginalImageAssetBytes(database, {
    assetHashBits: element.assetHashBits,
    bytes: bytes,
    expectedFileSize: element.fileSize,
    expectedMimeType: element.mimeType,
  }, noteId, true);
  if (result.becameAvailable) {
    assetAvailabilityHub.publish(result.storageHash, result.noteIds);
  }
}

// Network/authentication stays outside this boundary. A transport may call this only after it has
// received all bytes for metadata previously registered by CREATE_BLOCK IMAGE.
export async function receiveOriginalImageAsset(database: DatabaseManager,
  arrival: OriginalImageAssetArrival): Promise<void> {
  const result: AssetWriteResult = await writeOriginalImageAssetBytes(database, arrival, null, false);
  if (result.becameAvailable) {
    assetAvailabilityHub.publish(result.storageHash, result.noteIds);
  }
}

export async function receiveOriginalAsset(database: DatabaseManager,
  arrival: OriginalAssetArrival): Promise<void> {
  return receiveOriginalImageAsset(database, arrival);
}

export async function storeImportedOriginalAsset(database: DatabaseManager,
  metadata: OriginalAssetMetadata, bytes: Uint8Array, noteId: string): Promise<void> {
  const result: AssetWriteResult = await writeOriginalImageAssetBytes(database, {
    assetHashBits: metadata.assetHashBits,
    bytes: bytes,
    expectedFileSize: metadata.fileSize,
    expectedMimeType: metadata.mimeType,
  }, noteId, true);
  if (result.becameAvailable) {
    assetAvailabilityHub.publish(result.storageHash, result.noteIds);
  }
}

async function writeOriginalImageAssetBytes(database: DatabaseManager, arrival: OriginalImageAssetArrival,
  noteId: string | null, allowCreate: boolean): Promise<AssetWriteResult> {
  validateArrivalMetadata(arrival);
  const storageHash: string = originalAssetStorageHash(arrival.assetHashBits);
  const digestHex: string = await sha512Hex(arrival.bytes);
  if (digestHex !== storageHash) {
    throw new Error('original image asset SHA-512 does not match its declared hash');
  }
  const legacyHash: string = originalAssetHashKey(arrival.assetHashBits);
  return await assetMutationMutex.runExclusive(async (): Promise<AssetWriteResult> => {
    const store: relationalStore.RdbStore = database.getStore();
    const finalDirectory: string = database.getFilesDir() + '/assets/final';
    const pendingDirectory: string = database.getFilesDir() + '/assets/pending';
    const finalPath: string = finalDirectory + '/' + storageHash;
    let createdFile: boolean = false;
    await store.beginTransaction();
    try {
      const rows: StoredAssetRecord[] = await readStoredAssetRecords(store, storageHash, legacyHash);
      if (rows.length === 0 && !allowCreate) {
        throw new Error('original image asset metadata is not registered');
      }
      let noteIds: string[] = [];
      for (const row of rows) {
        if (row.fileSize !== arrival.expectedFileSize ||
          row.mimeType.toLowerCase() !== arrival.expectedMimeType.toLowerCase()) {
          throw new Error('original image asset metadata conflicts with registered metadata');
        }
        noteIds = mergeNoteIds(noteIds, row.noteIds);
      }
      if (noteId !== null) {
        noteIds = mergeNoteIds(noteIds, [noteId]);
      }

      const available: StoredAssetRecord | null = preferredAvailableRecord(rows, storageHash);
      let targetStatus: AssetStatus = AssetStatus.LOCAL;
      let targetPath: string = finalPath;
      if (available !== null) {
        if (available.localPath === null || available.localPath.length === 0 ||
          !fileIo.accessSync(available.localPath)) {
          throw new Error('available original image asset has no readable local file');
        }
        for (const row of rows) {
          if (isAvailableStatus(row.status) && row.localPath !== available.localPath) {
            throw new Error('available original image asset rows have conflicting local paths');
          }
        }
        if (fileIo.statSync(available.localPath).size !== arrival.bytes.length ||
          !fileContentsEqual(available.localPath, arrival.bytes)) {
          throw new Error('available original image asset contents conflict with received data');
        }
        targetStatus = available.status;
        targetPath = available.localPath;
      } else {
        for (const row of rows) {
          if (row.localPath !== null && row.localPath.length > 0 && row.localPath !== finalPath) {
            throw new Error('unavailable original image asset has a conflicting local path');
          }
        }
        fileIo.mkdirSync(finalDirectory, true);
        fileIo.mkdirSync(pendingDirectory, true);
        createdFile = writeFileAtomically(pendingDirectory, finalPath, arrival.bytes);
      }

      const canonical: StoredAssetRecord | undefined = rows.find(
        (row: StoredAssetRecord): boolean => row.assetHash === storageHash);
      const bucket: relationalStore.ValuesBucket = {
        'status': targetStatus,
        'note_ids': JSON.stringify(noteIds),
        'file_size': arrival.expectedFileSize,
        'mime_type': rows.length === 0 ? arrival.expectedMimeType : rows[0].mimeType,
        'local_path': targetPath,
      };
      if (canonical === undefined) {
        await store.insert('note_asset', {
          'asset_hash': storageHash,
          'status': targetStatus,
          'note_ids': JSON.stringify(noteIds),
          'file_size': arrival.expectedFileSize,
          'mime_type': rows.length === 0 ? arrival.expectedMimeType : rows[0].mimeType,
          'local_path': targetPath,
        });
      } else {
        const predicates = new relationalStore.RdbPredicates('note_asset');
        predicates.equalTo('asset_hash', storageHash);
        if (await store.update(bucket, predicates) !== 1) {
          throw new Error('original image asset changed concurrently');
        }
      }
      if (legacyHash !== storageHash && rows.some(
        (row: StoredAssetRecord): boolean => row.assetHash === legacyHash)) {
        const legacyPredicates = new relationalStore.RdbPredicates('note_asset');
        legacyPredicates.equalTo('asset_hash', legacyHash);
        if (await store.delete(legacyPredicates) !== 1) {
          throw new Error('legacy original image asset changed concurrently');
        }
      }
      await store.commit();
      return {
        storageHash: storageHash,
        noteIds: noteIds,
        becameAvailable: available === null,
      };
    } catch (error) {
      try {
        await store.rollBack();
      } catch (rollbackError) {
        console.error(`original image asset rollback failed: ${JSON.stringify(rollbackError)}`);
      }
      if (createdFile && fileIo.accessSync(finalPath)) {
        try {
          fileIo.unlinkSync(finalPath);
        } catch (cleanupError) {
          console.error(`original image asset compensation failed: ${JSON.stringify(cleanupError)}`);
        }
      }
      throw new Error(`storing original image asset failed: ${JSON.stringify(error)}`);
    }
  });
}

function validateArrivalMetadata(arrival: OriginalImageAssetArrival): void {
  if (!Number.isSafeInteger(arrival.expectedFileSize) || arrival.expectedFileSize <= 0 ||
    arrival.bytes.length !== arrival.expectedFileSize) {
    throw new Error('original image asset length does not match metadata');
  }
  if (arrival.expectedMimeType.length === 0) {
    throw new Error('original image asset MIME type is empty');
  }
}

async function readStoredAssetRecords(store: relationalStore.RdbStore, storageHash: string,
  legacyHash: string): Promise<StoredAssetRecord[]> {
  const rows = storageHash === legacyHash ? await store.querySql(
    `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
     FROM note_asset WHERE asset_hash = ?`, [storageHash]) : await store.querySql(
    `SELECT asset_hash, status, note_ids, file_size, mime_type, local_path
     FROM note_asset WHERE asset_hash = ? OR asset_hash = ?`, [storageHash, legacyHash]);
  const result: StoredAssetRecord[] = [];
  try {
    while (rows.goToNextRow()) {
      const status: number = rows.getLong(rows.getColumnIndex('status'));
      if (status < AssetStatus.PENDING || status > AssetStatus.FAILED) {
        throw new Error('original image asset has an invalid status');
      }
      const pathColumn: number = rows.getColumnIndex('local_path');
      result.push({
        assetHash: rows.getString(rows.getColumnIndex('asset_hash')),
        status: status as AssetStatus,
        noteIds: parseAssetNoteIds(rows.getString(rows.getColumnIndex('note_ids'))),
        fileSize: rows.getLong(rows.getColumnIndex('file_size')),
        mimeType: rows.getString(rows.getColumnIndex('mime_type')),
        localPath: rows.isColumnNull(pathColumn) ? null : rows.getString(pathColumn),
      });
    }
  } finally {
    rows.close();
  }
  return result;
}

function preferredAvailableRecord(rows: StoredAssetRecord[], storageHash: string): StoredAssetRecord | null {
  for (const row of rows) {
    if (row.assetHash === storageHash && isAvailableStatus(row.status)) {
      return row;
    }
  }
  for (const row of rows) {
    if (isAvailableStatus(row.status)) {
      return row;
    }
  }
  return null;
}

function isAvailableStatus(status: AssetStatus): boolean {
  return status === AssetStatus.LOCAL || status === AssetStatus.UPLOADED || status === AssetStatus.DOWNLOADED;
}

function readFileFully(fd: number, size: number): Uint8Array {
  const output: Uint8Array = new Uint8Array(size);
  let total: number = 0;
  while (total < size) {
    const chunkBuffer: ArrayBuffer = new ArrayBuffer(size - total);
    const read: number = fileIo.readSync(fd, chunkBuffer);
    if (read <= 0) {
      throw new Error(`short image asset read at ${total}/${size}`);
    }
    output.set(new Uint8Array(chunkBuffer, 0, read), total);
    total += read;
  }
  return output;
}

function writeFileAtomically(pendingDirectory: string, finalPath: string, bytes: Uint8Array): boolean {
  if (fileIo.accessSync(finalPath)) {
    if (fileIo.statSync(finalPath).size !== bytes.length) {
      throw new Error('existing original asset file has a conflicting size');
    }
    if (!fileContentsEqual(finalPath, bytes)) {
      throw new Error('existing original asset file has conflicting contents');
    }
    return false;
  }
  const temporaryPath: string = pendingDirectory +
    `/pending_asset_${Date.now()}_${Math.floor(Math.random() * 0x1000000)}.tmp`;
  const file: fileIo.File = fileIo.openSync(temporaryPath,
    fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
  let completed: boolean = false;
  try {
    let offset: number = 0;
    while (offset < bytes.length) {
      const chunk: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset + offset,
        bytes.byteOffset + bytes.length) as ArrayBuffer;
      const written: number = fileIo.writeSync(file.fd, chunk);
      if (written <= 0) {
        throw new Error(`short image asset write at ${offset}/${bytes.length}`);
      }
      offset += written;
    }
    fileIo.fsyncSync(file.fd);
    completed = true;
  } finally {
    fileIo.closeSync(file);
    if (!completed && fileIo.accessSync(temporaryPath)) {
      fileIo.unlinkSync(temporaryPath);
    }
  }
  try {
    fileIo.renameSync(temporaryPath, finalPath);
  } catch (error) {
    if (fileIo.accessSync(temporaryPath)) {
      fileIo.unlinkSync(temporaryPath);
    }
    throw new Error(`moving original image asset into final storage failed: ${JSON.stringify(error)}`);
  }
  return true;
}

function fileContentsEqual(path: string, expected: Uint8Array): boolean {
  const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
  try {
    const actual: Uint8Array = readFileFully(file.fd, expected.length);
    for (let index: number = 0; index < expected.length; index++) {
      if (actual[index] !== expected[index]) {
        return false;
      }
    }
    return true;
  } finally {
    fileIo.closeSync(file);
  }
}
