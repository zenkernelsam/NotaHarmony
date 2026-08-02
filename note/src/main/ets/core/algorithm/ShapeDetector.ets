// T-023 形状识别（§24：直线/椭圆/多边形，笔画完成时触发，失败保留手画）
// 纯数学模块：禁止 import 平台 API
import { Point2D, Rect2D } from '../model/GeometryTypes';
import { NoteElement, EllipseElement, PolygonElement, ElementType } from '../model/ElementTypes';
import { RecognitionResult, RecognitionProvider } from '../adaptation/RecognitionProvider';

export interface ShapeDetectorConfig {
  lineThreshold: number;       // 直线判据：距离/跨度 > 0.6
  lineMinLength: number;       // 直线最小长度 60px
  ellipseMaxGap: number;       // 椭圆首尾最大距离 120px
  refitThreshold: number;      // 重拟合偏差 5px
  confidenceThreshold: number; // 最低置信度 0.5
}

// 检测结果（ArkTS 不允许对象字面量类型）
export interface DetectionResult {
  confidence: number;
  element: NoteElement;
}

export class ShapeDetector implements RecognitionProvider {
  private config: ShapeDetectorConfig;

  constructor(config?: Partial<ShapeDetectorConfig>) {
    const merged: ShapeDetectorConfig = {
      lineThreshold: 0.6,
      lineMinLength: 60,
      ellipseMaxGap: 120,
      refitThreshold: 5.0,
      confidenceThreshold: 0.5,
    };
    if (config !== undefined) {
      if (config.lineThreshold !== undefined) {
        merged.lineThreshold = config.lineThreshold;
      }
      if (config.lineMinLength !== undefined) {
        merged.lineMinLength = config.lineMinLength;
      }
      if (config.ellipseMaxGap !== undefined) {
        merged.ellipseMaxGap = config.ellipseMaxGap;
      }
      if (config.refitThreshold !== undefined) {
        merged.refitThreshold = config.refitThreshold;
      }
      if (config.confidenceThreshold !== undefined) {
        merged.confidenceThreshold = config.confidenceThreshold;
      }
    }
    this.config = merged;
  }

  isAvailable(): boolean {
    return true;
  }

  recognizeShape(points: Point2D[]): RecognitionResult | null {
    if (points.length < 3) {
      return null;
    }
    // 尝试三种检测，取最高分
    let best: DetectionResult | null = null;
    const line = this.detectLine(points);
    if (line !== null) {
      best = this.pickBetter(best, line);
    }
    const ellipse = this.detectEllipse(points);
    if (ellipse !== null) {
      best = this.pickBetter(best, ellipse);
    }
    const polygon = this.detectPolygon(points);
    if (polygon !== null) {
      best = this.pickBetter(best, polygon);
    }
    if (best === null || best.confidence < this.config.confidenceThreshold) {
      return null;
    }
    return { confidence: best.confidence, elements: [best.element] };
  }

  recognizeText(_points: Point2D[]): string | null {
    return null;  // MVP 不实现
  }

  // 取置信度更高的检测结果（显式判空避免控制流收窄限制）
  private pickBetter(current: DetectionResult | null, candidate: DetectionResult): DetectionResult {
    if (current === null) {
      return candidate;
    }
    if (candidate.confidence > current.confidence) {
      return candidate;
    }
    return current;
  }

  // 直线检测：首尾距离/路径跨度 > lineThreshold 且长度 > lineMinLength
  private detectLine(points: Point2D[]): DetectionResult | null {
    const first: Point2D = points[0];
    const last: Point2D = points[points.length - 1];
    const spanLen: number = this.distance(first, last);
    const pathLen: number = this.pathLength(points);
    if (pathLen < this.config.lineMinLength) {
      return null;
    }
    const ratio: number = spanLen / pathLen;
    if (ratio < this.config.lineThreshold) {
      return null;
    }
    // 拟合度：点到直线最大距离（相对 span 归一）
    const maxDist: number = this.maxDistToSegment(points, first, last);
    const fit: number = Math.max(0, 1 - maxDist / Math.max(spanLen, 1));
    let score: number = ratio * fit;
    // 直线评分提升：拟合度 > 0.5 且长度 > 60 → (1+score)*0.5
    if (fit > 0.5 && pathLen > 60) {
      score = (1 + score) * 0.5;
    }
    const element: PolygonElement = {
      id: this.generateId(),
      type: ElementType.POLYGON,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: this.computeBounds(points),
      vertices: [first, last],
      isClosed: false,
      color: -16777216,
      strokeWidth: 4,
    };
    return { confidence: score, element: element };
  }

  // 椭圆检测：首尾距 < ellipseMaxGap + 质心/标准差拟合
  private detectEllipse(points: Point2D[]): DetectionResult | null {
    const first: Point2D = points[0];
    const last: Point2D = points[points.length - 1];
    if (this.distance(first, last) > this.config.ellipseMaxGap) {
      return null;
    }
    // 质心
    let cx: number = 0;
    let cy: number = 0;
    for (const p of points) {
      cx += p.x;
      cy += p.y;
    }
    cx /= points.length;
    cy /= points.length;
    // 标准差 → rx/ry
    let vx: number = 0;
    let vy: number = 0;
    for (const p of points) {
      vx += (p.x - cx) * (p.x - cx);
      vy += (p.y - cy) * (p.y - cy);
    }
    const rx: number = Math.sqrt(vx / points.length);
    const ry: number = Math.sqrt(vy / points.length);
    if (rx < 5 || ry < 5) {
      return null;  // 太小不是椭圆
    }
    // 径向误差评分
    let errSum: number = 0;
    for (const p of points) {
      const dx: number = (p.x - cx) / Math.max(rx, 0.001);
      const dy: number = (p.y - cy) / Math.max(ry, 0.001);
      const r: number = Math.sqrt(dx * dx + dy * dy);
      errSum += Math.abs(r - 1);
    }
    const meanErr: number = errSum / points.length;
    const confidence: number = Math.max(0, 1 - meanErr / 0.8);
    const bounds = this.computeBounds(points);
    const element: EllipseElement = {
      id: this.generateId(),
      type: ElementType.ELLIPSE,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: bounds,
      center: { x: cx, y: cy },
      radiusX: rx,
      radiusY: ry,
      rotationRadians: 0,
      color: -16777216,
      strokeWidth: 4,
    };
    return { confidence: confidence, element: element };
  }

  // 多边形检测：Douglas-Peucker 简化 → 顶点 3~8
  private detectPolygon(points: Point2D[]): DetectionResult | null {
    const simplified: Point2D[] = this.douglasPeucker(points, this.config.refitThreshold);
    if (simplified.length < 3 || simplified.length > 8) {
      return null;
    }
    // 置信度：基于简化点数（顶点越多置信度略降）
    const confidence: number = Math.max(0.55, 1 - (simplified.length - 3) * 0.05);
    const element: PolygonElement = {
      id: this.generateId(),
      type: ElementType.POLYGON,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: this.computeBounds(points),
      vertices: simplified,
      isClosed: true,
      color: -16777216,
      strokeWidth: 4,
    };
    return { confidence: confidence, element: element };
  }

  // Douglas-Peucker 简化
  private douglasPeucker(points: Point2D[], epsilon: number): Point2D[] {
    if (points.length < 3) {
      return points;
    }
    const first: Point2D = points[0];
    const last: Point2D = points[points.length - 1];
    let maxDist: number = 0;
    let index: number = 0;
    for (let i = 1; i < points.length - 1; i++) {
      const d: number = this.distToSegment(points[i], first, last);
      if (d > maxDist) {
        maxDist = d;
        index = i;
      }
    }
    if (maxDist > epsilon) {
      const left: Point2D[] = this.douglasPeucker(points.slice(0, index + 1), epsilon);
      const right: Point2D[] = this.douglasPeucker(points.slice(index, points.length), epsilon);
      return left.slice(0, left.length - 1).concat(right);
    }
    return [first, last];
  }

  private distToSegment(p: Point2D, a: Point2D, b: Point2D): number {
    const abx: number = b.x - a.x;
    const aby: number = b.y - a.y;
    const len2: number = abx * abx + aby * aby;
    let t: number = 0;
    if (len2 > 0) {
      t = ((p.x - a.x) * abx + (p.y - a.y) * aby) / len2;
      if (t < 0) {
        t = 0;
      }
      if (t > 1) {
        t = 1;
      }
    }
    const px: number = a.x + abx * t;
    const py: number = a.y + aby * t;
    return this.distance(p, { x: px, y: py });
  }

  private maxDistToSegment(points: Point2D[], a: Point2D, b: Point2D): number {
    let max: number = 0;
    for (const p of points) {
      const d: number = this.distToSegment(p, a, b);
      if (d > max) {
        max = d;
      }
    }
    return max;
  }

  private pathLength(points: Point2D[]): number {
    let total: number = 0;
    for (let i = 1; i < points.length; i++) {
      total += this.distance(points[i - 1], points[i]);
    }
    return total;
  }

  private distance(a: Point2D, b: Point2D): number {
    const dx: number = a.x - b.x;
    const dy: number = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  private computeBounds(points: Point2D[]): Rect2D {
    let left: number = points[0].x;
    let top: number = points[0].y;
    let right: number = left;
    let bottom: number = top;
    for (const p of points) {
      if (p.x < left) {
        left = p.x;
      }
      if (p.x > right) {
        right = p.x;
      }
      if (p.y < top) {
        top = p.y;
      }
      if (p.y > bottom) {
        bottom = p.y;
      }
    }
    return { left: left, top: top, right: right, bottom: bottom };
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
