// T-009 三次贝塞尔拟合器（任务卡 T-009，REVERSE_ANALYSIS §17：sqh.g/h/f）
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D, CubicSegment } from '../model/GeometryTypes';
import { StrokePathPoint } from '../model/StrokeTypes';

export interface FitterConfig {
  maxPointsPerSegment: number;  // 默认 200（单次拟合最大点数）
  contextExpansion: number;     // 默认 5（前后各扩 5 点上下文）
  baseTolerance: number;        // 默认 0.5（会被动态容差覆盖）
}

// 1.0.3 nt1.java:180 + od4.java:98-111.
export function computeOriginalFitTolerance(baseWidth: number, zoom: number): number {
  const scale: number = Math.max(zoom, 0.01);
  const screenWidth: number = Math.min(18, Math.max(baseWidth * scale, 2.6));
  return (0.5 / ((((screenWidth - 2.6) / 15.4) * 1.5) + 1.0)) / scale;
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
  // sqh.f() 语义：≤200 点直接接受（sqh.h），>200 点二分找最长可接受终点（wy5），
  // 段未覆盖末尾且前后各 ≥4 点时拆半重拟合，最后做段间方向连续性修正
  fit(points: StrokePathPoint[], baseWidth: number, zoom: number,
    initialTangent?: Point2D): CubicSegment[] {
    if (points.length < 2) {
      return [];
    }
    const pts: Point2D[] = [];
    for (const p of points) {
      pts.push(p.position);
    }
    const tolerance: number = this.computeTolerance(baseWidth, zoom);
    const result: CubicSegment[] = [];
    const n: number = pts.length;
    const maxPts: number = this.config.maxPointsPerSegment;
    let start: number = 0;
    while (start < n - 1) {
      const remainingCount: number = n - start;
      if (remainingCount <= maxPts) {
        // sqh.h 语义：目标区间 ≤200 点 → 直接拟合接受（不做误差检查）
        result.push(this.fitCubic(pts, start, n - 1));
        start = n - 1;
        break;
      }
      // sqh.f/wy5 语义：>200 点 → 二分查找最长可接受终点（误差 ≤ tolerance）
      let lo: number = start + 1;
      // wxh.d rejects target ranges above 200 points before evaluating their error.
      let hi: number = Math.min(n - 1, start + maxPts - 1);
      let bestEnd: number = start + 1;
      while (lo <= hi) {
        const mid: number = Math.floor((lo + hi) / 2);
        const curve: CubicSegment = this.fitCubic(pts, start, mid);
        const err: number = this.maxError(pts, start, mid, curve);
        if (err <= tolerance) {
          bestEnd = mid;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      let segEnd: number = bestEnd;
      // 拆半后处理（sqh.f）：段未覆盖末尾且前半 ≥4 点、剩余 ≥4 点 → 重拟合前半段
      const half: number = Math.floor((segEnd + start) / 2);
      if (segEnd < n - 1 && (half - start + 1) >= 4 && (n - half) >= 4) {
        segEnd = half;
      }
      result.push(this.fitCubic(pts, start, segEnd));
      start = segEnd;
    }
    // 段间连续性修正（sqh.f 尾部循环）：p1 = p0 + 前段 j(1.0) 切向投影
    this.applyContinuity(result, initialTangent);
    return result;
  }

  // 1.0.3 nt1 + od4.g：先把屏幕笔宽钳到 [2.6, 18]，再代入容差公式。
  private computeTolerance(baseWidth: number, zoom: number): number {
    return computeOriginalFitTolerance(baseWidth, zoom);
  }

  // 最小二乘求控制点（sqh.g）：三次 Bernstein 基 + 2×2 正规方程
  private fitCubic(points: Point2D[], segStart: number, segEnd: number): CubicSegment {
    const p0: Point2D = points[segStart];
    const p3: Point2D = points[segEnd];
    // 上下文扩展：拟合使用扩展区间点，但段端点仍为目标区间端点
    const ctx: number = this.config.contextExpansion;
    const fitStart: number = Math.max(0, segStart - ctx);
    const fitEnd: number = Math.min(points.length - 1, segEnd + ctx);
    const total: number = fitEnd - fitStart + 1;
    // wxh.b：一个收集点退化为点；两个收集点使用直线三等分手柄。
    if (total === 1) {
      const only: Point2D = points[fitStart];
      return { p0: only, p1: only, p2: only, p3: only };
    }
    if (total === 2) {
      const first: Point2D = points[fitStart];
      const last: Point2D = points[fitEnd];
      return {
        p0: first,
        p1: {
          x: first.x * 2 / 3 + last.x / 3,
          y: first.y * 2 / 3 + last.y / 3,
        },
        p2: {
          x: first.x / 3 + last.x * 2 / 3,
          y: first.y / 3 + last.y * 2 / 3,
        },
        p3: last,
      };
    }
    // 三点特例（sqh.g i12==3）：中点二阶外插控制点，端点取收集数组首末点（含上下文）
    if (total === 3) {
      const fp0: Point2D = points[fitStart];
      const fp1: Point2D = points[fitStart + 1];
      const fp3: Point2D = points[fitEnd];
      // dB3 = 2*fp1 - (fp3 + fp0)*0.5；p1 = fp0/3 + dB3*2/3；p2 = fp3/3 + dB3*2/3
      const midX: number = 2 * fp1.x - (fp3.x + fp0.x) * 0.5;
      const midY: number = 2 * fp1.y - (fp3.y + fp0.y) * 0.5;
      return {
        p0: fp0,
        p1: { x: fp0.x / 3 + midX * 2 / 3, y: fp0.y / 3 + midY * 2 / 3 },
        p2: { x: fp3.x / 3 + midX * 2 / 3, y: fp3.y / 3 + midY * 2 / 3 },
        p3: fp3,
      };
    }
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

    // 病态判据（sqh.g）：det <= 1e-9 * s11 * s22（相对阈值，原版无 abs）
    const det: number = s11 * s22 - s12 * s12;
    const fallbackP1: Point2D = {
      x: p0.x + (p3.x - p0.x) / 3,
      y: p0.y + (p3.y - p0.y) / 3,
    };
    const fallbackP2: Point2D = {
      x: p0.x + 2 * (p3.x - p0.x) / 3,
      y: p0.y + 2 * (p3.y - p0.y) / 3,
    };
    if (det <= 1e-9 * s11 * s22) {
      // 病态矩阵：回退直线三等分控制点
      return { p0: p0, p1: fallbackP1, p2: fallbackP2, p3: p3 };
    }
    const inv: number = 1 / det;
    const p1x: number = (s22 * bx - s12 * cx) * inv;
    const p1y: number = (s22 * by - s12 * cy) * inv;
    const p2x: number = (s11 * cx - s12 * bx) * inv;
    const p2y: number = (s11 * cy - s12 * by) * inv;
    // 非有限回退（sqh.g）：仅 abs(x) > Double.MAX_VALUE 时回退（NaN 不回退）
    if (Math.abs(p1x) > Number.MAX_VALUE || Math.abs(p1y) > Number.MAX_VALUE ||
      Math.abs(p2x) > Number.MAX_VALUE || Math.abs(p2y) > Number.MAX_VALUE) {
      return { p0: p0, p1: fallbackP1, p2: fallbackP2, p3: p3 };
    }
    return {
      p0: p0,
      p1: { x: p1x, y: p1y },
      p2: { x: p2x, y: p2y },
      p3: p3,
    };
  }

  // 最大误差检查（sqh.h 方式）：逐点按 t=(i-start)/(end-start) 直接求曲线点欧氏距离
  // （非最近点搜索；误差 < 1e-12 忽略，仅对目标区间 [start, end] 检查）
  private maxError(points: Point2D[], start: number, end: number, curve: CubicSegment): number {
    if (end - start < 2) {
      return 0;
    }
    let maxErr: number = 0;
    const span: number = end - start;
    for (let i = start; i <= end; i++) {
      const t: number = (i - start) / span;
      const mt: number = 1 - t;
      const x: number = mt * mt * mt * curve.p0.x + 3 * mt * mt * t * curve.p1.x +
        3 * mt * t * t * curve.p2.x + t * t * t * curve.p3.x;
      const y: number = mt * mt * mt * curve.p0.y + 3 * mt * mt * t * curve.p1.y +
        3 * mt * t * t * curve.p2.y + t * t * t * curve.p3.y;
      const dx: number = x - points[i].x;
      const dy: number = y - points[i].y;
      const d: number = Math.sqrt(dx * dx + dy * dy);
      if (d > 1e-12 && Math.abs(d) <= Number.MAX_VALUE && d > maxErr) {
        maxErr = d;
      }
    }
    return maxErr;
  }

  // 段间方向连续性修正（sqh.f 尾部循环）：p1 = p0 + 前段 j(1.0) 切向投影
  private applyContinuity(segments: CubicSegment[], initialTangent?: Point2D): void {
    for (let k = 0; k < segments.length; k++) {
      const cur: CubicSegment = segments[k];
      let tx: number;
      let ty: number;
      if (k === 0) {
        if (initialTangent === undefined) {
          continue;
        }
        tx = initialTangent.x;
        ty = initialTangent.y;
      } else {
        const prev: CubicSegment = segments[k - 1];
        // 前段 j(1.0) 切向 = 3*(p3 - p2)
        tx = 3 * (prev.p3.x - prev.p2.x);
        ty = 3 * (prev.p3.y - prev.p2.y);
      }
      const len: number = Math.sqrt(tx * tx + ty * ty);
      const dx: number = cur.p1.x - cur.p0.x;
      const dy: number = cur.p1.y - cur.p0.y;
      let ox: number;
      let oy: number;
      if (len === 0) {
        // 前段退化：偏移直接用本段端点差
        ox = dx;
        oy = dy;
      } else {
        const ux: number = tx / len;
        const uy: number = ty / len;
        const proj: number = dx * ux + dy * uy;
        ox = ux * proj;
        oy = uy * proj;
      }
      cur.p1 = { x: cur.p0.x + ox, y: cur.p0.y + oy };
    }
  }
}
