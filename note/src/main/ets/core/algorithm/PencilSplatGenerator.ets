// T-011 PencilSplat 生成器（任务卡 T-011，REVERSE_ANALYSIS §18：xaa.b()/xaa.d() 完整公式）
// 确定性 LCG 随机 + 椭圆盘散布 + 压感⁵缓动 + 倾斜响应
// 纯数学模块：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { PencilSplatPoint, StrokePathPoint } from '../model/StrokeTypes';
import { CubicSegment, Point2D } from '../model/GeometryTypes';

export interface SplatGeneratorConfig {
  spacing: number;          // splat 间距（原版 xaa.b 的 d = 笔刷宽度 c0()，由调用方传入）
  pressurePower: number;    // 压感幂次（默认 5）
  tiltNormalize: number;    // 倾斜归一化除数（默认 -0.9424777960769379，xaa.d 完整 double）
  ellipseShrink: number;    // 椭圆 x 收缩（默认 0.9）
  angleStep: number;        // 角度细分步长（默认 π/125）
  maxSubdivisions: number;  // 最大细分（默认 26）
  lcgMultiplier: number;    // LCG 乘子（默认 1118393071）
  lcgModulus: number;       // LCG 模数（默认 1946926193）
}

export interface SplatAttributes {
  pressure: number;
  altitudeAngleRadians: number;
  azimuthUnitX: number;
  azimuthUnitY: number;
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
      tiltNormalize: -0.9424777960769379,
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

  // 主入口：沿曲线行走生成 splat 点（xaa.b() 语义）
  // 预步进 spacing*0.25（te6.q 传 ow5Var=null → xaa.b L174 分支），
  // 后续步长 = spacing*0.25*(sizeFactor*0.5+0.5)（xaa.b L259，随尺寸变化）
  generate(segments: CubicSegment[], pathPoints: StrokePathPoint[]): PencilSplatPoint[] {
    if (this.config.spacing <= 0 || segments.length === 0 || pathPoints.length === 0) {
      return [];
    }
    const splats: PencilSplatPoint[] = [];
    const totalLength: number = this.totalLength(segments);
    // 预步进（xaa.b L174）：firstStep = spacing * 0.25
    let d: number = this.config.spacing * 0.25;
    while (d <= totalLength) {
      const walk = this.advanceByDistance(segments, d);
      if (walk === null) {
        break;
      }
      const ratio: number = totalLength > 0 ? d / totalLength : 0;
      const attrs: SplatAttributes = this.interpolateAttributes(pathPoints, ratio);
      const sizeF: number = this.sizeFactorOf(attrs);
      const atPos: PencilSplatPoint[] = this.generateAtPosition(walk.pos, walk.tangent,
        attrs);
      for (const s of atPos) {
        splats.push(s);
      }
      // 步进（xaa.b L259）：step = spacing*0.25*(sizeFactor*0.5+0.5)
      d += this.config.spacing * 0.25 * (sizeF * 0.5 + 0.5);
    }
    return splats;
  }

  // sizeFactor = sizeP*sizeT + (1-sizeT)*1.0（xaa.d()）
  private sizeFactorOf(attrs: SplatAttributes): number {
    const p: number = attrs.pressure < 0 ? 1.0 : attrs.pressure;
    const t: number = attrs.altitudeAngleRadians < 0 ? Math.PI / 2 : attrs.altitudeAngleRadians;
    const clampedPressure: number = Math.min(p, 2.0) / 2.0;
    const sizePressure: number = 1 - this.power5(1 - clampedPressure);
    const tiltNorm: number = Math.min((t - Math.PI / 2) / this.config.tiltNormalize, 1.0);
    const sizeTilt: number = 1 - this.power5(tiltNorm);
    return sizePressure * sizeTilt + (1 - sizeTilt) * 1.0;
  }

  // 单位置 splat 生成（xaa.b()/xaa.d() 完整公式）
  private generateAtPosition(pos: Point2D, tangent: Point2D,
    attrs: SplatAttributes): PencilSplatPoint[] {
    // 1.0.3 cfa.b()/ed0：缺失输入使用 force=1、altitude=π/2、azimuth=(1,0)。
    const pressure: number = attrs.pressure < 0 ? 1.0 : attrs.pressure;
    const altitude: number = attrs.altitudeAngleRadians < 0 ? Math.PI / 2 : attrs.altitudeAngleRadians;

    // === 散布盘参数 ===
    const scaleBase: number = Math.min(pressure, 2.0) / 2.0 * 0.97 + 0.03;
    const angleDiff: number = Math.max(Math.PI / 5 - altitude, 0);
    let splatCount: number = Math.floor(angleDiff / this.config.angleStep) + 1;
    if (splatCount > this.config.maxSubdivisions) {
      splatCount = this.config.maxSubdivisions;
    }
    const subdivisions: number = Math.floor(angleDiff / this.config.angleStep);
    // 散布盘半径（xaa.b L196）：ellipseR = 1.2*(d/2)*0.5*floor
    const ellipseR: number = 1.2 * (this.config.spacing / 2.0) * 0.5 * subdivisions;
    const ellipseS: number = (angleDiff / (Math.PI / 2)) * (-0.48) + 0.5;
    // scale = ellipseS * spacing * (sizeFactor*0.5 + 0.5)（xaa.b：d10*d11）
    const baseScale: number = ellipseS * this.config.spacing * (this.sizeFactorOf(attrs) * 0.5 + 0.5);

    // === 每 splat 随机散布（LCG）===
    // angleNorm 分母 0.45331853071795863（xaa.b L198 完整 double）
    const angleNorm: number = Math.min(Math.max(angleDiff / 0.45331853071795863, 0), 1);
    const edgeFactor: number = (1 - angleNorm) + 0.1 * angleNorm;
    const twoPi: number = Math.PI * 2;
    const hasAzimuth: boolean = Math.abs(attrs.azimuthUnitX) + Math.abs(attrs.azimuthUnitY) > 0.000001;
    const tx: number = hasAzimuth ? attrs.azimuthUnitX : tangent.x;
    const ty: number = hasAzimuth ? attrs.azimuthUnitY : tangent.y;

    const results: PencilSplatPoint[] = [];
    for (let i = 0; i < splatCount; i++) {
      const u1: number = this.nextRandom();
      const theta: number = this.nextRandom() * twoPi;
      const r: number = Math.sqrt(u1);
      const x: number = this.config.ellipseShrink * Math.cos(theta) * r;
      const len: number = (angleNorm + Math.sin(theta) * r) * 1.0;
      // 位置 = 曲线点 + 切线/法线偏移（公式精确照搬 xaa.b L216-218）
      // 原版：x' = d18*dB - d17*dC，y' = d18*dC + d17*dB（dB=方向x, dC=方向y）
      // 即 x' = len*ux - x*uy，y' = len*uy + x*ux（ux=切线x, uy=切线y）
      // 注意：不能写成 len*uy - x*ux（旋转方向会镜像，侧锋偏移方向反转）
      const splatX: number = pos.x + (len * tx - x * ty) * ellipseR;
      const splatY: number = pos.y + (len * ty + x * tx) * ellipseR;
      const rotation: number = this.nextRandom() * twoPi;
      // opacity 因子（xaa.b L226/L230）：splatCount==1 时为 1.0，否则 1-sqrt(u1)
      const opacityFactor: number = splatCount === 1 ? 1.0 : (1 - Math.sqrt(u1));
      const opacity: number = opacityFactor * edgeFactor * scaleBase;
      // 有限守卫（xaa.b L235）：超 Float.MAX_VALUE 跳过该 splat
      if (Math.abs(splatX) > 3.4028235e38 || Math.abs(splatY) > 3.4028235e38) {
        continue;
      }
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
    const start: SplatAttributes = this.attrsFromPathPoint(pathPoints[i0]);
    const end: SplatAttributes = this.attrsFromPathPoint(pathPoints[i1]);
    return {
      pressure: this.lerp(start.pressure, end.pressure, t),
      altitudeAngleRadians: this.lerp(start.altitudeAngleRadians, end.altitudeAngleRadians, t),
      azimuthUnitX: this.lerp(start.azimuthUnitX, end.azimuthUnitX, t),
      azimuthUnitY: this.lerp(start.azimuthUnitY, end.azimuthUnitY, t),
    };
  }

  private attrsFromPathPoint(p: StrokePathPoint): SplatAttributes {
    const pressure: number = p.pressure !== undefined
      ? p.pressure : this.clamp((p.widthFactor - 0.3) / 0.7, 0, 1);
    return {
      pressure: pressure,
      altitudeAngleRadians: p.altitudeAngleRadians !== undefined
        ? p.altitudeAngleRadians : Math.PI / 2,
      azimuthUnitX: p.azimuthUnitX !== undefined ? p.azimuthUnitX : 1,
      azimuthUnitY: p.azimuthUnitY !== undefined ? p.azimuthUnitY : 0,
    };
  }

  private lerp(start: number, end: number, t: number): number {
    return start + (end - start) * t;
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
