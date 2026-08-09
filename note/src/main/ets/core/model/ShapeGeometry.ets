import { ElementType, EllipseElement, PolygonElement, ShapeElement } from './ElementTypes';
import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes';

const ELLIPSE_HIT_SEGMENTS: number = 64;

export function cloneShapeElement(shape: ShapeElement): ShapeElement {
  if (shape.type === ElementType.ELLIPSE) {
    return {
      id: shape.id, type: ElementType.ELLIPSE, transform: shape.transform.slice(),
      bounds: cloneRect(shape.bounds), center: clonePoint(shape.center),
      radiusX: shape.radiusX, radiusY: shape.radiusY, rotationRadians: shape.rotationRadians,
      color: shape.color, strokeWidth: shape.strokeWidth, fillColor: shape.fillColor,
    };
  }
  return {
    id: shape.id, type: ElementType.POLYGON, transform: shape.transform.slice(),
    bounds: cloneRect(shape.bounds),
    vertices: shape.vertices.map((point: Point2D): Point2D => clonePoint(point)),
    isClosed: shape.isClosed, color: shape.color, strokeWidth: shape.strokeWidth,
    fillColor: shape.fillColor,
  };
}

export function transformShapeElements(shapes: ShapeElement[], selectedIds: string[],
  transform: TransformMatrix): ShapeElement[] {
  const selected: Set<string> = new Set<string>(selectedIds);
  const result: ShapeElement[] = [];
  for (const shape of shapes) {
    if (!selected.has(shape.id)) {
      result.push(shape);
      continue;
    }
    const updated: ShapeElement = cloneShapeElement(shape);
    updated.transform = multiplyTransform(transform, shape.transform);
    updated.bounds = pointsBounds(shapePathPoints(updated));
    result.push(updated);
  }
  return result;
}

export function shapePathPoints(shape: ShapeElement): Point2D[] {
  const local: Point2D[] = shape.type === ElementType.ELLIPSE
    ? ellipsePoints(shape) : polygonPoints(shape);
  const transformed: Point2D[] = [];
  for (const point of local) {
    transformed.push(transformPoint(point, shape.transform));
  }
  return transformed;
}

export function eraserPathHitsShape(eraserPath: Point2D[], shape: ShapeElement,
  eraserWidth: number): boolean {
  if (eraserPath.length === 0) {
    return false;
  }
  const shapePath: Point2D[] = shapePathPoints(shape);
  if (shapePath.length === 0) {
    return false;
  }
  if (shape.fillColor !== null && shapePath.length >= 3) {
    for (const eraserPoint of eraserPath) {
      if (pointInPolygon(eraserPoint, shapePath)) {
        return true;
      }
    }
  }
  const scale: number = maximumLinearScale(shape.transform);
  const radius: number = eraserWidth / 2 + shape.strokeWidth * scale / 2;
  const eraserSegments: number = Math.max(1, eraserPath.length - 1);
  const shapeSegments: number = Math.max(1, shapePath.length - 1);
  for (let i: number = 0; i < eraserSegments; i++) {
    const a: Point2D = eraserPath[i];
    const b: Point2D = eraserPath.length === 1 ? a : eraserPath[i + 1];
    for (let j: number = 0; j < shapeSegments; j++) {
      const c: Point2D = shapePath[j];
      const d: Point2D = shapePath.length === 1 ? c : shapePath[j + 1];
      if (segmentDistance(a, b, c, d) <= radius) {
        return true;
      }
    }
  }
  return false;
}

function maximumLinearScale(matrix: TransformMatrix): number {
  const a: number = matrix[0];
  const b: number = matrix[1];
  const c: number = matrix[3];
  const d: number = matrix[4];
  const trace: number = a * a + b * b + c * c + d * d;
  const determinant: number = a * d - b * c;
  const discriminant: number = Math.max(0, trace * trace - 4 * determinant * determinant);
  return Math.sqrt(Math.max(0, (trace + Math.sqrt(discriminant)) / 2));
}

export function multiplyTransform(a: TransformMatrix, b: TransformMatrix): TransformMatrix {
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

export function transformBounds(bounds: Rect2D, transform: TransformMatrix): Rect2D {
  const corners: Point2D[] = [
    { x: bounds.left, y: bounds.top }, { x: bounds.right, y: bounds.top },
    { x: bounds.right, y: bounds.bottom }, { x: bounds.left, y: bounds.bottom },
  ];
  let left: number = Number.MAX_VALUE;
  let top: number = Number.MAX_VALUE;
  let right: number = -Number.MAX_VALUE;
  let bottom: number = -Number.MAX_VALUE;
  for (const corner of corners) {
    const point: Point2D = transformPoint(corner, transform);
    left = Math.min(left, point.x);
    top = Math.min(top, point.y);
    right = Math.max(right, point.x);
    bottom = Math.max(bottom, point.y);
  }
  return { left: left, top: top, right: right, bottom: bottom };
}

function pointsBounds(points: Point2D[]): Rect2D {
  if (points.length === 0) {
    return { left: 0, top: 0, right: 0, bottom: 0 };
  }
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

function ellipsePoints(shape: EllipseElement): Point2D[] {
  const result: Point2D[] = [];
  const cosRotation: number = Math.cos(shape.rotationRadians);
  const sinRotation: number = Math.sin(shape.rotationRadians);
  for (let i: number = 0; i <= ELLIPSE_HIT_SEGMENTS; i++) {
    const angle: number = i / ELLIPSE_HIT_SEGMENTS * Math.PI * 2;
    const x: number = Math.cos(angle) * shape.radiusX;
    const y: number = Math.sin(angle) * shape.radiusY;
    result.push({
      x: shape.center.x + x * cosRotation - y * sinRotation,
      y: shape.center.y + x * sinRotation + y * cosRotation,
    });
  }
  return result;
}

function polygonPoints(shape: PolygonElement): Point2D[] {
  const result: Point2D[] = shape.vertices.map((point: Point2D): Point2D => clonePoint(point));
  if (shape.isClosed && result.length > 0) {
    result.push(clonePoint(result[0]));
  }
  return result;
}

function transformPoint(point: Point2D, matrix: TransformMatrix): Point2D {
  return {
    x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
    y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
  };
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

function clonePoint(point: Point2D): Point2D {
  return { x: point.x, y: point.y };
}

function cloneRect(rect: Rect2D): Rect2D {
  return { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom };
}
