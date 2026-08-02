// T-009 三次贝塞尔拟合器（任务卡 T-009，REVERSE_ANALYSIS §17：sqh.g/h/f）
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D, CubicSegment } from '../model/GeometryTypes';
import { StrokePathPoint } from '../model/StrokeTypes';

export interface FitterConfig {
  maxPointsPerSegment: number;  // 默认 200（单次拟合最大点数）
  contextExpansion: number;     // 默认 5（前后各扩 5 点上下文）
  baseTolerance: number;        // 默认 0.5（会被动态容差覆盖）
}

export class CubicFitter {
  private config: FitterConfig;

  constructor(config?: Partial<FitterConfig>) {
    const merged: FitterConfig = {
      maxPointsPerSegment: 200,
      contextExpansion: 5,
      baseTolerance: 0.5,
    };
    if (config !== undefined) {
      if (config.maxPointsPerSegment !== undefined) {
        merged.maxPointsPerSegment = config.maxPointsPerSegment;
      }
      if (config.contextExpansion !== undefined) {
        merged.contextExpansion = config.contextExpansion;
      }
      if (config.baseTolerance !== undefined) {
        merged.baseTolerance = config.baseTolerance;
      }
    }
    this.config = merged;
  }

  // 主入口：将中心线点序列拟合为三次贝塞尔段数组
  fit(points: StrokePathPoint[], baseWidth: number, zoom: number): CubicSegment[] {
    if (points.length < 2) {
      return [];
    }
    const pts: Point2D[] = [];
    for (const p of points) {
      pts.push(p.position);
    }
    const tolerance: number = this.computeTolerance(baseWidth, zoom);
    const result: CubicSegment[] = [];
    this.fitRecursive(pts, 0, pts.length - 1, tolerance, result);
    return result;
  }

  // 动态容差（§17 公式；dd4.d() 用 Math.log 近似，待逆向确认后可能调整）
  private computeTolerance(baseWidth: number, zoom: number): number {
    const scale: number = Math.max(zoom, 0.01);
    const width: number = Math.max(baseWidth * scale, 1.0);
    return (0.5 / ((((Math.log(width) - 2.6) / 15.4) * 1.5) + 1.0)) / scale;
  }

  // 最小二乘求控制点（sqh.g）：三次 Bernstein 基 + 2×2 正规方程
  private fitCubic(points: Point2D[], segStart: number, segEnd: number): CubicSegment {
    const p0: Point2D = points[segStart];
    const p3: Point2D = points[segEnd];
    // 上下文扩展：拟合使用扩展区间点，但段端点仍为目标区间端点
    const ctx: number = this.config.contextExpansion;
    const fitStart: number = Math.max(0, segStart - ctx);
    const fitEnd: number = Math.min(points.length - 1, segEnd + ctx);
    const count: number = segEnd - segStart;

    let s11: number = 0;
    let s12: number = 0;
    let s22: number = 0;
    let bx: number = 0;
    let by: number = 0;
    let cx: number = 0;
    let cy: number = 0;

    for (let i = fitStart; i <= fitEnd; i++) {
      const t: number = (i - segStart) / count;
      const mt: number = 1 - t;
      const w1: number = 3 * mt * mt * t;
      const w2: number = 3 * mt * t * t;
      if (w1 === 0 && w2 === 0) {
        continue;
      }
      // delta = 目标点 - 端点基函数贡献
      const b0: number = mt * mt * mt;
      const b3: number = t * t * t;
      const dx: number = points[i].x - (b0 * p0.x + b3 * p3.x);
      const dy: number = points[i].y - (b0 * p0.y + b3 * p3.y);
      s11 += w1 * w1;
      s12 += w1 * w2;
      s22 += w2 * w2;
      bx += w1 * dx;
      by += w1 * dy;
      cx += w2 * dx;
      cy += w2 * dy;
    }

    const det: number = s11 * s22 - s12 * s12;
    const fallbackP1: Point2D = {
      x: p0.x + (p3.x - p0.x) / 3,
      y: p0.y + (p3.y - p0.y) / 3,
    };
    const fallbackP2: Point2D = {
      x: p0.x + 2 * (p3.x - p0.x) / 3,
      y: p0.y + 2 * (p3.y - p0.y) / 3,
    };
    if (Math.abs(det) < 1e-9) {
      // 病态矩阵：回退直线三等分控制点
      return { p0: p0, p1: fallbackP1, p2: fallbackP2, p3: p3 };
    }
    const inv: number = 1 / det;
    const p1x: number = (s22 * bx - s12 * cx) * inv;
    const p1y: number = (s22 * by - s12 * cy) * inv;
    const p2x: number = (s11 * cx - s12 * bx) * inv;
    const p2y: number = (s11 * cy - s12 * by) * inv;
    if (!isFinite(p1x) || !isFinite(p1y) || !isFinite(p2x) || !isFinite(p2y)) {
      // 非有限结果：同样回退
      return { p0: p0, p1: fallbackP1, p2: fallbackP2, p3: p3 };
    }
    return {
      p0: p0,
      p1: { x: p1x, y: p1y },
      p2: { x: p2x, y: p2y },
      p3: p3,
    };
  }

  // 最大误差检查（sqh.h）：逐点采样曲线求最大欧氏距离
  private maxError(points: Point2D[], start: number, end: number, curve: CubicSegment): number {
    let maxErr: number = 0;
    const steps: number = 50;  // t 步长 0.02
    for (let i = start; i <= end; i++) {
      const p: Point2D = points[i];
      let best: number = Number.MAX_VALUE;
      for (let s = 0; s <= steps; s++) {
        const t: number = s / steps;
        const mt: number = 1 - t;
        const x: number = mt * mt * mt * curve.p0.x + 3 * mt * mt * t * curve.p1.x +
          3 * mt * t * t * curve.p2.x + t * t * t * curve.p3.x;
        const y: number = mt * mt * mt * curve.p0.y + 3 * mt * mt * t * curve.p1.y +
          3 * mt * t * t * curve.p2.y + t * t * t * curve.p3.y;
        const dx: number = x - p.x;
        const dy: number = y - p.y;
        const d: number = dx * dx + dy * dy;
        if (d < best) {
          best = d;
        }
      }
      const err: number = Math.sqrt(best);
      if (err > maxErr) {
        maxErr = err;
      }
    }
    return maxErr;
  }

  // 二分分段（sqh.f）：最长可接受区间，超容差则二分
  private fitRecursive(points: Point2D[], start: number, end: number, tolerance: number,
    result: CubicSegment[]): void {
    if (end - start < 1) {
      return;
    }
    let segEnd: number = end;
    if (segEnd - start > this.config.maxPointsPerSegment) {
      segEnd = start + this.config.maxPointsPerSegment;
    }
    const curve: CubicSegment = this.fitCubic(points, start, segEnd);
    const err: number = this.maxError(points, start, segEnd, curve);
    if (err <= tolerance) {
      result.push(curve);
    } else if (segEnd - start > 1) {
      const mid: number = Math.floor((start + segEnd) / 2);
      this.fitRecursive(points, start, mid, tolerance, result);
      this.fitRecursive(points, mid, segEnd, tolerance, result);
    } else {
      // 相邻两点仍超容差：直线段（三等分控制点）兜底
      result.push(curve);
    }
  }
}
