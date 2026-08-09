// T-010 可变宽度轮廓算法（任务卡 T-010，REVERSE_ANALYSIS §23/§35：w4a.b() 等价）
// 中心线 → 填充轮廓：法向量 + 上下轮廓 + 半圆帽 + 尖角过渡
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D } from '../model/GeometryTypes';
import { StrokePathPoint } from '../model/StrokeTypes';

export interface OutlineResult {
  // 封闭轮廓点序列（可直接用 Canvas path moveTo/lineTo/closePath 绘制）
  outlinePoints: Point2D[];
  // 是否为有效轮廓（点数 >= 3）
  isValid: boolean;
}

export class WidthOutlineBuilder {
  // Port assumption; the original bezierkit path has no matching dot threshold.
  private static readonly CORNER_THRESHOLD: number = 0.5;
  // Port assumption used only to reject numerically degenerate line segments.
  private static readonly MIN_SEGMENT_LENGTH: number = 0.01;
  // Port assumption pending the adaptive round-join replacement; scale by local width.
  private static readonly CORNER_EXPANSION_RATIO: number = 0.1;
  private static readonly CIRCLE_SEGMENTS: number = 16;

  // 主入口：从中心线 + 逐点宽度生成填充轮廓
  build(centerline: StrokePathPoint[], baseWidth: number): OutlineResult {
    if (centerline.length === 0 || baseWidth <= 0) {
      return { outlinePoints: [], isValid: false };
    }
    if (this.firstUsableTangent(centerline) === null) {
      return this.buildDegenerateCircle(centerline, baseWidth);
    }
    const normals: Point2D[] = this.computeNormals(centerline);
    const upper: Point2D[] = this.offsetCurve(centerline, normals, baseWidth, 1);
    const lower: Point2D[] = this.offsetCurve(centerline, normals, baseWidth, -1);
    // 尖角过渡：在法向量突变处插入过渡点，避免轮廓自交
    this.handleSharpCorners(upper, lower, normals);

    const lastIdx: number = centerline.length - 1;
    const startCap: Point2D[] = this.buildRoundCap(centerline[0].position, normals[0],
      centerline[0].widthFactor * baseWidth / 2, false);
    const endCap: Point2D[] = this.buildRoundCap(centerline[lastIdx].position, normals[lastIdx],
      centerline[lastIdx].widthFactor * baseWidth / 2, true);

    // 组装：起点帽（lower[0]→upper[0]）+ 上轮廓正序 + 终点帽（upper[n-1]→lower[n-1]）+ 下轮廓逆序
    const outline: Point2D[] = [];
    for (const p of startCap) {
      outline.push(p);
    }
    for (const p of upper) {
      outline.push(p);
    }
    for (const p of endCap) {
      outline.push(p);
    }
    for (let i = lower.length - 1; i >= 0; i--) {
      outline.push(lower[i]);
    }
    return { outlinePoints: outline, isValid: outline.length >= 3 };
  }

  // 计算每个点的法向量（垂直于切线方向）
  private computeNormals(points: StrokePathPoint[]): Point2D[] {
    const n: number = points.length;
    const normals: Point2D[] = [];
    for (let i = 0; i < n; i++) {
      let tangent: Point2D;
      if (i === 0) {
        tangent = this.diff(points[1].position, points[0].position);
      } else if (i === n - 1) {
        tangent = this.diff(points[n - 1].position, points[n - 2].position);
      } else {
        tangent = this.diff(points[i + 1].position, points[i - 1].position);
      }
      const len: number = Math.sqrt(tangent.x * tangent.x + tangent.y * tangent.y);
      if (len < WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
        const recovered: Point2D | null = this.tangentNear(points, i);
        if (recovered !== null) {
          const recoveredLength: number = Math.sqrt(
            recovered.x * recovered.x + recovered.y * recovered.y);
          normals.push({ x: -recovered.y / recoveredLength, y: recovered.x / recoveredLength });
          continue;
        }
        // The all-degenerate path is handled by buildDegenerateCircle().
        if (normals.length > 0) {
          normals.push({ x: normals[normals.length - 1].x, y: normals[normals.length - 1].y });
        } else {
          normals.push({ x: 0, y: 1 });
        }
        continue;
      }
      const tx: number = tangent.x / len;
      const ty: number = tangent.y / len;
      // 法向量 = (-tangent.y, tangent.x)
      normals.push({ x: -ty, y: tx });
    }
    return normals;
  }

  // 生成上（sign=+1）/下（sign=-1）轮廓线
  private offsetCurve(points: StrokePathPoint[], normals: Point2D[], baseWidth: number,
    sign: number): Point2D[] {
    const result: Point2D[] = [];
    for (let i = 0; i < points.length; i++) {
      const halfWidth: number = points[i].widthFactor * baseWidth / 2;
      result.push({
        x: points[i].position.x + normals[i].x * halfWidth * sign,
        y: points[i].position.y + normals[i].y * halfWidth * sign,
      });
    }
    return result;
  }

  // 端点半圆帽：isEnd=false 时从 -normal 扫到 +normal；isEnd=true 时反向
  private buildRoundCap(center: Point2D, normal: Point2D, halfWidth: number, isEnd: boolean): Point2D[] {
    const pts: Point2D[] = [];
    const segments: number = 5;  // 4-6 点半圆弧
    const baseAngle: number = Math.atan2(normal.y, normal.x);
    const startAngle: number = isEnd ? baseAngle : baseAngle + Math.PI;
    for (let i = 0; i <= segments; i++) {
      const a: number = startAngle - (Math.PI * i) / segments;
      pts.push({
        x: center.x + Math.cos(a) * halfWidth,
        y: center.y + Math.sin(a) * halfWidth,
      });
    }
    return pts;
  }

  // 尖角处理：相邻法向量夹角 > 60°（dot < 0.5）时插入过渡点
  private handleSharpCorners(upper: Point2D[], lower: Point2D[], normals: Point2D[]): void {
    let i: number = 0;
    while (i < normals.length - 1) {
      const dot: number = normals[i].x * normals[i + 1].x + normals[i].y * normals[i + 1].y;
      if (dot < WidthOutlineBuilder.CORNER_THRESHOLD) {
        // 平均法向量（归一化）作为过渡方向
        let nx: number = (normals[i].x + normals[i + 1].x) / 2;
        let ny: number = (normals[i].y + normals[i + 1].y) / 2;
        const len: number = Math.sqrt(nx * nx + ny * ny);
        if (len > 1e-6) {
          nx /= len;
          ny /= len;
        } else {
          nx = normals[i].x;
          ny = normals[i].y;
        }
        const currentHalfWidth: number = this.distance(upper[i], lower[i]) / 2;
        const nextHalfWidth: number = this.distance(upper[i + 1], lower[i + 1]) / 2;
        const expansion: number = (currentHalfWidth + nextHalfWidth) / 2 *
          WidthOutlineBuilder.CORNER_EXPANSION_RATIO;
        // 过渡点取相邻轮廓点中点（沿过渡法向略微外扩防止自交）
        const midUpper: Point2D = {
          x: (upper[i].x + upper[i + 1].x) / 2 + nx * expansion,
          y: (upper[i].y + upper[i + 1].y) / 2 + ny * expansion,
        };
        const midLower: Point2D = {
          x: (lower[i].x + lower[i + 1].x) / 2 - nx * expansion,
          y: (lower[i].y + lower[i + 1].y) / 2 - ny * expansion,
        };
        upper.splice(i + 1, 0, midUpper);
        lower.splice(i + 1, 0, midLower);
        normals.splice(i + 1, 0, { x: nx, y: ny });
        i += 2;  // 跳过新插入点
      } else {
        i++;
      }
    }
  }

  private diff(a: Point2D, b: Point2D): Point2D {
    return { x: a.x - b.x, y: a.y - b.y };
  }

  private firstUsableTangent(points: StrokePathPoint[]): Point2D | null {
    const origin: Point2D = points[0].position;
    for (let i: number = 1; i < points.length; i++) {
      const tangent: Point2D = this.diff(points[i].position, origin);
      if (this.length(tangent) >= WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
        return tangent;
      }
    }
    return null;
  }

  private tangentNear(points: StrokePathPoint[], index: number): Point2D | null {
    const center: Point2D = points[index].position;
    for (let i: number = index + 1; i < points.length; i++) {
      const forward: Point2D = this.diff(points[i].position, center);
      if (this.length(forward) >= WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
        return forward;
      }
    }
    for (let i: number = index - 1; i >= 0; i--) {
      const backward: Point2D = this.diff(center, points[i].position);
      if (this.length(backward) >= WidthOutlineBuilder.MIN_SEGMENT_LENGTH) {
        return backward;
      }
    }
    return null;
  }

  private buildDegenerateCircle(points: StrokePathPoint[], baseWidth: number): OutlineResult {
    let maxWidthFactor: number = points[0].widthFactor;
    for (let i: number = 1; i < points.length; i++) {
      maxWidthFactor = Math.max(maxWidthFactor, points[i].widthFactor);
    }
    const center: Point2D = points[0].position;
    const radius: number = maxWidthFactor * baseWidth / 2;
    const outline: Point2D[] = [];
    for (let i: number = 0; i < WidthOutlineBuilder.CIRCLE_SEGMENTS; i++) {
      const angle: number = Math.PI * 2 * i / WidthOutlineBuilder.CIRCLE_SEGMENTS;
      outline.push({
        x: center.x + Math.cos(angle) * radius,
        y: center.y + Math.sin(angle) * radius,
      });
    }
    return { outlinePoints: outline, isValid: radius > 0 && outline.length >= 3 };
  }

  private length(point: Point2D): number {
    return Math.sqrt(point.x * point.x + point.y * point.y);
  }

  private distance(first: Point2D, second: Point2D): number {
    return this.length(this.diff(first, second));
  }
}
