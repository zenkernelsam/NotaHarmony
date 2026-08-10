import { fileIo } from '@kit.CoreFileKit';
import { ImageElement } from '../core/model/ElementTypes';
import { originalAssetLookupKeys, originalAssetStorageHash } from '../core/model/ImageBlockGeometry';
import { AssetStatus, NoteAsset } from '../core/model/AssetTypes';
import { AssetRepositoryImpl } from './AssetRepositoryImpl';
import { DatabaseManager } from './DatabaseManager';

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
  if (bytes.length !== element.fileSize) {
    throw new Error(`imported image asset ${element.id} length does not match metadata`);
  }
  const repository: AssetRepositoryImpl = new AssetRepositoryImpl(database);
  const existing: NoteAsset | null = await resolveImageAsset(repository, element);
  if (existing !== null) {
    if (existing.fileSize > 0 && existing.fileSize !== bytes.length) {
      throw new Error(`existing image asset ${element.id} conflicts with imported size`);
    }
    if (existing.localPath !== null && existing.localPath.length > 0 && fileIo.accessSync(existing.localPath)) {
      const existingSize: number = fileIo.statSync(existing.localPath).size;
      if (existingSize !== bytes.length) {
        throw new Error(`existing image asset ${element.id} local file is corrupt`);
      }
      if (!fileContentsEqual(existing.localPath, bytes)) {
        throw new Error(`existing image asset ${element.id} contents conflict with imported data`);
      }
      await repository.saveAsset({
        assetHash: existing.assetHash, status: availableLocalStatus(existing.status),
        noteIds: [noteId], fileSize: bytes.length, mimeType: element.mimeType,
        localPath: existing.localPath,
      });
      return;
    }
  }
  const storageHash: string = originalAssetStorageHash(element.assetHashBits);
  const finalDirectory: string = database.getFilesDir() + '/assets/final';
  fileIo.mkdirSync(finalDirectory, true);
  const finalPath: string = finalDirectory + '/' + storageHash;
  const createdFile: boolean = writeFileAtomically(finalPath, bytes);
  try {
    await repository.saveAsset({
      assetHash: existing === null ? storageHash : existing.assetHash,
      status: AssetStatus.LOCAL,
      noteIds: [noteId],
      fileSize: bytes.length,
      mimeType: element.mimeType,
      localPath: finalPath,
    });
  } catch (error) {
    if (createdFile && fileIo.accessSync(finalPath)) {
      fileIo.unlinkSync(finalPath);
    }
    throw new Error(`saving imported image asset failed: ${JSON.stringify(error)}`);
  }
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

function writeFileAtomically(finalPath: string, bytes: Uint8Array): boolean {
  if (fileIo.accessSync(finalPath)) {
    if (fileIo.statSync(finalPath).size !== bytes.length) {
      throw new Error('existing original asset file has a conflicting size');
    }
    if (!fileContentsEqual(finalPath, bytes)) {
      throw new Error('existing original asset file has conflicting contents');
    }
    return false;
  }
  const temporaryPath: string = finalPath + `.tmp-${Date.now()}-${Math.floor(Math.random() * 0x1000000)}`;
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
  fileIo.renameSync(temporaryPath, finalPath);
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

function availableLocalStatus(status: AssetStatus): AssetStatus {
  if (status === AssetStatus.PENDING || status === AssetStatus.FAILED) {
    return AssetStatus.LOCAL;
  }
  return status;
}
