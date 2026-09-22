// T-019 编辑器工具栏（工具切换 + 颜色/粗细面板 + Undo/Redo 占位）
// T-038：工具栏 surface 随主题
import { BrushStyle, ToolState, ToolType } from '../../core/model/BrushTypes';
import { EditorViewModel } from './EditorViewModel';
import { ToolboxSettingsDialog, toolTypeLabel } from './ToolboxSettingsDialog';
import { ColorPickerView } from '../components/ColorPicker';
import { WidthSlider } from '../components/WidthSlider';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Component
export struct EditorToolbar {
  @ObjectLink viewModel: EditorViewModel;
  @State compact: boolean = false;
  @State showToolSettings: boolean = false;
  private toolbarScroller: Scroller = new Scroller();
  // Undo/Redo 回调（T-021 实现功能）
  onUndo: () => void = () => {
  };
  onRedo: () => void = () => {
  };
  onInsertMath: () => void = () => {
  };
  onInsertPhotos: () => void = () => {
  };
  onTakePhoto: () => void = () => {
  };
  onSelectionStyle: (style: BrushStyle) => void = (_style: BrushStyle): void => {
  };
  onSelectionColor: (color: number) => void = (_color: number): void => {
  };
  onSelectionWidth: (width: number) => void = (_width: number): void => {
  };
  @Prop selectionColor: number = -16777216;
  @Prop selectionWidth: number = 5;
  @Prop selectionWidthMinimum: number = 0.5;
  @Prop selectionWidthMaximum: number = 30;
  @Prop photoImportLeaseActive: boolean = false;
  @Prop selectionVariableStyleEnabled: boolean = true;
  @Prop selectionStyle: BrushStyle = BrushStyle.MONO;
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
        // === 工具按钮（48vp 点击区）：按原版托盘顺序渲染可见工具 ===
        ForEach(this.viewModel.visibleToolStates(), (state: ToolState) => {
          if (state.toolType === ToolType.WHOLE_ERASER) {
            if (this.compact) {
              this.StateToolButton($r('app.string.eraser'), state)
            } else {
              this.EraserToolButtons(state)
            }
          } else {
            this.StateToolButton(toolTypeLabel(state.toolType), state)
          }
        }, (state: ToolState): string => state.toolId)
          if (this.compact) {
            Button('...')
              .height(40)
              .fontSize(13)
              .margin({ left: 2, right: 2 })
              .enabled(!this.viewModel.toolStateLoading &&
                !this.photoImportLeaseActive)
              // 原版 feature_note__toolbar_more_menu：溢出菜单描述为
              // "More options"。
              .accessibilityText($r('app.string.toolbar_more_menu'))
              .bindMenu(this.buildCompactToolMenu())
          }
          // 原版 toolbox settings 入口（o6f 工具设置页）
          Button('⚙')
            .height(40)
            .fontSize(15)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .accessibilityText($r('app.string.toolbox_settings'))
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.showToolSettings = true;
            })

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        // 颜色按钮（当前色圆点）
        Button()
          .width(32)
          .height(32)
          .borderRadius(16)
          // 原版 feature_note__cd_quick_tool_color：色板按钮描述为 "Color"。
          .accessibilityText($r('app.string.cd_quick_tool_color'))
          .backgroundColor(this.viewModel.colorToHex(this.viewModel.isSelectionActive() ?
            this.selectionColor : this.viewModel.brushColor))
          .margin({ left: 4, right: 4 })
          .enabled((this.viewModel.supportsBrushControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading &&
            !this.photoImportLeaseActive)
          .opacity((this.viewModel.supportsBrushControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading ? 1 : 0.4)
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.viewModel.showColorPicker = !this.viewModel.showColorPicker;
            this.viewModel.showWidthSlider = false;
          })

        // 粗细按钮（当前宽度指示）
        Button((this.viewModel.isSelectionActive() ? this.selectionWidth :
          Math.round(this.viewModel.brushWidth)).toString())
          .width(48)
          .height(32)
          .fontSize(13)
          .margin({ left: 4, right: 4 })
          .enabled((this.viewModel.supportsBrushControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading &&
            !this.photoImportLeaseActive)
          .opacity((this.viewModel.supportsBrushControls() || this.viewModel.isSelectionActive()) &&
            !this.viewModel.toolStateLoading ? 1 : 0.4)
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.viewModel.showWidthSlider = !this.viewModel.showWidthSlider;
            this.viewModel.showColorPicker = false;
          })

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        if (!this.compact) {
          Button($r('app.string.insert_photo'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onInsertPhotos();
            })
          // 原版插入菜单序位：Add Photo → Take Photo → Math（qc.java）
          Button($r('app.string.take_photo'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onTakePhoto();
            })
          Button($r('app.string.insert_math'))
            .height(32)
            .fontSize(13)
            .margin({ left: 2, right: 2 })
            .enabled(!this.viewModel.toolStateLoading &&
              !this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.onInsertMath();
            })
          Divider().vertical(true).height(24).margin({ left: 8, right: 8 })
        }

        // Undo / Redo（T-021 实现功能）
        Button('↶')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canUndo &&
            !this.photoImportLeaseActive)
          .opacity(this.canUndo ? 1 : 0.4)
          // 原版 feature_note__toprighttoolbar_undo_action：撤销按钮描述。
          .accessibilityText($r('app.string.cd_undo_action'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.onUndo();
          })
        Button('↷')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canRedo &&
            !this.photoImportLeaseActive)
          .opacity(this.canRedo ? 1 : 0.4)
          // 原版 feature_note__toprighttoolbar_redo_action：重做按钮描述。
          .accessibilityText($r('app.string.cd_redo_action'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
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
          ColorPickerView({
            viewModel: this.viewModel,
            selectionMode: this.viewModel.isSelectionActive(),
            selectionColor: this.selectionColor,
            photoImportLeaseActive: this.photoImportLeaseActive,
            onSelectionColor: (color: number): void => this.onSelectionColor(color),
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      if (this.viewModel.showWidthSlider) {
        Row() {
          WidthSlider({
            viewModel: this.viewModel,
            selectionMode: this.viewModel.isSelectionActive(),
            selectionWidth: this.selectionWidth,
            selectionMinimum: this.selectionWidthMinimum,
            selectionMaximum: this.selectionWidthMaximum,
            photoImportLeaseActive: this.photoImportLeaseActive,
            onSelectionWidth: (width: number): void => this.onSelectionWidth(width),
          })
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
              .enabled(!this.viewModel.toolStateLoading &&
                !this.photoImportLeaseActive)
              .onClick(() => {
                if (this.photoImportLeaseActive) {
                  return;
                }
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
    .bindSheet(this.showToolSettings, this.buildToolSettings(), {
      height: SheetSize.MEDIUM,
      showClose: false,
    })
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      this.compact = (newArea.width as number) < 600;
    })
  }

  private buildCompactToolMenu(): MenuElement[] {
    return [
      { value: $r('app.string.whole_eraser'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.WHOLE_ERASER);
      } },
      { value: $r('app.string.partial_eraser'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.PARTIAL_ERASER);
      } },
      { value: $r('app.string.selection'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.SELECTION);
      } },
      { value: $r('app.string.text'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectTool(ToolType.DEFAULT);
      } },
      { value: $r('app.string.insert_photo'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onInsertPhotos();
      } },
      { value: $r('app.string.take_photo'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onTakePhoto();
      } },
      { value: $r('app.string.insert_math'), action: () => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onInsertMath();
      } },
    ];
  }

  // 每个可见工具行一个按钮；tool_id 级选中高亮支持同类型重复工具。
  @Builder
  StateToolButton(label: ResourceStr, tool: ToolState) {
    Button(label)
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.isActiveTool(tool.toolId) ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.viewModel.isActiveTool(tool.toolId) ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectToolById(tool.toolId);
      })
  }

  // WHOLE_ERASER 行渲染为 整笔/局部 两个模式按钮（与原版 eraserIsPartial 模式位对应）。
  @Builder
  EraserToolButtons(tool: ToolState) {
    Button($r('app.string.whole_eraser'))
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.isActiveTool(tool.toolId) && !this.viewModel.eraserIsPartial ?
        this.resolveTokens().accent : this.resolveTokens().control)
      .fontColor(this.viewModel.isActiveTool(tool.toolId) && !this.viewModel.eraserIsPartial ?
        this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectToolById(tool.toolId).then((selected: boolean): void => {
          if (selected) {
            this.viewModel.setEraserIsPartial(false);
          }
        });
      })
    Button($r('app.string.partial_eraser'))
      .width(this.compact ? 72 : 88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.isActiveTool(tool.toolId) && this.viewModel.eraserIsPartial ?
        this.resolveTokens().accent : this.resolveTokens().control)
      .fontColor(this.viewModel.isActiveTool(tool.toolId) && this.viewModel.eraserIsPartial ?
        this.resolveTokens().onAccent : this.resolveTokens().textPrimary)
      .margin({ left: 2, right: 2 })
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.viewModel.selectToolById(tool.toolId).then((selected: boolean): void => {
          if (selected) {
            this.viewModel.setEraserIsPartial(true);
          }
        });
      })
  }

  @Builder
  buildToolSettings() {
    ToolboxSettingsDialog({
      viewModel: this.viewModel,
      onClose: (): void => {
        this.showToolSettings = false;
      },
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
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive)
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
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
      .backgroundColor(this.selectionStyle === style ? this.resolveTokens().accent :
        this.resolveTokens().control)
      .fontColor(this.selectionStyle === style ? this.resolveTokens().onAccent :
        this.resolveTokens().textPrimary)
      .enabled(!this.viewModel.toolStateLoading &&
        !this.photoImportLeaseActive &&
        (style !== BrushStyle.TAPER || this.selectionVariableStyleEnabled))
      .onClick(() => {
        if (this.photoImportLeaseActive) {
          return;
        }
        this.onSelectionStyle(style);
      })
  }
}
