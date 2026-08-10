import { TextBlockElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

export interface TextBlockTransformComponents {
  origin: Point2D;
  rotationRadians: number;
  scaleX: number;
  scaleY: number;
}

export function cloneTextBlockElement(element: TextBlockElement): TextBlockElement {
  return {
    id: element.id, type: element.type, transform: element.transform.slice(),
    bounds: cloneRect(element.bounds), richText: element.richText,
    textOrigin: clonePoint(element.textOrigin), blockWidth: element.blockWidth,
    blockHeight: element.blockHeight, rotationRadians: element.rotationRadians,
    contentLeftInset: element.contentLeftInset, contentTopInset: element.contentTopInset,
    fontSize: element.fontSize, fontColor: element.fontColor,
    positionLocked: isTextBlockPositionLocked(element),
  };
}

export function isTextBlockPositionLocked(element: TextBlockElement): boolean {
  return element.positionLocked === true;
}

export function textBlockLocalBounds(element: TextBlockElement): Rect2D {
  return {
    left: element.textOrigin.x,
    top: element.textOrigin.y,
    right: element.textOrigin.x + element.blockWidth,
    bottom: element.textOrigin.y + element.blockHeight,
  };
}

export function textBlockWorldCorners(element: TextBlockElement): Point2D[] {
  const local: Rect2D = textBlockLocalBounds(element);
  return [
    transformPoint({ x: local.left, y: local.top }, element.transform),
    transformPoint({ x: local.right, y: local.top }, element.transform),
    transformPoint({ x: local.right, y: local.bottom }, element.transform),
    transformPoint({ x: local.left, y: local.bottom }, element.transform),
  ];
}

export function textBlockWorldBounds(element: TextBlockElement): Rect2D {
  return pointsBounds(textBlockWorldCorners(element));
}

export function textBlockTransformComponents(element: TextBlockElement): TextBlockTransformComponents {
  const matrix: TransformMatrix = element.transform;
  const scaleX: number = Math.sqrt(matrix[0] * matrix[0] + matrix[3] * matrix[3]);
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  const scaleY: number = scaleX > 0.0000001
    ? determinant / scaleX : Math.sqrt(matrix[1] * matrix[1] + matrix[4] * matrix[4]);
  return {
    origin: transformPoint(element.textOrigin, matrix),
    rotationRadians: scaleX > 0.0000001 ? Math.atan2(matrix[3], matrix[0]) : 0,
    scaleX: scaleX,
    scaleY: scaleY,
  };
}

export function transformTextBlockElements(elements: TextBlockElement[], selectedIds: string[],
  transform: TransformMatrix): TextBlockElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: TextBlockElement[] = [];
  for (const element of elements) {
    if (!selected.has(element.id)) {
      result.push(element);
      continue;
    }
    if (isTextBlockPositionLocked(element)) {
      result.push(element);
      continue;
    }
    const updated: TextBlockElement = cloneTextBlockElement(element);
    updated.transform = multiplyTransform(transform, element.transform);
    updated.rotationRadians = Math.atan2(updated.transform[3], updated.transform[0]);
    updated.bounds = textBlockWorldBounds(updated);
    result.push(updated);
  }
  return result;
}

export function pointHitsTextBlock(point: Point2D, element: TextBlockElement): boolean {
  return !isTextBlockPositionLocked(element) && pointInPolygon(point, textBlockWorldCorners(element));
}

export function eraserPathHitsTextBlock(eraserPath: Point2D[], element: TextBlockElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0 || isTextBlockPositionLocked(element)) {
    return false;
  }
  const corners: Point2D[] = textBlockWorldCorners(element);
  for (const point of eraserPath) {
    if (pointInPolygon(point, corners)) {
      return true;
    }
  }
  const closed: Point2D[] = corners.concat([corners[0]]);
  const radius: number = Math.max(0, eraserWidth) / 2;
  const eraserSegments: number = Math.max(1, eraserPath.length - 1);
  for (let i: number = 0; i < eraserSegments; i++) {
    const a: Point2D = eraserPath[i];
    const b: Point2D = eraserPath.length === 1 ? a : eraserPath[i + 1];
    for (let j: number = 0; j < corners.length; j++) {
      if (segmentDistance(a, b, closed[j], closed[j + 1]) <= radius) {
        return true;
      }
    }
  }
  return false;
}

function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
  const result: TransformMatrix = [0, 0, 0, 0, 0, 0, 0, 0, 1];
  for (let row: number = 0; row < 3; row++) {
    for (let col: number = 0; col < 3; col++) {
      let sum: number = 0;
      for (let k: number = 0; k < 3; k++) {
        sum += a[row * 3 + k] * b[k * 3 + col];
      }
      result[row * 3 + col] = sum;
    }
  }
  return result;
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function pointsBounds(points: Point2D[]): Rect2D {
  let left: number = points[0].x;
  let top: number = points[0].y;
  let right: number = points[0].x;
  let bottom: number = points[0].y;
  for (let i: number = 1; i < points.length; i++) {
    left = Math.min(left, points[i].x);
    top = Math.min(top, points[i].y);
    right = Math.max(right, points[i].x);
    bottom = Math.max(bottom, points[i].y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

function pointInPolygon(point: Point2D, polygon: Point2D[]): boolean {
  let inside: boolean = false;
  let previous: number = polygon.length - 1;
  for (let current: number = 0; current < polygon.length; current++) {
    const a: Point2D = polygon[current];
    const b: Point2D = polygon[previous];
    const crosses: boolean = (a.y > point.y) !== (b.y > point.y) &&
      point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
    if (crosses) {
      inside = !inside;
    }
    previous = current;
  }
  return inside;
}

function segmentDistance(a: Point2D, b: Point2D, c: Point2D, d: Point2D): number {
  if (segmentsIntersect(a, b, c, d)) {
    return 0;
  }
  return Math.min(
    Math.min(pointSegmentDistance(a, c, d), pointSegmentDistance(b, c, d)),
    Math.min(pointSegmentDistance(c, a, b), pointSegmentDistance(d, a, b)));
}

function segmentsIntersect(a: Point2D, b: Point2D, c: Point2D, d: Point2D): boolean {
  const abC: number = cross(a, b, c);
  const abD: number = cross(a, b, d);
  const cdA: number = cross(c, d, a);
  const cdB: number = cross(c, d, b);
  return abC * abD <= 0 && cdA * cdB <= 0 &&
    Math.max(Math.min(a.x, b.x), Math.min(c.x, d.x)) <= Math.min(Math.max(a.x, b.x), Math.max(c.x, d.x)) &&
    Math.max(Math.min(a.y, b.y), Math.min(c.y, d.y)) <= Math.min(Math.max(a.y, b.y), Math.max(c.y, d.y));
}

function pointSegmentDistance(point: Point2D, a: Point2D, b: Point2D): number {
  const dx: number = b.x - a.x;
  const dy: number = b.y - a.y;
  const lengthSquared: number = dx * dx + dy * dy;
  if (lengthSquared <= 0.0000001) {
    return Math.sqrt((point.x - a.x) * (point.x - a.x) + (point.y - a.y) * (point.y - a.y));
  }
  const raw: number = ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared;
  const t: number = Math.max(0, Math.min(1, raw));
  const x: number = a.x + t * dx;
  const y: number = a.y + t * dy;
  return Math.sqrt((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y));
}

function cross(a: Point2D, b: Point2D, point: Point2D): number {
  return (b.x - a.x) * (point.y - a.y) - (b.y - a.y) * (point.x - a.x);
}

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
