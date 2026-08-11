// T-019 编辑器工具栏（工具切换 + 颜色/粗细面板 + Undo/Redo 占位）
// T-038：工具栏 surface 随主题
import { BrushStyle, ToolType } from '../../core/model/BrushTypes';
import { EditorViewModel } from './EditorViewModel';
import { ColorPickerView } from '../components/ColorPicker';
import { WidthSlider } from '../components/WidthSlider';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Component
export struct EditorToolbar {
  @ObjectLink viewModel: EditorViewModel;
  @State compact: boolean = false;
  private toolbarScroller: Scroller = new Scroller();
  // Undo/Redo 回调（T-021 实现功能）
  onUndo: () => void = () => {
  };
  onRedo: () => void = () => {
  };
  onSelectionStyle: (style: BrushStyle) => void = (_style: BrushStyle): void => {
  };
  @Prop canUndo: boolean = false;
  @Prop canRedo: boolean = false;
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Scroll(this.toolbarScroller) {
        Row() {
        // === 工具按钮（48vp 点击区）===
        this.ToolButton($r('app.string.pen'), ToolType.PEN)
        this.ToolButton($r('app.string.pencil'), ToolType.PENCIL)
        this.ToolButton($r('app.string.highlighter'), ToolType.HIGHLIGHTER)
          if (this.compact) {
            this.ToolButton($r('app.string.eraser'), this.viewModel.eraserIsPartial ?
              ToolType.PARTIAL_ERASER : ToolType.WHOLE_ERASER)
            Button('...')
              .height(40)
              .fontSize(13)
              .margin({ left: 2, right: 2 })
              .enabled(!this.viewModel.toolStateLoading)
              .accessibilityText($r('app.string.more_tools'))
              .bindMenu(this.buildCompactToolMenu())
          } else {
            this.ToolButton($r('app.string.whole_eraser'), ToolType.WHOLE_ERASER)
            this.ToolButton($r('app.string.partial_eraser'), ToolType.PARTIAL_ERASER)
            this.ToolButton($r('app.string.selection'), ToolType.SELECTION)
            this.ToolButton($r('app.string.text'), ToolType.DEFAULT)
          }

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        // 颜色按钮（当前色圆点）
        Button()
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.viewModel.colorToHex(this.viewModel.brushColor))
          .margin({ left: 4, right: 4 })
          .enabled(this.viewModel.supportsBrushControls() && !this.viewModel.toolStateLoading)
          .opacity(this.viewModel.supportsBrushControls() && !this.viewModel.toolStateLoading ? 1 : 0.4)
          .onClick(() => {
            this.viewModel.showColorPicker = !this.viewModel.showColorPicker;
            this.viewModel.showWidthSlider = false;
          })

        // 粗细按钮（当前宽度指示）
        Button(Math.round(this.viewModel.brushWidth).toString())
          .width(48)
          .height(32)
          .fontSize(13)
          .margin({ left: 4, right: 4 })
          .enabled(this.viewModel.supportsBrushControls() && !this.viewModel.toolStateLoading)
          .opacity(this.viewModel.supportsBrushControls() && !this.viewModel.toolStateLoading ? 1 : 0.4)
          .onClick(() => {
            this.viewModel.showWidthSlider = !this.viewModel.showWidthSlider;
            this.viewModel.showColorPicker = false;
          })

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        // Undo / Redo（T-021 实现功能）
        Button('↶')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canUndo)
          .opacity(this.canUndo ? 1 : 0.4)
          .onClick(() => {
            this.onUndo();
          })
        Button('↷')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canRedo)
          .opacity(this.canRedo ? 1 : 0.4)
          .onClick(() => {
            this.onRedo();
          })
        }
        .height(48)
        .padding({ left: 8, right: 8 })
        .backgroundColor(this.resolveTokens().surface)
      }
      .width('100%')
      .height(48)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      // 弹层（颜色/粗细面板）
      if (this.viewModel.showColorPicker) {
        Row() {
          ColorPickerView({ viewModel: this.viewModel })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      if (this.viewModel.showWidthSlider) {
        Row() {
          WidthSlider({ viewModel: this.viewModel })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      if (this.viewModel.supportsBrushControls()) {
        Row() {
          this.StyleButton($r('app.string.style_mono'), BrushStyle.MONO)
          this.StyleButton($r('app.string.style_taper'), BrushStyle.TAPER)
          this.StyleButton($r('app.string.style_dash'), BrushStyle.DASH)
          this.StyleButton($r('app.string.style_dots'), BrushStyle.DOT)
        }
        .width('100%')
        .height(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.viewModel.isSelectionActive()) {
        Column() {
          Row() {
            Text($r('app.string.selection'))
            Button(this.viewModel.selectionIsFreehand ? $r('app.string.freehand') : $r('app.string.rectangle'))
              .height(30)
              .margin({ left: 12 })
              .onClick(() => {
                this.viewModel.setSelectionIsFreehand(!this.viewModel.selectionIsFreehand);
              })
          }
          Row() {
            this.SelectionStyleButton($r('app.string.style_mono'), BrushStyle.MONO)
            this.SelectionStyleButton($r('app.string.style_taper'), BrushStyle.TAPER)
            this.SelectionStyleButton($r('app.string.style_dash'), BrushStyle.DASH)
            this.SelectionStyleButton($r('app.string.style_dots'), BrushStyle.DOT)
          }
        }
        .width('100%')
        .height(72)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.compact = (newArea.width as number) < 600;
    })
  }

  private buildCompactToolMenu(): MenuElement[] {
    return [
      { value: $r('app.string.whole_eraser'), action: () => { this.viewModel.selectTool(ToolType.WHOLE_ERASER); } },
      { value: $r('app.string.partial_eraser'), action: () => { this.viewModel.selectTool(ToolType.PARTIAL_ERASER); } },
      { value: $r('app.string.selection'), action: () => { this.viewModel.selectTool(ToolType.SELECTION); } },
      { value: $r('app.string.text'), action: () => { this.viewModel.selectTool(ToolType.DEFAULT); } },
    ];
  }

  @Builder
  ToolButton(label: ResourceStr, tool: ToolType) {
    Button(label)
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.currentTool === tool ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.viewModel.currentTool === tool ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading)
      .onClick(() => {
        this.viewModel.selectTool(tool);
      })
  }

  @Builder
  StyleButton(label: ResourceStr, style: BrushStyle) {
    Button(label)
      .height(30)
      .fontSize(12)
      .borderRadius(4)
      .margin({ left: 2, right: 2 })
      .backgroundColor(this.viewModel.brushStyle === style ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.viewModel.brushStyle === style ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .enabled(!this.viewModel.toolStateLoading)
      .onClick(() => {
        this.viewModel.setBrushStyle(style);
      })
  }

  @Builder
  SelectionStyleButton(label: ResourceStr, style: BrushStyle) {
    Button(label)
      .height(30)
      .fontSize(12)
      .borderRadius(4)
      .margin({ left: 2, right: 2 })
      .backgroundColor(this.resolveTokens().control)
      .fontColor(this.resolveTokens().textPrimary)
      .enabled(!this.viewModel.toolStateLoading)
      .onClick(() => {
        this.onSelectionStyle(style);
      })
  }
}
