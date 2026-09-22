// Phase 585 — 原版胶带图案选择器（mh9 → t7f sheet → nh9(patternOrdinal)）。
// Original evidence (decompiled_1.0.3):
//   lfe.a — picker lists the 9 ife patterns in declaration order
//     [STRIPES, GRID, DOTS, PLAIN, STARS, FLOWERS, HEARTS, WAVES, CHECKERS],
//     each swatch tinted with the tool color (j2 = kkf.d(y5f.d(toolState))),
//     current pattern marked selected; click dispatches i31 case26 → nh9(i).
//   lfe.b — the tool-settings row previews the current pattern swatch.
//   ife.I — pattern id = enum ordinal (matches TapePattern 0..8).
//   yh9(i3=1) — g5f.h(state, null, ordinal, 15) copies the tool state with
//     the new tapePattern; ti9.q applies + persists (tool_state.tape_pattern).
import { TapePattern, StrokeElementData, StrokePathPoint, InkStyle } from '../../core/model/StrokeTypes';
import { ToolState } from '../../core/model/BrushTypes';
import { EditorViewModel } from './EditorViewModel';
import { Canvas2DRenderContext, Canvas2DStrokeRenderer } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { BitmapTransferTracker } from '../../core/adaptation/BitmapTransferTracker';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

const TAPE_PATTERN_ORDER: TapePattern[] = [
  TapePattern.STRIPES, TapePattern.GRID, TapePattern.DOTS, TapePattern.PLAIN,
  TapePattern.STARS, TapePattern.FLOWERS, TapePattern.HEARTS, TapePattern.WAVES,
  TapePattern.CHECKERS,
];

function argbToCss(color: number): string {
  const a: number = (color >>> 24) & 0xFF;
  const r: number = (color >>> 16) & 0xFF;
  const g: number = (color >>> 8) & 0xFF;
  const b: number = color & 0xFF;
  return `rgba(${r}, ${g}, ${b}, ${a / 255})`;
}

// lfe.d 等价物：一个胶带图案的小样（带体色 + 图案层）。
function buildSwatchStroke(pattern: TapePattern, color: number,
  x0: number, x1: number, midY: number, bandWidth: number): StrokeElementData {
  const point = (x: number): StrokePathPoint => ({
    position: { x: x, y: midY }, widthFactor: 1, pressure: -1,
    altitudeAngleRadians: -1, azimuthUnitX: 0, azimuthUnitY: 0,
  });
  return {
    id: 'tape-swatch',
    pathPoints: [point(x0), point((x0 + x1) / 2), point(x1)],
    cubicSegments: [],
    splatPoints: [],
    renderSpec: {
      color: color, brushWidth: bandWidth, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false, tapePattern: pattern,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: x0, top: midY - bandWidth / 2, right: x1, bottom: midY + bandWidth / 2 },
    maskPath: [],
    isFinished: true,
  };
}

@Component
struct TapePatternSwatch {
  pattern: TapePattern = TapePattern.STRIPES;
  tapeColor: number = -1706497;
  selected: boolean = false;
  accent: string = '#0A59F7';
  onPick: () => void = () => {
  };
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderer: Canvas2DStrokeRenderer =
    new Canvas2DStrokeRenderer(new BitmapTransferTracker());

  private draw(): void {
    const w: number = this.ctx.width;
    const h: number = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    const bandWidth: number = h * 0.55;
    const midY: number = h / 2;
    // 带体（原版 PLAIN = 纯色胶带；其余图案叠加于带体之上）
    this.ctx.fillStyle = argbToCss(this.tapeColor);
    this.ctx.fillRect(2, midY - bandWidth / 2, w - 4, bandWidth);
    if (this.pattern !== TapePattern.PLAIN) {
      const stroke: StrokeElementData = buildSwatchStroke(
        this.pattern, this.tapeColor, 2, w - 2, midY, bandWidth);
      this.renderer.renderTapePattern(
        stroke, new Canvas2DRenderContext(this.ctx), 1);
    }
  }

  build() {
    Canvas(this.ctx)
      .width(72)
      .height(36)
      .margin(4)
      .borderRadius(4)
      .border({ width: this.selected ? 2 : 1,
        color: this.selected ? this.accent : '#33000000' })
      .onReady((): void => this.draw())
      .onClick((): void => this.onPick())
  }
}

@Component
export struct TapePatternPicker {
  // 目标工具行（REVIEW）——选择写入该行并持久化。
  tool: ToolState | null = null;
  @ObjectLink viewModel: EditorViewModel;
  accent: string = '#0A59F7';
  onClose: () => void = () => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private pick(pattern: TapePattern): void {
    const tool: ToolState | null = this.tool;
    if (tool === null) {
      this.onClose();
      return;
    }
    this.viewModel.setToolTapePattern(tool.toolId, pattern).then((): void => this.onClose());
  }

  build() {
    Column() {
      Row() {
        Button('‹')
          .fontSize(16)
          .height(32)
          .accessibilityText($r('app.string.back'))
          .onClick((): void => this.onClose())
        Text($r('app.string.tape_patterns'))
          .fontSize(16)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(TAPE_PATTERN_ORDER, (pattern: TapePattern) => {
          TapePatternSwatch({
            pattern: pattern,
            tapeColor: this.tool === null ? -1706497 : this.tool.brush.color,
            selected: this.tool !== null && this.tool.tapePattern === pattern,
            accent: this.accent,
            onPick: (): void => this.pick(pattern),
          })
        }, (pattern: TapePattern): string => pattern.toString())
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
  }
}
