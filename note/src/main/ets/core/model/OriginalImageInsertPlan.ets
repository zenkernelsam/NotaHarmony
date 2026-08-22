// Pure IMAGE insertion geometry derived from original 1.0.3 bvh.a/bgj.b.
//
// The original keeps the decoded image size as CREATE_BLOCK.size and stores
// the fitted display size in the Block scale.  The requested point denotes the
// image centre before each axis is clamped into the resolved page.
import { ElementType, ImageElement } from './ElementTypes';
import { Point2D } from './GeometryTypes';
import {
  imageBlockWorldBounds, originalAssetHashKey, originalAssetStorageHash,
} from './ImageBlockGeometry';

export const ORIGINAL_IMAGE_INSERT_MAX_DISPLAY_SIDE: number = 320;
export const ORIGINAL_IMAGE_INSERT_PAGE_FRACTION: number = 0.8;
// Original vuh.b() rewrites larger images before bgj.b() receives them.
export const ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE: number = 3000;

export interface OriginalImagePixelDimensions {
  width: number;
  height: number;
}

export interface OriginalImageInsertAssetDraft {
  assetHashBits: string[];
  fileName: string;
  mimeType: string;
  fileSize: number;
  intrinsicWidth: number;
  intrinsicHeight: number;
}

export interface OriginalImageInsertGeometry {
  intrinsicWidth: number;
  intrinsicHeight: number;
  displayWidth: number;
  displayHeight: number;
  origin: Point2D;
  scaleX: number;
  scaleY: number;
}

export interface OriginalImageNormalizationPlan {
  sampleSize: number;
  width: number;
  height: number;
}

/**
 * Replays vuh.b() after the oriented dimensions have already crossed the
 * original 3000px boundary.  Java float arithmetic and the power-of-two
 * sampling loop use encoded axes exactly as the original does.
 */
export function planOriginalImageDownscale(encodedWidth: number,
  encodedHeight: number): OriginalImageNormalizationPlan | null {
  if (!Number.isSafeInteger(encodedWidth) || !Number.isSafeInteger(encodedHeight) ||
    encodedWidth <= 0 || encodedHeight <= 0) {
    return null;
  }
  if (encodedWidth <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE &&
    encodedHeight <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE) {
    return { sampleSize: 1, width: encodedWidth, height: encodedHeight };
  }
  const floatRatio: number = Math.fround(
    Math.fround(ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE) /
    Math.fround(Math.max(encodedWidth, encodedHeight)));
  const scaledWidth: number = Math.max(1, roundHalfUp(encodedWidth * floatRatio));
  const scaledHeight: number = Math.max(1, roundHalfUp(encodedHeight * floatRatio));
  let sampleSize: number = 1;
  while (Math.floor(encodedWidth / (sampleSize * 2)) >= scaledWidth &&
    Math.floor(encodedHeight / (sampleSize * 2)) >= scaledHeight) {
    sampleSize *= 2;
  }
  return {
    sampleSize: sampleSize,
    width: scaledWidth,
    height: scaledHeight,
  };
}

export function isOriginalNormalizedImageDimensions(width: number, height: number): boolean {
  return Number.isSafeInteger(width) && Number.isSafeInteger(height) &&
    width > 0 && height > 0 && width <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE &&
    height <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE;
}

/**
 * vuh.b()/w34.l() swap the dimensions for all EXIF orientations whose visual
 * transform rotates by 90 or 270 degrees. Unknown/missing metadata keeps the
 * encoded axis order, matching the original default rotation of zero.
 */
export function originalImageOrientedDimensions(width: number, height: number,
  orientation: string): OriginalImagePixelDimensions | null {
  if (!Number.isSafeInteger(width) || !Number.isSafeInteger(height) || width <= 0 || height <= 0) {
    return null;
  }
  const normalized: string = orientation.trim().toLowerCase();
  const swapsAxes: boolean = normalized === '5' || normalized === '6' ||
    normalized === '7' || normalized === '8' || normalized === 'left-top' ||
    normalized === 'right-top' || normalized === 'right-bottom' ||
    normalized === 'left-bottom';
  return swapsAxes ? { width: height, height: width } : { width: width, height: height };
}

export function originalImageDecodedDimensionsAreConsistent(encodedWidth: number,
  encodedHeight: number, orientation: string, decodedWidth: number,
  decodedHeight: number): boolean {
  if (!Number.isSafeInteger(decodedWidth) || !Number.isSafeInteger(decodedHeight) ||
    decodedWidth <= 0 || decodedHeight <= 0) {
    return false;
  }
  const oriented: OriginalImagePixelDimensions | null = originalImageOrientedDimensions(
    encodedWidth, encodedHeight, orientation);
  if (oriented === null) {
    return false;
  }
  return (decodedWidth === encodedWidth && decodedHeight === encodedHeight) ||
    (decodedWidth === oriented.width && decodedHeight === oriented.height);
}

/**
 * Mirrors bvh.a and bgj.b with Java-float arithmetic at every original float
 * boundary.  `anchor` is page-relative; page selection/document offsets stay
 * outside this pure helper.
 */
export function planOriginalImageInsertGeometry(intrinsicWidth: number,
  intrinsicHeight: number, pageWidth: number, pageHeight: number,
  zoom: number, anchor: Point2D): OriginalImageInsertGeometry | null {
  const imageWidth: number = originalFloat(intrinsicWidth);
  const imageHeight: number = originalFloat(intrinsicHeight);
  const targetPageWidth: number = originalFloat(pageWidth);
  const targetPageHeight: number = originalFloat(pageHeight);
  const viewportZoom: number = originalFloat(zoom);
  const anchorX: number = originalFloat(anchor.x);
  const anchorY: number = originalFloat(anchor.y);
  if (!validPositive(imageWidth) || !validPositive(imageHeight) ||
    !validPositive(targetPageWidth) || !validPositive(targetPageHeight) ||
    !validPositive(viewportZoom) || !Number.isFinite(anchorX) || !Number.isFinite(anchorY)) {
    return null;
  }

  const pageWidthLimit: number = originalFloat(
    targetPageWidth * originalFloat(ORIGINAL_IMAGE_INSERT_PAGE_FRACTION));
  const pageHeightLimit: number = originalFloat(
    targetPageHeight * originalFloat(ORIGINAL_IMAGE_INSERT_PAGE_FRACTION));
  const zoomLimit: number = originalFloat(
    originalFloat(ORIGINAL_IMAGE_INSERT_MAX_DISPLAY_SIDE) / viewportZoom);
  const widthScale: number = originalFloat(
    originalFloat(Math.min(pageWidthLimit, zoomLimit)) / imageWidth);
  const heightScale: number = originalFloat(
    originalFloat(Math.min(pageHeightLimit, zoomLimit)) / imageHeight);
  const fitScale: number = originalFloat(Math.min(originalFloat(1), widthScale, heightScale));
  if (!validPositive(fitScale)) {
    return null;
  }

  const displayWidth: number = originalFloat(imageWidth * fitScale);
  const displayHeight: number = originalFloat(imageHeight * fitScale);
  if (!validPositive(displayWidth) || !validPositive(displayHeight)) {
    return null;
  }
  const centeredX: number = originalFloat(
    anchorX - originalFloat(displayWidth / originalFloat(2)));
  const centeredY: number = originalFloat(
    anchorY - originalFloat(displayHeight / originalFloat(2)));
  const originX: number = fittedAxisOrigin(
    centeredX, displayWidth, targetPageWidth);
  const originY: number = fittedAxisOrigin(
    centeredY, displayHeight, targetPageHeight);
  const scaleX: number = originalFloat(displayWidth / imageWidth);
  const scaleY: number = originalFloat(displayHeight / imageHeight);
  if (!Number.isFinite(originX) || !Number.isFinite(originY) ||
    !validPositive(scaleX) || !validPositive(scaleY)) {
    return null;
  }
  return {
    intrinsicWidth: imageWidth,
    intrinsicHeight: imageHeight,
    displayWidth: displayWidth,
    displayHeight: displayHeight,
    origin: { x: originX, y: originY },
    scaleX: scaleX,
    scaleY: scaleY,
  };
}

export function createOriginalImageInsertDraft(asset: OriginalImageInsertAssetDraft,
  anchor: Point2D, pageWidth: number, pageHeight: number,
  zoom: number): ImageElement | null {
  if (asset === null || asset === undefined || asset.fileName.length === 0 ||
    !isImageMimeType(asset.mimeType) || !Number.isSafeInteger(asset.fileSize) ||
    asset.fileSize <= 0 || !isOriginalNormalizedImageDimensions(
      asset.intrinsicWidth, asset.intrinsicHeight)) {
    return null;
  }
  let assetHash: string;
  try {
    originalAssetStorageHash(asset.assetHashBits);
    assetHash = originalAssetHashKey(asset.assetHashBits);
  } catch (_error) {
    return null;
  }
  const geometry: OriginalImageInsertGeometry | null = planOriginalImageInsertGeometry(
    asset.intrinsicWidth, asset.intrinsicHeight, pageWidth, pageHeight, zoom, anchor);
  if (geometry === null) {
    return null;
  }
  const image: ImageElement = {
    id: '',
    type: ElementType.IMAGE,
    transform: [
      geometry.scaleX, 0, geometry.origin.x,
      0, geometry.scaleY, geometry.origin.y,
      0, 0, 1,
    ],
    bounds: { left: 0, top: 0, right: 0, bottom: 0 },
    assetHash: assetHash,
    assetHashBits: asset.assetHashBits.slice(),
    fileName: asset.fileName,
    mimeType: asset.mimeType,
    fileSize: asset.fileSize,
    intrinsicWidth: geometry.intrinsicWidth,
    intrinsicHeight: geometry.intrinsicHeight,
    cropRect: null,
    blockWidth: geometry.intrinsicWidth,
    blockHeight: geometry.intrinsicHeight,
    rotationRadians: 0,
    corner: 0,
    textWrap: 0,
    enableCaption: false,
    webUrl: null,
    imageFlippedHorizontally: false,
    imageFlippedVertically: false,
    positionLocked: false,
  };
  image.bounds = imageBlockWorldBounds(image);
  return image;
}

function fittedAxisOrigin(centeredOrigin: number, displaySize: number,
  pageSize: number): number {
  if (displaySize <= pageSize) {
    const maximum: number = originalFloat(pageSize - displaySize);
    return originalFloat(Math.max(originalFloat(0), Math.min(centeredOrigin, maximum)));
  }
  return originalFloat(originalFloat(pageSize - displaySize) / originalFloat(2));
}

function isImageMimeType(value: string): boolean {
  return value.length > 6 && value.toLowerCase().startsWith('image/');
}

function validPositive(value: number): boolean {
  return Number.isFinite(value) && value > 0;
}

function roundHalfUp(value: number): number {
  return Math.floor(value + 0.5);
}

function originalFloat(value: number): number {
  return Math.fround(value);
}
