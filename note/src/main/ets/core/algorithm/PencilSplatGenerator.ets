// T-011 PencilSplat 生成器（任务卡 T-011，REVERSE_ANALYSIS §18：xaa.b()/xaa.d() 完整公式）
// 确定性 LCG 随机 + 椭圆盘散布 + 压感⁵缓动 + 倾斜响应
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { PencilSplatPoint, StrokePathPoint } from '../model/StrokeTypes';
import { CubicSegment, Point2D } from '../model/GeometryTypes';

export interface SplatGeneratorConfig {
  spacing: number;          // splat 间距（默认 2.0）
  pressurePower: number;    // 压感幂次（默认 5）
  tiltNormalize: number;    // 倾斜归一化除数（默认 -0.94248）
  ellipseShrink: number;    // 椭圆 x 收缩（默认 0.9）
  angleStep: number;        // 角度细分步长（默认 π/125）
  maxSubdivisions: number;  // 最大细分（默认 26）
  lcgMultiplier: number;    // LCG 乘子（默认 1118393071）
  lcgModulus: number;       // LCG 模数（默认 1946926193）
}

export interface SplatAttributes {
  pressure: number;
  tilt: number;
  orientation: number;
  width: number;
}

// 曲线行走点：位置 + 单位切向量（ArkTS 不允许对象字面量类型，需显式 interface）
export interface CurveWalkPoint {
  pos: Point2D;
  tangent: Point2D;
}

export class PencilSplatGenerator {
  private config: SplatGeneratorConfig;
  private seed: number;

  constructor(config?: Partial<SplatGeneratorConfig>) {
    const merged: SplatGeneratorConfig = {
      spacing: 2.0,
      pressurePower: 5,
      tiltNormalize: -0.94248,
      ellipseShrink: 0.9,
      angleStep: Math.PI / 125,
      maxSubdivisions: 26,
      lcgMultiplier: 1118393071,
      lcgModulus: 1946926193,
    };
    if (config !== undefined) {
      if (config.spacing !== undefined) {
        merged.spacing = config.spacing;
      }
      if (config.pressurePower !== undefined) {
        merged.pressurePower = config.pressurePower;
      }
      if (config.tiltNormalize !== undefined) {
        merged.tiltNormalize = config.tiltNormalize;
      }
      if (config.ellipseShrink !== undefined) {
        merged.ellipseShrink = config.ellipseShrink;
      }
      if (config.angleStep !== undefined) {
        merged.angleStep = config.angleStep;
      }
      if (config.maxSubdivisions !== undefined) {
        merged.maxSubdivisions = config.maxSubdivisions;
      }
      if (config.lcgMultiplier !== undefined) {
        merged.lcgMultiplier = config.lcgMultiplier;
      }
      if (config.lcgModulus !== undefined) {
        merged.lcgModulus = config.lcgModulus;
      }
    }
    this.config = merged;
    this.seed = 42;  // 默认 seed（可重置）
  }

  // 主入口：沿曲线等距行走生成 splat 点
  generate(segments: CubicSegment[], pathPoints: StrokePathPoint[]): PencilSplatPoint[] {
    if (this.config.spacing <= 0 || segments.length === 0 || pathPoints.length === 0) {
      return [];
    }
    const splats: PencilSplatPoint[] = [];
    const totalLength: number = this.totalLength(segments);
    let d: number = 0;
    while (d <= totalLength) {
      const walk = this.advanceByDistance(segments, d);
      if (walk === null) {
        break;
      }
      const ratio: number = totalLength > 0 ? d / totalLength : 0;
      const attrs: SplatAttributes = this.interpolateAttributes(pathPoints, ratio);
      const atPos: PencilSplatPoint[] = this.generateAtPosition(walk.pos, walk.tangent,
        attrs.pressure, attrs.tilt, attrs.orientation, attrs.width);
      for (const s of atPos) {
        splats.push(s);
      }
      d += this.config.spacing;
    }
    return splats;
  }

  // 单位置 splat 生成（xaa.b()/xaa.d() 完整公式）
  private generateAtPosition(pos: Point2D, tangent: Point2D, pressure: number, tilt: number,
    orientation: number, width: number): PencilSplatPoint[] {
    // 无能力输入 fallback
    const p: number = pressure < 0 ? 0.5 : pressure;
    const t: number = tilt < 0 ? Math.PI / 4 : tilt;
    const o: number = orientation < 0 ? 0 : orientation;

    // === 尺寸系数（xaa.d()）===
    const clampedPressure: number = Math.min(p, 2.0) / 2.0;
    const sizePressure: number = 1 - this.power5(1 - clampedPressure);
    const tiltNorm: number = Math.min((t - Math.PI / 2) / this.config.tiltNormalize, 1.0);
    const sizeTilt: number = 1 - this.power5(tiltNorm);
    const sizeFactor: number = sizePressure * sizeTilt + (1 - sizeTilt) * 1.0;

    // === 散布盘参数 ===
    const scaleBase: number = Math.min(width, 2.0) / 2.0 * 0.97 + 0.03;
    const angleDiff: number = Math.max(Math.PI / 5 - o, 0);
    let splatCount: number = Math.floor(angleDiff / this.config.angleStep) + 1;
    if (splatCount > this.config.maxSubdivisions) {
      splatCount = this.config.maxSubdivisions;
    }
    const subdivisions: number = Math.floor(angleDiff / this.config.angleStep);
    const ellipseR: number = 1.2 * (this.config.spacing / 2.0) * 0.5 * subdivisions;
    const ellipseS: number = (angleDiff / (Math.PI / 2)) * (-0.48) + 0.5;
    const baseScale: number = ellipseS * this.config.spacing * sizeFactor;

    // === 每 splat 随机散布（LCG）===
    const angleNorm: number = Math.min(Math.max(angleDiff / 0.45332, 0), 1);
    const edgeFactor: number = (1 - angleNorm) + 0.1 * angleNorm;
    const twoPi: number = Math.PI * 2;
    const tx: number = tangent.x;
    const ty: number = tangent.y;

    const results: PencilSplatPoint[] = [];
    for (let i = 0; i < splatCount; i++) {
      const u1: number = this.nextRandom();
      const theta: number = this.nextRandom() * twoPi;
      const r: number = Math.sqrt(u1);
      const x: number = this.config.ellipseShrink * Math.cos(theta) * r;
      const len: number = (angleNorm + Math.sin(theta)) * 1.0;
      // 位置 = 曲线点 + 切线/法线偏移（公式精确照搬 §18）
      const splatX: number = pos.x + (len * ty + x * (-tx)) * ellipseR;
      const splatY: number = pos.y + (len * tx + x * ty) * ellipseR;
      const rotation: number = this.nextRandom() * twoPi;
      const opacity: number = (1 - Math.sqrt(u1)) * edgeFactor * scaleBase;
      results.push({
        x: splatX,
        y: splatY,
        rotation: rotation,
        scale: baseScale,
        opacity: opacity,
      });
    }
    return results;
  }

  // LCG 伪随机（确定性）：拆分乘法模拟取模，避免 double 精度丢失
  private nextRandom(): number {
    const a: number = this.config.lcgMultiplier;
    const m: number = this.config.lcgModulus;
    const base: number = 1024;  // 2^10
    const ah: number = Math.floor(a / base);
    const al: number = a % base;
    const sh: number = Math.floor(this.seed / base);
    const sl: number = this.seed % base;
    // (ah*base+al)*(sh*base+sl) mod m，逐步取模保证中间值 < 2^53
    const m1: number = (ah * sl + al * sh) % m;
    const m2: number = (ah * sh) % m;
    const lo: number = (al * sl) % m;
    const next: number = (lo + m1 * base + m2 * base * base) % m;
    this.seed = next;
    return next / m;
  }

  // 沿贝塞尔曲线等距前进（先定位到段，再在段内二分 t）
  private advanceByDistance(segments: CubicSegment[], distance: number): CurveWalkPoint | null {
    if (segments.length === 0 || distance < 0) {
      return null;
    }
    let remaining: number = distance;
    for (const seg of segments) {
      const segLen: number = this.segmentLength(seg);
      if (remaining <= segLen || seg === segments[segments.length - 1]) {
        const t: number = this.bisectArc(seg, remaining, 0, 1, 40);
        return this.pointOnSegment(seg, t);
      }
      remaining -= segLen;
    }
    return null;
  }

  // 段内二分查找弧长 ≈ target 的 t
  private bisectArc(seg: CubicSegment, target: number, lo: number, hi: number, iterations: number): number {
    let low: number = lo;
    let high: number = hi;
    for (let i = 0; i < iterations; i++) {
      const mid: number = (low + high) / 2;
      const len: number = this.arcLengthFromStart(seg, mid);
      if (len < target) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  // 段 [0, t] 的弧长（分段线性近似，40 子段）
  private arcLengthFromStart(seg: CubicSegment, t: number): number {
    const steps: number = 40;
    let total: number = 0;
    let prev: Point2D = seg.p0;
    for (let i = 1; i <= steps; i++) {
      const ti: number = (t * i) / steps;
      const walk: CurveWalkPoint = this.pointOnSegment(seg, ti);
      const pt: Point2D = walk.pos;
      const dx: number = pt.x - prev.x;
      const dy: number = pt.y - prev.y;
      total += Math.sqrt(dx * dx + dy * dy);
      prev = pt;
    }
    return total;
  }

  // 整段弧长
  private segmentLength(seg: CubicSegment): number {
    return this.arcLengthFromStart(seg, 1);
  }

  // 曲线总长
  private totalLength(segments: CubicSegment[]): number {
    let total: number = 0;
    for (const seg of segments) {
      total += this.segmentLength(seg);
    }
    return total;
  }

  // 贝塞尔段上的点与切线
  private pointOnSegment(seg: CubicSegment, t: number): CurveWalkPoint {
    const mt: number = 1 - t;
    const x: number = mt * mt * mt * seg.p0.x + 3 * mt * mt * t * seg.p1.x +
      3 * mt * t * t * seg.p2.x + t * t * t * seg.p3.x;
    const y: number = mt * mt * mt * seg.p0.y + 3 * mt * mt * t * seg.p1.y +
      3 * mt * t * t * seg.p2.y + t * t * t * seg.p3.y;
    // 切线 = 一阶导数
    const dx: number = 3 * mt * mt * (seg.p1.x - seg.p0.x) + 6 * mt * t * (seg.p2.x - seg.p1.x) +
      3 * t * t * (seg.p3.x - seg.p2.x);
    const dy: number = 3 * mt * mt * (seg.p1.y - seg.p0.y) + 6 * mt * t * (seg.p2.y - seg.p1.y) +
      3 * t * t * (seg.p3.y - seg.p2.y);
    const len: number = Math.sqrt(dx * dx + dy * dy);
    const tx: number = len > 1e-9 ? dx / len : 1;
    const ty: number = len > 1e-9 ? dy / len : 0;
    const pos: Point2D = { x: x, y: y };
    const tangent: Point2D = { x: tx, y: ty };
    return { pos: pos, tangent: tangent };
  }

  // 沿 pathPoints 按弧长比例插值属性（pressure 由 widthFactor 反推）
  private interpolateAttributes(pathPoints: StrokePathPoint[], ratio: number): SplatAttributes {
    const n: number = pathPoints.length;
    if (n === 1) {
      return this.attrsFromPathPoint(pathPoints[0]);
    }
    const f: number = ratio * (n - 1);
    const i0: number = Math.min(Math.floor(f), n - 2);
    const i1: number = i0 + 1;
    const t: number = f - i0;
    const w0: number = pathPoints[i0].widthFactor;
    const w1: number = pathPoints[i1].widthFactor;
    const width: number = w0 + (w1 - w0) * t;
    return {
      pressure: this.clamp((width - 0.3) / 0.7, 0, 1),  // 与 StrokeSession 的映射互逆
      tilt: Math.PI / 4,   // 默认 45°（MVP 无倾斜数据）
      orientation: 0,      // 默认 0
      width: width,
    };
  }

  private attrsFromPathPoint(p: StrokePathPoint): SplatAttributes {
    return {
      pressure: this.clamp((p.widthFactor - 0.3) / 0.7, 0, 1),
      tilt: Math.PI / 4,
      orientation: 0,
      width: p.widthFactor,
    };
  }

  private power5(x: number): number {
    return x * x * x * x * x;
  }

  private clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }

  reset(seed: number): void {
    this.seed = seed;
  }
}
