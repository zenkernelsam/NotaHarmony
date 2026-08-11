import { ImageElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';
import { cloneImageElement, imageBlockWorldBounds } from './ImageBlockGeometry';

const CROP_EPSILON: number = 0.0001;

export interface OriginalImageCropSession {
  original: ImageElement;
  sourceCrop: Rect2D;
  draft: Rect2D;
  domain: Rect2D;
}

export function beginOriginalImageCrop(element: ImageElement): OriginalImageCropSession | null {
  if (element.positionLocked || !validPositive(element.intrinsicWidth) ||
    !validPositive(element.intrinsicHeight) || !validPositive(element.blockWidth) ||
    !validPositive(element.blockHeight) || !canonicalBlockTransform(element.transform)) {
    return null;
  }
  const source: Rect2D = element.cropRect === null ? {
    left: 0, top: 0, right: element.intrinsicWidth, bottom: element.intrinsicHeight,
  } : cloneCropRect(element.cropRect);
  if (!validCrop(source, element.intrinsicWidth, element.intrinsicHeight) ||
    !numbersNear(source.right - source.left, element.blockWidth) ||
    !numbersNear(source.bottom - source.top, element.blockHeight)) {
    return null;
  }
  return {
    original: cloneImageElement(element),
    sourceCrop: source,
    draft: { left: 0, top: 0, right: element.blockWidth, bottom: element.blockHeight },
    domain: {
      left: -source.left,
      top: -source.top,
      right: element.intrinsicWidth - source.left,
      bottom: element.intrinsicHeight - source.top,
    },
  };
}

export function resetOriginalImageCropDraft(session: OriginalImageCropSession): Rect2D {
  return cloneCropRect(session.domain);
}

export function applyOriginalImageCropDraft(session: OriginalImageCropSession,
  draft: Rect2D): ImageElement | null {
  if (!validDraft(draft, session.domain)) {
    return null;
  }
  const source: Rect2D = session.sourceCrop;
  const crop: Rect2D = {
    left: Math.fround(source.left + draft.left),
    top: Math.fround(source.top + draft.top),
    right: Math.fround(source.left + draft.right),
    bottom: Math.fround(source.top + draft.bottom),
  };
  if (!validCrop(crop, session.original.intrinsicWidth, session.original.intrinsicHeight)) {
    return null;
  }
  const result: ImageElement = cloneImageElement(session.original);
  const matrix: TransformMatrix = session.original.transform;
  result.transform = matrix.slice();
  result.transform[2] = Math.fround(matrix[0] * draft.left + matrix[1] * draft.top + matrix[2]);
  result.transform[5] = Math.fround(matrix[3] * draft.left + matrix[4] * draft.top + matrix[5]);
  result.blockWidth = Math.fround(draft.right - draft.left);
  result.blockHeight = Math.fround(draft.bottom - draft.top);
  result.cropRect = crop;
  result.bounds = imageBlockWorldBounds(result);
  return result;
}

export function imageCropDraftCanvasCorners(session: OriginalImageCropSession,
  draft: Rect2D): Point2D[] {
  const matrix: TransformMatrix = session.original.transform;
  return [
    transformPoint(draft.left, draft.top, matrix),
    transformPoint(draft.right, draft.top, matrix),
    transformPoint(draft.right, draft.bottom, matrix),
    transformPoint(draft.left, draft.bottom, matrix),
  ];
}

export function originalImageCropLocalDelta(element: ImageElement,
  canvasDeltaX: number, canvasDeltaY: number): Point2D | null {
  const matrix: TransformMatrix = element.transform;
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  if (!Number.isFinite(canvasDeltaX) || !Number.isFinite(canvasDeltaY) ||
    !Number.isFinite(determinant) || determinant <= CROP_EPSILON) {
    return null;
  }
  return {
    x: (matrix[4] * canvasDeltaX - matrix[1] * canvasDeltaY) / determinant,
    y: (-matrix[3] * canvasDeltaX + matrix[0] * canvasDeltaY) / determinant,
  };
}

function validDraft(draft: Rect2D, domain: Rect2D): boolean {
  return finiteRect(draft) && draft.right - draft.left > CROP_EPSILON &&
    draft.bottom - draft.top > CROP_EPSILON &&
    draft.left >= domain.left - CROP_EPSILON && draft.top >= domain.top - CROP_EPSILON &&
    draft.right <= domain.right + CROP_EPSILON && draft.bottom <= domain.bottom + CROP_EPSILON;
}

function validCrop(crop: Rect2D, intrinsicWidth: number, intrinsicHeight: number): boolean {
  return finiteRect(crop) && crop.left >= -CROP_EPSILON && crop.top >= -CROP_EPSILON &&
    crop.right <= intrinsicWidth + CROP_EPSILON && crop.bottom <= intrinsicHeight + CROP_EPSILON &&
    crop.right - crop.left > CROP_EPSILON && crop.bottom - crop.top > CROP_EPSILON;
}

function canonicalBlockTransform(matrix: TransformMatrix): boolean {
  if (matrix.length !== 9 || !matrix.every((value: number): boolean => Number.isFinite(value)) ||
    !numbersNear(matrix[6], 0) || !numbersNear(matrix[7], 0) || !numbersNear(matrix[8], 1)) {
    return false;
  }
  const scaleX: number = Math.hypot(matrix[0], matrix[3]);
  const scaleY: number = Math.hypot(matrix[1], matrix[4]);
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  return scaleX > CROP_EPSILON && scaleY > CROP_EPSILON && determinant > CROP_EPSILON &&
    Math.abs(matrix[0] * matrix[1] + matrix[3] * matrix[4]) <=
      CROP_EPSILON * Math.max(1, scaleX * scaleY);
}

function transformPoint(x: number, y: number, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * x + matrix[1] * y + matrix[2],
    y: matrix[3] * x + matrix[4] * y + matrix[5],
  };
}

function validPositive(value: number): boolean {
  return Number.isFinite(value) && value > CROP_EPSILON;
}

function finiteRect(rect: Rect2D): boolean {
  return Number.isFinite(rect.left) && Number.isFinite(rect.top) &&
    Number.isFinite(rect.right) && Number.isFinite(rect.bottom);
}

function numbersNear(left: number, right: number): boolean {
  return Math.abs(left - right) <= CROP_EPSILON * Math.max(1, Math.abs(left), Math.abs(right));
}

function cloneCropRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
