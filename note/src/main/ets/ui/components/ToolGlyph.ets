// Original ui_designsystem__<tool>_* layered toolbox glyph (x5f main strip:
// cq.h(m4f, brushColor,…) for color tools, rz1.c(m4f,…) for the rest).
// Renders the full m4f five-layer composite as ArkUI Path layers inside a
// Shape+viewPort 24×24 — tn8 enabled order: fill(e) → overlay(d) →
// highlight(b) → shadow(c) → outline(a). "f" is tinted to the brush color for
// color tools (cq.h) or the content color for the rest (rz1.c).
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
    case ToolType.CALLIGRAPHY: return 'calligraphy';
    case ToolType.SHAPE: return 'shape';
    default: return 'text';
  }
}

// Tools whose fill carries the user's brush color (x5f cq.h brush-color tint).
// 1.4.2 j87.b：calligraphy_* 为彩色书写工具层（fill 取 brushColor）。
const COLOR_GLYPHS: string[] = ['pen', 'pencil', 'highlighter', 'calligraphy', 'shape'];

// tn8 layer tints: overlay/highlight are the theme's light token, shadow the dark
// token. Alpha split by theme (dark ? darkVal : lightVal) from tn8/gt.
const LIGHT_LAYER = '#ffffff';
const DARK_LAYER = '#000000';

function argbToCss(color: number): string {
  return '#' + (color >>> 0).toString(16).padStart(8, '0');
}

@Component
export struct ToolGlyph {
  @Prop glyph: string = 'pen';            // TOOL_GLYPHS key
  @Prop brushColor: number = -16777216;   // tool.brush.color (ARGB)
  @Prop contentColor: ResourceColor = '#171a20'; // outline/foreground (theme-aware)
  @Prop dark: boolean = false;            // theme is dark -> tn8 alpha split
  iconSize: number = 24; // rendered vp size (24 = original 24dp)

  private paths(): ToolGlyphPaths {
    const p: ToolGlyphPaths | undefined = TOOL_GLYPHS[this.glyph];
    return p !== undefined ? p : { f: '', o: '', sw: 1.5, h: '', s: '', v: '', vw: 24, vh: 24 };
  }

  build() {
    // Shape+viewPort establishes a fixed 24×24 user coordinate space that the
    // framework scales onto the iconSize-vp component — deterministic across densities.
    // tn8 enabled-branch draw order: fill -> overlay -> highlight -> shadow -> outline.
    Shape() {
      // e: fill — brush color for color-bearing tools, else content color.
      if (this.paths().f.length > 0) {
        Path()
          .commands(this.paths().f)
          .fill(COLOR_GLYPHS.indexOf(this.glyph) >= 0 ? argbToCss(this.brushColor) : this.contentColor)
          .stroke(Color.Transparent)
      }
      // d: overlay — light sheen regions (alpha 0.75 light / 0.35 dark).
      if (this.paths().v.length > 0) {
        Path()
          .commands(this.paths().v)
          .fill(LIGHT_LAYER)
          .fillOpacity(this.dark ? 0.35 : 0.75)
          .stroke(Color.Transparent)
      }
      // b: highlight — light gloss accents (alpha 0.65 light / 0.5 dark).
      if (this.paths().h.length > 0) {
        Path()
          .commands(this.paths().h)
          .fill(LIGHT_LAYER)
          .fillOpacity(this.dark ? 0.5 : 0.65)
          .stroke(Color.Transparent)
      }
      // c: shadow — dark depth accents (alpha 0.25 light / 0.4 dark).
      if (this.paths().s.length > 0) {
        Path()
          .commands(this.paths().s)
          .fill(DARK_LAYER)
          .fillOpacity(this.dark ? 0.4 : 0.25)
          .stroke(Color.Transparent)
      }
      // a: outline — content-colored stroke on top.
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
    // viewPort = the icon's native vector coordinate space (vw×vh — 24×24 for
    // most glyphs, but e.g. plus=12×12 and search=16×17 keep their own space so
    // the pathData scales correctly onto iconSize).
    .viewPort({ x: 0, y: 0, width: this.paths().vw, height: this.paths().vh })
    .width(this.iconSize)
    .height(this.iconSize)
  }
}
