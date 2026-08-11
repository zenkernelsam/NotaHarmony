// T-001 笔画/输入类型（契约 phase-1-data-model.md §3.2，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { Point2D, CubicSegment, Rect2D, TransformMatrix } from './GeometryTypes';

// maskPath 中相邻两次独立像素擦除的分段哨兵。使用可 JSON 往返的有限值，
// 避免 NaN 被序列化为 null 后破坏持久化数据。
export const ERASER_PATH_BREAK_COORDINATE: number = Number.MAX_VALUE;

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
  pressure: number;  // 原版 cd0.d() force；无能力时 -1
  altitudeAngleRadians: number;  // 原版 cd0.a()，笔杆与屏幕平面的夹角；无能力时 -1
  azimuthUnitX: number;  // 原版 cd0.b()，笔杆方位角单位向量 X；无能力时 0
  azimuthUnitY: number;  // 原版 cd0.c()，笔杆方位角单位向量 Y；无能力时 0
}

// 渲染规格（对应 vzf WetMirrorRenderSpec）
export interface RenderSpec {
  color: number;             // ARGB 整数
  brushWidth: number;        // 基础笔宽
  inkStyle: InkStyle;
  isHighlighter: boolean;
  isPencil: boolean;
  // Original Ink effects are a uint64 bitmask (RAINBOW=1, GLITTER=2). Keep the
  // decimal string precision-safe even when the current renderer cannot shade them yet.
  inkEffects?: string;
  inkEffectsTinted?: boolean;
  inkEffectPhase?: number;
  // Presence identifies an original Tape stroke. CREATE defaults missing Tape fields to STRIPES.
  tapePattern?: TapePattern;
}

export enum TapePattern {
  STRIPES = 0,
  GRID = 1,
  DOTS = 2,
  PLAIN = 3,
  STARS = 4,
  FLOWERS = 5,
  HEARTS = 6,
  WAVES = 7,
  CHECKERS = 8,
}

// 墨水样式（对应 sz5）
export enum InkStyle {
  FIXED_WIDTH = 0,
  VARIABLE_WIDTH = 1,
  DASH = 2,
  DOTS = 3,
}

// Original encoded custom/fill paths preserve Android Path verbs. Unlike the center path,
// these paths may contain multiple move-to components and do not carry stroke attributes.
export enum InkPathCommandType {
  MOVE_TO = 0,
  LINE_TO = 1,
  QUADRATIC = 2,
  CUBIC = 3,
}

export interface InkPathCommand {
  type: InkPathCommandType;
  points: Point2D[];
}

// Original yyd is a 20-byte inline struct, one entry per center-path component.
// The backing values keep Pencil scatter and dashed strokes stable after edits/copies.
export interface InkStyleMapEntry {
  backingPencilSeed: number;
  backingPencilReferencePoint: Point2D;
  backingDashPhase: number;
  backingDashPeriod: number;
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
  maskPath: Point2D[];                 // 擦除遮罩点；独立路径间用 ERASER_PATH_BREAK_COORDINATE 分隔
  customPath?: InkPathCommand[] | null; // 原版显式笔迹轮廓；缺席时由中心线和宽度生成
  fillPath?: InkPathCommand[] | null;   // 原版填充区域；缺席时回退中心线
  fillColor?: number | null;            // 原版可空内部填充色
  styleMap?: InkStyleMapEntry[];        // 原版每个 center-path component 的稳定渲染状态
  isFinished: boolean;
}
