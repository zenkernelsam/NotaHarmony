import { pasteboard } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import {
  isOriginalNormalizedImageDimensions, planOriginalImageDownscale,
} from '../core/model/OriginalImageInsertPlan';

const CLIPBOARD_IMAGE_MAX_BYTES: number = 104857600;
const WEBP_LOSSY_QUALITY: number = 85;

export interface NormalizedOriginalClipboardImage {
  bytes: Uint8Array;
  width: number;
  height: number;
}

export interface OriginalClipboardImageSource {
  pixelMap: image.PixelMap;
  release: () => Promise<void>;
}

export type OriginalClipboardImageReader = () => Promise<OriginalClipboardImageSource | null>;

export type OriginalClipboardImageAvailabilityProbe =
  () => Promise<boolean>;

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
  return mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP);
}

export async function isOriginalClipboardImageAvailable(): Promise<boolean> {
  try {
    return await probeOriginalClipboardImageAvailability();
  } catch (_probeError) {
    return false;
  }
}

async function readWithHarmonyPasteboard(): Promise<OriginalClipboardImageSource | null> {
  const systemPasteboard: pasteboard.SystemPasteboard =
    pasteboard.getSystemPasteboard();
  if (!(await systemPasteboard.hasData())) {
    return null;
  }
  const data: pasteboard.PasteData = await systemPasteboard.getData();
  const mimeTypes: string[] = data.getProperty().mimeTypes;
  if (!mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)) {
    return null;
  }
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

export async function importOriginalClipboardImage():
  Promise<NormalizedOriginalClipboardImage> {
  const source: OriginalClipboardImageSource | null = await readOriginalClipboardImage();
  if (source === null) {
    throw new Error('system pasteboard has no original clipboard image');
  }
  try {
    const info: image.ImageInfo = await source.pixelMap.getImageInfo();
    if (!validDimensions(info.size.width, info.size.height)) {
      throw new Error('original clipboard image dimensions are invalid');
    }
    const plan = planOriginalImageDownscale(info.size.width, info.size.height);
    if (plan === null || !isOriginalNormalizedImageDimensions(plan.width, plan.height)) {
      throw new Error('original clipboard image normalization is invalid');
    }
    let normalized: image.PixelMap = source.pixelMap;
    let ownedNormalized: boolean = false;
    try {
      if (plan.sampleSize > 1 || plan.width !== info.size.width ||
        plan.height !== info.size.height) {
        normalized = await source.pixelMap.createScaledPixelMap(
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
      return { bytes: bytes, width: plan.width, height: plan.height };
    } finally {
      if (ownedNormalized) {
        try {
          await normalized.release();
        } catch (_releaseError) {
        }
      }
    }
  } finally {
    await source.release();
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
