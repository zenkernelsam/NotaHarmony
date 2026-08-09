// T-014 笔画会话状态机（任务卡 T-014，从 touchDown 到 touchUp 的完整生命周期）
// 只调用算法模块和模型类型：禁止 import 平台 API
import {
  InputBatch, InputBatchKind, InputPoint, StrokeElementData, StrokePathPoint,
  PencilSplatPoint, RenderSpec, InkStyle,
} from '../core/model/StrokeTypes';
import { CubicSegment, Rect2D } from '../core/model/GeometryTypes';
import { ForceSmoother } from '../core/algorithm/ForceSmoother';
import {
  CubicAttributeSplitOptions, CubicFitResult, CubicFitter, CubicSourceRange,
} from '../core/algorithm/CubicFitter';
import { WidthOutlineBuilder, OutlineResult } from '../core/algorithm/WidthOutlineBuilder';
import { PencilSplatGenerator } from '../core/algorithm/PencilSplatGenerator';
import { computePencilSplatBounds } from '../core/adaptation/PencilSplatMath';

export interface StrokeSessionConfig {
  widthFactorMin: number;    // 默认 0.3（最小宽度比例）
  widthFactorRange: number;  // 默认 0.7（压力映射范围）
  // splatSeed 兼容保留字段（T-AUDIT 后 seed 改用笔画起始时间戳，原版 hud.f()）
  splatSeed: number;         // 默认 42（不再使用，保留契约兼容）
}

export class StrokeSession {
  private smoother: ForceSmoother;
  private fitter: CubicFitter;
  private outlineBuilder: WidthOutlineBuilder;
  private splatGenerator: PencilSplatGenerator;
  private config: StrokeSessionConfig;

  // 当前笔画状态
  private rawPoints: InputPoint[] = [];
  private pathPoints: StrokePathPoint[] = [];
  private cubicSegments: CubicSegment[] = [];
  private cubicSourceRanges: CubicSourceRange[] = [];
  private splatPoints: PencilSplatPoint[] = [];
  private outline: OutlineResult | null = null;
  private previewPathPoints: StrokePathPoint[] = [];
  private previewCubicSegments: CubicSegment[] = [];
  private previewSplatPoints: PencilSplatPoint[] = [];
  private previewOutline: OutlineResult | null = null;
  private renderSpec: RenderSpec;
  private active: boolean = false;  // 字段名避开与 isActive() 方法重名（ArkTS 限制）
  private strokeId: string = '';
  private startTime: number = 0;
  private currentStroke: StrokeElementData | null = null;
  // T-040 审核修复：画布缩放感知（拟合容差按屏幕空间计算）
  private zoom: number = 1.0;

  constructor(renderSpec: RenderSpec, config?: Partial<StrokeSessionConfig>) {
    this.renderSpec = renderSpec;
    const merged: StrokeSessionConfig = {
      widthFactorMin: 0.3,
      widthFactorRange: 0.7,
      splatSeed: 42,
    };
    if (config !== undefined) {
      if (config.widthFactorMin !== undefined) {
        merged.widthFactorMin = config.widthFactorMin;
      }
      if (config.widthFactorRange !== undefined) {
        merged.widthFactorRange = config.widthFactorRange;
      }
      if (config.splatSeed !== undefined) {
        merged.splatSeed = config.splatSeed;
      }
    }
    this.config = merged;
    this.smoother = new ForceSmoother();
    this.fitter = new CubicFitter();
    this.outlineBuilder = new WidthOutlineBuilder();
    // spacing = 笔刷宽度（oz5.t：dC0 = ry5Var.c0()），beginStroke 时按当前 spec 重建
    this.splatGenerator = new PencilSplatGenerator({ spacing: this.renderSpec.brushWidth });
  }

  // 开始新笔画
  beginStroke(spec: RenderSpec, timestamp: number, zoom?: number): void {
    this.renderSpec = spec;
    if (zoom !== undefined && zoom > 0) {
      this.zoom = zoom;
    }
    this.rawPoints = [];
    this.pathPoints = [];
    this.cubicSegments = [];
    this.cubicSourceRanges = [];
    this.splatPoints = [];
    this.outline = null;
    this.clearPreview();
    this.currentStroke = null;
    this.active = true;
    this.startTime = timestamp;
    this.strokeId = this.generateStrokeId();
    this.smoother.reset();
    // 按当前笔刷宽度重建 splat 生成器（xaa 的 spacing = c0()），seed 用笔画起始时间戳
    this.splatGenerator = new PencilSplatGenerator({ spacing: this.renderSpec.brushWidth });
    this.splatGenerator.reset(this.startTime);
  }

  // 真实批次替换上一帧预测；预测批次只构造临时尾段，不写入 raw/path/smoother。
  addBatch(batch: InputBatch): void {
    if (!this.active) {
      return;
    }
    if (batch.kind === InputBatchKind.PREDICTED) {
      this.rebuildPreview(batch.points);
      return;
    }
    this.clearPreview();
    const smoothed: InputPoint[] = this.smoother.smooth(batch.points);
    for (const p of smoothed) {
      this.rawPoints.push(p);
      this.pathPoints.push({
        position: { x: p.x, y: p.y },
        widthFactor: this.pressureToWidthFactor(p.pressure),
        pressure: p.pressure,
        altitudeAngleRadians: p.tiltRadians,
        azimuthUnitX: p.orientationRadians >= 0 ? -Math.sin(p.orientationRadians) : 0,
        azimuthUnitY: p.orientationRadians >= 0 ? Math.cos(p.orientationRadians) : 0,
      });
    }
    this.rebuildGeometry();
  }

  // 完成笔画 → 返回完整 StrokeElementData
  finishStroke(): StrokeElementData {
    this.clearPreview();
    this.active = false;
    const stroke: StrokeElementData = this.buildElementData(true);
    this.currentStroke = null;
    return stroke;
  }

  // 取消笔画
  cancelStroke(): void {
    this.clearPreview();
    this.active = false;
    this.currentStroke = null;
  }

  // 获取当前笔画的实时渲染数据（供渲染器每帧使用）
  getCurrentStroke(): StrokeElementData | null {
    if (!this.active) {
      return null;
    }
    if (this.previewPathPoints.length > 0) {
      this.currentStroke = this.buildElementData(false, this.previewPathPoints,
        this.previewCubicSegments, this.previewSplatPoints, this.previewOutline);
    } else {
      this.currentStroke = this.buildElementData(false);
    }
    return this.currentStroke;
  }

  // 非渲染消费者（如形状识别）必须显式读取真实输入，不能让预测尾点改变最终文档语义。
  getCurrentRealStroke(): StrokeElementData | null {
    if (!this.active) {
      return null;
    }
    return this.buildElementData(false);
  }

  private rebuildPreview(points: InputPoint[]): void {
    this.clearPreview();
    if (points.length === 0 || this.pathPoints.length === 0) {
      return;
    }
    this.previewPathPoints = this.pathPoints.slice();
    const predicted: InputPoint[] = this.smoother.smooth(points, false);
    for (const p of predicted) {
      this.previewPathPoints.push(this.toPathPoint(p));
    }
    const geometry: StrokeGeometry = this.buildGeometry(this.previewPathPoints, true);
    this.previewCubicSegments = geometry.cubicSegments;
    this.previewSplatPoints = geometry.splatPoints;
    this.previewOutline = geometry.outline;
  }

  private clearPreview(): void {
    this.previewPathPoints = [];
    this.previewCubicSegments = [];
    this.previewSplatPoints = [];
    this.previewOutline = null;
  }

  // 重建拟合几何（贝塞尔段 / splat / 轮廓）
  private rebuildGeometry(): void {
    const geometry: StrokeGeometry = this.buildGeometry(this.pathPoints, false);
    this.cubicSegments = geometry.cubicSegments;
    this.cubicSourceRanges = geometry.cubicSourceRanges;
    this.splatPoints = geometry.splatPoints;
    this.outline = geometry.outline;
  }

  private buildGeometry(pathPoints: StrokePathPoint[], preview: boolean): StrokeGeometry {
    if (pathPoints.length < 2) {
      return new StrokeGeometry();
    }
    const attributeSplit: CubicAttributeSplitOptions = {
      preserveWidth: this.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH,
      preservePencilAttributes: this.renderSpec.isPencil,
    };
    const fitResult: CubicFitResult = this.fitter.fitWithSourceRanges(
      pathPoints, this.renderSpec.brushWidth, this.zoom, undefined, attributeSplit);
    let splatPoints: PencilSplatPoint[] = [];
    if (this.renderSpec.isPencil && fitResult.segments.length > 0) {
      const generator: PencilSplatGenerator = preview ?
        new PencilSplatGenerator({ spacing: this.renderSpec.brushWidth }) : this.splatGenerator;
      // Refit the full stroke on every batch; restart the original per-stroke LCG so old splats stay stable.
      generator.reset(this.startTime);
      splatPoints = generator.generate(fitResult.segments, pathPoints, fitResult.sourceRanges);
    }
    let outline: OutlineResult | null = null;
    if (this.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH) {
      outline = this.outlineBuilder.build(pathPoints, this.renderSpec.brushWidth, fitResult.segments);
    }
    return new StrokeGeometry(fitResult.segments, fitResult.sourceRanges, splatPoints, outline);
  }

  private buildElementData(isFinished: boolean, pathPoints: StrokePathPoint[] = this.pathPoints,
    cubicSegments: CubicSegment[] = this.cubicSegments,
    splatPoints: PencilSplatPoint[] = this.splatPoints,
    outline: OutlineResult | null = this.outline): StrokeElementData {
    const bounds: Rect2D = this.computeBounds(pathPoints, splatPoints, outline);
    return {
      id: this.strokeId,
      pathPoints: isFinished ? pathPoints.slice() : pathPoints,
      cubicSegments: isFinished ? cubicSegments.slice() : cubicSegments,
      splatPoints: isFinished ? splatPoints.slice() : splatPoints,
      renderSpec: this.renderSpec,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],  // 单位矩阵
      bounds: bounds,
      maskPath: [],
      isFinished: isFinished,
    };
  }

  private computeBounds(pathPoints: StrokePathPoint[], splatPoints: PencilSplatPoint[],
    outline: OutlineResult | null): Rect2D {
    // 优先使用可变宽度轮廓点扩展边界（更精确），否则用中心线点
    let left: number;
    let top: number;
    let right: number;
    let bottom: number;
    const half: number = this.renderSpec.brushWidth / 2;
    if (outline !== null && outline.isValid) {
      left = outline.outlinePoints[0].x;
      top = outline.outlinePoints[0].y;
      right = left;
      bottom = top;
      for (const p of outline.outlinePoints) {
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
    // 原版 mea.a() 以 scale*sqrt(2) 覆盖旋转纹理的最坏外接范围。
    if (this.renderSpec.isPencil && splatPoints.length > 0) {
      const splatBounds: Rect2D | null = computePencilSplatBounds(splatPoints);
      if (splatBounds !== null) {
        return splatBounds;
      }
    }
    if (pathPoints.length === 0) {
      return { left: 0, top: 0, right: 0, bottom: 0 };
    }
    left = pathPoints[0].position.x;
    top = pathPoints[0].position.y;
    right = left;
    bottom = top;
    for (const p of pathPoints) {
      const x: number = p.position.x;
      const y: number = p.position.y;
      if (x < left) {
        left = x;
      }
      if (x > right) {
        right = x;
      }
      if (y < top) {
        top = y;
      }
      if (y > bottom) {
        bottom = y;
      }
    }
    return { left: left - half, top: top - half, right: right + half, bottom: bottom + half };
  }

  // widthFactor 推导：pressure → widthFactor（可配置，默认 0.3 + 0.7 * pressure）
  // T-AUDIT 标注：原版 fc0.e() 逐点宽度因子的生成来源为 🟡（REVERSE_ANALYSIS §35 未闭环），
  // 当前 0.3 + 0.7*p 映射为假设值（基于任务卡约定），待真机/逆向确认后可能调整
  private pressureToWidthFactor(pressure: number): number {
    if (pressure < 0) {
      return 1.0;  // 无压感
    }
    return this.config.widthFactorMin + this.config.widthFactorRange * pressure;
  }

  private toPathPoint(p: InputPoint): StrokePathPoint {
    return {
      position: { x: p.x, y: p.y },
      widthFactor: this.pressureToWidthFactor(p.pressure),
      pressure: p.pressure,
      altitudeAngleRadians: p.tiltRadians,
      azimuthUnitX: p.orientationRadians >= 0 ? -Math.sin(p.orientationRadians) : 0,
      azimuthUnitY: p.orientationRadians >= 0 ? Math.cos(p.orientationRadians) : 0,
    };
  }

  private generateStrokeId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }

  isActive(): boolean {
    return this.active;
  }

  getStartTime(): number {
    return this.startTime;
  }
}

class StrokeGeometry {
  cubicSegments: CubicSegment[];
  cubicSourceRanges: CubicSourceRange[];
  splatPoints: PencilSplatPoint[];
  outline: OutlineResult | null;

  constructor(cubicSegments: CubicSegment[] = [], cubicSourceRanges: CubicSourceRange[] = [],
    splatPoints: PencilSplatPoint[] = [], outline: OutlineResult | null = null) {
    this.cubicSegments = cubicSegments;
    this.cubicSourceRanges = cubicSourceRanges;
    this.splatPoints = splatPoints;
    this.outline = outline;
  }
}
