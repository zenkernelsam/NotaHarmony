import { pasteboard } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

const CLIPBOARD_IMAGE_MAX_SIDE: number = 12000;
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

let readOriginalClipboardImage: OriginalClipboardImageReader = readWithHarmonyPasteboard;

export function setOriginalClipboardImageReaderForTest(
  reader: OriginalClipboardImageReader): void {
  readOriginalClipboardImage = reader;
}

export function resetOriginalClipboardImageReaderForTest(): void {
  readOriginalClipboardImage = readWithHarmonyPasteboard;
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
    const packed: ArrayBuffer = await packWebpLossy(source.pixelMap);
    const bytes: Uint8Array = new Uint8Array(packed);
    if (bytes.byteLength <= 0 || bytes.byteLength > CLIPBOARD_IMAGE_MAX_BYTES) {
      throw new Error(`original clipboard image exceeds ${CLIPBOARD_IMAGE_MAX_BYTES} bytes`);
    }
    return { bytes: bytes, width: info.size.width, height: info.size.height };
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
    width > 0 && height > 0 && width <= CLIPBOARD_IMAGE_MAX_SIDE &&
    height <= CLIPBOARD_IMAGE_MAX_SIDE;
}
