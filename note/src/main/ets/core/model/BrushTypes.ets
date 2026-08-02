// T-002 笔刷与工具类型（契约 phase-1-data-model.md §3.3，照搬，禁止修改签名）
// 纯类型文件：禁止 import 任何 @ohos.* / @kit.* 平台模块
import { InkStyle } from './StrokeTypes';

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
}

// 笔刷配置（对应 f21 Brush）
export interface BrushSpec {
  brushStyle: BrushStyle;
  widthSize: number;               // 默认 36.0
  color: number;                   // ARGB，默认 -16777216（黑）
  selectedWidthWellIndex: number;
  selectedColorWellIndex: number;
}

// 工具状态（对应 j0f/jze）
export interface ToolState {
  toolId: string;
  trayOwnerId: string;
  toolType: ToolType;
  trayIndex: number;
  brush: BrushSpec;
  selectionIsFreehand: boolean;
  eraserIsPartial: boolean;
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
