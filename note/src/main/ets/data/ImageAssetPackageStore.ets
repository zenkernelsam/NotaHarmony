import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { ImageElement } from '../core/model/ElementTypes';
import {
  originalAssetHashKey, originalAssetLookupKeys, originalAssetStorageHash,
} from '../core/model/ImageBlockGeometry';
import { AssetStatus, NoteAsset } from '../core/model/AssetTypes';
import { OriginalAssetMetadata } from '../core/model/NoteTypes';
import {
  isOriginalNormalizedImageDimensions, originalImageDecodedDimensionsAreConsistent,
  originalImageOrientedDimensions, OriginalImagePixelDimensions,
} from '../core/model/OriginalImageInsertPlan';
import {
  assetMutationMutex, AssetRepositoryImpl, mergeNoteIds, parseAssetNoteIds, validateNoteReferences,
} from './AssetRepositoryImpl';
import { assetAvailabilityHub } from './AssetAvailabilityHub';
import {
  originalAssetHashBitsFromSha512, sha512BytesToHex, sha512Digest, sha512Hex,
} from './AssetDigest';
import { DatabaseManager } from './DatabaseManager';
import { databaseWriteMutex } from './DatabaseWriteMutex';

const FILE_IO_CHUNK_SIZE: number = 64 * 1024;
export const MAX_ORIGINAL_LOCAL_IMAGE_ASSET_BYTES: number = 104857600;

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

export interface PreparedLocalOriginalImageAsset {
  metadata: OriginalAssetMetadata;
  intrinsicWidth: number;
  intrinsicHeight: number;
  storageHash: string;
  legacyHash: string;
  filesRoot: string;
  finalPath: string;
  createdFinalFile: boolean;
}

export interface LocalOriginalImageAssetMergeResult {
  noteIds: string[];
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

/**
 * Prepares one caller-owned, immutable byte snapshot while the caller holds
 * assetMutationMutex.  This function performs no database write and acquires
 * no writer mutex, so it can be followed by one editor transaction.
 */
export async function prepareLocalOriginalImageAsset(database: DatabaseManager,
  bytes: Uint8Array, fileName: string, mimeType: string,
  expectedIntrinsicWidth: number, expectedIntrinsicHeight: number):
  Promise<PreparedLocalOriginalImageAsset> {
  validateLocalOriginalImageAssetInput(bytes, fileName, mimeType);
  await validateDecodedLocalOriginalImageAsset(bytes, expectedIntrinsicWidth,
    expectedIntrinsicHeight);
  const digestBytes: Uint8Array = await sha512Digest(bytes);
  const assetHashBits: string[] = originalAssetHashBitsFromSha512(digestBytes);
  const storageHash: string = sha512BytesToHex(digestBytes);
  if (originalAssetStorageHash(assetHashBits) !== storageHash) {
    throw new Error('local image AssetHash conversion is inconsistent');
  }
  const filesRoot: string = database.getFilesDir();
  const pendingDirectory: string = filesRoot + '/assets/pending';
  const finalDirectory: string = filesRoot + '/assets/final';
  const finalPath: string = finalDirectory + '/' + storageHash;
  let createdFinalFile: boolean = false;
  try {
    fileIo.mkdirSync(pendingDirectory, true);
    fileIo.mkdirSync(finalDirectory, true);
    createdFinalFile = writeFileAtomically(pendingDirectory, finalPath, bytes);
    return {
      metadata: {
        assetHashBits: assetHashBits,
        fileName: fileName,
        mimeType: mimeType,
        fileSize: bytes.length,
      },
      intrinsicWidth: expectedIntrinsicWidth,
      intrinsicHeight: expectedIntrinsicHeight,
      storageHash: storageHash,
      legacyHash: originalAssetHashKey(assetHashBits),
      filesRoot: filesRoot,
      finalPath: finalPath,
      createdFinalFile: createdFinalFile,
    };
  } catch (error) {
    if (createdFinalFile) {
      unlinkPreparedLocalOriginalImageAsset({
        metadata: {
          assetHashBits: assetHashBits, fileName: fileName,
          mimeType: mimeType, fileSize: bytes.length,
        },
        intrinsicWidth: expectedIntrinsicWidth,
        intrinsicHeight: expectedIntrinsicHeight,
        storageHash: storageHash,
        legacyHash: originalAssetHashKey(assetHashBits),
        filesRoot: filesRoot,
        finalPath: finalPath,
        createdFinalFile: true,
      });
    }
    throw new Error(`preparing local image asset failed: ${JSON.stringify(error)}`);
  }
}

/**
 * Canonicalizes already-present canonical/legacy rows before CREATE_BLOCK sees
 * them. This is required only for a local insert because it owns verified bytes
 * that can prove two historical private paths contain the same asset.
 */
export async function reconcileExistingPreparedLocalOriginalImageAsset(
  store: relationalStore.RdbStore, noteId: string,
  prepared: PreparedLocalOriginalImageAsset): Promise<void> {
  validatePreparedLocalOriginalImageAsset(noteId, prepared);
  const rows: StoredAssetRecord[] = await readStoredAssetRecords(
    store, prepared.storageHash, prepared.legacyHash);
  if (rows.length > 0) {
    await mergePreparedLocalOriginalImageAssetRows(store, noteId, prepared, rows);
  }
}

/**
 * Upgrades/merges the PENDING reference created by IMAGE CREATE_BLOCK inside
 * the caller's already-open SQLite transaction.  No mutex or transaction is
 * opened here.
 */
export async function mergePreparedLocalOriginalImageAsset(store: relationalStore.RdbStore,
  noteId: string, prepared: PreparedLocalOriginalImageAsset): Promise<LocalOriginalImageAssetMergeResult> {
  validatePreparedLocalOriginalImageAsset(noteId, prepared);
  const rows: StoredAssetRecord[] = await readStoredAssetRecords(
    store, prepared.storageHash, prepared.legacyHash);
  if (rows.length === 0) {
    throw new Error('local image asset was not registered by CREATE_BLOCK');
  }
  return mergePreparedLocalOriginalImageAssetRows(store, noteId, prepared, rows);
}

async function mergePreparedLocalOriginalImageAssetRows(store: relationalStore.RdbStore,
  noteId: string, prepared: PreparedLocalOriginalImageAsset,
  rows: StoredAssetRecord[]): Promise<LocalOriginalImageAssetMergeResult> {
  let noteIds: string[] = [noteId];
  let targetStatus: AssetStatus = AssetStatus.LOCAL;
  for (const row of rows) {
    if (row.fileSize !== prepared.metadata.fileSize ||
      row.mimeType.toLowerCase() !== prepared.metadata.mimeType.toLowerCase()) {
      throw new Error('local image asset metadata conflicts with its CREATE_BLOCK reference');
    }
    validateStoredLocalOriginalImageAssetPath(row.localPath, prepared);
    noteIds = mergeNoteIds(noteIds, row.noteIds);
    if (row.status === AssetStatus.UPLOADED) {
      targetStatus = AssetStatus.UPLOADED;
    } else if (targetStatus !== AssetStatus.UPLOADED && row.status === AssetStatus.DOWNLOADED) {
      targetStatus = AssetStatus.DOWNLOADED;
    }
  }
  await validateNoteReferences(store, noteIds);
  const canonical: StoredAssetRecord | undefined = rows.find(
    (row: StoredAssetRecord): boolean => row.assetHash === prepared.storageHash);
  const bucket: relationalStore.ValuesBucket = {
    'status': targetStatus,
    'note_ids': JSON.stringify(noteIds),
    'file_size': prepared.metadata.fileSize,
    'mime_type': prepared.metadata.mimeType,
    'local_path': prepared.finalPath,
  };
  if (canonical === undefined) {
    await store.insert('note_asset', {
      'asset_hash': prepared.storageHash,
      'status': targetStatus,
      'note_ids': JSON.stringify(noteIds),
      'file_size': prepared.metadata.fileSize,
      'mime_type': prepared.metadata.mimeType,
      'local_path': prepared.finalPath,
    });
  } else {
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', prepared.storageHash);
    if (await store.update(bucket, predicates) !== 1) {
      throw new Error('local image asset changed concurrently');
    }
  }
  if (prepared.legacyHash !== prepared.storageHash && rows.some(
    (row: StoredAssetRecord): boolean => row.assetHash === prepared.legacyHash)) {
    const predicates = new relationalStore.RdbPredicates('note_asset');
    predicates.equalTo('asset_hash', prepared.legacyHash);
    if (await store.delete(predicates) !== 1) {
      throw new Error('legacy local image asset changed concurrently');
    }
  }
  return { noteIds: noteIds };
}

export function unlinkPreparedLocalOriginalImageAsset(
  prepared: PreparedLocalOriginalImageAsset): void {
  if (!prepared.createdFinalFile) {
    return;
  }
  try {
    if (prepared.finalPath.length > 0 && fileIo.accessSync(prepared.finalPath)) {
      fileIo.unlinkSync(prepared.finalPath);
    }
  } catch (error) {
    console.error(`local image asset compensation failed: ${JSON.stringify(error)}`);
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
    return await databaseWriteMutex.runExclusive(async (): Promise<AssetWriteResult> => {
      return writeOriginalImageAssetBytesLocked(
        database, arrival, noteId, allowCreate, storageHash, legacyHash);
    });
  });
}

async function writeOriginalImageAssetBytesLocked(database: DatabaseManager,
  arrival: OriginalImageAssetArrival, noteId: string | null, allowCreate: boolean,
  storageHash: string, legacyHash: string): Promise<AssetWriteResult> {
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
      await validateNoteReferences(store, noteIds);

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

function validateLocalOriginalImageAssetInput(bytes: Uint8Array,
  fileName: string, mimeType: string): void {
  if (bytes === null || bytes === undefined || !Number.isSafeInteger(bytes.length) ||
    bytes.length <= 0 || bytes.length > MAX_ORIGINAL_LOCAL_IMAGE_ASSET_BYTES) {
    throw new Error('local image asset exceeds the original byte boundary');
  }
  if (fileName.length === 0 || mimeType.length <= 6 ||
    !mimeType.toLowerCase().startsWith('image/')) {
    throw new Error('local image asset metadata is invalid');
  }
}

async function validateDecodedLocalOriginalImageAsset(bytes: Uint8Array,
  expectedIntrinsicWidth: number, expectedIntrinsicHeight: number): Promise<void> {
  if (!isOriginalNormalizedImageDimensions(expectedIntrinsicWidth, expectedIntrinsicHeight)) {
    throw new Error('local image asset dimensions were not normalized by the original 3000px boundary');
  }
  const buffer: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset,
    bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
  let source: image.ImageSource | null = null;
  let pixelMap: image.PixelMap | null = null;
  try {
    source = image.createImageSource(buffer);
    const encodedInfo: image.ImageInfo = await source.getImageInfo();
    if (!isOriginalNormalizedImageDimensions(encodedInfo.size.width, encodedInfo.size.height) ||
      encodedInfo.mimeType.length <= 6 ||
      !encodedInfo.mimeType.toLowerCase().startsWith('image/')) {
      throw new Error('decoded image header is invalid or exceeds the original 3000px boundary');
    }
    const orientation: string = await readOriginalImageOrientation(source);
    const oriented: OriginalImagePixelDimensions | null = originalImageOrientedDimensions(
      encodedInfo.size.width, encodedInfo.size.height, orientation);
    if (oriented === null || oriented.width !== expectedIntrinsicWidth ||
      oriented.height !== expectedIntrinsicHeight) {
      throw new Error('decoded image dimensions do not match the insertion plan');
    }
    pixelMap = await source.createPixelMap({ editable: false });
    const decodedInfo: image.ImageInfo = await pixelMap.getImageInfo();
    if (!originalImageDecodedDimensionsAreConsistent(encodedInfo.size.width,
      encodedInfo.size.height, orientation, decodedInfo.size.width, decodedInfo.size.height)) {
      throw new Error('decoded PixelMap dimensions are inconsistent with the image header');
    }
  } catch (error) {
    throw new Error(`local image asset cannot be decoded: ${JSON.stringify(error)}`);
  } finally {
    if (pixelMap !== null) {
      try {
        await pixelMap.release();
      } catch (error) {
        console.warn(`local image validation PixelMap cleanup failed: ${JSON.stringify(error)}`);
      }
    }
    if (source !== null) {
      try {
        await source.release();
      } catch (error) {
        console.warn(`local image validation ImageSource cleanup failed: ${JSON.stringify(error)}`);
      }
    }
  }
}

async function readOriginalImageOrientation(source: image.ImageSource): Promise<string> {
  try {
    return await source.getImageProperty(image.PropertyKey.ORIENTATION, {
      index: 0, defaultValue: '1',
    });
  } catch (_error) {
    return '1';
  }
}

function validatePreparedLocalOriginalImageAsset(noteId: string,
  prepared: PreparedLocalOriginalImageAsset): void {
  if (noteId.length === 0 || prepared.metadata.fileSize <= 0 ||
    prepared.metadata.fileSize > MAX_ORIGINAL_LOCAL_IMAGE_ASSET_BYTES ||
    prepared.metadata.fileName.length === 0 || prepared.metadata.mimeType.length <= 6 ||
    !prepared.metadata.mimeType.toLowerCase().startsWith('image/') ||
    !isOriginalNormalizedImageDimensions(prepared.intrinsicWidth, prepared.intrinsicHeight) ||
    prepared.filesRoot.length === 0 ||
    prepared.finalPath.length === 0 || !fileIo.accessSync(prepared.finalPath)) {
    throw new Error('prepared local image asset is invalid');
  }
  const stat = fileIo.statSync(prepared.finalPath);
  const expectedFinalPath: string = normalizeAssetPath(prepared.filesRoot) +
    '/assets/final/' + prepared.storageHash;
  if (!stat.isFile() || stat.size !== prepared.metadata.fileSize ||
    originalAssetStorageHash(prepared.metadata.assetHashBits) !== prepared.storageHash ||
    originalAssetHashKey(prepared.metadata.assetHashBits) !== prepared.legacyHash ||
    normalizeAssetPath(prepared.finalPath) !== expectedFinalPath) {
    throw new Error('prepared local image asset does not match its file or hash');
  }
}

function validateStoredLocalOriginalImageAssetPath(path: string | null,
  prepared: PreparedLocalOriginalImageAsset): void {
  if (path === null || path.length === 0 ||
    normalizeAssetPath(path) === normalizeAssetPath(prepared.finalPath)) {
    return;
  }
  if (!isAssetPathInside(prepared.filesRoot, path)) {
    if (fileIo.accessSync(path)) {
      throw new Error('local image asset has a readable stored path outside the app files directory');
    }
    return;
  }
  if (!fileIo.accessSync(path)) {
    return;
  }
  const stat = fileIo.statSync(path);
  if (!stat.isFile() || stat.size !== prepared.metadata.fileSize ||
    !filesHaveEqualContents(path, prepared.finalPath, prepared.metadata.fileSize)) {
    throw new Error('local image asset stored path conflicts with the prepared bytes');
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
  if (!Number.isSafeInteger(size) || size < 0) {
    throw new Error(`invalid image asset size: ${size}`);
  }
  const output: Uint8Array = new Uint8Array(size);
  let total: number = 0;
  while (total < size) {
    const requested: number = Math.min(FILE_IO_CHUNK_SIZE, size - total);
    const chunkBuffer: ArrayBuffer = new ArrayBuffer(requested);
    const read: number = fileIo.readSync(fd, chunkBuffer);
    if (read <= 0 || read > requested) {
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
      const end: number = Math.min(bytes.length, offset + FILE_IO_CHUNK_SIZE);
      const view: Uint8Array = bytes.subarray(offset, end);
      const chunk: ArrayBuffer = view.buffer.slice(view.byteOffset,
        view.byteOffset + view.byteLength) as ArrayBuffer;
      const written: number = fileIo.writeSync(file.fd, chunk);
      if (written <= 0 || written > view.byteLength) {
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
  const stat = fileIo.statSync(path);
  if (!stat.isFile() || stat.size !== expected.length) {
    return false;
  }
  const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
  try {
    let total: number = 0;
    while (total < expected.length) {
      const requested: number = Math.min(FILE_IO_CHUNK_SIZE, expected.length - total);
      const buffer: ArrayBuffer = new ArrayBuffer(requested);
      const read: number = fileIo.readSync(file.fd, buffer);
      if (read <= 0 || read > requested) {
        return false;
      }
      const actual: Uint8Array = new Uint8Array(buffer, 0, read);
      for (let index: number = 0; index < read; index++) {
        if (actual[index] !== expected[total + index]) {
          return false;
        }
      }
      total += read;
    }
    return total === expected.length && fileIo.statSync(path).size === expected.length;
  } finally {
    fileIo.closeSync(file);
  }
}

function filesHaveEqualContents(leftPath: string, rightPath: string,
  expectedSize: number): boolean {
  if (normalizeAssetPath(leftPath) === normalizeAssetPath(rightPath)) {
    return true;
  }
  const leftStat = fileIo.statSync(leftPath);
  const rightStat = fileIo.statSync(rightPath);
  if (!leftStat.isFile() || !rightStat.isFile() || leftStat.size !== expectedSize ||
    rightStat.size !== expectedSize) {
    return false;
  }
  const left: fileIo.File = fileIo.openSync(leftPath, fileIo.OpenMode.READ_ONLY);
  let right: fileIo.File | null = null;
  try {
    right = fileIo.openSync(rightPath, fileIo.OpenMode.READ_ONLY);
    let total: number = 0;
    while (total < expectedSize) {
      const requested: number = Math.min(FILE_IO_CHUNK_SIZE, expectedSize - total);
      const leftBytes: Uint8Array | null = readChunkFully(left.fd, requested);
      const rightBytes: Uint8Array | null = readChunkFully(right.fd, requested);
      if (leftBytes === null || rightBytes === null) {
        return false;
      }
      for (let index: number = 0; index < requested; index++) {
        if (leftBytes[index] !== rightBytes[index]) {
          return false;
        }
      }
      total += requested;
    }
    return true;
  } finally {
    if (right !== null) {
      fileIo.closeSync(right);
    }
    fileIo.closeSync(left);
  }
}

function readChunkFully(fd: number, size: number): Uint8Array | null {
  const output: Uint8Array = new Uint8Array(size);
  let total: number = 0;
  while (total < size) {
    const buffer: ArrayBuffer = new ArrayBuffer(size - total);
    const read: number = fileIo.readSync(fd, buffer);
    if (read <= 0 || read > size - total) {
      return null;
    }
    output.set(new Uint8Array(buffer, 0, read), total);
    total += read;
  }
  return output;
}

function isAssetPathInside(root: string, candidate: string): boolean {
  const normalizedRoot: string = normalizeAssetPath(root);
  const normalizedCandidate: string = normalizeAssetPath(candidate);
  return normalizedCandidate.startsWith(normalizedRoot + '/') &&
    normalizedCandidate.indexOf('/../') < 0 && !normalizedCandidate.endsWith('/..');
}

function normalizeAssetPath(value: string): string {
  return value.replace(/\\/g, '/').replace(/\/+$/, '');
}
