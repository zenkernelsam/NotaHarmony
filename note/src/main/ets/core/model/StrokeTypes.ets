// T-001 笔画/输入类型（契约 phase-1-data-model.md §3.2，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D, CubicSegment, Rect2D, TransformMatrix } from './GeometryTypes';

// 输入工具类型（对应 AndroidX Ink InputToolType）
export enum InputToolType {
  STYLUS = 0,
  MOUSE = 1,
  TOUCH = 2,
}

// 单个输入采样点（对应 hda.v() → StrokeInput）
export interface InputPoint {
  x: number;
  y: number;
  elapsedTimeMillis: number;
  toolType: InputToolType;
  pressure: number;         // [0,1]，无能力时 -1
  tiltRadians: number;      // [0, π/2]，无能力时 -1
  orientationRadians: number; // [0, 2π)，无能力时 -1
}

// 输入批次（区分真实/历史/预测）
export enum InputBatchKind {
  REAL = 0,       // 真实采样点（持久化）
  HISTORICAL = 1, // 历史点（持久化）
  PREDICTED = 2,  // 预测点（仅渲染预览，不持久化）
}

export interface InputBatch {
  kind: InputBatchKind;
  points: InputPoint[];
}

// 铅笔飞溅点（对应 faa）
export interface PencilSplatPoint {
  x: number;
  y: number;
  rotation: number;  // 弧度
  scale: number;
  opacity: number;   // [0,1]
}

// 持久化笔画点（对应 vm4/r4a + 三次贝塞尔分段）
export interface StrokePathPoint {
  position: Point2D;
  widthFactor: number;  // fc0.e() 逐点宽度因子，默认 1.0
}

// 渲染规格（对应 vzf WetMirrorRenderSpec）
export interface RenderSpec {
  color: number;             // ARGB 整数
  brushWidth: number;        // 基础笔宽
  inkStyle: InkStyle;
  isHighlighter: boolean;
  isPencil: boolean;
}

// 墨水样式（对应 sz5）
export enum InkStyle {
  FIXED_WIDTH = 0,
  VARIABLE_WIDTH = 1,
  DASH = 2,
  DOTS = 3,
}

// 渲染态笔画（对应 s78 的移植等价物）
export interface StrokeElementData {
  id: string;
  pathPoints: StrokePathPoint[];       // 中心线点序列
  cubicSegments: CubicSegment[];       // 拟合后的贝塞尔段
  splatPoints: PencilSplatPoint[];     // 铅笔专用（非铅笔为空）
  renderSpec: RenderSpec;              // 渲染规格
  transform: TransformMatrix;          // 统一变换矩阵
  bounds: Rect2D;                      // 边界盒
  maskPath: Point2D[];                 // 擦除遮罩点（可选）
  isFinished: boolean;
}
