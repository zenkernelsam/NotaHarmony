import { fileIo } from '@kit.CoreFileKit';
import { NormalizedOriginalImageBytes, normalizeOriginalImageBytes } from './OriginalImageNormalizer';

export const ORIGINAL_PHOTO_MAX_BYTES: number = 104857600;

const SUPPORTED_EXTENSIONS: string[] = [
  'png', 'jpg', 'jpeg', 'webp', 'tif', 'tiff', 'gif', 'heif', 'heic',
];

export interface OriginalPhotoIngressItem {
  bytes: Uint8Array;
  fileName: string;
  mimeType: string;
  encodedWidth: number;
  encodedHeight: number;
  orientedWidth: number;
  orientedHeight: number;
}

export type OriginalPhotoUriReader = (uri: string, maxBytes: number) => Promise<Uint8Array>;

let readOriginalPhotoUri: OriginalPhotoUriReader = readPhotoUriWithLimit;

export function setOriginalPhotoUriReaderForTest(reader: OriginalPhotoUriReader): void {
  readOriginalPhotoUri = reader;
}

export function resetOriginalPhotoUriReaderForTest(): void {
  readOriginalPhotoUri = readPhotoUriWithLimit;
}

export function validateOriginalPhotoSelection(uris: string[]): boolean {
  return Array.isArray(uris) && uris.length > 0 && uris.every((uri: string) =>
    typeof uri === 'string' && isValidOriginalPhotoUri(uri));
}

export function isOversizedOriginalPhoto(size: number): boolean {
  return !Number.isSafeInteger(size) || size <= 0 || size > ORIGINAL_PHOTO_MAX_BYTES;
}

export function isValidOriginalPhotoUri(uri: string): boolean {
  const separator: number = uri.lastIndexOf('/');
  const fileName: string = separator >= 0 ? uri.slice(separator + 1) : uri;
  const extensionStart: number = fileName.lastIndexOf('.');
  if (extensionStart <= 0 || fileName.length - extensionStart > 6) {
    return false;
  }
  const extension: string = fileName.slice(extensionStart + 1).toLowerCase();
  return SUPPORTED_EXTENSIONS.includes(extension);
}

export async function importOriginalPhotos(uris: string[], cacheDirectory: string):
  Promise<OriginalPhotoIngressItem[]> {
  if (!Array.isArray(uris) || uris.length === 0 || typeof cacheDirectory !== 'string' ||
    cacheDirectory === '') {
    throw new Error('original photo selection is empty');
  }
  for (const uri of uris) {
    if (typeof uri !== 'string' || !isValidOriginalPhotoUri(uri)) {
      throw new Error('original photo selection contains an unsupported image');
    }
  }
  const temporaryPaths: string[] = [];
  try {
    const items: OriginalPhotoIngressItem[] = [];
    for (const uri of uris) {
      const copyPath: string = createTemporaryPhotoCopy(cacheDirectory);
      temporaryPaths.push(copyPath);
      const bytes: Uint8Array = await readOriginalPhotoUri(uri,
        ORIGINAL_PHOTO_MAX_BYTES + 1);
      await writeTemporaryPhotoCopy(copyPath, bytes);
      if (isOversizedOriginalPhoto(bytes.byteLength)) {
        throw new Error(`original photo exceeds ${ORIGINAL_PHOTO_MAX_BYTES} bytes`);
      }
      const normalized: NormalizedOriginalImageBytes = await normalizeOriginalImageBytes(bytes);
      items.push({
        bytes: normalized.bytes,
        fileName: `photo-${temporaryPaths.length}.${fileExtension(uri)}`,
        mimeType: normalized.mimeType,
        encodedWidth: normalized.encodedWidth,
        encodedHeight: normalized.encodedHeight,
        orientedWidth: normalized.orientedWidth,
        orientedHeight: normalized.orientedHeight,
      });
    }
    return items;
  } finally {
    removeTemporaryCopies(temporaryPaths);
  }
}

function fileExtension(uri: string): string {
  return uri.slice(uri.lastIndexOf('.') + 1).toLowerCase();
}

function createTemporaryPhotoCopy(cacheDirectory: string): string {
  if (typeof cacheDirectory !== 'string' || cacheDirectory === '') {
    throw new Error('original photo ingress cache directory is unavailable');
  }
  return `${cacheDirectory}/temp_${Date.now()}_${Math.random().toString(36).slice(2)}.bin`;
}

async function writeTemporaryPhotoCopy(path: string, bytes: Uint8Array): Promise<void> {
  let file: fileIo.File | null = null;
  try {
    file = fileIo.openSync(path,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    const source: ArrayBuffer = bytes.buffer.slice(
      bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
    let total: number = 0;
    while (total < source.byteLength) {
      total += fileIo.writeSync(file.fd, source, { offset: total });
    }
  } finally {
    if (file !== null) {
      fileIo.closeSync(file);
    }
  }
}

function removeTemporaryCopies(paths: string[]): void {
  for (const path of paths) {
    try {
      if (fileIo.accessSync(path)) {
        fileIo.unlinkSync(path);
      }
    } catch (_cleanupError) {
    }
  }
}

async function readPhotoUriWithLimit(uri: string, maxBytes: number): Promise<Uint8Array> {
  let file: fileIo.File | null = null;
  try {
    file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const stat: fileIo.Stat = fileIo.statSync(file.fd);
    if (!Number.isSafeInteger(stat.size) || stat.size < 0) {
      throw new Error('original photo size is invalid');
    }
    if (stat.size > maxBytes) {
      throw new Error('original photo exceeds the ingress limit');
    }
    const output: Uint8Array = new Uint8Array(stat.size);
    let total = 0;
    while (total < stat.size) {
      const requested: number = Math.min(1024 * 1024, stat.size - total);
      const chunk: ArrayBuffer = new ArrayBuffer(requested);
      const read: number = fileIo.readSync(file.fd, chunk);
      if (read <= 0 || read > requested) {
        throw new Error('original photo read ended unexpectedly');
      }
      output.set(new Uint8Array(chunk, 0, read), total);
      total += read;
    }
    return output;
  } catch (error) {
    throw new Error(`reading original photo failed: ${JSON.stringify(error)}`);
  } finally {
    if (file !== null) {
      fileIo.closeSync(file);
    }
  }
}
