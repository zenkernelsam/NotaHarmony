import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeElement,
} from './ElementTypes';
import { Point2D } from './GeometryTypes';
import { cloneShapeElement, recomputeShapeBounds } from './ShapeGeometry';

export const ORIGINAL_SHAPE_HOLD_ADJUSTMENT_MIN_DISTANCE: number = 5;
const ORIGINAL_SHAPE_HOLD_DISTANCE_EPSILON: number = 0.001;

// Android 1.0.3 a5g keeps the snapped Shape active after detection. The first
// subsequent input point becomes a stable adjustment origin; every later point
// is evaluated against the recognized geometry rather than cumulatively.
export class ShapeHoldAdjustmentSession {
  private baseShapes: ShapeElement[] = [];
  private firstPoint: Point2D | null = null;
  private anchor: Point2D | null = null;
  private singleLine: boolean = false;

  begin(shapes: ShapeElement[]): boolean {
    this.reset();
    if (shapes.length === 0) {
      return false;
    }
    for (const shape of shapes) {
      if (!this.validShape(shape)) {
        return false;
      }
      this.baseShapes.push(cloneShapeElement(shape));
    }
    this.singleLine = this.baseShapes.length === 1 &&
      this.baseShapes[0].type === ElementType.LINE;
    this.anchor = this.singleLine ? null : this.aggregateAnchor(this.baseShapes);
    if (!this.singleLine && this.anchor === null) {
      this.reset();
      return false;
    }
    return true;
  }

  update(point: Point2D): ShapeElement[] | null {
    if (this.baseShapes.length === 0 || !this.finitePoint(point)) {
      return null;
    }
    let anchor: Point2D | null = this.anchor;
    if (!this.singleLine) {
      if (anchor === null || this.distance(anchor, point) <
        ORIGINAL_SHAPE_HOLD_ADJUSTMENT_MIN_DISTANCE) {
        return null;
      }
    }
    if (this.firstPoint === null) {
      this.firstPoint = this.clonePoint(point);
    }
    if (this.singleLine) {
      return [this.adjustLine(this.baseShapes[0] as LineElement, this.firstPoint, point)];
    }
    if (anchor === null) {
      return null;
    }
    const resolvedAnchor: Point2D = anchor;
    const initialDistance: number = this.distance(resolvedAnchor, this.firstPoint);
    const scale: number = initialDistance > ORIGINAL_SHAPE_HOLD_DISTANCE_EPSILON ?
      this.distance(resolvedAnchor, point) / initialDistance : 1;
    if (!Number.isFinite(scale) || scale < 0) {
      return null;
    }
    return this.baseShapes.map((shape: ShapeElement): ShapeElement =>
      this.scaleShape(shape, resolvedAnchor, scale));
  }

  isActive(): boolean {
    return this.baseShapes.length > 0;
  }

  reset(): void {
    this.baseShapes = [];
    this.firstPoint = null;
    this.anchor = null;
    this.singleLine = false;
  }

  private adjustLine(base: LineElement, first: Point2D, current: Point2D): LineElement {
    const result: LineElement = cloneShapeElement(base) as LineElement;
    result.end = {
      x: base.end.x + current.x - first.x,
      y: base.end.y + current.y - first.y,
    };
    result.controlPoint1 = this.adjustLineControl(
      base.start, base.end, result.end, base.controlPoint1);
    result.controlPoint2 = this.adjustLineControl(
      base.start, base.end, result.end, base.controlPoint2);
    result.bounds = recomputeShapeBounds(result);
    return result;
  }

  private adjustLineControl(start: Point2D, oldEnd: Point2D, newEnd: Point2D,
    control: Point2D | null): Point2D | null {
    if (control === null) {
      return null;
    }
    const oldX: number = oldEnd.x - start.x;
    const oldY: number = oldEnd.y - start.y;
    const oldLengthSquared: number = oldX * oldX + oldY * oldY;
    if (oldLengthSquared <= ORIGINAL_SHAPE_HOLD_DISTANCE_EPSILON) {
      return null;
    }
    const controlX: number = control.x - start.x;
    const controlY: number = control.y - start.y;
    const parallel: number = (controlX * oldX + controlY * oldY) / oldLengthSquared;
    const perpendicular: number = (controlY * oldX - controlX * oldY) / oldLengthSquared;
    const newX: number = newEnd.x - start.x;
    const newY: number = newEnd.y - start.y;
    return {
      x: start.x + parallel * newX - perpendicular * newY,
      y: start.y + perpendicular * newX + parallel * newY,
    };
  }

  private scaleShape(base: ShapeElement, anchor: Point2D, scale: number): ShapeElement {
    const result: ShapeElement = cloneShapeElement(base);
    if (result.type === ElementType.ELLIPSE) {
      const ellipse: EllipseElement = result as EllipseElement;
      ellipse.center = this.scalePoint(ellipse.center, anchor, scale);
      ellipse.radiusX *= scale;
      ellipse.radiusY *= scale;
    } else if (result.type === ElementType.POLYGON) {
      const polygon: PolygonElement = result as PolygonElement;
      polygon.vertices = polygon.vertices.map((point: Point2D): Point2D =>
        this.scalePoint(point, anchor, scale));
    } else {
      const line: LineElement = result as LineElement;
      line.start = this.scalePoint(line.start, anchor, scale);
      line.end = this.scalePoint(line.end, anchor, scale);
      line.controlPoint1 = line.controlPoint1 === null ? null :
        this.scalePoint(line.controlPoint1, anchor, scale);
      line.controlPoint2 = line.controlPoint2 === null ? null :
        this.scalePoint(line.controlPoint2, anchor, scale);
    }
    result.bounds = recomputeShapeBounds(result);
    return result;
  }

  private aggregateAnchor(shapes: ShapeElement[]): Point2D | null {
    let totalX: number = 0;
    let totalY: number = 0;
    let count: number = 0;
    for (const shape of shapes) {
      if (shape.type === ElementType.ELLIPSE) {
        totalX += shape.center.x;
        totalY += shape.center.y;
        count++;
      } else if (shape.type === ElementType.POLYGON) {
        for (const vertex of shape.vertices) {
          totalX += vertex.x;
          totalY += vertex.y;
          count++;
        }
      } else {
        totalX += shape.start.x + shape.end.x;
        totalY += shape.start.y + shape.end.y;
        count += 2;
      }
    }
    return count === 0 ? null : { x: totalX / count, y: totalY / count };
  }

  private validShape(shape: ShapeElement): boolean {
    if (!Number.isFinite(shape.strokeWidth) || shape.strokeWidth < 0 ||
      shape.transform.length !== 9) {
      return false;
    }
    for (const value of shape.transform) {
      if (!Number.isFinite(value)) {
        return false;
      }
    }
    if (shape.type === ElementType.ELLIPSE) {
      return this.finitePoint(shape.center) && Number.isFinite(shape.radiusX) &&
        Number.isFinite(shape.radiusY) && shape.radiusX > 0 && shape.radiusY > 0 &&
        Number.isFinite(shape.rotationRadians);
    }
    if (shape.type === ElementType.POLYGON) {
      if (shape.vertices.length < 3) {
        return false;
      }
      for (const vertex of shape.vertices) {
        if (!this.finitePoint(vertex)) {
          return false;
        }
      }
      return true;
    }
    return this.finitePoint(shape.start) && this.finitePoint(shape.end) &&
      this.finiteNullablePoint(shape.controlPoint1) &&
      this.finiteNullablePoint(shape.controlPoint2);
  }

  private finiteNullablePoint(point: Point2D | null): boolean {
    return point === null || this.finitePoint(point);
  }

  private finitePoint(point: Point2D): boolean {
    return Number.isFinite(point.x) && Number.isFinite(point.y);
  }

  private scalePoint(point: Point2D, anchor: Point2D, scale: number): Point2D {
    return {
      x: anchor.x + (point.x - anchor.x) * scale,
      y: anchor.y + (point.y - anchor.y) * scale,
    };
  }

  private distance(a: Point2D, b: Point2D): number {
    const dx: number = a.x - b.x;
    const dy: number = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  private clonePoint(point: Point2D): Point2D {
    return { x: point.x, y: point.y };
  }
}
