import { MathElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

export function cloneMathElement(element: MathElement): MathElement {
  return {
    id: element.id,
    type: element.type,
    transform: element.transform.slice(),
    bounds: cloneRect(element.bounds),
    latex: element.latex,
    color: element.color,
    blockWidth: element.blockWidth,
    blockHeight: element.blockHeight,
    rotationRadians: element.rotationRadians,
    corner: element.corner,
    textWrap: element.textWrap,
    enableCaption: element.enableCaption,
    positionLocked: element.positionLocked,
  };
}

export function mathBlockWorldBounds(element: MathElement): Rect2D {
  const corners: Point2D[] = [
    transformPoint(0, 0, element),
    transformPoint(element.blockWidth, 0, element),
    transformPoint(element.blockWidth, element.blockHeight, element),
    transformPoint(0, element.blockHeight, element),
  ];
  let left: number = corners[0].x;
  let top: number = corners[0].y;
  let right: number = corners[0].x;
  let bottom: number = corners[0].y;
  for (let index: number = 1; index < corners.length; index++) {
    left = Math.min(left, corners[index].x);
    top = Math.min(top, corners[index].y);
    right = Math.max(right, corners[index].x);
    bottom = Math.max(bottom, corners[index].y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

export function isMathBlockPositionLocked(element: MathElement): boolean {
  return element.positionLocked === true;
}

export function transformMathElements(elements: MathElement[], selectedIds: string[],
  transform: TransformMatrix): MathElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: MathElement[] = [];
  for (const element of elements) {
    if (!selected.has(element.id) || isMathBlockPositionLocked(element)) {
      result.push(element);
      continue;
    }
    const updated: MathElement = cloneMathElement(element);
    updated.transform = multiplyTransform(transform, element.transform);
    updated.rotationRadians = Math.atan2(updated.transform[3], updated.transform[0]);
    updated.bounds = mathBlockWorldBounds(updated);
    result.push(updated);
  }
  return result;
}

export function eraserPathHitsMathBlock(eraserPath: Point2D[], element: MathElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0 || isMathBlockPositionLocked(element)) {
    return false;
  }
  const corners: Point2D[] = [
    transformPoint(0, 0, element),
    transformPoint(element.blockWidth, 0, element),
    transformPoint(element.blockWidth, element.blockHeight, element),
    transformPoint(0, element.blockHeight, element),
  ];
  const radius: number = Math.max(0, eraserWidth) / 2;
  const closed: Point2D[] = corners.concat([corners[0]]);
  for (const point of eraserPath) {
    if (pointInPolygon(point, corners)) {
      return true;
    }
  }
  const segmentCount: number = Math.max(1, eraserPath.length - 1);
  for (let index: number = 0; index < segmentCount; index++) {
    const start: Point2D = eraserPath[index];
    const end: Point2D = eraserPath.length === 1 ? start : eraserPath[index + 1];
    for (let edge: number = 0; edge < corners.length; edge++) {
      if (segmentDistance(start, end, closed[edge], closed[edge + 1]) <= radius) {
        return true;
      }
    }
  }
  return false;
}

function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
  return [
    a[0] * b[0] + a[1] * b[3], a[0] * b[1] + a[1] * b[4],
    a[0] * b[2] + a[1] * b[5] + a[2],
    a[3] * b[0] + a[4] * b[3], a[3] * b[1] + a[4] * b[4],
    a[3] * b[2] + a[4] * b[5] + a[5],
    0, 0, 1,
  ];
}

function pointInPolygon(point: Point2D, polygon: Point2D[]): boolean {
  let inside: boolean = false;
  for (let i: number = 0, j: number = polygon.length - 1; i < polygon.length; j = i++) {
    const left: Point2D = polygon[i];
    const right: Point2D = polygon[j];
    if ((left.y > point.y) !== (right.y > point.y) &&
      point.x < (right.x - left.x) * (point.y - left.y) / (right.y - left.y) + left.x) {
      inside = !inside;
    }
  }
  return inside;
}

function segmentDistance(a0: Point2D, a1: Point2D, b0: Point2D, b1: Point2D): number {
  if (segmentsIntersect(a0, a1, b0, b1)) {
    return 0;
  }
  return Math.min(pointSegmentDistance(a0, b0, b1), pointSegmentDistance(a1, b0, b1),
    pointSegmentDistance(b0, a0, a1), pointSegmentDistance(b1, a0, a1));
}

function segmentsIntersect(a0: Point2D, a1: Point2D, b0: Point2D, b1: Point2D): boolean {
  const epsilon: number = 0.0000001;
  const o1: number = orientation(a0, a1, b0);
  const o2: number = orientation(a0, a1, b1);
  const o3: number = orientation(b0, b1, a0);
  const o4: number = orientation(b0, b1, a1);
  if (((o1 > epsilon && o2 < -epsilon) || (o1 < -epsilon && o2 > epsilon)) &&
    ((o3 > epsilon && o4 < -epsilon) || (o3 < -epsilon && o4 > epsilon))) {
    return true;
  }
  return (Math.abs(o1) <= epsilon && pointOnSegment(b0, a0, a1, epsilon)) ||
    (Math.abs(o2) <= epsilon && pointOnSegment(b1, a0, a1, epsilon)) ||
    (Math.abs(o3) <= epsilon && pointOnSegment(a0, b0, b1, epsilon)) ||
    (Math.abs(o4) <= epsilon && pointOnSegment(a1, b0, b1, epsilon));
}

function pointOnSegment(point: Point2D, start: Point2D, end: Point2D, epsilon: number): boolean {
  return point.x >= Math.min(start.x, end.x) - epsilon &&
    point.x <= Math.max(start.x, end.x) + epsilon &&
    point.y >= Math.min(start.y, end.y) - epsilon &&
    point.y <= Math.max(start.y, end.y) + epsilon;
}

function orientation(a: Point2D, b: Point2D, c: Point2D): number {
  return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

function pointSegmentDistance(point: Point2D, start: Point2D, end: Point2D): number {
  const dx: number = end.x - start.x;
  const dy: number = end.y - start.y;
  const lengthSquared: number = dx * dx + dy * dy;
  if (lengthSquared <= 0.0000001) {
    return Math.hypot(point.x - start.x, point.y - start.y);
  }
  const ratio: number = Math.max(0, Math.min(1,
    ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared));
  return Math.hypot(point.x - (start.x + ratio * dx), point.y - (start.y + ratio * dy));
}

function transformPoint(x: number, y: number, element: MathElement): Point2D {
  return {
    x: element.transform[0] * x + element.transform[1] * y + element.transform[2],
    y: element.transform[3] * x + element.transform[4] * y + element.transform[5],
  };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
