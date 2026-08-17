import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

const GEOMETRY_EPSILON: number = 0.0000001;

// Android 1.0.3 fu1.j()/g() maps a Block query through the inverse Block
// transform before testing the local [0,size] rectangle. Harmony Text can
// retain a non-zero local textOrigin, so callers pass the equivalent local
// rectangle explicitly.
export function pointHitsAffineBlock(point: Point2D, localBounds: Rect2D,
  transform: TransformMatrix): boolean {
  if (!validLocalBounds(localBounds)) {
    return false;
  }
  const local: Point2D | null = inverseAffinePoint(point, transform);
  return local !== null && pointInHalfOpenRect(local, localBounds);
}

export function selectionPathHitsAffineBlock(selectionPath: Point2D[], localBounds: Rect2D,
  transform: TransformMatrix): boolean {
  if (selectionPath.length < 3 || !validLocalBounds(localBounds)) {
    return false;
  }
  const localPath: Point2D[] | null = inverseAffinePath(selectionPath, transform);
  if (localPath === null) {
    return false;
  }
  for (const point of localPath) {
    if (pointInClosedRect(point, localBounds)) {
      return true;
    }
  }
  const corners: Point2D[] = rectCorners(localBounds);
  for (const corner of corners) {
    if (pointInPolygonOrBoundary(corner, localPath)) {
      return true;
    }
  }
  return closedPathIntersectsRect(localPath, localBounds);
}

export function eraserPathHitsAffineBlock(eraserPath: Point2D[], localBounds: Rect2D,
  transform: TransformMatrix, eraserWidth: number): boolean {
  if (eraserPath.length === 0 || !Number.isFinite(eraserWidth) ||
    !validLocalBounds(localBounds)) {
    return false;
  }
  const localPath: Point2D[] | null = inverseAffinePath(eraserPath, transform);
  const scale: number | null = maximumBlockScale(transform);
  if (localPath === null || scale === null) {
    return false;
  }
  // fu1.j() divides the point-query radius by max(scaleX, scaleY) after
  // inversion. Preserve that exact conservative Block contract instead of
  // measuring world-space distance to a transformed AABB/quad.
  const radius: number = Math.max(0, eraserWidth) / 2 / scale;
  const expanded: Rect2D = {
    left: localBounds.left - radius,
    top: localBounds.top - radius,
    right: localBounds.right + radius,
    bottom: localBounds.bottom + radius,
  };
  for (const point of localPath) {
    if (pointInClosedRect(point, expanded)) {
      return true;
    }
  }
  for (let index: number = 1; index < localPath.length; index++) {
    if (segmentIntersectsRect(localPath[index - 1], localPath[index], expanded)) {
      return true;
    }
  }
  return false;
}

function inverseAffinePath(path: Point2D[], transform: TransformMatrix): Point2D[] | null {
  const inverse: TransformMatrix | null = inverseAffineTransform(transform);
  if (inverse === null) {
    return null;
  }
  const result: Point2D[] = [];
  for (const point of path) {
    if (!finitePoint(point)) {
      return null;
    }
    const local: Point2D = transformPoint(point, inverse);
    if (!finitePoint(local)) {
      return null;
    }
    result.push(local);
  }
  return result;
}

function inverseAffinePoint(point: Point2D, transform: TransformMatrix): Point2D | null {
  if (!finitePoint(point)) {
    return null;
  }
  const inverse: TransformMatrix | null = inverseAffineTransform(transform);
  if (inverse === null) {
    return null;
  }
  const local: Point2D = transformPoint(point, inverse);
  return finitePoint(local) ? local : null;
}

function inverseAffineTransform(matrix: TransformMatrix): TransformMatrix | null {
  if (!validAffineTransform(matrix)) {
    return null;
  }
  const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  if (!Number.isFinite(determinant) || Math.abs(determinant) <= GEOMETRY_EPSILON) {
    return null;
  }
  const inverseDeterminant: number = 1 / determinant;
  const a: number = matrix[4] * inverseDeterminant;
  const b: number = -matrix[1] * inverseDeterminant;
  const d: number = -matrix[3] * inverseDeterminant;
  const e: number = matrix[0] * inverseDeterminant;
  return [
    a, b, -(a * matrix[2] + b * matrix[5]),
    d, e, -(d * matrix[2] + e * matrix[5]),
    0, 0, 1,
  ];
}

function maximumBlockScale(matrix: TransformMatrix): number | null {
  if (!validAffineTransform(matrix)) {
    return null;
  }
  const scaleX: number = Math.sqrt(matrix[0] * matrix[0] + matrix[3] * matrix[3]);
  const scaleY: number = Math.sqrt(matrix[1] * matrix[1] + matrix[4] * matrix[4]);
  const scale: number = Math.max(scaleX, scaleY);
  return Number.isFinite(scale) && scale > GEOMETRY_EPSILON ? scale : null;
}

function validAffineTransform(matrix: TransformMatrix): boolean {
  if (matrix.length !== 9) {
    return false;
  }
  for (const value of matrix) {
    if (!Number.isFinite(value)) {
      return false;
    }
  }
  return Math.abs(matrix[6]) <= GEOMETRY_EPSILON &&
    Math.abs(matrix[7]) <= GEOMETRY_EPSILON &&
    Math.abs(matrix[8] - 1) <= GEOMETRY_EPSILON;
}

function validLocalBounds(bounds: Rect2D): boolean {
  return Number.isFinite(bounds.left) && Number.isFinite(bounds.top) &&
    Number.isFinite(bounds.right) && Number.isFinite(bounds.bottom) &&
    bounds.right > bounds.left && bounds.bottom > bounds.top;
}

function finitePoint(point: Point2D): boolean {
  return Number.isFinite(point.x) && Number.isFinite(point.y);
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
}

function pointInHalfOpenRect(point: Point2D, rect: Rect2D): boolean {
  return point.x >= rect.left && point.x < rect.right &&
    point.y >= rect.top && point.y < rect.bottom;
}

function pointInClosedRect(point: Point2D, rect: Rect2D): boolean {
  return point.x >= rect.left - GEOMETRY_EPSILON &&
    point.x <= rect.right + GEOMETRY_EPSILON &&
    point.y >= rect.top - GEOMETRY_EPSILON &&
    point.y <= rect.bottom + GEOMETRY_EPSILON;
}

function rectCorners(rect: Rect2D): Point2D[] {
  return [
    { x: rect.left, y: rect.top },
    { x: rect.right, y: rect.top },
    { x: rect.right, y: rect.bottom },
    { x: rect.left, y: rect.bottom },
  ];
}

function closedPathIntersectsRect(path: Point2D[], rect: Rect2D): boolean {
  for (let index: number = 0; index < path.length; index++) {
    const next: number = (index + 1) % path.length;
    if (segmentIntersectsRect(path[index], path[next], rect)) {
      return true;
    }
  }
  return false;
}

function segmentIntersectsRect(start: Point2D, end: Point2D, rect: Rect2D): boolean {
  if (pointInClosedRect(start, rect) || pointInClosedRect(end, rect)) {
    return true;
  }
  const corners: Point2D[] = rectCorners(rect);
  for (let index: number = 0; index < corners.length; index++) {
    if (segmentsIntersect(start, end, corners[index], corners[(index + 1) % corners.length])) {
      return true;
    }
  }
  return false;
}

function pointInPolygonOrBoundary(point: Point2D, polygon: Point2D[]): boolean {
  let inside: boolean = false;
  for (let current: number = 0, previous: number = polygon.length - 1;
    current < polygon.length; previous = current++) {
    const a: Point2D = polygon[previous];
    const b: Point2D = polygon[current];
    if (Math.abs(orientation(a, b, point)) <= GEOMETRY_EPSILON &&
      pointOnSegment(point, a, b)) {
      return true;
    }
    if ((a.y > point.y) !== (b.y > point.y) &&
      point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) {
      inside = !inside;
    }
  }
  return inside;
}

function segmentsIntersect(a: Point2D, b: Point2D, c: Point2D, d: Point2D): boolean {
  const abC: number = orientation(a, b, c);
  const abD: number = orientation(a, b, d);
  const cdA: number = orientation(c, d, a);
  const cdB: number = orientation(c, d, b);
  if (((abC > GEOMETRY_EPSILON && abD < -GEOMETRY_EPSILON) ||
    (abC < -GEOMETRY_EPSILON && abD > GEOMETRY_EPSILON)) &&
    ((cdA > GEOMETRY_EPSILON && cdB < -GEOMETRY_EPSILON) ||
    (cdA < -GEOMETRY_EPSILON && cdB > GEOMETRY_EPSILON))) {
    return true;
  }
  return (Math.abs(abC) <= GEOMETRY_EPSILON && pointOnSegment(c, a, b)) ||
    (Math.abs(abD) <= GEOMETRY_EPSILON && pointOnSegment(d, a, b)) ||
    (Math.abs(cdA) <= GEOMETRY_EPSILON && pointOnSegment(a, c, d)) ||
    (Math.abs(cdB) <= GEOMETRY_EPSILON && pointOnSegment(b, c, d));
}

function pointOnSegment(point: Point2D, start: Point2D, end: Point2D): boolean {
  return point.x >= Math.min(start.x, end.x) - GEOMETRY_EPSILON &&
    point.x <= Math.max(start.x, end.x) + GEOMETRY_EPSILON &&
    point.y >= Math.min(start.y, end.y) - GEOMETRY_EPSILON &&
    point.y <= Math.max(start.y, end.y) + GEOMETRY_EPSILON;
}

function orientation(a: Point2D, b: Point2D, point: Point2D): number {
  return (b.x - a.x) * (point.y - a.y) - (b.y - a.y) * (point.x - a.x);
}
