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
