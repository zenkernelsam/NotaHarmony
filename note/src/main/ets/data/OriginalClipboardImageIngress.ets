import { pasteboard } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import {
  isOriginalNormalizedImageDimensions, planOriginalImageDownscale,
} from '../core/model/OriginalImageInsertPlan';
import { normalizeOriginalImageBytes } from './OriginalImageNormalizer';
import { isValidOriginalPhotoUri } from './OriginalPhotoIngress';

const CLIPBOARD_IMAGE_MAX_BYTES: number = 104857600;
const WEBP_LOSSY_QUALITY: number = 85;

export interface NormalizedOriginalClipboardImage {
  bytes: Uint8Array;
  width: number;
  height: number;
  encodedWidth: number;
  encodedHeight: number;
  mimeType: string;
  rewroteBytes: boolean;
  fileExtension: string;
}

// 原版 x7j.c：剪贴板图像门 = hasMimeType("image/*") —— URI 载体同样成立。
// Harmony 无 image/* 记录级 MIME；text/uri 记录以扩展名预筛，解码兜底。
export interface OriginalClipboardImageSource {
  pixelMap: image.PixelMap | null;
  uri?: string;
  release: () => Promise<void>;
}

export type OriginalClipboardImageReader = () => Promise<OriginalClipboardImageSource | null>;

export type OriginalClipboardImageAvailabilityProbe =
  () => Promise<boolean>;

export type OriginalClipboardImageChangeListener = () => void;

let readOriginalClipboardImage: OriginalClipboardImageReader = readWithHarmonyPasteboard;

let probeOriginalClipboardImageAvailability: OriginalClipboardImageAvailabilityProbe =
  probeWithHarmonyPasteboardMimeTypes;

export function setOriginalClipboardImageReaderForTest(
  reader: OriginalClipboardImageReader): void {
  readOriginalClipboardImage = reader;
}

export function resetOriginalClipboardImageReaderForTest(): void {
  readOriginalClipboardImage = readWithHarmonyPasteboard;
}

export function setOriginalClipboardImageAvailabilityProbeForTest(
  probe: OriginalClipboardImageAvailabilityProbe): void {
  probeOriginalClipboardImageAvailability = probe;
}

export function resetOriginalClipboardImageAvailabilityProbeForTest(): void {
  probeOriginalClipboardImageAvailability = probeWithHarmonyPasteboardMimeTypes;
}

async function probeWithHarmonyPasteboardMimeTypes(): Promise<boolean> {
  const systemPasteboard: pasteboard.SystemPasteboard =
    pasteboard.getSystemPasteboard();
  const mimeTypes: string[] = await systemPasteboard.getMimeTypes();
  if (mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)) {
    return true;
  }
  // 原版 x7j.c 的 image/* 门在 Harmony 侧等价于 text/uri 记录 + 扩展名预筛。
  if (!mimeTypes.includes(pasteboard.MIMETYPE_TEXT_URI) ||
    !(await systemPasteboard.hasData())) {
    return false;
  }
  try {
    const data: pasteboard.PasteData = await systemPasteboard.getData();
    return firstSupportedClipboardImageUri(data) !== null;
  } catch (_error) {
    return false;
  }
}

export async function isOriginalClipboardImageAvailable(): Promise<boolean> {
  try {
    return await probeOriginalClipboardImageAvailability();
  } catch (_probeError) {
    return false;
  }
}

export function addOriginalClipboardImageChangeListenerForTest(
  listener: OriginalClipboardImageChangeListener): void {
  try {
    pasteboard.getSystemPasteboard().on('update', listener);
  } catch (e) {
    hilog.error(0x0001, 'OriginalClipboardImageIngress',
      'pasteboard update subscribe failed: %{public}s', JSON.stringify(e));
    throw e as Error;
  }
}

export function removeOriginalClipboardImageChangeListenerForTest(
  listener: OriginalClipboardImageChangeListener): void {
  try {
    pasteboard.getSystemPasteboard().off('update', listener);
  } catch (e) {
    hilog.error(0x0001, 'OriginalClipboardImageIngress',
      'pasteboard update unsubscribe failed: %{public}s', JSON.stringify(e));
    throw e as Error;
  }
}

function firstSupportedClipboardImageUri(data: pasteboard.PasteData): string | null {
  const count: number = data.getRecordCount();
  for (let index = 0; index < count; index++) {
    let record: pasteboard.PasteDataRecord;
    try {
      record = data.getRecord(index);
    } catch (_error) {
      continue;
    }
    const uri: string = record.uri;
    if (typeof uri === 'string' && isValidOriginalPhotoUri(uri)) {
      return uri;
    }
  }
  return null;
}

async function readWithHarmonyPasteboard(): Promise<OriginalClipboardImageSource | null> {
  const systemPasteboard: pasteboard.SystemPasteboard =
    pasteboard.getSystemPasteboard();
  if (!(await systemPasteboard.hasData())) {
    return null;
  }
  const data: pasteboard.PasteData = await systemPasteboard.getData();
  const mimeTypes: string[] = data.getProperty().mimeTypes;
  if (mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)) {
    let released = false;
    const pixelMap: image.PixelMap = await data.getPrimaryPixelMap();
    return {
      pixelMap: pixelMap,
      release: async (): Promise<void> => {
        if (!released) {
          released = true;
          await pixelMap.release();
        }
      },
    };
  }
  if (!mimeTypes.includes(pasteboard.MIMETYPE_TEXT_URI)) {
    return null;
  }
  const uri: string | null = firstSupportedClipboardImageUri(data);
  if (uri === null) {
    return null;
  }
  return {
    pixelMap: null,
    uri: uri,
    release: async (): Promise<void> => {
    },
  };
}

export async function importOriginalClipboardImage():
  Promise<NormalizedOriginalClipboardImage> {
  const source: OriginalClipboardImageSource | null = await readOriginalClipboardImage();
  if (source === null) {
    throw new Error('system pasteboard has no original clipboard image');
  }
  try {
    if (source.pixelMap !== null) {
      const normalized: NormalizedOriginalClipboardImage =
        await normalizeOriginalPixelMap(source.pixelMap);
      return normalized;
    }
    if (typeof source.uri === 'string' && source.uri.length > 0) {
      return await normalizeClipboardImageUri(source.uri);
    }
    throw new Error('system pasteboard has no original clipboard image');
  } finally {
    await source.release();
  }
}

async function normalizeClipboardImageUri(uri: string):
  Promise<NormalizedOriginalClipboardImage> {
  const bytes: Uint8Array = await readClipboardImageUri(uri);
  const normalized = await normalizeOriginalImageBytes(bytes);
  return {
    bytes: normalized.bytes,
    width: normalized.orientedWidth,
    height: normalized.orientedHeight,
    encodedWidth: normalized.encodedWidth,
    encodedHeight: normalized.encodedHeight,
    mimeType: normalized.mimeType,
    rewroteBytes: normalized.rewroteBytes,
    fileExtension: normalized.rewroteBytes ? 'webp' : uriExtension(uri),
  };
}

async function readClipboardImageUri(uri: string): Promise<Uint8Array> {
  let file: fileIo.File | null = null;
  try {
    file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    const stat: fileIo.Stat = fileIo.statSync(file.fd);
    if (!Number.isSafeInteger(stat.size) || stat.size <= 0 ||
      stat.size > CLIPBOARD_IMAGE_MAX_BYTES) {
      throw new Error(`original clipboard image exceeds ${CLIPBOARD_IMAGE_MAX_BYTES} bytes`);
    }
    const bytes: Uint8Array = new Uint8Array(stat.size);
    let total: number = 0;
    while (total < stat.size) {
      const chunk: ArrayBuffer = new ArrayBuffer(Math.min(1048576, stat.size - total));
      const read: number = fileIo.readSync(file.fd, chunk);
      if (read <= 0) {
        throw new Error('original clipboard image read ended unexpectedly');
      }
      bytes.set(new Uint8Array(chunk, 0, read), total);
      total += read;
    }
    return bytes;
  } finally {
    if (file !== null) {
      fileIo.closeSync(file);
    }
  }
}

function uriExtension(uri: string): string {
  const separator: number = uri.lastIndexOf('/');
  const fileName: string = separator >= 0 ? uri.slice(separator + 1) : uri;
  const dot: number = fileName.lastIndexOf('.');
  return dot > 0 ? fileName.slice(dot + 1).toLowerCase() : 'img';
}

export async function normalizeOriginalPixelMap(pixelMap: image.PixelMap):
  Promise<NormalizedOriginalClipboardImage> {
  const info: image.ImageInfo = await pixelMap.getImageInfo();
  if (!validDimensions(info.size.width, info.size.height)) {
    throw new Error('original clipboard image dimensions are invalid');
  }
  const plan = planOriginalImageDownscale(info.size.width, info.size.height);
  if (plan === null || !isOriginalNormalizedImageDimensions(plan.width, plan.height)) {
    throw new Error('original clipboard image normalization is invalid');
  }
  let normalized: image.PixelMap = pixelMap;
  let ownedNormalized: boolean = false;
  try {
    if (plan.sampleSize > 1 || plan.width !== info.size.width ||
      plan.height !== info.size.height) {
      normalized = await pixelMap.createScaledPixelMap(
        plan.width / info.size.width, plan.height / info.size.height);
      ownedNormalized = true;
    }
    const scaledInfo: image.ImageInfo = await normalized.getImageInfo();
    if (scaledInfo.size.width !== plan.width || scaledInfo.size.height !== plan.height) {
      throw new Error('original clipboard normalization produced unexpected dimensions');
    }
    const packed: ArrayBuffer = await packWebpLossy(normalized);
    const bytes: Uint8Array = new Uint8Array(packed);
    if (bytes.byteLength <= 0 || bytes.byteLength > CLIPBOARD_IMAGE_MAX_BYTES) {
      throw new Error(`original clipboard image exceeds ${CLIPBOARD_IMAGE_MAX_BYTES} bytes`);
    }
    return {
      bytes: bytes, width: plan.width, height: plan.height,
      encodedWidth: plan.width, encodedHeight: plan.height,
      mimeType: 'image/webp', rewroteBytes: true, fileExtension: 'webp',
    };
  } finally {
    if (ownedNormalized) {
      try {
        await normalized.release();
      } catch (_releaseError) {
      }
    }
  }
}

async function packWebpLossy(pixelMap: image.PixelMap): Promise<ArrayBuffer> {
  const packer: image.ImagePacker = image.createImagePacker();
  try {
    return await packer.packToData(pixelMap, {
      format: 'image/webp', quality: WEBP_LOSSY_QUALITY,
      bufferSize: CLIPBOARD_IMAGE_MAX_BYTES + 1,
    });
  } finally {
    await packer.release();
  }
}

function validDimensions(width: number, height: number): boolean {
  return Number.isSafeInteger(width) && Number.isSafeInteger(height) &&
    width > 0 && height > 0 && width <= CLIPBOARD_IMAGE_MAX_BYTES &&
    height <= CLIPBOARD_IMAGE_MAX_BYTES;
}
