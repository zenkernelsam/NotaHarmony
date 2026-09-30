// Original ui_designsystem__<tool>_* layered toolbox glyph (x5f main strip:
// cq.h(m4f, brushColor,…) for color tools, rz1.c(m4f,…) for the rest).
// Rendered as ArkUI Path layers — "f" body filled with the brush color
// (pen/pencil/highlighter) or content color (others), "o" stroked with the
// content color on top. 24×24 viewport matches the original 24dp.
import { ToolType } from '../../core/model/BrushTypes';
import { TOOL_GLYPHS, ToolGlyphPaths } from './ToolGlyphs';

// ToolType -> ui_designsystem__<key> glyph name (ho5 toolbox icon set).
export function toolGlyphKey(toolType: ToolType): string {
  switch (toolType) {
    case ToolType.PEN: return 'pen';
    case ToolType.PENCIL: return 'pencil';
    case ToolType.HIGHLIGHTER: return 'highlighter';
    case ToolType.WHOLE_ERASER: return 'eraser';
    case ToolType.PARTIAL_ERASER: return 'eraser_partial';
    case ToolType.SELECTION: return 'selectrectangle';
    case ToolType.LASER: return 'laser';
    case ToolType.ZOOM: return 'zoom';
    case ToolType.REVIEW: return 'tape';
    default: return 'text';
  }
}

// Tools whose fill carries the user's brush color (x5f cq.h brush-color tint).
const COLOR_GLYPHS: string[] = ['pen', 'pencil', 'highlighter'];

function argbToCss(color: number): string {
  return '#' + (color >>> 0).toString(16).padStart(8, '0');
}

@Component
export struct ToolGlyph {
  @Prop glyph: string = 'pen';            // TOOL_GLYPHS key
  @Prop brushColor: number = -16777216;   // tool.brush.color (ARGB)
  @Prop contentColor: string = '#171a20'; // outline/foreground (theme-aware)
  iconSize: number = 24; // rendered vp size (24 = original 24dp)

  private paths(): ToolGlyphPaths {
    const p: ToolGlyphPaths | undefined = TOOL_GLYPHS[this.glyph];
    return p !== undefined ? p : { f: '', o: '', sw: 1.5 };
  }

  build() {
    // Shape+viewPort establishes a fixed 24×24 user coordinate space that the
    // framework scales onto the `size`vp component — deterministic across densities.
    Shape() {
      // fill layer — brush color for color-bearing tools, else content color.
      if (this.paths().f.length > 0) {
        Path()
          .commands(this.paths().f)
          .fill(COLOR_GLYPHS.indexOf(this.glyph) >= 0 ? argbToCss(this.brushColor) : this.contentColor)
          .stroke(Color.Transparent)
      }
      // outline layer — content-colored stroke on top.
      if (this.paths().o.length > 0) {
        Path()
          .commands(this.paths().o)
          .fill(Color.Transparent)
          .stroke(this.contentColor)
          .strokeWidth(this.paths().sw)
          .strokeLineCap(LineCapStyle.Round)
          .strokeLineJoin(LineJoinStyle.Round)
      }
    }
    .viewPort({ x: 0, y: 0, width: 24, height: 24 })
    .width(this.iconSize)
    .height(this.iconSize)
  }
}
