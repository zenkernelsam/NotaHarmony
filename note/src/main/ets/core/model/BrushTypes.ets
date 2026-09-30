// T-002 笔刷与工具类型（契约 phase-1-data-model.md §3.3，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { InkStyle, TapePattern } from './StrokeTypes';

// 笔刷样式（对应 z21）
export enum BrushStyle {
  MONO = 0,    // → FIXED_WIDTH
  TAPER = 1,   // → VARIABLE_WIDTH
  DASH = 2,    // → DASH
  DOT = 3,     // → DOTS
}

// 工具类型（对应 zy5）
export enum ToolType {
  DEFAULT = 0,
  SELECTION = 1,
  PARTIAL_ERASER = 2,
  PEN = 3,
  HIGHLIGHTER = 4,
  PENCIL = 5,
  REVIEW = 6,
  WHOLE_ERASER = 7,
  // 原版 a6f.R = LASER：瞬态指示笔，不产生持久笔画。
  LASER = 8,
  // 原版 a6f.U = ZOOM：放大书写视口（ac4.F ZOOM_VIEW → "androidZoomView"，
  // 打包默认 true → 1.0.3 默认可见，见 ADR-0690 更正 ADR-0644）。
  ZOOM = 9,
  // 1.4.2 eti.G = CALLIGRAPHY：平头笔（凿尖 nib）专用工具，介于 PEN 与 PENCIL 之间。
  // 笔画宽度随运笔方向相对 nib 角/扁率变化（nibAngle/nibFlatness）。
  CALLIGRAPHY = 10,
  // 1.4.2 eti.T = SHAPE：拖拽成形工具——按下拖拽出包围盒，松手提交
  // RECTANGLE/ELLIPSE/DIAMOND/TRIANGLE/ARROW/LINE（r5g）形状元素。
  SHAPE = 11,
  // 原版 a6f 另两个成员不移植（ADR-0644/0642）：
  //   a6f.Q POINTER=多人 presence 光标（ac4.c0/b0 服务端协作域 fail-closed）
  //   a6f.T RULER=s01.a0 无条件隐藏（原版即不可见）
}

// 1.4.2 r5g 形状种类（SHAPE 工具的子模式，ordinal 与原版一致）。
// RECTANGLE/ELLIPSE/DIAMOND/TRIANGLE 由拖拽包围盒成形；ARROW/LINE 为起点→终点线段。
export enum ShapeKind {
  RECTANGLE = 0,
  ELLIPSE = 1,
  DIAMOND = 2,
  TRIANGLE = 3,
  ARROW = 4,
  LINE = 5,
}

// 笔刷配置（对应 f21 Brush）
export interface BrushSpec {
  brushStyle: BrushStyle;
  widthSize: number;               // 默认 36.0
  color: number;                   // ARGB，默认 -16777216（黑）
  selectedWidthWellIndex: number;
  selectedColorWellIndex: number;
}

// Original cgf tray ordinals (zff.a: Primary/Secondary/Hidden). Tray membership is
// the original's tool-visibility mechanism; there is no separate "hidden" flag.
export const TRAY_TYPE_PRIMARY: number = 0;
export const TRAY_TYPE_SECONDARY: number = 1;
export const TRAY_TYPE_HIDDEN: number = 2;
// o6f.java:142 / wb4.java:127 — the original caps the Primary tray at 12 tools.
export const MAX_PRIMARY_TOOLS: number = 12;

// 工具状态（对应 j0f/jze / u5f ToolStateEntity）
export interface ToolState {
  toolId: string;
  trayOwnerId: string;
  toolType: ToolType;
  // Original tray_owner_id → TrayEntity membership, stored as the cgf ordinal.
  trayType: number;
  trayIndex: number;
  brush: BrushSpec;
  // Original ToolStateEntity.tapePattern (e47.java): nullable — only the REVIEW/tape
  // tool sets it; NULL for every other tool. STRIPES..CHECKERS (0..8).
  tapePattern?: TapePattern | null;
  selectionIsFreehand: boolean;
  eraserIsPartial: boolean;
  // 1.4.2 ToolStateEntity.nibAngle / nibFlatness (REAL)：仅 CALLIGRAPHY 工具使用，
  // NULL 其余工具。nibAngle 弧度制；nibFlatness∈(0,1]，1=圆头（无方向差）。
  nibAngle?: number | null;
  nibFlatness?: number | null;
  // 1.4.2 ToolStateEntity.shapeKind (TEXT DEFAULT 'RECTANGLE')：仅 SHAPE 工具使用，
  // NULL 其余工具。
  shapeKind?: ShapeKind | null;
  // 1.4.2 ToolStateEntity.stabilization (INTEGER)：笔画防抖开关，CALLIGRAPHY 默认 1。
  // NULL 其余工具。
  stabilization?: number | null;
}

// 1.4.2 ToolStateEntity.shapeKind 以枚举名 TEXT 持久化（'RECTANGLE'…'LINE'）。
// 与 r5g.java ordinal 对齐：name→kind、kind→name 双向映射。
const SHAPE_KIND_NAMES: string[] = [
  'RECTANGLE', 'ELLIPSE', 'DIAMOND', 'TRIANGLE', 'ARROW', 'LINE'];

export function shapeKindToName(kind: ShapeKind): string {
  const idx: number = kind;
  return idx >= 0 && idx < SHAPE_KIND_NAMES.length ? SHAPE_KIND_NAMES[idx] : 'RECTANGLE';
}

export function shapeKindFromName(name: string | null | undefined): ShapeKind | null {
  if (name === null || name === undefined) {
    return null;
  }
  const idx: number = SHAPE_KIND_NAMES.indexOf(name);
  return idx >= 0 ? idx as ShapeKind : null;
}

// Harmony adaptation of the original ToolboxEntity selection history.
export interface EditorToolboxState {
  ownerId: string;
  mostRecentlySelectedToolId: string;
  previouslySelectedToolId: string;
}

// Harmony adaptation of the original TrayEntity (e47.java:380). The original
// writes lastUsedToolId on every tool selection (i8f.g).
export interface EditorTray {
  trayId: number;
  trayType: number;
  toolboxOwnerId: string;
  lastUsedToolId: string | null;
}

// BrushStyle → InkStyle 映射（对应 dxe.a()）
export function brushStyleToInkStyle(style: BrushStyle): InkStyle {
  switch (style) {
    case BrushStyle.MONO: return InkStyle.FIXED_WIDTH;
    case BrushStyle.TAPER: return InkStyle.VARIABLE_WIDTH;
    case BrushStyle.DASH: return InkStyle.DASH;
    case BrushStyle.DOT: return InkStyle.DOTS;
    default: return InkStyle.FIXED_WIDTH;
  }
}

export function inkStyleToBrushStyle(style: InkStyle): BrushStyle {
  switch (style) {
    case InkStyle.VARIABLE_WIDTH: return BrushStyle.TAPER;
    case InkStyle.DASH: return BrushStyle.DASH;
    case InkStyle.DOTS: return BrushStyle.DOT;
    default: return BrushStyle.MONO;
  }
}
