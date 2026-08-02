// T-019 编辑器状态管理（@Observed）
import { ToolType, BrushStyle, brushStyleToInkStyle } from '../../core/model/BrushTypes';
import { RenderSpec } from '../../core/model/StrokeTypes';

@Observed
export class EditorViewModel {
  currentTool: ToolType = ToolType.PEN;
  brushStyle: BrushStyle = BrushStyle.MONO;
  brushColor: number = -16777216;  // 黑
  brushWidth: number = 36.0;
  eraserIsPartial: boolean = false;
  selectionIsFreehand: boolean = false;
  showColorPicker: boolean = false;
  showWidthSlider: boolean = false;
  shapeDetectionEnabled: boolean = true;

  // 从当前状态构建 RenderSpec
  getRenderSpec(): RenderSpec {
    return {
      color: this.brushColor,
      brushWidth: this.brushWidth,
      inkStyle: brushStyleToInkStyle(this.brushStyle),
      isHighlighter: this.currentTool === ToolType.HIGHLIGHTER,
      isPencil: this.currentTool === ToolType.PENCIL,
    };
  }

  selectTool(tool: ToolType): void {
    this.currentTool = tool;
    this.showColorPicker = false;
    this.showWidthSlider = false;
  }

  isEraserActive(): boolean {
    return this.currentTool === ToolType.PARTIAL_ERASER || this.currentTool === ToolType.WHOLE_ERASER;
  }

  isSelectionActive(): boolean {
    return this.currentTool === ToolType.SELECTION;
  }

  // ARGB int → '#RRGGBB'
  colorToHex(argb: number): string {
    const r: number = (argb >>> 16) & 0xFF;
    const g: number = (argb >>> 8) & 0xFF;
    const b: number = argb & 0xFF;
    const toHex = (v: number): string => {
      const s: string = v.toString(16);
      return s.length === 1 ? '0' + s : s;
    };
    return '#' + toHex(r) + toHex(g) + toHex(b);
  }
}
