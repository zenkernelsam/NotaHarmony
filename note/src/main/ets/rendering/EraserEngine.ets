// T-014 橡皮擦引擎（任务卡 T-014，REVERSE_ANALYSIS §5b：PARTIAL 挖洞 + WHOLE 整条删除）
// 纯几何碰撞检测：禁止 import 平台 API
import { StrokeElementData, ERASER_PATH_BREAK_COORDINATE } from '../core/model/StrokeTypes';
import { Point2D, Rect2D } from '../core/model/GeometryTypes';

export enum EraserMode {
  PARTIAL = 0,  // 像素擦除（挖洞）
  WHOLE = 1,    // 整条删除
}

export interface EraseResult {
  mode: EraserMode;
  // PARTIAL: 受影响的笔画（maskPath 已更新）
  affectedStrokes: StrokeElementData[];
  // WHOLE: 应删除的笔画 ID
  deletedStrokeIds: string[];
}

export class EraserEngine {
  private mode: EraserMode;
  private eraserWidth: number;  // 擦除宽度（默认 20）

  constructor(mode: EraserMode, eraserWidth?: number) {
    this.mode = mode;
    this.eraserWidth = eraserWidth !== undefined ? eraserWidth : 20;
  }

  // 执行擦除（传入擦除路径点 + 当前所有笔画）
  erase(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    if (this.mode === EraserMode.WHOLE) {
      return this.eraseWhole(eraserPath, strokes);
    }
    return this.erasePartial(eraserPath, strokes);
  }

  // WHOLE: AABB 仅粗筛，最终以擦除线段到笔画中心线的距离判定。
  private eraseWhole(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    const deleted: string[] = [];
    if (eraserPath.length === 0) {
      return { mode: this.mode, affectedStrokes: [], deletedStrokeIds: deleted };
    }
    const radius: number = this.eraserWidth / 2;
    for (const stroke of strokes) {
      if (this.pathHitsStroke(eraserPath, stroke, radius)) {
        deleted.push(stroke.id);
      }
    }
    return { mode: this.mode, affectedStrokes: [], deletedStrokeIds: deleted };
  }

  // PARTIAL: 将擦除路径写入受影响笔画的 maskPath（渲染器用 destination-out 挖洞）
  private erasePartial(eraserPath: Point2D[], strokes: StrokeElementData[]): EraseResult {
    const affected: StrokeElementData[] = [];
    if (eraserPath.length === 0) {
      return { mode: this.mode, affectedStrokes: affected, deletedStrokeIds: [] };
    }
    const radius: number = this.eraserWidth / 2;
    for (const stroke of strokes) {
      if (this.pathHitsStroke(eraserPath, stroke, radius)) {
        const localPath: Point2D[] | null = this.toStrokeLocalPath(eraserPath, stroke.transform);
        if (localPath === null) {
          continue;
        }
        const maskPath: Point2D[] = stroke.maskPath.slice();
        if (maskPath.length > 0) {
          maskPath.push({
            x: ERASER_PATH_BREAK_COORDINATE,
            y: ERASER_PATH_BREAK_COORDINATE,
          });
        }
        for (const point of localPath) {
          maskPath.push(point);
        }
        const updated: StrokeElementData = {
          id: stroke.id,
          pathPoints: stroke.pathPoints,
          cubicSegments: stroke.cubicSegments,
          splatPoints: stroke.splatPoints,
          renderSpec: stroke.renderSpec,
          transform: stroke.transform,
          bounds: stroke.bounds,
          maskPath: maskPath,
          customPath: stroke.customPath,
          fillPath: stroke.fillPath,
          fillColor: stroke.fillColor,
          isFinished: stroke.isFinished,
        };
        affected.push(updated);
      }
    }
    return { mode: this.mode, affectedStrokes: affected, deletedStrokeIds: [] };
  }

  private pathHitsStroke(path: Point2D[], stroke: StrokeElementData, eraserRadius: number): boolean {
    if (path.length === 0 || stroke.pathPoints.length === 0) {
      return false;
    }
    const transformedStroke: Point2D[] = [];
    for (const point of stroke.pathPoints) {
      transformedStroke.push(this.transformPoint(point.position, stroke.transform));
    }
    // Frobenius norm is a conservative upper bound for the affine linear part's
    // maximum scale, including rotation, non-uniform scale and shear.
    const transformScale: number = Math.sqrt(
      stroke.transform[0] * stroke.transform[0] + stroke.transform[1] * stroke.transform[1] +
      stroke.transform[3] * stroke.transform[3] + stroke.transform[4] * stroke.transform[4]);
    const hitRadius: number = eraserRadius + stroke.renderSpec.brushWidth * transformScale / 2;
    const transformedBounds: Rect2D = this.pointsBounds(transformedStroke);
    const eraserSegmentCount: number = Math.max(1, path.length - 1);
    for (let i: number = 0; i < eraserSegmentCount; i++) {
      const ea: Point2D = path[i];
      const eb: Point2D = path.length === 1 ? path[0] : path[i + 1];
      if (!this.segmentBoundsOverlap(ea, eb, transformedBounds, hitRadius)) {
        continue;
      }
      if (transformedStroke.length === 1) {
        if (this.pointSegmentDistance(transformedStroke[0], ea, eb) <= hitRadius) {
          return true;
        }
        continue;
      }
      for (let j: number = 0; j < transformedStroke.length - 1; j++) {
        if (this.segmentDistance(ea, eb, transformedStroke[j], transformedStroke[j + 1]) <= hitRadius) {
          return true;
        }
      }
    }
    return false;
  }

  private pointsBounds(points: Point2D[]): Rect2D {
    let left: number = points[0].x;
    let right: number = points[0].x;
    let top: number = points[0].y;
    let bottom: number = points[0].y;
    for (let i: number = 1; i < points.length; i++) {
      left = Math.min(left, points[i].x);
      right = Math.max(right, points[i].x);
      top = Math.min(top, points[i].y);
      bottom = Math.max(bottom, points[i].y);
    }
    return { left: left, top: top, right: right, bottom: bottom };
  }

  private segmentBoundsOverlap(a: Point2D, b: Point2D, bounds: Rect2D, radius: number): boolean {
    const left: number = Math.min(a.x, b.x) - radius;
    const right: number = Math.max(a.x, b.x) + radius;
    const top: number = Math.min(a.y, b.y) - radius;
    const bottom: number = Math.max(a.y, b.y) + radius;
    return left <= bounds.right && right >= bounds.left && top <= bounds.bottom && bottom >= bounds.top;
  }

  private segmentDistance(a: Point2D, b: Point2D, c: Point2D, d: Point2D): number {
    if (this.segmentsIntersect(a, b, c, d)) {
      return 0;
    }
    return Math.min(
      Math.min(this.pointSegmentDistance(a, c, d), this.pointSegmentDistance(b, c, d)),
      Math.min(this.pointSegmentDistance(c, a, b), this.pointSegmentDistance(d, a, b)));
  }

  private segmentsIntersect(a: Point2D, b: Point2D, c: Point2D, d: Point2D): boolean {
    const abC: number = this.cross(a, b, c);
    const abD: number = this.cross(a, b, d);
    const cdA: number = this.cross(c, d, a);
    const cdB: number = this.cross(c, d, b);
    return abC * abD <= 0 && cdA * cdB <= 0 &&
      Math.max(Math.min(a.x, b.x), Math.min(c.x, d.x)) <= Math.min(Math.max(a.x, b.x), Math.max(c.x, d.x)) &&
      Math.max(Math.min(a.y, b.y), Math.min(c.y, d.y)) <= Math.min(Math.max(a.y, b.y), Math.max(c.y, d.y));
  }

  private cross(a: Point2D, b: Point2D, p: Point2D): number {
    return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
  }

  private pointSegmentDistance(point: Point2D, a: Point2D, b: Point2D): number {
    const dx: number = b.x - a.x;
    const dy: number = b.y - a.y;
    const lengthSquared: number = dx * dx + dy * dy;
    if (lengthSquared <= 0.0000001) {
      return Math.sqrt((point.x - a.x) * (point.x - a.x) + (point.y - a.y) * (point.y - a.y));
    }
    const rawT: number = ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared;
    const t: number = Math.max(0, Math.min(1, rawT));
    const px: number = a.x + t * dx;
    const py: number = a.y + t * dy;
    return Math.sqrt((point.x - px) * (point.x - px) + (point.y - py) * (point.y - py));
  }

  private transformPoint(point: Point2D, matrix: number[]): Point2D {
    return {
      x: matrix[0] * point.x + matrix[1] * point.y + matrix[2],
      y: matrix[3] * point.x + matrix[4] * point.y + matrix[5],
    };
  }

  private toStrokeLocalPath(path: Point2D[], matrix: number[]): Point2D[] | null {
    const determinant: number = matrix[0] * matrix[4] - matrix[1] * matrix[3];
    if (Math.abs(determinant) < 0.0000001) {
      return null;
    }
    const inverse: number[] = [
      matrix[4] / determinant, -matrix[1] / determinant, 0,
      -matrix[3] / determinant, matrix[0] / determinant, 0,
      0, 0, 1,
    ];
    inverse[2] = -(inverse[0] * matrix[2] + inverse[1] * matrix[5]);
    inverse[5] = -(inverse[3] * matrix[2] + inverse[4] * matrix[5]);
    const local: Point2D[] = [];
    for (const point of path) {
      local.push(this.transformPoint(point, inverse));
    }
    return local;
  }

  setMode(mode: EraserMode): void {
    this.mode = mode;
  }

  setWidth(width: number): void {
    this.eraserWidth = width;
  }

  getMode(): EraserMode {
    return this.mode;
  }

  getWidth(): number {
    return this.eraserWidth;
  }
}
