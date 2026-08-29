import { image } from '@kit.ImageKit';
import {
  isOriginalNormalizedImageDimensions, ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE,
  originalImageOrientedDimensions,
  planOriginalImageDownscale,
  OriginalImageNormalizationPlan,
} from '../core/model/OriginalImageInsertPlan';

const WEBP_LOSSY_QUALITY: number = 85;

export interface NormalizedOriginalImageBytes {
  bytes: Uint8Array;
  mimeType: string;
  rewroteBytes: boolean;
  encodedWidth: number;
  encodedHeight: number;
  orientedWidth: number;
  orientedHeight: number;
}

/**
 * Harmony adapter for Android vuh.b().  The caller owns the input copy; the
 * returned bytes are an independent normalized snapshot.  WebP lossy encoding
 * is fail-closed because ImageKit support varies by device.
 */
export async function normalizeOriginalImageBytes(bytes: Uint8Array):
  Promise<NormalizedOriginalImageBytes> {
  const stable: Uint8Array = bytes.slice();
  let source: image.ImageSource | null = null;
  let pixelMap: image.PixelMap | null = null;
  try {
    source = await createSource(stable);
    const info: image.ImageInfo = await source.getImageInfo();
    if (!validDimensions(info.size.width, info.size.height)) {
      throw new Error('original image normalization dimensions are invalid');
    }
    const orientation: string = await readOrientation(source);
    const oriented = originalImageOrientedDimensions(
      info.size.width, info.size.height, orientation);
    if (oriented === null) {
      throw new Error('original image EXIF orientation is invalid');
    }
    const rotationDegrees: number = originalRotationDegrees(orientation);
    // Android computes the sampling target from encoded axes, then rotates the
    // scaled bitmap. Keep that distinction explicit instead of feeding the
    // already-oriented axes into the encoded-axis planner.
    const plan = planOriginalImageDownscale(info.size.width, info.size.height);
    const needsNormalization: boolean = !isOriginalNormalizedImageDimensions(
      oriented.width, oriented.height);
    if (plan === null) {
      throw new Error('original image normalization plan is invalid');
    }
    const downscale: OriginalImageNormalizationPlan = plan;
    const targetOriented = originalImageOrientedDimensions(
      downscale.width, downscale.height, orientation);
    if (targetOriented === null) {
      throw new Error('original image normalization target dimensions are invalid');
    }
    if (!needsNormalization) {
      return {
        bytes: stable,
        mimeType: sourceMime(info.mimeType),
        rewroteBytes: false,
        encodedWidth: info.size.width,
        encodedHeight: info.size.height,
        orientedWidth: oriented.width,
        orientedHeight: oriented.height,
      };
    }
    pixelMap = await source.createPixelMap({
      sampleSize: downscale.sampleSize > 1 ? downscale.sampleSize : undefined,
      editable: true,
    });
    if (rotationDegrees > 0) {
      await pixelMap.rotate(rotationDegrees);
    }
    const orientedInfo: image.ImageInfo = await pixelMap.getImageInfo();
    const scaleX: number = originalFloat(
      originalFloat(targetOriented.width) / originalFloat(orientedInfo.size.width));
    const scaleY: number = originalFloat(
      originalFloat(targetOriented.height) / originalFloat(orientedInfo.size.height));
    if (!Number.isFinite(scaleX) || !Number.isFinite(scaleY) ||
      scaleX <= 0 || scaleY <= 0) {
      throw new Error('original image normalization scale is invalid');
    }
    await pixelMap.scale(scaleX, scaleY);
    const decoded: image.ImageInfo = await pixelMap.getImageInfo();
    if (decoded.size.width !== targetOriented.width || decoded.size.height !== targetOriented.height) {
      throw new Error('original image normalization produced unexpected dimensions');
    }
    const packed: ArrayBuffer = await packWebpLossy(pixelMap);
    return {
      bytes: new Uint8Array(packed),
      mimeType: 'image/webp',
      rewroteBytes: true,
      // WebP packing stores the post-rotation physical axes and no longer
      // carries the source EXIF orientation.
      encodedWidth: targetOriented.width,
      encodedHeight: targetOriented.height,
      orientedWidth: targetOriented.width,
      orientedHeight: targetOriented.height,
    };
  } catch (error) {
    throw new Error(`normalizing original image failed: ${JSON.stringify(error)}`);
  } finally {
    if (pixelMap !== null) {
      try {
        await pixelMap.release();
      } catch (_releaseError) {
      }
    }
    if (source !== null) {
      try {
        await source.release();
      } catch (_releaseError) {
      }
    }
  }
}

async function createSource(bytes: Uint8Array): Promise<image.ImageSource> {
  const buffer: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset,
    bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
  return image.createImageSource(buffer);
}

function packWebpLossy(pixelMap: image.PixelMap): Promise<ArrayBuffer> {
  const packer: image.ImagePacker = image.createImagePacker();
  return packer.packing(pixelMap, {
    format: 'image/webp',
    quality: WEBP_LOSSY_QUALITY,
  }).finally(async (): Promise<void> => {
    await packer.release();
  });
}

async function readOrientation(source: image.ImageSource): Promise<string> {
  try {
    return await source.getImageProperty(image.PropertyKey.ORIENTATION, {
      index: 0, defaultValue: '1',
    });
  } catch (_error) {
    return '1';
  }
}

export function originalExifMirrorsHorizontally(orientation: string): boolean {
  const value: string = orientation.trim().toLowerCase();
  return value === '2' || value === '4' || value === '5' || value === '7';
}

export function originalRotationDegrees(orientation: string): number {
  const value: string = orientation.trim().toLowerCase();
  if (value === '3' || value === '4' || value === 'bottom-right' || value === 'bottom-left') {
    return 180;
  }
  if (value === '5' || value === '8' || value === 'left-top' || value === 'left-bottom') {
    return 270;
  }
  if (value === '6' || value === '7' || value === 'right-top' || value === 'right-bottom') {
    return 90;
  }
  return 0;
}

function validDimensions(width: number, height: number): boolean {
  return Number.isSafeInteger(width) && Number.isSafeInteger(height) &&
    width > 0 && height > 0 && width <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE * 8 &&
    height <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE * 8;
}

function sourceMime(value: string): string {
  const normalized: string = value.trim().toLowerCase();
  return normalized.length > 6 && normalized.startsWith('image/')
    ? normalized : 'image/*';
}

function originalFloat(value: number): number {
  return Math.fround(value);
}
