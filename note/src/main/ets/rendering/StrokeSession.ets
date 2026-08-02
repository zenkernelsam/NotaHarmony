// T-014 笔画会话状态机（任务卡 T-014，从 touchDown 到 touchUp 的完整生命周期）
// 只调用算法模块和模型类型：禁止 import 平台 API
import {
  InputBatch, InputBatchKind, InputPoint, StrokeElementData, StrokePathPoint,
  PencilSplatPoint, RenderSpec, InkStyle,
} from '../core/model/StrokeTypes';
import { CubicSegment, Rect2D } from '../core/model/GeometryTypes';
import { ForceSmoother } from '../core/algorithm/ForceSmoother';
import { CubicFitter } from '../core/algorithm/CubicFitter';
import { WidthOutlineBuilder, OutlineResult } from '../core/algorithm/WidthOutlineBuilder';
import { PencilSplatGenerator } from '../core/algorithm/PencilSplatGenerator';

export interface StrokeSessionConfig {
  widthFactorMin: number;    // 默认 0.3（最小宽度比例）
  widthFactorRange: number;  // 默认 0.7（压力映射范围）
  splatSeed: number;         // 默认 42（splat 确定性随机种子）
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
  private splatPoints: PencilSplatPoint[] = [];
  private outline: OutlineResult | null = null;
  private renderSpec: RenderSpec;
  private active: boolean = false;  // 字段名避开与 isActive() 方法重名（ArkTS 限制）
  private strokeId: string = '';
  private startTime: number = 0;
  private currentStroke: StrokeElementData | null = null;

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
    this.splatGenerator = new PencilSplatGenerator();
  }

  // 开始新笔画
  beginStroke(spec: RenderSpec, timestamp: number): void {
    this.renderSpec = spec;
    this.rawPoints = [];
    this.pathPoints = [];
    this.cubicSegments = [];
    this.splatPoints = [];
    this.outline = null;
    this.currentStroke = null;
    this.active = true;
    this.startTime = timestamp;
    this.strokeId = this.generateStrokeId();
    this.smoother.reset();
    this.splatGenerator.reset(this.config.splatSeed);
  }

  // 添加输入批次（每帧调用）；预测点批次仅用于预览不持久化，MVP 直接忽略
  addBatch(batch: InputBatch): void {
    if (!this.isActive || batch.kind === InputBatchKind.PREDICTED) {
      return;
    }
    const smoothed: InputPoint[] = this.smoother.smooth(batch.points);
    for (const p of smoothed) {
      this.rawPoints.push(p);
      this.pathPoints.push({
        position: { x: p.x, y: p.y },
        widthFactor: this.pressureToWidthFactor(p.pressure),
      });
    }
    this.rebuildGeometry();
  }

  // 完成笔画 → 返回完整 StrokeElementData
  finishStroke(): StrokeElementData {
    this.active = false;
    const stroke: StrokeElementData = this.buildElementData(true);
    this.currentStroke = null;
    return stroke;
  }

  // 取消笔画
  cancelStroke(): void {
    this.active = false;
    this.currentStroke = null;
  }

  // 获取当前笔画的实时渲染数据（供渲染器每帧使用）
  getCurrentStroke(): StrokeElementData | null {
    if (!this.active) {
      return null;
    }
    this.currentStroke = this.buildElementData(false);
    return this.currentStroke;
  }

  // 重建拟合几何（贝塞尔段 / splat / 轮廓）
  private rebuildGeometry(): void {
    if (this.pathPoints.length < 2) {
      this.cubicSegments = [];
      this.splatPoints = [];
      this.outline = null;
      return;
    }
    this.cubicSegments = this.fitter.fit(this.pathPoints, this.renderSpec.brushWidth, 1.0);
    if (this.renderSpec.isPencil && this.cubicSegments.length > 0) {
      this.splatPoints = this.splatGenerator.generate(this.cubicSegments, this.pathPoints);
    }
    if (this.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH) {
      this.outline = this.outlineBuilder.build(this.pathPoints, this.renderSpec.brushWidth);
    } else {
      this.outline = null;
    }
  }

  private buildElementData(isFinished: boolean): StrokeElementData {
    const bounds: Rect2D = this.computeBounds();
    return {
      id: this.strokeId,
      pathPoints: this.pathPoints,
      cubicSegments: this.cubicSegments,
      splatPoints: this.splatPoints,
      renderSpec: this.renderSpec,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],  // 单位矩阵
      bounds: bounds,
      maskPath: [],
      isFinished: isFinished,
    };
  }

  private computeBounds(): Rect2D {
    // 优先使用可变宽度轮廓点扩展边界（更精确），否则用中心线点
    let left: number;
    let top: number;
    let right: number;
    let bottom: number;
    const half: number = this.renderSpec.brushWidth / 2;
    if (this.outline !== null && this.outline.isValid) {
      left = this.outline.outlinePoints[0].x;
      top = this.outline.outlinePoints[0].y;
      right = left;
      bottom = top;
      for (const p of this.outline.outlinePoints) {
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
    if (this.pathPoints.length === 0) {
      return { left: 0, top: 0, right: 0, bottom: 0 };
    }
    left = this.pathPoints[0].position.x;
    top = this.pathPoints[0].position.y;
    right = left;
    bottom = top;
    for (const p of this.pathPoints) {
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
