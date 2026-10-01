// Phase 1389 — 1.4.2 SHAPE 种类选择器（h5g.java：每类渲染 shape 图标 + 标签，
// 选中标记；点击写回 ToolStateEntity.shapeKind）。
// Original evidence (decompiled_1.4.2):
//   h5g.java:154-170 — 6 类按 r5g ordinal 取标签
//     [RECTANGLE, ELLIPSE, DIAMOND, TRIANGLE, ARROW, LINE]；
//   i87.b — 每项 = 24dp 形状图标 + 文字标签，当前种类高亮选中；
//   cc3.H() 默认 RECTANGLE；shapeKind 列以枚举名 TEXT 持久化（fgf.java）。
// 图标用 buildDragShape 在样片坐标内成形，经 ShapeCanvasRenderer 渲染。
import { ShapeKind, ToolState } from '../../core/model/BrushTypes';
import { ShapeElement } from '../../core/model/ElementTypes';
import { Point2D } from '../../core/model/GeometryTypes';
import { buildDragShape } from '../../core/model/ShapeDragGeometry';
import { EditorViewModel } from './EditorViewModel';
import { Canvas2DRenderContext, Canvas2DStrokeRenderer } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { ShapeCanvasRenderer } from '../../rendering/ShapeCanvasRenderer';
import { BitmapTransferTracker } from '../../core/adaptation/BitmapTransferTracker';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

// r5g 声明序（ordinal 0..5）。
export const SHAPE_KIND_ORDER: ShapeKind[] = [
  ShapeKind.RECTANGLE, ShapeKind.ELLIPSE, ShapeKind.DIAMOND,
  ShapeKind.TRIANGLE, ShapeKind.ARROW, ShapeKind.LINE,
];

function shapeKindLabel(kind: ShapeKind): Resource {
  switch (kind) {
    case ShapeKind.RECTANGLE: return $r('app.string.shape_rectangle');
    case ShapeKind.ELLIPSE: return $r('app.string.shape_ellipse');
    case ShapeKind.DIAMOND: return $r('app.string.shape_diamond');
    case ShapeKind.TRIANGLE: return $r('app.string.shape_triangle');
    case ShapeKind.ARROW: return $r('app.string.shape_arrow');
    case ShapeKind.LINE: return $r('app.string.shape_line');
    default: return $r('app.string.shape_rectangle');
  }
}

// 1.4.2 h5g.b：编辑器次级条的 48×48 图标格（compact 时无文字标签，
// a11y 仍用 ui_tools__shape_* 名）。
@Component
export struct ShapeKindSwatch {
  kind: ShapeKind = ShapeKind.RECTANGLE;
  shapeColor: number = -16777216;
  selected: boolean = false;
  accent: string = '#0A59F7';
  textColor: string = '#000000';
  compact: boolean = false;
  onPick: () => void = () => {
  };
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private strokeRenderer: Canvas2DStrokeRenderer =
    new Canvas2DStrokeRenderer(new BitmapTransferTracker());
  private shapeRenderer: ShapeCanvasRenderer = new ShapeCanvasRenderer(this.strokeRenderer);

  private draw(): void {
    const w: number = this.ctx.width;
    const h: number = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    const m: number = 6;
    const strokeW: number = 2.0;
    const start: Point2D = { x: m, y: m };
    const end: Point2D = { x: w - m, y: h - m };
    const shape: ShapeElement | null = buildDragShape(
      this.kind, start, end, this.shapeColor, strokeW);
    if (shape !== null) {
      this.shapeRenderer.renderShape(shape, new Canvas2DRenderContext(this.ctx), 1);
    }
  }

  build() {
    Column() {
      Canvas(this.ctx)
        .width(this.compact ? 36 : 56)
        .height(this.compact ? 36 : 40)
        .borderRadius(4)
        .border({ width: this.selected ? 2 : 1,
          color: this.selected ? this.accent : '#33000000' })
        .onReady((): void => this.draw())
        .onClick((): void => this.onPick())
      if (!this.compact) {
        Text(shapeKindLabel(this.kind))
          .fontSize(11)
          .fontColor(this.textColor)
          .margin({ top: 3 })
          .maxLines(1)
      }
    }
    // h5g 单元格：compact 时 36dp 图标 + 2 边距（适配 40dp 次级条行高）。
    .justifyContent(FlexAlign.Center)
    .padding(this.compact ? 2 : 4)
    .accessibilityText(shapeKindLabel(this.kind))
    .onClick((): void => this.onPick())
  }
}

@Component
export struct ShapeKindPicker {
  // 目标工具行（SHAPE）——选择写入该行并持久化。
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

  private pick(kind: ShapeKind): void {
    const tool: ToolState | null = this.tool;
    if (tool === null) {
      this.onClose();
      return;
    }
    this.viewModel.setToolShapeKind(tool.toolId, kind).then((): void => this.onClose());
  }

  build() {
    Column() {
      Row() {
        Button() {
          ToolGlyph({
            glyph: 'chevron_left',
            contentColor: this.resolveTokens().textPrimary,
            iconSize: 22,
          })
        }
          .height(32)
          .accessibilityText($r('app.string.back'))
          .onClick((): void => this.onClose())
        Text($r('app.string.shape'))
          .fontSize(16)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(SHAPE_KIND_ORDER, (kind: ShapeKind) => {
          ShapeKindSwatch({
            kind: kind,
            shapeColor: this.tool === null ? -16777216 : this.tool.brush.color,
            selected: this.tool !== null && this.tool.shapeKind === kind,
            accent: this.accent,
            textColor: this.resolveTokens().textPrimary,
            onPick: (): void => this.pick(kind),
          })
        }, (kind: ShapeKind): string => kind.toString())
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
  }
}
